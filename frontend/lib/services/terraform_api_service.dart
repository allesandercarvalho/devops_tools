import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/terraform.dart';

class TerraformApiService {
  static const String baseUrl = 'http://localhost:3002/api/terraform';

  static Future<TerraformExecution> executeCommand({
    required String workDir,
    required String command,
    List<String> args = const [],
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/exec'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'work_dir': workDir,
        'command': command,
        'args': args,
      }),
    );

    if (response.statusCode == 200) {
      return TerraformExecution.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to execute terraform command: ${response.body}');
    }
  }

  static Future<TerraformState> getState(String workDir) async {
    final response = await http.get(
      Uri.parse('$baseUrl/state?work_dir=$workDir'),
    );

    if (response.statusCode == 200) {
      return TerraformState.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get terraform state: ${response.body}');
    }
  }
}
