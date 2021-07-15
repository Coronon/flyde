import 'dart:io';

import 'package:flyde/core/fs/compiler/installed_compiler.dart';
import 'package:flyde/core/fs/configs/compiler_config.dart';
import 'package:flyde/core/fs/file_extension.dart';
import 'package:flyde/core/fs/search_directory.dart';
import 'package:flyde/core/fs/wrapper/source_file.dart';
import 'package:flyde/features/build_server/cache/project_cache.dart';
import 'package:flyde/features/build_server/compiler.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../helpers/clear_test_cache_directory.dart';
import '../../helpers/create_dummy_project_cache.dart';

const _cacheId = 'compiler_test';

Future<String> _run(File file) async {
  final proc = await Process.run(file.path, []);
  return proc.stdout as String;
}

void main() {
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

  late ProjectCache cache;
  late List<SourceFile> files;
  final fileOverview = <String, String>{};

  setUp(() async {
    await clearTestCacheDirectory(id: _cacheId);
    cache = await createDummyProjectCache(init: true, id: _cacheId);

    files = await searchDirectory(Directory('./example'), (e) {
      final isSource = FileExtension.sources.contains(p.extension(e.path));
      final isHeader = FileExtension.headers.contains(p.extension(e.path));

      if (e is File && (isSource || isHeader)) {
        return SourceFile.fromFile(0, e, entryDirectory: Directory('./example'));
      }

      return null;
    });

    for (final file in files) {
      fileOverview.addEntries([MapEntry(file.id, await file.hash)]);
    }
  });

  tearDown(() async => await clearTestCacheDirectory(id: _cacheId));

  test('Finds outdated files', () async {
    final comp = Compiler(config1, fileOverview, cache);
    final old = await comp.outdatedFiles;

    expect(old.length, files.length);
    expect(old, unorderedEquals(files.map((e) => e.id)));
  });

  test('Compiles with all flags', () async {
    final comp = Compiler(config1, fileOverview, cache);
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
    final comp = Compiler(config1, fileOverview, cache);
    final out = <String>[];
    final exe = <File?>[];

    for (final file in files) {
      await comp.insert(file);
    }

    await comp.compile();

    exe.add(await comp.lastExecutable);
    out.add(await _run(exe[0]!));

    comp.update(config2, fileOverview);
    await comp.compile();

    exe.add(await comp.lastExecutable);
    out.add(await _run(exe[1]!));

    expect(out[0].trim(), equals('HELLO'));
    expect(out[1].trim(), equals('BYE'));
  });

  test('Fails when not in sync', () async {
    final comp = Compiler(config1, fileOverview, cache);
    await expectLater(comp.compile(), throwsA(isA<StateError>()));
  });
}
