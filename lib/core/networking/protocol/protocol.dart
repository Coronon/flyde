import 'dart:convert';

import 'authentication.dart';

/// Function signature of '$.fromJson'
typedef Deserialize<T> = T Function(Map<String, dynamic>);

/// Intermediate between transmittable and usable messages.
///
/// This class translates protocol messages to transmittable (string)
/// messages and vice versa.
class ProtocolDelegate {
  /// A dictionary of all protocol elements and their coresponding deserializers
  //? This should not be final because of how testing is implemented.
  static Map<String, Deserialize> elements = <String, Deserialize>{
    //* Authentication
    'AuthRequest': (Map<String, dynamic> json) => AuthRequest.fromJson(json),
    'AuthResponse': (Map<String, dynamic> json) => AuthResponse.fromJson(json),
  };

  /// Serialize a protocol message to a transmittable message
  static String serialize(dynamic message) {
    // Get className
    final String type = message.runtimeType.toString();
    final String data = jsonEncode(message);

    return '{"type":"$type","data":$data}';
  }

  /// Deserialize a transmittable message to a protocol message
    final Map<String, dynamic> data = jsonDecode(message);
    if (!data.containsKey('type')) {
      throw ProtocolException("Message does not contain 'type' property");
    }
    final String type = data['type'];

    if (!elements.containsKey(type)) {
      throw ProtocolException("'$type' unknown protocol element");
    }
    return elements[type]!(data['data']);
  }
}

/// Exception exclusively used by [ProtocolDelegate]
class ProtocolException implements Exception {
  final String message;
  ProtocolException(this.message);

  @override
  String toString() {
    return message;
  }
}
