import 'dart:async';
import 'dart:io';

import 'middleware.dart';

/// Base class for client and server sessions
abstract class Session<T> {
  /// Awaitable to ensure ready for use
  late Future<void> ready;

  /// Individial storage attached to each session for ephemeral data
  Map<dynamic, dynamic> storage = <dynamic, dynamic>{};

  /// WebSocket connection used to transfer data from client <-> server
  late WebSocket _socket;

  /// A reference to the instantiated subclass.
  /// This is used to allow passing of non base [Session] objects
  /// such as [ServerSession] or [ClientSession].
  T? _ref;

  /// Handler for received messages
  Future<dynamic> Function(T, dynamic)? onMessage;

  /// Handler for encountered errors
  void Function(T, Object)? onError;

  /// Handler for stream closure
  void Function(T)? onDone;

  /// Custom handler executed after low level teardown
  Future<void> Function()? customTeardown;

  /// Send data over the WebSocket
  void send(dynamic message) async {
    // Wait for the connection to be established to avoid errors
    await ready;

    if (_socket.readyState == WebSocket.open) _socket.add(message);
  }

  /// Teardown the connection and remove references to enable garbage collection
  ///
  /// Control whether any [customTeardown] function is called with the [runCustom]
  /// flag which defaults to true.
  Future<void> close({bool runCustom = true}) async {
    await _socket.close();

    // Run custom teardown
    if (runCustom && customTeardown != null) await customTeardown!();
  }

  /// Listen on the WebSocket.
  /// This should be called AFTER the WebSocket has been created by the subclass.
  void _listen() => _socket.listen(_onData, onError: _onError, onDone: _onDone);

  /// Internal delegation handler for received messages
  void _onData(dynamic message) async {
    if (onMessage != null) {
      dynamic response = await onMessage!(_ref!, message);
      if (response != null) send(response);
    }
  }

  /// Internal delegation handler for encountered errors
  void _onError(Object error) async {
    if (onError != null) {
      onError!(_ref!, error);
    }

    await close();
  }

  /// Internal delegation handler for stream closure
  void _onDone() {
    if (onDone != null) {
      onDone!(_ref!);
    }

    _ref = null;
  }
}

/// Extends base session to add support for installing middleware
class MiddlewareSession<T> extends Session<T> {
  /// List of installed middleware.
  ///
  /// Each middleware recieves the calling [Session] instance, message,
  /// [MiddlewareAction] and a proxy to the next [MiddlewareFunc].
  List<MiddlewareFunc> middleware = <MiddlewareFunc>[];

  /// Internal index to handle running middleware
  late int _middlewareIndex;

  /// Internal cache to handle running middleware
  late MiddlewareAction _middlewareAction;

  /// Run all installed middleware on given message and action
  Future<dynamic> runMiddleware(dynamic message, MiddlewareAction action) async {
    _middlewareIndex = 0;
    _middlewareAction = action;
    return await _nextMiddleware(message);
  }

  /// Internal implementation of recursively running middleware
  Future<dynamic> _nextMiddleware(dynamic message) async {
    if (_middlewareIndex == middleware.length) return message;
    _middlewareIndex += 1;

    return await middleware[_middlewareIndex - 1](
      _ref!,
      message,
      _middlewareAction,
      _nextMiddleware,
    );
  }

  //* Overrides to include middleware

  @override
  void send(dynamic message) async {
    message = await runMiddleware(message, MiddlewareAction.send);
    if (message == null) return;

    super.send(message);
  }

  @override
  void _onData(dynamic message) async {
    message = await runMiddleware(message, MiddlewareAction.recieve);
    if (message == null) return;

    super._onData(message);
  }
}

/// Session implementation specific to server-side applications
class ServerSession extends MiddlewareSession<ServerSession> {
  ServerSession(HttpRequest request) {
    // This reference is used to allow the superclass [Session] to pass
    // on a reference to this subclass
    _ref = this;

    ready = _init(request);
  }

  /// Internal initializer
  Future<void> _init(HttpRequest request) async {
    // Create WebSocket from HTTP request (101 - upgrade)
    _socket = await WebSocketTransformer.upgrade(request);
    // Listen on the socket
    _listen();
  }
}
