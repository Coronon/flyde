import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:flyde/core/fs/compiler/installed_compiler.dart';
import 'package:json_annotation/json_annotation.dart';

part 'compiler_config.g.dart';

@JsonSerializable()
class CompilerConfig {
  final InstalledCompiler compiler;

  final int threads;

  final List<String> sourceDirectories;

  List<String> compilerFlags;

  List<String> linkerFlags;

  CompilerConfig({
    required this.compiler,
    required this.threads,
    required this.sourceDirectories,
    required this.compilerFlags,
    required this.linkerFlags,
  }) {
    _validate();
  }

  factory CompilerConfig.fromJson(Map<String, dynamic> json) => _$CompilerConfigFromJson(json);

  Map<String, dynamic> toJson() => _$CompilerConfigToJson(this);

  String get hash {
    final output = AccumulatorSink<Digest>();
    final input = sha256.startChunkedConversion(output);

    input.add(utf8.encode(compiler.toString()));
    input.add(compilerFlags.expand((flag) => utf8.encode(flag)).toList());
    input.add(utf8.encode('-- linker --'));
    input.add(linkerFlags.expand((flag) => utf8.encode(flag)).toList());
    input.close();

    return output.events.single.toString();
  }

  void _validate() {
    const invalidOptions = ['-c', '-o'];

    if (threads <= 0) {
      final message = 'The number of used threads has to be greater than zero. Given: $threads';
      throw ArgumentError(message);
    }

    /// Throws an error if a flag which is not allowed is used
    /// and wraps value args in double braces.
    /// ```dart
    /// var list = ['-c', '-o', '-x', 'hello'];
    /// list = list.map(cleanInput).toList();
    ///
    /// // ['-x', '"hello"']
    /// print(list);
    /// ```
    final cleanInput = (String flag) {
      if (invalidOptions.contains(flag)) {
        throw ArgumentError('"$flag" is not allowed in configuration files.');
      }

      final isFlag = RegExp(r'-{1,2}[a-zA-Z0-9]+[^\s]*').stringMatch(flag)?.length == flag.length;
      final isValue = RegExp(r'[a-zA-Z0-9]+[^\s]*').stringMatch(flag)?.length == flag.length;

      if (!isFlag && isValue) {
        return '"$flag"';
      }

      return flag;
    };

    compilerFlags = compilerFlags.map(cleanInput).toList();
    linkerFlags = linkerFlags.map(cleanInput).toList();
  }
}
