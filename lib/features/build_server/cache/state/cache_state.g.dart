// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CacheState _$CacheStateFromJson(Map<String, dynamic> json) {
  return CacheState(
    projects:
        (json['projects'] as List<dynamic>).map((e) => e as String).toSet(),
  );
}

Map<String, dynamic> _$CacheStateToJson(CacheState instance) =>
    <String, dynamic>{
      'projects': instance.projects.toList(),
    };
