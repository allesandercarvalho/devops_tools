class HttpCollection {
  String id;
  String name;
  String? description;
  List<SavedRequest> requests;
  DateTime createdAt;
  DateTime updatedAt;

  HttpCollection({
    required this.id,
    required this.name,
    this.description,
    List<SavedRequest>? requests,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : requests = requests ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'requests': requests.map((r) => r.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory HttpCollection.fromJson(Map<String, dynamic> json) {
    return HttpCollection(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      requests: (json['requests'] as List?)?.map((r) => SavedRequest.fromJson(r)).toList() ?? [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class SavedRequest {
  String id;
  String name;
  String? description;
  String method;
  String url;
  Map<String, String> headers;
  Map<String, String> queryParams;
  String body;
  String bodyType;
  Map<String, dynamic>? auth;
  DateTime createdAt;

  SavedRequest({
    required this.id,
    required this.name,
    this.description,
    required this.method,
    required this.url,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    this.body = '',
    this.bodyType = 'json',
    this.auth,
    DateTime? createdAt,
  })  : headers = headers ?? {},
        queryParams = queryParams ?? {},
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'method': method,
      'url': url,
      'headers': headers,
      'query_params': queryParams,
      'body': body,
      'body_type': bodyType,
      'auth': auth,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SavedRequest.fromJson(Map<String, dynamic> json) {
    return SavedRequest(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      method: json['method'],
      url: json['url'],
      headers: Map<String, String>.from(json['headers'] ?? {}),
      queryParams: Map<String, String>.from(json['query_params'] ?? {}),
      body: json['body'] ?? '',
      bodyType: json['body_type'] ?? 'json',
      auth: json['auth'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
