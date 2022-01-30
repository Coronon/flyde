import 'dart:io';

import 'package:path/path.dart';

import '../../core/fs/configs/compiler_config.dart';
import '../../core/fs/compiler/installed_compiler.dart';
import '../../core/fs/wrapper/source_file.dart';
import '../../core/logs/log_level.dart';
import '../../core/logs/log_scope.dart';
import '../../core/logs/logger.dart';
import 'cache/implementation_object_ref.dart';
import 'cache/project_cache.dart';

/// A class that manages compilation and caching of user C++ projects.
///
/// ```dart
/// final Compiler compiler = Compiler(configuration, filesOfTheProject, cacheInstance);
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
  /// Delegate object which is called when the build state changes.
  CompilerStatusDelegate? delegate;

  /// The configuration used to compile the project.
  CompilerConfig _config;

  /// The object which takes care of file placement and caching.
  final ProjectCache _cache;

  /// A list of all files of the user project with their id and hash.
  Map<String, String> _projectFiles;

  /// List of all outdated and unavailable files.
  List<String>? _outdatedFiles;

  /// The total count of all source files which will be compiled.
  int srcFileCount = 0;

  /// The current progress of compilation in a range from 0 to 1.
  double progress = 0;

  /// [Logger] for the compilation process.
  ///
  /// Reset using [logger.reset()] after compilation
  /// has finished. Otherwise messages of two iterations
  /// will be mixed up.
  final Logger logger = Logger();

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
  /// If no executable is available, `null` is returned.
  Future<File?> get lastExecutable async {
    await _syncCache();
    final exe = await _cache.executable;

    if ((await exe.stat()).size == 0) {
      return null;
    }

    return exe;
  }

  /// Updates the cache with the given project files and config.
  void update(CompilerConfig config, Map<String, String> projectFiles) {
    _projectFiles = projectFiles;
    _config = config;
    _outdatedFiles = null;
  }

  /// Adds the [file] to the cache. Required for all files which should be compiled.
  Future<void> insert(SourceFile file) async {
    if (_outdatedFiles == null) {
      await _syncCache();
    }

    _outdatedFiles!.remove(file.id);
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
        'There are ${_outdatedFiles!.length} outdated files. Pass those files to `insert` in order to finish synchronization.',
      );
    }

    final srcFiles = await _cache.sourceFiles;
    final compileCommands = <_ProcessInvocation>[];

    srcFileCount = srcFiles.length;
    progress = 0;
    delegate?.didStartCompilation();

    for (final file in srcFiles) {
      compileCommands.add(await _buildCompileCommand(file));
    }

    await _runCommands(
      compileCommands,
      threads: _config.threads,
      logger: logger,
      scope: LogScope.compiler,
    );

    delegate?.didFinishCompilation();

    await _runCommands(
      [await _buildLinkCommand()],
      logger: logger,
      scope: LogScope.linker,
    );

    await _cache.finish();

    delegate?.done();
  }

  /// Synchronizes the cache with the given project files and config.
  ///
  /// A list of all files which require an update is returned and stored in `_outdatedFiles`.
  Future<List<String>> _syncCache() async {
    _outdatedFiles = await _cache.sync(_projectFiles, _config);
    return _outdatedFiles!;
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

    return _ProcessInvocation(
      compilerPath!,
      [...includes, '-c', sourcePath, '-o', objectPath, ..._config.compilerFlags],
      () async {
        await ref.link();
        progress += 1 / srcFileCount;
        delegate?.isCompiling(progress);
      },
    );
  }

  /// Builds the command that links the given object files.
  Future<_ProcessInvocation> _buildLinkCommand() async {
    final path = await _config.compiler.path();
    final objectFiles = await _cache.objectFiles;

    delegate?.didStartLinking();

    // TODO: Maybe call linker directly (eg ld)
    return _ProcessInvocation(
      path!,
      [
        ...objectFiles.map((file) => file.path),
        '-o',
        (await _cache.executable).path,
        ..._config.linkerFlags
      ],
      () async => delegate?.didFinishLinking(),
    );
  }

  /// Runs the given commands on multiple [threads].
  ///
  /// The [scope] indicates how the output of the processes should
  /// be logged using the provided [logger].
  static Future<void> _runCommands(
    List<_ProcessInvocation> invocations, {
    int threads = 1,
    required Logger logger,
    required LogScope scope,
  }) async {
    threads = threads < 1 ? 1 : threads;

    final groups = List<List<_ProcessInvocation>>.generate(threads, (_) => <_ProcessInvocation>[]);

    /// Runs the commands in the order they are present in [invocs]
    /// and calls each completion handler after execution.
    /// Each process will be started after the previous one has finished.
    /// If all started processes are using only one thread,
    /// `run` will also only use one thread at a time.
    Future<void> run(List<_ProcessInvocation> invocs) async {
      for (final invoc in invocs) {
        final ProcessResult result = await Process.run(invoc.executable, invoc.args);
        final didFail = result.exitCode != 0;

        await invoc.completionHandler?.call();

        if (result.stdout.isNotEmpty) {
          logger.add(
            result.stdout,
            description: '${invoc.executable} on stdout',
            scope: scope,
            level: didFail ? LogLevel.warning : LogLevel.info,
          );
        }

        if (result.stderr.isNotEmpty) {
          logger.add(
            result.stderr,
            description: '${invoc.executable} on stderr',
            scope: scope,
            level: didFail ? LogLevel.error : LogLevel.warning,
          );
        }

        if (didFail) {
          logger.add(
            'Exited with error code ${result.exitCode}',
            description: invoc.executable,
            scope: scope,
            level: LogLevel.error,
          );
        }
      }
    }

    // We group the commands in [threads] groups.
    // So each group contains the same number of commands (+- 1).
    for (int i = 0; i < invocations.length; ++i) {
      groups[i % threads].add(invocations[i]);
    }

    // We run all the groups in parallel.
    await Future.wait(groups.map((group) => run(group)));
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

/// The status delegate of the `Compiler`.
mixin CompilerStatusDelegate {
  /// Called when the compiler has started compiling.
  void didStartCompilation();

  /// Called when the compiler has finished a compiliation stage.
  void isCompiling(double progress);

  /// Called when the compiler has finished compiling.
  void didFinishCompilation();

  /// Called when the compiler has started linking.
  void didStartLinking();

  /// Called when the compiler has finished linking.
  void didFinishLinking();

  /// Called when the compiler has finished.
  void done();
}
