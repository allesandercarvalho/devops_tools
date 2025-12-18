class NetworkToolExecution {
  final String id;
  final String userId;
  final String tool;
  final String target;
  final List<String> args;
  final String status;
  final String output;
  final dynamic parsedResult;
  final String? error;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int durationMs;

  NetworkToolExecution({
    required this.id,
    required this.userId,
    required this.tool,
    required this.target,
    required this.args,
    required this.status,
    required this.output,
    this.parsedResult,
    this.error,
    required this.startedAt,
    this.completedAt,
    required this.durationMs,
  });

  factory NetworkToolExecution.fromJson(Map<String, dynamic> json) {
    dynamic parsedResult;
    
    // Parse based on tool type
    if (json['parsed_result'] != null) {
      switch (json['tool']) {
        case 'ping':
          parsedResult = PingResult.fromJson(json['parsed_result']);
          break;
        case 'dig':
          parsedResult = DNSResult.fromJson(json['parsed_result']);
          break;
        case 'traceroute':
          parsedResult = TracerouteResult.fromJson(json['parsed_result']);
          break;
        case 'tcp-check':
          parsedResult = TCPPortResult.fromJson(json['parsed_result']);
          break;
        case 'http-request':
          parsedResult = HTTPResult.fromJson(json['parsed_result']);
          break;
        case 'dns-propagation':
          parsedResult = DNSPropagationResult.fromJson(json['parsed_result']);
          break;
        case 'whois':
          parsedResult = WhoisResult.fromJson(json['parsed_result']);
          break;
        case 'geoip':
          parsedResult = GeoIPResult.fromJson(json['parsed_result']);
          break;
        case 'tls-inspect':
          parsedResult = TLSResult.fromJson(json['parsed_result']);
          break;
        case 'nmap':
          parsedResult = NmapResult.fromJson(json['parsed_result']);
          break;
      }
    }

    return NetworkToolExecution(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      tool: json['tool'] ?? '',
      target: json['target'] ?? '',
      args: List<String>.from(json['args'] ?? []),
      status: json['status'] ?? '',
      output: json['output'] ?? '',
      parsedResult: parsedResult,
      error: json['error'],
      startedAt: DateTime.parse(json['started_at']),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
      durationMs: json['duration_ms'] ?? 0,
    );
  }
}

class PingResult {
  final int packetsSent;
  final int packetsReceived;
  final double packetLoss;
  final double minRTT;
  final double maxRTT;
  final double avgRTT;
  final double stdDevRTT;

  PingResult({
    required this.packetsSent,
    required this.packetsReceived,
    required this.packetLoss,
    required this.minRTT,
    required this.maxRTT,
    required this.avgRTT,
    required this.stdDevRTT,
  });

  factory PingResult.fromJson(Map<String, dynamic> json) {
    return PingResult(
      packetsSent: json['packets_sent'] ?? 0,
      packetsReceived: json['packets_received'] ?? 0,
      packetLoss: (json['packet_loss'] ?? 0).toDouble(),
      minRTT: (json['min_rtt'] ?? 0).toDouble(),
      maxRTT: (json['max_rtt'] ?? 0).toDouble(),
      avgRTT: (json['avg_rtt'] ?? 0).toDouble(),
      stdDevRTT: (json['stddev_rtt'] ?? 0).toDouble(),
    );
  }
}

class DNSResult {
  final String queryType;
  final List<String> answers;
  final int queryTime;
  final String server;

  DNSResult({
    required this.queryType,
    required this.answers,
    required this.queryTime,
    required this.server,
  });

  factory DNSResult.fromJson(Map<String, dynamic> json) {
    return DNSResult(
      queryType: json['query_type'] ?? '',
      answers: List<String>.from(json['answers'] ?? []),
      queryTime: json['query_time_ms'] ?? 0,
      server: json['server'] ?? '',
    );
  }
}

class TracerouteResult {
  final List<TracerouteHop> hops;

  TracerouteResult({required this.hops});

