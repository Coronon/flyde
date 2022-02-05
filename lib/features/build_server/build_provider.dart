import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import '../../core/fs/wrapper/source_file.dart';
import '../../core/networking/protocol/process_completion.dart';
import '../../core/networking/protocol/project_build.dart';
import '../../core/networking/protocol/project_update.dart';
import '../../core/networking/protocol/project_init.dart';
import '../../core/networking/server.dart';
import '../../core/networking/websockets/session.dart';
import 'cache/cache.dart';
import 'cache/project_cache.dart';
import 'compiler_interface.dart';

/// Provides the build service on the local network.
///
/// A call to `setup` is mandatory to ensure that connections can be accepted.
class BuildProvider {
  /// The server that is used to handle connections.
  final WebServer _server;

  /// The list of interfaces to isolates which handle compilation.
  final Map<String, ProjectInterface> _interfaces = {};

  /// List of all projects which have a spawned worker isolate
  /// and can therefore accept build request.
  ///
  /// The projects are mapped as `id: name`
  final Map<String, String> _availableProjects = {};

  /// The cache that is used to store the compiled code.
  late final Cache _cache;

  /// A queue for each project that manages which client can
  /// access a project and which have to wait.
  final Map<String, Queue<ServerSession>> _projectCapacityQueues = {};

  BuildProvider(this._server);

  /// Sets up the server.
  Future<void> setup({Directory? cacheDirectory}) async {
    await _server.ready;

    _cache = await Cache.load(from: cacheDirectory);
    _server.wsOnMessage = _handleWebSocketMessage;
    _server.wsOnDone = (ServerSession session) {
      final String? id = session.storage['id'];

      if (id != null) {
        _activateNextSession(id, removing: session);
      }
    };
  }

  /// Kills all project isolates and shuts down the server.
  Future<void> terminate() async {
    _availableProjects.keys.toList().forEach(kill);
    _availableProjects.clear();
    _interfaces.clear();
    await _server.close();
  }

  /// Terminates the isolate which hosts the project with the id [projectId].
  void kill(String projectId) {
    final ProjectInterface? interface = _interfaces[projectId];

    if (interface != null) {
      interface.isolate.isolate.kill(priority: Isolate.immediate);
    }

    if (_availableProjects.containsKey(projectId)) {
      _availableProjects.remove(projectId);
    }
  }

  /// Returns a list of all projects which have an active connection.
  List<String> get activeProjectIds => _availableProjects.keys.toList();

  /// Returns the name of the project with the [projectId].
  ///
  /// If the project is not available, an argument error is thrown.
  String projectName(String projectId) {
    final String? name = _availableProjects[projectId];

    if (name != null) {
      return name;
    }

    throw StateError('Project with id $projectId does not exists');
  }

  /// Handles a new websocket message.
  Future<void> _handleWebSocketMessage(ServerSession session, dynamic message) async {
    //* Registration

    //? Each client has to register first using an init request
    if (message is ProjectInitRequest) {
      await _handleProjectInit(session, message);
      return;
    }

    //? All following messages require that the client is registered
    final String id = _ensureId(session);

    //* Resource Management

    //? A client reserves a place in the queue for a project
    if (message == reserveBuildRequest) {
      _projectCapacityQueues[id]!.addLast(session);

      if (_isFirstInQueue(session, id)) {
        await _activateSession(session, id);
      }
    }

    //? When unsubscribing a client gives it place in the
    //? queue to the next client waiting
    if (message == unsubscribeRequest) {
      await _activateNextSession(id, removing: session);
      return;
    }

    //? Only the first client in the queue for it's project
    //? is eligable to send build requests
    if (!_isFirstInQueue(session, id)) {
      session.send(isInactiveSessionResponse);
      return;
    }

    //* Compile Workflow

    //? Request to compile the project
    if (message == projectBuildRequest) {
      await _getInterface(id).build();
    }

    //? Updates the project state with a new
    //? source file list and configuration
    if (message is ProjectUpdateRequest) {
      await _handleProjectUpdate(session, message, id);
    }

    //? Update a specific file
    if (message is FileUpdate) {
      await _handleFileUpdate(session, message, id);
    }

    //? Download the latest binary
    if (message == getBinaryRequest) {
      await _handleBinaryRequest(session, message, id);
    }

    //? Download the logs for the last build
    if (message == getBuildLogsRequest) {
      await _handleLogsRequest(session, message, id);
    }
  }

