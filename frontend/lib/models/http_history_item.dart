class HttpHistoryItem {
  String id;
  String method;
  String url;
  int? statusCode;
  String? statusText;
  int? timeMs;
  DateTime timestamp;
  Map<String, String> headers;
  Map<String, String> queryParams;
  String body;
  String? responseBody;
  bool isSuccess;

  HttpHistoryItem({
    required this.id,
    required this.method,
    required this.url,
    this.statusCode,
    this.statusText,
    this.timeMs,
    DateTime? timestamp,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    this.body = '',
    this.responseBody,
    bool? isSuccess,
  })  : timestamp = timestamp ?? DateTime.now(),
        headers = headers ?? {},
        queryParams = queryParams ?? {},
        isSuccess = isSuccess ?? (statusCode != null && statusCode >= 200 && statusCode < 300);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'method': method,
      'url': url,
      'status_code': statusCode,
      'status_text': statusText,
      'time_ms': timeMs,
      'timestamp': timestamp.toIso8601String(),
      'headers': headers,
      'query_params': queryParams,
      'body': body,
      'response_body': responseBody,
      'is_success': isSuccess,
    };
  }

  factory HttpHistoryItem.fromJson(Map<String, dynamic> json) {
    return HttpHistoryItem(
      id: json['id'],
      method: json['method'],
      url: json['url'],
      statusCode: json['status_code'],
      statusText: json['status_text'],
      timeMs: json['time_ms'],
      timestamp: DateTime.parse(json['timestamp']),
      headers: Map<String, String>.from(json['headers'] ?? {}),
      queryParams: Map<String, String>.from(json['query_params'] ?? {}),
      body: json['body'] ?? '',
      responseBody: json['response_body'],
      isSuccess: json['is_success'],
    );
  }

  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get shortUrl {
    try {
      final uri = Uri.parse(url);
      return uri.path.length > 30 ? '${uri.path.substring(0, 27)}...' : uri.path;
    } catch (e) {
      return url.length > 30 ? '${url.substring(0, 27)}...' : url;
    }
  }
}
