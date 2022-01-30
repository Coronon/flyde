/// Extension on [String] to convert it to bold text in the terminal.
extension Bold on String {
  /// Adds the required ANSI codes to display bold text in the terminal.
  String get bold {
    return '\x1B[1m$this\x1B[22m';
  }
}
