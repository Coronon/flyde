import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:flyde/core/async/event_synchronizer.dart';
import 'package:flyde/core/fs/compiler/installed_compiler.dart';
import 'package:flyde/core/fs/configs/compiler_config.dart';
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

import '../../helpers/clear_test_cache_directory.dart';
import '../../helpers/get_uri.dart';
import '../../helpers/load_eaxmple_files.dart';
import '../../helpers/map_example_files.dart';
import '../../helpers/value_hook.dart';

/// Name of the temporary file storage
const tmpDirName = 'flyde-test-lib-build_provider_test_binary';

/// Attempts to build the project and download the compiled binary.
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
  // Synchronizer for more readable and typesafe communication
  final sync = EventSynchronizer(clientSession.send, Duration(milliseconds: 100));

  // Pass all messages received by 'clientSession' to the synchronizer
  clientSession.onMessage = (session, message) async {
    await sync.handleMessage(message);
  };

  // Request project initialization and expect verification
  await sync.request(ProjectInitRequest(id: projectName, name: projectName));
  await sync.expect(
    ProcessCompletionMessage,
    validator: (ProcessCompletionMessage msg) => msg.process == CompletableProcess.projectInit,
  );

  // Request the permission to use the compiler
  await sync.request(reserveBuildRequest);

  // Wait until permission is granted
  await sync.expect(
    String,
    validator: (String resp) => resp == isActiveSessionResponse,
    keepAlive: true,
  );

  // Sync the example project with the compiler
  await sync.request(ProjectUpdateRequest(config: config, files: fileMap));

  // Expect a response which contains the ids of all files which
  // need to be sent to the compiler
  final List<String> fileIds = await sync.expect(
    ProjectUpdateResponse,
    handler: (ProjectUpdateResponse resp) => resp.files,
  );

  // Exchange the requested files with the compiler.
  // Expect a `ProcessCompletionMessage` after each file is has been sent.
  await sync
      .exchange(
        Stream.fromFutures(
          fileIds
              .map((id) => files.singleWhere((f) => f.id == id))
              .map((f) => FileUpdate.fromSourceFile(f)),
        ),
        ProcessCompletionMessage,
        validator: (FileUpdate update, ProcessCompletionMessage comp) =>
            comp.process == CompletableProcess.fileUpdate,
      )
      .drain();

  // Request to build the newly synced project.
  await sync.request(projectBuildRequest);

  // Expect state updates and wait until compilation is done.
  await sync.expect(
    CompileStatusMessage,
    validator: (CompileStatusMessage msg) => msg.status == CompileStatus.done,
    keepAlive: true,
  );

  // Request the produced binary file
  await sync.request(getBinaryRequest);
  final bin = await sync.expect(
    BinaryResponse,
    handler: (BinaryResponse resp) => resp.binary,
  );

  // Unsubscribe from the compiler to allow other clients
  // to access the same project
  await sync.request(unsubscribeRequest);

  expect(bin, isNotNull);

  return bin!;
}

/// Runs the binary and compares the output to the expected output.
Future<void> _runBinary(Uint8List binary, String fileName, String expectedOutput) async {
  final dir = Directory('./$tmpDirName');
  final file = File('./$tmpDirName/$fileName.out');

  // Create and write binary to disk
  await file.create(recursive: true);
  await file.writeAsBytes(binary.toList());

  // Make the binary runable
  await Process.run('chmod', ['u+x', file.path]);

  // Run the binary
  final proc = await Process.run(file.path, []);
  expect(proc.stdout.trim(), equals(expectedOutput));

  // Clean up
  await dir.delete(recursive: true);
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

  final files = await loadExampleFiles();
  final fileMap = await mapExampleFiles(files);

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
    clientSession.middleware = const [protocolMiddleware];
  });

  tearDown(() async {
    await clientSession.close();
    await provider.terminate();
    await clearTestCacheDirectory(id: cacheSuffix);
  });

  test('Responds with list of required files', () async {
    final filesHook = VHook<List<String>?>(null);
    final initHook = VHook<bool?>(null);

    clientSession.onMessage = (session, message) async {
      if (message is ProjectUpdateResponse) {
        filesHook.set(message.files);
      }

      if (message is ProcessCompletionMessage) {
        initHook.set(message.process == CompletableProcess.projectInit);
      }
    };

    clientSession.send(ProjectInitRequest(id: 'test', name: 'test'));

    await initHook.awaitValue(Duration(milliseconds: 500));

    clientSession.send(reserveBuildRequest);
    clientSession.send(ProjectUpdateRequest(config: config1, files: fileMap));

    await filesHook.awaitValue(Duration(seconds: 2));

    expect(filesHook.value, unorderedEquals(files.map((f) => f.id)));
  });

  test('Verifies that initialization has been completed and accepts build requests', () async {
    final initHook = VHook<bool?>(null);
    final hadError = VHook<bool?>(null);

    clientSession.onMessage = (session, message) async {
      if (message is ProcessCompletionMessage) {
        initHook.set(message.process == CompletableProcess.projectInit);
      }
    };

    server.wsOnError = (session, error) async {
      hadError.set(true);
    };

    clientSession.send(ProjectInitRequest(id: 'test', name: 'test'));

    await initHook.awaitValue(Duration(seconds: 10), raiseOnTimeout: true);
    initHook.expect(equals(true));

    clientSession.send(reserveBuildRequest);
    clientSession.send(ProjectUpdateRequest(config: config1, files: fileMap));

    //? Wait for 500ms to ensure no errors have been thrown.
    await hadError.awaitValue(Duration(milliseconds: 500));
    hadError.expect(isNull);
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

  test('Can handle multiple clients for the same project', () async {
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
        'test',
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

  test('Can manage active projects', () async {
    final initHook1 = VHook<bool?>(null);
    final initHook2 = VHook<bool?>(null);
    final secondSession = ClientSession(getUri(server, 'ws').toString())
      ..middleware.add(protocolMiddleware);

    clientSession.onMessage = (session, message) async {
      if (message is ProcessCompletionMessage) {
        initHook1.set(true);
      }
    };

    secondSession.onMessage = (session, message) async {
      if (message is ProcessCompletionMessage) {
        initHook2.set(true);
      }
    };

    clientSession.send(ProjectInitRequest(id: 'test_id', name: 'test_name'));
    secondSession.send(ProjectInitRequest(id: 'test_id_2', name: 'test_name_2'));

    await initHook1.awaitValue(Duration(milliseconds: 100));
    await initHook2.awaitValue(Duration(milliseconds: 100));

    expect(provider.activeProjectIds, unorderedEquals(['test_id', 'test_id_2']));
    expect(provider.projectName('test_id'), equals('test_name'));
    expect(provider.projectName('test_id_2'), equals('test_name_2'));

    provider.kill('test_id');

    expect(provider.activeProjectIds, unorderedEquals(['test_id_2']));
    expect(() => provider.projectName('test_id'), throwsStateError);
  });
}
