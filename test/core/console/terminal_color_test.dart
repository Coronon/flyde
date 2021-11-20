import 'package:flyde/core/console/terminal_color.dart';
import 'package:test/test.dart';

void main() {
  const testStrings = ['hello', 'world', 'Hello, World!'];

  test('Can prepare strings for being displayed colorful', () {
    for (final testStr in testStrings) {
      expect(
        TerminalColor.black.prepare(testStr),
        equals('\x1B[30m$testStr\x1B[0m'),
      );

      expect(
        TerminalColor.white.prepare(testStr),
        equals('\x1B[37m$testStr\x1B[0m'),
      );

      expect(
        TerminalColor.red.prepare(testStr),
        equals('\x1B[31m$testStr\x1B[0m'),
      );

      expect(
        TerminalColor.green.prepare(testStr),
        equals('\x1B[32m$testStr\x1B[0m'),
      );

      expect(
        TerminalColor.blue.prepare(testStr),
        equals('\x1B[34m$testStr\x1B[0m'),
      );

      expect(
        TerminalColor.yellow.prepare(testStr),
        equals('\x1B[33m$testStr\x1B[0m'),
      );

      expect(
        TerminalColor.cyan.prepare(testStr),
        equals('\x1B[36m$testStr\x1B[0m'),
      );

      expect(
        TerminalColor.magenta.prepare(testStr),
        equals('\x1B[35m$testStr\x1B[0m'),
      );
    }
  });
}
