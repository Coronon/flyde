import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:flyde/core/fs/search_directory.dart';

void main() {
  test('Can list all files', () async {
    final files = await searchDirectory(Directory('example'), fileMatcher);
    final List<String> expected = [
      'example/.vscode/c_cpp_properties.json',
      'example/.vscode/settings.json',
      'example/src/main.cpp',
      'example/include/constants/numbers.hpp',
      'example/include/model/Calculator.hpp',
      'example/src/model/Calculator.cpp',
    ];

    expect(
      files.map((f) => p.hash(f.path)),
      unorderedEquals(expected.map((f) => p.hash(f))),
    );
  });

  test('Returns empty list on non-existing directory', () async {
    expect(
      await searchDirectory(Directory('not-real'), fileMatcher),
      isEmpty,
    );
  });
}
