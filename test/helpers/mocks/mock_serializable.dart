/// Mock implementation of serializable as used in
/// [ProtocolDelegate]
class MockSerializable {
  final String value;

  const MockSerializable(this.value);

  factory MockSerializable.fromJson(Map<String, dynamic> json) => MockSerializable(json['value']);
  Map<String, dynamic> toJson() => <String, dynamic>{'value': value};
}
