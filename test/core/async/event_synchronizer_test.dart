import 'package:flyde/core/async/event_synchronizer.dart';
import 'package:test/test.dart';

import '../../helpers/value_hook.dart';

/// Class used to mock I/O communication.
class _MockIOCLient {
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

void main() {
  late _MockIOCLient client;
  late EventSynchronizer sync;

  setUp(() {
    client = _MockIOCLient();
    sync = EventSynchronizer(client.send, Duration(milliseconds: 1));

    client.onMessage = sync.handleMessage;
  });

  test('Can send and expect the echo', () async {
    await sync.request('echo');
    await sync.expect(String, handler: (String resp) => expect(resp, equals('echo')));
  });

  test('Fails if the wrong type is received', () async {
    await sync.request('echo');

    await expectLater(
      sync.expect(int),
      throwsArgumentError,
    );
  });

  test('Can validate responses', () async {
    await sync.request('echo');

    await expectLater(
      sync.expect(String, validator: (String resp) => resp != 'echo'),
      throwsArgumentError,
    );
  });

  test('Can transform responses', () async {
    await sync.request('echo');

    await expectLater(
      sync.expect(String, handler: (String resp) => resp == 'echo' ? 1 : 2),
      completion(equals(1)),
    );
  });

  test('Can transform and validate responses', () async {
    await sync.request('echo');

    await expectLater(
      sync.expect(
        String,
        handler: (String resp) => resp == 'echo' ? 1 : 2,
        validator: (String resp) => resp == 'echo',
      ),
      completion(equals(1)),
    );
  });

  test('Requests each stream item', () async {
    final firstHook = VHook<bool?>(null);
    final secondHook = VHook<bool?>(null);

    Stream<String> streamCreator() async* {
      yield 'test1';
      yield 'test2';
    }

    client.onSent = (dynamic message) {
      if (message == 'test1') {
        firstHook.set(true);
      } else if (message == 'test2') {
        secondHook.set(true);
      }
    };

    await sync.request(streamCreator());
    await firstHook.awaitValue(Duration(milliseconds: 1));
    await secondHook.awaitValue(Duration(milliseconds: 1));

    firstHook.expect(equals(true));
    secondHook.expect(equals(true));
  });

  test('Can exchange a data stream', () async {
    Stream<String> streamCreator() async* {
      yield 'echo 1';
      yield 'echo 2';
    }

    final List<int> results = await sync.exchange(
      streamCreator(),
      int,
      handler: (String item, int resp) {
        if (item == 'echo 1') {
          expect(resp, equals(1));
        } else if (item == 'echo 2') {
          expect(resp, equals(2));
        }

        return resp;
      },
    ).toList();

    expect(results, orderedEquals([1, 2]));
  });

  test('Can validate each stream item', () async {
    Stream<String> streamCreator() async* {
      yield 'echo 1';
      yield 'echo 2';
    }

    await expectLater(
      sync
          .exchange(
            streamCreator(),
            int,
            validator: (String item, int resp) => resp != 2,
          )
          .toList(),
      throwsArgumentError,
    );
  });

  test('Can ignore messages until the right one is received', () async {
    final receivedHook = VHook<bool?>(null);
    await sync.request('echo many');
    await sync.expect(
      String,
      validator: (String resp) {
        if (resp == 'right') {
          receivedHook.set(true);
          return true;
        }

        return false;
      },
      keepAlive: true,
    );

    await receivedHook.awaitValue(Duration(milliseconds: 1));
    receivedHook.expect(equals(true));
  });
}
