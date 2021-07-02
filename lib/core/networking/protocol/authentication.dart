import 'package:json_annotation/json_annotation.dart';

part 'authentication.g.dart';

@JsonSerializable()
class AUTH_REQUEST {
  String username;
  String password;

  AUTH_REQUEST({required this.username, required this.password});

  factory AUTH_REQUEST.fromJson(Map<String, dynamic> json) => _$AUTH_REQUESTFromJson(json);
  Map<String, dynamic> toJson() => _$AUTH_REQUESTToJson(this);
}

enum AUTH_RESPONSE_STATUS {
  AUTH_REQUIRED,
  SUCCESS,
  FAILURE,
}

@JsonSerializable()
class AUTH_RESPONSE {
  AUTH_RESPONSE_STATUS status;

  AUTH_RESPONSE({required this.status});

  factory AUTH_RESPONSE.fromJson(Map<String, dynamic> json) => _$AUTH_RESPONSEFromJson(json);
  Map<String, dynamic> toJson() => _$AUTH_RESPONSEToJson(this);
}
