import 'dart:io';

Future<void> clearTestCacheDirectory({String id = ''}) async {
  final suffix = '${id.isNotEmpty ? '-' : ''}$id';
  final dir = Directory('./flyde-test-lib$suffix');

  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }
}
