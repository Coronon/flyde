import 'dart:async';

import '../../core/networking/websockets/session.dart';
import '../../core/networking/protocol/authentication.dart';
import '../../core/networking/websockets/middleware.dart';

import 'cli_server.dart';
import 'handler/session_handler_wrapper.dart';

/// Middleware that is applied to all connections
const List<MiddlewareFunc> basicMiddleware = [
  encryptionMiddleware,
  protocolMiddleware,
];

/// The deamon that continuously runs on the client's computer
class Daemon {
  //* Stream subscriptions

  /// Server that handles interactions with the CLI
  late final _cliServer = CLIServer(this);

  /// Map of all projects to their corresponding build-server connections
  ///
  /// Project(ID) -> [SessionHandlerWrapper]
  final Map<String, SessionHandlerWrapper> _projects = {};

  //TODO Constructor

  //* Message passing

  /// Attempt to forward message from CLI to [SessionHandlerWrapper]
  ///
  /// This will throw a [StateError] if project was not found.
  /// The returned Future will resolve with an optional response.
  Future<dynamic> forwardToSessionWrapper(String project, dynamic message) {
    final completer = Completer<dynamic>();

    // Attempt to find SessionHandlerWrapper for project
    if (!_projects.containsKey(project)) throw StateError('Project not found');

    _projects[project]!.handleCLI(message, (dynamic response) => completer.complete(response));

    return completer.future;
  }

  //* Lifecycle

  /// Connect a project to its build-server and save connection in [_projects]
  ///
  /// This is a noop if the [project] is already connected to the [url].
  /// If the [url] is different, the old connection will be closed and
  /// one to the new [url] established.
  Future<SessionHandlerWrapper> connectToServer(
    String project,
    String url,
    AuthRequest? credentials,
  ) async {
    // Allow only one connection per project
    if (_projects.containsKey(project)) {
      if (_projects[project]!.session.storage['url'] == url) {
        return _projects[project]!;
      }

      // Url is different, close old
      closeConnection(project);
    }

    // Establish connection
    final connection = ClientSession(url);
    connection.storage['url'] = url;
    connection.middleware = basicMiddleware;
    await connection.ready;

    // Try to login if credentials are provided
    if (credentials != null) {
      connection.send(credentials);
    }

    // Store connection
    final wrapper = SessionHandlerWrapper(connection);
    _projects[project] = wrapper;

    return wrapper;
  }

  /// Close established connection to build-server for [project]
  ///
  /// This is a noop if the [project] is not connected
  Future<void> closeConnection(String project) async {
    // Don't attempt to close nonexistent connection
    if (!_projects.containsKey(project)) return;

    // Tear down connection
    await _projects[project]!.close();
    _projects.remove(project);
  }

  /// Gracefully shut down the daemon
  ///
  /// This closes all connections
  Future<void> shutdown() async {
    // Close all connections
    for (final String project in _projects.keys) {
      await closeConnection(project);
    }
  }
}
