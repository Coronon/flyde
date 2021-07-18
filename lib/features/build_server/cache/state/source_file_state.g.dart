// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'source_file_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SourceFileState _$SourceFileStateFromJson(Map<String, dynamic> json) {
  return SourceFileState(
    id: json['id'] as String,
    hash: json['hash'] as String,
    path: json['path'] as String,
  );
}

Map<String, dynamic> _$SourceFileStateToJson(SourceFileState instance) =>
    <String, dynamic>{
      'id': instance.id,
      'hash': instance.hash,
      'path': instance.path,
    };
