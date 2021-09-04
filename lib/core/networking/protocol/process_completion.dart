import 'package:json_annotation/json_annotation.dart';

part 'process_completion.g.dart';

/// Enum of possible processes for which completion should be reported.
enum CompletableProcess {
  /// Project has been initialized.
  projectInit,

  /// File has been updated.
  fileUpdate,
}

/// Message which informs about the completion of a server side process.
@JsonSerializable()
class ProcessCompletionMessage {
  /// The process which has been completed.
  final CompletableProcess process;

  /// Description or required information about the process.
  final String description;

  ProcessCompletionMessage({required this.process, required this.description});

  factory ProcessCompletionMessage.fromJson(Map<String, dynamic> json) =>
      _$ProcessCompletionMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ProcessCompletionMessageToJson(this);
}
