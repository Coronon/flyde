import '../../protocol/protocol.dart';

import 'middleware_types.dart';

/// A middleware that handles serialization and deserialization of messages.
Future<dynamic> protocolMiddleware(
  dynamic session,
  dynamic message,
  MiddlewareAction action,
  Future<dynamic> Function(dynamic) next,
) async {
  if (action == MiddlewareAction.receive) {
    // Instantly deserialize the message so other middleware can work with it
    dynamic msg;
    // We catch all errors here as we can't trust the incoming data
    try {
      msg = ProtocolDelegate.deserialize(message);
    } catch (e) {
      session.raise(e);
      return null;
    }

    return await next(msg);
  } else {
    // Let other middleware work with the message, finally serialize it
    return ProtocolDelegate.serialize(await next(message));
  }
}
