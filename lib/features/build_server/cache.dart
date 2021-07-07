import 'package:flyde/features/build_server/cache_file.dart';
import 'package:hive/hive.dart';

enum FileType { object, source }

class Cache {
  final String _projectId;

  late final String _objectBox;

  late final String _sourceBox;

  static const _objectCacheId = 'object-cache';

  static const _sourceCacheId = 'source-cache';

  Cache(this._projectId) {
    _sourceBox = '$_projectId-${Cache._sourceCacheId}';
    _objectBox = '$_projectId-${Cache._objectCacheId}';
    Hive.openBox(_objectBox);
    Hive.openBox(_sourceBox);
  }

  Future<void> store(CacheFile file, FileType type) async {
    final box = _getBox(type);
    await box.put(file.id, file);
  }

  CacheFile retrieve(String id, FileType type) {
    final box = _getBox(type);

    if (!box.containsKey(id)) {
      throw Exception('$id is not available');
    }

    return box.get(id) as CacheFile;
  }

  List<CacheFile> all(FileType type) {
    return _getBox(type).values.toList();
  }

  Box<CacheFile> _getBox(FileType type) {
    switch (type) {
      case FileType.object:
        return Hive.box(_objectBox);
      case FileType.source:
        return Hive.box(_sourceBox);
    }
  }
}
