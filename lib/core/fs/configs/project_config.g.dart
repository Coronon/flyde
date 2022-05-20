// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectConfig _$ProjectConfigFromJson(Map<String, dynamic> json) =>
    ProjectConfig(
      name: json['name'] as String,
      port: json['port'] as int,
      host: json['host'] as String,
    );

Map<String, dynamic> _$ProjectConfigToJson(ProjectConfig instance) =>
    <String, dynamic>{
      'name': instance.name,
      'port': instance.port,
      'host': instance.host,
    };
