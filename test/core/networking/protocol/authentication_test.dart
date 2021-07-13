import 'package:test/test.dart';

import 'package:flyde/core/networking/protocol/authentication.dart';
import 'package:flyde/core/networking/protocol/protocol.dart';

void main() {
  group('AuthRequest', () {
    test('In ProtocolDelegate.elements', () {
      expect(ProtocolDelegate.elements['AuthRequest'], equals(isA<Deserialize>()));
    });

    test('Can serialize', () {
      AuthRequest request = AuthRequest(username: "testUser", password: "testPassword");

      String serialized = ProtocolDelegate.serialize(request);

      expect(
        serialized,
        equals(
          '{"type":"AuthRequest","data":{"username":"testUser","password":"testPassword"}}',
        ),
      );
    });

    test('Can deserialize', () {
      String request =
          '{"type":"AuthRequest","data":{"username":"testUser","password":"testPassword"}}';

      dynamic deserialized = ProtocolDelegate.deSerialize(request);

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
      AuthResponse response1 = AuthResponse(status: AuthResponseStatus.required);
      AuthResponse response2 = AuthResponse(status: AuthResponseStatus.success);
      AuthResponse response3 = AuthResponse(status: AuthResponseStatus.failure);

      String serialized1 = ProtocolDelegate.serialize(response1);
      String serialized2 = ProtocolDelegate.serialize(response2);
      String serialized3 = ProtocolDelegate.serialize(response3);

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
      String response1 = '{"type":"AuthResponse","data":{"status":"required"}}';
      String response2 = '{"type":"AuthResponse","data":{"status":"success"}}';
      String response3 = '{"type":"AuthResponse","data":{"status":"failure"}}';

      dynamic deserialized1 = ProtocolDelegate.deSerialize(response1);
      dynamic deserialized2 = ProtocolDelegate.deSerialize(response2);
      dynamic deserialized3 = ProtocolDelegate.deSerialize(response3);

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
