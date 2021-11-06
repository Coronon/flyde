import 'dart:io';

import 'package:path/path.dart';
import 'package:flyde/core/fs/file_extension.dart';
import 'package:flyde/core/fs/search_directory.dart';
import 'package:flyde/core/fs/wrapper/source_file.dart';

/// Reads the files of the 'example' project and returns them as a
/// [SourceFile] [List].
///
/// Only C++ source or header files are returned. For the corresponding
/// extensions see [FileExtension].
Future<List<SourceFile>> loadExampleFiles() async {
  return await searchDirectory(Directory('./example'), (e) {
    final isSource = FileExtension.sources.contains(extension(e.path));
    final isHeader = FileExtension.headers.contains(extension(e.path));

    if (e is File && (isSource || isHeader)) {
      return SourceFile.fromFile(0, e, entryDirectory: Directory('./example'));
    }

    return null;
  });
}
