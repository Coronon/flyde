import 'dart:isolate';

import 'package:flyde/core/async/connect.dart';
import 'package:flyde/core/async/interface.dart';
import 'package:flyde/core/fs/configs/compiler_config.dart';
import 'package:flyde/core/fs/wrapper/source_file.dart';
import 'package:flyde/core/networking/protocol/compile_status.dart';
import 'package:flyde/features/build_server/cache/project_cache.dart';

import 'compiler.dart';

/// List of constant message ids to be used in inter-isolate communication.
class _MessageIdentifiers {
  static const init = 'init';
  static const build = 'build';
  static const update = 'update';
  static const sync = 'sync';
  static const stateUpdate = 'stateUpdate';
  static const hasCapacity = 'hasCapacity';
}

/// Interface for the compiler running in a seperate [Isolate].
class _WorkerInterface extends Interface with CompilerStatusDelegate {
  // ignore: unused_field
  static _WorkerInterface? _instance;

  /// Flag to store if the worker needs to be ininitalized.
  bool _requiresInit = true;

  /// `true` if the worker can accept a new build request.
  bool _hasCapacity = true;

  /// The internal `Compiler` instance.
  late Compiler _compiler;

  _WorkerInterface(SpawnedIsolate isolate) : super(isolate);

  /// Starts a new worker or throws an error if already running.
  static void start(SendPort sendPort, ReceivePort receivePort) {
    if (_instance != null) {
      throw StateError('A worker instance is already running in this isolate.');
    }

    _instance = _WorkerInterface(
      SpawnedIsolate(Isolate.current, receivePort)..sendPort = sendPort,
    );
  }

  @override
  Future<void> onMessage(InterfaceMessage message) async {
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
    }

    //! Do not answer requests if the worker is not initialized.
    if (_requiresInit) {
      return;
    }

    //* Respond to capacity requests.
    if (message.name == _MessageIdentifiers.hasCapacity) {
      final response = InterfaceMessage(message.name, _hasCapacity);

      response.send(isolate.sendPort, isResponse: true);
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

      final response = InterfaceMessage(message.name, await _compiler.outdatedFiles);
      response.send(isolate.sendPort, isResponse: true);
    }

    //* Handle file update requests.
    if (message.name == _MessageIdentifiers.update && message.args is SourceFile) {
      final file = message.args as SourceFile;

      _compiler.insert(file);
    }

    //* Handle file build requests.
    if (message.name == _MessageIdentifiers.build) {
      await build();
    }
  }

  /// Builds the project.
  ///
  /// If the compilation fails an error message will be sent to the [MainInterface].
  Future<void> build() async {
    _hasCapacity = false;

    try {
      await _compiler.compile();
    } catch (e) {
      await call(
        InterfaceMessage(
          _MessageIdentifiers.stateUpdate,
          CompileStatusMessage(
            status: CompileStatus.failed,
            payload: e.toString(),
          ),
        ),
      );
    }

    _hasCapacity = true;
  }

  /// Sends an state update [message] to the [MainInterface].
  Future<void> updateState(CompileStatusMessage message) async =>
      await call(InterfaceMessage(_MessageIdentifiers.stateUpdate, message));

  //* Delegate Implementation

  @override
  void didStartCompilation() {
    updateState(CompileStatusMessage(
      status: CompileStatus.compiling,
      payload: 0.0,
    ));
  }

  @override
  void isCompiling(double progress) {
    updateState(CompileStatusMessage(
      status: CompileStatus.compiling,
      payload: progress,
    ));
  }

  @override
  void didFinishCompilation() {
    updateState(CompileStatusMessage(
      status: CompileStatus.waiting,
      payload: WaitReason.awaitingNextPhase,
    ));
  }

  @override
  void didStartLinking() {
    updateState(CompileStatusMessage(
      status: CompileStatus.linking,
      payload: null,
    ));
  }

  @override
  void didFinishLinking() {
    updateState(CompileStatusMessage(
      status: CompileStatus.waiting,
      payload: WaitReason.finishing,
    ));
  }

  @override
  void done() {
    updateState(CompileStatusMessage(
      status: CompileStatus.done,
      payload: null,
    ));
  }
}

/// The interface to an isolate which manages a single project.
class MainInterface extends Interface {
  /// Callback to be used when the compilation state updates.
  void Function(CompileStatusMessage)? onStateUpdate;

  MainInterface._(SpawnedIsolate isolate) : super(isolate);

  /// Launches the [MainInterface] by spawning a worker isolate and setting up the connection.
  static Future<MainInterface> launch() async {
    return MainInterface._(
      await connect(ReceivePort(), _WorkerInterface.start),
    );
  }

  @override
  Future<void> onMessage(InterfaceMessage message) async {
    if (message.name == _MessageIdentifiers.stateUpdate && message.args is CompileStatusMessage) {
      onStateUpdate?.call(message.args as CompileStatusMessage);
    }
  }

  /// `true` when the worker can handle a build request.
  Future<bool> hasCapacity() async => await expectResponse(
        InterfaceMessage(_MessageIdentifiers.hasCapacity, null),
        typeError: '"${_MessageIdentifiers.hasCapacity}" expects a boolean response.',
      );

  /// Initializes the worker with the given [config], [files] and [cache].
  Future<void> init(
    Map<String, String> files,
    CompilerConfig config,
    ProjectCache? cache,
  ) async =>
      await call(InterfaceMessage(_MessageIdentifiers.init, [files, config, cache]));

  /// Updates the project with the given [config] and [files].
  Future<List<String>> sync(
    Map<String, String> files,
    CompilerConfig config,
  ) async =>
      await expectResponse(InterfaceMessage(_MessageIdentifiers.sync, [files, config]));

  Future<void> update(SourceFile file) async =>
      await call(InterfaceMessage(_MessageIdentifiers.update, file));

  Future<void> build() async => await call(InterfaceMessage(_MessageIdentifiers.build, null));
}
