class ArgoAppDetail {
  final String name;
  final String project;
  final ArgoSource source;
  final ArgoDestination destination;
  final ArgoSyncStatus sync;
  final ArgoHealthStatus health;
  final ArgoOperation? operation;

  ArgoAppDetail({
    required this.name,
    required this.project,
    required this.source,
    required this.destination,
    required this.sync,
    required this.health,
    this.operation,
  });

  factory ArgoAppDetail.fromJson(Map<String, dynamic> json) {
    return ArgoAppDetail(
      name: json['name'] ?? '',
      project: json['project'] ?? '',
      source: ArgoSource.fromJson(json['source'] ?? {}),
      destination: ArgoDestination.fromJson(json['destination'] ?? {}),
      sync: ArgoSyncStatus.fromJson(json['sync'] ?? {}),
      health: ArgoHealthStatus.fromJson(json['health'] ?? {}),
      operation: json['operation'] != null ? ArgoOperation.fromJson(json['operation']) : null,
    );
  }
}

class ArgoSource {
  final String repoURL;
  final String path;
  final String targetRevision;

  ArgoSource({
    required this.repoURL,
    required this.path,
    required this.targetRevision,
  });

  factory ArgoSource.fromJson(Map<String, dynamic> json) {
    return ArgoSource(
      repoURL: json['repoURL'] ?? '',
      path: json['path'] ?? '',
      targetRevision: json['targetRevision'] ?? '',
    );
  }
}

class ArgoDestination {
  final String server;
  final String namespace;

  ArgoDestination({
    required this.server,
    required this.namespace,
  });

  factory ArgoDestination.fromJson(Map<String, dynamic> json) {
    return ArgoDestination(
      server: json['server'] ?? '',
      namespace: json['namespace'] ?? '',
    );
  }
}

class ArgoSyncStatus {
  final String status;
  final String revision;

  ArgoSyncStatus({
    required this.status,
    required this.revision,
  });

  factory ArgoSyncStatus.fromJson(Map<String, dynamic> json) {
    return ArgoSyncStatus(
      status: json['status'] ?? 'Unknown',
      revision: json['revision'] ?? '',
    );
  }
}

class ArgoHealthStatus {
  final String status;
  final String message;

  ArgoHealthStatus({
    required this.status,
    required this.message,
  });

  factory ArgoHealthStatus.fromJson(Map<String, dynamic> json) {
    return ArgoHealthStatus(
      status: json['status'] ?? 'Unknown',
      message: json['message'] ?? '',
    );
  }
}

class ArgoOperation {
  final ArgoSyncOperation? sync;

  ArgoOperation({this.sync});

  factory ArgoOperation.fromJson(Map<String, dynamic> json) {
    return ArgoOperation(
      sync: json['sync'] != null ? ArgoSyncOperation.fromJson(json['sync']) : null,
    );
  }
}

class ArgoSyncOperation {
  final String revision;
  final String status;

  ArgoSyncOperation({
    required this.revision,
    required this.status,
  });

  factory ArgoSyncOperation.fromJson(Map<String, dynamic> json) {
    return ArgoSyncOperation(
      revision: json['revision'] ?? '',
      status: json['status'] ?? '',
    );
  }
}
