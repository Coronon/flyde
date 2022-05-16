import 'dart:io';

import '../../../core/async/event_synchronizer.dart';
import '../../../core/networking/protocol/project_build.dart';

/// Requests the binary of the last build of the [session] and writes it
/// to the [outFile].
Future<void> downloadBinary(EventSynchronizer session, File outFile) async {
  // Request the produced binary file
  await session.request(getBinaryRequest);
  final bin = await session.expect(
    BinaryResponse,
    handler: (BinaryResponse resp) => resp.binary,
  );

  if (bin == null) {
    throw StateError('No binary received from the build server');
  }

  await outFile.create(recursive: true);
  await outFile.writeAsBytes(bin.toList());
}
