import 'package:flyde/features/build_server/cache/dependencies/dependency_graph.dart';
import 'package:json_annotation/json_annotation.dart';

part 'config_state.g.dart';

/// The persisted state of `CompilerConfig`.
///
/// The state should be part of the project cache's `.state.json` file.
@JsonSerializable()
class ConfigState {
  /// The checksum of the configuration.
  /// It should be unique for each config producing a different executable.
  final String checksum;

  /// Set of all files which latest version is available as object file for this config.
  final Set<String> compiledFiles;

  /// A graph used to determine which files rely on each other.
  final DependencyGraph dependencyGraph;

  ConfigState({required this.checksum, required this.compiledFiles, required this.dependencyGraph});

  factory ConfigState.fromJson(Map<String, dynamic> json) => _$ConfigStateFromJson(json);

  Map<String, dynamic> toJson() => _$ConfigStateToJson(this);

  @override
  bool operator ==(other) {
    if (other is! ConfigState) {
      return false;
    }

    return checksum == other.checksum;
  }

  @override
  int get hashCode {
    return checksum.hashCode;
  }
}
