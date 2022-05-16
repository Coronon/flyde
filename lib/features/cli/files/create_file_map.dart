import '../../../core/fs/wrapper/source_file.dart';

/// Converts the given list of [files] to a [Map] where the keys are the
/// file identifiers and the values are the hashes of the file contents.
Future<Map<String, String>> createFileMap(List<SourceFile> files) async {
  return {
    for (final file in files) file.id: await file.hash,
  };
}
