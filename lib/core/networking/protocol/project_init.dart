import 'package:json_annotation/json_annotation.dart';

part 'project_init.g.dart';

/// Requests to initialize the project.
@JsonSerializable()
class ProjectInitRequest {
  /// The id of the project.
  ///
  /// Each unique id has a shared cache and resources.
  final String id;

  /// The name of the project.
  final String name;

  ProjectInitRequest({required this.id, required this.name});

  factory ProjectInitRequest.fromJson(Map<String, dynamic> json) =>
      _$ProjectInitRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ProjectInitRequestToJson(this);
}
