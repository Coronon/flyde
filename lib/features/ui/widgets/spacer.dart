import 'dart:math';

import '../../../core/console/terminal_color.dart';
import '../render/widget.dart';
import 'label.dart';

/// Spacer element which resolves to a bunch of empty lines.
class Spacer extends Widget with ContainerWidget {
  /// Number of lines which should be empty.
  final int _lines;

  Spacer([this._lines = 1]);

  @override
  List<Widget> get children => List.filled(
        max(_lines, 1),
        Label.constant('', color: TerminalColor.none),
      );
}
