import 'dart:io';

import 'package:flyde/core/fs/configs/compiler_config.dart';
import 'package:flyde/core/fs/compiler/installed_compiler.dart';
import 'package:flyde/core/fs/wrapper/source_file.dart';
import 'package:flyde/features/build_server/cache/implementation_object_ref.dart';
import 'package:flyde/features/build_server/cache/project_cache.dart';
import 'package:path/path.dart';

class Compiler {
  CompilerConfig _config;

  final ProjectCache _cache;

  Map<String, String> _projectFiles;

  List<String>? _outdatedFiles;

  Compiler(this._config, this._projectFiles, this._cache);

  /// List of all outdated project file ids.
  /// These files have to be `insert`ed.
  Future<List<String>> get outdatedFiles async {
    if (_outdatedFiles != null) {
      return _outdatedFiles!;
    }

    return await _syncCache();
  }

  Future<File?> get lastExecutable async {
    try {
      return await _cache.executable;
    } catch (_) {
      return null;
    }
  }

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
    if (_outdatedFiles == null) {
      await _syncCache();
    }

    if (_outdatedFiles!.isNotEmpty) {
      throw StateError(
          'There are ${_outdatedFiles!.length} outdated files. Use `insert` to sync your project.');
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

  Future<List<String>> _syncCache() async {
    final files = await _cache.sync(_projectFiles, _config);
    _outdatedFiles = files;
    return files;
  }

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

  static Future<void> _runCommands(List<_ProcessInvocation> invocations, {int threads = 1}) async {
    threads = threads < 1 ? 1 : threads;

    final groups = List<List<_ProcessInvocation>>.generate(threads, (_) => <_ProcessInvocation>[]);

    final runSync = (List<_ProcessInvocation> invocs) async {
      for (final invoc in invocs) {
        await Process.run(invoc.executable, invoc.args);
        await invoc.completionHandler?.call();
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

  final Future<void> Function()? completionHandler;

  _ProcessInvocation(this.executable, this.args, this.completionHandler);

  @override
  String toString() {
    return '$executable ${args.join(' ')}';
  }
}
