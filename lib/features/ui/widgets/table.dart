import '../../../core/console/text_alignment.dart';
import '../../../core/list/insert_between.dart';
import '../render/widget.dart';
import 'label.dart';
import 'line.dart';

/// Creates a table like widget with cell dividers and fixed cell width.
///
/// ```dart
///Table(
///  bodyAlignment: TextAlignment.center,
///  cellWidth: 40,
///  head: [
///    Label.constant('Item1', bold: true),
///    Label.constant('Item1', bold: true),
///    Label.constant('Item1', bold: true),
///  ],
///  body: [
///    [
///      Label.constant('Child1.1'),
///      Label.constant('Child1.2'),
///      Label.constant('Child1.3'),
///    ],
///    [
///      Label.constant('Child2.1'),
///      Label.constant('Child2.2'),
///      Label.constant('Child2.3'),
///    ]
///  ],
///);
/// ```
///
/// renders to
///
///```bash
///                  Item1                  │                   Item1                  │                   Item1
///──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
///                Child1.1                 │                 Child1.2                 │                 Child1.3
///──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
///                Child2.1                 │                 Child2.2                 │                 Child2.3
/// ```
class Table extends Widget with ContainerWidget {
  /// The [Widget]s used to create the head row.
  final List<Widget> _head;

  /// A list of [Widget]s for each row.
  final List<List<Widget>> _body;

  /// The width of each table cell.
  final int _cellWidth;

  /// The alignment of the cell in the body section.
  final TextAlignment _bodyAlignment;

  Table(
      {required List<Widget> head,
      required List<List<Widget>> body,
      int cellWidth = 20,
      TextAlignment bodyAlignment = TextAlignment.left})
      : _head = head,
        _body = body,
        _cellWidth = cellWidth,
        _bodyAlignment = bodyAlignment {
    if (_head.isEmpty) {
      throw ArgumentError('Table requires the header cells to contain at least one element.');
    }

    for (final row in _body) {
      if (row.length != _head.length) {
        throw ArgumentError('Each row has to contain the same amount of widgets as the header.');
      }
    }
  }

  @override
  List<Widget> get children {
    return [
      Line(_head, _verticalDivider, width: _cellWidth, alignment: TextAlignment.center),
      _horizontalDivider,
      ..._composeBody()
    ];
  }

  /// Creates the table rows and inserts the dividing lines.
  Iterable<Widget> _composeBody() {
    final Iterable<Widget> rows = _body.map(
      (row) => Line(row, _verticalDivider, width: _cellWidth, alignment: _bodyAlignment),
    );

    return rows.insertBetween(_horizontalDivider);
  }

  /// The [Widget] used to divide cells vertically.
  Widget get _horizontalDivider {
    // Combined width of each cell + combined width of the dividers.
    final int totalLineWidth = _cellWidth * _head.length + (_head.length - 1) * 3;

    return Label.constant(
      ''.padRight(totalLineWidth, '─'),
      bold: true,
    );
  }

  static Widget get _verticalDivider => Label.constant(' │ ', bold: true);
}
