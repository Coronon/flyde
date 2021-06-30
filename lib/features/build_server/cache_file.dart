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
  Uint8List data;

  CacheFile(this.id, this.hash, this.data);
}
