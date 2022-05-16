import 'package:test/test.dart';

import 'package:flyde/core/logs/log_scope.dart';

void main() {
  test('Can convert all scopes to display strings', () {
    for (final scope in LogScope.values) {
      switch (scope) {
        case LogScope.application:
          expect(
            scope.toDisplayString(colored: true),
            equals('\x1B[34mapplication\x1B[39m'),
          );
          expect(
            scope.toDisplayString(colored: false),
            equals('application'),
          );
          expect(
            scope.toDisplayString(),
            equals(scope.toDisplayString(colored: false)),
          );
          break;
        case LogScope.compiler:
          expect(
            scope.toDisplayString(colored: true),
            equals('\x1B[32mcompiler\x1B[39m'),
          );
          expect(
            scope.toDisplayString(colored: false),
            equals('compiler'),
          );
          expect(
            scope.toDisplayString(),
            equals(scope.toDisplayString(colored: false)),
          );
          break;
        case LogScope.linker:
          expect(
            scope.toDisplayString(colored: true),
            equals('\x1B[35mlinker\x1B[39m'),
          );
          expect(
            scope.toDisplayString(colored: false),
            equals('linker'),
          );
          expect(
            scope.toDisplayString(),
            equals(scope.toDisplayString(colored: false)),
          );
          break;
      }
    }
  });

  test('Can convert color-less display strings back to log scope', () {
    for (final scope in LogScope.values) {
      switch (scope) {
        case LogScope.application:
          expect(
            ConvertScopeToString.fromDisplayString('application'),
            equals(scope),
          );
          break;
        case LogScope.compiler:
          expect(
            ConvertScopeToString.fromDisplayString('compiler'),
            equals(scope),
          );
          break;
        case LogScope.linker:
          expect(
            ConvertScopeToString.fromDisplayString('linker'),
            equals(scope),
          );
          break;
      }
    }
  });

  test('Fails to convert a bad string to log scope', () {
    expect(
      () => ConvertScopeToString.fromDisplayString('bad'),
      throwsA(isA<ArgumentError>()),
    );
  });
}
