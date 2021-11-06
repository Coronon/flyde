// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'process_completion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProcessCompletionMessage _$ProcessCompletionMessageFromJson(
        Map<String, dynamic> json) =>
    ProcessCompletionMessage(
      process: _$enumDecode(_$CompletableProcessEnumMap, json['process']),
      description: json['description'] as String,
    );

Map<String, dynamic> _$ProcessCompletionMessageToJson(
        ProcessCompletionMessage instance) =>
    <String, dynamic>{
      'process': _$CompletableProcessEnumMap[instance.process],
      'description': instance.description,
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

const _$CompletableProcessEnumMap = {
  CompletableProcess.projectInit: 'projectInit',
  CompletableProcess.fileUpdate: 'fileUpdate',
};
