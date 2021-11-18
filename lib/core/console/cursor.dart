import 'dart:io';

/// Writes a sequence to [sink] or [stdout] which
/// moves the cursor to the start of the previous line.
void moveUp(int lines, {StringSink? sink}) {
  (sink ?? stdout).write('\x1B[${lines}F');
}

/// Writes a sequence to [sink] or [stdout] which
/// moves the cursor to the start of the next line.
void moveDown(int lines, {StringSink? sink}) {
  (sink ?? stdout).write('\x1B[${lines}E');
}

/// Writes a sequence to [sink] or [stdout] which
/// clears the current line.
void clearLine({StringSink? sink}) {
  (sink ?? stdout).write('\x1B[2K');
}

/// Writes a sequence to [sink] or [stdout] which
/// hides the cursor.
void hideCursor({StringSink? sink}) {
  (sink ?? stdout).write('\x1B[?25l');
}

/// Writes a sequence to [sink] or [stdout] which
/// shows the cursor.
void showCursor({StringSink? sink}) {
  (sink ?? stdout).write('\x1B[?25h');
}
