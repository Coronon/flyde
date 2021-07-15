import 'dart:io';

import 'package:flyde/features/build_server/cache/project_cache.dart';

Future<ProjectCache> createDummyProjectCache({bool init = true, String id = ''}) async {
  final suffix = '${id.isNotEmpty ? '-' : ''}$id';
  final cache = ProjectCache('testing', Directory('./flyde-test-lib$suffix/cache'));

  if (init) {
    await cache.init();
  }

  return cache;
}
