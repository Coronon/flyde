import 'dart:convert';
import 'dart:io';

import 'package:flyde/core/fs/standard_location.dart';
import 'package:flyde/features/build_server/cache/lock/cache_lock.dart';
import 'package:flyde/features/build_server/cache/project_cache.dart';
import 'package:path/path.dart';

/// Class to manage access to the compiler cache.
///
/// `Cache` allows to get, add and remove caches for projects
/// and takes core of the right location on disk as to initialize
/// the project caches.
///
/// Use the async static method `load` to get an instance of `Cache`.
/// ```dart
/// final cache = await Cache.load();
/// ```
class Cache {
  final Directory _workingDirectory;

  final CacheLock _lock;

  Cache._(this._workingDirectory, this._lock);

  /// Loads the cache from disk and returns an instance of `Cache`.
  static Future<Cache> load() async {
    final appLibPath = StandardLocation.applicationLibrary.directory.path;
    final workingDir = Directory(join(appLibPath, 'cache'));
    final lockFile = File(join(workingDir.path, '.lock.json'));
    late final CacheLock lock;

    await workingDir.create(recursive: true);

    if (await lockFile.exists()) {
      lock = CacheLock.fromJson(json.decode(await lockFile.readAsString()));
    } else {
      lock = CacheLock(projects: {});
    }

    return Cache._(workingDir, lock);
  }

  /// A list of all available project caches.
  Future<List<ProjectCache>> get all async {
    final projects = <ProjectCache>[];

    for (final available in availableProjects) {
      projects.add(await get(available));
    }

    return projects;
  }

  /// A list of all available project ids.
  Set<String> get availableProjects => {..._lock.projects};

  /// Permanently deletes the project cache with the given id [projectId].
  Future<void> remove(String projectId) async {
    _validateId(projectId);

    if (!has(projectId)) {
      throw Exception('No project with id $projectId exists.');
    }

    final dir = _getProjectDirectory(projectId);

    await dir.delete(recursive: true);
    _lock.projects.remove(projectId);
    await _save();
  }

  /// Creates and initializes a new project cache with the given id [projectId].
  Future<ProjectCache> create(String projectId) async {
    _validateId(projectId);

    if (has(projectId)) {
      throw Exception(
          'Project with id "$projectId" already exists. Consider choosing a different id.');
    }

    _lock.projects.add(projectId);
    await _save();
    return await get(projectId);
  }

  /// Loads and initializes the project cache with the given id [projectId].
  Future<ProjectCache> get(String projectId) async {
    _validateId(projectId);

    if (!has(projectId)) {
      throw Exception('No project with id $projectId exists.');
    }

    final project = ProjectCache(projectId, _workingDirectory);
    await project.init();
    return project;
  }

  /// Returns whether a cache with the [projectId] exists.
  bool has(String projectId) {
    _validateId(projectId);

    return _lock.projects.contains(projectId);
  }

  void _validateId(String projectId) {
    final regex = RegExp('[a-zA-Z0-9\-]+');
    final match = regex.stringMatch(projectId);

    if (match != projectId) {
      throw Exception(
          '"$projectId" is not a valid project id. The id has to match "[a-zA-Z0-9\-]+"');
    }
  }

  Directory _getProjectDirectory(String projectId) {
    return Directory(join(_workingDirectory.path, projectId));
  }

  Future<void> _save() async {
    final lockFile = File(join(_workingDirectory.path, '.lock.json'));
    await lockFile.writeAsString(json.encode(_lock.toJson()));
  }
}