import 'package:args/command_runner.dart';

///flyde build
///    --config            -c      \<name:str\>
///    --detached          -d      \<flag\>
///    --output            -o      \<path:str\>
///    --logs              -l      \<path:str\>
///    --verbose           -v      \<flag\>
class BuildCommand extends Command {
  /// Command name 'flyde {name} ...'
  @override
  final name = "build";

  /// Basic description of this command
  @override
  final description = "Handle builds of the current project.";

  BuildCommand() {
    //* Add command line arguments for this command
    argParser.addOption(
      'config',
      abbr: 'c',
      defaultsTo: 'build.conf',
      help: 'Path to build config file',
    );

    argParser.addFlag(
      'detached',
      abbr: 'd',
      defaultsTo: false,
      negatable: false,
      help: 'Run build in detached mode',
    );

    argParser.addOption(
      'output',
      abbr: 'o',
      defaultsTo: 'build.out',
      help: 'Path the build output should be written to',
    );

    argParser.addOption(
      'logs',
      abbr: 'l',
      defaultsTo: 'logs.txt',
      help: 'Path the build logs should be written to',
    );

    argParser.addFlag(
      'verbose',
      abbr: 'v',
      defaultsTo: false,
      negatable: false,
      help: 'Enable verbose output',
    );
  }

  @override
  void run() {}
}
