import 'package:args/command_runner.dart';

/// Mixin for [Command]s to easier fetch arguments and convert
/// bewteen types.
mixin CommandArgGetter on Command {
  /// Tries to read the argument with the given [key] and convert it to
  /// be [T].
  ///
  /// When the argument is a subtype of [T], it will be returned as is.
  /// Otherwise a custom [parser] has to be provieded or a
  /// [UsageException] will be thrown.
  T useArg<T>(String key, {T Function(dynamic)? parser}) {
    final bool wasParsed = argResults?.wasParsed(key) ?? false;

    if (!wasParsed && argResults?[key] == null) {
      throw StateError('Argument "$key" was not provided or not yet parsed.');
    }

    final dynamic value = argResults![key];

    if (parser != null) {
      try {
        return parser(value);
      } catch (e) {
        throw UsageException(
          'Failed to parse the argument for "$key". $e',
          usage,
        );
      }
    }

    if (value is T) {
      return value;
    }

    throw UsageException('Argument $key does not match the expected format', usage);
  }
}
