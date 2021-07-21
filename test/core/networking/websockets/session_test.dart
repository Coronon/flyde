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
    final msgReceived = VHook<String?>(null);

    server!.listen((HttpRequest request) {
      final ServerSession sess = ServerSession(request);
      sess.onMessage = (ServerSession sess, dynamic msg) async {
        msgReceived.set(msg);

        return msg;
      };
    });

    // Connect to WebServer and open ServerSession
    final ClientSession client = ClientSession(url.toString());
    client.send('ANYTHING');

    // Wait for msgs to be received
    await msgReceived.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);

    // Check received data
    msgReceived.expect(equals('ANYTHING'));

    // Teardown
    client.close();
  });
  test('Server can send; Client can receive', () async {
    final msgReceived = VHook<String?>(null);

    server!.listen((HttpRequest request) {
      final ServerSession sess = ServerSession(request);
      sess.send('ANYTHING');
    });

    // Connect to WebServer and open ServerSession
    final ClientSession client = ClientSession(url.toString());
    //? This is not a race condition, because of how the dart eventloop is implemented
    //? The internal 'WebSocket.connect' is scheduled and executed when this strain waits (await)
    client.onMessage = (ClientSession sess, dynamic msg) async {
      msgReceived.set(msg);
      return null;
    };

    // Wait for msgs to be received
    await msgReceived.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);

    // Check received data
    msgReceived.expect(equals('ANYTHING'));

    // Teardown
    client.close();
  });
  test('Middleware is run', () async {
    final msgClientReceived = VHook<bool?>(null);
    // First middleware
    final middlewareServerReceived1 = VHook<String?>(null);
    final middlewareServerSend1 = VHook<String?>(null);
    final middlewareClientReceived1 = VHook<String?>(null);
    final middlewareClientSend1 = VHook<String?>(null);
    // Second middleware
    final middlewareServerReceived2 = VHook<String?>(null);
    final middlewareServerSend2 = VHook<String?>(null);
    final middlewareClientReceived2 = VHook<String?>(null);
    final middlewareClientSend2 = VHook<String?>(null);

    // Two middleware functions to test 'next' behaviour
    Future<dynamic> middlewareFunc1(
      dynamic session,
      dynamic message,
      MiddlewareAction action,
      Future<dynamic> Function(dynamic) next,
    ) async {
      if (session is ServerSession) {
        if (action == MiddlewareAction.receive) {
          middlewareServerReceived1.set(message);
        } else {
          middlewareServerSend1.set(message);
        }
      } else {
        if (action == MiddlewareAction.receive) {
          middlewareClientReceived1.set(message);
        } else {
          middlewareClientSend1.set(message);
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
          middlewareServerReceived2.set(message);
        } else {
          middlewareServerSend2.set(message);
        }
      } else {
        if (action == MiddlewareAction.receive) {
          middlewareClientReceived2.set(message);
        } else {
          middlewareClientSend2.set(message);
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
      msgClientReceived.set(true);
    };

    // Send messages
    client.send('ANYTHING-1');

    // Wait for msgs to be received
    await msgClientReceived.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);

    await middlewareServerReceived1.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
    await middlewareServerSend1.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
    await middlewareClientReceived1.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
    await middlewareClientSend1.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);

    await middlewareServerReceived2.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
    await middlewareServerSend2.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
    await middlewareClientReceived2.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
    await middlewareClientSend2.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);

    // Check received data
    msgClientReceived.expect(equals(true));

    middlewareServerReceived1.expect(equals('ANYTHING-1'));
    middlewareServerSend1.expect(equals('ANYTHING-2'));
    middlewareClientReceived1.expect(equals('ANYTHING-2'));
    middlewareClientSend1.expect(equals('ANYTHING-1'));

    middlewareServerReceived2.expect(equals('ANYTHING-1'));
    middlewareServerSend2.expect(equals('ANYTHING-2'));
    middlewareClientReceived2.expect(equals('ANYTHING-2'));
    middlewareClientSend2.expect(equals('ANYTHING-1'));

    // Teardown
    client.close();
  });
  test('OnDone is called', () async {
    final onDoneServerCalled = VHook<bool?>(null);
    final onDoneClientCalled = VHook<bool?>(null);

    server!.listen((HttpRequest request) {
      final ServerSession sess = ServerSession(request);
      sess.onDone = (ServerSession sess) {
        onDoneServerCalled.set(true);
      };
    });

    // Connect to WebServer and open ServerSession
    final ClientSession client = ClientSession(url.toString());
    //? This is not a race condition, because of how the dart eventloop is implemented
    //? The internal 'WebSocket.connect' is scheduled and executed when this strain waits (await)
    client.onDone = (ClientSession sess) {
      onDoneClientCalled.set(true);
    };
    client.close();

    // Wait for handlers to be called
    await onDoneServerCalled.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
    await onDoneClientCalled.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);

    onDoneServerCalled.expect(equals(true));
    onDoneClientCalled.expect(equals(true));
  });
  test('Storage is persisted', () async {
    final serverSession = VHook<ServerSession?>(null);
    final serverPersisted = VHook<bool?>(null);
    final clientPersisted = VHook<bool?>(null);

    server!.listen((HttpRequest request) {
      serverSession.set(ServerSession(request));
      serverSession.value!.onMessage = (ServerSession sess, dynamic msg) async {
        sess.storage['msg'] = msg;
        serverPersisted.set(true);
        sess.send('ANYTHING-2');
      };
    });

    // Connect to WebServer and open ServerSession
    final ClientSession client = ClientSession(url.toString());
    //? This is not a race condition, because of how the dart eventloop is implemented
    //? The internal 'WebSocket.connect' is scheduled and executed when this strain waits (await)
    client.onMessage = (ClientSession sess, dynamic msg) async {
      sess.storage['msg'] = msg;
      clientPersisted.set(true);
    };

    // Send messages
    client.send('ANYTHING-1');

    // Wait for msgs to be persisted
    await serverSession.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
    await serverPersisted.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
    await clientPersisted.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);

    // Check persisted data
    serverSession.expect(isA<ServerSession>());
    serverPersisted.expect(equals(true));
    clientPersisted.expect(equals(true));

    expect(serverSession.value!.storage['msg'], equals('ANYTHING-1'));
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
    expect(client.storage['msg'], equals(null));
  });
  test('OnError is called', () async {
    final exceptionServer = VHook<Object?>(null);
    final exceptionClient = VHook<Object?>(null);

    //* Test server
    final StreamSubscription<HttpRequest> sub = server!.listen((HttpRequest request) {
      final ServerSession sess = ServerSession(request);
      sess.onMessage = (ServerSession sess, dynamic msg) async {
        sess.raise(MockException(msg));
      };
      sess.onError = (ServerSession sess, Object ex) {
        exceptionServer.set(ex);
      };
    });

    // Connect to WebServer and open ServerSession
    ClientSession client = ClientSession(url.toString());
    client.send('ANYTHING-1');

    // Wait for handlers to be called
    await exceptionServer.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);

    // Check exception
    exceptionServer.expect(
      equals(
        isA<MockException>().having(
          (MockException e) => e.message,
          'message',
          equals('ANYTHING-1'),
        ),
      ),
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
      exceptionClient.set(ex);
    };

    // Wait for handlers to be called
    await exceptionClient.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);

    // Check exception
    exceptionClient.expect(
      equals(
        isA<MockException>().having(
          (MockException e) => e.message,
          'message',
          equals('ANYTHING-2'),
        ),
      ),
    );
  });
  test('OnMessage return is send', () async {
    final msgReceivedFromServer = VHook<String?>(null);
    final msgReceivedFromClient = VHook<String?>(null);

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
      msgReceivedFromServer.set(msg);
    };

    // Send message to trigger onMessage return
    client.send('ANYTHING');

    // Wait for msgs to be received
    await msgReceivedFromServer.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);

    // Check received data
    msgReceivedFromServer.expect(equals('ANYTHING-RETURN-1'));

    //* Test client
    sub.onData((HttpRequest request) {
      final ServerSession sess = ServerSession(request);
      sess.onMessage = (ServerSession sess, dynamic msg) async {
        msgReceivedFromClient.set(msg);
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

    // Wait for msgs to be received
    await msgReceivedFromClient.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);

    // Check received data
    msgReceivedFromClient.expect(equals('ANYTHING-RETURN-2'));

    // Teardown
    client.close();
  });
}
