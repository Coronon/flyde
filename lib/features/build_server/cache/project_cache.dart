import 'dart:convert';
import 'dart:io';

import 'package:flyde/core/fs/configs/compiler_config.dart';
import 'package:flyde/core/fs/file_extension.dart';
import 'package:flyde/features/build_server/cache/dependencies/dependency_graph.dart';
import 'package:flyde/features/build_server/cache/dependencies/find_dependencies.dart';
import 'package:flyde/features/build_server/cache/dependencies/resolve_dependency.dart';
import 'package:flyde/features/build_server/cache/implementation_object_ref.dart';
import 'package:flyde/features/build_server/cache/state/config_state.dart';
import 'package:flyde/features/build_server/cache/state/project_cache_state.dart';
import 'package:flyde/core/fs/wrapper/source_file.dart';
import 'package:flyde/features/build_server/cache/state/source_file_state.dart';
import 'package:path/path.dart';

/// The cache for a single project.
///
/// Creates an abstraction around the raw source and object files.
///
/// After an instance has been created `init` has to be called.
/// ```
/// final cache = ProjectCache('my-id', directoryWhereCacheIsStored);
/// await cache.init(); // Neccessary to load persisted state
/// ```
class ProjectCache {
  /// The id of the project.
  final String _projectId;

  /// The directory where all cache files reside.
  late final Directory _workingDirectory;

  /// The persisted state of the cache.
  late final ProjectCacheState _state;

  /// The current config of the project.
  CompilerConfig? _config;

  /// List of all file ids which are not synced
  /// for the current config.
  Set<String> _unsyncedFiles = <String>{};

  /// Flag to indicate if the inter-file dependencies need to be updated.
  bool _needsDependencyUpdate = true;

  ProjectCache(this._projectId, Directory cacheDir) {
    _workingDirectory = Directory(join(cacheDir.path, _projectId));
  }

  /// Initiates the cache and loads persisted state if available.
  Future<void> init() async {
    if (await _stateFile.exists()) {
      final content = await _stateFile.readAsString();

      if (content.isEmpty) {
        _state = ProjectCacheState(configs: {}, files: {});
      } else {
        _state = ProjectCacheState.fromJson(jsonDecode(content));
      }
    } else {
      await _stateFile.create(recursive: true);
      _state = ProjectCacheState(configs: {}, files: {});
    }
  }

  /// Saves the cache state to disk.
  Future<void> finish() async {
    await _stateFile.writeAsString(json.encode(_state.toJson()));
  }

  /// Synchronizes the cache with the user project.
  ///
  /// [files] is a map where each unique file id is associated to it's hash value.
  /// `sync` checks which stored files are outdated and returns a `List` of
  /// those outdated files and each file which is not present in cache.
  ///
  /// [config] will be used to put files at the correct destination. To change the
  /// used config, call `sync` once more.
  Future<List<String>> sync(Map<String, String> files, CompilerConfig config) async {
    _config = config;
    _state.configs.add(ConfigState(
      checksum: config.hash,
      compiledFiles: {},
      dependencyGraph: DependencyGraph(nodes: {}),
    ));

    final required = <String>[];

    // Update dependency graph with new files
    _currentConfigState.dependencyGraph.update(files.keys.toSet());

    for (final entry in files.entries) {
      final id = entry.key;
      final checksum = entry.value;
      final matches = _state.files.where((file) => file.id == id);

      if (matches.length > 1) {
        throw StateError(
          'Did not expect to find more than one file of the same id in the state file.',
        );
      }

      if (matches.isEmpty) {
        required.add(id);
      } else if (matches.isNotEmpty && matches.first.hash != checksum) {
        _setIsCompiled(matches.first.id, false);
        required.add(id);
      }
    }

    _unsyncedFiles = required.toSet();
    _needsDependencyUpdate = true;

    return required;
  }

  /// Persists the passed [file].
  Future<void> insert(SourceFile file) async {
    if (!_unsyncedFiles.contains(file.id)) {
      return;
    }

    final entryDirectory = Directory(join(_workingDirectory.path, 'src', file.entry.toString()));
    final path = joinAll([entryDirectory.path, ...file.path, '${file.name}.${file.extension}']);
    final diskFile = File(path);

    await diskFile.create(recursive: true);
    await diskFile.writeAsBytes(await file.data, flush: true);

    if (_state.files.where((f) => f.id == file.id).isNotEmpty) {
      final stateFile = _state.files.singleWhere((f) => f.id == file.id);
      stateFile.hash = await file.hash;
    } else {
      _state.files.add(SourceFileState(id: file.id, hash: await file.hash, path: path));
    }
  }

  /// A list of all stored header files.
  List<File> get headerFiles {
    final headers = <File>[];

    for (final file in _state.files) {
      final ext = extension(file.path);

      if (FileExtension.headers.contains(ext)) {
        headers.add(File(file.path));
      }
    }

    return headers;
  }

