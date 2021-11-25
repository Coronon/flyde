import '../../../core/console/terminal_color.dart';
import '../../../core/console/bold.dart';
import '../render/widget.dart';

/// A [Widget] which displays non-static styled text.
class Label extends Widget with StatefulWidget {
  /// The text displayed by the [Label].
  final State<String> _text;

  /// A flag indicating if the [_text] is bold.
  final State<bool> _bold;

  /// The color of the [_text].
  final State<TerminalColor> _color;

  Label(this._text, {State<TerminalColor>? color, State<bool>? bold})
      : _color = color ?? State(TerminalColor.white),
        _bold = bold ?? State(false) {
    _text.subscribe(this);
    _color.subscribe(this);
    _bold.subscribe(this);
  }

  /// Use this constructor when later changes of the text or style are not required.
  Label.constant(String content, {TerminalColor color = TerminalColor.white, bool bold = false})
      : _text = State(content),
        _color = State(color),
        _bold = State(bold);

  /// Use this constructor when the text could change in the future but the style will be consistent.
  Label.fixedStyle(this._text, {TerminalColor color = TerminalColor.white, bool bold = false})
      : _color = State(color),
        _bold = State(bold) {
    _text.subscribe(this);
  }

  @override
  String render() {
    final content = _color.value.prepare(_text.value);
    return _bold.value ? content.bold() : content;
  }
}
