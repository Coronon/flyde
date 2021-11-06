/// Class used to mock I/O communication.
class MockIOCLient {
  Future<void> Function(dynamic)? onMessage;
  void Function(dynamic)? onSent;

  Future<void> send(dynamic message) async {
    onSent?.call(message);

    if (message == 'echo') {
      onMessage?.call('echo');
    }

    if (message == 'echo 1') {
      onMessage?.call(1);
    }

    if (message == 'echo 2') {
      onMessage?.call(2);
    }

    if (message == 'echo many') {
      onMessage?.call('wrong 1');
      onMessage?.call('wrong 2');
      onMessage?.call('wrong 3');
      onMessage?.call('wrong 4');
      onMessage?.call('wrong 5');
      onMessage?.call('right');
    }
  }
}
