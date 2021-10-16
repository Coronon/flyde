import 'dart:async';
import 'dart:io';
import 'package:test/test.dart';

import 'package:flyde/core/networking/websockets/session.dart';
import 'package:flyde/core/networking/websockets/middleware.dart';

import '../../../helpers/value_hook.dart';
import '../../../helpers/wait_for.dart';
import '../../../helpers/mocks/mock_exception.dart';

void main() {
  late HttpServer? server;
  late Uri? url;

  setUp(() async {
    server = await HttpServer.bind('localhost', 0);
    url = Uri.parse('ws://${server!.address.host}:${server!.port}');
  });

  tearDown(() async {
    await server!.close(force: true);
    server = null;
    url = null;
  });

  test('Server can receive; Client can send', () async {
    final msgReceived = VHook<String>.empty();

    server!.listen((HttpRequest request) {
      final ServerSession sess = ServerSession(request);
      sess.onMessage = (ServerSession sess, dynamic msg) async {
        msgReceived.completeValue(msg);

        return msg;
      };
    });

    // Connect to WebServer and open ServerSession
    final ClientSession client = ClientSession(url.toString());
    client.send('ANYTHING');

    // Wait for msgs to be received and check received data
    await msgReceived.expectAsync(
      equals('ANYTHING'),
      timeout: Duration(seconds: 5),
      onlyOnCompletion: true,
    );

    // Teardown
    client.close();
  });
  test('Server can send; Client can receive', () async {
    final msgReceived = VHook<String>.empty();

    server!.listen((HttpRequest request) {
      final ServerSession sess = ServerSession(request);
      sess.send('ANYTHING');
    });

    // Connect to WebServer and open ServerSession
    final ClientSession client = ClientSession(url.toString());
    //? This is not a race condition, because of how the dart eventloop is implemented
    //? The internal 'WebSocket.connect' is scheduled and executed when this strain waits (await)
    client.onMessage = (ClientSession sess, dynamic msg) async {
      msgReceived.completeValue(msg);
      return null;
    };

    // Wait for msgs to be received and check received data
    await msgReceived.expectAsync(
      equals('ANYTHING'),
      timeout: Duration(seconds: 5),
      onlyOnCompletion: true,
    );

    // Teardown
    client.close();
  });
  test('Middleware is run', () async {
    final msgClientReceived = VHook<bool>.empty();
    // First middleware
    final middlewareServerReceived1 = VHook<String>.empty();
    final middlewareServerSend1 = VHook<String>.empty();
    final middlewareClientReceived1 = VHook<String>.empty();
    final middlewareClientSend1 = VHook<String>.empty();
    // Second middleware
    final middlewareServerReceived2 = VHook<String>.empty();
    final middlewareServerSend2 = VHook<String>.empty();
    final middlewareClientReceived2 = VHook<String>.empty();
    final middlewareClientSend2 = VHook<String>.empty();

    // Two middleware functions to test 'next' behaviour
    Future<dynamic> middlewareFunc1(
      dynamic session,
      dynamic message,
      MiddlewareAction action,
      Future<dynamic> Function(dynamic) next,
    ) async {
      if (session is ServerSession) {
        if (action == MiddlewareAction.receive) {
          middlewareServerReceived1.completeValue(message);
        } else {
          middlewareServerSend1.completeValue(message);
        }
      } else {
        if (action == MiddlewareAction.receive) {
          middlewareClientReceived1.completeValue(message);
        } else {
          middlewareClientSend1.completeValue(message);
        }
      }

      return await next(message);
    }

    Future<dynamic> middlewareFunc2(
      dynamic session,
      dynamic message,
      MiddlewareAction action,
      Future<dynamic> Function(dynamic) next,
    ) async {
      if (session is ServerSession) {
        if (action == MiddlewareAction.receive) {
          middlewareServerReceived2.completeValue(message);
        } else {
          middlewareServerSend2.completeValue(message);
        }
      } else {
        if (action == MiddlewareAction.receive) {
          middlewareClientReceived2.completeValue(message);
        } else {
          middlewareClientSend2.completeValue(message);
        }
      }

      return await next(message);
    }

    final List<MiddlewareFunc> middleware = <MiddlewareFunc>[middlewareFunc1, middlewareFunc2];

    server!.listen((HttpRequest request) {
      final ServerSession sess = ServerSession(request);
      sess.middleware = middleware;
      sess.onMessage = (ServerSession sess, dynamic msg) async {
        expect(msg, equals('ANYTHING-1'));
        sess.send('ANYTHING-2');
      };
    });

    // Connect to WebServer and open ServerSession
    final ClientSession client = ClientSession(url.toString());
    //? This is not a race condition, because of how the dart eventloop is implemented
    //? The internal 'WebSocket.connect' is scheduled and executed when this strain waits (await)
    client.middleware = middleware;
    client.onMessage = (ClientSession sess, dynamic msg) async {
      expect(msg, equals('ANYTHING-2'));
      msgClientReceived.completeValue(true);
    };

    // Send messages
    client.send('ANYTHING-1');

    // Wait for msgs to be received and check received data
    await msgClientReceived.expectAsync(
      isTrue,
      timeout: Duration(seconds: 5),
      onlyOnCompletion: true,
    );

    await middlewareServerReceived1.expectAsync(
      equals('ANYTHING-1'),
      timeout: Duration(seconds: 5),
      onlyOnCompletion: true,
    );
    await middlewareServerSend1.expectAsync(
      equals('ANYTHING-2'),
      timeout: Duration(seconds: 5),
      onlyOnCompletion: true,
    );
    await middlewareClientReceived1.expectAsync(
      equals('ANYTHING-2'),
      timeout: Duration(seconds: 5),
      onlyOnCompletion: true,
    );
    await middlewareClientSend1.expectAsync(
      equals('ANYTHING-1'),
      timeout: Duration(seconds: 5),
      onlyOnCompletion: true,
    );

    await middlewareServerReceived2.expectAsync(
      equals('ANYTHING-1'),
      timeout: Duration(seconds: 5),
      onlyOnCompletion: true,
    );
    await middlewareServerSend2.expectAsync(
      equals('ANYTHING-2'),
      timeout: Duration(seconds: 5),
      onlyOnCompletion: true,
    );
    await middlewareClientReceived2.expectAsync(
      equals('ANYTHING-2'),
      timeout: Duration(seconds: 5),
      onlyOnCompletion: true,
    );
    await middlewareClientSend2.expectAsync(
      equals('ANYTHING-1'),
      timeout: Duration(seconds: 5),
      onlyOnCompletion: true,
    );

    // Teardown
    client.close();
  });
  test('OnDone is called', () async {
    final onDoneServerCalled = VHook.empty();
    final onDoneClientCalled = VHook.empty();

    server!.listen((HttpRequest request) {
      final ServerSession sess = ServerSession(request);
      sess.onDone = (ServerSession sess) {
        onDoneServerCalled.complete();
      };
    });

    // Connect to WebServer and open ServerSession
    final ClientSession client = ClientSession(url.toString());
    //? This is not a race condition, because of how the dart eventloop is implemented
    //? The internal 'WebSocket.connect' is scheduled and executed when this strain waits (await)
    client.onDone = (ClientSession sess) {
      onDoneClientCalled.complete();
    };
    client.close();

    // Wait for handlers to be called
    await onDoneServerCalled.awaitCompletion(Duration(seconds: 5));
    await onDoneClientCalled.awaitCompletion(Duration(seconds: 5));
  });
  test('Storage is persisted', () async {
    final serverSession = VHook<ServerSession>.empty();
    final serverPersisted = VHook.empty();
    final clientPersisted = VHook.empty();

    server!.listen((HttpRequest request) {
      serverSession.completeValue(ServerSession(request));
      serverSession.value.onMessage = (ServerSession sess, dynamic msg) async {
        sess.storage['msg'] = msg;
        serverPersisted.complete();
        sess.send('ANYTHING-2');
      };
    });

    // Connect to WebServer and open ServerSession
    final ClientSession client = ClientSession(url.toString());
    //? This is not a race condition, because of how the dart eventloop is implemented
    //? The internal 'WebSocket.connect' is scheduled and executed when this strain waits (await)
    client.onMessage = (ClientSession sess, dynamic msg) async {
      sess.storage['msg'] = msg;
      clientPersisted.complete();
    };

    // Send messages
    client.send('ANYTHING-1');

    // Wait for msgs to be persisted and check persisted data
    await serverSession.expectAsync(
      isA<ServerSession>(),
      timeout: Duration(seconds: 5),
      onlyOnCompletion: true,
    );
    await serverPersisted.awaitCompletion(Duration(seconds: 5));
    await clientPersisted.awaitCompletion(Duration(seconds: 5));

    expect(serverSession.value.storage['msg'], equals('ANYTHING-1'));
    expect(client.storage['msg'], equals('ANYTHING-2'));

    //* Check storage is erased on close
    client.close();

    // Wait for storage to be erased
    await waitFor(
      () => client.storage.isEmpty,
      timeout: Duration(seconds: 5),
      raiseOnTimeout: true,
    );

    // Check 'msg' not in storage
    expect(client.storage['msg'], isNull);
  });
  test('OnError is called', () async {
    final exceptionServer = VHook<Object>.empty();
    final exceptionClient = VHook<Object>.empty();

    //* Test server
    final StreamSubscription<HttpRequest> sub = server!.listen((HttpRequest request) {
      final ServerSession sess = ServerSession(request);
      sess.onMessage = (ServerSession sess, dynamic msg) async {
        sess.raise(MockException(msg));
      };
      sess.onError = (ServerSession sess, Object ex) {
        exceptionServer.completeValue(ex);
      };
    });

    // Connect to WebServer and open ServerSession
    ClientSession client = ClientSession(url.toString());
    client.send('ANYTHING-1');

    // Wait for handlers to be called and check exception
    await exceptionServer.expectAsync(
      isA<MockException>().having(
        (MockException e) => e.message,
        'message',
        equals('ANYTHING-1'),
      ),
      timeout: Duration(seconds: 5),
      onlyOnCompletion: true,
    );

    //* Test client
    sub.onData((HttpRequest request) {
      final ServerSession sess = ServerSession(request);
      sess.send('ANYTHING-2');
    });
    await client.close();

    // Connect to WebServer and open ServerSession
    client = ClientSession(url.toString());
    //? This is not a race condition, because of how the dart eventloop is implemented
    //? The internal 'WebSocket.connect' is scheduled and executed when this strain waits (await)
    client.onMessage = (ClientSession sess, dynamic msg) async {
      sess.raise(MockException(msg));
    };
    client.onError = (ClientSession sess, Object ex) {
      exceptionClient.completeValue(ex);
    };

    // Wait for handlers to be called and check exception
    await exceptionClient.expectAsync(
      isA<MockException>().having(
        (MockException e) => e.message,
        'message',
        equals('ANYTHING-2'),
      ),
      timeout: Duration(seconds: 5),
      onlyOnCompletion: true,
    );
  });
  test('OnMessage return is send', () async {
    final msgReceivedFromServer = VHook<String>.empty();
    final msgReceivedFromClient = VHook<String>.empty();

    //* Test server
    final StreamSubscription<HttpRequest> sub = server!.listen((HttpRequest request) {
      final ServerSession sess = ServerSession(request);
      sess.onMessage = (ServerSession sess, dynamic msg) async {
        return 'ANYTHING-RETURN-1';
      };
    });

    // Connect to WebServer and open ServerSession
    ClientSession client = ClientSession(url.toString());
    //? This is not a race condition, because of how the dart eventloop is implemented
    //? The internal 'WebSocket.connect' is scheduled and executed when this strain waits (await)
    client.onMessage = (ClientSession sess, dynamic msg) async {
      msgReceivedFromServer.completeValue(msg);
    };

    // Send message to trigger onMessage return
    client.send('ANYTHING');

    // Wait for msgs to be received and check received data
    await msgReceivedFromServer.expectAsync(
      equals('ANYTHING-RETURN-1'),
      timeout: Duration(seconds: 5),
      onlyOnCompletion: true,
    );

    //* Test client
    sub.onData((HttpRequest request) {
      final ServerSession sess = ServerSession(request);
      sess.onMessage = (ServerSession sess, dynamic msg) async {
        msgReceivedFromClient.completeValue(msg);
      };

      // Send message to trigger onMessage return
      sess.send('ANYTHING');
    });
    await client.close();

    // Connect to WebServer and open ServerSession
    client = ClientSession(url.toString());
    //? This is not a race condition, because of how the dart eventloop is implemented
    //? The internal 'WebSocket.connect' is scheduled and executed when this strain waits (await)
    client.onMessage = (ClientSession sess, dynamic msg) async {
      return 'ANYTHING-RETURN-2';
    };

    // Wait for msgs to be received and check received data
    await msgReceivedFromClient.expectAsync(
      equals('ANYTHING-RETURN-2'),
      timeout: Duration(seconds: 5),
      onlyOnCompletion: true,
    );

    // Teardown
    client.close();
  });
}
