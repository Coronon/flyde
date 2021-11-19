import 'package:args/command_runner.dart';

///flyde run <workflow:str>
///    --remote            -r      \<flag\>
///    --args              -a      \<str\>
class RunCommand extends Command {
  /// Command name 'flyde {name} ...'
  @override
  final name = 'run';

  /// Basic description of this command
  @override
  final description = 'Run command for this project.';

  RunCommand() {
    //* Add command line arguments for this command
    argParser.addOption(
      'remote',
      abbr: 'r',
      help: 'Remote to execute command on',
    );

    argParser.addOption(
      'args',
      abbr: 'a',
      defaultsTo: '',
      help: 'Arguments for command',
    );
  }

  @override
  void run() {}
}
