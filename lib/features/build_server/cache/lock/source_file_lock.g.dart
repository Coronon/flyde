// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'source_file_lock.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SourceFileLock _$SourceFileLockFromJson(Map<String, dynamic> json) {
  return SourceFileLock(
    id: json['id'] as String,
    hash: json['hash'] as String,
    path: json['path'] as String,
  );
}

Map<String, dynamic> _$SourceFileLockToJson(SourceFileLock instance) =>
    <String, dynamic>{
      'id': instance.id,
      'hash': instance.hash,
      'path': instance.path,
    };