  factory TracerouteResult.fromJson(Map<String, dynamic> json) {
    return TracerouteResult(
      hops: (json['hops'] as List?)
          ?.map((h) => TracerouteHop.fromJson(h))
          .toList() ?? [],
    );
  }
}

class TracerouteHop {
  final int number;
  final String ip;
  final String? host;
  final double rtt1;
  final double rtt2;
  final double rtt3;
  final double avgRTT;

  TracerouteHop({
    required this.number,
    required this.ip,
    this.host,
    required this.rtt1,
    required this.rtt2,
    required this.rtt3,
    required this.avgRTT,
  });

  factory TracerouteHop.fromJson(Map<String, dynamic> json) {
    return TracerouteHop(
      number: json['number'] ?? 0,
      ip: json['ip'] ?? '',
      host: json['host'],
      rtt1: (json['rtt1'] ?? 0).toDouble(),
      rtt2: (json['rtt2'] ?? 0).toDouble(),
      rtt3: (json['rtt3'] ?? 0).toDouble(),
      avgRTT: (json['avg_rtt'] ?? 0).toDouble(),
    );
  }
}

class TCPPortResult {
  final String host;
  final int port;
  final bool open;
  final int timeMs;

  TCPPortResult({
    required this.host,
    required this.port,
    required this.open,
    required this.timeMs,
  });

  factory TCPPortResult.fromJson(Map<String, dynamic> json) {
    return TCPPortResult(
      host: json['host'] ?? '',
      port: json['port'] ?? 0,
      open: json['open'] ?? false,
      timeMs: json['time_ms'] ?? 0,
    );
  }
}

class HTTPResult {
  final int statusCode;
  final String statusText;
  final Map<String, List<String>> headers;
  final String body;
  final int timeMs;
  final int contentLength;

  HTTPResult({
    required this.statusCode,
    required this.statusText,
    required this.headers,
    required this.body,
    required this.timeMs,
    required this.contentLength,
  });

  factory HTTPResult.fromJson(Map<String, dynamic> json) {
    return HTTPResult(
      statusCode: json['status_code'] ?? 0,
      statusText: json['status_text'] ?? '',
      headers: Map<String, List<String>>.from(json['headers'] ?? {}),
      body: json['body'] ?? '',
      timeMs: json['time_ms'] ?? 0,
      contentLength: json['content_length'] ?? 0,
    );
  }
}

class NmapResult {
  final List<NmapHost> hosts;

  NmapResult({required this.hosts});

  factory NmapResult.fromJson(Map<String, dynamic> json) {
    return NmapResult(
      hosts: (json['hosts'] as List?)
          ?.map((h) => NmapHost.fromJson(h))
          .toList() ?? [],
    );
  }
}

class NmapHost {
  final String hostname;
  final String? ip;
  final String? os;
  final List<NmapPort> ports;

  NmapHost({
    required this.hostname,
    this.ip,
    this.os,
    required this.ports,
  });

  factory NmapHost.fromJson(Map<String, dynamic> json) {
    return NmapHost(
      hostname: json['hostname'] ?? '',
      ip: json['ip'],
      os: json['os'],
      ports: (json['ports'] as List?)
          ?.map((p) => NmapPort.fromJson(p))
          .toList() ?? [],
    );
  }
}

class NmapPort {
  final int port;
  final String state;
  final String service;

  NmapPort({
    required this.port,
    required this.state,
    required this.service,
  });

  factory NmapPort.fromJson(Map<String, dynamic> json) {
    return NmapPort(
      port: json['port'] ?? 0,
      state: json['state'] ?? '',
      service: json['service'] ?? '',
    );
  }
}

class WhoisResult {
  final String domain;
  final String registrar;
  final String createdDate;
  final String expiryDate;
  final String updatedDate;
  final String registrant;
  final List<String> nameServers;
  final String rawData;

  WhoisResult({
    required this.domain,
    required this.registrar,
    required this.createdDate,
    required this.expiryDate,
    required this.updatedDate,
    required this.registrant,
    required this.nameServers,
    required this.rawData,
  });

