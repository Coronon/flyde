import 'dart:async';
import 'dart:isolate';

import 'package:test/test.dart';
import 'package:flyde/core/async/connect.dart';
import 'package:flyde/core/async/interface.dart';
import 'package:flyde/core/fs/compiler/installed_compiler.dart';
import 'package:flyde/core/fs/configs/compiler_config.dart';
import 'package:flyde/core/fs/file_extension.dart';
import 'package:flyde/core/fs/wrapper/source_file.dart';
import 'package:flyde/core/networking/protocol/build_status.dart';
import 'package:flyde/features/build_server/cache/project_cache.dart';
import 'package:flyde/features/build_server/compiler_interface.dart';

import '../../helpers/clear_test_cache_directory.dart';
import '../../helpers/create_dummy_project_cache.dart';
import '../../helpers/load_eaxmple_files.dart';
import '../../helpers/map_example_files.dart';
import '../../helpers/value_hook.dart';

/// Attempts to build the project using the [interface].
Future<List<BuildStatusMessage>> _buildProject(
  ProjectInterface interface,
  List<SourceFile> files,
  Map<String, String> fileMap,
  CompilerConfig config,
  ProjectCache cache, {
  bool skipUpdateFiles = false,
}) async {
  final VHook<List<BuildStatusMessage>> messageHook = VHook([]);

  interface.onStateUpdate = (BuildStatusMessage m) {
    messageHook.update((p) => [...p, m]);

    if (m.status == BuildStatus.done) {
      messageHook.complete();
    }
    if (m.status == BuildStatus.failed) {
      messageHook.completeError(StateError(m.payload));
    }
  };

  await interface.init(fileMap, config, cache);

  if (!skipUpdateFiles) {
    final requiredFiles = await interface.sync(fileMap, config);

    for (final file in requiredFiles) {
      final srcFile = files.singleWhere((element) => element.id == file);
      await interface.update(srcFile);
    }
  }

  await interface.build();

  return await messageHook.awaitCompletion(Duration(seconds: 5));
}

