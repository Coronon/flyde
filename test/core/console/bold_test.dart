import 'package:test/test.dart';

import 'package:flyde/core/console/bold.dart';

void main() {
  test('Applies ANSI code to print bold text to string', () {
    expect('hello'.bold, equals('\x1B[1mhello\x1B[22m'));
  });
}
