// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectUpdateRequest _$ProjectUpdateRequestFromJson(
        Map<String, dynamic> json) =>
    ProjectUpdateRequest(
      files: Map<String, String>.from(json['files'] as Map),
      config: CompilerConfig.fromJson(json['config'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ProjectUpdateRequestToJson(
        ProjectUpdateRequest instance) =>
    <String, dynamic>{
      'files': instance.files,
      'config': instance.config,
    };

ProjectUpdateResponse _$ProjectUpdateResponseFromJson(
        Map<String, dynamic> json) =>
    ProjectUpdateResponse(
      files: (json['files'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$ProjectUpdateResponseToJson(
        ProjectUpdateResponse instance) =>
    <String, dynamic>{
      'files': instance.files,
    };

FileUpdate _$FileUpdateFromJson(Map<String, dynamic> json) => FileUpdate(
      name: json['name'] as String,
      extension: json['extension'] as String,
      entry: json['entry'] as int,
      data: _intList2uint8List(json['data'] as String),
      path: (json['path'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$FileUpdateToJson(FileUpdate instance) =>
    <String, dynamic>{
      'name': instance.name,
      'extension': instance.extension,
      'entry': instance.entry,
      'path': instance.path,
      'data': _uint8List2intList(instance.data),
    };
