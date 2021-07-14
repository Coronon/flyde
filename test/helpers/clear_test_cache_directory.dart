import 'dart:io';

Future<void> clearTestCacheDirectory() async {
  final dir = Directory('./flyde-test-lib');

  if (!await dir.exists()) {
    await dir.create();
  }

  final items = await dir.list(recursive: false).toList();

  for (final entity in items) {
    await entity.delete(recursive: true);
  }
}
