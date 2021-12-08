import 'package:flyde/features/ui/render/widget.dart';

/// Mock implementation of [Widget] using [StatefulWidget].
///
/// The mock exposes a stateful [content] property and subscribes to
/// state changes.
///
/// The result of [render] is the state of content with the prefix `mock-`.
class MockWidget extends Widget with StatefulWidget {
  /// The stateful content of the widget.
  final State<String> content;

  /// If the flag is true, do not add the `mock-` prefix to the
  /// render output
  final bool straightForwardContent;

  MockWidget(this.content, {this.straightForwardContent = false}) {
    content.subscribe(this);
  }

  @override
  String render() {
    if (straightForwardContent) {
      return content.value;
    }

    return 'mock-${content.value}';
  }
}

/// Simple implementation of [InlineWidget].
///
/// The rendered output is the rendered body joined with `->`.
class MockInline extends InlineWidget {
  MockInline(List<Widget> body) : super(body);

  @override
  String render() {
    return body.map((e) => e.render()).join('->');
  }
}

/// Simple mock for [ContainerWidget].
///
/// The children property returns an array containing two [MockWidget]s with
/// the state of [content].
class MockContainer extends Widget with ContainerWidget {
  /// The state of the child widgets
  final State<String> content;

  MockContainer(this.content);

  @override
  List<Widget> get children => [MockWidget(content), MockWidget(content)];
}
