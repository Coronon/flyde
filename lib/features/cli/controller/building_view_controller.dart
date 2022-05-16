import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';

import '../../../core/async/event_synchronizer.dart';
import '../../../core/console/terminal_color.dart';
import '../../../core/fs/configs/compiler_config.dart';
import '../../../core/fs/configs/project_config.dart';
import '../../../core/fs/wrapper/source_file.dart';
import '../../../core/fs/yaml.dart';
import '../../../core/logs/logger.dart';
import '../../../core/networking/protocol/build_status.dart';
import '../../../core/networking/protocol/process_completion.dart';
import '../../../core/networking/protocol/project_build.dart';
import '../../../core/networking/protocol/project_init.dart';
import '../../../core/networking/protocol/project_update.dart';
import '../../../core/networking/websockets/session.dart';
import '../files/create_file_map.dart';
import '../files/load_project_config.dart';
import '../files/load_project_files.dart';
import '../networking/create_client_session.dart';
import '../networking/download_binary.dart';
import '../networking/download_logs.dart';
import '../networking/sync_session.dart';
import '../views/building_view.dart';
import '../../ui/render/widget.dart';
import 'view_controller.dart';

/// The [ViewController] for the view shown when building a project.
class BuildingViewController extends ViewController {
  //* Model State

  /// The [ProjectConfig] for the project.
  late ProjectConfig _projectConfig;

  /// The [CompilerConfig] for the project.
  late CompilerConfig _buildConfig;

  /// The [EventSynchronizer] for the underlying [ClientSession].
  late EventSynchronizer _session;

  /// The [SourceFile]s of the project.
  late List<SourceFile> _files;

  /// A mapping for the ids and their hashes of the [SourceFile]s.
  late Map<String, String> _fileMap;

  /// The underlying [ClientSession].
  ///
  /// Do not use this directly. Use [_session] instead.
  late ClientSession _clientSession;

  /// The [Timer] used to display the elapsed time of the build.
  late Timer _timer;

  /// A [Stopwatch] for counting the elapsed time of the build.
  final Stopwatch _stopwatch = Stopwatch();

  //* Args

  /// The path of the build config
  final String _buildConfigPath;

  /// The format in which the logs should be stored
  final LogFormat _logFormat;

  //* View State

  /// The text displayed as the build status.
  final State<String> _label = State('Preparing build...');

  /// The color of the label.
  final State<TerminalColor> _color = State(TerminalColor.none);

  /// The current progress of the build.
  final State<double> _progress = State(0);

  /// The text displayed to show the files which had to be recompiled.
  final State<String> _filesToUpdate = State('-');

  /// The text displayed to show the elpased time of the build.
  final State<String> _elapsedTime = State('-');

  BuildingViewController(this._buildConfigPath, this._logFormat) {
    addTask('Could not set-up tools', _startStopwatch);
    addTask('Could not load project configuration', _loadProject);
    addTask('Could not load compiler configuration', _loadBuildConfig);
    addTask('Could not connect to build server', _createSession);
    addTask('Could not read source files', _readFiles);
    addTask('Could not establish build session', _waitForAuth);
    addTask('Could not synchronize files', _syncFiles);
    addTask('Could not build source files', _build);
    addTask('Could not download logs', _downloadLogs);
    addTask('Could not download binary', _downloadBinary);
    addTask('Could not stop tools', _stopStopwatch);
    addTask('Could not tear down', _tearDown);

    showView(
      buildingView(
        _filesToUpdate,
        _progress,
        _label,
        _color,
        _elapsedTime,
      ),
    );
  }

  @override
  FutureOr<void> fail(String message) async {
    _label.value = 'Compilation failed. $message.';
    _progress.value = 1;
    _color.value = TerminalColor.red;

    try {
      await _downloadLogs();
    } catch (_) {}

    try {
      await _tearDown();
    } catch (_) {}

    await _stopStopwatch();
  }

  //* Tasks

  /// Starts the [_stopwatch] and inits the a [_timer] to update
  /// the GUI state every 100ms.
  Future<void> _startStopwatch() async {
    _stopwatch.stop();
    _stopwatch.reset();
    _stopwatch.start();

    _timer = Timer.periodic(Duration(milliseconds: 100), (_) {
      _elapsedTime.value = _stopwatch.elapsed.toString().split('.').first;
    });
  }

  /// Stops the [_stopwatch] and [_timer].
  Future<void> _stopStopwatch() async {
    _stopwatch.stop();
    _timer.cancel();
  }

  /// Loads the [_projectConfig]
  Future<void> _loadProject() async {
    _label.value = 'Loading project configuration...';
    _projectConfig = await loadProjectConfig();
  }

  /// Loads the [_buildConfig]
  Future<void> _loadBuildConfig() async {
    _label.value = 'Loading build configuration...';

    final Map<String, dynamic> yaml = loadYamlAsMap(
      await File(_buildConfigPath).readAsString(),
    );

    _buildConfig = CompilerConfig.fromJson(yaml);
  }

