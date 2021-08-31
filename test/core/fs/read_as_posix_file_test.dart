import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flyde/core/fs/read_as_posix_file.dart';
import 'package:test/test.dart';

void main() {
  late File file;

  setUp(() async {
    file = File('flyde-test-lib-read_as_posix_file/windows.txt');
    await file.create(recursive: true);
    await file.writeAsString('Hello \r\n Windows \r\n', flush: true);
  });

  tearDown(() async {
    await file.delete();
    await Directory('flyde-test-lib-read_as_posix_file').delete();
  });

  test(r'Converts \r\n to \n', () async {
    final String winCnt = await file.readAsString();
    final Uint8List posixCnt = await readAsPosixFile(file);

    expect(winCnt.contains('\r\n'), equals(true));
    expect(utf8.decode(posixCnt).contains('\r\n'), equals(false));
  });

  test(r'Fails on non-existing file', () async {
    await expectLater(
      readAsPosixFile(File("It's a trap!")),
      throwsArgumentError,
    );
  });
}
