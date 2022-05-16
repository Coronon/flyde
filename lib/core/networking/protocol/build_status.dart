import 'package:json_annotation/json_annotation.dart';

part 'build_status.g.dart';

/// A message which informs about the current build state.
@JsonSerializable(genericArgumentFactories: true)
class BuildStatusMessage<T> {
  /// The current build state.
  final BuildStatus status;

  /// The message payload.
  ///
  /// See [BuildStatus] docs for type details.
  final T payload;

  BuildStatusMessage({required this.status, required this.payload});

  factory BuildStatusMessage.fromJson(Map<String, dynamic> json) =>
      _$BuildStatusMessageFromJson(json, (obj) => obj as T);

  Map<String, dynamic> toJson() => _$BuildStatusMessageToJson(
        this,
        (Object? obj) {
          if (obj is double || obj is int || obj is String || obj is bool) {
            return obj;
          } else {
            return obj?.toString();
          }
        },
      );
}

/// The status of the compilation.
enum BuildStatus {
  /// Process has to wait. Payload is a [WaitReason].
  waiting,

  /// Compilation in progress. Payload is a progress percentage as `Double` value.
  compiling,

  /// Project is linking. No further payload.
  linking,

  /// Compilation has succeeded. No further payload.
  done,

  /// Compilation failed. Payload is a `String` with the error message.
  failed,
}

/// Reasons why the build process has to wait.
enum WaitReason {
  resourcesBlocked,
  finishing,
  awaitingNextPhase,
}
