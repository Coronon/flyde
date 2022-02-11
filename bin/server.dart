import 'dart:io';

import 'package:flyde/core/networking/server.dart';
import 'package:flyde/core/networking/websockets/middleware.dart';
import 'package:flyde/core/networking/websockets/middleware/protocol_middleware.dart';
import 'package:flyde/features/build_server/build_provider.dart';

void main() async {
  final server = await WebServer.open(
    InternetAddress.anyIPv4,
    3030,
    wsMiddleware: [
      protocolMiddleware,
    ],
  );

  final provider = BuildProvider(server);

  await provider.setup();
}
