import 'dart:async';

import 'package:args/command_runner.dart';

import '../controller/building_view_controller.dart';
import 'command_arg_getter.dart';

///```sh
///flyde build
///    --config            -c      <name:str>
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
  }

  @override
  Future<void> run() async {
    //? Collect command line arguments
    final String configPath = useArg('config');

    final controller = BuildingViewController(configPath);

    await controller.executeTasks();
  }
}
