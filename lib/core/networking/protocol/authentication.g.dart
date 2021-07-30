// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authentication.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthRequest _$AuthRequestFromJson(Map<String, dynamic> json) => AuthRequest(
      username: json['username'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$AuthRequestToJson(AuthRequest instance) => <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
    };

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
      status: _$enumDecode(_$AuthResponseStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) => <String, dynamic>{
      'status': _$AuthResponseStatusEnumMap[instance.status],
    };

K _$enumDecode<K, V>(
  Map<K, V> enumValues,
  Object? source, {
  K? unknownValue,
}) {
  if (source == null) {
    throw ArgumentError(
      'A value must be provided. Supported values: '
      '${enumValues.values.join(', ')}',
    );
  }

  return enumValues.entries.singleWhere(
    (e) => e.value == source,
    orElse: () {
      if (unknownValue == null) {
        throw ArgumentError(
          '`$source` is not one of the supported values: '
          '${enumValues.values.join(', ')}',
        );
      }
      return MapEntry(unknownValue, enumValues.values.first);
    },
  ).key;
}

const _$AuthResponseStatusEnumMap = {
  AuthResponseStatus.required: 'required',
  AuthResponseStatus.success: 'success',
  AuthResponseStatus.failure: 'failure',
};
