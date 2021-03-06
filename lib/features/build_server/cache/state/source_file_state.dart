import 'dart:io';

import 'package:flyde/core/fs/wrapper/source_file.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart';

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

  /// Converts the [SourceFileState] back to a [SourceFile].
  ///
  /// [storageDirectory] is required to find the relative path to the file.
  /// The entry id of the `SourceFile` is either determined by the first
  /// component of the relative path or can be passed directly as [entry].
  Future<SourceFile> toSourceFile(Directory storageDirectory, {int? entry}) async {
    final relPath = relative(path, from: storageDirectory.path);
    final pathComps = split(normalize(relPath));
    final entryId = entry ?? int.parse(pathComps[0]);

    return SourceFile.fromFile(
      entryId,
      File(path),
      entryDirectory: Directory(join(
        storageDirectory.path,
        entry is int ? null : entryId.toString(),
      )),
    );
  }

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
