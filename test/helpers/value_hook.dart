import 'dart:async';

import 'package:test/test.dart' as test show expect, Matcher, TestFailure;

/// Useful to easily test handler functions
/// that set values outside of their scope.
///
/// ```dart
/// // Construct VHook with no initial value
/// VHook calledHandler = VHook.empty();
///
/// willCallHandler(() {
///   // Some handler code
///   // ...
///   calledHandler.complete();
/// });
///
/// // Test that the handler was called
/// // If the handler was not called after 5s, throw an error
/// calledHandler.awaitCompletion(Duration(seconds: 5));
/// ```
class VHook<T> {
  /// The value of the variable.
  late T _value;

  /// Whether a value is present.
  bool _hasValue = false;

  /// The error that might be completed with.
  Object? _error;

  /// Flag that indicates that the value reached it's final state.
  final _completer = Completer<T>();

  /// Stream used to subscribe to value changes
  ///
  /// Used to allow awaiting values with [awaitValue]
  final _stream = StreamController<T>.broadcast();

  /// Construct a new ValueHook with the given initial value.
  VHook(this._value) : _hasValue = true;

  /// Construct a new ValueHook with no initial value.
  ///
  /// Please check [hasValue] before directly accessing
  /// [value] if you use this constructor.
  VHook.empty();

  /// Set the value of the variable.
  void set(T val) {
    // Do not change value if already completed
    _assertNotCompleted();

    // Note presence of value
    _hasValue = true;

    // Update value
    _value = val;

    // Notify listeners
    _stream.add(val);
  }

  /// Complete with the given value.
  void completeValue(T val) {
    // Update value
    set(val);

    // Complete with newly updated value
    complete();
  }

  /// Complete with the current value.
  void complete() {
    // Can not complete multiple times
    _assertNotCompleted();

    // Close stream
    _stream.close();

    // Complete value
    _completer.complete(_value);
  }

  /// Complete with an error or exception
  void completeError(Object error) {
    // Can not complete multiple times
    _assertNotCompleted();

    // Save error
    _error = error;

    // Publish error to all listeners
    _stream.addError(error);

    // Complete with error
    _completer.completeError(error);
  }

  /// Update value with the return of [updater] which takes
  /// the current value as its only argument.
  ///
  /// The new value is returned.
  ///
  /// [updater] will not be called if no value has been set, use
  /// [orElse] to provide a fallback in such a case. An error will be
  /// thrown if neither [updater] nor [orElse] can be used.
  ///
  /// Please note that providing a wrapped `Future<T>` withing a [VHookValue]
  /// to [orElse] will throw an [ArgumentError].
  ///
  /// ```dart
  /// // Construct VHook with initial value
  /// VHook<int> myHook = VHook<int>(someInteger);
  ///
  /// // Raise the current value (any value) to the power of two (x^2)
  /// int newVal = myHook.update((int val) => val*val);
  /// ```
  T update(T Function(T) updater, {VHookValue<T>? orElse}) {
    // Do not change value if already completed
    _assertNotCompleted();

    if (hasValue) {
      // Some value already set -> type guarantee -> can use updater
      set(updater(_value));
    } else if (orElse != null) {
      // No value set + fallback provided -> use fallback
      final FutureOr<T> value = orElse.value;

      /// Don't accept Future<T>
      if (value is Future) {
        throw ArgumentError("Please use 'updateAsync' for a fallback of type 'Future<T>'");
      }

      set(value);
    } else {
      throw StateError('Attempted to update value before initial set without fallback');
    }

    return _value;
  }

  /// Update value with the return of [updater] which takes
  /// the current value as its only argument.
  ///
  /// The new value is returned.
  ///
  /// [updater] will not be called if no value has been set, use
  /// [orElse] to provide a fallback in such a case, which can be a [Future]
  /// whose completion value will be used. An error will be
  /// thrown if neither [updater] nor [orElse] can be used.
  ///
  /// ```dart
  /// // Construct VHook with initial value
  /// VHook<String> myHook = VHook<String>(someFileName);
  ///
  /// // Use current value as filename and set content of that file
  /// // as new value
  /// String content = await myHook.updateAsync(
  ///   (String name) async => await File(name).readAsString()
  /// );
  /// ```
  Future<T> updateAsync(Future<T> Function(T) updater, {VHookValue<T>? orElse}) async {
    // Do not change value if already completed
    _assertNotCompleted();

    if (hasValue) {
      // Some value already set -> type guarantee -> can use updater
      set(await updater(_value));
    } else if (orElse != null) {
      // No value set + fallback provided -> use fallback
      // Handle both value and Future fallbacks
      final FutureOr<T> fallbackValue = orElse.value;
      if (fallbackValue is Future) {
        set(await fallbackValue);
      } else {
        set(fallbackValue);
      }
    } else {
      throw StateError('Attempted to update value before initial set without fallback');
    }

    return _value;
  }

  /// Obtain the current value.
  ///
  /// This will throw if no value has been assigned yet.
  /// Check with [hasValue] before.
  T get value => hasValue ? _value : throw StateError('No value set yet');

  /// Whether a value is present.
  ///
  /// Precondition before accessing [value].
  bool get hasValue => _hasValue;

  /// Obtain completion error.
  ///
  /// This will throw if not already completed with error.
  /// Check with [hasError] before.
  Object get error => hasError ? _error! : throw StateError('Did not complete with error');

