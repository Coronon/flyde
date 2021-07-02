import 'package:flyde/core/fs/configs/compiler_config.dart';
import 'package:flyde/features/build_server/cache.dart';
import 'package:flyde/features/build_server/cache_file.dart';

class Compiler {
  /// Settings for compilation.
  final CompilerConfig _config;

  /// Map of all project files.
  /// Key: Unique file ID.
  /// Value: File hash code.
  final Map<String, String> _files;

  /// Internal file cache. Required for storing source, object and executable files.
  final Cache _cache;

  Compiler(this._config, this._files, this._cache);

  /// Returns a `List` of all file ids which are out of date and need to be synced using `addFile`.
  List<String> get outdatedFiles {
    var outdated = <String>[];

    for (final entry in _files.entries) {
      try {
        final cached = _cache.retrieve(entry.key, FileType.source);

        if (cached.hash != entry.value) {
          outdated.add(entry.key);
        }
      } catch (e) {
        outdated.add(entry.key);
      }
    }

    return outdated;
  }

  /// `true` if any of the source files changed since last compilation.
  bool get requiresRecompile => true;

  /// Adds a file to internal cache.
  /// Required for each source file.
  void addFile(CacheFile file) async {
    if (!_files.containsKey(file.id)) {
      throw Exception('File of id "${file.id}" is not part of the project');
    }

    if (file.hash != _files[file.id]) {
      throw Exception('The files[${file.id}] hash code is not in sync with the project');
    }

    await _cache.store(file, FileType.source);
  }

  /// Compiles the project and stores the object files and executables in the cache
  void compile() async {}
}
