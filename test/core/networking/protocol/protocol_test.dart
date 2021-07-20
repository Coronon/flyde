import 'package:test/test.dart';

import 'package:flyde/core/networking/protocol/protocol.dart';

void main() {
  // Add to known elements
  ProtocolDelegate.elements['MockSerializable'] =
      (Map<String, dynamic> json) => MockSerializable.fromJson(json);

  test('ProtocolDelegate can recreate object', () {
    final serializable = MockSerializable("ANYTHING");

    final dynamic recreated =
        ProtocolDelegate.deSerialize(ProtocolDelegate.serialize(serializable));

    expect(recreated is MockSerializable, equals(true));
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

    final dynamic deSerialized = ProtocolDelegate.deSerialize(serialized);

    expect(deSerialized is MockSerializable, equals(true));
    deSerialized as MockSerializable;
    expect(deSerialized.value, equals("ANYTHING"));
  });

  test('ProtocolDelegate throw if no type provided', () {
    final String msg = '{"data": {"value": "MockSerializable"}}';

    expect(
      () => ProtocolDelegate.deSerialize(msg),
      throwsA(
        isA<ProtocolException>().having(
          (ProtocolException error) => error.message,
          'message',
          equals("Message does not contain 'type' property"),
        ),
      ),
    );
  });

  test('ProtocolDelegate throw if invalid type provided', () {
    final String msg = '{"type": "NonExistentType", "data": {"value": "MockSerializable"}}';

    expect(
      () => ProtocolDelegate.deSerialize(msg),
      throwsA(
        isA<ProtocolException>().having(
          (ProtocolException error) => error.message,
          'message',
          equals("'NonExistentType' unknown protocol element"),
        ),
      ),
    );
  });

  test('ProtocolDelegate throw if invalid data', () {
    final String msg1 = '{"type": "MockSerializable", "data": {"value": 1}}';
    final String msg2 = '{"type": "MockSerializable", "data": {"ANYTHING": "ANYTHING"}}';

    expect(() => ProtocolDelegate.deSerialize(msg1), throwsA(isA<TypeError>()));
    expect(() => ProtocolDelegate.deSerialize(msg2), throwsA(isA<TypeError>()));
  });

  test('ProtocolDelegate throw if not json string', () {
    final String msg = 'ANYTHING';

    expect(() => ProtocolDelegate.deSerialize(msg), throwsA(isA<FormatException>()));
  });
}

/// Mock class to test serialization
  final String value;

  const MockSerializable(this.value);

  factory MockSerializable.fromJson(Map<String, dynamic> json) => MockSerializable(json['value']);
  Map<String, dynamic> toJson() => <String, dynamic>{'value': value};
}
