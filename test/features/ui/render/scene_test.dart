import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';

import 'package:flyde/features/ui/render/scene.dart';
import 'package:flyde/features/ui/render/widget.dart';

import '../../../helpers/mocks/mock_widget.dart';
import '../../../helpers/value_hook.dart';

void main() {
  late Scene scene;
  late IOSink fakeOutStream;
  late StreamController<List<int>> controller;
  late List<Widget> widgets;
  late State<String> widgetState;
  const int virtualTerminalWidth = 200;

  setUp(() {
    widgetState = State('state1');
    widgets = [
      MockWidget(widgetState),
      MockWidget(State('state2')),
    ];
    controller = StreamController();
    fakeOutStream = IOSink(controller.sink);
    scene = Scene(
      widgets,
      output: fakeOutStream,
      fallbackTerminalColumns: virtualTerminalWidth,
    );
  });

  test('Renders widgets', () async {
    final hook = VHook<List<String>>([]);

    controller.stream.listen((event) {
      hook.update(
        (previous) => [
          ...previous,
          String.fromCharCodes(event),
        ],
      );
    });

    scene.show();
    await hook.awaitValue(
      timeout: Duration(seconds: 1),
      condition: (cnt) => cnt.length == 4,
    );

    hook.expect(hasLength(4));
    hook.expect(orderedEquals(['mock-state1', '\n', 'mock-state2', '\n']));
  });

  test('Updates related lines on state change', () async {
    final hook = VHook<List<String>>([]);
    controller.stream.listen((event) {
      hook.update(
        (previous) => [
          ...previous,
          String.fromCharCodes(event),
        ],
      );
    });
    scene.show();
    widgetState.value = 'state-changed';
    await hook.awaitValue(
      timeout: Duration(seconds: 1),
      condition: (cnt) => cnt.length == 9,
    );

    hook.expect(hasLength(9));
    hook.expect(orderedEquals([
      'mock-state1',
      '\n',
      'mock-state2',
      '\n',
      '\x1B[?25l',
      '\x1B[2F',
      'mock-state-changed'.padRight(virtualTerminalWidth),
      '\x1B[2E',
      '\x1B[?25h',
    ]));
  });
}
