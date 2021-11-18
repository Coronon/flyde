import 'dart:async';

import 'package:flyde/features/ui/render/widget.dart';
import 'package:test/test.dart';

import '../../../helpers/value_hook.dart';

void main() {
  StreamController<WidgetUpdateRequest> controller = StreamController();
  State<String> state = State('hi');
  _MockWidget widget = _MockWidget(state)
    ..updateRequestReceiver = controller
    ..line = 0;

  setUp(() {
    controller = StreamController();
    state = State('hi');
    widget = _MockWidget(state)
      ..updateRequestReceiver = controller
      ..line = 0;
  });

  test('Renders expected output', () {
    expect(widget.render(), equals('mock-hi'));
  });

  test('Requests update on state change', () async {
    final hook = VHook.empty();

    controller.stream.listen((event) {
      expect(event.line, equals(0));
      hook.complete();
    });

    state.value = 'bye';
    await hook.awaitCompletion(Duration(seconds: 1));
    expect(widget.content.value, equals('bye'));
    expect(widget.render(), equals('mock-bye'));
  });
}

class _MockWidget extends Widget with StatefulWidget {
  final State<String> content;

  _MockWidget(this.content) {
    content.subscribe(this);
  }

  @override
  String render() {
    return 'mock-${content.value}';
  }
}
