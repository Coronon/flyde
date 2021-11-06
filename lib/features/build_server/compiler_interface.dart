import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../core/async/connect.dart';
import '../../core/async/interface.dart';
import '../../core/fs/configs/compiler_config.dart';
import '../../core/fs/wrapper/source_file.dart';
import '../../core/networking/protocol/compile_status.dart';
import 'cache/project_cache.dart';
import 'compiler.dart';

/// List of constant message ids to be used in inter-isolate communication.
class _MessageIdentifiers {
  static const init = 'init';
  static const build = 'build';
  static const update = 'update';
  static const sync = 'sync';
  static const stateUpdate = 'stateUpdate';
  static const hasCapacity = 'hasCapacity';
  static const getBinary = 'getBinary';
}

/// Interface for the compiler running in a seperate [Isolate].
@visibleForTesting
class WorkerInterface extends Interface with CompilerStatusDelegate {
  /// Singleton instance to keep the [WorkerInterface] alive.
  @visibleForTesting
  static WorkerInterface? instance;

  /// Flag to store if the worker needs to be ininitalized.
  bool _requiresInit = true;

  /// `true` if the worker can accept a new build request.
  bool _hasCapacity = true;

  /// The internal `Compiler` instance.
  late Compiler _compiler;

  @visibleForTesting
  WorkerInterface(SpawnedIsolate isolate) : super(isolate);

  /// Starts a new worker or throws an error if already running.
  @visibleForTesting
  static void start(SendPort sendPort, ReceivePort receivePort) {
    if (instance != null) {
      throw StateError('A worker instance is already running in this isolate.');
    }

    instance = WorkerInterface(
      SpawnedIsolate(Isolate.current, receivePort)..sendPort = sendPort,
    )..ready.complete();
  }

  @visibleForTesting
  @override
  void onMessage(InterfaceMessage message) async {
    //* Respond to init requests.
    if (message.name == _MessageIdentifiers.init &&
        _requiresInit &&
        message.args is List<dynamic>) {
      final args = message.args as List<dynamic>;
      final files = args[0] as Map<String, String>;
      final config = args[1] as CompilerConfig;
      final cache = args[2] as ProjectCache;

      _compiler = Compiler(config, files, cache);
      _compiler.delegate = this;
      _requiresInit = false;
      message.respond(isolate.sendPort, null);
    }

    //! Do not answer requests if the worker is not initialized.
    if (_requiresInit) {
      return;
    }

    //* Respond to capacity requests.
    if (message.name == _MessageIdentifiers.hasCapacity) {
      message.respond(isolate.sendPort, _hasCapacity);
    }

    //! Do not handle build requests if the worker is bussy.
    if (!_hasCapacity) {
      return;
    }

    //* Respond to sync requests.
    if (message.name == _MessageIdentifiers.sync && message.args is List<dynamic>) {
      final args = message.args as List<dynamic>;
      final files = args[0] as Map<String, String>;
      final config = args[1] as CompilerConfig;

      _compiler.update(config, files);
      message.respond(isolate.sendPort, await _compiler.outdatedFiles);
    }

    //* Handle file update requests.
    if (message.name == _MessageIdentifiers.update && message.args is SourceFile) {
      final file = message.args as SourceFile;

      await _compiler.insert(file);
      message.respond(isolate.sendPort, null);
    }

    //* Handle file build requests.
    if (message.name == _MessageIdentifiers.build) {
      await _build();
    }

    //* Handle binary requests.
    if (message.name == _MessageIdentifiers.getBinary) {
      final File? bin = await _compiler.lastExecutable;
      final Uint8List? data = await bin?.readAsBytes();

      message.respond(isolate.sendPort, data);
    }
  }

  /// Builds the project.
  ///
  /// If the compilation fails an error message will be sent to the [ProjectInterface].
  Future<void> _build() async {
    _hasCapacity = false;

    try {
      await _compiler.compile();
    } catch (e) {
      await _updateState(CompileStatusMessage(
        status: CompileStatus.failed,
        payload: e.toString(),
      ));
    }

    _hasCapacity = true;
  }

