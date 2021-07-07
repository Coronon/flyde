import 'package:flyde/core/fs/compiler/installed_compiler.dart';
import 'package:json_annotation/json_annotation.dart';

part 'compiler_config.g.dart';

@JsonSerializable()
class CompilerConfig {
  final InstalledCompiler compiler;

  final int threads;

  final List<String> sourceDirectories;

  final List<String> compilerFlags;

  final List<String> linkerFlags;

  CompilerConfig(
      {required this.compiler,
      required this.threads,
      required this.sourceDirectories,
      required this.compilerFlags,
      required this.linkerFlags}) {
    _validate();
  }

  factory CompilerConfig.fromJson(Map<String, dynamic> json) => _$CompilerConfigFromJson(json);

  Map<String, dynamic> toJson() => _$CompilerConfigToJson(this);

  void _validate() {
    const invalidOptions = ['-c'];

    if (threads <= 0) {
      final message = 'The number od used threads has to be greater than zero. Given: $threads';
      throw Exception(message);
    }

    for (var flag in [...compilerFlags, ...linkerFlags]) {
      if (invalidOptions.contains(flag)) {
        throw Exception('"$flag" is not allowed in configuration files.');
      }

      if (!flag.startsWith(RegExp('-(-?)')) && !(flag.startsWith('"') && flag.endsWith('"'))) {
        flag = '"$flag"';
      }
    }
  }
}
