import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/argocd.dart';

class ArgoCDApiService {
  static const String baseUrl = 'http://localhost:3002/api/argocd';

  static Future<List<ArgoAppDetail>> listApplications() async {
    final response = await http.get(Uri.parse('$baseUrl/apps'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => ArgoAppDetail.fromJson(json)).toList();
    } else {
      throw Exception('Failed to list applications: ${response.body}');
    }
  }

  static Future<ArgoAppDetail> getApplication(String name) async {
    final response = await http.get(Uri.parse('$baseUrl/apps/$name'));

    if (response.statusCode == 200) {
      return ArgoAppDetail.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get application: ${response.body}');
    }
  }

  static Future<void> syncApplication(String name) async {
    final response = await http.post(Uri.parse('$baseUrl/apps/$name/sync'));

    if (response.statusCode != 200) {
      throw Exception('Failed to sync application: ${response.body}');
    }
  }
}
