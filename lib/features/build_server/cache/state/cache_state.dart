import 'package:json_annotation/json_annotation.dart';

part 'cache_state.g.dart';

/// The persisted state of `Cache`.
///
/// The state meant to be saved in `.state.json` files.
@JsonSerializable()
class CacheState {
  /// List of all project identifiers.
  final Set<String> projects;

  CacheState({required this.projects});

  factory CacheState.fromJson(Map<String, dynamic> json) => _$CacheStateFromJson(json);

  Map<String, dynamic> toJson() => _$CacheStateToJson(this);
}
