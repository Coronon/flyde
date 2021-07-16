import 'dart:io';

import 'package:flyde/core/fs/configs/compiler_config.dart';
import 'package:flyde/core/fs/compiler/installed_compiler.dart';
import 'package:flyde/core/fs/wrapper/source_file.dart';
import 'package:flyde/features/build_server/cache/implementation_object_ref.dart';
import 'package:flyde/features/build_server/cache/project_cache.dart';
import 'package:path/path.dart';

/// A class that manages compilation and caching of user C++ projects.
///
/// ```dart
/// final  Compiler compiler = Compiler(configuration, filesOfTheProject, cacheInstance);
///
/// // A list of all the files that are absent or out of date in the cache.
/// final List<String> filesToUpdate = await compiler.outdatedFiles;
///
/// // We have to insert all the files that are absent or out of date.
/// for (final outdated in filesToUpdate) {
///   final SourceFile sourceFile = loadSourceFile(outdated);
///   await compiler.insert(sourceFile);
/// }
///
/// // We call compile so the compiler will invoke the C++ compiler and handle the cache.
/// await compiler.compile();
///
/// // Now we can run the compiled binary.
/// runBinary(compiler.lastExecutable!);
/// ```
///
/// If the configuration or the project changes over time we can update the compiler as well.
/// Afterwards we have to check if there are new outdated files and insert them.
///
/// ```dart
/// compiler.update(newConfig, newFileList);
/// ```
class Compiler {
  CompilerConfig _config;

  final ProjectCache _cache;

  Map<String, String> _projectFiles;

  List<String>? _outdatedFiles;

  Compiler(this._config, this._projectFiles, this._cache);

  /// List of all outdated and unavailable files.
  /// These files have to be `insert`ed.
  Future<List<String>> get outdatedFiles async {
    if (_outdatedFiles != null) {
      return _outdatedFiles!;
    }

    return await _syncCache();
  }

  /// A file reference to the last compiled executable of the currect config.
  ///
  /// If no executable is available, this will be `null`.
  Future<File?> get lastExecutable async {
    try {
      return await _cache.executable;
    } catch (_) {
      return null;
    }
  }

  /// Updates the cache with the given project files and config.
  void update(CompilerConfig config, Map<String, String> projectFiles) {
    _projectFiles = projectFiles;
    _config = config;
    _outdatedFiles = null;
  }

  /// Adds the [file] to the cache. Required for all files which should be compiled.
  Future<void> insert(SourceFile file) async {
    await _cache.insert(file);
  }

  /// Compiles the project.
  Future<void> compile() async {
    // If we don't have information about the sync status, we need to sync.
    if (_outdatedFiles == null) {
      await _syncCache();
    }

    // We cannot compile if not all files required are in the cache yet.
    if (_outdatedFiles!.isNotEmpty) {
      throw StateError(
          'There are ${_outdatedFiles!.length} outdated files. Pass those files to `insert` in order to finish synchronization.');
    }

    final srcFiles = await _cache.sourceFiles;
    final compileCommands = <_ProcessInvocation>[];

    for (final file in srcFiles) {
      compileCommands.add(await _buildCompileCommand(file));
    }

    await _runCommands(compileCommands, threads: _config.threads);
    await _runCommands([await _buildLinkCommand()]);
    await _cache.finish();
  }

  /// Synchronizes the cache with the given project files and config.
  ///
  /// A list of all files which require an update is returned and stored in `_outdatedFiles`.
  Future<List<String>> _syncCache() async {
    final files = await _cache.sync(_projectFiles, _config);
    _outdatedFiles = files;
    return files;
  }

  /// Builds the command that compiles the given source file.
  ///
  /// When compilation is done the `link` method of [ref] is called,
  /// which signals that the source file has now an up to date object file.
  Future<_ProcessInvocation> _buildCompileCommand(ImplementationObjectRef ref) async {
    if (!await _config.compiler.isAvailable()) {
      throw ArgumentError('Requested compiler is not available on build machine');
    }

    // TODO: Change include command construction algorythm when supporting more compilers
    final includes = _cache.headerFiles.map((file) => '-I${dirname(file.path)}').toSet();
    final compilerPath = await _config.compiler.path();
    final sourcePath = ref.source.path;
    final objectPath = ref.object.path;

    return _ProcessInvocation(compilerPath!,
        [...includes, '-c', sourcePath, '-o', objectPath, ..._config.compilerFlags], ref.link);
  }

  /// Builds the command that links the given object files.
  Future<_ProcessInvocation> _buildLinkCommand() async {
    final path = await _config.compiler.path();
    final objectFiles = await _cache.objectFiles;

    // TODO: Maybe call linker directly (eg ld)
    return _ProcessInvocation(
        path!,
        [
          ...objectFiles.map((file) => file.path),
          '-o',
          (await _cache.executable).path,
          ..._config.linkerFlags
        ],
        null);
  }

  /// Runs the given commands on multiple [threads].
  static Future<void> _runCommands(List<_ProcessInvocation> invocations, {int threads = 1}) async {
    threads = threads < 1 ? 1 : threads;

    final groups = List<List<_ProcessInvocation>>.generate(threads, (_) => <_ProcessInvocation>[]);

    final runSync = (List<_ProcessInvocation> invocs) async {
      for (final invoc in invocs) {
        await Process.run(invoc.executable, invoc.args);
        await invoc.completionHandler?.call();
      }
    };

    for (int i = 0; i < invocations.length; ++i) {
      groups[i % threads].add(invocations[i]);
    }

    await Future.wait(groups.map((group) => runSync(group)));
  }
}

/// A class which stores the data to invoke a process and a completion handler.
class _ProcessInvocation {
  /// The path to the executable.
  final String executable;

  /// The arguments to invoke the executable with.
  final List<String> args;

  /// A completion handler which should be called when the process has finished.
  final Future<void> Function()? completionHandler;

  _ProcessInvocation(this.executable, this.args, this.completionHandler);

  @override
  String toString() {
    return '$executable ${args.join(' ')}';
  }
}
