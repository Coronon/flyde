import 'dart:isolate';

import '../../../core/async/connect.dart';
import '../../../core/async/interface.dart';
import '../../../core/networking/websockets/session.dart';

/// Runs in it's own isolate and manages one project and all
/// its communication over a [ClientSession] with the backend
class ProjectSession extends Interface {
  /// The running instance in this isolate
  ///
  /// Used to keep the instance alive
  static ProjectSession? _instance;

  ProjectSession._(SpawnedIsolate isolate) : super(isolate);

  /// Used to start a new [ProjectSession] in a freshly spawned isolate
  static void start(SendPort sendPort, ReceivePort receivePort) {
    if (_instance != null) {
      throw StateError('A worker instance is already running in this isolate.');
    }

    _instance = ProjectSession._(
      SpawnedIsolate(Isolate.current, receivePort)..sendPort = sendPort,
    )..ready.complete();
  }

  @override
  Future<void> onMessage(InterfaceMessage message) async {
    message.respond(isolate.sendPort, message);
  }
}
