import 'package:json_annotation/json_annotation.dart';

part 'authentication.g.dart';

@JsonSerializable()
class AuthRequest {
  final String username;
  final String password;

  const AuthRequest({required this.username, required this.password});

  factory AuthRequest.fromJson(Map<String, dynamic> json) => _$AuthRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AuthRequestToJson(this);
}

enum AuthResponseStatus {
  required,
  success,
  failure,
}

@JsonSerializable()
class AuthResponse {
  final AuthResponseStatus status;

  const AuthResponse({required this.status});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}
