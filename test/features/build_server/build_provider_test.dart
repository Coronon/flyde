import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flyde/core/fs/compiler/installed_compiler.dart';
import 'package:flyde/core/fs/configs/compiler_config.dart';
import 'package:flyde/core/fs/file_extension.dart';
import 'package:flyde/core/fs/search_directory.dart';
import 'package:flyde/core/fs/wrapper/source_file.dart';
import 'package:flyde/core/networking/protocol/compile_status.dart';
import 'package:flyde/core/networking/protocol/process_completion.dart';
import 'package:flyde/core/networking/protocol/project_build.dart';
import 'package:flyde/core/networking/protocol/project_update.dart';
import 'package:flyde/core/networking/protocol/project_init.dart';
import 'package:flyde/core/networking/server.dart';
import 'package:flyde/core/networking/websockets/middleware.dart';
import 'package:flyde/core/networking/websockets/session.dart';
import 'package:flyde/features/build_server/build_provider.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../helpers/clear_test_cache_directory.dart';
import '../../helpers/get_uri.dart';
import '../../helpers/value_hook.dart';

/// Name of the temporary file storage
const tmpDirName = 'flyde-test-lib-build_provider_test_binary';

/// Verifies that a prject can be built and the binary can be downloaded using the 'test' package.
///
/// The downloaded binary is returned if the build was successful.
/// Otherwise the tests will fail.
Future<Uint8List> _requestAndDownloadProject(
  String projectName,
  ClientSession clientSession,
  Map<String, String> fileMap,
  List<SourceFile> files,
  CompilerConfig config,
) async {
  List<String> requiredFiles = [];
  final isDone = VHook<bool?>(null);
  final hasBinary = VHook<bool?>(null);
  Uint8List? bin;

  clientSession.onMessage = (session, message) async {
    if (message is ProjectUpdateResponse) {
      requiredFiles = message.files;

      final id = requiredFiles.removeLast();
      final file = files.singleWhere((f) => f.id == id);

      await session.send(FileUpdate.fromSourceFile(file));
    }

    if (message is CompileStatusMessage) {
      if (message.status == CompileStatus.done) {
        isDone.set(true);
      }
    }

    if (message is ProcessCompletionMessage) {
      if (message.process == CompletableProcess.projectInit) {
        await clientSession.send(ProjectUpdateRequest(config: config, files: fileMap));
      }

      if (message.process == CompletableProcess.fileUpdate) {
        if (requiredFiles.isNotEmpty) {
          final id = requiredFiles.removeLast();
          final file = files.singleWhere((f) => f.id == id);

          await session.send(FileUpdate.fromSourceFile(file));
        } else {
          await session.send(projectBuildRequest);
        }
      }
    }

    if (message is BinaryResponse) {
      hasBinary.set(message.binary != null);
      bin = message.binary;
    }
  };

  await clientSession.send(ProjectInitRequest(id: projectName, name: projectName));

  await isDone.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
  isDone.expect(equals(true));

  await clientSession.send(getBinaryRequest);
  await hasBinary.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
  hasBinary.expect(equals(true));

  return bin!;
}

/// Runs the binary and compares the output to the expected output.
Future<void> _runBinary(Uint8List binary, String fileName, String expectedOutput) async {
  final dir = Directory('./$tmpDirName');
  final file = File('./$tmpDirName/$fileName.out');

  // Create and write binary to disk
  await dir.create();
  await file.create();
  await file.writeAsBytes(binary.toList());

  // Make the binary runable
  await Process.run('chmod', ['u+x', file.path]);

  // Run the binary
  final proc = await Process.run(file.path, []);
  expect(proc.stdout.trim(), equals(expectedOutput));

  // Clean up
  await file.delete();
  await dir.delete();
}

