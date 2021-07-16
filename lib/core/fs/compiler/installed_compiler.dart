import 'dart:convert';
import 'dart:io';

import 'package:json_annotation/json_annotation.dart';

enum InstalledCompiler {
  @JsonValue('g++')
  gpp
}

extension InstalledCompilerImpl on InstalledCompiler {
  static final _available = <InstalledCompiler, bool>{}; // map [Self: bool]

  static final _location = <InstalledCompiler, String>{};

  Future<bool> isAvailable() async {
    if (InstalledCompilerImpl._available.containsKey(this)) {
      return InstalledCompilerImpl._available[this]!;
    }

    await path();
    return InstalledCompilerImpl._available[this]!;
  }

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

  String _command() {
    switch (this) {
      case InstalledCompiler.gpp:
        return 'g++';
    }
  }
}
