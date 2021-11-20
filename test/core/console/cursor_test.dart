import 'dart:async';
import 'dart:io';

import 'package:flyde/core/console/cursor.dart';
import 'package:test/test.dart';

void main() {
  late StreamController<List<int>> controller;

  setUp(() {
    controller = StreamController<List<int>>();
  });

  test('Uses correct ANSI code for moving cursor up', () async {
    moveUp(3, sink: IOSink(controller.sink));
    expect(
      String.fromCharCodes(await controller.stream.first),
      equals('\x1B[3F'),
    );
  });

  test('Uses correct ANSI code for moving cursor down', () async {
    moveDown(3, sink: IOSink(controller.sink));
    expect(
      String.fromCharCodes(await controller.stream.first),
      equals('\x1B[3E'),
    );
  });

  test('Uses correct ANSI code to clear a line', () async {
    clearLine(sink: IOSink(controller.sink));
    expect(
      String.fromCharCodes(await controller.stream.first),
      equals('\x1B[2K'),
    );
  });

  test('Uses correct ANSI code to hide the cursor', () async {
    hideCursor(sink: IOSink(controller.sink));
    expect(
      String.fromCharCodes(await controller.stream.first),
      equals('\x1B[?25l'),
    );
  });

  test('Uses correct ANSI code to show the cursor', () async {
    showCursor(sink: IOSink(controller.sink));
    expect(
      String.fromCharCodes(await controller.stream.first),
      equals('\x1B[?25h'),
    );
  });
}
