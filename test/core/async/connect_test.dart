import 'dart:async';
import 'dart:isolate';

import 'package:flyde/core/async/connect.dart';
import 'package:test/test.dart';

/// [SpawnFunc] which sends the isolate's debug name.
void _sendIsolateName(SendPort send, ReceivePort receive) async {
  send.send(Isolate.current.debugName);
}

/// [SpawnFunc] which acts as an echo server.
void _echo(SendPort send, ReceivePort receive) async => receive.listen(send.send);

void main() {
  test('Spawn function is called in new isolate', () async {
    final isolate = await connect(ReceivePort(), _sendIsolateName);
    final completer = Completer<String>();

    isolate.receivePort.listen((dynamic message) {
      if (message is String) {
        completer.complete(message);
      }
    });

    expect(
      await completer.future,
      isNot(equals(Isolate.current.debugName)),
    );
  });

  test('Isolates can communicate in both directions', () async {
    final isolate = await connect(ReceivePort(), _echo);
    final sendPortCompleter = Completer<void>();
    final messageCompleter = Completer<String>();
    const testMessage = 'test';

    isolate.receivePort.listen((dynamic message) {
      if (message is SendPort) {
        isolate.sendPort = message;
        sendPortCompleter.complete();
      }

      if (message is String) {
        messageCompleter.complete(message);
      }
    });

    await sendPortCompleter.future;
    isolate.sendPort.send(testMessage);

    expect(await messageCompleter.future, equals(testMessage));
  });
}
