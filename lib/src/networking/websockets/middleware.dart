/// Different actions middleware can handle
enum MiddlewareAction {
  RECEIVE,
  SEND,
}

/// A Middleware function for use in MiddlewareSession
///
/// Arguments: Calling [Session] instance, message, [MiddlewareAction] action and a proxy to the next [MiddlewareFunc].
typedef MiddlewareFunc = void Function(dynamic, dynamic, MiddlewareAction, void Function(dynamic));

class MiddlewareRunner<T> {
  /// List of installed middleware.
  ///
  /// Each middleware recieves the calling [Session] instance, message,
  /// [MiddlewareAction] and a proxy to the next [MiddlewareFunc].
  List<MiddlewareFunc> middleware = <MiddlewareFunc>[];

  late T ref;

  late int _i;

  late MiddlewareAction _action;

  /// Run all installed middleware on given message and action
  dynamic run(dynamic message, MiddlewareAction action) {
    _i = 0;
    _action = action;
    return _next(message);
  }

  dynamic _next(dynamic message) {
    if (_i == middleware.length) return message;
    _i += 1;

    middleware[_i - 1](ref, message, _action, _next);
  }
}
