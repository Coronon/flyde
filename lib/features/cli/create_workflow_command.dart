import 'package:args/command_runner.dart';

///flyde create workflow
///    --name              -n      \<str\>
class CreateWorkflowCommand extends Command {
  /// Command name 'flyde create {name} ...'
  @override
  final name = 'workflow';

  /// Basic description of this command
  @override
  final description = 'Create a new workflow for this project.';

  CreateWorkflowCommand() {
    //* Add command line arguments for this command
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'Name for the new workflow',
    );
  }

  @override
  void run() {}
}
