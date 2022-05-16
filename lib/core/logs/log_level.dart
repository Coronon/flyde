import '../console/terminal_color.dart';

/// A [LogLevel] is a way to group log messages by importance.
enum LogLevel {
  /// The message is a debug message and should not
  /// cover information that is important for the user.
  debug,

  /// The message is solely for informational purposes and
  /// should not be used to report abnormal behaviour.
  info,

  /// The message is a warning and should be used to
  /// report state that could lead to crashes / bugs but is
  /// at the time of the message not critical.
  warning,

  /// The message is a error and indicates that a task could not be completed,
  /// but the application can continue to run.
  error,

  /// The message is a critical error and indicates
  /// that the application has encountered a state from
  /// which it cannot recover.
  critical,
}

/// Extension to convert [LogLevel] to a [String] and back.
extension ConvertLevelToString on LogLevel {
  /// Converts [displayString] to a [LogLevel].
  /// [displayString] is the result to the call to [toDisplayString]
  /// without formatting.
  ///
  /// If [displayString] is not a valid [LogLevel]
  /// an [ArgumentError] is thrown.
  static LogLevel fromDisplayString(String displayString) {
    switch (displayString) {
      case 'debug':
        return LogLevel.debug;
      case 'info':
        return LogLevel.info;
      case 'warning':
        return LogLevel.warning;
      case 'error':
        return LogLevel.error;
      case 'critical':
        return LogLevel.critical;
      default:
        throw ArgumentError('Invalid log level: $displayString');
    }
  }

  /// Converts [this] to a [String] that can be used
  /// to display the [LogLevel].
  ///
  /// If [colored] is true, the string will be formatted
  /// to be displayed in a terminal.
  String toDisplayString({bool colored = false}) {
    switch (this) {
      case LogLevel.debug:
        return colored ? 'debug'.colored(TerminalColor.cyan) : 'debug';
      case LogLevel.info:
        return colored ? 'info'.colored(TerminalColor.blue) : 'info';
      case LogLevel.warning:
        return colored ? 'warning'.colored(TerminalColor.yellow) : 'warning';
      case LogLevel.error:
        return colored ? 'error'.colored(TerminalColor.magenta) : 'error';
      case LogLevel.critical:
        return colored ? 'critical'.colored(TerminalColor.red) : 'critical';
    }
  }
}
