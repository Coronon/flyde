import 'dart:async';

import 'package:test/test.dart' as test show expect, Matcher;

import 'wait_for.dart';

/// Useful to easily test handler functions
/// that set values outside of their scope.
///
/// ```dart
/// // Construct VHook with initial value of 'false'
/// VHook<bool> calledHandler = VHook<bool>(false);
///
/// willCallHandler(() {
///   calledHandler.set(true);
///   // Some handler code
/// });
///
/// // Test that the handler was called
/// // This will throw an error if the handler was not called.
/// calledHandler.expect(equals(true));
/// ```
class VHook<T> {
  /// The value of the variable.
  T _value;

  /// Construct a new ValueHook with the given initial value.
  VHook(this._value);

  /// Set the value of the variable.
  void set(T val) => _value = val;

  /// Current value
  T get value => _value;

  /// Check the value of the variable.
  ///
  /// This method uses 'expect' from the 'test' package.
  /// [val] is the expected value e.g. `equals(true)`
  void expect(
    test.Matcher matcher, {
    String? reason,
    dynamic skip,
  }) =>
      test.expect(
        _value,
        matcher,
        reason: reason,
        skip: skip,
      );

  /// Get awaitable that completes when the contained value is non-null.
  ///
  /// Note: The initial value of the VHook must have been null, and the final
  /// value non-null.
  ///
  /// The optional [timeout] specifies the maximum time to wait for the value.
  /// [pollInterval] specifies the time between value checks.
  /// If [raiseOnTimeout] is true, this function will throw if the timeout is reached.
  ///
  /// The returned Future's completion value is whether the value was set (true)
  /// or whether the timeout was reached (false).
  ///
  /// ```dart
  /// // Construct VHook with initial value of 'null'
  /// VHook<bool?> conditionValue = VHook<bool?>(null);
  ///
  /// // This function is supposed to call the handler soon
  /// willCallHandlerAsync(() {
  ///   if (someCondition) {
  ///     conditionValue.set(true);
  ///   } else {
  ///     conditionValue.set(false);
  ///   }
  /// });
  ///
  /// // Wait for the handler to be called
  /// // If the handler was not called after 5s, throw an error
  /// await conditionValue.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
  ///
  /// // This will throw an error if the condition evaluated to false
  /// conditionValue.expect(equals(true));
  /// ```
  Future<bool> awaitValue(
    Duration? timeout, {
    Duration pollInterval = Duration.zero,
    bool raiseOnTimeout = false,
  }) async {
    return waitFor(
      () => _value != null,
      timeout: timeout,
      pollInterval: pollInterval,
      raiseOnTimeout: raiseOnTimeout,
    );
  }
}
