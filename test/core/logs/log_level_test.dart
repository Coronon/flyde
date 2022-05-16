import 'package:test/test.dart';

import 'package:flyde/core/logs/log_level.dart';

void main() {
  test('Can convert all levels to display strings', () {
    for (final level in LogLevel.values) {
      switch (level) {
        case LogLevel.debug:
          expect(
            level.toDisplayString(colored: true),
            equals('\x1B[36mdebug\x1B[39m'),
          );
          expect(
            level.toDisplayString(colored: false),
            equals('debug'),
          );
          expect(
            level.toDisplayString(),
            equals(level.toDisplayString(colored: false)),
          );
          break;
        case LogLevel.info:
          expect(
            level.toDisplayString(colored: true),
            equals('\x1B[34minfo\x1B[39m'),
          );
          expect(
            level.toDisplayString(colored: false),
            equals('info'),
          );
          expect(
            level.toDisplayString(),
            equals(level.toDisplayString(colored: false)),
          );
          break;
        case LogLevel.warning:
          expect(
            level.toDisplayString(colored: true),
            equals('\x1B[33mwarning\x1B[39m'),
          );
          expect(
            level.toDisplayString(colored: false),
            equals('warning'),
          );
          expect(
            level.toDisplayString(),
            equals(level.toDisplayString(colored: false)),
          );
          break;
        case LogLevel.error:
          expect(
            level.toDisplayString(colored: true),
            equals('\x1B[35merror\x1B[39m'),
          );
          expect(
            level.toDisplayString(colored: false),
            equals('error'),
          );
          expect(
            level.toDisplayString(),
            equals(level.toDisplayString(colored: false)),
          );
          break;
        case LogLevel.critical:
          expect(
            level.toDisplayString(colored: true),
            equals('\x1B[31mcritical\x1B[39m'),
          );
          expect(
            level.toDisplayString(colored: false),
            equals('critical'),
          );
          expect(
            level.toDisplayString(),
            equals(level.toDisplayString(colored: false)),
          );
          break;
      }
    }
  });

  test('Can convert color-less display strings back to log level', () {
    for (final level in LogLevel.values) {
      switch (level) {
        case LogLevel.debug:
          expect(
            ConvertLevelToString.fromDisplayString('debug'),
            equals(LogLevel.debug),
          );
          break;
        case LogLevel.info:
          expect(
            ConvertLevelToString.fromDisplayString('info'),
            equals(LogLevel.info),
          );
          break;
        case LogLevel.warning:
          expect(
            ConvertLevelToString.fromDisplayString('warning'),
            equals(LogLevel.warning),
          );
          break;
        case LogLevel.error:
          expect(
            ConvertLevelToString.fromDisplayString('error'),
            equals(LogLevel.error),
          );
          break;
        case LogLevel.critical:
          expect(
            ConvertLevelToString.fromDisplayString('critical'),
            equals(LogLevel.critical),
          );
          break;
      }
    }
  });

  test('Fails to convert a bad string to log level', () {
    expect(
      () => ConvertLevelToString.fromDisplayString('bad'),
      throwsA(isA<ArgumentError>()),
    );
  });
}
