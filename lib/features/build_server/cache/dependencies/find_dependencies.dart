import 'dart:convert';

import 'package:flyde/core/fs/wrapper/source_file.dart';

/// Finds all direct dependencies in [file].
Future<Set<String>> findDependencies(SourceFile file) async {
  final text = utf8.decode((await file.data).toList());
  final includes = LineSplitter()
      .convert(text)
      // Remove comments
      .map((line) => line.replaceAll(RegExp(r'\/\/.*$'), ""))
      // Remove leading and trailing whitespace
      .map((line) => line.trim())
      // Get all possible includes
      .where((line) => line.startsWith('#include'))
      // Remove '#include' prefix
      .map((line) => line.substring('#include'.length).trim())
      // Filter out all <*> includes and ensure "*" or '*'
      .where((include) =>
          !RegExp(r'^\<[^\0]+\>$').hasMatch(include) &&
          (RegExp(r'^\"[^\0]+\"$').hasMatch(include) || RegExp(r"^\'[^\0]+\'$").hasMatch(include)))
      // Remove quotes
      .map((include) => include.substring(1, include.length - 1))
      .toSet();

  return includes;
}
