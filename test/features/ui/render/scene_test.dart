import 'dart:async';
import 'dart:io';

import 'package:flyde/features/ui/render/scene.dart';
import 'package:flyde/features/ui/render/widget.dart';
import 'package:test/test.dart';

import '../../../helpers/mocks/mock_widget.dart';
import '../../../helpers/value_hook.dart';

void main() {
  late Scene scene;
  late IOSink fakeOutStream;
  late StreamController<List<int>> controller;
  late List<Widget> widgets;

  setUp(() {
    widgets = [
      MockWidget(State('state1')),
      MockWidget(State('state2')),
    ];
    controller = StreamController();
    fakeOutStream = IOSink(controller.sink);
    scene = Scene(widgets, output: fakeOutStream);
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
}
