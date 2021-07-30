import 'dart:io';

import 'package:crypto/crypto.dart';

/// Hashes the content of a file with SHA-256 algorithm.
Future<String> hash({required File file}) async {
  final digest = await sha256.bind(file.openRead()).last;
  return digest.toString();
}

/// Extension of the `File` class that allows to retrieve the hash of the file.
extension FileHash on File {
  /// The SHA-256 hash of the file.
  Future<String> get contentHash async {
    return await hash(file: this);
  }
}
