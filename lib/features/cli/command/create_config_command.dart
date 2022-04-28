import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../core/console/terminal_color.dart';
import 'command_arg_getter.dart';
import '../../../core/fs/compiler/installed_compiler.dart';
import '../../../core/fs/configs/compiler_config.dart';
import '../../../core/fs/yaml.dart';

///```sh
///flyde create config
///    --preset            -p      <str>
///    --name              -n      <str>
///    --src               -s      <str[]>
///    --threads           -t      <int>
///    --compiler          -c      <str>
///```
class CreateConfigCommand extends Command with CommandArgGetter {
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
      defaultsTo: 'default',
      allowed: ['default'],
      help: 'Available presets',
    );

    argParser.addOption(
      'name',
      abbr: 'n',
      mandatory: true,
      help: 'Name for the new config',
    );

    argParser.addMultiOption(
      'src',
      abbr: 's',
      splitCommas: true,
      help: 'Locations of top level source directories',
    );

    argParser.addOption(
      'threads',
      abbr: 't',
      defaultsTo: '4',
      help: 'Number of threads used for compilation',
    );

    argParser.addOption(
      'compiler',
      abbr: 'c',
      allowed: ['g++'],
      defaultsTo: 'g++',
      help: 'Used underlying compiler',
    );
  }

  @override
  Future<void> run() async {
    final String preset = useArg('preset');
    final String name = useArg('name');
    final List<String> src = useArg('src');
    final int threads = useArg('threads', parser: (arg) => int.parse(arg));
    final String compilerId = useArg('compiler');
    final file = File('${Directory.current.path}/$name.config.yaml');

    if (await file.exists()) {
      const message =
          'Configuration with the same name already exists. Consider using a different name or modify the existing configuration.';
      stderr.writeln(TerminalColor.red.prepare(message));
      return;
    }

    final compiler = InstalledCompiler.values.firstWhere(
      (val) => val.name == compilerId,
    );

    // TODO: When supporting more default configs assign them here
    final CompilerConfig config = CompilerConfig.defaultConfig(
      name,
      src,
      compiler,
      threads: threads,
    );

    final yaml = encodeAsYaml(config.toJson());

    await file.writeAsString(yaml);
  }
}
