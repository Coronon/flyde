// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_lock.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConfigLock _$ConfigLockFromJson(Map<String, dynamic> json) {
  return ConfigLock(
    checksum: json['checksum'] as String,
    compiledFiles: (json['compiledFiles'] as List<dynamic>)
        .map((e) => e as String)
        .toSet(),
  );
}

Map<String, dynamic> _$ConfigLockToJson(ConfigLock instance) =>
    <String, dynamic>{
      'checksum': instance.checksum,
      'compiledFiles': instance.compiledFiles.toList(),
    };
