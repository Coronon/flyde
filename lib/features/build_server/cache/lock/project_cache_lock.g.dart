// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_cache_lock.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectCacheLock _$ProjectCacheLockFromJson(Map<String, dynamic> json) {
  return ProjectCacheLock(
    configs: (json['configs'] as List<dynamic>)
        .map((e) => ConfigLock.fromJson(e as Map<String, dynamic>))
        .toSet(),
    files: (json['files'] as List<dynamic>)
        .map((e) => SourceFileLock.fromJson(e as Map<String, dynamic>))
        .toSet(),
  );
}

Map<String, dynamic> _$ProjectCacheLockToJson(ProjectCacheLock instance) =>
    <String, dynamic>{
      'configs': instance.configs.toList(),
      'files': instance.files.toList(),
    };
