import 'dart:async';
import 'dart:isolate';

import '../../../core/async/connect.dart';
import '../../../core/async/interface.dart';
import '../../../core/networking/websockets/session.dart';
import 'project_session_message.dart';
import 'project_session.dart';

/// Runs in it's own isolate and manages one project and all
/// its communication over a [ClientSession] with the backend
class ProjectSessionWrapper extends Interface {
  /// Queue of messages
  final messageQueue = StreamController<InterfaceMessage>();

  late final String project;

  ProjectSessionWrapper._(SpawnedIsolate isolate) : super(isolate);

  /// Start a new [ProjectSession] in a fresh isolate
  Future<ProjectSessionWrapper> start(String project, String url) async {
    // Start new isolate for project
    final instance = ProjectSessionWrapper._(await connect(ReceivePort(), ProjectSession.start));

    // Setup newly created ProjectSession
    await instance.expectResponse(
      InterfaceMessage(ProjectSessionMessage.setup, [project, url]),
      timeout: Duration(seconds: 15),
    );

    return instance;
  }

  /// Handle a request made by a CLI client (treated as authenticated)
  ///
  /// [wait] controlls whether you expect a response
  Future<dynamic> handleCLI(InterfaceMessage message, [bool wait = true, Duration? timeout]) async {
    try {
      if (timeout != null && !wait) {
        throw ArgumentError("Timeout can not be set when not waiting for response");
      }

      if (wait) {
        return await expectResponse(message, timeout: timeout);
      } else {
        call(message, timeout: timeout);
      }
    } catch (err) {
      return InterfaceMessage('error', err);
    }
  }

  /// Close the underlying connection and clean up
  Future<void> close() async {
    // Teardown stream if instructed to shutdown
    await messageQueue.close();
  }

  @override
  Future<void> onMessage(InterfaceMessage message) async {
    // Discard messages if stream is already closed
    if (messageQueue.isClosed) return;

    messageQueue.add(message);
  }
}
