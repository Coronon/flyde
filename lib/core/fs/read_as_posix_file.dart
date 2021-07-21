import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Reads a [file] as bytes and replaces all DOS line feeds (`\r\n`)
/// with Posix line feeds (`\n`).
Future<Uint8List> readAsPosixFile(File file) async {
  if (!await file.exists()) {
    throw ArgumentError('The file at path "${file.path}" does not exist.');
  }

  final content = await file.readAsString();
  final normalized = content.replaceAll('\r\n', '\n');

  return Uint8List.fromList(utf8.encode(normalized));
}

/// Extension on [File] which provides a method to read it as Posix file.
extension PosixReadable on File {
  /// Reads the file as bytes and replaces all DOS line feeds (`\r\n`)
  /// with Posix line feeds (`\n`).
  Future<Uint8List> readAsPosixBytes() async => await readAsPosixFile(this);
}
