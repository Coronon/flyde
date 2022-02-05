import 'dart:async';

import '../../../core/async/event_synchronizer.dart';
import '../../../core/networking/websockets/session.dart';

/// Creates an [EventSynchronizer] for a [ClientSession].
///
/// An optional [messageHandler] can be assigned which executes on
/// every message received from the server.
EventSynchronizer syncSession(
  ClientSession session, [
  FutureOr<void> Function(dynamic)? messageHandler,
]) {
  final sync = EventSynchronizer(session.send, Duration(milliseconds: 100));

  // Pass all messages received by 'session' to the synchronizer
  session.onMessage = (session, message) async {
    await messageHandler?.call(message);
    await sync.handleMessage(message);
  };

  return sync;
}
