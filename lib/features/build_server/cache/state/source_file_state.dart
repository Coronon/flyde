import 'package:json_annotation/json_annotation.dart';

part 'source_file_state.g.dart';

/// The persisted state of a source file.
///
/// The state should be part of the project cache's `.state.json` file.
@JsonSerializable()
class SourceFileState {
  /// The unique id of the project file.
  final String id;

  /// The hash value of the file's content.
  String hash;

  /// The path to the in cache stored file copy.
  final String path;

  SourceFileState({required this.id, required this.hash, required this.path});

  factory SourceFileState.fromJson(Map<String, dynamic> json) => _$SourceFileStateFromJson(json);

  Map<String, dynamic> toJson() => _$SourceFileStateToJson(this);

  @override
  bool operator ==(other) {
    if (other is! SourceFileState) {
      return false;
    }

    return id == other.id && path == other.path;
  }

  @override
  int get hashCode {
    return id.hashCode ^ path.hashCode;
  }
}
