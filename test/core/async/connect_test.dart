import 'dart:async';
import 'dart:isolate';

import 'package:test/test.dart';
import 'package:flyde/core/async/connect.dart';

import '../../helpers/value_hook.dart';

/// [SpawnFunc] which sends the isolate's debug name.
void _sendIsolateName(SendPort send, ReceivePort receive) async {
  send.send(Isolate.current.debugName);
}

/// [SpawnFunc] which acts as an echo server.
void _echo(SendPort send, ReceivePort receive) async => receive.listen(send.send);

void main() {
  test('Spawn function is called in new isolate', () async {
    final isolate = await connect(ReceivePort(), _sendIsolateName);
    final messageHook = VHook<String?>(null);

    isolate.receivePort.listen((dynamic message) {
      if (message is String) {
        messageHook.set(message);
      }
    });

    await messageHook.awaitValue(Duration(milliseconds: 100));

    expect(
      messageHook.value,
      isNot(equals(Isolate.current.debugName)),
    );
  });

  test('Isolates can communicate in both directions', () async {
    final isolate = await connect(ReceivePort(), _echo);
    final sendPortHook = VHook<bool?>(null);
    final messageHook = VHook<String?>(null);
    const testMessage = 'test';

    isolate.receivePort.listen((dynamic message) {
      if (message is SendPort) {
        isolate.sendPort = message;
        sendPortHook.set(true);
      }

      if (message is String) {
        messageHook.set(message);
      }
    });

    await sendPortHook.awaitValue(Duration(milliseconds: 100));
    isolate.sendPort.send(testMessage);
    await messageHook.awaitValue(Duration(milliseconds: 100));

    expect(messageHook.value, equals(testMessage));
  });
}
