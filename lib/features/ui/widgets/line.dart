import 'dart:math';

import '../../../core/console/displayed_length.dart';
import '../../../core/console/text_alignment.dart';
import '../render/widget.dart';

/// A line combines multiple [Widget]s in one line and adds a separator between them.
///
/// If a `width` parameter is passed to the constructor, each child [Widget] which
/// is smaller in width will be padded according to `alignment` to match the required width.
///
/// A [Line] does not support rendering container (-> multi-line) [Widget]s for obvious reasons.
class Line extends InlineWidget {
  /// The [Widget] used to separate the child [Widget]s
  final Widget _separator;

  /// The minimum width of each children.
  final int _width;

  /// The alignment of each child which has a width less than the minimum width
  final TextAlignment _alignment;

  /// Value used as default width for each child.
  ///
  /// Indicates that no further padding should be applied.
  static const int _defaultWidth = -1;

  Line(
    List<Widget> body,
    this._separator, {
    int width = _defaultWidth,
    TextAlignment alignment = TextAlignment.left,
  })  : _width = width,
        _alignment = alignment,
        super(body);

  @override
  String render() {
    final rendered = body.map((e) => e.render());

    if (_width <= _defaultWidth) {
      return rendered.join(_separator.render());
    }

    final displayedWidths = rendered.map(getDisplayedLength);
    final minWidth = displayedWidths.reduce(max);
    final width = max(minWidth, _width);

    final padded = rendered.map((String child) {
      while (child.displayedLength < width) {
        final hasEvenWidth = child.displayedLength % 2 == 0;
        final alignCenter = _alignment == TextAlignment.center;
        final alignLeft = _alignment == TextAlignment.left;

        if (alignLeft || (alignCenter && hasEvenWidth)) {
          child += ' ';
        } else {
          child = ' ' + child;
        }
      }

      return child;
    });

    return padded.join(_separator.render());
  }
}
