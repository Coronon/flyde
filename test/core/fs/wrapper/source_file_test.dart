import 'dart:io';

import 'package:flyde/core/fs/wrapper/source_file.dart';
import 'package:test/test.dart';

void main() {
  test('Can be created from file', () async {
    final file = File('./example/src/main.cpp');
    final srcFile = SourceFile(0, ['src'], 'main', 'cpp', file: file);
    final data = await srcFile.data;
    final id = srcFile.id;
    final hash = await srcFile.hash;

    expect(data, isNotEmpty);
    expect(id, equals('84728edd64e9e57bfadf71a0edacd55d0b9398f04e3603a12bae84f454edf588'));
    expect(hash, equals('63bf8796ebbce7587b03af682924e3b12fdcda0ac40b174cec60e8094594fb07'));
  });

  test('Can be created from file constructor', () async {
    final file = File('./example/src/main.cpp');
    final srcFile = SourceFile.fromFile(0, file, entryDirectory: Directory('./example'));
    final data = await srcFile.data;
    final id = srcFile.id;
    final hash = await srcFile.hash;

    expect(data, isNotEmpty);
    expect(srcFile.extension, equals('cpp'));
    expect(srcFile.name, equals('main'));
    expect(srcFile.path, orderedEquals(['src']));
    expect(id, equals('84728edd64e9e57bfadf71a0edacd55d0b9398f04e3603a12bae84f454edf588'));
    expect(hash, equals('63bf8796ebbce7587b03af682924e3b12fdcda0ac40b174cec60e8094594fb07'));
  });

  test('Can be created from raw data', () async {
    final file = File('./example/src/main.cpp');
    final srcFile = SourceFile(0, ['src'], 'main', 'cpp', data: await file.readAsBytes());
    final data = await srcFile.data;
    final id = srcFile.id;
    final hash = await srcFile.hash;

    expect(data, isNotEmpty);
    expect(id, equals('84728edd64e9e57bfadf71a0edacd55d0b9398f04e3603a12bae84f454edf588'));
    expect(hash, equals('63bf8796ebbce7587b03af682924e3b12fdcda0ac40b174cec60e8094594fb07'));
  });

  test('Has different ids and hashes for different files', () async {
    final file1 = SourceFile.fromFile(
      0,
      File('./example/src/main.cpp'),
      entryDirectory: Directory('./example'),
    );
    final file2 = SourceFile.fromFile(
      0,
      File('./example/src/model/Calculator.cpp'),
      entryDirectory: Directory('./example'),
    );

    expect(file1.id, isNot(equals(file2.id)));
    expect(await file1.hash, isNot(equals(await file2.hash)));
  });
}
