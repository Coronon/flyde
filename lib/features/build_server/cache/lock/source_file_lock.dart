import 'package:json_annotation/json_annotation.dart';

part 'source_file_lock.g.dart';

/// The model of the persisted information of
/// the available source files.
@JsonSerializable()
class SourceFileLock {
  /// The unique id of the project file.
  final String id;

  /// The hash value of the file's content.
  String hash;

  /// The path to the in cache stored file copy.
  final String path;

  SourceFileLock({required this.id, required this.hash, required this.path});

  factory SourceFileLock.fromJson(Map<String, dynamic> json) => _$SourceFileLockFromJson(json);

  Map<String, dynamic> toJson() => _$SourceFileLockToJson(this);

  @override
  bool operator ==(other) {
    if (other is! SourceFileLock) {
      return false;
    }

    return id == other.id && path == other.path;
  }

  @override
  int get hashCode {
    return id.hashCode ^ path.hashCode;
  }
}
