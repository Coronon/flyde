import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:flyde/features/cli/command/build_command.dart';
import 'package:flyde/features/cli/command/create_command.dart';
import 'package:flyde/features/cli/command/init_command.dart';
import 'package:flyde/features/cli/command/load_command.dart';
import 'package:flyde/features/cli/command/run_command.dart';

void main(List<String> args) {
  CommandRunner('flyde', 'An easy to use C++ distributed compilation framework.')
    ..addCommand(BuildCommand())
    ..addCommand(LoadCommand())
    ..addCommand(InitCommand())
    ..addCommand(CreateCommand())
    ..addCommand(RunCommand())
    ..run(args).catchError((error) {
      if (error is! UsageException) throw error;
      print(error);
      exit(64); // Exit code 64 indicates a usage error.
    });
}
