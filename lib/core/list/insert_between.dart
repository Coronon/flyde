/// Extension which implements [insertBetween].
extension InsertBetween<T> on Iterable<T> {
  /// Inserts an element between the existing ones and returns a new [Iterable] without modifying the object.
  ///
  /// ```dart
  /// Iterable<String> list = ['red', 'green', 'blue'];
  /// list.insertBetween('color'); // ['red', 'color', 'green', 'color', 'blue']
  /// ```
  Iterable<T> insertBetween(T element) {
    if (isEmpty) return this;

    final out = <T>[first];

    for (final item in List.from(this).getRange(1, length)) {
      out.addAll([element, item]);
    }

    return out;
  }
}
