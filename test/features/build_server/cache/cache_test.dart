import 'dart:io';

import 'package:flyde/features/build_server/cache/cache.dart';
import 'package:flyde/features/build_server/cache/project_cache.dart';
import 'package:test/test.dart';

import '../../../helpers/clear_test_cache_directory.dart';

const _cacheId = 'cache_test';
const _cachePath = './flyde-test-lib-$_cacheId';

void main() {
  setUp(() async => await clearTestCacheDirectory(id: _cacheId));
  tearDown(() async => await clearTestCacheDirectory(id: _cacheId));

  test('Can load from disk', () async {
    await expectLater(Cache.load(from: Directory(_cachePath)), completion(isA<Cache>()));
  });

  test('Can create project caches', () async {
    final cache = await Cache.load(from: Directory(_cachePath));

    await expectLater(cache.create('test'), completion(isA<ProjectCache>()));

    final cacheLock = File('$_cachePath/cache/.lock.json');
    final pCacheLock = File('$_cachePath/cache/test/.lock.json');

    await expectLater(cacheLock.exists(), completion(equals(true)));
    await expectLater(pCacheLock.exists(), completion(equals(true)));
  });

  test('Can list all project caches', () async {
    final cache = await Cache.load(from: Directory(_cachePath));

    await cache.create('test');
    await cache.create('test-2');
    final projects = await cache.all;

    expect(cache.availableProjects, unorderedEquals({'test', 'test-2'}));
    expect(projects.length, equals(2));
  });

  test('Knows if it has a project cache', () async {
    final cache = await Cache.load(from: Directory(_cachePath));
    await cache.create('test');

    expect(cache.has('test'), equals(true));
    expect(cache.has('test-2'), equals(false));
  });

  test('Can remove a project cache', () async {
    final cache = await Cache.load(from: Directory(_cachePath));
    await cache.create('test');
    await cache.create('test-2');

    expect(cache.availableProjects, unorderedEquals({'test', 'test-2'}));
    await expectLater(cache.all, completion(hasLength(2)));
    await expectLater(cache.remove('test'), completion(isA<void>()));
    expect(cache.availableProjects, unorderedEquals({'test-2'}));
    expect(cache.has('test'), equals(false));
    await expectLater(cache.get('test'), throwsA(isA<ArgumentError>()));
    await expectLater(cache.all, completion(hasLength(1)));
    await expectLater(Directory('$_cachePath/cache/test').exists(), completion(equals(false)));
  });
}
