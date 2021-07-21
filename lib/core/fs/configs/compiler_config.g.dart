// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compiler_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompilerConfig _$CompilerConfigFromJson(Map<String, dynamic> json) {
  return CompilerConfig(
    compiler: _$enumDecode(_$InstalledCompilerEnumMap, json['compiler']),
    threads: json['threads'] as int,
    sourceDirectories: (json['sourceDirectories'] as List<dynamic>)
        .map((e) => e as String)
        .toList(),
    compilerFlags: (json['compilerFlags'] as List<dynamic>)
        .map((e) => e as String)
        .toList(),
    linkerFlags:
        (json['linkerFlags'] as List<dynamic>).map((e) => e as String).toList(),
  );
}

Map<String, dynamic> _$CompilerConfigToJson(CompilerConfig instance) =>
    <String, dynamic>{
      'compiler': _$InstalledCompilerEnumMap[instance.compiler],
      'threads': instance.threads,
      'sourceDirectories': instance.sourceDirectories,
      'compilerFlags': instance.compilerFlags,
      'linkerFlags': instance.linkerFlags,
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

const _$InstalledCompilerEnumMap = {
  InstalledCompiler.gpp: 'g++',
};
