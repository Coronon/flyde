import 'package:json_annotation/json_annotation.dart';

part 'cache_lock.g.dart';

/// The model of the lock file for the cache.
/// Represents the persisted state of the cache.
@JsonSerializable()
class CacheLock {
  /// List of all project identifiers.
  final Set<String> projects;

  CacheLock({required this.projects});

  factory CacheLock.fromJson(Map<String, dynamic> json) => _$CacheLockFromJson(json);

  Map<String, dynamic> toJson() => _$CacheLockToJson(this);
}
