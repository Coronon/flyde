import 'dart:io';

import 'package:flyde/core/fs/wrapper/source_file.dart';
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
  final Map<String, MainInterface> _isolates = {};

  /// The cache that is used to store the compiled code.
  late final Cache _cache;

  BuildProvider(this._server);

  /// Sets up the server.
  Future<void> setup({Directory? cacheDirectory}) async {
    await _server.ready;

    _cache = await Cache.load(from: cacheDirectory);
    _server.wsOnMessage = _handleWebSocketMessage;
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

  /// Returns the interfacve with the given [id] or throws an exception.
  MainInterface _getInterface(String id) {
    if (_isolates.containsKey(id)) {
      return _isolates[id]!;
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
    if (_isolates.containsKey(message.id)) {
      return;
    }

    _isolates[message.id] = await MainInterface.launch();
    session.storage['id'] = message.id;
    _isolates[message.id]?.onStateUpdate = session.send;
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
  }
}
