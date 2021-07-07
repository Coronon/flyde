import 'dart:io';

import 'package:crypto/crypto.dart';

Future<String> hash({required File file}) async {
  final digest = await sha256.bind(file.openRead()).last;
  return digest.toString();
}

extension FileHash on File {
  Future<String> get contentHash async {
    return await hash(file: this);
  }
}
