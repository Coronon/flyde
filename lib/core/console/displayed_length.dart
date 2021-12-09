/// Removes all ANSI sequences from [str] and returns it's resulting length
int getDisplayedLength(String str) {
  return str.replaceAll(RegExp('\x1B[[0-9]+[a-zA-Z]'), '').length;
}

extension DisplayedLength on String {
  /// The length of this [String] without ANSI escape sequences
  int get displayedLength => getDisplayedLength(this);
}
