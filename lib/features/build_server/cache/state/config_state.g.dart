// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConfigState _$ConfigStateFromJson(Map<String, dynamic> json) => ConfigState(
      checksum: json['checksum'] as String,
      compiledFiles: (json['compiledFiles'] as List<dynamic>)
          .map((e) => e as String)
          .toSet(),
      dependencyGraph: DependencyGraph.fromJson(
          json['dependencyGraph'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ConfigStateToJson(ConfigState instance) =>
    <String, dynamic>{
      'checksum': instance.checksum,
      'compiledFiles': instance.compiledFiles.toList(),
      'dependencyGraph': instance.dependencyGraph,
    };
