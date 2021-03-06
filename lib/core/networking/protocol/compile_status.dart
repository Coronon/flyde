import 'package:json_annotation/json_annotation.dart';

part 'compile_status.g.dart';

/// A message which informs about the current build state.
@JsonSerializable(genericArgumentFactories: true)
class CompileStatusMessage<T> {
  /// The current build state.
  final CompileStatus status;

  /// The message payload.
  ///
  /// See [CompileStatus] docs for type details.
  final T payload;

  CompileStatusMessage({required this.status, required this.payload});

  factory CompileStatusMessage.fromJson(Map<String, dynamic> json) =>
      _$CompileStatusMessageFromJson(json, (obj) => obj as T);

  Map<String, dynamic> toJson() => _$CompileStatusMessageToJson(
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
enum CompileStatus {
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
