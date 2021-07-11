import 'package:json_annotation/json_annotation.dart';

part 'authentication.g.dart';

@JsonSerializable()
class AuthRequest {
  String username;
  String password;

  AuthRequest({required this.username, required this.password});

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
  AuthResponseStatus status;

  AuthResponse({required this.status});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}
