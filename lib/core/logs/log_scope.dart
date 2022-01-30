import '../console/terminal_color.dart';

/// A [logScope] is a way to group log messages
/// by the scope of the message.
enum LogScope {
  /// The message covers information about the main
  /// application.
  application,

  /// The message covers information about the
  /// compiler.
  compiler,

  /// The message covers information about the
  /// linker.
  linker,
}

/// Extension to convert [LogScope] to a [String] and back.
extension ConvertScopeToString on LogScope {
  /// Converts [displayString] to a [LogScope].
  /// [displayString] is the result to the call to [toDisplayString]
  /// without formatting.
  ///
  /// If [displayString] is not a valid [LogScope]
  /// an [ArgumentError] is thrown.
  static LogScope fromDisplayString(String displayString) {
    switch (displayString) {
      case 'application':
        return LogScope.application;
      case 'compiler':
        return LogScope.compiler;
      case 'linker':
        return LogScope.linker;
      default:
        throw ArgumentError('Invalid log scope: $displayString');
    }
  }

  /// Converts [this] to a [String] that can be used
  /// to display the [LogScope].
  ///
  /// If [colored] is true, the string will be formatted
  /// to be displayed in a terminal.
  String toDisplayString({bool colored = false}) {
    switch (this) {
      case LogScope.application:
        return colored ? 'application'.colored(TerminalColor.blue) : 'application';
      case LogScope.compiler:
        return colored ? 'compiler'.colored(TerminalColor.green) : 'compiler';
      case LogScope.linker:
        return colored ? 'linker'.colored(TerminalColor.magenta) : 'linker';
    }
  }
}
