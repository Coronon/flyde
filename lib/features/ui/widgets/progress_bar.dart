import 'package:flyde/features/ui/render/widget.dart';

/// Simple progress bar widget.
class ProgressBar extends Widget with StatefulWidget {
  /// The current progress. Should be in the range from 0 to 1.
  final State<double> _progress;

  /// The width of the bar element.
  /// The percent monitor requires extra space.
  final int _width;

  /// Character for the active part of the bar.
  static final String _backgroundActive = '█';

  /// Character for the inactive part of the bar.
  static final String _backgroundInactive = '▒';

  ProgressBar(this._progress, {int width = 100}) : _width = width {
    _progress.subscribe(this);
  }

  @override
  String render() {
    final int activeWidth = (_progress.value * _width).ceil().clamp(0, _width);
    final int percent = (_progress.value * 100).ceil().clamp(0, 100);
    String out = '';

    for (int i = 0; i < _width; ++i) {
      if (i < activeWidth) {
        out += _backgroundActive;
      } else {
        out += _backgroundInactive;
      }
    }

    return '$out | $percent%';
  }
}
