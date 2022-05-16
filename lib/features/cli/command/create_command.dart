import 'package:args/command_runner.dart';

import 'create_config_command.dart';

///flyde create {command}
class CreateCommand extends Command {
  /// Command name 'flyde {name} ...'
  @override
  final name = 'create';

  /// Basic description of this command
  @override
  final description = 'Create project resources.';

  CreateCommand() {
    //* Add sub-commands for this command
    addSubcommand(CreateConfigCommand());
  }
}
