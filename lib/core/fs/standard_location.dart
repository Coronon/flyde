import 'dart:io';

enum StandardLocation { tmp }

extension StandardLocationImpl on StandardLocation {
  Directory get directory {
    switch (this) {
      case StandardLocation.tmp:
        return Directory.systemTemp;
    }
  }
}
