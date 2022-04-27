import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:collection/collection.dart';

import '../list/int_reducer.dart';
import '../list/insert_between.dart';
import '../console/bold.dart';
import 'log_level.dart';
import 'log_scope.dart';

/// A logger is used to manage logging and
/// to display, store or load the logs.
class Logger {
  /// A byte sequence which indicates that a binary buffer contains log data.
  static final Uint8List _magicByte = Uint8List.fromList([0x4c, 0x4f, 0x47, 0x45]);

  /// The in-memory messages
  final List<_LogMessage> _messages;

  /// Default constructor which creates an empty logger.
  Logger() : _messages = [];

  /// Constructor which creates a logger with the given [messages].
  Logger._([this._messages = const []]);

  /// Creates a logger from the given [json].
  ///
  /// Throws an [ArgumentError] if the [json] is not valid.
  static Logger fromJson(dynamic json) {
    if (json is! List<Map<String, dynamic>>) {
      throw ArgumentError('Invalid json format');
    }

    final messages = json.map((m) => _LogMessage.fromJson(m)).toList();

    return Logger._(messages);
  }

  /// Creates a [Logger] with the messages encoded in the given [bytes].
  static Logger fromBytes(Uint8List bytes) {
    final magicByte = bytes.sublist(0, 4);
    final List<_LogMessage> messages = [];
    int sectionStart = 4;

    if (!magicByte.equals(_magicByte)) {
      throw ArgumentError('Invalid binary format');
    }

    while (sectionStart < bytes.length) {
      final len = bytes.getRange(sectionStart, sectionStart + 4).toList().reduceIndexed(intReducer);
      final data = bytes.getRange(sectionStart + 4, sectionStart + 4 + len).toList();

      messages.add(_LogMessage.fromRawData(Uint8List.fromList(data)));
      sectionStart += 4 + len;
    }

    return Logger._(messages);
  }

  /// Removes all messages currently stored in memory.
  void reset() {
    _messages.clear();
  }

  /// Adds the [message] to the logger and combines
  /// it with the meta data consisting of
  /// [level], [scope], [description] and the current time.
  void add(
    String message, {
    LogLevel level = LogLevel.info,
    required LogScope scope,
    String? description,
  }) {
    _messages.add(_LogMessage(message, level, DateTime.now(), scope, description));
  }

  /// Creates a human readable string of all stored messages
  /// which meet the requirements. If [formatForTerminal] is true,
  /// the output is formatted for a terminal.
  @override
  String toString({
    LogScope? scope,
    LogLevel? level,
    DateTime? from,
    DateTime? to,
    bool formatForTerminal = false,
  }) {
    final buffer = StringBuffer();
    final messages = _filter(scope, level, from, to);

    messages
        .map((m) => m.toString(formatForTerminal: formatForTerminal))
        .insertBetween('\n\n')
        .forEach(buffer.write);

    return buffer.toString();
  }

  /// Creates a [Uint8List] which contains all encoded messages,
  /// which meet the requirements.
  Uint8List toBytes({LogScope? scope, LogLevel? level, DateTime? from, DateTime? to}) {
    final builder = BytesBuilder();

    builder.add(_magicByte);

    for (final message in _filter(scope, level, from, to)) {
      final data = message.toRawData();
      final len = data.length;
      final lenBuffer = Uint8List(4)..buffer.asUint32List(0, 1)[0] = len;

      builder.add(lenBuffer);
      builder.add(data);
    }

    return builder.toBytes();
  }

  /// Creates a [List] which contains all json encoded messages,
  /// which meet the requirements.
  List<Map<String, dynamic>> toJson({
    LogScope? scope,
    LogLevel? level,
    DateTime? from,
    DateTime? to,
  }) =>
      _filter(scope, level, from, to).map((m) => m.toJson()).toList();

  /// Returns a [List] of all messages which meet the requirements.
  List<_LogMessage> _filter(LogScope? scope, LogLevel? level, DateTime? from, DateTime? to) {
    return _messages
        .where((m) => m.scope == scope || scope == null)
        .where((m) => m.level == level || level == null)
        .where((m) => m.time.isAfter(from ?? DateTime.fromMillisecondsSinceEpoch(0)))
        .where((m) => m.time.isBefore(to ?? DateTime.now()))
        .toList();
  }
}

