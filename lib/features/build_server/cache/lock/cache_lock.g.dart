// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_lock.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CacheLock _$CacheLockFromJson(Map<String, dynamic> json) {
  return CacheLock(
    projects:
        (json['projects'] as List<dynamic>).map((e) => e as String).toSet(),
  );
}

Map<String, dynamic> _$CacheLockToJson(CacheLock instance) => <String, dynamic>{
      'projects': instance.projects.toList(),
    };
