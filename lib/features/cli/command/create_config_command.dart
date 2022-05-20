import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../core/console/terminal_color.dart';
import '../../../core/fs/compiler/installed_compiler.dart';
import '../../../core/fs/configs/compiler_config.dart';
import '../../../core/fs/yaml.dart';
import 'helper/command_arg_getter.dart';

/// Creates a new compiler configuration file.
///
/// The compiler config contains how the compiler should build
/// the project, not where to reach it. That's defined in the
/// [ProjectConfig] file.
///
/// The compiler config file is a YAML file that contains the
/// following fields:
/// 1. The compiler's name
/// 2. The number of threads used for compilation
/// 3. The path to the local source files
/// 4. The path where the binary should be saved
/// 5. The path where the logs should be saved
/// 6. The flags to pass to the compiler
/// 7. The flags to pass to the linker
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
