import 'package:flyde/features/ui/render/widget.dart';

class MockWidget extends Widget with StatefulWidget {
  final State<String> content;
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

class MockInline extends InlineWidget {
  MockInline(List<Widget> body) : super(body);

  @override
  String render() {
    return body.map((e) => e.render()).join('->');
  }
}

class MockContainer extends Widget with ContainerWidget {
  final State<String> content;

  MockContainer(this.content);

  @override
  List<Widget> get children => [MockWidget(content), MockWidget(content)];
}
