import 'package:json_annotation/json_annotation.dart';

part 'compiler_config.g.dart';

enum CompilerID {
  @JsonValue('g++')
  gpp
}

@JsonSerializable()
class CompilerConfig {
  late final CompilerID compiler;

  late final int cores;

  late final List<String> sourceDirectories;

  late final List<String> compilerFlags;

  late final List<String> linkerFlags;

  CompilerConfig(
      {required this.compiler,
      required this.cores,
      required this.sourceDirectories,
      required this.compilerFlags,
      required this.linkerFlags}) {
    _validate();
  }

  factory CompilerConfig.fromJson(Map<String, dynamic> json) => _$CompilerConfigFromJson(json);

  Map<String, dynamic> toJson() => _$CompilerConfigToJson(this);

  void _validate() {
    const invalidOptions = ['-c'];

    if (cores <= 0) {
      final message = 'The number od used cores has to be greater than zero. Given: $cores';
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
