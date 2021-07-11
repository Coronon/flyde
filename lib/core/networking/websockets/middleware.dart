/// Different actions middleware can handle
enum MiddlewareAction {
  recieve,
  send,
}

/// A Middleware function for use in MiddlewareSession
///
/// Arguments: Calling [Session] instance, message, [MiddlewareAction] action and a proxy to the next [MiddlewareFunc].
typedef MiddlewareFunc = void Function(dynamic, dynamic, MiddlewareAction, void Function(dynamic));
