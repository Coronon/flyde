import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../core/console/terminal_color.dart';
import '../../../core/fs/configs/compiler_config.dart';
import '../../../core/fs/yaml.dart';
import 'command_arg_getter.dart';

///flyde run
///    --config            -c      \<str\>
///    --args              -a      \<str\>
class RunCommand extends Command with CommandArgGetter {
  /// Command name 'flyde {name} ...'
  @override
  final name = 'run';

  /// Basic description of this command
  @override
  final description = 'Execute an available binary.';

  RunCommand() {
    //* Add command line arguments for this command
    argParser.addOption(
      'args',
      abbr: 'a',
      defaultsTo: '',
      help: 'Arguments which should be passed to the binary',
    );

    argParser.addOption(
      'config',
      abbr: 'c',
      defaultsTo: 'default',
      help: 'A config file. Can be the path to the YAML file or the name (<name>.config.yaml)',
    );
  }

  @override
  Future<void> run() async {
    final String configName = useArg('config');
    final List<String> args = useArg<String>('args').split(' ').where((a) => a.isNotEmpty).toList();
    final CompilerConfig config;
    final String configPath =
        configName.toLowerCase().endsWith('yaml') ? configName : '$configName.config.yaml';

    try {
      final Map<String, dynamic> yaml = loadYamlAsMap(
        await File(configPath).readAsString(),
      );

      config = CompilerConfig.fromJson(yaml);
    } catch (e) {
      print(TerminalColor.red.prepare('Could not load config file: $configPath'));
      return;
    }

    final String binaryPath = config.binaryPath;

    if (!await File(binaryPath).exists()) {
      print(TerminalColor.red.prepare('Could not find binary: $binaryPath'));
      return;
    }

    final Process proc = await Process.start(
      binaryPath,
      args,
      runInShell: true,
      includeParentEnvironment: true,
      workingDirectory: Directory.current.absolute.path,
    );

    stdout.addStream(proc.stdout);
    stderr.addStream(proc.stderr);

    final int exitCode = await proc.exitCode;

    //? Wait until the output from the sub process is
    //? flushed to stdout and stderr
    await Future.delayed(Duration(milliseconds: 100));

    if (exitCode == 0) {
      print(TerminalColor.green.prepare('Process completed successfully'));
    } else {
      print(TerminalColor.red.prepare('Process failed with exit code: $exitCode'));
    }
  }
}
