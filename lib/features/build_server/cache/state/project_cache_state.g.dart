// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_cache_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectCacheState _$ProjectCacheStateFromJson(Map<String, dynamic> json) {
  return ProjectCacheState(
    configs: (json['configs'] as List<dynamic>)
        .map((e) => ConfigState.fromJson(e as Map<String, dynamic>))
        .toSet(),
    files: (json['files'] as List<dynamic>)
        .map((e) => SourceFileState.fromJson(e as Map<String, dynamic>))
        .toSet(),
  );
}

Map<String, dynamic> _$ProjectCacheStateToJson(ProjectCacheState instance) =>
    <String, dynamic>{
      'configs': instance.configs.toList(),
      'files': instance.files.toList(),
    };
