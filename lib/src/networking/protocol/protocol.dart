import 'dart:convert';

import 'authentication.dart';

typedef Deserialize<T> = T Function(Map<String, dynamic>);

class ProtocolDelegate {
  /// A dictionary of all protocol elements and their coresponding deserializers
  static Map<String, Deserialize> elements = <String, Deserialize>{
    //* Authentication
    'AUTH_REQUEST': (Map<String, dynamic> json) => AUTH_REQUEST.fromJson(json),
    'AUTH_RESPONSE': (Map<String, dynamic> json) => AUTH_RESPONSE.fromJson(json),
  };

  static String serialize(dynamic message) {
    // Get className
    String type = message.runtimeType.toString();
    String data = jsonEncode(message);

    return '{"type":"$type","data":$data}';
  }

  static dynamic deSerialize(String message) {
    Map<String, dynamic> data = jsonDecode(message);
    if (!data.containsKey('type')) throw ProtocolError("Message does not contain 'type' property");
    String type = data['type'];

    if (!elements.containsKey(type)) throw ProtocolError("'$type' unknown protocol element");
    return elements[type]!(data['data']);
  }
}

class ProtocolError extends Error {
  String cause;
  ProtocolError(this.cause);

  @override
  String toString() {
    return cause;
  }
}
