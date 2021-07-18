import 'dart:convert';
import 'dart:io';

import 'package:flyde/core/fs/configs/compiler_config.dart';
import 'package:flyde/core/fs/file_extension.dart';
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
  final String _projectId;

  late final Directory _workingDirectory;

  late final ProjectCacheState _state;

  CompilerConfig? _config;

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
    _state.configs.add(ConfigState(checksum: config.hash, compiledFiles: {}));

    final required = <String>[];
    final inSync = <String>[];

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
      } else {
        inSync.add(id);
      }
    }

    return required;
  }

  /// Persists the passed [file].
  Future<void> insert(SourceFile file) async {
    final path = joinAll([
      _workingDirectory.path,
      'src',
      file.entry.toString(),
      ...file.path,
      '${file.name}.${file.extension}'
    ]);
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
  Future<List<ImplementationObjectRef>> get sourceFiles async {
    final refs = <ImplementationObjectRef>[];

    for (final file in _state.files) {
      if (_isCompiled(file.id)) {
        continue;
      }

      final ext = extension(file.path);

      if (FileExtension.sources.contains(ext)) {
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

  File get _stateFile => File(join(_workingDirectory.path, '.state.json'));

  bool _isCompiled(String fileId) {
    return _currentConfigState.compiledFiles.contains(fileId);
  }

  void _setIsCompiled(String fileId, bool compiled) {
    final files = _currentConfigState.compiledFiles;

    if (compiled) {
      files.add(fileId);
    } else {
      files.remove(fileId);
    }
  }

  ConfigState get _currentConfigState =>
      _state.configs.singleWhere((conf) => conf.checksum == _config!.hash);
}
