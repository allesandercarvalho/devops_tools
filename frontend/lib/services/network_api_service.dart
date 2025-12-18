import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/network_tool.dart';

class NetworkApiService {
  static const String baseUrl = 'http://localhost:3002/api/network';

  // Ping
  static Future<NetworkToolExecution> executePing({
    required String target,
    int count = 4,
    int timeout = 5,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ping'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'target': target,
        'count': count,
        'timeout': timeout,
      }),
    );

    if (response.statusCode == 200) {
      return NetworkToolExecution.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to execute ping: ${response.body}');
    }
  }

  // DNS Lookup
  static Future<NetworkToolExecution> executeDNSLookup({
    required String target,
    String queryType = 'A',
    String server = '',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/dns/lookup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'target': target,
        'query_type': queryType,
        'server': server,
      }),
    );

    if (response.statusCode == 200) {
      return NetworkToolExecution.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to execute DNS lookup: ${response.body}');
    }
  }

  // Traceroute
  static Future<NetworkToolExecution> executeTraceroute({
    required String target,
    int maxHops = 30,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/traceroute'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'target': target,
        'max_hops': maxHops,
      }),
    );

    if (response.statusCode == 200) {
      return NetworkToolExecution.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to execute traceroute: ${response.body}');
    }
  }

  // TCP Port Check
  static Future<NetworkToolExecution> checkTCPPort({
    required String host,
    required int port,
    int timeout = 5,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tcp/check'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'host': host,
        'port': port,
        'timeout': timeout,
      }),
    );

    if (response.statusCode == 200) {
      return NetworkToolExecution.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to check TCP port: ${response.body}');
    }
  }

  // HTTP Request
  static Future<NetworkToolExecution> executeHTTPRequest({
    required String method,
    required String url,
    Map<String, String> headers = const {},
    String body = '',
    int timeout = 10,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/http/request'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'method': method,
        'url': url,
        'headers': headers,
        'body': body,
        'timeout': timeout,
      }),
    );

    if (response.statusCode == 200) {
      return NetworkToolExecution.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to execute HTTP request: ${response.body}');
    }
  }

  // Nmap Scan
  static Future<NetworkToolExecution> executeNmap({
    required String target,
    String scanType = 'quick',
    String ports = '',
    Map<String, dynamic>? options,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/nmap/scan'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'target': target,
        'scan_type': scanType,
        'ports': ports, // legacy
        'options': options ?? {},
      }),
    );

    if (response.statusCode == 200) {
      return NetworkToolExecution.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to execute nmap: ${response.body}');
    }
  }

  // Whois Lookup
  static Future<NetworkToolExecution> executeWhois({
    required String domain,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/whois'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'domain': domain,
      }),
    );

    if (response.statusCode == 200) {
      return NetworkToolExecution.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to execute whois: ${response.body}');
    }
  }

  // TLS Inspector
  static Future<NetworkToolExecution> inspectTLS({
    required String host,
    int port = 443,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tls/inspect'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'host': host,
        'port': port,
      }),
    );

    if (response.statusCode == 200) {
      return NetworkToolExecution.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to inspect TLS: ${response.body}');
    }
  }

  // GeoIP Lookup
  static Future<NetworkToolExecution> lookupGeoIP({
    required String ip,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/geoip'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ip': ip,
      }),
    );

    if (response.statusCode == 200) {
      return NetworkToolExecution.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to lookup GeoIP: ${response.body}');
    }
  }

  // DNS Propagation
  static Future<NetworkToolExecution> executeDNSPropagation({
    required String domain,
    required String type,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/dns/propagation'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'domain': domain,
        'type': type,
      }),
    );

    if (response.statusCode == 200) {
      return NetworkToolExecution.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to check DNS propagation: ${response.body}');
    }
  }

  // Advanced HTTP Request with curl
  static Future<NetworkToolExecution> executeCurlRequest(Map<String, dynamic> request) async {
    final response = await http.post(
      Uri.parse('$baseUrl/http/curl'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request),
    );

    if (response.statusCode == 200) {
      return NetworkToolExecution.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to execute HTTP request: ${response.body}');
    }
  }

}
