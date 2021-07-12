import 'package:test/test.dart' as test show expect, Matcher;

/// Useful to easily test handler functions
///  to set values outside of their scope.
///
/// ```dart
/// // Construct VHook with initial value of 'false'
/// VHook<bool> calledHandler = VHook<bool>(false);
///
/// willCallHandler((){
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
  T? value;

  /// Construct a new VariableHook with the given initial value.
  VHook(T this.value);

  /// Set the value of the variable.
  void set(T val) => value = val;

  /// Check the value of the variable.
  ///
  /// This method uses 'expect' from the 'test' package.
  /// [val] is the expected value e.g. `equals(true)`
  void expect(
    dynamic val, {
    String? reason,
    dynamic skip,
    @Deprecated("Deprecated in 'test' package, does nothing") bool verbose = false,
    @Deprecated("Deprecated in 'test' package, does nothing")
        String Function(dynamic, test.Matcher, String?, Map<dynamic, dynamic>, bool)? formatter,
  }) =>
      test.expect(
        value,
        val,
        reason: reason,
        skip: skip,
      );
}
