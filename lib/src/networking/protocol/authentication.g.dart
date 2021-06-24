// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authentication.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AUTH_REQUEST _$AUTH_REQUESTFromJson(Map<String, dynamic> json) {
  return AUTH_REQUEST(
    username: json['username'] as String,
    password: json['password'] as String,
  );
}

Map<String, dynamic> _$AUTH_REQUESTToJson(AUTH_REQUEST instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
    };

AUTH_RESPONSE _$AUTH_RESPONSEFromJson(Map<String, dynamic> json) {
  return AUTH_RESPONSE(
    status: _$enumDecode(_$AUTH_RESPONSE_STATUSEnumMap, json['status']),
  );
}

Map<String, dynamic> _$AUTH_RESPONSEToJson(AUTH_RESPONSE instance) =>
    <String, dynamic>{
      'status': _$AUTH_RESPONSE_STATUSEnumMap[instance.status],
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

const _$AUTH_RESPONSE_STATUSEnumMap = {
  AUTH_RESPONSE_STATUS.AUTH_REQUIRED: 'AUTH_REQUIRED',
  AUTH_RESPONSE_STATUS.SUCCESS: 'SUCCESS',
  AUTH_RESPONSE_STATUS.FAILURE: 'FAILURE',
};
