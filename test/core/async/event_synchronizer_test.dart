import 'package:test/test.dart';

import 'package:flyde/core/async/event_synchronizer.dart';

import '../../helpers/mocks/mock_io_client.dart';
import '../../helpers/value_hook.dart';

void main() {
  late MockIOCLient client;
  late EventSynchronizer sync;

  setUp(() {
    client = MockIOCLient();
    sync = EventSynchronizer(client.send);

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
    final firstHook = VHook.empty();
    final secondHook = VHook.empty();

    Stream<String> streamCreator() async* {
      yield 'test1';
      yield 'test2';
    }

    client.onSent = (dynamic message) {
      if (message == 'test1') {
        firstHook.complete();
      } else if (message == 'test2') {
        secondHook.complete();
      }
    };

    await sync.request(streamCreator());

    await firstHook.awaitCompletion(Duration(milliseconds: 1));
    await secondHook.awaitCompletion(Duration(milliseconds: 1));
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
    final receivedHook = VHook.empty();
    await sync.request('echo many');
    await sync.expect(
      String,
      validator: (String resp) {
        if (resp == 'right') {
          receivedHook.complete();
          return true;
        }

        return false;
      },
      keepAlive: true,
    );

    await receivedHook.awaitCompletion(Duration(milliseconds: 1));
  });
}