Future<void> main() async {
  late ProjectInterface interface;
  late ProjectCache cache;

  final config1 = CompilerConfig(
    compiler: InstalledCompiler.gpp,
    threads: 4,
    sourceDirectories: ['./example'],
    compilerFlags: ['-O2', '-DPRINTHELLO'],
    linkerFlags: ['-flto'],
  );

  final files = await loadExampleFiles();
  final fileMap = await mapExampleFiles(files);
  const cacheId = 'compiler_interface_test';

  setUp(() async {
    await clearTestCacheDirectory(id: cacheId);

    interface = await ProjectInterface.launch();
    cache = await createDummyProjectCache(id: cacheId);
  });

  tearDown(() async => await clearTestCacheDirectory(id: cacheId));

  test('Requires "init" call before answering other requests', () async {
    await expectLater(
      interface.hasCapacity(),
      throwsStateError,
    );

    await interface.init(fileMap, config1, cache);

    await expectLater(
      interface.hasCapacity(),
      completion(equals(true)),
    );
  });

  test('Does not initialize twice', () async {
    expect(interface.isInitialized, isFalse);
    await interface.init(fileMap, config1, cache);
    expect(interface.isInitialized, isTrue);

    await expectLater(
      interface.init(fileMap, config1, cache),
      throwsStateError,
    );

    expect(interface.isInitialized, isTrue);
  });

  test('Can sychronize and update a project', () async {
    await expectLater(() async => await interface.init(fileMap, config1, cache), returnsNormally);

    final requiredFiles = await interface.sync(fileMap, config1);

    expect(requiredFiles, unorderedEquals(fileMap.keys));

    for (final file in requiredFiles) {
      final srcFile = files.singleWhere((element) => element.id == file);
      await expectLater(
        () async => await interface.update(srcFile),
        returnsNormally,
      );
    }

    await expectLater(() async => await interface.build(), returnsNormally);
  });

  test('Informs about the compilation state', () async {
    final messages = await _buildProject(interface, files, fileMap, config1, cache);

    final compiledSourceFiles = files.where(
      (f) => FileExtension.sources.contains('.${f.extension}'),
    );
    final expectedMessageStates = [
      BuildStatus.compiling,
      ...List.filled(
        compiledSourceFiles.length,
        BuildStatus.compiling,
      ),
      BuildStatus.compiling,
      BuildStatus.linking,
      BuildStatus.waiting,
      BuildStatus.done
    ];

    expect(
      messages.map((e) => e.status),
      orderedEquals(expectedMessageStates),
    );
  });

  test('Emits a state error when not all files are updated', () async {
    await expectLater(
      _buildProject(
        interface,
        files,
        fileMap,
        config1,
        cache,
        skipUpdateFiles: true,
      ),
      throwsStateError,
    );
  });

  group('Worker', () {
    setUp(() {
      WorkerInterface.instance = null;
    });

    test('can be started exactly once', () {
      final receivePort = ReceivePort();
      final sendPort = receivePort.sendPort;

      expect(() => WorkerInterface.start(sendPort, receivePort), returnsNormally);
      expect(() => WorkerInterface.start(sendPort, receivePort), throwsStateError);
    });

    test('forwards delegation calls', () async {
      final testReceive = ReceivePort();
      final receivePort = ReceivePort();
      final sendPort = testReceive.sendPort;

      WorkerInterface.start(sendPort, receivePort);

      final worker = WorkerInterface.instance!;
      final compiling = VHook(0);
      final linking = VHook(0);
      final waiting = VHook(0);
      final done = VHook.empty();

      testReceive.listen((message) {
        if (message is InterfaceMessage && message.name == 'stateUpdate') {
          final msg = message.args as BuildStatusMessage;
          switch (msg.status) {
            case BuildStatus.compiling:
              compiling.update((val) => val + 1);
              break;
            case BuildStatus.linking:
              linking.update((val) => val + 1);
              break;
            case BuildStatus.waiting:
              waiting.update((val) => val + 1);
              break;
            case BuildStatus.done:
              done.complete();
              break;
            case BuildStatus.failed:
              break;
          }
        }
      });

      worker.didStartCompilation();
      worker.isCompiling(0);
      worker.isCompiling(0.5);
      worker.isCompiling(1);
      worker.didFinishCompilation();
      worker.didStartLinking();
      worker.didFinishLinking();
      worker.done();

      await done.awaitCompletion(Duration(seconds: 1));

      compiling.expect(equals(5));
      linking.expect(equals(1));
      waiting.expect(equals(1));
    });

    test('only initializes once', () async {
      final testReceive = ReceivePort();
      final receivePort = ReceivePort();
      final sendPort = testReceive.sendPort;
      final testSend = receivePort.sendPort;

      WorkerInterface.start(sendPort, receivePort);

      final responseHook = VHook<int>(0);

      testReceive.listen((message) {
        if (message is InterfaceMessage && message.name == 'init') {
          responseHook.update((int prev) => prev + 1, orElse: ValueContainer(1));
        }
      });

      testSend.send(InterfaceMessage('init', [fileMap, config1, cache]));
      testSend.send(InterfaceMessage('init', [fileMap, config1, cache]));

      await Future.delayed(Duration(milliseconds: 100));

      responseHook.expect(equals(1));
    });

    test('requires init as first call', () async {
      final testReceive = ReceivePort();
      final receivePort = ReceivePort();
      final sendPort = testReceive.sendPort;
      final testSend = receivePort.sendPort;
      final capacityResponseHook = VHook.empty();

      WorkerInterface.start(sendPort, receivePort);

      testReceive.listen((message) {
        if (message is InterfaceMessage) {
          capacityResponseHook.complete();
        }
      });

      testSend.send(InterfaceMessage('hasCapacity', null));

      await Future.delayed(Duration(milliseconds: 100));
      expect(capacityResponseHook.isEmpty, isTrue);
    });

    test('responds to all build related requests', () async {
      final testReceive = ReceivePort();
      final receivePort = ReceivePort();
      final sendPort = testReceive.sendPort;
      final testSend = receivePort.sendPort;
      final buildCompleter = VHook.empty();

      WorkerInterface.start(sendPort, receivePort);

      final mainInterface = ProjectInterface(
        SpawnedIsolate(Isolate.current, testReceive),
      );

      //? The [SendPort] must be sent to testReceive to simulate the
      //? behaviour of `connect` on which `Interface` relies.
      sendPort.send(testSend);

      mainInterface.onStateUpdate = (msg) {
        if (msg.status == BuildStatus.done) {
          buildCompleter.complete();
        }

        if (msg.status == BuildStatus.failed) {
          buildCompleter.completeError(StateError('Build failed with exception'));
        }
      };

      await mainInterface.init(fileMap, config1, cache);

      expect(await mainInterface.hasCapacity(), isTrue);
      expect(await mainInterface.sync(fileMap, config1), isNotEmpty);

      for (final file in files) {
        await mainInterface.update(file);
      }

      await mainInterface.build();
      await buildCompleter.awaitCompletion();

      expect(await mainInterface.binary, isNotNull);
    });
  });
}
