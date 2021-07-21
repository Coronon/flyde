import 'dart:io';

import 'package:flyde/core/networking/server.dart';

/// Open a WebServer instance on localhost with a random port
Future<WebServer> openWebServer({bool waitForReady = true}) async {
  final server = WebServer.open(InternetAddress.loopbackIPv4, 0);
  if (waitForReady) await server;
  return server;
}
