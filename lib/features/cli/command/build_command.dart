import 'dart:async';

import 'package:args/command_runner.dart';

import '../../../core/logs/logger.dart';
import '../controller/building_view_controller.dart';
import 'helper/command_arg_getter.dart';

/// A command that launches a build run using the given config.
///
/// A complete build includes multiple steps:
/// 1. Load and parse the project and compiler configuration
/// 2. Connect to the build server and exchange cache information
/// 3. Send non-cached files to the build server
/// 4. Wait for the build server to finish
/// 5. Download the resulting binary and logs
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

    argParser.addOption('logFormat',
        abbr: 'l',
        allowed: ['json', 'text', 'binary', 'ansi'],
        help: 'The format in which the logs should be saved to disk',
        defaultsTo: 'text',
        allowedHelp: {
          'json': 'Use when you want to process the logs',
          'text': 'Use when you want to view the logs as is',
          'binary': 'Use when you want to load the logs with flyde',
          'ansi': 'Use when you want to view the logs in the terminal',
        });
  }

  @override
  Future<void> run() async {
    //? Collect command line arguments
    final String configPath = useArg('config');
    final LogFormat logFormat = useArg<LogFormat>('logFormat', parser: (desc) {
      switch (desc) {
        case 'json':
          return LogFormat.json;
        case 'text':
          return LogFormat.text;
        case 'binary':
          return LogFormat.bytes;
        case 'ansi':
          return LogFormat.ansi;
        default:
          throw ArgumentError('Unknown log format: $desc');
      }
    });

    final controller = BuildingViewController(configPath, logFormat);

    await controller.executeTasks();
  }
}
