import 'package:flyde/core/fs/wrapper/source_file.dart';

/// Creates a map of [files], where each file hash is associated with the file's id.
///
/// Used to compare project files with their version stored in some cache.
Future<Map<String, String>> mapExampleFiles(List<SourceFile> files) async {
  return {
    for (final file in files) file.id: await file.hash,
  };
}
