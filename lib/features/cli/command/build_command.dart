import 'dart:async';

import 'package:args/command_runner.dart';

import '../controller/building_view_controller.dart';
import 'command_arg_getter.dart';

///```sh
///flyde build
///    --config            -c      <name:str>
///    --output            -o      <path:str>
///    --logs              -l      <path:str>
///    --verbose           -v      <flag>
/// ```
class BuildCommand extends Command with CommandArgGetter {
  /// Command name 'flyde {name} ...'
  @override
  final name = 'build';

  /// Basic description of this command
  @override
  final description = 'Handle builds of the current project.';

  BuildCommand() {
    //* Add command line arguments for this command
    argParser.addOption(
      'config',
      abbr: 'c',
      defaultsTo: 'default.config.yaml',
      help: 'Path to build config file',
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
  Future<void> run() async {
    //? Collect command line arguments
    final String configPath = useArg('config');
    final String outputPath = useArg('output');
    final String logsPath = useArg('logs');

    final controller = BuildingViewController(configPath, outputPath, logsPath);

    await controller.executeTasks();
  }
}
