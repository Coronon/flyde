import 'package:flyde/core/fs/configs/CompilerConfig.dart';

class Compiler {
  /// Settings for compilation.
  CompilerConfig _config;

  /// Map of all project files.
  /// Key: Unique file ID.
  /// Value: File hash code.
  Map<String, String> _files = {};

  /// Internal file cache. Required for storing source, object and executable files.
  /// NOTE: Type must be changed to explicit
  dynamic _cache;

  Compiler(this._config, this._files, this._cache);

  /// Returns a `List` of all file ids which are out of date and need to be synced using `addFile`.
  List<String> get outdatedFiles => [];

  /// `true` if any of the source files changed since last compilation.
  bool get requiresRecompile => true;

  /// Adds a file to internal cache.
  /// Required for each source file.
  void addFile(dynamic file) async {}

  /// Compiles
  void compile() async {}
}
