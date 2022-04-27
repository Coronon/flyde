import 'dart:typed_data';

import 'package:flyde/core/logs/log_level.dart';
import 'package:flyde/core/logs/log_scope.dart';
import 'package:flyde/core/logs/logger.dart';

import 'package:test/test.dart';

Future<void> _addSampleMessages(Logger logger, {bool withDelay = false}) async {
  logger.add('This is an info message from the application', scope: LogScope.application);
  logger.add('This is an info message from the linker', scope: LogScope.linker);
  logger.add('This is an info message from the compiler', scope: LogScope.compiler);

  if (withDelay) {
    await Future.delayed(Duration(milliseconds: 100));
  }

  logger.add(
    'This is a warning from the application',
    scope: LogScope.application,
    level: LogLevel.warning,
  );
  logger.add(
    'This is a warning from the linker',
    scope: LogScope.linker,
    level: LogLevel.warning,
  );
  logger.add(
    'This is a warning from the compiler',
    scope: LogScope.compiler,
    level: LogLevel.warning,
  );

  logger.add(
    'This is an error from the application',
    scope: LogScope.application,
    level: LogLevel.error,
  );
  logger.add(
    'This is an error from the linker',
    scope: LogScope.linker,
    level: LogLevel.error,
  );
  logger.add(
    'This is an error from the compiler',
    scope: LogScope.compiler,
    level: LogLevel.error,
  );

  logger.add(
    'This is a critical error from the application',
    scope: LogScope.application,
    level: LogLevel.critical,
  );
  logger.add(
    'This is a critical error from the linker',
    scope: LogScope.linker,
    level: LogLevel.critical,
  );
  logger.add(
    'This is a critical error from the compiler',
    scope: LogScope.compiler,
    level: LogLevel.critical,
  );

  logger.add(
    'This is a debug message from the application',
    scope: LogScope.application,
    level: LogLevel.debug,
  );
  logger.add(
    'This is a debug message from the linker',
    scope: LogScope.linker,
    level: LogLevel.debug,
  );
  logger.add(
    'This is a debug message from the compiler',
    scope: LogScope.compiler,
    level: LogLevel.debug,
  );

  logger.add(
    'This is an info message from the application with description',
    scope: LogScope.application,
    level: LogLevel.info,
    description: 'This is a description',
  );
}

