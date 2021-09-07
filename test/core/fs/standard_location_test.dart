@TestOn('!windows')

import 'dart:io';

import 'package:test/test.dart';
import 'package:flyde/core/fs/standard_location.dart';

void main() {
  test('Can create valid directory path', () {
    expect(
      StandardLocation.tmp.directory.path,
      equals(Directory.systemTemp.path),
    );

    expect(
      StandardLocation.library.directory.path,
      equals('/var/lib'),
    );

    expect(
      StandardLocation.applicationLibrary.directory.path,
      equals('${Platform.environment['HOME']}/.flyde'),
    );
  });
}