  /// Checks if the [session] is the first in the queue for
  /// the project with the id [id].
  bool _isFirstInQueue(ServerSession session, String id) {
    if (_projectCapacityQueues[id]?.isNotEmpty == true) {
      return identical(_projectCapacityQueues[id]?.first, session);
    }

    return false;
  }

  /// Activates the first session in the queue for the project with the id [id].
  ///
  /// If [removing] is not null, the session is removed from the queue.
  Future<void> _activateNextSession(String id, {ServerSession? removing}) async {
    if (removing != null) {
      _projectCapacityQueues[id]?.remove(removing);
    }

    if (_projectCapacityQueues[id]?.isNotEmpty == true) {
      _activateSession(_projectCapacityQueues[id]!.first, id);
    }
  }

  /// Activates the [session] for the project with the id [id].
  Future<void> _activateSession(ServerSession session, String id) async {
    _interfaces[id]?.onStateUpdate = session.send;
    session.send(isActiveSessionResponse);
  }

  /// Returns the interface with the given [id] or throws an exception.
  ProjectInterface _getInterface(String id) {
    if (_interfaces.containsKey(id)) {
      return _interfaces[id]!;
    }

    throw StateError('Interface with id $id has not been created yet.');
  }

  /// Throws an error if the [session] has no id or returns it.
  String _ensureId(ServerSession session) {
    final dynamic id = session.storage['id'];

    if (id is String) {
      return id;
    }

    throw StateError('Session has no project id.');
  }

  /// Handles a new project initialization request.
  Future<void> _handleProjectInit(ServerSession session, ProjectInitRequest message) async {
    session.storage['id'] = message.id;

    if (!_interfaces.containsKey(message.id)) {
      _interfaces[message.id] = await ProjectInterface.launch();
      _availableProjects[message.id] = message.name;
      _interfaces[message.id]?.onStateUpdate = session.send;
      _projectCapacityQueues[message.id] = Queue<ServerSession>();
    }

    session.send(
      ProcessCompletionMessage(
        process: CompletableProcess.projectInit,
        description: '',
      ),
    );
  }

  /// Handles a new project update request.
  Future<void> _handleProjectUpdate(
    ServerSession session,
    ProjectUpdateRequest message,
    String id,
  ) async {
    final ProjectCache cache;

    if (!_cache.has(id)) {
      cache = await _cache.create(id);
    } else {
      cache = await _cache.get(id);
    }

    _getInterface(id).init(message.files, message.config, cache);

    session.send(
      ProjectUpdateResponse(
        files: await _getInterface(id).sync(
          message.files,
          message.config,
        ),
      ),
    );
  }

  /// Handles a new file update request.
  Future<void> _handleFileUpdate(
    ServerSession session,
    FileUpdate message,
    String id,
  ) async {
    final SourceFile file = await message.toSourceFile();

    await _getInterface(id).update(file);

    session.send(
      ProcessCompletionMessage(
        process: CompletableProcess.fileUpdate,
        description: file.id,
      ),
    );
  }

  /// Handles a binary request.
  Future<void> _handleBinaryRequest(
    ServerSession session,
    dynamic message,
    String id,
  ) async {
    final Uint8List? data = await _getInterface(id).binary;
    session.send(BinaryResponse(binary: data));
  }

  /// Handles a logs request.
  Future<void> _handleLogsRequest(
    ServerSession session,
    dynamic message,
    String id,
  ) async {
    final Uint8List data = await _getInterface(id).logData;
    session.send(BinaryResponse(binary: data));
  }
}
