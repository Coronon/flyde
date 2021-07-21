import 'dart:io';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

import 'package:flyde/core/networking/server.dart';
import 'package:flyde/core/networking/websockets/session.dart';

import '../../helpers/value_hook.dart';
import '../../helpers/wait_for.dart';
import '../../helpers/get_uri.dart';
import '../../helpers/open_webserver.dart';
import '../../helpers/mocks/mock_exception.dart';

void main() {
  test('WebServer can receive http request', () async {
    final VHook<bool?> received = VHook<bool?>(null);

    final WebServer server = await openWebServer();
    server.httpOnRequest = (HttpRequest req) {
      received.set(true);
      req.response.statusCode = 404;
      req.response.close();
    };

    http.get(getUri(server, 'http'));

    // Wait for handler to be called and check
    await received.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
    received.expect(equals(true));

    // Teardown
    server.close();
  });

  test('WebServer can respond to http request', () async {
    final WebServer server = await openWebServer();
    server.httpOnRequest = (HttpRequest req) {
      req.response.statusCode = 200;
      req.response.write('ANYTHING');
      req.response.close();
    };

    final http.Response response = await http.get(getUri(server, 'http'));

    // Check response
    expect(response.statusCode, equals(200));
    expect(response.body.toString(), equals('ANYTHING'));

    // Teardown
    server.close();
  });

  test('WebServer returns 404 if no handler was set', () async {
    final WebServer server = await openWebServer();

    final http.Response response = await http.get(getUri(server, 'http'));

    // Check response
    expect(response.statusCode, equals(404));
    expect(response.body.toString(), equals(''));

    // Teardown
    server.close();
  });

  test('WebServer can establish WebSocket connections', () async {
    final VHook<bool?> received = VHook<bool?>(null);

    final WebServer server = await openWebServer();
    server.wsOnMessage = (ServerSession sess, dynamic msg) async {
      received.set(true);
    };

    final WebSocket client = await WebSocket.connect(getUri(server, 'ws').toString());
    client.add('ANYTHING');

    // Wait for handler to be called
    await received.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
    received.expect(equals(true));

    // Teardown
    client.close();
    server.close();
  });

  test('WebServer can close all WebSocket connections', () async {
    final VHook<bool?> established = VHook<bool?>(null);
    final VHook<bool?> closed = VHook<bool?>(null);

    final WebServer server = await openWebServer();
    server.wsOnMessage = (ServerSession sess, dynamic msg) async {
      established.set(true);
    };

    final ClientSession client = ClientSession(getUri(server, 'ws').toString());
    client.onDone = (ClientSession _) async {
      closed.set(true);
    };
    client.send('ANYTHING');

    // Wait for connection to be established
    await established.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
    established.expect(equals(true));

    // Close server
    server.close();

    // Wait for connection to be closed
    await closed.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
    closed.expect(equals(true));
    waitFor(() => server.hasNoSessions, timeout: Duration(seconds: 5), raiseOnTimeout: true);
  });

  test('WebServer can redirect WebSocket requests', () async {
    final VHook<bool?> received = VHook<bool?>(null);

    final WebServer server = await openWebServer();
    server.redirectWebsocket = true;
    server.httpOnRequest = (HttpRequest req) {
      received.set(true);
      req.response.statusCode = 404;
      req.response.close();
    };

    expect(
      () async {
        await WebSocket.connect(getUri(server, 'ws').toString());
      },
      throwsA(
        isA<WebSocketException>()
            .having(
              (WebSocketException e) => e.message,
              'message begin',
              startsWith("Connection to '"),
            )
            .having(
              (WebSocketException e) => e.message,
              'message end',
              endsWith("' was not upgraded to websocket"),
            ),
      ),
    );

    // Wait for handler to be called
    await received.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
    received.expect(equals(true));

    // Teardown
    server.close();
  });

  test('OnError is called', () async {
    final VHook<Object?> called = VHook<Object?>(null);

    final WebServer server = await openWebServer();
    server.wsOnError = (ServerSession sess, Object error) {
      called.set(error);
    };
    server.wsOnMessage = (ServerSession sess, dynamic msg) async {
      sess.raise(MockException(msg));
    };

    // Connect client
    final ClientSession client = ClientSession(getUri(server, 'ws').toString());
    client.send('ANYTHING');

    // Wait for handler to be called
    await called.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
    called.expect(
      isA<MockException>().having(
        (MockException e) => e.message,
        'message',
        equals('ANYTHING'),
      ),
    );

    // Teardown
    client.close();
    server.close();
  });

  test('OnDone is called', () async {
    final VHook<bool?> called = VHook<bool?>(null);

    final WebServer server = await openWebServer();
    server.wsOnDone = (ServerSession sess) {
      called.set(true);
    };
    server.wsOnMessage = (ServerSession sess, dynamic msg) async {};

    // Connect client
    final ClientSession client = ClientSession(getUri(server, 'ws').toString());
    await client.send('ANYTHING');
    client.close();

    // Wait for handler to be called
    await called.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
    called.expect(equals(true));

    // Teardown
    client.close();
    server.close();
  });

  test('Can get address from WebServer', () async {
    final WebServer server = await openWebServer();

    expect(server.address, equals(InternetAddress.loopbackIPv4));

    // Teardown
    server.close();
  });

  test('Can get port from WebServer', () async {
    final WebServer server = await openWebServer();

    expect(server.port, isA<int>());

    // Teardown
    server.close();
  });

  test('Can get hasNoSessions from WebServer', () async {
    final VHook<bool?> received = VHook<bool?>(null);

    final WebServer server = await openWebServer();
    server.wsOnMessage = (ServerSession sess, dynamic msg) async {
      received.set(true);
    };

    expect(server.hasNoSessions, equals(true));

    // Connect a client
    final ClientSession client = ClientSession(getUri(server, 'ws').toString());
    client.send('ANYTHING');

    // Check if server is still empty
    await received.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
    received.expect(equals(true));

    expect(server.hasNoSessions, equals(false));

    // Teardown
    client.close();
    await server.close();

    // Is empty again
    expect(server.hasNoSessions, equals(true));
  });
}
