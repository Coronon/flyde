/// Different actions middleware can handle
enum MiddlewareAction {
  RECEIVE,
  SEND,
}

/// Contract between multiple pieces of middleware in a chain.
///
/// Arguments: Message and [MiddlewareAction] action.
typedef NextMiddlewareFunc = void Function(dynamic, MiddlewareAction);

/// A Middleware function for use in MiddlewareSession
///
/// Arguments: Calling [Session] instance, message, [MiddlewareAction] action and the next [MiddlewareFunc].
typedef MiddlewareFunc = void Function(dynamic, dynamic, MiddlewareAction, NextMiddlewareFunc);
