import 'dart:io';

import 'package:flyde/core/networking/server.dart';
import 'package:flyde/features/build_server/build_provider.dart';

Future<void> main() async {
  final server = await WebServer.open(InternetAddress.anyIPv4, 3030);
  final provider = BuildProvider(server);

  await provider.setup();
}