  /// Whether an error is present.
  ///
  /// Precondition before accessing [error].
  bool get hasError => _error != null;

  /// Check the value of the variable.
  ///
  /// This method uses 'expect' from the 'test' package.
  ///
  /// [matcher] is used to test for the expected value
  /// e.g. `equals(true)`
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

  /// Wait for the value to conform to [matcher].
  ///
  /// The optional [timeout] specifies the maximum time to wait for the match
  /// before a [TimeoutException] is thrown.
  ///
  /// By default all intermediate states are checked, to only check after
  /// completion enable [onlyOnCompletion].
  ///
  /// This method uses 'expect' from the 'test' package.
  ///
  /// [matcher] is used to test for the expected value
  /// e.g. `equals(true)`
  Future<void> expectAsync(
    test.Matcher matcher, {
    String? reason,
    dynamic skip,
    Duration? timeout,
    bool onlyOnCompletion = false,
  }) async {
    if (onlyOnCompletion) {
      // Only check after completion
      await awaitCompletion(timeout);
    } else {
      // Check all intermediate states
      try {
        await awaitValue(
          timeout: timeout,
          condition: (T val) {
            try {
              test.expect(
                _value,
                matcher,
                reason: reason,
                skip: skip,
              );

              return true;
            } on test.TestFailure {
              return false;
            }
          },
        );
      } on TimeoutException {
        // We catch TimeoutException to show the results of
        // matching the most current value (the [TestFailure])
      }
    }

    test.expect(
      _value,
      matcher,
      reason: reason,
      skip: skip,
    );
  }

  /// Get awaitable that completes when the contained value is set.
  ///
  /// The optional [timeout] specifies the maximum time to wait for the value
  /// before a [TimeoutException] is thrown.
  /// You can specify a custom [condition] which takes the current value after
  /// each update and must return a bool that indicates if it is met. Note that
  /// [condition] is not called when the value is not yet set.
  ///
  /// The returned Future's completion value is whether the value was set (true)
  /// or whether the timeout was reached (false).
  ///
  /// ```dart
  /// // Construct VHook with no initial value
  /// VHook<int> conditionValue = VHook<int>.empty();
  ///
  /// // This function is supposed to call the handler soon
  /// willCallHandlerAsyncRecurring(() {
  ///   if (someCondition) {
  ///     conditionValue.set(42);
  ///   } else {
  ///     conditionValue.set(17);
  ///   }
  /// });
  ///
  /// // Wait for the handler to be called and value set to <= 20
  /// // If the conditions are not met after 5s, throw an error
  /// await conditionValue.awaitValue(
  ///   timeout: Duration(seconds: 5),
  ///   condition: (int val) => val <= 20,
  /// );
  /// ```
  Future<T> awaitValue({Duration? timeout, bool Function(T)? condition}) async {
    // Wrap condition to ensure correct handling
    bool wrappedCond(T val) {
      // Don't test without value
      if (!hasValue) return false;

      // Test condition if specified
      if (condition != null) {
        return condition(val);
      }

      // No custom condition specified, value recieved -> complete
      return true;
    }

    // Throw if already completed with error
    _assertNotCompletedError();

    // Check current value
    if (wrappedCond(_value)) return _value;

    // Throw if already completed as no updates are expected
    _assertNotCompleted();

    // Subscribe to changes and find first that satisfies [condition]
    Future<T> value = _stream.stream.firstWhere(wrappedCond);

    // Add optional timeout
    if (timeout != null) value = value.timeout(timeout);

    // Wait for condition to be met
    return await value;
  }

  /// Wait for and return the completed value.
  ///
  /// When specified [timeout] is waited for completion
  /// before a [TimeoutException] is thrown.
  ///
  /// ```dart
  /// // Construct VHook with no initial value
  /// VHook<int> conditionValue = VHook<int>.empty();
  ///
  /// // This function is supposed to call the handler soon
  /// willCallHandlerAsyncRecurring(() {
  ///   // These will not cause the [conditionValue] to complete
  ///   if (someCondition) {
  ///     conditionValue.set(42);
  ///   } else {
  ///     conditionValue.complete(17);
  ///   }
  ///
  ///   // You have so specifically signal completion
  ///   if (someRarerCondition) {
  ///     conditionValue.complete();
  ///   }
  /// });
  ///
  /// // Wait for the conditionValue to be completed
  /// // If not completed after 5s, throw an error
  /// await conditionValue.awaitCompletion(timeout: Duration(seconds: 5));
  /// ```
  Future<T> awaitCompletion([Duration? timeout]) async {
    if (timeout != null) {
      return await _completer.future.timeout(
        timeout,
        onTimeout: () => throw TimeoutException('Timed out awaiting value'),
      );
    }

    return await _completer.future;
  }

  /// Assert that the value is not yet completed
  void _assertNotCompleted() {
    if (_completer.isCompleted) {
      throw StateError(
        'VHook is completed with a value that does not satisfy the provided condition',
      );
    }
  }

  /// Assert that value is not yet completed with an error
  ///
  /// Will throw [_error] if set
  void _assertNotCompletedError() {
    if (_error != null) throw _error!;
  }
}

/// Used to encapsulate a value.
///
/// This is useful to distinguish  between the value `null`
/// and 'argument not specified' for optional arguments.
class VHookValue<T> {
  /// Value encapsulated
  final FutureOr<T> value;

  const VHookValue(this.value);
}
