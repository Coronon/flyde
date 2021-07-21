import 'package:test/test.dart';

import 'package:flyde/core/networking/protocol/protocol.dart';

import '../../../helpers/mocks/mock_serializable.dart';

void main() {
  // Add to known elements
  ProtocolDelegate.elements['MockSerializable'] =
      (Map<String, dynamic> json) => MockSerializable.fromJson(json);

  test('ProtocolDelegate can recreate object', () {
    final serializable = MockSerializable("ANYTHING");

    final dynamic recreated =
        ProtocolDelegate.deserialize(ProtocolDelegate.serialize(serializable));

    expect(recreated, isA<MockSerializable>());
    recreated as MockSerializable;
    expect(recreated.value, equals(serializable.value));
  });

  test('ProtocolDelegate can serialize object', () {
    final serializable = MockSerializable("ANYTHING");

    final String serialized = ProtocolDelegate.serialize(serializable);

    expect(serialized, equals('{"type":"MockSerializable","data":{"value":"ANYTHING"}}'));
  });

  test('ProtocolDelegate can deserialize object', () {
    final String serialized = '{"type":"MockSerializable","data":{"value":"ANYTHING"}}';

    final dynamic deserialized = ProtocolDelegate.deserialize(serialized);

    expect(deserialized, isA<MockSerializable>());
    deserialized as MockSerializable;
    expect(deserialized.value, equals("ANYTHING"));
  });

  test('ProtocolDelegate throws if no type is provided', () {
    final String msg = '{"data": {"value": "MockSerializable"}}';

    expect(
      () => ProtocolDelegate.deserialize(msg),
      throwsA(
        isA<ProtocolException>().having(
          (ProtocolException error) => error.message,
          'message',
          equals("Message does not contain 'type' property"),
        ),
      ),
    );
  });

  test('ProtocolDelegate throws if invalid type is provided', () {
    final String msg = '{"type": "NonExistentType", "data": {"value": "MockSerializable"}}';

    expect(
      () => ProtocolDelegate.deserialize(msg),
      throwsA(
        isA<ProtocolException>().having(
          (ProtocolException error) => error.message,
          'message',
          equals("'NonExistentType' unknown protocol element"),
        ),
      ),
    );
  });

  test('ProtocolDelegate throws on invalid data', () {
    final String msg1 = '{"type": "MockSerializable", "data": {"value": 1}}';
    final String msg2 = '{"type": "MockSerializable", "data": {"ANYTHING": "ANYTHING"}}';

    expect(() => ProtocolDelegate.deserialize(msg1), throwsA(isA<TypeError>()));
    expect(() => ProtocolDelegate.deserialize(msg2), throwsA(isA<TypeError>()));
  });

  test('ProtocolDelegate throws if message is not valid JSON', () {
    final String msg = 'ANYTHING';

    expect(() => ProtocolDelegate.deserialize(msg), throwsA(isA<FormatException>()));
  });

  test('ProtocolException string representation is message', () {
    final exception = ProtocolException('ANYTHING');

    expect(exception.toString(), equals('ANYTHING'));
  });
}
