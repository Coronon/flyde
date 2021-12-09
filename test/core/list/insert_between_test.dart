import 'package:flyde/core/list/insert_between.dart';
import 'package:test/test.dart';

void main() {
  test('Inserts elements at the right positions', () {
    const list = ['red', 'green', 'blue'];

    expect(
      list.insertBetween('color'),
      orderedEquals([
        'red',
        'color',
        'green',
        'color',
        'blue',
      ]),
    );
  });

  test('Can handle empty arrays', () {
    expect(<int>[].insertBetween(0), isEmpty);
  });
}
