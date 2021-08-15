import 'dart:async';
import 'dart:isolate';

import 'package:flyde/core/async/connect.dart';
import 'package:tuple/tuple.dart';

/// Message object to be exchanged between two [Isolate]s.
class InterfaceMessage {
  /// The name of the message.
  ///
  /// Required to identifiable and to be able to send responses.
  String name;

  /// The payload of the message.
  Object? args;

  InterfaceMessage(this.name, this.args);

  /// Creates a [InterfaceMessage] from the received data.
  static InterfaceMessage? from(dynamic message) {
    if (message is List<dynamic> && message.length == 2) {
      final dynamic name = message[0];
      final dynamic args = message[1];

      if (name is String) {
        return InterfaceMessage(name, args);
      }
    }

    return null;
  }

  /// Sends the message through the [port].
  void send(SendPort port, {bool isResponse = false}) {
    port.send([isResponse ? _responseName : name, args]);
  }

  /// The identifier of the message if it is an awaited response.
  String get _responseName => '$name-response';

  /// Checks if the received data is a response to this [InterfaceMessage].
  InterfaceMessage? _match(dynamic message) {
    final response = InterfaceMessage.from(message);

    if (response != null && response.name == _responseName) {
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

  /// A list of expected [InterfaceMessage]s and a callback when the message is received.
  final List<_Expectation> _expectations = [];

  Interface(this.isolate) {
    // Sole listener to the receive port.
    //? If another listener is attached a runtime error will occure.
    isolate.receivePort.listen((dynamic message) {
      //* Store `SendPort`s when received.
      if (message is SendPort) {
        isolate.sendPort = message;
        return;
      }

      //* Check if the received message is a response to an expected message.
      for (final expectation in _expectations) {
        final InterfaceMessage? response = expectation.item1._match(message);

        if (response != null) {
          expectation.item2.call(response);
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
  Future<InterfaceMessage?> call(InterfaceMessage message, {bool expectResponse = false}) async {
    message.send(isolate.sendPort);

    if (!expectResponse) {
      return null;
    }

    final completer = Completer<InterfaceMessage>();

    _expectations.add(Tuple2(message, completer.complete));

    return completer.future;
  }

  /// Handler which is called on every message which is not a response.
  Future<void> onMessage(InterfaceMessage message);

  /// Handler which can be used to await the response to [request].
  ///
  /// A custom [typeError] can be provided which will be used if the response has a different type than expected.
  /// If not set, a more generic message will be used.
  Future<T> expectResponse<T>(InterfaceMessage request, {String? typeError}) async {
    final InterfaceMessage? response = await call(request, expectResponse: true);

    if (response!.args is T) {
      return response.args as T;
    }

    throw InvalidMessageError(
      response,
      typeError ?? '"${request.name}" expects a response with different args.',
    );
  }
}

/// An error to be thrown if a received message does not match the expectations.
class InvalidMessageError extends Error {
  /// The faulty message.
  InterfaceMessage receivedMessage;

  /// Reason of termination.
  String description;

  InvalidMessageError(this.receivedMessage, this.description);
}
