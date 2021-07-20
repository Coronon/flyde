import 'package:flyde/core/networking/server.dart';

/// Get current URI to server
Uri getUri(WebServer? server, String prefix) {
  return Uri.parse('$prefix://${server!.address!.host}:${server.port!}');
}