void main() {
  late Logger logger;
  final String dateRegex = r'[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]*';
  final String unformattedTextLogs = '^'
      '\\[level: info\\]\\[scope: application\\]\\[$dateRegex\\]\n'
      'This is an info message from the application\n\n'
      '\\[level: info\\]\\[scope: linker\\]\\[$dateRegex\\]\n'
      'This is an info message from the linker\n\n'
      '\\[level: info\\]\\[scope: compiler\\]\\[$dateRegex\\]\n'
      'This is an info message from the compiler\n\n'
      '\\[level: warning\\]\\[scope: application\\]\\[$dateRegex\\]\n'
      'This is a warning from the application\n\n'
      '\\[level: warning\\]\\[scope: linker\\]\\[$dateRegex\\]\n'
      'This is a warning from the linker\n\n'
      '\\[level: warning\\]\\[scope: compiler\\]\\[$dateRegex\\]\n'
      'This is a warning from the compiler\n\n'
      '\\[level: error\\]\\[scope: application\\]\\[$dateRegex\\]\n'
      'This is an error from the application\n\n'
      '\\[level: error\\]\\[scope: linker\\]\\[$dateRegex\\]\n'
      'This is an error from the linker\n\n'
      '\\[level: error\\]\\[scope: compiler\\]\\[$dateRegex\\]\n'
      'This is an error from the compiler\n\n'
      '\\[level: critical\\]\\[scope: application\\]\\[$dateRegex\\]\n'
      'This is a critical error from the application\n\n'
      '\\[level: critical\\]\\[scope: linker\\]\\[$dateRegex\\]\n'
      'This is a critical error from the linker\n\n'
      '\\[level: critical\\]\\[scope: compiler\\]\\[$dateRegex\\]\n'
      'This is a critical error from the compiler\n\n'
      '\\[level: debug\\]\\[scope: application\\]\\[$dateRegex\\]\n'
      'This is a debug message from the application\n\n'
      '\\[level: debug\\]\\[scope: linker\\]\\[$dateRegex\\]\n'
      'This is a debug message from the linker\n\n'
      '\\[level: debug\\]\\[scope: compiler\\]\\[$dateRegex\\]\n'
      'This is a debug message from the compiler\n\n'
      '\\[level: info\\]\\[scope: application\\]\\[$dateRegex\\] This is a description\n'
      'This is an info message from the application with description'
      r'$';

  setUp(() => logger = Logger());

  test('Creates plain text logs', () {
    _addSampleMessages(logger);

    final String text = logger.toString();

    expect(text, matches(RegExp(unformattedTextLogs)));
  });

  test('Creates ANSI formatted text logs', () {
    _addSampleMessages(logger);

    final String text = logger.toString(formatForTerminal: true);
    final String expected = '^'
        '\\x1B\\[1m\\[level: \\x1B\\[34minfo\\x1B\\[39m\\]\\[scope: \\x1B\\[34mapplication\\x1B\\[39m\\]\\[$dateRegex\\]\\x1B\\[22m\n'
        'This is an info message from the application\n\n'
        '\\x1B\\[1m\\[level: \\x1B\\[34minfo\\x1B\\[39m\\]\\[scope: \\x1B\\[35mlinker\\x1B\\[39m\\]\\[$dateRegex\\]\\x1B\\[22m\n'
        'This is an info message from the linker\n\n'
        '\\x1B\\[1m\\[level: \\x1B\\[34minfo\\x1B\\[39m\\]\\[scope: \\x1B\\[32mcompiler\\x1B\\[39m\\]\\[$dateRegex\\]\\x1B\\[22m\n'
        'This is an info message from the compiler\n\n'
        '\\x1B\\[1m\\[level: \\x1B\\[33mwarning\\x1B\\[39m\\]\\[scope: \\x1B\\[34mapplication\\x1B\\[39m\\]\\[$dateRegex\\]\\x1B\\[22m\n'
        'This is a warning from the application\n\n'
        '\\x1B\\[1m\\[level: \\x1B\\[33mwarning\\x1B\\[39m\\]\\[scope: \\x1B\\[35mlinker\\x1B\\[39m\\]\\[$dateRegex\\]\\x1B\\[22m\n'
        'This is a warning from the linker\n\n'
        '\\x1B\\[1m\\[level: \\x1B\\[33mwarning\\x1B\\[39m\\]\\[scope: \\x1B\\[32mcompiler\\x1B\\[39m\\]\\[$dateRegex\\]\\x1B\\[22m\n'
        'This is a warning from the compiler\n\n'
        '\\x1B\\[1m\\[level: \\x1B\\[35merror\\x1B\\[39m\\]\\[scope: \\x1B\\[34mapplication\\x1B\\[39m\\]\\[$dateRegex\\]\\x1B\\[22m\n'
        'This is an error from the application\n\n'
        '\\x1B\\[1m\\[level: \\x1B\\[35merror\\x1B\\[39m\\]\\[scope: \\x1B\\[35mlinker\\x1B\\[39m\\]\\[$dateRegex\\]\\x1B\\[22m\n'
        'This is an error from the linker\n\n'
        '\\x1B\\[1m\\[level: \\x1B\\[35merror\\x1B\\[39m\\]\\[scope: \\x1B\\[32mcompiler\\x1B\\[39m\\]\\[$dateRegex\\]\\x1B\\[22m\n'
        'This is an error from the compiler\n\n'
        '\\x1B\\[1m\\[level: \\x1B\\[31mcritical\\x1B\\[39m\\]\\[scope: \\x1B\\[34mapplication\\x1B\\[39m\\]\\[$dateRegex\\]\\x1B\\[22m\n'
        'This is a critical error from the application\n\n'
        '\\x1B\\[1m\\[level: \\x1B\\[31mcritical\\x1B\\[39m\\]\\[scope: \\x1B\\[35mlinker\\x1B\\[39m\\]\\[$dateRegex\\]\\x1B\\[22m\n'
        'This is a critical error from the linker\n\n'
        '\\x1B\\[1m\\[level: \\x1B\\[31mcritical\\x1B\\[39m\\]\\[scope: \\x1B\\[32mcompiler\\x1B\\[39m\\]\\[$dateRegex\\]\\x1B\\[22m\n'
        'This is a critical error from the compiler\n\n'
        '\\x1B\\[1m\\[level: \\x1B\\[36mdebug\\x1B\\[39m\\]\\[scope: \\x1B\\[34mapplication\\x1B\\[39m\\]\\[$dateRegex\\]\\x1B\\[22m\n'
        'This is a debug message from the application\n\n'
        '\\x1B\\[1m\\[level: \\x1B\\[36mdebug\\x1B\\[39m\\]\\[scope: \\x1B\\[35mlinker\\x1B\\[39m\\]\\[$dateRegex\\]\\x1B\\[22m\n'
        'This is a debug message from the linker\n\n'
        '\\x1B\\[1m\\[level: \\x1B\\[36mdebug\\x1B\\[39m\\]\\[scope: \\x1B\\[32mcompiler\\x1B\\[39m\\]\\[$dateRegex\\]\\x1B\\[22m\n'
        'This is a debug message from the compiler\n\n'
        '\\x1B\\[1m\\[level: \\x1B\\[34minfo\\x1B\\[39m\\]\\[scope: \\x1B\\[34mapplication\\x1B\\[39m\\]\\[$dateRegex\\] This is a description\\x1B\\[22m\n'
        'This is an info message from the application with description'
        r'$';

    expect(text, matches(RegExp(expected)));
  });

  test('Can apply scope filter when creating text logs', () {
    _addSampleMessages(logger);

    final String applicationText = logger.toString(scope: LogScope.application);
    final String compilerText = logger.toString(scope: LogScope.compiler);
    final String linkerText = logger.toString(scope: LogScope.linker);
    final String expectedApplication = '^'
        '\\[level: info\\]\\[scope: application\\]\\[$dateRegex\\]\n'
        'This is an info message from the application\n\n'
        '\\[level: warning\\]\\[scope: application\\]\\[$dateRegex\\]\n'
        'This is a warning from the application\n\n'
        '\\[level: error\\]\\[scope: application\\]\\[$dateRegex\\]\n'
        'This is an error from the application\n\n'
        '\\[level: critical\\]\\[scope: application\\]\\[$dateRegex\\]\n'
        'This is a critical error from the application\n\n'
        '\\[level: debug\\]\\[scope: application\\]\\[$dateRegex\\]\n'
        'This is a debug message from the application\n\n'
        '\\[level: info\\]\\[scope: application\\]\\[$dateRegex\\] This is a description\n'
        'This is an info message from the application with description'
        r'$';
    final String expectedCompiler = '^'
        '\\[level: info\\]\\[scope: compiler\\]\\[$dateRegex\\]\n'
        'This is an info message from the compiler\n\n'
        '\\[level: warning\\]\\[scope: compiler\\]\\[$dateRegex\\]\n'
        'This is a warning from the compiler\n\n'
        '\\[level: error\\]\\[scope: compiler\\]\\[$dateRegex\\]\n'
        'This is an error from the compiler\n\n'
        '\\[level: critical\\]\\[scope: compiler\\]\\[$dateRegex\\]\n'
        'This is a critical error from the compiler\n\n'
        '\\[level: debug\\]\\[scope: compiler\\]\\[$dateRegex\\]\n'
        'This is a debug message from the compiler'
        r'$';
    final String expectedLinker = '^'
        '\\[level: info\\]\\[scope: linker\\]\\[$dateRegex\\]\n'
        'This is an info message from the linker\n\n'
        '\\[level: warning\\]\\[scope: linker\\]\\[$dateRegex\\]\n'
        'This is a warning from the linker\n\n'
        '\\[level: error\\]\\[scope: linker\\]\\[$dateRegex\\]\n'
        'This is an error from the linker\n\n'
        '\\[level: critical\\]\\[scope: linker\\]\\[$dateRegex\\]\n'
        'This is a critical error from the linker\n\n'
        '\\[level: debug\\]\\[scope: linker\\]\\[$dateRegex\\]\n'
        'This is a debug message from the linker'
        r'$';

    expect(applicationText, matches(RegExp(expectedApplication)));
    expect(compilerText, matches(RegExp(expectedCompiler)));
    expect(linkerText, matches(RegExp(expectedLinker)));
  });

  test('Can apply level filter for text logs', () {
    _addSampleMessages(logger);

    final String infoText = logger.toString(level: LogLevel.info);
    final String warningText = logger.toString(level: LogLevel.warning);
    final String errorText = logger.toString(level: LogLevel.error);
    final String criticalText = logger.toString(level: LogLevel.critical);
    final String debugText = logger.toString(level: LogLevel.debug);

    final String expectedInfo = '^'
        '\\[level: info\\]\\[scope: application\\]\\[$dateRegex\\]\n'
        'This is an info message from the application\n\n'
        '\\[level: info\\]\\[scope: linker\\]\\[$dateRegex\\]\n'
        'This is an info message from the linker\n\n'
        '\\[level: info\\]\\[scope: compiler\\]\\[$dateRegex\\]\n'
        'This is an info message from the compiler\n\n'
        '\\[level: info\\]\\[scope: application\\]\\[$dateRegex\\] This is a description\n'
        'This is an info message from the application with description'
        r'$';
    final String expectedWarning = '^'
        '\\[level: warning\\]\\[scope: application\\]\\[$dateRegex\\]\n'
        'This is a warning from the application\n\n'
        '\\[level: warning\\]\\[scope: linker\\]\\[$dateRegex\\]\n'
        'This is a warning from the linker\n\n'
        '\\[level: warning\\]\\[scope: compiler\\]\\[$dateRegex\\]\n'
        'This is a warning from the compiler'
        r'$';
    final String expectedError = '^'
        '\\[level: error\\]\\[scope: application\\]\\[$dateRegex\\]\n'
        'This is an error from the application\n\n'
        '\\[level: error\\]\\[scope: linker\\]\\[$dateRegex\\]\n'
        'This is an error from the linker\n\n'
        '\\[level: error\\]\\[scope: compiler\\]\\[$dateRegex\\]\n'
        'This is an error from the compiler'
        r'$';
    final String expectedCritical = '^'
        '\\[level: critical\\]\\[scope: application\\]\\[$dateRegex\\]\n'
        'This is a critical error from the application\n\n'
        '\\[level: critical\\]\\[scope: linker\\]\\[$dateRegex\\]\n'
        'This is a critical error from the linker\n\n'
        '\\[level: critical\\]\\[scope: compiler\\]\\[$dateRegex\\]\n'
        'This is a critical error from the compiler'
        r'$';
    final String expectedDebug = '^'
        '\\[level: debug\\]\\[scope: application\\]\\[$dateRegex\\]\n'
        'This is a debug message from the application\n\n'
        '\\[level: debug\\]\\[scope: linker\\]\\[$dateRegex\\]\n'
        'This is a debug message from the linker\n\n'
        '\\[level: debug\\]\\[scope: compiler\\]\\[$dateRegex\\]\n'
        'This is a debug message from the compiler'
        r'$';

    expect(infoText, matches(RegExp(expectedInfo)));
    expect(warningText, matches(RegExp(expectedWarning)));
    expect(errorText, matches(RegExp(expectedError)));
    expect(criticalText, matches(RegExp(expectedCritical)));
    expect(debugText, matches(RegExp(expectedDebug)));
  });

  test('Can apply date filters for text logs', () async {
    await _addSampleMessages(logger, withDelay: true);

    final String oldText = logger.toString(
      to: DateTime.now().subtract(Duration(milliseconds: 50)),
    );
    final String newText = logger.toString(
      from: DateTime.now().subtract(Duration(milliseconds: 50)),
    );

    final String oldExpected = '^'
        '\\[level: info\\]\\[scope: application\\]\\[$dateRegex\\]\n'
        'This is an info message from the application\n\n'
        '\\[level: info\\]\\[scope: linker\\]\\[$dateRegex\\]\n'
        'This is an info message from the linker\n\n'
        '\\[level: info\\]\\[scope: compiler\\]\\[$dateRegex\\]\n'
        'This is an info message from the compiler'
        r'$';

    final String newExpected = '^'
        '\\[level: warning\\]\\[scope: application\\]\\[$dateRegex\\]\n'
        'This is a warning from the application\n\n'
        '\\[level: warning\\]\\[scope: linker\\]\\[$dateRegex\\]\n'
        'This is a warning from the linker\n\n'
        '\\[level: warning\\]\\[scope: compiler\\]\\[$dateRegex\\]\n'
        'This is a warning from the compiler\n\n'
        '\\[level: error\\]\\[scope: application\\]\\[$dateRegex\\]\n'
        'This is an error from the application\n\n'
        '\\[level: error\\]\\[scope: linker\\]\\[$dateRegex\\]\n'
        'This is an error from the linker\n\n'
        '\\[level: error\\]\\[scope: compiler\\]\\[$dateRegex\\]\n'
        'This is an error from the compiler\n\n'
        '\\[level: critical\\]\\[scope: application\\]\\[$dateRegex\\]\n'
        'This is a critical error from the application\n\n'
        '\\[level: critical\\]\\[scope: linker\\]\\[$dateRegex\\]\n'
        'This is a critical error from the linker\n\n'
        '\\[level: critical\\]\\[scope: compiler\\]\\[$dateRegex\\]\n'
        'This is a critical error from the compiler\n\n'
        '\\[level: debug\\]\\[scope: application\\]\\[$dateRegex\\]\n'
        'This is a debug message from the application\n\n'
        '\\[level: debug\\]\\[scope: linker\\]\\[$dateRegex\\]\n'
        'This is a debug message from the linker\n\n'
        '\\[level: debug\\]\\[scope: compiler\\]\\[$dateRegex\\]\n'
        'This is a debug message from the compiler\n\n'
        '\\[level: info\\]\\[scope: application\\]\\[$dateRegex\\] This is a description\n'
        'This is an info message from the application with description'
        r'$';

    expect(oldText, matches(RegExp(oldExpected)));
    expect(newText, matches(RegExp(newExpected)));
  });

  test('Can convert from and to bytes', () {
    _addSampleMessages(logger);

    final Uint8List bytes = logger.toBytes();
    final Logger restoredLogger = Logger.fromBytes(bytes);

    expect(restoredLogger.toString(), matches(RegExp(unformattedTextLogs)));
  });

  test('Can convert from and to JSON', () {
    _addSampleMessages(logger);

    final List<Map<String, dynamic>> json = logger.toJson();
    final Logger restoredLogger = Logger.fromJson(json);

    expect(restoredLogger.toString(), matches(RegExp(unformattedTextLogs)));
  });
}
