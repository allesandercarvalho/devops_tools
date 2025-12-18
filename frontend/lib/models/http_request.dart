class HttpRequestModel {
  String method;
  String url;
  Map<String, String> headers;
  Map<String, String> queryParams;
  String body;
  String bodyType; // json, xml, form, raw
  AuthConfig? auth;
  int timeout;
  bool followRedirects;
  bool verifySSL;
  bool verbose;

  HttpRequestModel({
    this.method = 'GET',
    this.url = '',
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    this.body = '',
    this.bodyType = 'json',
    this.auth,
    this.timeout = 30,
    this.followRedirects = true,
    this.verifySSL = true,
    this.verbose = false,
  })  : headers = headers ?? {},
        queryParams = queryParams ?? {};

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'url': url,
      'headers': headers,
      'query_params': queryParams,
      'body': body,
      'body_type': bodyType,
      'auth': auth?.toJson(),
      'timeout': timeout,
      'follow_redirects': followRedirects,
      'verify_ssl': verifySSL,
      'verbose': verbose,
    };
  }

  factory HttpRequestModel.fromJson(Map<String, dynamic> json) {
    return HttpRequestModel(
      method: json['method'] ?? 'GET',
      url: json['url'] ?? '',
      headers: Map<String, String>.from(json['headers'] ?? {}),
      queryParams: Map<String, String>.from(json['query_params'] ?? {}),
      body: json['body'] ?? '',
      bodyType: json['body_type'] ?? 'json',
      auth: json['auth'] != null ? AuthConfig.fromJson(json['auth']) : null,
      timeout: json['timeout'] ?? 30,
      followRedirects: json['follow_redirects'] ?? true,
      verifySSL: json['verify_ssl'] ?? true,
      verbose: json['verbose'] ?? false,
    );
  }
}

class AuthConfig {
  String type; // none, basic, bearer, apikey
  String? username;
  String? password;
  String? token;
  String? apiKey;
  String? apiKeyHeader;

  AuthConfig({
    this.type = 'none',
    this.username,
    this.password,
    this.token,
    this.apiKey,
    this.apiKeyHeader,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'username': username,
      'password': password,
      'token': token,
      'api_key': apiKey,
      'api_key_header': apiKeyHeader,
    };
  }

  factory AuthConfig.fromJson(Map<String, dynamic> json) {
    return AuthConfig(
      type: json['type'] ?? 'none',
      username: json['username'],
      password: json['password'],
      token: json['token'],
      apiKey: json['api_key'],
      apiKeyHeader: json['api_key_header'],
    );
  }
}

class HttpResponseModel {
  int statusCode;
  String statusText;
  Map<String, List<String>> headers;
  String body;
  int timeMs;
  int contentLength;
  String contentType;
  String curlCommand;

  HttpResponseModel({
    required this.statusCode,
    required this.statusText,
    required this.headers,
    required this.body,
    required this.timeMs,
    required this.contentLength,
    required this.contentType,
    required this.curlCommand,
  });

  factory HttpResponseModel.fromJson(Map<String, dynamic> json) {
    // Parse headers
    Map<String, List<String>> parsedHeaders = {};
    if (json['headers'] != null) {
      (json['headers'] as Map<String, dynamic>).forEach((key, value) {
        if (value is List) {
          parsedHeaders[key] = List<String>.from(value);
        } else if (value is String) {
          parsedHeaders[key] = [value];
        }
      });
    }

    return HttpResponseModel(
      statusCode: json['status_code'] ?? 0,
      statusText: json['status_text'] ?? '',
      headers: parsedHeaders,
      body: json['body'] ?? '',
      timeMs: json['time_ms'] ?? 0,
      contentLength: json['content_length'] ?? 0,
      contentType: json['content_type'] ?? '',
      curlCommand: json['curl_command'] ?? '',
    );
  }

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  bool get isRedirect => statusCode >= 300 && statusCode < 400;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isServerError => statusCode >= 500;
}
