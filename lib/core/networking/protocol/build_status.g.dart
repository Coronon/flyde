// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuildStatusMessage<T> _$BuildStatusMessageFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    BuildStatusMessage<T>(
      status: _$enumDecode(_$BuildStatusEnumMap, json['status']),
      payload: fromJsonT(json['payload']),
    );

Map<String, dynamic> _$BuildStatusMessageToJson<T>(
  BuildStatusMessage<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'status': _$BuildStatusEnumMap[instance.status],
      'payload': toJsonT(instance.payload),
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

const _$BuildStatusEnumMap = {
  BuildStatus.waiting: 'waiting',
  BuildStatus.compiling: 'compiling',
  BuildStatus.linking: 'linking',
  BuildStatus.done: 'done',
  BuildStatus.failed: 'failed',
};
