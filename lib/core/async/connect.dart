import 'dart:async';
import 'dart:isolate';

/// A function which is called as the entry point of a new isolate.
typedef SpawnFunc = void Function(SendPort, ReceivePort);

/// Data structure to hold an [Isolate] and
/// it's send and receive ports.
///
/// The ports are either connected to the main [Isolate]
/// or, if the class is used in the main [Isolate], to the
/// spawned child [Isolate]s.
class SpawnedIsolate {
  /// The [Isolate] object.
  final Isolate isolate;

  /// The send port to the parent isolate.
  ///
  /// Should be initialized by user code when
  /// the partner [Isolate] has send the
  /// [SendPort] instance.
  late final SendPort sendPort;

  /// The receive port to the parent isolate.
  final ReceivePort receivePort;

  SpawnedIsolate(this.isolate, this.receivePort);
}

/// Function which should be invoked to spawn the new [Isolate].
///
/// [args] is a list with two elements:
/// - the [SendPort] instance
/// - the [SpawnFunc] which is called as the entry point of the new [Isolate]
void _spawn(List<dynamic> args) {
  if (args[0] is! SendPort || args[1] is! SpawnFunc) {
    throw ArgumentError('Spawning a new isolate requires a [SendPort] and [SpawnFunc] object.');
  }

  final isolateReceive = ReceivePort();
  final sendPort = args[0] as SendPort;
  final spawnFunc = args[1] as SpawnFunc;

  //? Send the SendPort of the spawned isolate to the
  //? main isolate to allow the main isolate to
  //? send messages to the newly spawned isolate.
  //? This way two-way communication is created.
  sendPort.send(isolateReceive.sendPort);

  spawnFunc(sendPort, isolateReceive);
}

/// Function which connects two isolates by their send and receive ports.
///
/// The function spawns a new [Isolate] and returns an object containing the spawned [Isolate]
/// and the receive port. The send port will be transmitted to the receive port and should
/// be stored.
///
/// [spawnFunc] must be a static or top level function.
Future<SpawnedIsolate> connect(ReceivePort mainReceive, SpawnFunc spawnFunc) async {
  final isolate = await Isolate.spawn<List<dynamic>>(
    _spawn,
    [mainReceive.sendPort, spawnFunc],
  );

  return SpawnedIsolate(isolate, mainReceive);
}
