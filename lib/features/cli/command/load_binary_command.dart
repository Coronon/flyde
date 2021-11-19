import 'package:args/command_runner.dart';

///flyde load binary
///    --output            -o      \<path:str\>
class LoadBinaryCommand extends Command {
  /// Command name 'flyde load {name} ...'
  @override
  final name = 'binary';

  /// Basic description of this command
  @override
  final description = 'Load the built binary.';

  LoadBinaryCommand() {
    //* Add command line arguments for this command
    argParser.addOption(
      'output',
      abbr: 'o',
      defaultsTo: 'build.out',
      help: 'Path to write loaded binary to',
    );
  }

  @override
  void run() {}
}
