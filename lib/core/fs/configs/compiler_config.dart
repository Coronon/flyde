import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:json_annotation/json_annotation.dart';

import '../compiler/installed_compiler.dart';

part 'compiler_config.g.dart';

/// A JSON serializable class that contains the compiler configuration.
@JsonSerializable()
class CompilerConfig {
  /// The used compiler.
  final InstalledCompiler compiler;

  /// The number of threads used by the compiler.
  final int threads;

  /// A list of all directory pathes where source files are located.
  final List<String> sourceDirectories;

  /// The local path on the user's machine where the binary should be saved.
  final String binaryPath;

  /// The local path on the user's machine where the logs should be saved.
  final String logDirectory;

  /// The flags to pass to the compiler.
  List<String> compilerFlags;

  /// The flags to pass to the linker.
  List<String> linkerFlags;

  CompilerConfig({
    required this.compiler,
    required this.threads,
    required this.sourceDirectories,
    required this.compilerFlags,
    required this.linkerFlags,
    this.binaryPath = './bin.out',
    this.logDirectory = './logs',
  }) {
    _validate();
  }

  factory CompilerConfig.fromJson(Map<String, dynamic> json) {
    // Json needs to be modifiale, so missing keys can be replaced with default values.
    json = Map.from(json);

    if (!json.containsKey('linkerFlags') || json['linkerFlags'] == null) {
      json['linkerFlags'] = <String>[];
    }

    if (!json.containsKey('compilerFlags') || json['compilerFlags'] == null) {
      json['compilerFlags'] = <String>[];
    }

    return _$CompilerConfigFromJson(json);
  }

  Map<String, dynamic> toJson() => _$CompilerConfigToJson(this);

  /// A hash which is unique for each compiler + linker configuration.
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

  /// Validates the input and throws an exception if it is invalid.
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
    String cleanInput(String flag) {
      if (invalidOptions.contains(flag)) {
        throw ArgumentError('"$flag" is not allowed in configuration files.');
      }

      final isFlag = RegExp(r'-{1,2}[a-zA-Z0-9]+[^\s]*').stringMatch(flag)?.length == flag.length;
      final isValue = RegExp(r'[a-zA-Z0-9]+[^\s]*').stringMatch(flag)?.length == flag.length;

      if (!isFlag && isValue) {
        return '"$flag"';
      }

      return flag;
    }

    compilerFlags = compilerFlags.map(cleanInput).toList();
    linkerFlags = linkerFlags.map(cleanInput).toList();
  }

  /// Returns a [CompilerConfig] with the recommended default compiler settings
  /// and given [src] file directories, [compiler] and [threads].
  /// The binary path will be created from the given [name].
  static defaultConfig(
    String name,
    List<String> src,
    InstalledCompiler compiler, {
    required int threads,
  }) {
    return CompilerConfig(
      compiler: compiler,
      threads: threads,
      binaryPath: './$name.bin.out',
      sourceDirectories: src,
      compilerFlags: [
        '-std=c++17',
        '-D_FORTIFY_SOURCE=2',
        '-D_GLIBCXX_ASSERTIONS',
        '-fasynchronous-unwind-tables',
        '-fexceptions',
        '-g',
        '-grecord-gcc-switches',
        '-O2',
        '-Wall',
        '-Werror=format-security',
      ],
      linkerFlags: [],
    );
  }
}
