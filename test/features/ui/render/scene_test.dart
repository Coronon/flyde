import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';

import 'package:flyde/features/ui/render/scene.dart';
import 'package:flyde/features/ui/render/widget.dart';
import 'package:flyde/core/console/displayed_length.dart';

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
      MockInline([
        MockWidget(State('inline-1'), straightForwardContent: true),
        MockWidget(State('inline-2'), straightForwardContent: true),
      ]),
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
      condition: (cnt) => cnt.length == 6,
    );

    hook.expect(hasLength(6));
    hook.expect(
      orderedEquals([
        'mock-state1',
        '\n',
        'mock-state2',
        '\n',
        'inline-1->inline-2',
        '\n',
      ]),
    );
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
      condition: (cnt) => cnt.length == 11,
    );

    hook.expect(hasLength(11));
    hook.expect(orderedEquals([
      'mock-state1',
      '\n',
      'mock-state2',
      '\n',
      'inline-1->inline-2',
      '\n',
      '\x1B[?25l',
      '\x1B[3F',
      'mock-state-changed'.padRight(virtualTerminalWidth),
      '\x1B[3E',
      '\x1B[?25h',
    ]));
  });

  test('Fails when minimum or maximum width are not met', () {
    final int len = widgets.last.render().displayedLength;
    final maxErrMsg = 'The widget is wider than expected. Expected: ${len - 1}. Actual: $len';
    final minErrMsg = 'The widget is smaller than expected. Expected: ${len + 1}. Actual: $len';

    widgets.last.minWidth = len + 1;

    expect(
      scene.show,
      throwsA(
        isA<StateError>().having(
          (err) => err.message,
          'message',
          equals(minErrMsg),
        ),
      ),
    );

    widgets.last.minWidth = null;
    widgets.last.maxWidth = len - 1;

    expect(
      scene.show,
      throwsA(
        isA<StateError>().having(
          (err) => err.message,
          'message',
          equals(maxErrMsg),
        ),
      ),
    );
  });
}
