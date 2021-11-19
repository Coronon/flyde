import 'package:args/command_runner.dart';

import 'load_binary_command.dart';

///flyde load {command}
class LoadCommand extends Command {
  /// Command name 'flyde {name} ...'
  @override
  final name = 'load';

  /// Basic description of this command
  @override
  final description = 'Load project resources.';

  LoadCommand() {
    //* Add sub-commands for this command
    addSubcommand(LoadBinaryCommand());
  }

  @override
  void run() {}
}
