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
    final received = VHook.empty();

    final WebServer server = await openWebServer();
    server.httpOnRequest = (HttpRequest req) {
      received.complete();
      req.response.statusCode = 404;
      req.response.close();
    };

    http.get(getUri(server, 'http'));

    // Wait for handler to be called and check
    await received.awaitCompletion(Duration(seconds: 5));

    // Teardown
    server.close();
  });

  test('WebServer can receive https request', () async {
    final received = VHook.empty();

    final securityContext = SecurityContext()
      ..useCertificateChain('./test/helpers/mocks/certs/mock_key_store.p12')
      ..usePrivateKey('./test/helpers/mocks/certs/mock_key.pem');

    final WebServer server = await openWebServer(securityContext: securityContext);
    server.httpOnRequest = (HttpRequest req) {
      received.complete();
      req.response.statusCode = 404;
      req.response.close();
    };

    // Create HttpClient that accepts self-signed certificate and connect to server
    final client = HttpClient()
      // Trust every certificate
      ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
    client.getUrl(getUri(server, 'https')).then((HttpClientRequest req) => req.close());

    // Wait for handler to be called
    await received.awaitCompletion(Duration(seconds: 5));

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
    final received = VHook.empty();

    final WebServer server = await openWebServer();
    server.wsOnMessage = (ServerSession sess, dynamic msg) async {
      received.complete();
    };

    final WebSocket client = await WebSocket.connect(getUri(server, 'ws').toString());
    client.add('ANYTHING');

    // Wait for handler to be called
    await received.awaitCompletion(Duration(seconds: 5));

    // Teardown
    client.close();
    server.close();
  });

  test('WebServer can close all WebSocket connections', () async {
    final established = VHook.empty();
    final closed = VHook.empty();

    final WebServer server = await openWebServer();
    server.wsOnMessage = (ServerSession sess, dynamic msg) async {
      established.complete();
    };

    final ClientSession client = ClientSession(getUri(server, 'ws').toString());
    client.onDone = (ClientSession _) async {
      closed.complete();
    };
    client.send('ANYTHING');

    // Wait for connection to be established
    await established.awaitCompletion(Duration(seconds: 5));

    // Close server
    server.close();

    // Wait for connection to be closed
    await closed.awaitCompletion(Duration(seconds: 5));
    waitFor(() => server.hasNoSessions, timeout: Duration(seconds: 5), raiseOnTimeout: true);
  });

  test('WebServer can redirect WebSocket requests', () async {
    final received = VHook.empty();

    final WebServer server = await openWebServer();
    server.redirectWebsocket = true;
    server.httpOnRequest = (HttpRequest req) {
      received.complete();
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
    await received.awaitCompletion(Duration(seconds: 5));

    // Teardown
    server.close();
  });

  test('OnError is called', () async {
    final VHook<Object> called = VHook<Object>.empty();

    final WebServer server = await openWebServer();
    server.wsOnError = (ServerSession sess, Object error) {
      called.completeValue(error);
    };
    server.wsOnMessage = (ServerSession sess, dynamic msg) async {
      sess.raise(MockException(msg));
    };

    // Connect client
    final ClientSession client = ClientSession(getUri(server, 'ws').toString());
    client.send('ANYTHING');

    // Wait for handler to be called
    await called.expectAsync(
      isA<MockException>().having(
        (MockException e) => e.message,
        'message',
        equals('ANYTHING'),
      ),
      timeout: Duration(seconds: 5),
      onlyOnCompletion: true,
    );

    // Teardown
    client.close();
    server.close();
  });

  test('OnDone is called', () async {
    final called = VHook.empty();

    final WebServer server = await openWebServer();
    server.wsOnDone = (ServerSession sess) {
      called.complete();
    };
    server.wsOnMessage = (ServerSession sess, dynamic msg) async {};

    // Connect client
    final ClientSession client = ClientSession(getUri(server, 'ws').toString());
    await client.send('ANYTHING');
    client.close();

    // Wait for handler to be called
    await called.awaitCompletion(Duration(seconds: 5));

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
    final received = VHook.empty();

    final WebServer server = await openWebServer();
    server.wsOnMessage = (ServerSession sess, dynamic msg) async {
      received.complete();
    };

    expect(server.hasNoSessions, isTrue);

    // Connect a client
    final ClientSession client = ClientSession(getUri(server, 'ws').toString());
    client.send('ANYTHING');

    // Check if server is still empty
    await received.awaitCompletion(Duration(seconds: 5));

    expect(server.hasNoSessions, isFalse);

    // Teardown
    client.close();
    await server.close();

    // Is empty again
    expect(server.hasNoSessions, isTrue);
  });
}
