import '../protocol/authentication.dart';
import '../protocol/protocol.dart';

import 'session.dart';

//* Type declarations
/// Different actions middleware can handle
enum MiddlewareAction {
  recieve,
  send,
}

/// A Middleware function for use in MiddlewareSession
///
/// Arguments: Calling [Session] instance, message, [MiddlewareAction] action and a proxy to the next [MiddlewareFunc].
typedef MiddlewareFunc = Future<dynamic> Function(
  dynamic,
  dynamic,
  MiddlewareAction,
  Future<dynamic> Function(dynamic),
);

//* Middleware implementations
/// A middleware that handles serialization and deserialization of messages.
Future<dynamic> protocolMiddleware(
  dynamic session,
  dynamic message,
  MiddlewareAction action,
  Future<dynamic> Function(dynamic) next,
) async {
  if (action == MiddlewareAction.recieve) {
    // Instantly deSerialize the message so other middleware can work with it
    dynamic msg;
    // We catch all errors here as we can't trust the incoming data
    try {
      msg = ProtocolDelegate.deSerialize(message);
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

/// Make an AuthenticationMiddleware with the given [isAuthenticated] handler.
///
/// [isAuthenticated] is called with an AuthRequest and should return if the user authenticated.
MiddlewareFunc makeAuthenticationMiddleware(
  Future<bool> Function(AuthRequest) isAuthenticated,
) {
  /// A middleware that authenticates a user
  Future<dynamic> authenticate(
    dynamic session,
    dynamic message,
    MiddlewareAction action,
    Future<dynamic> Function(dynamic) next,
  ) async {
    // Don't run on messages that should be send
    if (action == MiddlewareAction.send) return await next(message);

    if (message is AuthRequest) {
      // Let handler check if user is authenticated
      final bool authenticated = await isAuthenticated(message);
      session.storage['authenticated'] = authenticated;

      return AuthResponse(
        status: authenticated ? AuthResponseStatus.success : AuthResponseStatus.failure,
      );
    } else if (session.storage.containsKey('authenticated') && session.storage['authenticated']) {
      // User is already authenticated -> message is passed to the next middleware
      return await next(message);
    } else {
      // User is not authenticated -> send AuthResponse(Required)
      return AuthResponse(status: AuthResponseStatus.required);
    }
  }

  return authenticate;
}
