import 'dart:async';

import 'package:uuid/uuid.dart';

/// A function which dispatches messages over I/O ports.
typedef Sender = Future<void> Function(dynamic);

/// A subscriber is a function that receives messages from [handleMessage] and acts on them.
///
/// A subscriber is short lived and is killed after the first call.
/// When the subscriber returns `true`, it's kept alive and will be called on upcoming messages until
/// it returns `null` or `false`.
typedef _Subscriber = Future<bool?> Function(dynamic);

/// A class which helps managing asynchronuous, callback-based communnication.
///
/// [EventSynchronizer] allows to request, expect and exchange messages between two independent
/// endpoints, e.g. web sockets, isolates, ...
///
/// ```dart
/// // Some I/O client which sends and receives messages.
/// final client = IOCLient()
///
/// // The synchronizer is initialized with the send function of the client.
/// final synchronizer = EventSynchronizer(client.send);
///
/// // We need to pass each message from the client to the synchronizer.
/// client.onMessage = synchronizer.handleMessage;
///
/// // Simple messages are sent using the request function.
/// await synchronizer.request('ANYTHING');
///
/// // We can receive the String response directly but have to explicitly type the response.
/// final String response = await synchronizer.expect(String);
///
/// // If we are waiting for a specific response and can ignore other messages, we can use keepAlive.
/// // It will wait with completion until we receive "THAT'S IT".
/// // The return value in this case is "THAT'S IT".
/// await synchronizer.expect(String, validator: (String resp) => resp == "THAT'S IT", keepAlive: true);
///
/// // Using exchange, we can realize a ping-pong communication.
/// // Use drain to await the stream completion.
/// synchronizer.exchange(someStream, String).listen((String resp) {
///  print(resp);
/// });
/// ```
class EventSynchronizer {
  /// The sener function used to dispatch messages.
  final Sender _sender;

  /// A map of message subscriptions identified by a random UUID.
  final Map<String, _Subscriber> _subscriptions = {};

  /// UUID generator.
  final _uuid = Uuid();

  /// A time offset required if the I/O responses might be faster than the code which attaches
  /// a listener ([expect]) for them.
  ///
  /// The duration is a minimum time which is required for each [handleMessage] call.
  /// Use with caution!
  final Duration messageOffset;

  EventSynchronizer(this._sender, [this.messageOffset = Duration.zero]);

  /// Message handler which should be called for each incoming [message] without pre-filtering.
  Future<void> handleMessage(dynamic message) async {
    await Future.delayed(messageOffset);

    List<String> toKeep = [];

    for (final entry in _subscriptions.entries) {
      final id = entry.key;
      final subscription = entry.value;

      if (await subscription(message) == true) {
        toKeep.add(id);
      }
    }

    _subscriptions.removeWhere((key, value) => !toKeep.contains(key));
  }

  /// Sends a [message] using the [_sender] function.
  ///
  /// If [message] is a [Stream] each item will be sent seperately.
  Future<void> request(dynamic message) async {
    if (message is Stream) {
      await for (final item in message) {
        await _sender(item);
      }
    } else {
      await _sender(message);
    }
  }

  /// Waits for an incoming message of type [responseType] and transforms it using
  /// [handler]. If [validator] returns `false` the returned [Future] completes with an error.
  ///
  /// If the incoming message has not the expected type an [ArgumenError] will be thrown.
  /// Use [keepAlive] to call [handler] and [validator] on every incoming message until [validator] returns `true`.
  Future<R> expect<T, R>(
    Type responseType, {
    R Function(T)? handler,
    bool Function(T)? validator,
    bool keepAlive = false,
  }) async {
    final String id = _uuid.v4();
    final completer = Completer<R>();

    _subscriptions[id] = (dynamic message) async {
      if (message.runtimeType == responseType) {
        final isValid = validator?.call(message) ?? true;

        if (!isValid && keepAlive) {
          return true;
        }

        if (!isValid) {
          completer.completeError(ArgumentError('Message is invalid'));
        } else {
          if (handler != null) {
            completer.complete(handler(message));
          } else {
            completer.complete(message);
          }
        }
      } else {
        completer.completeError(ArgumentError(
          'Expected type was $responseType. Received ${message.runtimeType}',
        ));
      }
    };

    return await completer.future;
  }

  /// Exchanges the [items] stream by sending each item and waiting for a response
  /// of type [responseType] before sending the next one.
  ///
  /// The returned value is itself a [Stream] which will emit the results of [handler]
  /// on each response. If [handler] is ommited the received items will be emited as is.
  ///
  /// If [validator] fails on any of the received items the whole function will fail.
  Stream<R> exchange<T, U, R>(
    Stream<T> items,
    Type responseType, {
    R Function(T, U)? handler,
    bool Function(T, U)? validator,
  }) async* {
    await for (final item in items) {
      final wrappedValidator = validator == null ? null : (U res) => validator(item, res);
      final wrappedHandler = handler == null ? null : (U res) => handler(item, res);

      await request(item);

      yield await expect(
        responseType,
        handler: wrappedHandler,
        validator: wrappedValidator,
      );
    }
  }
}