/// A log message which combines
/// a message with useful meta data and
/// provides methods for serialization.
class _LogMessage {
  /// The message.
  final String message;

  /// The log level.
  final LogLevel level;

  /// An optional short description of the message.
  final String? _description;

  /// The time the message was created.
  final DateTime time;

  /// The scope of the message.
  final LogScope scope;

  _LogMessage(this.message, this.level, this.time, this.scope, this._description);

  /// Creates a [_LogMessage] from JSON data.
  factory _LogMessage.fromJson(Map<String, dynamic> json) => _LogMessage(
        json['message'] as String,
        ConvertLevelToString.fromDisplayString(json['level'] as String),
        DateTime.parse(json['time'] as String),
        ConvertScopeToString.fromDisplayString(json['scope'] as String),
        json['description'] as String?,
      );

  /// Converts the [_LogMessage] to JSON data.
  Map<String, dynamic> toJson() {
    return {
      'description': _description ?? '',
      'level': level.toDisplayString(),
      'scope': scope.toDisplayString(),
      'time': time.toIso8601String(),
      'message': message,
    };
  }

  /// Creates a [_LogMessage] from raw data produced by [toRawData].
  static _LogMessage fromRawData(Uint8List data) {
    // The single data entries are stored as described in [toRawData].
    final int timestamp = data.getRange(0, 8).reduceIndexed(intReducer);
    final int levelIdx = data.getRange(8, 9).single;
    final int scopeIdx = data.getRange(9, 10).single;
    final int messageLength = data.getRange(12, 16).reduceIndexed(intReducer);
    final List<int> messageData = data.getRange(16, 16 + messageLength).toList();
    final List<int> descriptionData = data.getRange(16 + messageLength, data.length).toList();

    return _LogMessage(
      utf8.decode(messageData),
      LogLevel.values[levelIdx],
      DateTime.fromMillisecondsSinceEpoch(timestamp),
      LogScope.values[scopeIdx],
      descriptionData.isNotEmpty ? utf8.decode(descriptionData) : null,
    );
  }

  /// Converts the [_LogMessage] to raw data.
  Uint8List toRawData() {
    // 8 byte for the timestamp
    // 1 byte for the level
    // 1 byte for the scope
    // 2 bytes to support int32 data alignment
    // 4 byte for the message length
    // n bytes for the message + description

    final messageData = utf8.encode(message);
    final descrData = _description == null ? null : utf8.encode(_description!);
    final messageBytes = messageData.length;
    final descriptionBytes = descrData?.length ?? 0;
    final dataSize = 16 + messageBytes + descriptionBytes;
    final buffer = Uint8List(dataSize);

    buffer.buffer.asInt64List(0, 1)[0] = time.millisecondsSinceEpoch;
    buffer.setAll(8, [level.index, scope.index]);
    buffer.buffer.asInt32List(12, 1)[0] = messageBytes;
    buffer.setAll(16, messageData);

    if (_description != null) {
      buffer.setAll(16 + messageBytes, descrData!);
    }

    return buffer;
  }

  /// Returns a string representation of the description,
  /// including the meta data.
  ///
  /// If [formatForTerminal] is true, the message will be
  /// formatted for terminal output.
  String description({bool formatForTerminal = false}) {
    final formattedTime = '[${time.toString()}]';
    final formattedScope = '[scope: ${scope.toDisplayString(colored: formatForTerminal)}]';
    final formattedLevel = '[level: ${level.toDisplayString(colored: formatForTerminal)}]';
    final composed = '$formattedLevel$formattedScope$formattedTime ${_description ?? ''}'.trim();

    return formatForTerminal ? composed.bold : composed;
  }

  /// Returns a string representation of the [_LogMessage].
  ///
  /// If [formatForTerminal] is true, the message will be
  /// formatted for terminal output.
  @override
  String toString({bool formatForTerminal = false}) =>
      '${description(formatForTerminal: formatForTerminal)}\n$message';

  @override
  int get hashCode => toString().hashCode;

  @override
  bool operator ==(Object other) {
    return other is _LogMessage && hashCode == other.hashCode;
  }
}
