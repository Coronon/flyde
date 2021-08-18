import 'dart:io';
import 'dart:isolate';

import 'package:flyde/core/fs/wrapper/source_file.dart';
import 'package:flyde/core/networking/protocol/process_completion.dart';
import 'package:flyde/core/networking/protocol/project_build.dart';
import 'package:flyde/core/networking/protocol/project_update.dart';
import 'package:flyde/core/networking/protocol/project_init.dart';
import 'package:flyde/core/networking/server.dart';
import 'package:flyde/core/networking/websockets/session.dart';
import 'package:flyde/features/build_server/cache/cache.dart';
import 'package:flyde/features/build_server/cache/project_cache.dart';
import 'package:flyde/features/build_server/compiler_interface.dart';

/// Provides the build service on the local network.
///
/// A call to `setup` is mandatory to ensure that connections can be accepted.
class BuildProvider {
  /// The server that is used to handle connections.
  final WebServer _server;

  /// The list of interfaces to isolates which handle compilation.
  final Map<String, MainInterface> _interfaces = {};

  final Map<String, String> _availableProjects = {};

  /// The cache that is used to store the compiled code.
  late final Cache _cache;

  BuildProvider(this._server);

  /// Sets up the server.
  Future<void> setup({Directory? cacheDirectory}) async {
    await _server.ready;

    _cache = await Cache.load(from: cacheDirectory);
    _server.wsOnMessage = _handleWebSocketMessage;
  }

  /// Kills all project isolates and shuts down the server.
  Future<void> terminate() async {
    _availableProjects.keys.forEach(kill);
    _availableProjects.clear();
    _interfaces.clear();
    await _server.close();
  }

  /// Terminates the isolate which hosts the project with the id [projectId].
  void kill(String projectId) {
    final MainInterface? interface = _interfaces[projectId];

    if (interface != null) {
      interface.isolate.isolate.kill(priority: Isolate.immediate);
    }
  }

  /// Returns a list of all projects which have an active connection.
  List<String> get projectIds {
    return _availableProjects.keys.toList();
  }

  /// Returns the name of the project with the [projectId].
  ///
  /// If the project is not available, an argument error is thrown.
  String projectName(String projectId) {
    final String? name = _availableProjects[projectId];

    if (name != null) {
      return name;
    }

    throw ArgumentError('Project with id $projectId does not exists');
  }

  /// Handles a new websocket message.
  Future<void> _handleWebSocketMessage(ServerSession session, dynamic message) async {
    if (message is ProjectInitRequest) {
      await _handleProjectInit(session, message);
      return;
    }

    final String id = _ensureId(session);

    if (message is ProjectUpdateRequest) {
      await _handleProjectUpdate(session, message, id);
    }

    if (message is FileUpdate) {
      await _handleFileUpdate(session, message, id);
    }

    if (message == projectBuildRequest) {
      await _getInterface(id).build();
    }
  }

  /// Returns the interface with the given [id] or throws an exception.
  MainInterface _getInterface(String id) {
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
    if (_interfaces.containsKey(message.id)) {
      return;
    }

    _interfaces[message.id] = await MainInterface.launch();
    _availableProjects[message.id] = message.name;
    session.storage['id'] = message.id;
    _interfaces[message.id]?.onStateUpdate = session.send;

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
    final file = SourceFile(
      message.entry,
      message.path,
      message.name,
      message.extension,
      data: message.data,
    );

    await _getInterface(id).update(file);

    session.send(
      ProcessCompletionMessage(
        process: CompletableProcess.fileUpdate,
        description: file.id,
      ),
    );
  }
}
