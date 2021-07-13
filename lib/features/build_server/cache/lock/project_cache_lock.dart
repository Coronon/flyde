import 'package:json_annotation/json_annotation.dart';
import 'package:flyde/features/build_server/cache/lock/config_lock.dart';
import 'package:flyde/features/build_server/cache/lock/source_file_lock.dart';

part 'project_cache_lock.g.dart';

/// Model for project cache lock files.
/// The persisted state of  `ProjectCache` is
/// stored in an object of `ProjectCacheLock`.
@JsonSerializable()
class ProjectCacheLock {
  /// Set of available compilation configs.
  final Set<ConfigLock> configs;

  /// Set of latest project files.
  final Set<SourceFileLock> files;

  ProjectCacheLock({required this.configs, required this.files});

  factory ProjectCacheLock.fromJson(Map<String, dynamic> json) => _$ProjectCacheLockFromJson(json);

  Map<String, dynamic> toJson() => _$ProjectCacheLockToJson(this);
}
