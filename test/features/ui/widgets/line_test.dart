import 'package:flyde/core/console/text_alignment.dart';
import 'package:flyde/features/ui/render/widget.dart';
import 'package:flyde/features/ui/widgets/line.dart';
import 'package:test/test.dart';

import '../../../helpers/mocks/mock_widget.dart';

void main() {
  test('Concatenates all body elements', () {
    final line = Line(
      [
        MockWidget(State('hi'), straightForwardContent: true),
        MockWidget(State('bye'), straightForwardContent: true),
      ],
      MockWidget(State('|'), straightForwardContent: true),
    );

    expect(line.render(), equals('hi|bye'));
  });

  test('Scales body elements on fixed width', () {
    final leftAligned = Line(
      [
        MockWidget(State('hi'), straightForwardContent: true),
        MockWidget(State('bye'), straightForwardContent: true),
      ],
      MockWidget(State('|'), straightForwardContent: true),
      alignment: TextAlignment.left,
      width: 5,
    );
    final centerAligned = Line(
      [
        MockWidget(State('hi'), straightForwardContent: true),
        MockWidget(State('bye'), straightForwardContent: true),
      ],
      MockWidget(State('|'), straightForwardContent: true),
      alignment: TextAlignment.center,
      width: 5,
    );
    final rightAligned = Line(
      [
        MockWidget(State('hi'), straightForwardContent: true),
        MockWidget(State('bye'), straightForwardContent: true),
      ],
      MockWidget(State('|'), straightForwardContent: true),
      alignment: TextAlignment.right,
      width: 5,
    );

    expect(leftAligned.render(), equals('hi   |bye  '));
    expect(rightAligned.render(), equals('   hi|  bye'));
    expect(centerAligned.render(), equals(' hi  | bye '));
  });

  test('Fails when used with container elements', () {
    final line = Line(
      [
        MockWidget(State('hi'), straightForwardContent: true),
        MockWidget(State('bye'), straightForwardContent: true),
        MockContainer(State('')),
      ],
      MockWidget(State('|'), straightForwardContent: true),
    );

    expect(line.render, throwsStateError);
  });
}
