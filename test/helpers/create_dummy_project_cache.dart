import 'dart:io';

import 'package:flyde/features/build_server/cache/project_cache.dart';

/// Creates a dummy cache for testing.
///
/// If [id] is provided, the suffix of the cache directory is generated automatically.
/// If [init] is true, the cache will be initilized with additional files.
Future<ProjectCache> createDummyProjectCache({bool init = true, String id = ''}) async {
  final suffix = '${id.isNotEmpty ? '-' : ''}$id';
  final cache = ProjectCache('testing', Directory('./flyde-test-lib$suffix/cache'));

  if (init) {
    await cache.init();
  }

  return cache;
}
