import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../core/fs/configs/project_config.dart';
import '../../../core/fs/yaml.dart';
import 'helper/command_arg_getter.dart';

/// Initiates a project with a name, and the information
/// how to reach the build server.
///
/// This includes the server's host name and port.
class InitCommand extends Command with CommandArgGetter {
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
      mandatory: true,
      help: 'Name of the new project',
    );

    argParser.addOption(
      'server',
      abbr: 's',
      mandatory: true,
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
  Future<void> run() async {
    final int port = useArg('port', parser: (arg) => int.parse(arg));
    final String name = useArg('name');
    final String server = useArg('server');

    final ProjectConfig projectConfig = ProjectConfig(
      name: name,
      host: server,
      port: port,
    );

    final yaml = encodeAsYaml(projectConfig.toJson());
    final file = File('${Directory.current.path}/project.yaml');

    await file.writeAsString(yaml);
  }
}
