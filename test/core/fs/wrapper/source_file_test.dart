import 'dart:io';

import 'package:flyde/core/fs/wrapper/source_file.dart';
import 'package:flyde/core/fs/read_as_posix_file.dart';
import 'package:test/test.dart';

void main() {
  test('Can be created from file', () async {
    final file = File('./example/src/main.cpp');
    final srcFile = SourceFile(0, ['src'], 'main', 'cpp', file: file);
    final data = await srcFile.data;
    final id = srcFile.id;
    final hash = await srcFile.hash;

    expect(data, isNotEmpty);
    expect(id, equals('c058d89c09ad3dff84c14c15be2181d8c687edea3062ae455d84223f2dd39296'));
    expect(hash, equals('2404e944e90806eab0a73b2459ee30f13f4d17a5dfed2536232f9938655e1773'));
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
    expect(id, equals('c058d89c09ad3dff84c14c15be2181d8c687edea3062ae455d84223f2dd39296'));
    expect(hash, equals('2404e944e90806eab0a73b2459ee30f13f4d17a5dfed2536232f9938655e1773'));
  });

  test('Can be created from raw data', () async {
    final file = File('./example/src/main.cpp');
    final srcFile = SourceFile(0, ['src'], 'main', 'cpp', data: await file.readAsPosixBytes());
    final data = await srcFile.data;
    final id = srcFile.id;
    final hash = await srcFile.hash;

    expect(data, isNotEmpty);
    expect(id, equals('c058d89c09ad3dff84c14c15be2181d8c687edea3062ae455d84223f2dd39296'));
    expect(hash, equals('2404e944e90806eab0a73b2459ee30f13f4d17a5dfed2536232f9938655e1773'));
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
