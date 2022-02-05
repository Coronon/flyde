import 'dart:io';

import 'package:path/path.dart';

import '../../../core/fs/configs/compiler_config.dart';
import '../../../core/fs/file_extension.dart';
import '../../../core/fs/search_directory.dart';
import '../../../core/fs/wrapper/source_file.dart';

/// Seaches for all source and header files in the directories given in the [config].
Future<List<SourceFile>> loadProjectFiles(CompilerConfig config) async {
  final List<SourceFile> files = [];
  final Map<int, Directory> entryDirectories = config.sourceDirectories
      .map(
        (path) => Directory(path),
      )
      .toList()
      .asMap();

  for (final entryDirectoryIdx in entryDirectories.keys) {
    final Directory entryDirectory = entryDirectories[entryDirectoryIdx]!;

    files.addAll(
      await searchDirectory(
        entryDirectory,
        (e) {
          final isSource = FileExtension.sources.contains(extension(e.path));
          final isHeader = FileExtension.headers.contains(extension(e.path));

          if (e is File && (isSource || isHeader)) {
            return SourceFile.fromFile(entryDirectoryIdx, e, entryDirectory: entryDirectory);
          }

          return null;
        },
      ),
    );
  }

  return files;
}
