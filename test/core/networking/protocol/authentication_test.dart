import 'package:test/test.dart';

import 'package:flyde/core/networking/protocol/authentication.dart';
import 'package:flyde/core/networking/protocol/protocol.dart';

void main() {
  group('AuthRequest', () {
    test('In ProtocolDelegate.elements', () {
      expect(ProtocolDelegate.elements['AuthRequest'], equals(isA<Deserialize>()));
    });

    test('Can serialize', () {
      final request = AuthRequest(username: "testUser", password: "testPassword");

      final String serialized = ProtocolDelegate.serialize(request);

      expect(
        serialized,
        equals(
          '{"type":"AuthRequest","data":{"username":"testUser","password":"testPassword"}}',
        ),
      );
    });

    test('Can deserialize', () {
      final String request =
          '{"type":"AuthRequest","data":{"username":"testUser","password":"testPassword"}}';

      final dynamic deserialized = ProtocolDelegate.deSerialize(request);

      expect(deserialized, equals(isA<AuthRequest>()));
      deserialized as AuthRequest;
      expect(deserialized.username, equals('testUser'));
      expect(deserialized.password, equals('testPassword'));
    });
  });

  group('AuthResponse', () {
    test('In ProtocolDelegate.elements', () {
      expect(ProtocolDelegate.elements['AuthResponse'], equals(isA<Deserialize>()));
    });

    test('Can serialize', () {
      final response1 = AuthResponse(status: AuthResponseStatus.required);
      final response2 = AuthResponse(status: AuthResponseStatus.success);
      final response3 = AuthResponse(status: AuthResponseStatus.failure);

      final String serialized1 = ProtocolDelegate.serialize(response1);
      final String serialized2 = ProtocolDelegate.serialize(response2);
      final String serialized3 = ProtocolDelegate.serialize(response3);

      expect(
        serialized1,
        equals(
          '{"type":"AuthResponse","data":{"status":"required"}}',
        ),
      );
      expect(
        serialized2,
        equals(
          '{"type":"AuthResponse","data":{"status":"success"}}',
        ),
      );
      expect(
        serialized3,
        equals(
          '{"type":"AuthResponse","data":{"status":"failure"}}',
        ),
      );
    });

    test('Can deserialize', () {
      final String response1 = '{"type":"AuthResponse","data":{"status":"required"}}';
      final String response2 = '{"type":"AuthResponse","data":{"status":"success"}}';
      final String response3 = '{"type":"AuthResponse","data":{"status":"failure"}}';

      final dynamic deserialized1 = ProtocolDelegate.deSerialize(response1);
      final dynamic deserialized2 = ProtocolDelegate.deSerialize(response2);
      final dynamic deserialized3 = ProtocolDelegate.deSerialize(response3);

      expect(deserialized1, equals(isA<AuthResponse>()));
      deserialized1 as AuthResponse;
      expect(deserialized1.status, equals(AuthResponseStatus.required));

      expect(deserialized2, equals(isA<AuthResponse>()));
      deserialized2 as AuthResponse;
      expect(deserialized2.status, equals(AuthResponseStatus.success));

      expect(deserialized3, equals(isA<AuthResponse>()));
      deserialized3 as AuthResponse;
      expect(deserialized3.status, equals(AuthResponseStatus.failure));
    });
  });
}
