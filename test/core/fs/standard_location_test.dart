@TestOn('!windows')

import 'dart:io';

import 'package:flyde/core/fs/standard_location.dart';
import 'package:test/test.dart';

void main() {
  test('Directory can be created', () {
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