void main() async {
  const String cacheSuffix = 'build_provider';
  final cacheDir = Directory('./flyde-test-lib-$cacheSuffix');
  final config1 = CompilerConfig(
    compiler: InstalledCompiler.gpp,
    threads: 4,
    sourceDirectories: ['./example'],
    compilerFlags: ['-O2', '-DPRINTHELLO'],
    linkerFlags: ['-flto'],
  );
  final config2 = CompilerConfig(
    compiler: InstalledCompiler.gpp,
    threads: 4,
    sourceDirectories: ['./example'],
    compilerFlags: ['-O3', '-DPRINTBYE'],
    linkerFlags: ['-flto'],
  );

  final files = await searchDirectory(Directory('./example'), (e) {
    final isSource = FileExtension.sources.contains(p.extension(e.path));
    final isHeader = FileExtension.headers.contains(p.extension(e.path));

    if (e is File && (isSource || isHeader)) {
      return SourceFile.fromFile(0, e, entryDirectory: Directory('./example'));
    }

    return null;
  });

  final fileMap = {
    for (final file in files) file.id: await file.hash,
  };

  late WebServer server;
  late ClientSession clientSession;
  late BuildProvider provider;

  setUp(() async {
    await clearTestCacheDirectory(id: cacheSuffix);

    server = await WebServer.open(
      InternetAddress.loopbackIPv4,
      9000,
      wsMiddleware: [protocolMiddleware],
    );

    provider = BuildProvider(server);

    await provider.setup(cacheDirectory: cacheDir);

    clientSession = ClientSession(getUri(server, 'ws').toString());
    clientSession.middleware.add(protocolMiddleware);
  });

  tearDown(() async {
    await clientSession.close();
    await provider.terminate();
    await clearTestCacheDirectory(id: cacheSuffix);
  });

  test('Responds with list of required files', () async {
    final completer = VHook<List<String>?>(null);

    clientSession.onMessage = (session, message) async {
      if (message is ProjectUpdateResponse) {
        completer.set(message.files);
      }
    };

    clientSession.send(ProjectInitRequest(id: 'test', name: 'test'));

    //? Wait for the server to handle the init request.
    // In productive code the [ProcessCompletionMessage] would be awaited
    // instead of an absolute time intervall.
    await Future.delayed(Duration(milliseconds: 500));

    clientSession.send(ProjectUpdateRequest(config: config1, files: fileMap));

    await completer.awaitValue(Duration(seconds: 2));

    expect(completer.value, unorderedEquals(files.map((f) => f.id)));
  });

  test('Verifies that initialization has been completed and accepts build requests', () async {
    final completer = VHook<bool?>(null);
    final hadError = VHook<bool?>(null);

    clientSession.onMessage = (session, message) async {
      if (message is ProcessCompletionMessage) {
        completer.set(message.process == CompletableProcess.projectInit);
      }
    };

    server.wsOnError = (session, error) async {
      hadError.set(true);
    };

    clientSession.send(ProjectInitRequest(id: 'test', name: 'test'));

    await completer.awaitValue(Duration(seconds: 10), raiseOnTimeout: true);
    completer.expect(equals(true));

    clientSession.send(ProjectUpdateRequest(config: config1, files: fileMap));

    //? Wait for 500ms to ensure no errors have been thrown.
    await hadError.awaitValue(Duration(milliseconds: 500));
    hadError.expect(isNot(equals(true)));
  });

  test('Receives correct binary after successfull build', () async {
    final Uint8List bin = await _requestAndDownloadProject(
      'test',
      clientSession,
      fileMap,
      files,
      config1,
    );

    await _runBinary(bin, 'test', 'HELLO');
  });

  test('Can handle multiple clients', () async {
    final secondSession = ClientSession(getUri(server, 'ws').toString())
      ..middleware.add(protocolMiddleware);

    final List<Uint8List> bins = await Future.wait([
      _requestAndDownloadProject(
        'test',
        clientSession,
        fileMap,
        files,
        config1,
      ),
      _requestAndDownloadProject(
        'test1',
        secondSession,
        fileMap,
        files,
        config2,
      ),
    ]);

    await _runBinary(bins[0], 'test', 'HELLO');
    await _runBinary(bins[1], 'test1', 'BYE');

    secondSession.close();
  });
}
