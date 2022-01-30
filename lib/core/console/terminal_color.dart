/// Enumeration of colors available in standard terminals.
enum TerminalColor {
  white,
  red,
  green,
  blue,
  yellow,
  cyan,
  magenta,
  black,
  none,
}

/// Implementation of [TerminalColor] to support [String] manipulation.
extension TerminalColorImpl on TerminalColor {
  /// Prepares [output] to be displayed colorful on the terminal.
  String prepare(String output) {
    switch (this) {
      case TerminalColor.white:
        return '\x1B[37m$output\x1B[39m';
      case TerminalColor.red:
        return '\x1B[31m$output\x1B[39m';
      case TerminalColor.green:
        return '\x1B[32m$output\x1B[39m';
      case TerminalColor.blue:
        return '\x1B[34m$output\x1B[39m';
      case TerminalColor.yellow:
        return '\x1B[33m$output\x1B[39m';
      case TerminalColor.cyan:
        return '\x1B[36m$output\x1B[39m';
      case TerminalColor.magenta:
        return '\x1B[35m$output\x1B[39m';
      case TerminalColor.black:
        return '\x1B[30m$output\x1B[39m';
      case TerminalColor.none:
        return output;
    }
  }
}

/// Adds a method to [String] to support [TerminalColor] manipulation.
extension ColoredString on String {
  /// Prepares the string to be displayed colorful on the terminal
  /// using the [color] provided.
  String colored(TerminalColor color) => color.prepare(this);
}
