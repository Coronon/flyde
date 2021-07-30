import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flyde/core/fs/compiler/installed_compiler.dart';
import 'package:flyde/core/fs/configs/compiler_config.dart';
import 'package:flyde/core/fs/file_extension.dart';
import 'package:flyde/core/fs/wrapper/source_file.dart';
import 'package:flyde/features/build_server/cache/project_cache.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/clear_test_cache_directory.dart';
import '../../../helpers/create_dummy_project_cache.dart';

const _cacheId = 'project_cache_test';
const _dummyProjectCachePath = './flyde-test-lib-$_cacheId/cache/testing';

void main() {
  final config = CompilerConfig(
      compiler: InstalledCompiler.gpp,
      threads: 4,
      sourceDirectories: ['./example'],
      compilerFlags: ['-O2'],
      linkerFlags: ['-flto']);

  setUp(() async => await clearTestCacheDirectory(id: _cacheId));
  tearDown(() async => await clearTestCacheDirectory(id: _cacheId));

  test('Creates state file on init', () async {
    await createDummyProjectCache(id: _cacheId);

    final state = File('$_dummyProjectCachePath/.state.json');
    final exists = await state.exists();

    expect(exists, true);
  });

  test('Can handle blank cache', () async {
    await createDummyProjectCache(id: _cacheId);
    await expectLater(createDummyProjectCache(id: _cacheId), completion(isA<ProjectCache>()));
  });

  test('Can synchronize files', () async {
    final cache = await createDummyProjectCache(id: _cacheId);
    final srcFiles = await _getSourceFiles();
    final requiredFiles = await _getRequiredFiles(cache, config, srcFiles);

    // Requires all files on first initialization
    expect(requiredFiles, unorderedEquals(srcFiles.map((e) => e.id)));

    for (final file in srcFiles) {
      await cache.insert(file);
    }

    // Requires no files when synced again
    expect(await _getRequiredFiles(cache, config, srcFiles), isEmpty);
  });

  test('Re-requires files with changed content', () async {
    final cache = await createDummyProjectCache(id: _cacheId);
    List<SourceFile> srcFiles = await _getSourceFiles();
    List<String> requiredFiles = await _getRequiredFiles(cache, config, srcFiles);

    // Requires all files on first initialization
    expect(requiredFiles, unorderedEquals(srcFiles.map((e) => e.id)));

    for (final file in srcFiles.where((file) => requiredFiles.contains(file.id))) {
      await cache.insert(file);
    }

    srcFiles = await _getSourceFiles(
      changing: 'main',
      withContent: (cnt) => cnt.replaceFirst('PRINTHELLO', 'PRINTNOTHELLO'),
    );

    requiredFiles = await _getRequiredFiles(
      cache,
      config,
      srcFiles,
    );

    // Requires 'main.cpp' after the file changed
    expect(
      requiredFiles,
      unorderedEquals([srcFiles.singleWhere((file) => file.name == 'main').id]),
    );
  });

  test('Provides all source files for compilation', () async {
    final cache = await createDummyProjectCache(id: _cacheId);
    final srcFiles = await _getSourceFiles();
    final requiredFiles = await _getRequiredFiles(cache, config, srcFiles);

    for (final file in srcFiles.where((file) => requiredFiles.contains(file.id))) {
      await cache.insert(file);
    }

    expect(
      await cache.sourceFiles,
      hasLength(equals(
        srcFiles.where((f) => FileExtension.sources.contains('.${f.extension}')).length,
      )),
    );
  });

  test('Provides all source files for compilation after header changed', () async {
    final cache = await createDummyProjectCache(id: _cacheId);
    List<SourceFile> srcFiles = await _getSourceFiles();
    List<String> requiredFiles = await _getRequiredFiles(cache, config, srcFiles);

    for (final file in srcFiles.where((file) => requiredFiles.contains(file.id))) {
      await cache.insert(file);
    }

    for (final ref in await cache.sourceFiles) {
      await ref.object.writeAsString('compiled file');
      await ref.link();
    }

    srcFiles = await _getSourceFiles(
      changing: 'numbers',
      withContent: (cnt) => cnt.replaceFirst(
        'constexpr int seven = 7;',
        'constexpr int seven = 9;',
      ),
    );

    requiredFiles = await _getRequiredFiles(
      cache,
      config,
      srcFiles,
    );

    for (final file in srcFiles.where((file) => requiredFiles.contains(file.id))) {
      await cache.insert(file);
    }

    final filesToRecompile = await cache.sourceFiles;

    expect(
      filesToRecompile.map((e) => e.source.path),
      hasLength(equals(1)),
    );

    expect(
      filesToRecompile.map((e) => e.source.path),
      everyElement(endsWith('main.cpp')),
    );
  });
}

/// Reads the `./example` directory and returns a list of all cpp related files.
Future<List<File>> _loadExampleFiles() async {
  return [
    await for (final entity in Directory('./example').list(recursive: true)) entity,
  ]
      .whereType<File>()
      .where((file) =>
          FileExtension.sources.contains(p.extension(file.path)) ||
          FileExtension.headers.contains(p.extension(file.path)))
      .toList();
}

/// Returns a list of all files in the `./example` directory converted
/// to `SourceFile`s.
///
/// If [changing] is not null, all files with the name will be
/// changed using the [withContent] function on it's data.
Future<List<SourceFile>> _getSourceFiles({
  String? changing,
  String Function(String)? withContent,
}) async {
  final files = await _loadExampleFiles();
  final srcFiles = <SourceFile>[];

  for (final file in files) {
    final srcFile = SourceFile.fromFile(0, file, entryDirectory: Directory('./example'));

    if (srcFile.name == changing && withContent != null) {
      final newCnt = withContent(utf8.decode(await srcFile.data));
      srcFiles.add(SourceFile(
        srcFile.entry,
        srcFile.path,
        srcFile.name,
        srcFile.extension,
        data: Uint8List.fromList(utf8.encode(newCnt)),
      ));
    } else {
      srcFiles.add(srcFile);
    }
  }

  return srcFiles;
}

/// Returns a list of all required file ids of [cache] with the
/// given [config] after synchronizing with [srcFiles].
Future<List<String>> _getRequiredFiles(
  ProjectCache cache,
  CompilerConfig config,
  List<SourceFile> srcFiles,
) async {
  final fileMap = {
    for (final file in srcFiles) file.id: await file.hash,
  };

  return await cache.sync(fileMap, config);
}
