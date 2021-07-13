import 'package:json_annotation/json_annotation.dart';

part 'config_lock.g.dart';

/// The model of the lock file entry for
/// compiler configurations.
@JsonSerializable()
class ConfigLock {
  /// The checksum of the configuration.
  /// It should be unique for each config producing a different executable.
  final String checksum;

  /// Set of all files which latest version is available as object file for this config.
  final Set<String> compiledFiles;

  ConfigLock({required this.checksum, required this.compiledFiles});

  factory ConfigLock.fromJson(Map<String, dynamic> json) => _$ConfigLockFromJson(json);

  Map<String, dynamic> toJson() => _$ConfigLockToJson(this);

  @override
  bool operator ==(other) {
    if (other is! ConfigLock) {
      return false;
    }

    return checksum == other.checksum;
  }

  @override
  int get hashCode {
    return checksum.hashCode;
  }
}
