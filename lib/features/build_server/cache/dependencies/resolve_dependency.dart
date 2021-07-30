import 'dart:io';

import 'package:flyde/core/fs/wrapper/source_file.dart';
import 'package:path/path.dart';

/// Resolves the [dependency] of [origin], which is located within [storageRoot], and returns
/// the id of the resolved dependency.
///
/// If [dependency] is an absolute name, `resolve` checks if it exists exactly one time within [all] source files.
Future<String> resolve(
  String dependency,
  SourceFile origin,
  List<SourceFile> all,
  Directory storageRoot,
) async {
  final originPath = origin.relativePath(filename: false);

  if (RegExp(r'^.*(\/|\\).+$').hasMatch(dependency)) {
    // Dependency is a relative path to origin -> resolve path and check if the file exists
    final resolved = normalize(join(originPath, dependency));
    final file = File(normalize(join(storageRoot.path, resolved)));

    if (!await file.exists() || !isWithin(storageRoot.path, file.path)) {
      throw ArgumentError('Cannot resolve dependency "$dependency" to an existing file.');
    }

    return SourceFile.fromFile(origin.entry, file, entryDirectory: storageRoot).id;
  }

  // Dependency is an absolute name
  // -> iterate over all files and check if the name and extension exist at the entry point of [origin]
  final name = withoutExtension(dependency);
  final extension = context.extension(dependency).substring(1);

  return all
      .singleWhere(
        (file) => file.name == name && file.extension == extension && file.entry == origin.entry,
      )
      .id;
}
