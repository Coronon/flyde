import 'package:args/command_runner.dart';

///flyde init
///    --name              -n      \<str\>
///    --server            -s      \<str\>
///    --port              -p      \<num\>
class InitCommand extends Command {
  /// Command name 'flyde {name} ...'
  @override
  final name = 'init';

  /// Basic description of this command
  @override
  final description = 'Initialize a new project.';

  InitCommand() {
    //* Add command line arguments for this command
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'Name of the new project',
    );

    argParser.addOption(
      'server',
      abbr: 's',
      help: 'Server the new project should be hosted on',
    );

    argParser.addOption(
      'port',
      abbr: 'p',
      defaultsTo: '18820',
      help: 'Port of the flyde build server listens to on the server',
    );
  }

  @override
  void run() {}
}
