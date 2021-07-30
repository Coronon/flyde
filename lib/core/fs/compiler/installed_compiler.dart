import 'dart:convert';
import 'dart:io';

import 'package:json_annotation/json_annotation.dart';

/// A JSON serializable enum of all supported C++ compilers.
enum InstalledCompiler {
  /// The g++ compiler.
  @JsonValue('g++')
  gpp
}

/// An extension on `InstalledCompiler` that provides availability
/// information and the path where it is installed.
extension InstalledCompilerImpl on InstalledCompiler {
  /// Cache for availability.
  static final _available = <InstalledCompiler, bool>{}; // map [Self: bool]

  /// Cache of the compiler's path.
  static final _location = <InstalledCompiler, String>{};

  /// A flag whether the compiler is available.
  Future<bool> isAvailable() async {
    if (InstalledCompilerImpl._available.containsKey(this)) {
      return InstalledCompilerImpl._available[this]!;
    }

    await path();
    return InstalledCompilerImpl._available[this]!;
  }

  /// The path where the compiler is installed.
  Future<String?> path() async {
    if (InstalledCompilerImpl._available.containsKey(this)) {
      return InstalledCompilerImpl._location[this];
    }

    // TODO: When supporting windows as a build platform, change compiler search
    String out = '';
    final proc = await Process.start('which', [_command()]);

    await proc.stdout.transform(utf8.decoder).forEach((el) => out += el);

    final exitCode = await proc.exitCode;
    final available = await File(out.trim()).exists();

    if (exitCode == 0 && available) {
      InstalledCompilerImpl._available[this] = true;
      InstalledCompilerImpl._location[this] = out.trim();
      return out.trim();
    }

    InstalledCompilerImpl._available[this] = false;
    return null;
  }

  /// The command used to invoke the compiler.
  String _command() {
    switch (this) {
      case InstalledCompiler.gpp:
        return 'g++';
    }
  }
}
