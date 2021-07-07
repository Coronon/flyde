import 'dart:typed_data';

import 'package:hive/hive.dart';

part 'cache_file.g.dart';

@HiveType(typeId: 0)
class CacheFile {
  @HiveField(0)
  String id;

  @HiveField(1)
  String hash;

  @HiveField(2)
  String name;

  @HiveField(3)
  String extension;

  @HiveField(4)
  List<String> path;

  @HiveField(5)
  Uint8List data;

  CacheFile(this.id, this.hash, this.name, this.extension, this.path, this.data);

  String buildFullPath({String? parentDirectory, String? extension}) {
    return '${buildDirPath(parentDirectory: parentDirectory)}/$name.${extension ?? this.extension}';
  }

  String buildDirPath({String? parentDirectory}) {
    if (parentDirectory == null) {
      return '${path.join('/')}';
    }

    if (parentDirectory.endsWith('\/|\\')) {
      return '$parentDirectory${path.join('/')}';
    }

    return '$parentDirectory/${path.join('/')}';
  }
}
