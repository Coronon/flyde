/// Different actions middleware can handle
enum MiddlewareAction {
  receive,
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
