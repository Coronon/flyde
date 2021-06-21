import 'dart:async';
import 'dart:io';

/// Base class for client and server sessions
abstract class Session<T> {
  /// Awaitable to ensure ready for use
  late Future<void> ready;

  /// Common identifier between server and client
  String? id;

  /// WebSocket connection used to transfer data from client <-> server
  late WebSocket _socket;

  late StreamSubscription<dynamic> _subscription;

  /// A reference to the instantiated subclass.
  /// This is used to allow passing of non base [Session] objects
  /// such as [ServerSession] or [ClientSession].
  T? _ref;

  /// Handler for received messages
  dynamic Function(T, dynamic)? onMessage;

  /// Handler for encountered errors
  void Function(T, Object)? onError;

  /// Handler for stream closure
  void Function(T)? onDone;

  /// Send data over the WebSocket
  void send(dynamic message) async {
    // Wait for the connection to be established to avoid errors
    await ready;

    _socket.add(message);
  }

  /// Teardown the connection and remove references to enable garbage collection
  Future<void> teardown() async {
    _ref = null;
    await _subscription.cancel();
    await _socket.close();
  }

  /// Listen on the WebSocket.
  /// This should be called AFTER the WebSocket has been created by the subclass.
  void _listen() => _subscription = _socket.listen(_onData, onError: _onError, onDone: _onDone);

  /// Internal delegation handler for received messages
  void _onData(dynamic message) async {
    if (onMessage != null) {
      dynamic response = onMessage!(_ref!, message);
      if (response != null) _socket.add(response);
    }
  }

  /// Internal delegation handler for encountered errors
  void _onError(Object error) async {
    if (onError != null) {
      onError!(_ref!, error);
    }

    await teardown();
  }

  /// Internal delegation handler for stream closure
  void _onDone() async {
    if (onDone != null) {
      onDone!(_ref!);
    }

    await teardown();
  }
}

class ServerSession extends Session<ServerSession> {
  ServerSession(HttpRequest request) {
    // This reference is used to allow the superclass [Session] to pass
    // on a reference to this subclass
    _ref = this;

    ready = _init(request);
  }

  Future<void> _init(HttpRequest request) async {
    // Create WebSocket from HTTP request (101 - upgrade)
    _socket = await WebSocketTransformer.upgrade(request);
    // Listen on the socket
    _listen();
  }
}
