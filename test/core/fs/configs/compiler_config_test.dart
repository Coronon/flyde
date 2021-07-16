import 'package:flyde/core/fs/compiler/installed_compiler.dart';
import 'package:flyde/core/fs/configs/compiler_config.dart';
import 'package:test/test.dart';

void main() {
  final config = CompilerConfig(
      compiler: InstalledCompiler.gpp,
      threads: 4,
      sourceDirectories: ['./example'],
      compilerFlags: ['-O2'],
      linkerFlags: ['-flto']);

  final config2 = CompilerConfig(
      compiler: InstalledCompiler.gpp,
      threads: 4,
      sourceDirectories: ['./example'],
      compilerFlags: ['-O3'],
      linkerFlags: ['-flto']);

  final config3 = CompilerConfig(
      compiler: InstalledCompiler.gpp,
      threads: 3,
      sourceDirectories: ['./example2'],
      compilerFlags: ['-O2'],
      linkerFlags: ['-flto']);

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
}
