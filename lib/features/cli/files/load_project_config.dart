import 'dart:io';

import '../../../core/fs/yaml.dart';
import '../../../core/fs/configs/project_config.dart';

/// Loads the project config ans returns it.
///
/// The config file is assumed to be located in the current
/// working directory and named `project.yaml`.
///
/// Throws when the file is not present or mis-formated.
Future<ProjectConfig> loadProjectConfig() async {
  final path = '${Directory.current.path}/project.yaml';
  final file = File(path);

  if (!await file.exists()) {
    throw StateError('Project config file not found');
  }

  final String content = await file.readAsString();
  final Map<String, dynamic> yaml = loadYamlAsMap(content);

  return ProjectConfig.fromJson(yaml);
}
