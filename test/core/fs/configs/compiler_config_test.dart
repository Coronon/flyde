import 'package:flyde/core/fs/compiler/installed_compiler.dart';
import 'package:flyde/core/fs/configs/compiler_config.dart';
import 'package:test/test.dart';

void main() {
  final config = CompilerConfig(
    compiler: InstalledCompiler.gpp,
    threads: 4,
    sourceDirectories: ['./example'],
    compilerFlags: ['-O2'],
    linkerFlags: ['-flto'],
  );

  final config2 = CompilerConfig(
    compiler: InstalledCompiler.gpp,
    threads: 4,
    sourceDirectories: ['./example'],
    compilerFlags: ['-O3'],
    linkerFlags: ['-flto'],
  );

  final config3 = CompilerConfig(
    compiler: InstalledCompiler.gpp,
    threads: 3,
    sourceDirectories: ['./example2'],
    compilerFlags: ['-O2'],
    linkerFlags: ['-flto'],
  );

  final config4 = CompilerConfig(
    compiler: InstalledCompiler.gpp,
    threads: 3,
    sourceDirectories: ['./example2'],
    compilerFlags: ['-O2', '-std', 'c++17'],
    linkerFlags: ['-flto'],
  );

  test('Throws on invalid input', () {
    expect(
        () => CompilerConfig(
              compiler: InstalledCompiler.gpp,
              threads: 4,
              sourceDirectories: ['./example'],
              compilerFlags: ['-O2', '-c'],
              linkerFlags: ['-flto'],
            ),
        throwsA(isA<ArgumentError>()));
  });

  test('Creates consistent hash value', () {
    final hash1 = config.hash;
    final hash2 = config.hash;

    expect(hash1, equals(hash2));
  });

  test('Creates different hash values for different flags', () {
    final hash1 = config.hash;
    final hash2 = config2.hash;

    expect(hash1, isNot(equals(hash2)));
  });

  test('Creates equal hash on different source directories and threads', () {
    final hash1 = config.hash;
    final hash2 = config3.hash;

    expect(hash1, equals(hash2));
  });

  test('Constructor throws when threads are <= 0', () {
    expect(
      () => CompilerConfig(
        compiler: InstalledCompiler.gpp,
        threads: 0,
        sourceDirectories: [],
        compilerFlags: [],
        linkerFlags: [],
      ),
      throwsArgumentError,
    );

    expect(
      () => CompilerConfig(
        compiler: InstalledCompiler.gpp,
        threads: -42,
        sourceDirectories: [],
        compilerFlags: [],
        linkerFlags: [],
      ),
      throwsArgumentError,
    );
  });

  test('Wraps value options in parentheses', () {
    expect(
      config4.compilerFlags,
      orderedEquals(['-O2', '-std', '"c++17"']),
    );
  });

  test('Adds default values for missing / empty flag sets', () {
    final json1 = {
      'compiler': 'g++',
      'threads': 4,
      'binaryPath': '.any',
      'sourceDirectories': ['./example'],
      'compilerFlags': ['-O2'],
      'linkerFlags': null,
    };

    final json2 = {
      'compiler': 'g++',
      'threads': 4,
      'binaryPath': '.any',
      'sourceDirectories': ['./example'],
      'compilerFlags': null,
      'linkerFlags': null,
    };

    final json3 = {
      'compiler': 'g++',
      'threads': 4,
      'binaryPath': '.any',
      'sourceDirectories': ['./example'],
      'compilerFlags': ['-O2'],
    };

    final json4 = {
      'compiler': 'g++',
      'threads': 4,
      'binaryPath': '.any',
      'sourceDirectories': ['./example'],
    };

    expect(CompilerConfig.fromJson(json1).compilerFlags, unorderedEquals(['-O2']));
    expect(CompilerConfig.fromJson(json1).linkerFlags, isEmpty);

    expect(CompilerConfig.fromJson(json2).compilerFlags, isEmpty);
    expect(CompilerConfig.fromJson(json2).linkerFlags, isEmpty);

    expect(CompilerConfig.fromJson(json3).compilerFlags, unorderedEquals(['-O2']));
    expect(CompilerConfig.fromJson(json3).linkerFlags, isEmpty);

    expect(CompilerConfig.fromJson(json4).compilerFlags, isEmpty);
    expect(CompilerConfig.fromJson(json4).linkerFlags, isEmpty);
  });
}
