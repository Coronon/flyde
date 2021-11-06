import 'dart:io';

import 'package:test/test.dart';

import 'package:flyde/core/networking/websockets/middleware/middleware_types.dart';
import 'package:flyde/core/networking/websockets/middleware/encryption_middleware.dart';
import 'package:flyde/core/networking/websockets/session.dart';

import '../../../../helpers/value_hook.dart';
import '../../../../helpers/get_uri.dart';
import '../../../../helpers/open_webserver.dart';

void main() {
  test('EncryptionMiddleware can handshake', () async {
    final receivedMessage = VHook<String>.empty();

    final List<MiddlewareFunc> middleware = [encryptionMiddleware];

    // Create server to accept connection
    final server = await openWebServer();
    server.wsMiddleware = middleware;
    server.wsOnMessage = (ServerSession session, dynamic msg) async {
      receivedMessage.completeValue(msg);
    };

    // Connect to the server
    final session = ClientSession(getUri(server, 'ws').toString());
    session.middleware = middleware;

    session.send('ANYTHING');
    // Check message transmitted
    await receivedMessage.expectAsync(
      equals('ANYTHING'),
      timeout: Duration(seconds: 10),
      onlyOnCompletion: true,
    );

    expect(session.storage['crypto_provider'].runtimeType.toString(), equals('_CryptoProvider'));
  });

  test('EncryptionMiddleware throws on crypto message after shared key is established', () async {
    final receivedNormalMessage = VHook<String>.empty();
    final receivedCryptoMessage = VHook<String>.empty();
    final raisedException = VHook<Object>.empty();
    final closedSession = VHook.empty();

    final List<MiddlewareFunc> middleware = [encryptionMiddleware];

    // Create server to accept connection
    final server = await openWebServer();
    server.wsMiddleware = middleware;
    server.wsOnMessage = (ServerSession session, dynamic msg) async {
      if (msg == 'ANYTHING-1') {
        receivedNormalMessage.completeValue(msg);
      } else {
        receivedCryptoMessage.set(msg);
      }
    };
    server.wsOnError = (ServerSession session, Object exception) {
      raisedException.completeValue(exception);
    };

    // Connect to the server
    final session = ClientSession(getUri(server, 'ws').toString());
    session.middleware = middleware;
    session.onDone = (ClientSession session) {
      closedSession.complete();
    };

    session.send('ANYTHING-1');
    // Check message transmitted (extra timeout for key generation)
    await receivedNormalMessage.expectAsync(
      equals('ANYTHING-1'),
      timeout: Duration(seconds: 10),
      onlyOnCompletion: true,
    );

    // Send crypto message
    session.send(r'$ANYTHING-2');

    // Check exception raised and connection closed
    await raisedException.expectAsync(
      isA<HandshakeException>().having(
        (HandshakeException e) => e.message,
        'message',
        equals('Received crypto message after secure connection was established'),
      ),
      timeout: Duration(seconds: 5),
      onlyOnCompletion: true,
    );
    await closedSession.awaitCompletion(Duration(seconds: 5));

    expect(receivedCryptoMessage.isEmpty, isTrue);

    expect(session.storage['crypto_provider'], isNull);
  });

  test('EncryptionMiddleware throws on invalid crypto message', () async {
    final raisedException = VHook<Object>.empty();
    final closedSession = VHook.empty();

    final List<MiddlewareFunc> middleware = [encryptionMiddleware];

    // Create server to accept connection
    final server = await openWebServer();
    server.wsMiddleware = middleware;
    server.wsOnMessage = (ServerSession session, dynamic msg) async {};
    server.wsOnError = (ServerSession session, Object exception) {
      raisedException.completeValue(exception);
    };

    // Connect to the server
    final client = await WebSocket.connect(getUri(server, 'ws').toString());
    client.listen((dynamic _) {}, onDone: () {
      closedSession.complete();
    });

    // Send invalid crypto message
    client.add(r'$ANYTHING');

    // Check exception raised and connection closed
    await raisedException.expectAsync(
      isA<HandshakeException>()
          .having(
            (HandshakeException e) => e.message,
            'message',
            startsWith("Invalid crypto message: '"),
          )
          .having(
            (HandshakeException e) => e.message,
            'message',
            endsWith("'"),
          ),
      timeout: Duration(seconds: 5),
      onlyOnCompletion: true,
    );
    await closedSession.awaitCompletion(Duration(seconds: 5));
  });

  test('EncryptionMiddleware throws on invalid public key', () async {
    final raisedException = VHook<Object>.empty();
    final closedSession = VHook.empty();

    final List<MiddlewareFunc> middleware = [encryptionMiddleware];

    // Create server to accept connection
    final server = await openWebServer();
    server.wsMiddleware = middleware;
    server.wsOnMessage = (ServerSession session, dynamic msg) async {};
    server.wsOnError = (ServerSession session, Object exception) {
      raisedException.completeValue(exception);
    };

    // Connect to the server
    final client = await WebSocket.connect(getUri(server, 'ws').toString());
    client.listen((dynamic _) {}, onDone: () {
      closedSession.complete();
    });

    // Send invalid public key
    client.add(r'$KEY_REQUEST1-2-3-4-5-6-7-8-9-0');

    // Check exception raised and connection closed
    await raisedException.expectAsync(
      isA<HandshakeException>().having(
        (HandshakeException e) => e.message,
        'message',
        equals('Received publicKey is invalid'),
      ),
      timeout: Duration(seconds: 5),
      onlyOnCompletion: true,
    );
    await closedSession.awaitCompletion(Duration(seconds: 5));
  });

  test('EncryptionMiddleware throws on decryption of invalid data', () async {
    final receivedMessage = VHook<String?>.empty();
    final raisedException = VHook<Object>.empty();
    final closedSession = VHook<bool>.empty();

    final List<MiddlewareFunc> middleware = [encryptionMiddleware];

    // Create server to accept connection
    final server = await openWebServer();
    server.wsMiddleware = middleware;
    server.wsOnMessage = (ServerSession session, dynamic msg) async {
      receivedMessage.set(msg);
    };
    server.wsOnError = (ServerSession session, Object exception) {
      raisedException.set(exception);
    };

    // Connect to the server
    final session = ClientSession(getUri(server, 'ws').toString());
    session.middleware = middleware;
    session.onDone = (ClientSession session) {
      closedSession.set(true);
    };

    // Send message to establish secure connection
    session.send('ANYTHING-1');

    // Wait for secure connection to be established
    await receivedMessage.expectAsync(
      equals('ANYTHING-1'),
      timeout: Duration(seconds: 10),
    );
    receivedMessage.set(null);

    expect(raisedException.isEmpty, isTrue);
    expect(closedSession.isEmpty, isTrue);

    // Produce second CryptoProvider to copy keys -> mismatch server/client
    final sessionClone = ClientSession(getUri(server, 'ws').toString());
    sessionClone.middleware = middleware;
    sessionClone.send('ANYTHING-2');

    // Wait for secure connection to be established (clone session)
    await receivedMessage.expectAsync(
      equals('ANYTHING-2'),
      timeout: Duration(seconds: 10),
    );
    receivedMessage.set(null);

    // Copy CryptoProvider to cause mismatch for session
    session.storage['crypto_provider'] = sessionClone.storage['crypto_provider'];

    // Send message with wrong shared key
    session.send('ANYTHING-3');

    // This exception could be anything
    await raisedException.expectAsync(isA<Exception>(), timeout: Duration(seconds: 5));
    await closedSession.expectAsync(isTrue, timeout: Duration(seconds: 5));

    receivedMessage.expect(isNull);
  });
}
