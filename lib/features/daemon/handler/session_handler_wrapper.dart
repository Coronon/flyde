import 'package:flyde/core/networking/websockets/session.dart';

/// Wraps a [ClientSession] for routing and isolate management
class SessionHandlerWrapper {
  final ClientSession session;

  SessionHandlerWrapper(this.session);

  /// Handle a request made by a CLI client (treated as authenticated)
  ///
  /// The callback will be called with an optional response
  void handleCLI(dynamic message, void Function(dynamic) callback) {}

  /// Close the underlying connection and clean up
  Future<void> close() async {
    session.close();
  }
}
