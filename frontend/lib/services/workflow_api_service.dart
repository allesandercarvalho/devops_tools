import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/workflow.dart';

class WorkflowApiService {
  static const String baseUrl = 'http://localhost:3002/api';

  static Future<List<Workflow>> listWorkflows() async {
    final response = await http.get(Uri.parse('$baseUrl/workflows'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Workflow.fromJson(e)).toList();
    } else {
      throw Exception('Failed to list workflows: ${response.body}');
    }
  }

  static Future<Workflow> getWorkflow(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/workflows/$id'));

    if (response.statusCode == 200) {
      return Workflow.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get workflow: ${response.body}');
    }
  }

  static Future<Workflow> saveWorkflow(Workflow workflow) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workflows'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(workflow.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Workflow.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to save workflow: ${response.body}');
    }
  }

  static Future<void> deleteWorkflow(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/workflows/$id'));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete workflow: ${response.body}');
    }
  }

  static Future<WorkflowExecution> executeWorkflow(String id, Map<String, String> variables) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workflows/$id/execute'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'variables': variables}),
    );

    if (response.statusCode == 200) {
      return WorkflowExecution.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to execute workflow: ${response.body}');
    }
  }

  // Global Variables API
  static Future<List<GlobalVariable>> listGlobalVariables() async {
    final response = await http.get(Uri.parse('$baseUrl/variables'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => GlobalVariable.fromJson(e)).toList();
    } else {
      throw Exception('Failed to list global variables: ${response.body}');
    }
  }

  static Future<GlobalVariable> getGlobalVariable(String name) async {
    final response = await http.get(Uri.parse('$baseUrl/variables/$name'));

    if (response.statusCode == 200) {
      return GlobalVariable.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get global variable: ${response.body}');
    }
  }

  static Future<GlobalVariable> saveGlobalVariable(GlobalVariable variable) async {
    final response = await http.post(
      Uri.parse('$baseUrl/variables'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(variable.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return GlobalVariable.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to save global variable: ${response.body}');
    }
  }

  static Future<void> deleteGlobalVariable(String name) async {
    final response = await http.delete(Uri.parse('$baseUrl/variables/$name'));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete global variable: ${response.body}');
    }
  }
}