  /// A list of all stored uncompiled source files.
  ///
  /// Each source file is returned as an object which contains
  /// a path to the source file itself and to the object file.
  /// The compiler must use this path to create the corresponding object file.
  /// After compilation the `link` method has to be called, to let
  /// the cache know that the latest version of the file has been compiled.
  /// ```dart
  /// final refs = await cache.sourceFiles;
  ///
  /// for (final ref in refs) {
  ///   await compile(sourcePath: ref.source, objectPath: ref.object);
  ///   await ref.link();
  /// }
  /// ```
  ///
  /// On the first call after [sync] the dependency graph is updated.
  Future<List<ImplementationObjectRef>> get sourceFiles async {
    final refs = <ImplementationObjectRef>[];

    // Ensure that the dependency graph is up to date.
    // Required to be able to determine which files have to be compiled.
    if (_needsDependencyUpdate) {
      _needsDependencyUpdate = false;
      await _updateDependencyGraph();
    }

    for (final file in _state.files.where((f) => _isCompilationCandidate(f))) {
      final sourceFile = File(file.path);
      final objectFile = File(_objectPath(file.id));

      await objectFile.create(recursive: true);

      refs.add(ImplementationObjectRef(
        sourceFile,
        objectFile,
        () async {
          final exists = await objectFile.exists();
          final isNotEmpty = (await objectFile.stat()).size > 0;

          if (exists && isNotEmpty) {
            _setIsCompiled(file.id, true);
          }
        },
      ));
    }

    return refs;
  }

  /// A list of all stored object files.
  ///
  /// Only those are returned which represent the latest
  /// version of the associated source file.
  Future<List<File>> get objectFiles async {
    final objectFiles = <File>[];

    for (final file in _state.files) {
      if (_isCompiled(file.id)) {
        objectFiles.add(File(_objectPath(file.id)));
      }
    }

    return objectFiles;
  }

  /// The path of the executable.
  Future<File> get executable async {
    final path = join(_workingDirectory.path, 'bin', _config!.hash, 'app.out');
    final file = File(path);

    await file.create(recursive: true);

    return file;
  }

  /// Creates the path for the object file of
  /// the source file with given [sourceId].
  String _objectPath(String sourceId) {
    return joinAll([_workingDirectory.path, 'obj', _config!.hash, '$sourceId.o']);
  }

  /// A reference to the file which stores the state of the cache.
  File get _stateFile => File(join(_workingDirectory.path, '.state.json'));

  /// Determine whether [file] has to be compiled based on previous compilation, extension and dependencies.
  bool _isCompilationCandidate(SourceFileState file) {
    final compiled = _isCompiled(file.id);
    final ext = extension(file.path);
    final isSource = FileExtension.sources.contains(ext);

    if (!isSource) {
      return false;
    }

    if (!compiled) {
      return true;
    }

    final dependencies = _currentConfigState.dependencyGraph.indirectDependencies(file.id);
    return dependencies.intersection(_unsyncedFiles).isNotEmpty;
  }

  /// Updates the dependency graph.
  ///
  /// Has to be called after all unsynced files have been inserted.
  Future<void> _updateDependencyGraph() async {
    final all = await _allSourceFiles;
    final Map<String, SourceFile> fileMap = {
      for (final file in all) file.id: file,
    };

    for (final id in _unsyncedFiles) {
      final dependencies = await findDependencies(fileMap[id]!);
      final root = Directory(join(
        _workingDirectory.path,
        'src',
        fileMap[id]!.entry.toString(),
      ));
      final resolved = await Future.wait(
        dependencies.map((d) => resolve(d, fileMap[id]!, all, root)),
      );

      _currentConfigState.dependencyGraph.connect(id, resolved.toSet());
    }
  }

  /// Returns whether the file with given [fileId] has been compiled.
  bool _isCompiled(String fileId) {
    return _currentConfigState.compiledFiles.contains(fileId);
  }

  /// Sets the [compiled] flag for the file with given [fileId].
  void _setIsCompiled(String fileId, bool compiled) {
    final files = _currentConfigState.compiledFiles;

    if (compiled) {
      files.add(fileId);
    } else {
      files.remove(fileId);
    }
  }

  /// The currently used configuration state.
  ///
  /// Will be updated when synced with a different configuration.
  ConfigState get _currentConfigState =>
      _state.configs.singleWhere((conf) => conf.checksum == _config!.hash);

  /// A list of all project files as `SourceFile`s.
  Future<List<SourceFile>> get _allSourceFiles async {
    final storageDir = Directory(join(_workingDirectory.path, 'src'));
    return await Future.wait(_state.files.map(
      (file) => file.toSourceFile(storageDir),
    ));
  }
}
