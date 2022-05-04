import 'dart:io';

import '../../../core/async/event_synchronizer.dart';
import '../../../core/logs/logger.dart';
import '../../../core/networking/protocol/project_build.dart';

/// Requests the logs of the last build of the [session] and writes them
/// to the [outFile].
Future<void> downloadLogs(EventSynchronizer session, File outFile) async {
  // Request the produced log file
  await session.request(getBuildLogsRequest);
  final bin = await session.expect(
    BinaryResponse,
    handler: (BinaryResponse resp) => resp.binary,
  );

  if (bin == null) {
    throw StateError('No logs received from the build server');
  }

  // Load the binary data into a logger object for parsing
  final logger = Logger.fromBytes(bin);

  await outFile.create(recursive: true);
  await outFile.writeAsString(logger.toString());
}
