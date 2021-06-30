class CompilerConfig {
  late final String compiler;

  late final double capacity;

  late final List<String> entries;

  late final List<String> flags;

  late final Map<String, String> args;

  late final Map<String, String> trailingArgs;

  CompilerConfig(dynamic json) {
    compiler = json.compiler;
    capacity = json.capacity;
    entries = json.entries;
    flags = json.flags + json.trailingFlags;
    args = json.args;
    trailingArgs = json.trailingArgs;

    _validate();
  }

  void _validate() {
    const invalidOptions = ['c'];
    const allowedCompilers = ['g++'];

    if (!allowedCompilers.contains(compiler)) {
      final compilers = allowedCompilers.join(',');
      final message = 'Compiler has to be any of [$compilers]]. Given: "$compiler"';
      throw Exception(message);
    }

    if (capacity > 1 || capacity <= 0) {
      final capDesc = capacity.toStringAsFixed(3);
      final message = 'The capacity has to be in range 0 < capacity <= 1. Given: $capDesc';
      throw Exception(message);
    }

    for (final flag in flags) {
      if (flag.startsWith(RegExp('-(-?)'))) {
        throw Exception('A flag must not start with "-". Given: $flag');
      }

      if (invalidOptions.contains(flag)) {
        throw Exception('"$flag" is not allowed in configuration files.');
      }
    }

    for (final arg in [...args.entries, ...trailingArgs.entries]) {
      if (arg.key.startsWith(RegExp('-(-?)'))) {
        throw Exception('An argument must not start with "-". Given: ${arg.key}');
      }

      if (invalidOptions.contains(arg.key)) {
        throw Exception('"${arg.key}" is not allowed in configuration files.');
      }
    }
  }
}
