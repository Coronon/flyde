// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compile_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompileStatusMessage<T> _$CompileStatusMessageFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    CompileStatusMessage<T>(
      status: _$enumDecode(_$CompileStatusEnumMap, json['status']),
      payload: fromJsonT(json['payload']),
    );

Map<String, dynamic> _$CompileStatusMessageToJson<T>(
  CompileStatusMessage<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'status': _$CompileStatusEnumMap[instance.status],
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

const _$CompileStatusEnumMap = {
  CompileStatus.waiting: 'waiting',
  CompileStatus.compiling: 'compiling',
  CompileStatus.linking: 'linking',
  CompileStatus.done: 'done',
  CompileStatus.failed: 'failed',
};
