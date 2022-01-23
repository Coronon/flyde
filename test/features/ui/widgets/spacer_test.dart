import 'package:test/test.dart';

import 'package:flyde/features/ui/widgets/label.dart';
import 'package:flyde/features/ui/widgets/spacer.dart';

void main() {
  test('Resolves to label widgets', () {
    final spacer = Spacer();

    expect(spacer.children, hasLength(1));
    expect(spacer.children.first, isA<Label>());
    expect(spacer.children.first.render(), equals(''));
  });

  test('Scales with requested lines', () {
    final spacer = Spacer(4);

    expect(spacer.children, hasLength(4));

    for (final child in spacer.children) {
      expect(child, isA<Label>());
      expect(child.render(), equals(''));
    }
  });
}
