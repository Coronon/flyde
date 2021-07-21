/// Mock exception used for testing
class MockException implements Exception {
  final String message;

  const MockException(this.message);

  @override
  String toString() => message;
}
