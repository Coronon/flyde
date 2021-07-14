import 'dart:io';

typedef FileSystemEntityMatcher<T> = T? Function(FileSystemEntity entity);

/// A matcher function for `searchDirectory` which filters all `File`s.
File? fileMatcher(FileSystemEntity entity) {
  if (entity is File) {
    return entity;
  }

  return null;
}

/// Searches a [directory] and returns all items conforming to the conditions of [matcher].
///
/// [matcher] is a callback which can filter items by returning `null` and transforming them to
/// the required type. The general search is recursive.
Future<List<T>> searchDirectory<T>(Directory directory, FileSystemEntityMatcher<T> matcher) async {
  if (!await directory.exists()) {
    return [];
  }

  return (await directory.list(recursive: true).toList())
      .map((c) => matcher(c))
      .where((c) => c != null)
      .map((c) => c as T)
      .toList();
}
