import 'dart:async';

import 'package:meta/meta.dart';

import '../../ui/render/scene.dart';
import '../../ui/render/widget.dart';

/// A task executed by the [ViewController].
class _ControllerTask {
  /// A message shown when the task fails
  String failureMessage;

  /// An action which should update the view's state
  Future<void> Function() action;

  _ControllerTask(this.failureMessage, this.action);
}

/// A controller used to manage the lifecycle of a TUI view.
///
/// A CLI view has unlike to classical views a procedual lifecycle.
/// [ViewController] is used to manage tasks, which are responsible for
/// updating view state and model.
abstract class ViewController {
  /// Tasks that are executed when [executeTasks] is called.
  final List<_ControllerTask> _tasks = [];

  /// The scene which is to be shown until the [_tasks] are executed.
  late Scene _scene;

  /// Initializes the view. Required to be called before [executeTasks].
  @protected
  void showView(List<Widget> widgets) {
    _scene = Scene(widgets);
    _scene.show();
  }

  /// Adds a task to the queue.
  ///
  /// A task consists of an [action], which is responsible for updating the state
  /// of the view. An additional [failureMessage] is used to inform the user
  /// about the possible failure of the task. In this case [fail] will be called
  /// and should be used to show the failure message in the TUI.
  @protected
  void addTask(String failureMessage, Future<void> Function() action) {
    _tasks.add(_ControllerTask(failureMessage, action));
  }

  /// Called in case a tasks fails to execute.
  ///
  /// Use this message to present the [message] and tear down
  /// any resources that are used by the underlying tasks.
  @protected
  FutureOr<void> fail(String message);

  /// Executes all tasks in the queue.
  ///
  /// When execution has finished no more state updates should be performed
  /// and the CLI session should stop.
  Future<void> executeTasks() async {
    for (final task in _tasks) {
      try {
        await task.action();
      } catch (e) {
        fail(task.failureMessage);
        return;
      }
    }
  }
}
