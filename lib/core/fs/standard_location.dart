import 'dart:io';

import 'package:path/path.dart';

/// An enumeration of the most common directories to store application data.
enum StandardLocation { tmp, library, applicationLibrary }

/// An extension on `StandardLocation` that provides a `Directory` object for each location.
extension StandardLocationImpl on StandardLocation {
  /// The `Directory` object for this location.
  Directory get directory {
    switch (this) {
      case StandardLocation.tmp:
        return Directory.systemTemp;
      case StandardLocation.library:
        return Directory('/var/lib');
      case StandardLocation.applicationLibrary:
        if (Platform.environment.containsKey('FLYDE_APPLIBRARY')) {
          return Directory(Platform.environment['FLYDE_APPLIBRARY'] as String);
        }

        return Directory(join(StandardLocation.library.directory.path, 'flyde'));
    }
  }
}
