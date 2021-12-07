import 'dart:async';
import 'dart:io';

import '../../../core/console/displayed_length.dart';
import '../../../core/console/cursor.dart';
import 'widget.dart';

/// A [Scene] is the default renderer for [Widget]s.
///
/// [Scene] renders and displays [Widget]s on the
/// standard output. For [Scene] to work properly
/// [stdout] has to have a terminal attached.
class Scene {
  /// [List] of widgets to display.
  ///
  /// Contains all [Widget]s, which can be more
  /// than passed to the constructor if one of them
  /// is a [ContainerWidget].
  final List<Widget> _widgets = [];

  /// A [StreamController] to manage the stream of update requests on state
  /// changes of single [Widget]s.
  final StreamController<WidgetUpdateRequest> _updateController = StreamController();

  /// [IOSink] to use for rendered output.
  ///
  /// Default is [stdout]
  final IOSink _outStream;

  /// Fallback for number of available columns if [_outStream] has no terminal attached.
  final int _fallbackTerminalColumns;

  /// Creates a new [Scene] with the given [widgets].
  ///
  /// If output is not specified [stdout] will be used and
  /// a value for [fallbackTerminalColumns] must be passed. Otherwise a
  /// default value of 200 available columns will be used.
  Scene(List<Widget> widgets, {IOSink? output, int? fallbackTerminalColumns})
      : _outStream = output ?? stdout,
        _fallbackTerminalColumns = fallbackTerminalColumns ?? 200 {
    _updateController.stream.listen(_handleUpdateRequest);

    _importWidgets(widgets);
    _setup();
  }

  /// Redraws the parts of the scene which are affeced by the change
  /// of the [Widget] specified in [request].
  void _handleUpdateRequest(WidgetUpdateRequest request) {
    final int lineDifference = (request.line - _widgets.length).abs();
    final int width = _outStream == stdout ? stdout.terminalColumns : _fallbackTerminalColumns;
    final String newContent = _safeRender(_widgets[request.line]).padRight(width);

    hideCursor(sink: _outStream);
    moveUp(lineDifference, sink: _outStream);
    _outStream.write(newContent);
    moveDown(lineDifference, sink: _outStream);
    showCursor(sink: _outStream);
  }

  /// Imports all [Widget]s contained in [widgets] and
  /// possible children of [ContainerWidget]s.
  void _importWidgets(List<Widget> widgets) {
    for (final widget in widgets) {
      if (widget is ContainerWidget) {
        _importWidgets(widget.children);
      } else {
        _widgets.add(widget);
      }
    }
  }

  /// Gives each [Widget] the corresponding line number and
  /// if neccessary connects the notification stream.
  void _setup() {
    int line = 0;

    for (final widget in _widgets) {
      widget.line = line++;

      if (widget is StatefulWidget) {
        widget.updateRequestReceiver = _updateController.sink;
      }

      if (widget is InlineWidget) {
        widget.syncBody();
      }
    }
  }

  /// Renders the passed [widget] and ensures that it meets it's expected
  /// dimensions.
  ///
  /// If the [widget] is wider or smaller than expected a [StateError] will be thrown.
  String _safeRender(Widget widget) {
    final String content = widget.render();
    final int length = content.displayedLength;

    if (widget.maxWidth != null && widget.maxWidth! > length) {
      throw StateError(
        'The widget is smaller than expected. Expected: ${widget.maxWidth!}. Actual: $length',
      );
    }

    if (widget.minWidth != null && widget.minWidth! < length) {
      throw StateError(
        'The widget is wider than expected. Expected: ${widget.maxWidth!}. Actual: $length',
      );
    }

    return content;
  }

  /// Initially displays the [Scene] on the standard output.
  void show() {
    for (final widget in _widgets) {
      _outStream.write(_safeRender(widget));
      _outStream.write('\n');
    }
  }
}
