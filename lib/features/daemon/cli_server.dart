import 'package:flyde/features/daemon/daemon.dart';

/// Gateway between CLI and Daemon
class CLIServer {
  final Daemon daemon;

  CLIServer(this.daemon);
}
