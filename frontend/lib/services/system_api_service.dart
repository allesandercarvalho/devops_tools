import 'dart:convert';
import 'package:http/http.dart' as http;

class SystemDependency {
  final String name;
  final bool installed;
  final String path;
  final String installCmd;
  final String description;

  SystemDependency({
    required this.name,
    required this.installed,
    required this.path,
    required this.installCmd,
    required this.description,
  });

  factory SystemDependency.fromJson(Map<String, dynamic> json) {
    return SystemDependency(
      name: json['name'] ?? '',
      installed: json['installed'] ?? false,
      path: json['path'] ?? '',
      installCmd: json['install_cmd'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class SystemApiService {
  static const String baseUrl = 'http://localhost:3002/api/system';

  static Future<List<SystemDependency>> checkDependencies() async {
    final response = await http.get(Uri.parse('$baseUrl/dependencies'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => SystemDependency.fromJson(json)).toList();
    } else {
      throw Exception('Failed to check dependencies: ${response.body}');
    }
  }
}
