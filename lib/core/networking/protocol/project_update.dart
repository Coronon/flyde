import 'dart:convert';
import 'dart:typed_data';

import 'package:flyde/core/fs/configs/compiler_config.dart';
import 'package:json_annotation/json_annotation.dart';

part 'project_update.g.dart';

/// Updates a project with new files and configuration.
@JsonSerializable()
class ProjectUpdateRequest {
  /// The file list of the project.
  ///
  /// Each file id is mapped to the hash of it's content.
  final Map<String, String> files;

  /// The configuration which should be used for compilation.
  final CompilerConfig config;

  ProjectUpdateRequest({required this.files, required this.config});

  factory ProjectUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$ProjectUpdateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ProjectUpdateRequestToJson(this);
}

/// The response to a [ProjectUpdateRequest].
@JsonSerializable()
class ProjectUpdateResponse {
  /// List of files which need to be updated.
  final List<String> files;

  ProjectUpdateResponse({required this.files});

  factory ProjectUpdateResponse.fromJson(Map<String, dynamic> json) =>
      _$ProjectUpdateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ProjectUpdateResponseToJson(this);
}

/// A file update message used to transfer files from the user to the server.
@JsonSerializable()
class FileUpdate {
  /// Mirror of `SourceFile->name`
  final String name;

  /// Mirror of `SourceFile->extension`
  final String extension;

  /// Mirror of `SourceFile->entry`
  final int entry;

  /// Mirror of `SourceFile->path`
  final List<String> path;

  /// Mirror of `SourceFile->data`
  @JsonKey(toJson: _uint8List2intList, fromJson: _intList2uint8List)
  final Uint8List data;

  FileUpdate({
    required this.name,
    required this.extension,
    required this.entry,
    required this.data,
    required this.path,
  });

  factory FileUpdate.fromJson(Map<String, dynamic> json) => _$FileUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$FileUpdateToJson(this);
}

/// `Uint8List` -> List<int>
String _uint8List2intList(Uint8List data) => base64Encode(data);

/// List<int> -> `Uint8List`
Uint8List _intList2uint8List(String data) => base64Decode(data);
