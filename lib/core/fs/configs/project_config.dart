import 'package:json_annotation/json_annotation.dart';

import '../../networking/utils/is_valid_host_name.dart';
import '../../networking/utils/is_valid_ip_address.dart';

part 'project_config.g.dart';

/// [ProjectConfig] is the representation of the project configuration file.
///
/// A config contains the project's name, the server address and the port.
@JsonSerializable()
class ProjectConfig {
  /// The project's name.
  final String name;

  /// The port on which the build server is listening.
  final int port;

  /// The build server's host name / IP address.
  ///
  /// Must be either a valid host name or an IP address.
  final String host;

  ProjectConfig({required this.name, required this.port, required this.host}) {
    if (name.isEmpty) {
      throw ArgumentError('The name of the project cannot be empty');
    }

    if (port < 0 || port > 65535) {
      throw ArgumentError('The port must be between 0 and 65535');
    }

    if (!isValidHostName(host) && !isValidIPAddress(host)) {
      throw ArgumentError('The server must be a valid host name or IP address');
    }
  }

  factory ProjectConfig.fromJson(Map<String, dynamic> json) {
    return _$ProjectConfigFromJson({
      'name': json['name'],
      'port': json['server']['port'],
      'host': json['server']['host'],
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'server': {
        'port': port,
        'host': host,
      },
    };
  }
}