  factory WhoisResult.fromJson(Map<String, dynamic> json) {
    return WhoisResult(
      domain: json['domain'] ?? '',
      registrar: json['registrar'] ?? '',
      createdDate: json['created_date'] ?? '',
      expiryDate: json['expiry_date'] ?? '',
      updatedDate: json['updated_date'] ?? '',
      registrant: json['registrant'] ?? '',
      nameServers: List<String>.from(json['name_servers'] ?? []),
      rawData: json['raw_data'] ?? '',
    );
  }
}

class TLSResult {
  final String host;
  final int port;
  final String version;
  final String cipher;
  final String issuer;
  final String subject;
  final String validFrom;
  final String validTo;
  final List<String> dnsNames;
  final bool isValid;
  final int daysToExpiry;

  TLSResult({
    required this.host,
    required this.port,
    required this.version,
    required this.cipher,
    required this.issuer,
    required this.subject,
    required this.validFrom,
    required this.validTo,
    required this.dnsNames,
    required this.isValid,
    required this.daysToExpiry,
  });

  factory TLSResult.fromJson(Map<String, dynamic> json) {
    return TLSResult(
      host: json['host'] ?? '',
      port: json['port'] ?? 0,
      version: json['version'] ?? '',
      cipher: json['cipher'] ?? '',
      issuer: json['issuer'] ?? '',
      subject: json['subject'] ?? '',
      validFrom: json['valid_from'] ?? '',
      validTo: json['valid_to'] ?? '',
      dnsNames: List<String>.from(json['dns_names'] ?? []),
      isValid: json['is_valid'] ?? false,
      daysToExpiry: json['days_to_expiry'] ?? 0,
    );
  }
}

class GeoIPResult {
  final String ip;
  final String country;
  final String countryCode;
  final String region;
  final String city;
  final double latitude;
  final double longitude;
  final String isp;
  final String organization;

  GeoIPResult({
    required this.ip,
    required this.country,
    required this.countryCode,
    required this.region,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.isp,
    required this.organization,
  });

  factory GeoIPResult.fromJson(Map<String, dynamic> json) {
    return GeoIPResult(
      ip: json['ip'] ?? '',
      country: json['country'] ?? '',
      countryCode: json['country_code'] ?? '',
      region: json['region'] ?? '',
      city: json['city'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      isp: json['isp'] ?? '',
      organization: json['organization'] ?? '',
    );
  }
}

class DNSPropagationResult {
  final Map<String, PropagationDetail> servers;

  DNSPropagationResult({required this.servers});

  factory DNSPropagationResult.fromJson(Map<String, dynamic> json) {
    final servers = <String, PropagationDetail>{};
    json.forEach((key, value) {
      servers[key] = PropagationDetail.fromJson(value);
    });
    return DNSPropagationResult(servers: servers);
  }
}

class PropagationDetail {
  final String status;
  final List<String> records;
  final String error;

  PropagationDetail({
    required this.status,
    required this.records,
    required this.error,
  });

  factory PropagationDetail.fromJson(Map<String, dynamic> json) {
    return PropagationDetail(
      status: json['status'] ?? 'unknown',
      records: List<String>.from(json['records'] ?? []),
      error: json['error'] ?? '',
    );
  }
}

class HTTPRequestResult {
  final int statusCode;
  final String status;
  final String proto;
  final Map<String, dynamic> headers;
  final int bodySize;

  HTTPRequestResult({
    required this.statusCode,
    required this.status,
    required this.proto,
    required this.headers,
    required this.bodySize,
  });

  factory HTTPRequestResult.fromJson(Map<String, dynamic> json) {
    return HTTPRequestResult(
      statusCode: json['status_code'] ?? 0,
      status: json['status'] ?? '',
      proto: json['proto'] ?? '',
      headers: json['headers'] ?? {},
      bodySize: json['body_size'] ?? 0,
    );
  }
}
