import 'dart:async';

import 'package:test/test.dart';

import 'package:flyde/features/ui/render/widget.dart';

import '../../../helpers/mocks/mock_widget.dart';
import '../../../helpers/value_hook.dart';

const _initialPrimaryState = '1';
const _changedPrimaryState = '2';
const _initialSecondaryState = '3';
const _changedSecondaryState = '4';

void main() {
  late StreamController<WidgetUpdateRequest> controller;
  late State<String> state;
  late State<String> inlineState;
  late MockWidget widget;
  late MockInline inline;

  setUp(() {
    controller = StreamController();
    state = State(_initialPrimaryState);
    inlineState = State(_initialSecondaryState);
    widget = MockWidget(state)
      ..updateRequestReceiver = controller.sink
      ..line = 0;

    inline = MockInline([
      MockWidget(inlineState),
      MockWidget(State('*')),
    ])
      ..updateRequestReceiver = controller.sink
      ..line = 1;
  });

  test('Renders expected output', () {
    expect(widget.render(), equals('mock-$_initialPrimaryState'));
  });

  test('Requests update on state change', () async {
    final hook = VHook<int>.empty();

    controller.stream.listen((event) {
      hook.completeValue(event.line);
    });

    state.value = _changedPrimaryState;
    await hook.awaitValue(
      timeout: Duration(seconds: 1),
      condition: (line) => line == 0,
    );
    expect(widget.content.value, equals(_changedPrimaryState));
    expect(widget.render(), equals('mock-$_changedPrimaryState'));
  });

  test('Can render inline widgets', () {
    expect(inline.render(), equals('mock-$_initialSecondaryState->mock-*'));
  });

  test('Children of inline widgets respond to state updates', () async {
    final hook = VHook<int>.empty();

    inline.syncBody();
    controller.stream.listen((event) {
      hook.completeValue(event.line);
    });

    inlineState.value = _changedSecondaryState;
    await hook.awaitValue(
      timeout: Duration(seconds: 1),
      condition: (line) => line == 1,
    );
    expect(inline.render(), equals('mock-$_changedSecondaryState->mock-*'));
  });

  test('Container widget cannot be rendered', () {
    final container = MockContainer(State('any'));
    expect(container.render, throwsStateError);
  });
}
