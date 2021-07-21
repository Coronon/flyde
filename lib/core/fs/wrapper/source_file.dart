import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../read_as_posix_file.dart';

/// Representation of source files.
///
/// The file data can either be stored in memory or referenced on disk,
/// making the class usable on the front and backend.
///
/// If constructed using raw data, it must be ensured that the file's
/// data has been converted to posix line feed format.
/// It is recommended to use the `readAsPosixFile` function to do this.
class SourceFile {
  Uint8List? _data;

  File? _file;

  /// The hash of the file depending on `data`.
  late Future<String> hash = _hash;

  /// The id of the file. Unique for each file regardless of the content
  /// but reproducable.
  late String id = _id;

  /// The index of the entry point of the project.
  final int entry;

  /// The path relative to the entry point.
  late final List<String> path;

  /// The name of the file.
  late final String name;

  /// The file's extension used to determine if it's a header or source file.
  /// The `String` should not start with a `.`.
  ///
  /// Bad: `.cpp`
  ///
  /// Good: `cpp`
  late final String extension;

  SourceFile(this.entry, this.path, this.name, this.extension, {Uint8List? data, File? file}) {
    if (data != null) {
      _data = data;
    } else if (file != null) {
      _file = file;
    } else {
      throw ArgumentError('Either file or data has to be provided');
    }
  }

  SourceFile.fromFile(this.entry, File file, {Directory? entryDirectory}) {
    final String relPath;

    if (entryDirectory != null) {
      relPath = p.relative(file.path, from: entryDirectory.path);
    } else if (p.isRelative(file.path)) {
      relPath = file.path;
    } else {
      throw ArgumentError(
        '[file] must not have an absolute path, but be relative to the entry directory.',
      );
    }

    name = p.basenameWithoutExtension(relPath);
    path = p.split(p.dirname(relPath)).where((p) => p != '.' && p != './' && p != '/').toList();
    extension = p.extension(relPath).substring(1);
    _file = file;
  }

  /// Returns the file's path relative to [origin].
  ///
  /// If [filename] is false, only the directory will be returned.
  String relativePath({String origin = '', bool filename = true}) =>
      p.joinAll([origin, ...path, filename ? '$name.$extension' : '']);

  /// The content of the file as raw byte data.
  ///
  /// If the constructor was called with `file:` the getter will read
  /// the file and return it's content.
  ///
  /// When the data is provided by a file, all line feeds are converted
  /// to `\n`.
  Future<Uint8List> get data async => _data ?? await _file!.readAsPosixBytes();

  Future<String> get _hash async => sha256.convert((await data).toList()).toString();

  String get _id {
    final output = AccumulatorSink<Digest>();
    final input = sha256.startChunkedConversion(output);
    final delimiter = utf8.encode(':--:').toList();

    input.add([entry]);
    input.add(delimiter);
    input.add(utf8.encode(name));
    input.add(delimiter);
    input.add(utf8.encode(extension));
    input.add(delimiter);

    for (final pathSegement in path) {
      input.add(utf8.encode(pathSegement));
      input.add(delimiter);
    }

    input.close();

    return output.events.single.toString();
  }
}
