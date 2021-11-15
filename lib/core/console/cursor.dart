import 'dart:io';

/// Writes a sequence to [stdout] which
/// moves the cursor to the start of the previous line.
void moveUp(int lines) {
  stdout.write('\x1B[${lines}F');
}

/// Writes a sequence to [stdout] which
/// moves the cursor to the start of the next line.
void moveDown(int lines) {
  stdout.write('\x1B[${lines}E');
}

/// Writes a sequence to [stdout] which
/// clears the current line.
void clearLine() {
  stdout.write('\x1B[2K');
}

/// Writes a sequence to [stdout] which
/// hides the cursor.
void hideCursor() {
  stdout.write('\x1B[?25l');
}

/// Writes a sequence to [stdout] which
/// shows the cursor.
void showCursor() {
  stdout.write('\x1B[?25h');
}
