import 'package:test/test.dart';

import 'package:flyde/core/networking/websockets/middleware/middleware_types.dart';
import 'package:flyde/core/networking/websockets/middleware/protocol_middleware.dart';
import 'package:flyde/core/networking/protocol/authentication.dart';

import '../../../../helpers/value_hook.dart';
import '../../../../helpers/mocks/mock_session.dart';

void main() {
  test('ProtocolMiddleware deserializes messages and passes them onwards', () async {
    final request = AuthRequest(username: 'testUsername', password: 'testPassword');
    final String message =
        '{"type":"AuthRequest","data":{"username":"testUsername","password":"testPassword"}}';
    final calledNext = VHook.empty();

    final dynamic deserialized = await protocolMiddleware(
      null,
      message,
      MiddlewareAction.receive,
      (dynamic msg) async {
        expect(msg, isA<AuthRequest>());

        calledNext.complete();
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

    await calledNext.awaitCompletion(Duration(seconds: 1));
  });

  test('ProtocolMiddleware passes messages and finally serializes them', () async {
    final request = AuthRequest(username: 'testUsername', password: 'testPassword');
    final String message =
        '{"type":"AuthRequest","data":{"username":"testUsername","password":"testPassword"}}';
    final calledNext = VHook.empty();

    final dynamic serialized = await protocolMiddleware(
      null,
      request,
      MiddlewareAction.send,
      (dynamic msg) async {
        // Should still be non serialized
        expect(msg, isA<AuthRequest>());

        calledNext.complete();
        return msg;
      },
    );

    //* Verify that the serialized message is the same as the original message
    expect(serialized, equals(message));

    await calledNext.awaitCompletion(Duration(seconds: 1));
  });

  test('ProtocolMiddleware catches exceptions', () async {
    final session = MockSession();
    final calledNext = VHook.empty();

    final dynamic serialized = await protocolMiddleware(
      session,
      'ANYTHING',
      MiddlewareAction.receive,
      (dynamic msg) async {
        calledNext.complete();
        return msg;
      },
    );

    //* Verify that the middleware caught the exception
    expect(serialized, isNull);

    expect(calledNext.isEmpty, isTrue);
  });
}
