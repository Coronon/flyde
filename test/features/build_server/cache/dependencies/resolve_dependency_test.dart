import 'dart:io';

import 'package:test/test.dart';
import 'package:flyde/core/fs/wrapper/source_file.dart';
import 'package:flyde/features/build_server/cache/dependencies/resolve_dependency.dart';

void main() {
  final entryDir = Directory('./example');
  final mainFile = SourceFile.fromFile(
    0,
    File('./example/src/main.cpp'),
    entryDirectory: entryDir,
  );
  final calculatorHeaderFile = SourceFile.fromFile(
    0,
    File('./example/include/Calculator.hpp'),
    entryDirectory: entryDir,
  );
  final constNumberHeaderFile = SourceFile.fromFile(
    0,
    File('./example/include/constants/numbers.hpp'),
    entryDirectory: entryDir,
  );
  final calcDep = 'Calculator.hpp';
  final numDep = '../include/constants/numbers.hpp';
  final allFiles = [mainFile, calculatorHeaderFile, constNumberHeaderFile];

  test('Absolute dependencies can be resolved', () async {
    await expectLater(
      resolve(
        calcDep,
        mainFile,
        allFiles,
        entryDir,
      ),
      completion(equals(calculatorHeaderFile.id)),
    );
  });

  test('Relative dependencies can be resolved', () async {
    await expectLater(
      resolve(
        numDep,
        mainFile,
        allFiles,
        entryDir,
      ),
      completion(equals(constNumberHeaderFile.id)),
    );
  });
}
