import 'dart:io';

import 'package:test/test.dart';
import 'package:flyde/core/fs/wrapper/source_file.dart';
import 'package:flyde/features/build_server/cache/dependencies/find_dependencies.dart';

void main() {
  final file = SourceFile.fromFile(0, File('./example/src/main.cpp'));

  test('All dependencies can be detected', () async {
    final deps = await findDependencies(file);
    final expected = {'Calculator.hpp', '../include/constants/numbers.hpp'};

    expect(deps, unorderedEquals(expected));
  });
}
