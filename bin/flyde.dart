import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:flyde/features/cli/build_command.dart';
import 'package:flyde/features/cli/init_command.dart';
import 'package:flyde/features/cli/load_command.dart';

void main(List<String> args) {
  final runner = CommandRunner('flyde', 'An easy to use C++ distributed compilation framework.')
    ..addCommand(BuildCommand())
    ..addCommand(LoadCommand())
    ..addCommand(InitCommand())
    ..run(args).catchError((error) {
      if (error is! UsageException) throw error;
      print(error);
      exit(64); // Exit code 64 indicates a usage error.
    });
}
