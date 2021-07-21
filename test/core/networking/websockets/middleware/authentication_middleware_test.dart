import 'package:test/test.dart';

import 'package:flyde/core/networking/protocol/authentication.dart';
import 'package:flyde/core/networking/websockets/middleware/middleware_types.dart';
import 'package:flyde/core/networking/websockets/middleware/authentication_middleware.dart';

import '../../../../helpers/value_hook.dart';
import '../../../../helpers/mocks/mock_session.dart';

void main() {
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
}
