import 'package:json_annotation/json_annotation.dart';

part 'project_init.g.dart';

/// Request to reserve a space in the queue for a project.
const reserveBuildRequest = 'reserve_build_request';

/// Response that informs a client that it can now send
/// build requests.
const isActiveSessionResponse = 'is_active_session_response';

/// Response that informs a client that it has to wait until
/// it can send build requests.
const isInactiveSessionResponse = 'is_inactive_session_response';

/// Frees the reservation for the project and allows other clients to make
/// requests.
///
/// No more build requests can be sent afterwards.
const unsubscribeRequest = 'unsubscribe_request';

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
