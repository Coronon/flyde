import 'dart:async';

import 'package:meta/meta.dart';

/// [Widget] is the base type for each UI component.
///
/// A [Widget] occupies a single line in the terminal.
/// For multiline [Widget]s see [ContainerWidget].
/// For multiple widgets on the same line see [InlineWidget].
abstract class Widget {
  /// The line where the widget is displayed.
  ///
  /// The value has to be set by the renderer (normally [Scene])
  late int line;

  /// The expected minimum width of the widget.
  ///
  /// This property is expected to be set by an higher order widget,
  /// which expects it's child widgets to meet a specific width.
  int? minWidth;

  /// The expected maximum width of the widget.
  ///
  /// This property is expected to be set by an higher order widget,
  /// which expects it's child widgets to meet a specific width.
  int? maxWidth;

  /// The method used to convert the abstract state of a
  /// component into a displayable [String]s.
  /// The returned value may or may not contain ANSI escape sequences.
  String render();
}

/// Base type for [Widget]s which intend to display many other [Widget]s on
/// one line.
abstract class InlineWidget extends Widget with StatefulWidget {
  /// A [List] of [Widget]s which are displayed on a single line.
  final List<Widget> body;

  InlineWidget(this.body);

  /// The method must be called by the render engine, to attach
  /// [Widget]s in [body] to the notification stream used by stateful [Widget]s.
  void syncBody() {
    for (final child in body) {
      child.line = line;

      if (child is StatefulWidget) {
        child.updateRequestReceiver = updateRequestReceiver;
      }
    }
  }
}

/// Base type for [Widget]s which intend to display many other [Widget]s on
/// multiple lines.
mixin ContainerWidget on Widget {
  /// A [List] of child [Widget]s.
  ///
  /// Unlike normal widgets, a [ContainerWidget] is not! rendered directly.
  /// Instead the [children] of the container are rendered.
  /// Therefore a container doesn't add content to it's output but rather creates
  /// children which provide the content and react to state changes.
  List<Widget> get children;

  /// Calling the [render] method of a container will result in a [StateError].
  ///
  /// Unlike normal widgets, a [ContainerWidget] is not! rendered directly.
  /// Instead the [children] of the container are rendered.
  /// Therefore a container doesn't add content to it's output but rather creates
  /// children which provide the content and react to state changes.
  @nonVirtual
  @override
  String render() => throw StateError(
        'Rendering a ContainerWidget is not allowed. Render each widget of ContainerWidget::children instead.',
      );
}

/// [StatefulWidget]s can react to changes of [State] fields.
///
/// Use this mixin when displaying content which changes over time.
///
/// Each [State] field must register the wiget it's used on, to inform
/// about changes.
/// ```dart
/// class Example extends Widget with StatefulWidget {
///   final State<int> _counter;
///
///   Example(this._counter) {
///     _counter.subscribe(this);
///   }
/// }
/// ```
mixin StatefulWidget on Widget {
  /// Notification sink which is used to inform the render engine to re-render this [Widget].
  ///
  /// Must be set by the render engine.
  late StreamSink<WidgetUpdateRequest> updateRequestReceiver;

  /// Called by each [State] field on value changes.
  ///
  /// Do not call directly to avoid unneccessary redraws.
  void _requestUpdate() {
    updateRequestReceiver.add(WidgetUpdateRequest(line, this));
  }
}

/// A wrapper type for fields of [Widget]s which should respond to value changes.
///
/// When used inside a [StatefulWidget] the [Widget] re-renders when
/// the [value] of the [State] changes.
class State<T> {
  /// The underlying value of the [State] object.
  T _value;

  /// A [List] of all subscribed [StatefulWidget]s.
  ///
  /// Every available [Widget] will be informed about [value] changes.
  final List<StatefulWidget> _subscribers = [];

  State(this._value);

  /// The underlying value of the [State] object.
  T get value => _value;

  /// The underlying value of the [State] object.
  ///
  /// Changes will trigger a re-render.
  set value(T val) {
    _value = val;

    for (final subscriber in _subscribers) {
      subscriber._requestUpdate();
    }
  }

  /// This method has to called by every [Widget] which
  /// should be informed about changes.
  void subscribe(StatefulWidget widget) {
    _subscribers.add(widget);
  }
}

/// A request sent by a [StatefulWidget] to it's render engine
/// to trigger a re-render of the specific widget.
class WidgetUpdateRequest {
  /// The line where the [Widget] is located.
  final int line;

  /// The [Widget] which requests a re-render.
  final Widget widget;

  WidgetUpdateRequest(this.line, this.widget);
}