  /// Sends an state update [message] to the [ProjectInterface].
  Future<void> _updateState(CompileStatusMessage message) async =>
      await call(InterfaceMessage(_MessageIdentifiers.stateUpdate, message));

  //* Delegate Implementation

  @override
  void didStartCompilation() {
    _updateState(CompileStatusMessage(
      status: CompileStatus.compiling,
      payload: 0.0,
    ));
  }

  @override
  void isCompiling(double progress) {
    _updateState(CompileStatusMessage(
      status: CompileStatus.compiling,
      payload: progress,
    ));
  }

  @override
  void didFinishCompilation() {
    _updateState(CompileStatusMessage(
      status: CompileStatus.compiling,
      payload: 1.0,
    ));
  }

  @override
  void didStartLinking() {
    _updateState(CompileStatusMessage(
      status: CompileStatus.linking,
      payload: null,
    ));
  }

  @override
  void didFinishLinking() {
    _updateState(CompileStatusMessage(
      status: CompileStatus.waiting,
      payload: WaitReason.finishing,
    ));
  }

  @override
  void done() {
    _updateState(CompileStatusMessage(
      status: CompileStatus.done,
      payload: null,
    ));
  }
}

/// The interface to an isolate which manages a single project.
class ProjectInterface extends Interface {
  /// Callback to be used when the compilation state updates.
  void Function(CompileStatusMessage)? onStateUpdate;

  /// Constrcutor which should not be called unless for testing.
  /// Use [launch] to start the main interface.
  /// Otherwise the corresponding worker interface will not be invoked
  /// automatically.
  @visibleForTesting
  ProjectInterface(SpawnedIsolate isolate) : super(isolate);

  /// Launches the [ProjectInterface] by spawning a worker isolate and setting up the connection.
  static Future<ProjectInterface> launch() async {
    return ProjectInterface(
      await connect(ReceivePort(), WorkerInterface.start),
    );
  }

  @override
  void onMessage(InterfaceMessage message) async {
    if (message.name == _MessageIdentifiers.stateUpdate && message.args is CompileStatusMessage) {
      onStateUpdate?.call(message.args as CompileStatusMessage);
    }
  }

  /// `true` when the worker can handle a build request.
  Future<bool> hasCapacity() async => await expectResponse(
        InterfaceMessage(_MessageIdentifiers.hasCapacity, null),
        typeError: '"${_MessageIdentifiers.hasCapacity}" expects a boolean response.',
        timeout: Duration(seconds: 2),
      );

  /// Initializes the worker with the given [config], [files] and [cache].
  Future<void> init(
    Map<String, String> files,
    CompilerConfig config,
    ProjectCache? cache,
  ) async =>
      await expectResponse(
        InterfaceMessage(_MessageIdentifiers.init, [files, config, cache]),
        timeout: Duration(seconds: 10),
      );

  /// Updates the project with the given [config] and [files].
  Future<List<String>> sync(
    Map<String, String> files,
    CompilerConfig config,
  ) async =>
      await expectResponse(
        InterfaceMessage(_MessageIdentifiers.sync, [files, config]),
        timeout: Duration(seconds: 10),
      );

  /// Updates the project with the given [file].
  Future<void> update(SourceFile file) async => await expectResponse(
        InterfaceMessage(_MessageIdentifiers.update, await file.asMemoryData()),
        timeout: Duration(seconds: 10),
      );

  /// Builds the project.
  ///
  /// Use [onStateUpdate] to get the compilation state.
  Future<void> build() async => await call(InterfaceMessage(_MessageIdentifiers.build, null));

  /// The latest available binary for the project.
  Future<Uint8List?> get binary async {
    return await expectResponse(
      InterfaceMessage(
        _MessageIdentifiers.getBinary,
        null,
      ),
      timeout: Duration(seconds: 10),
    );
  }
}
