import 'dart:async';
import 'dart:io';

import 'websockets/session.dart';
import 'websockets/middleware.dart';

class WebServer {
  /// Awaitable to ensure ready for use
  late Future<void> ready;

  /// List of middleware that should be installed in each WebSocket session.
  ///
  /// Each middleware recieves the calling [Session] instance, message,
  /// [MiddlewareAction] and a proxy to the next [MiddlewareFunc].
  List<MiddlewareFunc> wsMiddleware;

  /// Handler for received WebSocket messages
  Future<dynamic> Function(ServerSession, dynamic)? wsOnMessage;

  /// Handler for encountered WebSocket errors
  void Function(ServerSession, Object)? wsOnError;

  /// Handler for stream WebSocket closure
  void Function(ServerSession)? wsOnDone;

  /// Handler for received HTTP requests.
  ///
  /// NOTE: Please ensure this calls `close()` on the response
  void Function(HttpRequest)? httpOnRequest;

  /// If WebSocket upgrade requests should be redirected
  /// to the HTTP handler if no [wsOnMessage] was specified.
  bool redirectWebsocket;

  /// Handler for stream WebSocket closure that wraps [wsOnDone]
  /// but also removes the session from the server.
  late void Function(ServerSession) wsOnDoneTeardown;

  /// HttpServer instance used to establish initial connection
  HttpServer? _server;

  /// List of all connected WebSockets
  final List<ServerSession> _wsSessions = <ServerSession>[];

  /// Create a WebServer that can handle HTTP and WebSocket connections
  ///
  /// For a secure connection specify a [securityContext] the server should use.
  WebServer(
    InternetAddress bindAddress,
    int bindPort, {
    SecurityContext? securityContext,
    this.wsMiddleware = const <MiddlewareFunc>[],
    this.wsOnMessage,
    this.wsOnError,
    this.wsOnDone,
    this.httpOnRequest,
    this.redirectWebsocket = false,
  }) {
    // Construct wrapper for wsOnDone
    wsOnDoneTeardown = (ServerSession sess) {
      _wsSessions.remove(sess);

      if (wsOnDone != null) wsOnDone!(sess);
    };

    ready = _init(bindAddress, bindPort, securityContext);
  }

  /// Internal initialisation
  Future<void> _init(
    InternetAddress bindAddress,
    int bindPort,
    SecurityContext? securityContext,
  ) async {
    if (securityContext == null) {
      _server = await HttpServer.bind(
        bindAddress,
        bindPort,
        shared: true,
      );
    } else {
      _server = await HttpServer.bindSecure(
        bindAddress,
        bindPort,
        securityContext,
        shared: true,
      );
    }
    _server!.autoCompress = true;
    _server!.listen(_onRequest);
  }

  /// Internal request handler
  void _onRequest(HttpRequest req) async {
    bool isWebsocketRequest = req.headers['upgrade'] != null &&
        req.headers['upgrade']!.length == 1 &&
        req.headers['upgrade']![0] == 'websocket';

    // Handle WebSocket connections
    if (wsOnMessage != null && isWebsocketRequest) {
      ServerSession newSess = ServerSession(req);
      newSess.middleware = wsMiddleware;
      newSess.onMessage = wsOnMessage;
      newSess.onError = wsOnError;
      newSess.onDone = wsOnDoneTeardown;

      _wsSessions.add(newSess);
    } else if (httpOnRequest != null &&
        (!isWebsocketRequest || redirectWebsocket)) {
      // Handle normal requests (or redirected WebSocket connections)
      httpOnRequest!(req);
    } else {
      // No Handler found, return 404
      req.response.statusCode = 404;
      req.response.close();
    }
  }

  /// The address the server is bound to
  InternetAddress? get address {
    if (_server == null) {
      return null;
    }

    return _server!.address;
  }

  /// The port the server is listening on
  int? get port {
    if (_server == null) {
      return null;
    }

    return _server!.port;
  }

  /// Wether there are no active WebSocket connections
  bool get isEmpty {
    return _wsSessions.isEmpty;
  }

  /// Close the WebServer and teardown all connections
  Future<void> close() async {
    await ready;

    await _server!.close();

    for (ServerSession sess in _wsSessions) {
      // Remove wrapped done handler, as we will clear the sessions afterwards
      sess.onDone = wsOnDone;
      await sess.close();
    }

    _wsSessions.clear();
  }
}
