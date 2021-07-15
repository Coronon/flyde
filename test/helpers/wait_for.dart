import 'dart:async';

/// Get awaitable that completes when the [test] evaluates to true.
///
/// The optional [timeout] specifies the maximum time to wait.
/// [pollInterval] specifies the time between `test()` checks.
/// If [raiseOnTimeout] is true, this function will throw if the timeout is reached.
///
/// The returned Future's completion value is whether the test was successful (true)
/// or whether the timeout was reached (false).
///
/// ```dart
/// // The 'Flag' class has a 'value' attribute in this example
/// // It will somehow be set to 'true' in the future
/// Flag someFlag = Flag();
///
/// // This function is supposed set the flag after some time
/// willSetFlag(someFlag);
///
/// // Wait for the Flag to be set
/// waitFor(() => someFlag.value, timeout: Duration(seconds: 5), raiseOnTimeout: true);
/// ```
Future<bool> waitFor(
  bool Function() test, {
  Duration? timeout,
  Duration pollInterval = Duration.zero,
  bool raiseOnTimeout = false,
}) {
  // Handle optional timeout
  DateTime? expireTime;
  if (timeout != null) {
    expireTime = DateTime.now().add(timeout);
  }

  Completer<bool> completer = Completer<bool>();
  // Check if test is true
  check() {
    if (test()) {
      completer.complete(true);
    } else if (expireTime != null && DateTime.now().isAfter(expireTime)) {
      if (raiseOnTimeout) throw TimeoutException("Timed out awaiting value");

      completer.complete(false);
    } else {
      Timer(pollInterval, check);
    }
  }

  check();
  return completer.future;
}
