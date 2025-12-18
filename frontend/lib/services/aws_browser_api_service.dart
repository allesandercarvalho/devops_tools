import 'dart:convert';
import 'package:http/http.dart' as http;

class AWSBrowserApiService {
  static const String baseUrl = 'http://localhost:3002/api';

  /// List all S3 buckets
  static Future<List<Map<String, dynamic>>> listS3Buckets({String? profile}) async {
    try {
      final uri = Uri.parse('$baseUrl/aws/s3/buckets${profile != null ? '?profile=$profile' : ''}');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['buckets'] ?? []);
      } else {
        throw Exception('Failed to list S3 buckets: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error listing S3 buckets: $e');
    }
  }

  /// List objects in an S3 bucket
  static Future<List<Map<String, dynamic>>> listS3Objects({
    required String bucket,
    String? prefix,
    String? profile,
  }) async {
    try {
      final queryParams = {
        'bucket': bucket,
        if (prefix != null && prefix.isNotEmpty) 'prefix': prefix,
        if (profile != null) 'profile': profile,
      };

      final uri = Uri.parse('$baseUrl/aws/s3/objects').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['objects'] ?? []);
      } else {
        throw Exception('Failed to list S3 objects: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error listing S3 objects: $e');
    }
  }

  /// List EC2 instances
  static Future<List<Map<String, dynamic>>> listEC2Instances({
    String? profile,
    String region = 'us-east-1',
  }) async {
    try {
      final queryParams = {
        'region': region,
        if (profile != null) 'profile': profile,
      };

      final uri = Uri.parse('$baseUrl/aws/ec2/instances').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['instances'] ?? []);
      } else {
        throw Exception('Failed to list EC2 instances: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error listing EC2 instances: $e');
    }
  }

  /// List RDS instances
  static Future<List<Map<String, dynamic>>> listRDSInstances({
    String? profile,
    String region = 'us-east-1',
  }) async {
    try {
      final queryParams = {
        'region': region,
        if (profile != null) 'profile': profile,
      };

      final uri = Uri.parse('$baseUrl/aws/rds/instances').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['instances'] ?? []);
      } else {
        throw Exception('Failed to list RDS instances: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error listing RDS instances: $e');
    }
  }

  /// List Lambda functions
  static Future<List<Map<String, dynamic>>> listLambdaFunctions({
    String? profile,
    String region = 'us-east-1',
  }) async {
    try {
      final queryParams = {
        'region': region,
        if (profile != null) 'profile': profile,
      };

      final uri = Uri.parse('$baseUrl/aws/lambda/functions').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['functions'] ?? []);
      } else {
        throw Exception('Failed to list Lambda functions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error listing Lambda functions: $e');
    }
  }
}
