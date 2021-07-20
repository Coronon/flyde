import 'dart:io';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

import 'package:flyde/core/networking/server.dart';
import 'package:flyde/core/networking/websockets/session.dart';

import '../../helpers/value_hook.dart';
import '../../helpers/wait_for.dart';

void main() {
  test('Can receive http request', () async {
    final VHook<bool?> received = VHook<bool?>(null);

    final WebServer server = WebServer(
      InternetAddress.loopbackIPv4,
      0,
      httpOnRequest: (HttpRequest req) {
        received.set(true);
        req.response.statusCode = 404;
        req.response.close();
      },
    );
    await server.ready;

    http.get(getUri(server, 'http'));

    // Wait for handler to be called and check
    await received.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
    received.expect(equals(true));

    // Teardown
    server.close();
  });

  test('Can respond to http request', () async {
    final WebServer server = WebServer(
      InternetAddress.loopbackIPv4,
      0,
      httpOnRequest: (HttpRequest req) {
        req.response.statusCode = 200;
        req.response.write('ANYTHING');
        req.response.close();
      },
    );
    await server.ready;

    final http.Response response = await http.get(getUri(server, 'http'));

    // Check response
    expect(response.statusCode, equals(200));
    expect(response.body.toString(), equals('ANYTHING'));

    // Teardown
    server.close();
  });

  test('Returns 404 if no handler set', () async {
    final WebServer server = WebServer(
      InternetAddress.loopbackIPv4,
      0,
    );
    await server.ready;

    final http.Response response = await http.get(getUri(server, 'http'));

    // Check response
    expect(response.statusCode, equals(404));
    expect(response.body.toString(), equals(''));

    // Teardown
    server.close();
  });

  test('Can establish websocket connection', () async {
    final VHook<bool?> received = VHook<bool?>(null);

    final WebServer server = WebServer(
      InternetAddress.loopbackIPv4,
      0,
      wsOnMessage: (ServerSession sess, dynamic msg) async {
        received.set(true);
      },
    );
    await server.ready;

    final WebSocket client = await WebSocket.connect(getUri(server, 'ws').toString());
    client.add('ANYTHING');

    // Wait for handler to be called
    await received.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
    received.expect(equals(true));

    // Teardown
    client.close();
    server.close();
  });

  test('Can close all WebSocket connections', () async {
    final VHook<bool?> established = VHook<bool?>(null);
    final VHook<bool?> closed = VHook<bool?>(null);

    final WebServer server = WebServer(
      InternetAddress.loopbackIPv4,
      0,
      wsOnMessage: (ServerSession sess, dynamic msg) async {
        established.set(true);
      },
    );
    await server.ready;

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
    waitFor(() => server.isEmpty, timeout: Duration(seconds: 5), raiseOnTimeout: true);
  });

  test('Can redirect websocket', () async {
    final VHook<bool?> received = VHook<bool?>(null);

    final WebServer server = WebServer(
      InternetAddress.loopbackIPv4,
      0,
      redirectWebsocket: true,
      httpOnRequest: (HttpRequest req) {
        received.set(true);
        req.response.statusCode = 404;
        req.response.close();
      },
    );
    await server.ready;

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

    final WebServer server = WebServer(
      InternetAddress.loopbackIPv4,
      0,
      wsOnError: (ServerSession sess, Object error) {
        called.set(error);
      },
      wsOnMessage: (ServerSession sess, dynamic msg) async {
        sess.raise(TestException(msg));
      },
    );
    await server.ready;

    // Connect client
    final ClientSession client = ClientSession(getUri(server, 'ws').toString());
    client.send('ANYTHING');

    // Wait for handler to be called
    await called.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
    called.expect(
      isA<TestException>().having(
        (TestException e) => e.message,
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

    final WebServer server = WebServer(
      InternetAddress.loopbackIPv4,
      0,
      wsOnDone: (ServerSession sess) {
        called.set(true);
      },
      wsOnMessage: (ServerSession sess, dynamic msg) async {},
    );
    await server.ready;

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

  test('Get address', () async {
    final WebServer server = WebServer(
      InternetAddress.loopbackIPv4,
      0,
    );
    await server.ready;

    expect(server.address, equals(InternetAddress.loopbackIPv4));

    // Teardown
    server.close();
  });

  test('Get port', () async {
    final WebServer server = WebServer(
      InternetAddress.loopbackIPv4,
      0,
    );
    await server.ready;

    expect(server.port, isA<int>());

    // Teardown
    server.close();
  });

  test('Get isEmpty', () async {
    final VHook<bool?> received = VHook<bool?>(null);

    WebServer server = WebServer(
      InternetAddress.loopbackIPv4,
      0,
      wsOnMessage: (ServerSession sess, dynamic msg) async {
        received.set(true);
      },
    );
    await server.ready;

    expect(server.isEmpty, equals(true));

    // Connect a client
    final ClientSession client = ClientSession(getUri(server, 'ws').toString());
    client.send('ANYTHING');

    // Check if server is still empty
    await received.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
    received.expect(equals(true));

    expect(server.isEmpty, equals(false));

    // Teardown
    client.close();
    await server.close();

    // Is empty again
    expect(server.isEmpty, equals(true));
  });
}

/// Get current URI to server
Uri getUri(WebServer? server, String prefix) {
  return Uri.parse('$prefix://${server!.address!.host}:${server.port!}');
}

/// Mock exception used for testing
class TestException implements Exception {
  final String message;

  const TestException(this.message);

  @override
  String toString() => message;
}