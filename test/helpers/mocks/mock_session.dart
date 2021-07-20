/// Mock implementation of sesseion to test simple middleware
class MockSession {
  final Map<dynamic, dynamic> storage = <dynamic, dynamic>{};

  void raise(Object e) {}
}
