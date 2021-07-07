import 'dart:io';

import 'package:flyde/core/fs/configs/compiler_config.dart';
import 'package:flyde/core/fs/compiler/installed_compiler.dart';
import 'package:flyde/core/fs/standard_location.dart';
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

  final _headerPath = <String>[];

  final _objectPath = <String>[];

  late final Directory _workingDirectory;

  Compiler(this._config, this._files, this._cache) {
    _workingDirectory = StandardLocation.tmp.directory.createTempSync('flyde-compiler');
  }

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
  Future<void> addFile(CacheFile file) async {
    if (!_files.containsKey(file.id)) {
      throw Exception('File of id "${file.id}" is not part of the project');
    }

    if (file.hash != _files[file.id]) {
      throw Exception('The files[${file.id}] hash code is not in sync with the project');
    }

    await _cache.store(file, FileType.source);
  }

  /// Compiles the project and stores the object files and executables in the cache
  Future<void> compile() async {
    final srcFiles = _cache.all(FileType.source).where((file) => !_isHeaderFile(file)).toList();
    final compileCommands = <_ProcessInvocation>[];

    await _setupTempDirectory();

    for (final file in srcFiles) {
      compileCommands.add(await _buildCompileCommand(file));
    }

    await _runCommands(compileCommands, threads: _config.threads);
    await _runCommands([await _buildLinkCommand()]);
  }

  bool _isHeaderFile(CacheFile file) {
    // TODO: Get header file extensions from project configuration
    return ['h', 'hpp', 'h++', 'hh'].contains(file.extension);
  }

  String get _sourceTempDirPath => '${_workingDirectory.path}/source';

  String get _objectTempDirPath => '${_workingDirectory.path}/object-files';

  Future<void> _setupTempDirectory() async {
    for (final file in _cache.all(FileType.source)) {
      final sourcePath = file.buildFullPath(parentDirectory: _sourceTempDirPath);
      final fileRef = File(sourcePath);

      await fileRef.create(recursive: true);
      await fileRef.writeAsBytes(file.data.toList());

      if (_isHeaderFile(file)) {
        _headerPath.add(sourcePath);
      }
    }
  }

  Future<_ProcessInvocation> _buildCompileCommand(CacheFile file) async {
    if (!await _config.compiler.isAvailable()) {
      throw Exception('Requested compiler is not available on build machine');
    }

    // TODO: Change include command construction algorythm when supporting more compilers
    final includes = _headerPath.map((path) => '-I$path');
    final compilerPath = await _config.compiler.path();
    final sourcePath = file.buildFullPath(parentDirectory: _sourceTempDirPath);
    final objectPath = '$_objectTempDirPath/${file.id}.o';

    _objectPath.add(objectPath);

    return _ProcessInvocation(
        compilerPath!, [...includes, '-c', sourcePath, '-o', objectPath, ..._config.compilerFlags]);
  }

  Future<_ProcessInvocation> _buildLinkCommand() async {
    final path = await _config.compiler.path();

    // TODO: Maybe call linker directly (eg ld)
    return _ProcessInvocation(path!, [..._objectPath, ..._config.linkerFlags]);
  }

  static Future<void> _runCommands(List<_ProcessInvocation> invocations, {int threads = 1}) async {
    threads = threads < 1 ? 1 : threads;

    final groups = List<List<_ProcessInvocation>>.filled(threads, <_ProcessInvocation>[]);

    final runSync = (List<_ProcessInvocation> invocations) async {
      for (final invoc in invocations) {
        await Process.run(invoc.executable, invoc.args);
      }
    };

    for (var i = 0; i < invocations.length; ++i) {
      groups[i % threads].add(invocations[i]);
    }

    await Future.wait(groups.map((group) => runSync(group)));
  }
}

class _ProcessInvocation {
  final String executable;

  final List<String> args;

  _ProcessInvocation(this.executable, this.args);
}
