import 'package:args/command_runner.dart';

///flyde create config
///    --preset            -p      \<which:str\>
///    --name              -n      \<str\>
class CreateConfigCommand extends Command {
  /// Command name 'flyde create {name} ...'
  @override
  final name = 'config';

  /// Basic description of this command
  @override
  final description = 'Create a new config for this project.';

  CreateConfigCommand() {
    //* Add command line arguments for this command
    argParser.addOption(
      'preset',
      abbr: 'p',
      help: 'Available presets: []',
    );

    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'Name for the new config',
    );
  }

  @override
  void run() {}
}
