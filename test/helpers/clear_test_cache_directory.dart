import 'dart:io';

/// Deletes the directry where tests could store their files.
///
/// If [id] is provided the suffix of the directory is generated automatically.
Future<void> clearTestCacheDirectory({String id = ''}) async {
  final suffix = '${id.isNotEmpty ? '-' : ''}$id';
  final dir = Directory('./flyde-test-lib$suffix');

  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }
}
