/// Different actions middleware can handle
enum MiddlewareAction {
  receive,
  send,
}

/// A Middleware function for use in MiddlewareSession
///
/// Arguments: Calling [Session] instance, message, [MiddlewareAction] action and a proxy to the next [MiddlewareFunc].
typedef MiddlewareFunc = Future<dynamic> Function(
  dynamic session,
  dynamic message,
  MiddlewareAction action,
  Future<dynamic> Function(dynamic) next,
);
