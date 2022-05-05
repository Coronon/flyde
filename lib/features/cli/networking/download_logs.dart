import 'dart:convert';
import 'dart:io';

import '../../../core/async/event_synchronizer.dart';
import '../../../core/logs/logger.dart';
import '../../../core/networking/protocol/project_build.dart';

/// Requests the logs of the last build of the [session] and writes them
/// to the [outFile].
Future<void> downloadLogs(
  EventSynchronizer session,
  File outFile, {
  LogFormat format = LogFormat.text,
}) async {
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

  switch (format) {
    case LogFormat.json:
      await outFile.writeAsString(jsonEncode(logger.toJson()));
      break;
    case LogFormat.text:
      await outFile.writeAsString(logger.toString());
      break;
    case LogFormat.bytes:
      await outFile.writeAsBytes(logger.toBytes());
      break;
    case LogFormat.ansi:
      await outFile.writeAsString(logger.toString(formatForTerminal: true));
      break;
    default:
      throw ArgumentError('Unknown log format: $format');
  }
}
