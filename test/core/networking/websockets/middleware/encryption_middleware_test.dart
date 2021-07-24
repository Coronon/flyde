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
    final receivedMessage = VHook<String?>(null);

    final List<MiddlewareFunc> middleware = [encryptionMiddleware];

    // Create server to accept connection
    final server = await openWebServer();
    server.wsMiddleware = middleware;
    server.wsOnMessage = (ServerSession session, dynamic msg) async {
      receivedMessage.set(msg);
    };

    // Connect to the server
    final session = ClientSession(getUri(server, 'ws').toString());
    session.middleware = middleware;

    session.send('ANYTHING');
    // Check message transmitted
    await receivedMessage.awaitValue(Duration(seconds: 10), raiseOnTimeout: true);

    receivedMessage.expect(equals('ANYTHING'));
    expect(session.storage['crypto_provider'].runtimeType.toString(), equals('_CryptoProvider'));
  });

  test('EncryptionMiddleware throws on crypto message after shared key is established', () async {
    final receivedNormalMessage = VHook<String?>(null);
    final receivedCryptoMessage = VHook<String?>(null);
    final raisedException = VHook<Object?>(null);
    final closedSession = VHook<bool?>(null);

    final List<MiddlewareFunc> middleware = [encryptionMiddleware];

    // Create server to accept connection
    final server = await openWebServer();
    server.wsMiddleware = middleware;
    server.wsOnMessage = (ServerSession session, dynamic msg) async {
      if (msg == 'ANYTHING-1') {
        receivedNormalMessage.set(msg);
      } else {
        receivedCryptoMessage.set(msg);
      }
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

    session.send('ANYTHING-1');
    // Check message transmitted (extra timeout for key generation)
    await receivedNormalMessage.awaitValue(Duration(seconds: 10), raiseOnTimeout: true);

    // Send crypto message
    session.send(r'$ANYTHING-2');

    // Check exception raised and connection closed
    await raisedException.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
    await closedSession.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);

    receivedNormalMessage.expect(equals('ANYTHING-1'));
    receivedCryptoMessage.expect(isNull);
    closedSession.expect(isTrue);
    raisedException.expect(
      isA<HandshakeException>().having(
        (HandshakeException e) => e.message,
        'message',
        equals('Received crypto message after secure connection was established'),
      ),
    );

    expect(session.storage['crypto_provider'], isNull);
  });

  test('EncryptionMiddleware throws on invalid crypto message', () async {
    final raisedException = VHook<Object?>(null);
    final closedSession = VHook<bool?>(null);

    final List<MiddlewareFunc> middleware = [encryptionMiddleware];

    // Create server to accept connection
    final server = await openWebServer();
    server.wsMiddleware = middleware;
    server.wsOnMessage = (ServerSession session, dynamic msg) async {};
    server.wsOnError = (ServerSession session, Object exception) {
      raisedException.set(exception);
    };

    // Connect to the server
    final client = await WebSocket.connect(getUri(server, 'ws').toString());
    client.listen((dynamic _) {}, onDone: () {
      closedSession.set(true);
    });

    // Send invalid crypto message
    client.add(r'$ANYTHING');

    // Check exception raised and connection closed
    await raisedException.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
    await closedSession.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);

    raisedException.expect(
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
    );
  });

  test('EncryptionMiddleware throws on invalid public key', () async {
    final raisedException = VHook<Object?>(null);
    final closedSession = VHook<bool?>(null);

    final List<MiddlewareFunc> middleware = [encryptionMiddleware];

    // Create server to accept connection
    final server = await openWebServer();
    server.wsMiddleware = middleware;
    server.wsOnMessage = (ServerSession session, dynamic msg) async {};
    server.wsOnError = (ServerSession session, Object exception) {
      raisedException.set(exception);
    };

    // Connect to the server
    final client = await WebSocket.connect(getUri(server, 'ws').toString());
    client.listen((dynamic _) {}, onDone: () {
      closedSession.set(true);
    });

    // Send invalid public key
    client.add(r'$KEY_REQUEST1-2-3-4-5-6-7-8-9-0');

    // Check exception raised and connection closed
    await raisedException.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
    await closedSession.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);

    raisedException.expect(
      isA<HandshakeException>().having(
        (HandshakeException e) => e.message,
        'message',
        equals('Received publicKey is invalid'),
      ),
    );
  });

  test('EncryptionMiddleware throws on decryption of invalid data', () async {
    final receivedMessage = VHook<String?>(null);
    final raisedException = VHook<Object?>(null);
    final closedSession = VHook<bool?>(null);

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
    await receivedMessage.awaitValue(Duration(seconds: 10), raiseOnTimeout: true);
    receivedMessage.expect(equals('ANYTHING-1'));
    receivedMessage.set(null);

    raisedException.expect(isNull);
    closedSession.expect(isNull);

    // Produce second CryptoProvider to copy keys -> mismatch server/client
    final sessionClone = ClientSession(getUri(server, 'ws').toString());
    sessionClone.middleware = middleware;
    sessionClone.send('ANYTHING-2');

    // Wait for secure connection to be established (clone session)
    await receivedMessage.awaitValue(Duration(seconds: 10), raiseOnTimeout: true);
    receivedMessage.expect(equals('ANYTHING-2'));
    receivedMessage.set(null);

    // Copy CryptoProvider to cause mismatch for session
    session.storage['crypto_provider'] = sessionClone.storage['crypto_provider'];

    // Send message with wrong shared key
    session.send('ANYTHING-3');
    await raisedException.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
    await closedSession.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);

    receivedMessage.expect(isNull);
    closedSession.expect(isTrue);

    // This exception could be anything
    raisedException.expect(isA<Exception>());
  });
}
