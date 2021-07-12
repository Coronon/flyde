import 'package:test/test.dart';

import 'package:flyde/core/networking/protocol/authentication.dart';
import 'package:flyde/core/networking/websockets/middleware.dart';

import '../../../helpers/value_hook.dart';

void main() {
  group('WebSocket middleware:', () {
    test('ProtocolMiddleware deserializes messages and passes them onwards', () async {
      AuthRequest request = AuthRequest(username: "testUsername", password: "testPassword");
      String message =
          '{"type":"AuthRequest","data":{"username":"testUsername","password":"testPassword"}}';
      VHook<bool> calledNext = VHook<bool>(false);

      dynamic deserialized = await protocolMiddleware(
        null,
        message,
        MiddlewareAction.recieve,
        (dynamic msg) async {
          expect(msg is AuthRequest, equals(true));

          calledNext.set(true);
          return msg;
        },
      );

      //* Verify that the deserialized message is the same as the original message
      expect(deserialized is AuthRequest, equals(true));
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
      AuthRequest request = AuthRequest(username: "testUsername", password: "testPassword");
      String message =
          '{"type":"AuthRequest","data":{"username":"testUsername","password":"testPassword"}}';
      VHook<bool> calledNext = VHook<bool>(false);

      dynamic serialized = await protocolMiddleware(
        null,
        request,
        MiddlewareAction.send,
        (dynamic msg) async {
          // Should still be non serialized
          expect(msg is AuthRequest, equals(true));

          calledNext.set(true);
          return msg;
        },
      );

      //* Verify that the serialized message is the same as the original message
      expect(serialized, equals(message));

      calledNext.expect(equals(true));
    });
    test('ProtocolMiddleware catches exceptions', () async {
      MockSession session = MockSession();
      VHook<bool> calledNext = VHook<bool>(false);

      dynamic serialized = await protocolMiddleware(
        session,
        "ANYTHING",
        MiddlewareAction.recieve,
        (dynamic msg) async {
          calledNext.set(true);
          return msg;
        },
      );

      //* Verify that the middleware caugth the exception
      expect(serialized, equals(null));

      calledNext.expect(equals(false));
    });

    test('AuthenticationMiddleware dont run on send', () async {
      MockSession session = MockSession();
      VHook<bool> calledAuthHandler = VHook<bool>(false);
      VHook<bool> calledNext = VHook<bool>(false);

      MiddlewareFunc authMiddleware = makeAuthenticationMiddleware((AuthRequest request) async {
        calledAuthHandler.set(true);
        return true;
      });

      dynamic response = await authMiddleware(
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
      expect(response == null, equals(true));
      expect(session.storage['authenticated'], equals(null));
    });
    test('AuthenticationMiddleware requires authentication', () async {
      MockSession session = MockSession();
      VHook<bool> calledAuthHandler = VHook<bool>(false);
      VHook<bool> calledNext = VHook<bool>(false);

      MiddlewareFunc authMiddleware = makeAuthenticationMiddleware((AuthRequest request) async {
        calledAuthHandler.set(true);
        return true;
      });

      dynamic response = await authMiddleware(
        session,
        "ANYTHING",
        MiddlewareAction.recieve,
        (dynamic msg) async {
          calledNext.set(true);
          return msg;
        },
      );

      //* Verify that the middleware rejected the message
      calledAuthHandler.expect(equals(false));
      calledNext.expect(equals(false));
      expect(response is AuthResponse, equals(true));
      response as AuthResponse;
      expect(response.status, equals(AuthResponseStatus.required));
      expect(session.storage['authenticated'], equals(null));
    });
    test('AuthenticationMiddleware lets authed sessions pass', () async {
      MockSession session = MockSession();
      session.storage['authenticated'] = true;
      VHook<bool> calledAuthHandler = VHook<bool>(false);
      VHook<bool> calledNext = VHook<bool>(false);

      MiddlewareFunc authMiddleware = makeAuthenticationMiddleware((AuthRequest request) async {
        calledAuthHandler.set(true);
        return false;
      });

      dynamic response = await authMiddleware(
        session,
        "ANYTHING",
        MiddlewareAction.recieve,
        (dynamic msg) async {
          expect(msg, equals("ANYTHING"));

          calledNext.set(true);
          return msg;
        },
      );

      //* Verify that the middleware let the message through
      calledAuthHandler.expect(equals(false));
      calledNext.expect(equals(true));
      expect(response is String, equals(true));
      response as String;
      expect(response, equals("ANYTHING"));
    });
    test('AuthenticationMiddleware can authentication', () async {
      MockSession session = MockSession();
      VHook<bool> calledAuthHandler = VHook<bool>(false);
      VHook<bool> calledNext = VHook<bool>(false);

      MiddlewareFunc authMiddleware = makeAuthenticationMiddleware((AuthRequest request) async {
        expect(request.username, equals("testUsername"));
        expect(request.password, equals("testPassword"));

        calledAuthHandler.set(true);
        return true;
      });

      dynamic response = await authMiddleware(
        session,
        AuthRequest(username: "testUsername", password: "testPassword"),
        MiddlewareAction.recieve,
        (dynamic msg) async {
          calledNext.set(true);
          return msg;
        },
      );

      //* Verify that the middleware can accept AuthRequest's
      calledAuthHandler.expect(equals(true));
      calledNext.expect(equals(false));
      expect(response is AuthResponse, equals(true));
      response as AuthResponse;
      expect(response.status, equals(AuthResponseStatus.success));
      expect(session.storage['authenticated'], equals(true));
    });
    test('AuthenticationMiddleware can reject', () async {
      MockSession session = MockSession();
      VHook<bool> calledAuthHandler = VHook<bool>(false);
      VHook<bool> calledNext = VHook<bool>(false);

      MiddlewareFunc authMiddleware = makeAuthenticationMiddleware((AuthRequest request) async {
        expect(request.username, equals("testUsername"));
        expect(request.password, equals("testPassword"));

        calledAuthHandler.set(true);
        return false;
      });

      dynamic response1 = await authMiddleware(
        session,
        AuthRequest(username: "testUsername", password: "testPassword"),
        MiddlewareAction.recieve,
        (dynamic msg) async {
          calledNext.set(true);
          return msg;
        },
      );

      //* Verify that the middleware can reject AuthRequest's
      calledAuthHandler.expect(equals(true));
      calledNext.expect(equals(false));
      expect(response1 is AuthResponse, equals(true));
      response1 as AuthResponse;
      expect(response1.status, equals(AuthResponseStatus.failure));
      expect(session.storage['authenticated'], equals(false));

      //? Second attempt (session.storage['authenticated'] is now not 'null')
      calledAuthHandler.set(false);
      calledNext.set(false);

      dynamic response2 = await authMiddleware(
        session,
        AuthRequest(username: "testUsername", password: "testPassword"),
        MiddlewareAction.recieve,
        (dynamic msg) async {
          calledNext.set(true);
          return msg;
        },
      );

      //* Verify that the middleware can reject AuthRequest's
      calledAuthHandler.expect(equals(true));
      calledNext.expect(equals(false));
      expect(response2 is AuthResponse, equals(true));
      response2 as AuthResponse;
      expect(response2.status, equals(AuthResponseStatus.failure));
      expect(session.storage['authenticated'], equals(false));
    });
  });
}

class MockSession {
  Map<dynamic, dynamic> storage = <dynamic, dynamic>{};

  void raise(Object e) {}
}
