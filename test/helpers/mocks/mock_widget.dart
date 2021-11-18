import 'package:flyde/features/ui/render/widget.dart';

class MockWidget extends Widget with StatefulWidget {
  final State<String> content;

  MockWidget(this.content) {
    content.subscribe(this);
  }

  @override
  String render() {
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
