import 'package:json_annotation/json_annotation.dart';
import 'package:flyde/features/build_server/cache/state/config_state.dart';
import 'package:flyde/features/build_server/cache/state/source_file_state.dart';

part 'project_cache_state.g.dart';

/// The persisted state of `ProjectCache`.
///
/// The state should be JSON serialized and stored in a `.state.json` file.
@JsonSerializable()
class ProjectCacheState {
  /// Set of available compilation configs.
  final Set<ConfigState> configs;

  /// Set of latest project files.
  final Set<SourceFileState> files;

  ProjectCacheState({required this.configs, required this.files});

  factory ProjectCacheState.fromJson(Map<String, dynamic> json) =>
      _$ProjectCacheStateFromJson(json);

  Map<String, dynamic> toJson() => _$ProjectCacheStateToJson(this);
}
