import 'dart:async';
import 'dart:io';

import 'package:flyde/core/fs/compiler/installed_compiler.dart';
import 'package:flyde/core/fs/configs/compiler_config.dart';
import 'package:flyde/core/fs/file_extension.dart';
import 'package:flyde/core/fs/search_directory.dart';
import 'package:flyde/core/fs/wrapper/source_file.dart';
import 'package:flyde/core/networking/protocol/compile_status.dart';
import 'package:flyde/features/build_server/cache/project_cache.dart';
import 'package:flyde/features/build_server/compiler_interface.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../helpers/clear_test_cache_directory.dart';
import '../../helpers/create_dummy_project_cache.dart';

Future<List<CompileStatusMessage>> _buildProject(
  MainInterface interface,
  List<SourceFile> files,
  Map<String, String> fileMap,
  CompilerConfig config,
  ProjectCache cache, {
  bool skipUpdateFiles = false,
}) async {
  final Completer<List<CompileStatusMessage>> completer = Completer();
  final List<CompileStatusMessage> messageCache = [];

  interface.onStateUpdate = (CompileStatusMessage m) {
    messageCache.add(m);
    if (m.status == CompileStatus.done) {
      completer.complete(messageCache);
    }
    if (m.status == CompileStatus.failed) {
      completer.completeError(StateError(m.payload));
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

  return await completer.future;
}

Future<void> main() async {
  MainInterface? interface;
  ProjectCache? cache;

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

  setUp(() async {
    await clearTestCacheDirectory(id: 'compiler_interface_test');

    interface = await MainInterface.launch();
    cache = await createDummyProjectCache(id: 'compiler_interface_test');
  });

  tearDown(() async => await clearTestCacheDirectory(id: 'compiler_interface_test'));

  test('Requires "init" call before answering other requests', () async {
    await expectLater(
      interface!.hasCapacity(),
      throwsStateError,
    );

    await interface!.init(fileMap, config1, cache);

    await expectLater(
      interface!.hasCapacity(),
      completion(equals(true)),
    );
  });

  test('Can sychronize and update a project', () async {
    await expectLater(() async => await interface!.init(fileMap, config1, cache), returnsNormally);

    final requiredFiles = await interface!.sync(fileMap, config1);

    expect(requiredFiles, unorderedEquals(fileMap.keys));

    for (final file in requiredFiles) {
      final srcFile = files.singleWhere((element) => element.id == file);
      await expectLater(
        () async => await interface!.update(srcFile),
        returnsNormally,
      );
    }

    await expectLater(() async => await interface!.build(), returnsNormally);
  });

  test('Informs about the compilation state', () async {
    final messages = await _buildProject(interface!, files, fileMap, config1, cache!);

    final compiledSourceFiles = files.where(
      (f) => FileExtension.sources.contains('.${f.extension}'),
    );
    final expectedMessageStates = [
      CompileStatus.compiling,
      ...List.filled(
        compiledSourceFiles.length,
        CompileStatus.compiling,
      ),
      CompileStatus.compiling,
      CompileStatus.linking,
      CompileStatus.waiting,
      CompileStatus.done
    ];

    expect(
      messages.map((e) => e.status),
      orderedEquals(expectedMessageStates),
    );
  });

  test('Emits a state error when not all files are updated', () async {
    await expectLater(
      _buildProject(
        interface!,
        files,
        fileMap,
        config1,
        cache!,
        skipUpdateFiles: true,
      ),
      throwsStateError,
    );
  });
}
