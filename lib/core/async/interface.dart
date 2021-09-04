import 'dart:async';
import 'dart:isolate';

import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

import 'connect.dart';

/// Message object to be exchanged between two [Isolate]s.
class InterfaceMessage {
  /// The name of the message.
  ///
  /// Required to be identifiable and able to send responses.
  String name;

  /// The payload of the message.
  Object? args;

  /// Unique id of this message and it's response.
  late final String _id;

  /// Flag which indicates if this message is a response.
  bool _isResponse;

  InterfaceMessage(this.name, this.args, [this._isResponse = false, String? id]) {
    _id = id ?? Uuid().v4();
  }

  /// Attempts to cast received data to an [InterfaceMessage].
  static InterfaceMessage? from(dynamic message) {
    if (message is InterfaceMessage) {
      return message;
    }

    return null;
  }

  /// Sends the message through the [port].
  void send(SendPort port, {bool isResponse = false}) => port.send(this.._isResponse = isResponse);

  /// Sends a response to this message with given [args].
  void respond(SendPort port, Object? args) =>
      InterfaceMessage(name, args, true, _id).send(port, isResponse: true);

  /// Checks if the received data is a response to this [InterfaceMessage].
  InterfaceMessage? _match(dynamic message) {
    final response = InterfaceMessage.from(message);

    if (response != null && response._isResponse && response._id == _id) {
      return response;
    }

    return null;
  }
}

typedef _Expectation = Tuple2<InterfaceMessage, void Function(InterfaceMessage)>;

/// Interface for two-way inter-isolate communication.
abstract class Interface {
  /// The isolate this [Interface] is running in with
  /// ports to the partner isolate.
  SpawnedIsolate isolate;

  /// Completes when the send port is connected.
  ///
  /// [ready] is set when a sent port is received on the receive port.
  /// When setting the send port manually, ensure to `complete` [ready].
  final Completer<void> ready = Completer();

  /// A list of expected [InterfaceMessage]s and a callback to be executed
  /// when the message is received.
  final List<_Expectation> _expectations = [];

  Interface(this.isolate) {
    // Sole listener on the receive port.
    //? If another listener is attached a runtime error will occure.
    isolate.receivePort.listen((dynamic message) {
      //* Store `SendPort`s when received.
      if (message is SendPort) {
        if (!ready.isCompleted) {
          isolate.sendPort = message;
          ready.complete();
        }
        return;
      }

      //* Check if the received message is a response to an expected message.
      for (final expectation in _expectations) {
        final InterfaceMessage? response = expectation.item1._match(message);

        if (response != null) {
          expectation.item2.call(response);
          _expectations.removeWhere((exepc) => exepc.item1._id == message._id);
          return;
        }
      }

      //* If the message is not a response, it is a request.
      final request = InterfaceMessage.from(message);

      if (request != null) {
        onMessage(request);
      }
    });
  }

  /// Sends the [message] and returns the response if [expectResponse] is `true`.
  Future<InterfaceMessage?> call(
    InterfaceMessage message, {
    bool expectResponse = false,
    Duration? timeout,
  }) async {
    await ready.future;

    message.send(isolate.sendPort);

    if (!expectResponse) {
      return null;
    }

    final completer = Completer<InterfaceMessage>();

    if (timeout != null) {
      Future.delayed(timeout).then(
        (dynamic val) {
          if (!completer.isCompleted) {
            _expectations.removeWhere((exepc) => exepc.item1._id == message._id);
            completer.completeError(
              StateError(
                'Request "${message.name}" {id: ${message._id}} timed out after ${timeout.toString()}',
              ),
            );
          }
        },
      );
    }

    _expectations.add(Tuple2(message, completer.complete));

    return completer.future;
  }

  /// Handler which is called on every message which is not a response.
  void onMessage(InterfaceMessage message);

  /// Handler which can be used to await the response to [request].
  ///
  /// A custom [typeError] can be provided which will be used if the response has a different type than expected.
  /// If not set, a more generic message will be used.
  Future<T> expectResponse<T>(
    InterfaceMessage request, {
    String? typeError,
    Duration? timeout,
  }) async {
    final InterfaceMessage? response = await call(request, expectResponse: true, timeout: timeout);

    if (response!.args is T) {
      return response.args as T;
    }

    throw InvalidMessageException(
      response,
      typeError ?? '"${request.name}" expects a response with different args.',
    );
  }
}

/// An exception to be thrown if a received message does not match the expectations.
class InvalidMessageException implements Exception {
  /// The faulty message.
  InterfaceMessage receivedMessage;

  /// Reason of termination.
  String description;

  InvalidMessageException(this.receivedMessage, this.description);
}
