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
    final messageHook = VHook<String>.empty();

    isolate.receivePort.listen((dynamic message) {
      if (message is String) {
        messageHook.completeValue(message);
      }
    });

    await messageHook.expectAsync(
      isNot(equals(Isolate.current.debugName)),
      timeout: Duration(milliseconds: 100),
      onlyOnCompletion: true,
    );
  });

  test('Isolates can communicate in both directions', () async {
    final isolate = await connect(ReceivePort(), _echo);
    final sendPortHook = VHook.empty();
    final messageHook = VHook<String>.empty();
    const testMessage = 'test';

    isolate.receivePort.listen((dynamic message) {
      if (message is SendPort) {
        isolate.sendPort = message;
        sendPortHook.complete();
      }

      if (message is String) {
        messageHook.completeValue(message);
      }
    });

    await sendPortHook.awaitCompletion(Duration(milliseconds: 100));
    isolate.sendPort.send(testMessage);
    await messageHook.expectAsync(
      equals(testMessage),
      timeout: Duration(milliseconds: 100),
      onlyOnCompletion: true,
    );
  });
}
