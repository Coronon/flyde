import 'dart:io';

import 'package:test/test.dart';

import 'package:flyde/core/networking/protocol/authentication.dart';
import 'package:flyde/core/networking/websockets/middleware.dart';
import 'package:flyde/core/networking/websockets/session.dart';

import '../../../helpers/value_hook.dart';
import '../../../helpers/get_uri.dart';
import '../../../helpers/open_webserver.dart';
import '../../../helpers/mocks/mock_session.dart';

void main() {
  test('ProtocolMiddleware deserializes messages and passes them onwards', () async {
    final request = AuthRequest(username: "testUsername", password: "testPassword");
    final String message =
        '{"type":"AuthRequest","data":{"username":"testUsername","password":"testPassword"}}';
    final calledNext = VHook<bool>(false);

    final dynamic deserialized = await protocolMiddleware(
      null,
      message,
      MiddlewareAction.receive,
      (dynamic msg) async {
        expect(msg, isA<AuthRequest>());

        calledNext.set(true);
        return msg;
      },
    );

    //* Verify that the deserialized message is the same as the original message
    expect(deserialized, isA<AuthRequest>());
    deserialized as AuthRequest;

    expect(
      deserialized.username,
      equals(request.username),
    );
    expect(
      deserialized.password,
      equals(request.password),
    );

    calledNext.expect(equals(true));
  });
  test('ProtocolMiddleware passes messages and finally serializes them', () async {
    final request = AuthRequest(username: "testUsername", password: "testPassword");
    final String message =
        '{"type":"AuthRequest","data":{"username":"testUsername","password":"testPassword"}}';
    final calledNext = VHook<bool>(false);

    final dynamic serialized = await protocolMiddleware(
      null,
      request,
      MiddlewareAction.send,
      (dynamic msg) async {
        // Should still be non serialized
        expect(msg, isA<AuthRequest>());

        calledNext.set(true);
        return msg;
      },
    );

    //* Verify that the serialized message is the same as the original message
    expect(serialized, equals(message));

    calledNext.expect(equals(true));
  });
  test('ProtocolMiddleware catches exceptions', () async {
    final session = MockSession();
    final calledNext = VHook<bool>(false);

    final dynamic serialized = await protocolMiddleware(
      session,
      "ANYTHING",
      MiddlewareAction.receive,
      (dynamic msg) async {
        calledNext.set(true);
        return msg;
      },
    );

    //* Verify that the middleware caught the exception
    expect(serialized, equals(null));

    calledNext.expect(equals(false));
  });

  test('AuthenticationMiddleware does not run on send', () async {
    final session = MockSession();
    final calledAuthHandler = VHook<bool>(false);
    final calledNext = VHook<bool>(false);

    final MiddlewareFunc authMiddleware = makeAuthenticationMiddleware((AuthRequest request) async {
      calledAuthHandler.set(true);
      return true;
    });

    final dynamic response = await authMiddleware(
      session,
      null,
      MiddlewareAction.send,
      (dynamic msg) async {
        calledNext.set(true);
        return msg;
      },
    );

    //* Verify that the middleware did not intercept the message
    calledAuthHandler.expect(equals(false));
    calledNext.expect(equals(true));
    expect(response, isNull);
    expect(session.storage, isNot(contains('authenticated')));
  });
  test('AuthenticationMiddleware requires authentication', () async {
    final session = MockSession();
    final calledAuthHandler = VHook<bool>(false);
    final calledNext = VHook<bool>(false);

    final MiddlewareFunc authMiddleware = makeAuthenticationMiddleware((AuthRequest request) async {
      calledAuthHandler.set(true);
      return true;
    });

    final dynamic response = await authMiddleware(
      session,
      "ANYTHING",
      MiddlewareAction.receive,
      (dynamic msg) async {
        calledNext.set(true);
        return msg;
      },
    );

    //* Verify that the middleware rejected the message
    calledAuthHandler.expect(equals(false));
    calledNext.expect(equals(false));
    expect(response, isA<AuthResponse>());
    response as AuthResponse;
    expect(response.status, equals(AuthResponseStatus.required));
    expect(session.storage['authenticated'], equals(null));
  });
  test('AuthenticationMiddleware lets authed sessions pass', () async {
    final session = MockSession();
    session.storage['authenticated'] = true;
    final calledAuthHandler = VHook<bool>(false);
    final calledNext = VHook<bool>(false);

    final MiddlewareFunc authMiddleware = makeAuthenticationMiddleware((AuthRequest request) async {
      calledAuthHandler.set(true);
      return false;
    });

    final dynamic response = await authMiddleware(
      session,
      "ANYTHING",
      MiddlewareAction.receive,
      (dynamic msg) async {
        expect(msg, equals("ANYTHING"));

        calledNext.set(true);
        return msg;
      },
    );

    //* Verify that the middleware let the message through
    calledAuthHandler.expect(equals(false));
    calledNext.expect(equals(true));
    expect(response, isA<String>());
    response as String;
    expect(response, equals("ANYTHING"));
  });
  test('AuthenticationMiddleware can authenticate session', () async {
    final session = MockSession();
    final calledAuthHandler = VHook<bool>(false);
    final calledNext = VHook<bool>(false);

    final MiddlewareFunc authMiddleware = makeAuthenticationMiddleware((AuthRequest request) async {
      expect(request.username, equals("testUsername"));
      expect(request.password, equals("testPassword"));

      calledAuthHandler.set(true);
      return true;
    });

    final dynamic response = await authMiddleware(
      session,
      AuthRequest(username: "testUsername", password: "testPassword"),
      MiddlewareAction.receive,
      (dynamic msg) async {
        calledNext.set(true);
        return msg;
      },
    );

    //* Verify that the middleware can accept AuthRequest's
    calledAuthHandler.expect(equals(true));
    calledNext.expect(equals(false));
    expect(response, isA<AuthResponse>());
    response as AuthResponse;
    expect(response.status, equals(AuthResponseStatus.success));
    expect(session.storage['authenticated'], equals(true));
  });
  test('AuthenticationMiddleware can reject authentication', () async {
    final session = MockSession();
    final calledAuthHandler = VHook<bool>(false);
    final calledNext = VHook<bool>(false);

    final MiddlewareFunc authMiddleware = makeAuthenticationMiddleware((AuthRequest request) async {
      expect(request.username, equals("testUsername"));
      expect(request.password, equals("testPassword"));

      calledAuthHandler.set(true);
      return false;
    });

    final dynamic response1 = await authMiddleware(
      session,
      AuthRequest(username: "testUsername", password: "testPassword"),
      MiddlewareAction.receive,
      (dynamic msg) async {
        calledNext.set(true);
        return msg;
      },
    );

    //* Verify that the middleware can reject AuthRequest's
    calledAuthHandler.expect(equals(true));
    calledNext.expect(equals(false));
    expect(response1, isA<AuthResponse>());
    response1 as AuthResponse;
    expect(response1.status, equals(AuthResponseStatus.failure));
    expect(session.storage['authenticated'], equals(false));

    //? Second attempt (session.storage['authenticated'] is now not 'null')
    calledAuthHandler.set(false);
    calledNext.set(false);

    final dynamic response2 = await authMiddleware(
      session,
      AuthRequest(username: "testUsername", password: "testPassword"),
      MiddlewareAction.receive,
      (dynamic msg) async {
        calledNext.set(true);
        return msg;
      },
    );

    //* Verify that the middleware can reject AuthRequest's
    calledAuthHandler.expect(equals(true));
    calledNext.expect(equals(false));
    expect(response2, isA<AuthResponse>());
    response2 as AuthResponse;
    expect(response2.status, equals(AuthResponseStatus.failure));
    expect(session.storage['authenticated'], equals(false));
  });

  //* EncryptionMiddleware
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

    receivedMessage.expect(equals("ANYTHING"));
    expect(session.storage['crypto_provider'], equals(isA<CryptoProvider>()));
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
    session.onDone = (dynamic session) {
      closedSession.set(true);
    };

    session.send('ANYTHING-1');
    // Check message transmitted (extra timeout for key generation)
    await receivedNormalMessage.awaitValue(Duration(seconds: 10), raiseOnTimeout: true);

    // Send crypto message
    session.send('\$ANYTHING-2');

    // Check exception raised and connection closed
    await raisedException.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);
    await closedSession.awaitValue(Duration(seconds: 5), raiseOnTimeout: true);

    receivedNormalMessage.expect(equals("ANYTHING-1"));
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
    client.add('\$ANYTHING');

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
    client.add('\$KEY_REQUEST1-2-3-4-5-6-7-8-9-0');

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
