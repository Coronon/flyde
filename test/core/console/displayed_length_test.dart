import 'package:flyde/core/console/bold.dart';
import 'package:flyde/core/console/displayed_length.dart';
import 'package:flyde/core/console/terminal_color.dart';
import 'package:test/test.dart';

void main() {
  const testStrings = ['hello', 'world', '42'];

  test('Can remove any ANSI codes from the string', () {
    for (final testStr in testStrings) {
      expect(
        getDisplayedLength(testStr.bold),
        equals(testStr.length),
      );

      expect(
        getDisplayedLength(TerminalColor.black.prepare(testStr)),
        equals(testStr.length),
      );
    }

    expect(
      getDisplayedLength('\x1B[2K'),
      equals(0),
    );
  });

  test('Works with string extension', () {
    expect(
      '\x1B[2K'.displayedLength,
      equals(0),
    );
  });
}
