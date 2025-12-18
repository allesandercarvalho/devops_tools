import 'dart:convert';
import 'package:http/http.dart' as http;

class AWSApiService {
  static const String baseUrl = 'http://localhost:3002/api';

  /// Execute an AWS CLI command
  static Future<Map<String, dynamic>> executeCommand({
    required String command,
    String? profile,
    String? region,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/aws/execute'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'command': command,
          if (profile != null) 'profile': profile,
          if (region != null) 'region': region,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 500) {
        // Return result even on 500 (command might have failed but we have output)
        return json.decode(response.body);
      } else {
        throw Exception('Failed to execute command: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error executing AWS command: $e');
    }
  }

  /// Get AWS CLI version
  static Future<String> getAWSVersion() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/aws/version'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['version'] ?? 'Unknown';
      } else {
        throw Exception('Failed to get AWS version');
      }
    } catch (e) {
      throw Exception('Error getting AWS version: $e');
    }
  }

  /// List configured AWS profiles
  static Future<List<String>> listProfiles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/aws/profiles'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['profiles'] ?? []);
      } else {
        throw Exception('Failed to list profiles');
      }
    } catch (e) {
      throw Exception('Error listing profiles: $e');
    }
  }
}
