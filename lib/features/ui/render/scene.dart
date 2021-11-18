import 'dart:async';
import 'dart:io';

import 'package:flyde/core/console/cursor.dart';
import 'package:flyde/features/ui/render/widget.dart';

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

  final IOSink _outStream;

  Scene(List<Widget> widgets, {IOSink? output}) : _outStream = output ?? stdout {
    _updateController.stream.listen(_handleUpdateRequest);

    _importWidgets(widgets);
    _setup();
  }

  /// Redraws the parts of the scene which are affeced by the change
  /// of the [Widget] specified in [request].
  void _handleUpdateRequest(WidgetUpdateRequest request) {
    final int lineDifference = (request.line - _widgets.length).abs();
    final int width = _outStream == stdout ? stdout.terminalColumns : 200;
    final newContent = _widgets[request.line].render().padRight(width);

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

  /// Initially displays the [Scene] on the standard output.
  void show() {
    for (final widget in _widgets) {
      _outStream.write(widget.render());
      _outStream.write('\n');
    }
  }
}
