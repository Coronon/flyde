import '../../../core/networking/websockets/middleware/protocol_middleware.dart';
import '../../../core/networking/websockets/session.dart';

/// Creates a new session to the server using the [host] and [port].
///
/// The created [ClientSession] is a wrapper around a `WebSocket` connection.
Future<ClientSession> createClientSession(String host, int port) async {
  const String prefix = 'ws';
  final Uri uri = Uri.parse('$prefix://$host:$port');
  final session = ClientSession(uri.toString())..middleware = const [protocolMiddleware];

  await session.ready;

  return session;
}
