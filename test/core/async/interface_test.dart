import 'dart:isolate';

import 'package:flyde/core/async/connect.dart';
import 'package:flyde/core/async/interface.dart';
import 'package:test/test.dart';

/// An implementation of [Interface] for testing.
class _TestInterface extends Interface {
  /// Static [_TestInterface] object, which is used in the spawned isolate.
  static _TestInterface? instance;

  _TestInterface(SpawnedIsolate isolate) : super(isolate);

  /// Creates the interface on the main thread.
  static Future<_TestInterface> create() async {
    return _TestInterface(await connect(ReceivePort(), spawn));
  }

  /// Creates the interface on the child thread.
  static void spawn(SendPort sendPort, ReceivePort receivePort) {
    instance = _TestInterface(SpawnedIsolate(Isolate.current, receivePort)..sendPort = sendPort);
  }

  @override
  Future<void> onMessage(InterfaceMessage message) async {
    if (message.name == 'echo') {
      message.send(isolate.sendPort, isResponse: true);
    }

    if (message.name == 'respond-with-true') {
      message.respond(isolate.sendPort, true);
    }
  }
}

void main() {
  test('"instance" is not changed in main isolate.', () async {
    await _TestInterface.create();

    //? Wait to ensure the isolate has been spawned.
    await Future.delayed(Duration(milliseconds: 100));

    expect(_TestInterface.instance, isNull);
  });

  test('Isolate can respond to messages.', () async {
    final main = await _TestInterface.create();
    final String response = await main.expectResponse(InterfaceMessage('echo', 'hello'));

    expect(response, equals('hello'));
  });

  test('Requests can time out', () async {
    final main = await _TestInterface.create();

    await expectLater(
      main.expectResponse(
        InterfaceMessage('any', null),
        timeout: Duration(seconds: 1),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('Throws an error when response has unexpected type', () async {
    final main = await _TestInterface.create();

    await expectLater(
      main.expectResponse<String>(InterfaceMessage('echo', 5)),
      throwsA(isA<InvalidMessageException>()),
    );
  });

  test('Can respond to messages using the "respond" method', () async {
    final main = await _TestInterface.create();

    await expectLater(
      main.expectResponse(InterfaceMessage('respond-with-true', null)),
      completion(equals(true)),
    );
  });
}
