import 'dart:async';
import 'dart:io';

import 'package:flyde/core/fs/compiler/installed_compiler.dart';
import 'package:flyde/core/fs/configs/compiler_config.dart';
import 'package:flyde/core/fs/file_extension.dart';
import 'package:flyde/core/fs/search_directory.dart';
import 'package:flyde/core/fs/wrapper/source_file.dart';
import 'package:flyde/core/networking/protocol/process_completion.dart';
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
}
