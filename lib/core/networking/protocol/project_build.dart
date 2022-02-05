import 'dart:convert';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

part 'project_build.g.dart';

/// Request to build the initialized project.
const projectBuildRequest = 'build_project';

/// Request to download the latest project binary.
const getBinaryRequest = 'get_binary';

/// Request to download the logs for the last build.
const getBuildLogsRequest = 'get_build_logs';

/// Server response which sends the latest binary or null
/// if not available.
@JsonSerializable()
class BinaryResponse {
  /// The binary data.
  @JsonKey(toJson: _binaryToJson, fromJson: _jsonToBinary)
  final Uint8List? binary;

  BinaryResponse({required this.binary});

  factory BinaryResponse.fromJson(Map<String, dynamic> json) => _$BinaryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BinaryResponseToJson(this);

  static String? _binaryToJson(Uint8List? binary) => binary == null ? null : base64Encode(binary);

  static Uint8List? _jsonToBinary(String? json) => json == null ? null : base64Decode(json);
}
