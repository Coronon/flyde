import 'dart:convert';

import 'authentication.dart';

typedef Deserialize<T> = T Function(Map<String, dynamic>);

class ProtocolDelegate {
  /// A dictionary of all protocol elements and their coresponding deserializers
  static Map<String, Deserialize> elements = <String, Deserialize>{
    //* Authentication
    'AuthRequest': (Map<String, dynamic> json) => AuthRequest.fromJson(json),
    'AuthResponse': (Map<String, dynamic> json) => AuthResponse.fromJson(json),
  };

  static String serialize(dynamic message) {
    // Get className
    String type = message.runtimeType.toString();
    String data = jsonEncode(message);

    return '{"type":"$type","data":$data}';
  }

  static dynamic deSerialize(String message) {
    Map<String, dynamic> data = jsonDecode(message);
    if (!data.containsKey('type')) {
      throw ProtocolException("Message does not contain 'type' property");
    }
    String type = data['type'];

    if (!elements.containsKey(type)) {
      throw ProtocolException("'$type' unknown protocol element");
    }
    return elements[type]!(data['data']);
  }
}

class ProtocolException implements Exception {
  String message;
  ProtocolException(this.message);

  @override
  String toString() {
    return message;
  }
}
