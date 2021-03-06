import 'package:test/test.dart';

import 'package:flyde/core/console/text_alignment.dart';
import 'package:flyde/features/ui/render/widget.dart';
import 'package:flyde/features/ui/widgets/table.dart';

import '../../../helpers/mocks/mock_widget.dart';

/// Creates an equivalent of a table divider width given [length]
String _verticalDivider(int length) => '\x1B[1m\x1B[37m${''.padRight(length, '─')}\x1B[0m\x1B[0m';

/// Creates a [Table] object for testing with stateless content
Table _createTestTable({int cellWidth = 20, TextAlignment alignment = TextAlignment.left}) {
  return Table(
    head: [
      MockWidget(State('head1'), straightForwardContent: true),
      MockWidget(State('head2'), straightForwardContent: true),
      MockWidget(State('head3'), straightForwardContent: true),
    ],
    body: [
      [
        MockWidget(State('body1.1'), straightForwardContent: true),
        MockWidget(State('body1.2'), straightForwardContent: true),
        MockWidget(State('body1.3'), straightForwardContent: true),
      ],
      [
        MockWidget(State('body2.1'), straightForwardContent: true),
        MockWidget(State('body2.2'), straightForwardContent: true),
        MockWidget(State('body2.3'), straightForwardContent: true),
      ],
    ],
    cellWidth: cellWidth,
    bodyAlignment: alignment,
  );
}

void main() {
  final verticalSpacer = '\x1B[1m\x1B[37m │ \x1B[0m\x1B[0m';

  test('Does not accept faulty parameters for initialization', () {
    expect(
      () => Table(head: [], body: []),
      throwsA(
        isA<ArgumentError>().having(
          (ArgumentError error) => error.message,
          'message',
          equals('Table requires the header cells to contain at least one element.'),
        ),
      ),
    );

    expect(
      () => Table(
        head: [
          MockWidget(State('a')),
          MockWidget(State('a')),
        ],
        body: [
          [
            MockWidget(State('a')),
            MockWidget(State('a')),
          ],
          [
            MockWidget(State('a')),
          ]
        ],
      ),
      throwsA(
        isA<ArgumentError>().having(
          (ArgumentError error) => error.message,
          'message',
          equals('Each row has to contain the same amount of widgets as the header.'),
        ),
      ),
    );
  });

  test('Creates expected children with default layout', () {
    final table = _createTestTable();
    final displayedChildren = table.children;

    expect(displayedChildren, hasLength(5));
    expect(
      displayedChildren[0].render(),
      equals(
        '        head1       $verticalSpacer        head2       $verticalSpacer        head3       ',
      ),
    );
    expect(
      displayedChildren[1].render(),
      equals(_verticalDivider(20 * 3 + 3 * 2)),
    );
    expect(
      displayedChildren[2].render(),
      equals(
        'body1.1             ${verticalSpacer}body1.2             ${verticalSpacer}body1.3             ',
      ),
    );
    expect(
      displayedChildren[3].render(),
      equals(_verticalDivider(20 * 3 + 3 * 2)),
    );
    expect(
      displayedChildren[4].render(),
      equals(
        'body2.1             ${verticalSpacer}body2.2             ${verticalSpacer}body2.3             ',
      ),
    );
  });

  test('Creates expected children with centered body', () {
    final table = _createTestTable(alignment: TextAlignment.center);
    final displayedChildren = table.children;

    expect(displayedChildren, hasLength(5));
    expect(
      displayedChildren[0].render(),
      equals(
        '        head1       $verticalSpacer        head2       $verticalSpacer        head3       ',
      ),
    );
    expect(
      displayedChildren[1].render(),
      equals(_verticalDivider(20 * 3 + 3 * 2)),
    );
    expect(
      displayedChildren[2].render(),
      equals(
        '       body1.1      $verticalSpacer       body1.2      $verticalSpacer       body1.3      ',
      ),
    );
    expect(
      displayedChildren[3].render(),
      equals(_verticalDivider(20 * 3 + 3 * 2)),
    );
    expect(
      displayedChildren[4].render(),
      equals(
        '       body2.1      $verticalSpacer       body2.2      $verticalSpacer       body2.3      ',
      ),
    );
  });

  test('Creates expected children with right-side layout', () {
    final table = _createTestTable(alignment: TextAlignment.right);
    final displayedChildren = table.children;

    expect(displayedChildren, hasLength(5));
    expect(
      displayedChildren[0].render(),
      equals(
        '        head1       $verticalSpacer        head2       $verticalSpacer        head3       ',
      ),
    );
    expect(
      displayedChildren[1].render(),
      equals(_verticalDivider(20 * 3 + 3 * 2)),
    );
    expect(
      displayedChildren[2].render(),
      equals(
        '             body1.1$verticalSpacer             body1.2$verticalSpacer             body1.3',
      ),
    );
    expect(
      displayedChildren[3].render(),
      equals(_verticalDivider(20 * 3 + 3 * 2)),
    );
    expect(
      displayedChildren[4].render(),
      equals(
        '             body2.1$verticalSpacer             body2.2$verticalSpacer             body2.3',
      ),
    );
  });

  test('Creates expected children with different cell width', () {
    final table = _createTestTable(cellWidth: 10);
    final displayedChildren = table.children;

    expect(displayedChildren, hasLength(5));
    expect(
      displayedChildren[0].render(),
      equals(
        '   head1  $verticalSpacer   head2  $verticalSpacer   head3  ',
      ),
    );
    expect(
      displayedChildren[1].render(),
      equals(_verticalDivider(10 * 3 + 3 * 2)),
    );
    expect(
      displayedChildren[2].render(),
      equals(
        'body1.1   ${verticalSpacer}body1.2   ${verticalSpacer}body1.3   ',
      ),
    );
    expect(
      displayedChildren[3].render(),
      equals(_verticalDivider(10 * 3 + 3 * 2)),
    );
    expect(
      displayedChildren[4].render(),
      equals(
        'body2.1   ${verticalSpacer}body2.2   ${verticalSpacer}body2.3   ',
      ),
    );
  });

  test('Sets the min and max width of the child widget acccording to the cell width', () {
    final cellWidth = 10;
    final table = _createTestTable(cellWidth: cellWidth);
    final displayedChildren = table.children;

    // Three cells per row and two dividers with length 3
    final rowWidth = cellWidth * 3 + 2 * 3;

    for (final child in displayedChildren) {
      expect(child.maxWidth, equals(rowWidth));
      expect(child.minWidth, equals(rowWidth));
    }
  });
}
