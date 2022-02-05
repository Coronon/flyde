import '../../../core/networking/websockets/middleware/protocol_middleware.dart';
import '../../../core/networking/websockets/session.dart';

/// Creates a new session to the server using the [host] and [port].
///
/// The created [ClientSession] is a wrapper around a `WebSocket` connection.
ClientSession createClientSession(String host, int port) {
  const String prefix = 'ws';
  final Uri uri = Uri.parse('$prefix://$host:$port');

  return ClientSession(uri.toString())..middleware = const [protocolMiddleware];
}
