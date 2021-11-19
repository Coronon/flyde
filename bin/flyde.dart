import 'package:args/command_runner.dart';

import 'package:flyde/features/cli/build_command.dart';

void main(List<String> args) {
  final runner = CommandRunner("flyde", "An easy to use C++ distributed compilation framework.")
    ..addCommand(BuildCommand())
    ..run(args);
}
