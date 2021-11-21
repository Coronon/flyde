import 'dart:async';

import 'package:flyde/core/console/terminal_color.dart';
import 'package:flyde/features/ui/render/widget.dart';
import 'package:flyde/features/ui/widgets/label.dart';
import 'package:test/test.dart';

void main() {
  test('Renders colorful and bold text', () {
    final both = Label.constant('both', color: TerminalColor.white, bold: true);
    final color = Label.constant('color', color: TerminalColor.white);
    final bold = Label.constant('bold', color: TerminalColor.none, bold: true);

    expect(
      both.render(),
      equals('\x1B[1m\x1B[37mboth\x1B[0m\x1B[0m'),
    );
    expect(
      color.render(),
      equals('\x1B[37mcolor\x1B[0m'),
    );
    expect(
      bold.render(),
      equals('\x1B[1mbold\x1B[0m'),
    );
  });

  test('Reacts to state changes', () {
    final color = State(TerminalColor.white);
    final bold = State(true);
    final content = State('test');
    final defaultLabel = Label(content, color: color, bold: bold);
    final styledLabel = Label.fixedStyle(content, color: TerminalColor.none, bold: false);

    defaultLabel
      ..updateRequestReceiver = StreamController<WidgetUpdateRequest>().sink
      ..line = 0;
    styledLabel
      ..updateRequestReceiver = StreamController<WidgetUpdateRequest>().sink
      ..line = 0;

    expect(defaultLabel.render(), equals('\x1B[1m\x1B[37mtest\x1B[0m\x1B[0m'));
    expect(styledLabel.render(), equals('test'));

    color.value = TerminalColor.black;
    bold.value = false;
    content.value = 'changed';

    expect(defaultLabel.render(), equals('\x1B[30mchanged\x1B[0m'));
    expect(styledLabel.render(), equals('changed'));
  });
}
