import 'dart:io';

import 'package:flyde/features/build_server/cache/project_cache.dart';
import 'package:test/test.dart';

import '../../../helpers/clear_test_cache_directory.dart';
import '../../../helpers/create_dummy_project_cache.dart';

const _cacheId = 'project_cache_test';
const _dummyProjectCachePath = './flyde-test-lib-$_cacheId/cache/testing';

void main() {
  setUp(() async => await clearTestCacheDirectory(id: _cacheId));
  tearDown(() async => await clearTestCacheDirectory(id: _cacheId));

  test('Creates state file on init', () async {
    await createDummyProjectCache(id: _cacheId);

    final state = File('$_dummyProjectCachePath/.state.json');
    final exists = await state.exists();

    expect(exists, true);
  });

  test('Can handle blank cache', () async {
    await createDummyProjectCache(id: _cacheId);
    await expectLater(createDummyProjectCache(id: _cacheId), completion(isA<ProjectCache>()));
  });
}
