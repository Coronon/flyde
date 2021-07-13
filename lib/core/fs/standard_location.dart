import 'dart:io';

import 'package:path/path.dart';

enum StandardLocation { tmp, library, applicationLibrary }

extension StandardLocationImpl on StandardLocation {
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