  /// Creates a [_clientSession] and syncs it with [_session].
  Future<void> _createSession() async {
    _label.value = 'Connecting to build server...';

    _clientSession = await createClientSession(
      _projectConfig.server,
      _projectConfig.port,
    );

    _session = syncSession(
      _clientSession,
      (dynamic msg) {
        if (msg is! BuildStatusMessage) {
          return;
        }

        if (msg.status == BuildStatus.compiling) {
          _label.value = 'Compiling...';
          _color.value = TerminalColor.yellow;
          _progress.value = 0.8 * msg.payload;
        } else if (msg.status == BuildStatus.failed) {
          _label.value = 'Compilation failed.';
          _color.value = TerminalColor.red;
          _progress.value = 1;
        } else if (msg.status == BuildStatus.linking) {
          _label.value = 'Linking...';
          _color.value = TerminalColor.blue;
          _progress.value = 0.8;
        } else if (msg.status == BuildStatus.waiting) {
          _label.value = 'Waiting...';
          _color.value = TerminalColor.magenta;
        } else if (msg.status == BuildStatus.done) {
          _label.value = 'Success';
          _color.value = TerminalColor.green;
          _progress.value = 1;
        }
      },
    );
  }

  /// Reads the [_files] from the file system and maps them.
  Future<void> _readFiles() async {
    _label.value = 'Reading source files...';
    _files = await loadProjectFiles(_buildConfig);
    _fileMap = await createFileMap(_files);
  }

  /// Waits for the [_session] to be authenticated and being
  /// authorized to perform a build task.
  Future<void> _waitForAuth() async {
    _label.value = 'Waiting for server authentication...';

    // Request project initialization and expect verification
    await _session.request(ProjectInitRequest(id: _projectConfig.name, name: _projectConfig.name));
    await _session.expect(
      ProcessCompletionMessage,
      validator: (ProcessCompletionMessage msg) => msg.process == CompletableProcess.projectInit,
    );

    // Request the permission to use the compiler
    await _session.request(reserveBuildRequest);

    // Wait until permission is granted
    await _session.expect(
      String,
      validator: (String resp) => resp == isActiveSessionResponse,
      keepAlive: true,
    );
  }

  /// Syncs the [_files] with the [_session].
  ///
  /// This tasks send all [_files] to the server which are not already cached.
  /// Can take some  time when the cache is empty.
  Future<void> _syncFiles() async {
    _label.value = 'Synchronizing source files...';

    // Sync the project with the compiler
    await _session.request(ProjectUpdateRequest(config: _buildConfig, files: _fileMap));

    // Expect a response which contains the ids of all files which
    // need to be sent to the compiler
    final List<String> fileIds = await _session.expect(
      ProjectUpdateResponse,
      handler: (ProjectUpdateResponse resp) => resp.files,
    );

    _filesToUpdate.value = '${fileIds.length}';

    // Exchange the requested files with the compiler.
    // Expect a `ProcessCompletionMessage` after each file has been sent.
    await _session
        .exchange(
          Stream.fromFutures(
            fileIds
                .map((id) => _files.singleWhere((f) => f.id == id))
                .map((f) => FileUpdate.fromSourceFile(f)),
          ),
          ProcessCompletionMessage,
          validator: (FileUpdate update, ProcessCompletionMessage comp) =>
              comp.process == CompletableProcess.fileUpdate,
        )
        .drain();
  }

  /// Waits for the build server to complete the compilation.
  /// Throws a [StateError] when the compiler could not build
  /// the project.
  Future<void> _build() async {
    bool didFail = false;

    // Request to build the newly synced project.
    await _session.request(projectBuildRequest);

    // Expect state updates and wait until compilation is done.
    await _session.expect(
      BuildStatusMessage,
      validator: (BuildStatusMessage msg) {
        if (msg.status == BuildStatus.done) {
          return true;
        }

        if (msg.status == BuildStatus.failed) {
          didFail = true;
          return true;
        }

        return false;
      },
      keepAlive: true,
    );

    if (didFail) {
      throw StateError('Source files could not be compiled.');
    }
  }

  /// Downalods the binary and writes it to [_binaryPath].
  Future<void> _downloadBinary() async {
    await downloadBinary(_session, File(_buildConfig.binaryPath));
  }

  /// Downalods the logs and writes them to the path provided by [_buildConfig].
  Future<void> _downloadLogs() async {
    final int dotIndex = _buildConfigPath.indexOf('.');
    final String time = DateTime.now().toIso8601String();
    final String configName = _buildConfigPath.substring(
      0,
      dotIndex > 0 ? dotIndex : _buildConfigPath.length,
    );

    final String name = '$configName-$time';
    final Directory dirPath = Directory(_buildConfig.logDirectory);
    final String fileName = join(dirPath.path, name);

    await downloadLogs(_session, File(fileName), format: _logFormat);
  }

  /// Closes the [_session] and [_clientSession].
  Future<void> _tearDown() async {
    // Unsubscribe from the compiler to allow other clients
    // to access the same project
    await _clientSession.send(unsubscribeRequest);
    await _clientSession.close();
  }
}
