import 'package:json_annotation/json_annotation.dart';

part 'authentication.g.dart';

/// Representation of an authentication request
@JsonSerializable()
class AuthRequest {
  /// Username to authenticate with
  final String username;

  /// Corresponding password
  final String password;

  const AuthRequest({required this.username, required this.password});

  factory AuthRequest.fromJson(Map<String, dynamic> json) => _$AuthRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AuthRequestToJson(this);
}

/// All possible [AuthResponse] types
enum AuthResponseStatus {
  required,
  success,
  failure,
}

/// Representation of an authentication response
///
/// Send in response to or lack of [AuthRequest].
@JsonSerializable()
class AuthResponse {
  /// Type of [AuthResponse]
  ///
  /// [AuthResponseStatus.required] if no [AuthRequest] recieved
  /// before initial protoco message.
  final AuthResponseStatus status;

  const AuthResponse({required this.status});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}
