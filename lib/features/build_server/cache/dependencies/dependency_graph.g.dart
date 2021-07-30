// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dependency_graph.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DependencyGraph _$DependencyGraphFromJson(Map<String, dynamic> json) =>
    DependencyGraph(
      nodes: (json['nodes'] as List<dynamic>)
          .map((e) => _DependencyNode.fromJson(e as Map<String, dynamic>))
          .toSet(),
    );

Map<String, dynamic> _$DependencyGraphToJson(DependencyGraph instance) =>
    <String, dynamic>{
      'nodes': instance.nodes.toList(),
    };

_DependencyNode _$DependencyNodeFromJson(Map<String, dynamic> json) =>
    _DependencyNode(
      id: json['id'] as String,
      dependencies: (json['dependencies'] as List<dynamic>)
          .map((e) => e as String)
          .toSet(),
      dependents:
          (json['dependents'] as List<dynamic>).map((e) => e as String).toSet(),
    );

Map<String, dynamic> _$DependencyNodeToJson(_DependencyNode instance) =>
    <String, dynamic>{
      'id': instance.id,
      'dependencies': instance.dependencies.toList(),
      'dependents': instance.dependents.toList(),
    };
