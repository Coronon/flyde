@TestOn('!windows')

import 'dart:io';

import 'package:test/test.dart';
import 'package:flyde/core/fs/compiler/installed_compiler.dart';
import 'package:flyde/core/fs/configs/compiler_config.dart';
import 'package:flyde/features/build_server/cache/project_cache.dart';
import 'package:flyde/features/build_server/compiler.dart';

import '../../helpers/clear_test_cache_directory.dart';
import '../../helpers/create_dummy_project_cache.dart';
import '../../helpers/load_eaxmple_files.dart';
import '../../helpers/map_example_files.dart';

const _cacheId = 'compiler_test';

Future<String> _run(File file) async {
  final proc = await Process.run(file.path, []);
  return proc.stdout as String;
}

Future<void> main() async {
  final config1 = CompilerConfig(
      compiler: InstalledCompiler.gpp,
      threads: 4,
      sourceDirectories: ['./example'],
      compilerFlags: ['-O2', '-DPRINTHELLO'],
      linkerFlags: ['-flto']);

  final config2 = CompilerConfig(
      compiler: InstalledCompiler.gpp,
      threads: 4,
      sourceDirectories: ['./example'],
      compilerFlags: ['-O3', '-DPRINTBYE'],
      linkerFlags: ['-flto']);

  ProjectCache cache = await createDummyProjectCache(init: true, id: _cacheId);

  final files = await loadExampleFiles();
  final fileMap = await mapExampleFiles(files);

  setUp(() async {
    await clearTestCacheDirectory(id: _cacheId);
    cache = await createDummyProjectCache(init: true, id: _cacheId);
  });

  tearDown(() async => await clearTestCacheDirectory(id: _cacheId));

  test('Finds outdated files', () async {
    final comp = Compiler(config1, fileMap, cache);
    final old = await comp.outdatedFiles;

    expect(old.length, files.length);
    expect(old, unorderedEquals(files.map((e) => e.id)));
  });

  test('Compiles with all flags', () async {
    final comp = Compiler(config1, fileMap, cache);
    String out;
    File? exe;

    for (final file in files) {
      await comp.insert(file);
    }

    await expectLater(comp.compile(), completion(isA<void>()));

    exe = await comp.lastExecutable;
    expect(exe, isNotNull);
    out = await _run(exe!);

    expect(out.trim(), equals('HELLO'));
  });

  test('Creates seperate binaries for different configs', () async {
    final comp = Compiler(config1, fileMap, cache);
    final out = <String>[];
    final exe = <File?>[];

    for (final file in files) {
      await comp.insert(file);
    }

    await comp.compile();

    exe.add(await comp.lastExecutable);
    out.add(await _run(exe[0]!));

    comp.update(config2, fileMap);
    await comp.compile();

    exe.add(await comp.lastExecutable);
    out.add(await _run(exe[1]!));

    expect(out[0].trim(), equals('HELLO'));
    expect(out[1].trim(), equals('BYE'));
  });

  test('Fails when not in sync', () async {
    final comp = Compiler(config1, fileMap, cache);
    await expectLater(comp.compile(), throwsA(isA<StateError>()));
  });

  test('Executable is null if nothing has been compiled', () async {
    final comp = Compiler(config1, fileMap, cache);
    await expectLater(comp.lastExecutable, completion(equals(null)));
  });
}
