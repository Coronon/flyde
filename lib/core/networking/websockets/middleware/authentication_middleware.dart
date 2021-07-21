import '../../protocol/authentication.dart';

import '../middleware.dart';

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
