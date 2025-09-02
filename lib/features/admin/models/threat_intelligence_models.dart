// Threat Intelligence Models

enum ThreatSeverity {
  low,
  medium,
  high,
  critical
}

enum ThreatType {
  malware,
  phishing,
  bruteForce,
  ddos,
  dataExfiltration,
  insider,
  apt,
  ransomware
}

class ThreatFeed {
  final String id;
  final String name;
  final String source;
  final ThreatType type;
  final ThreatSeverity severity;
  final String description;
  final List<String> indicators;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final bool isActive;

  ThreatFeed({
    required this.id,
    required this.name,
    required this.source,
    required this.type,
    required this.severity,
    required this.description,
    required this.indicators,
    required this.metadata,
    required this.timestamp,
    this.isActive = true,
  });

  factory ThreatFeed.fromJson(Map<String, dynamic> json) {
    return ThreatFeed(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      source: json['source'] ?? '',
      type: ThreatType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ThreatType.malware,
      ),
      severity: ThreatSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => ThreatSeverity.medium,
      ),
      description: json['description'] ?? '',
      indicators: List<String>.from(json['indicators'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'source': source,
      'type': type.name,
      'severity': severity.name,
      'description': description,
      'indicators': indicators,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'isActive': isActive,
    };
  }
}

class IPReputation {
  final String ipAddress;
  final String reputation;
  final int riskScore;
  final List<String> categories;
  final String country;
  final String organization;
  final DateTime lastSeen;
  final Map<String, dynamic> details;

  IPReputation({
    required this.ipAddress,
    required this.reputation,
    required this.riskScore,
    required this.categories,
    required this.country,
    required this.organization,
    required this.lastSeen,
    required this.details,
  });

  factory IPReputation.fromJson(Map<String, dynamic> json) {
    return IPReputation(
      ipAddress: json['ipAddress'] ?? '',
      reputation: json['reputation'] ?? 'unknown',
      riskScore: json['riskScore'] ?? 0,
      categories: List<String>.from(json['categories'] ?? []),
      country: json['country'] ?? '',
      organization: json['organization'] ?? '',
      lastSeen: DateTime.tryParse(json['lastSeen'] ?? '') ?? DateTime.now(),
      details: Map<String, dynamic>.from(json['details'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ipAddress': ipAddress,
      'reputation': reputation,
      'riskScore': riskScore,
      'categories': categories,
      'country': country,
      'organization': organization,
      'lastSeen': lastSeen.toIso8601String(),
      'details': details,
    };
  }
}

class IOC {
  final String id;
  final String type;
  final String value;
  final ThreatSeverity severity;
  final String source;
  final String description;
  final List<String> tags;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final int confidence;
  final Map<String, dynamic> context;

  IOC({
    required this.id,
    required this.type,
    required this.value,
    required this.severity,
    required this.source,
    required this.description,
    required this.tags,
    required this.firstSeen,
    required this.lastSeen,
    required this.confidence,
    required this.context,
  });

  factory IOC.fromJson(Map<String, dynamic> json) {
    return IOC(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      value: json['value'] ?? '',
      severity: ThreatSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => ThreatSeverity.medium,
      ),
      source: json['source'] ?? '',
      description: json['description'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      firstSeen: DateTime.tryParse(json['firstSeen'] ?? '') ?? DateTime.now(),
      lastSeen: DateTime.tryParse(json['lastSeen'] ?? '') ?? DateTime.now(),
      confidence: json['confidence'] ?? 0,
      context: Map<String, dynamic>.from(json['context'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'value': value,
      'severity': severity.name,
      'source': source,
      'description': description,
      'tags': tags,
      'firstSeen': firstSeen.toIso8601String(),
      'lastSeen': lastSeen.toIso8601String(),
      'confidence': confidence,
      'context': context,
    };
  }
}

class ThreatHuntQuery {
  final String id;
  final String name;
  final String query;
  final String description;
  final List<String> platforms;
  final Map<String, dynamic> parameters;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? lastRun;
  final bool isActive;

  ThreatHuntQuery({
    required this.id,
    required this.name,
    required this.query,
    required this.description,
    required this.platforms,
    required this.parameters,
    required this.createdBy,
    required this.createdAt,
    this.lastRun,
    this.isActive = true,
  });

  factory ThreatHuntQuery.fromJson(Map<String, dynamic> json) {
    return ThreatHuntQuery(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      query: json['query'] ?? '',
      description: json['description'] ?? '',
      platforms: List<String>.from(json['platforms'] ?? []),
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      createdBy: json['createdBy'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      lastRun: json['lastRun'] != null ? DateTime.tryParse(json['lastRun']) : null,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'query': query,
      'description': description,
      'platforms': platforms,
      'parameters': parameters,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'lastRun': lastRun?.toIso8601String(),
      'isActive': isActive,
    };
  }
}

class ThreatHuntResult {
  final String id;
  final String queryId;
  final String queryName;
  final List<Map<String, dynamic>> results;
  final int totalMatches;
  final DateTime executedAt;
  final Duration executionTime;
  final String status;
  final String? error;

  ThreatHuntResult({
    required this.id,
    required this.queryId,
    required this.queryName,
    required this.results,
    required this.totalMatches,
    required this.executedAt,
    required this.executionTime,
    required this.status,
    this.error,
  });

  factory ThreatHuntResult.fromJson(Map<String, dynamic> json) {
    return ThreatHuntResult(
      id: json['id'] ?? '',
      queryId: json['queryId'] ?? '',
      queryName: json['queryName'] ?? '',
      results: List<Map<String, dynamic>>.from(json['results'] ?? []),
      totalMatches: json['totalMatches'] ?? 0,
      executedAt: DateTime.tryParse(json['executedAt'] ?? '') ?? DateTime.now(),
      executionTime: Duration(milliseconds: json['executionTimeMs'] ?? 0),
      status: json['status'] ?? 'unknown',
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'queryId': queryId,
      'queryName': queryName,
      'results': results,
      'totalMatches': totalMatches,
      'executedAt': executedAt.toIso8601String(),
      'executionTimeMs': executionTime.inMilliseconds,
      'status': status,
      'error': error,
    };
  }
}

class ThreatActor {
  final String id;
  final String name;
  final List<String> aliases;
  final String description;
  final List<String> motivations;
  final List<String> capabilities;
  final List<String> targetSectors;
  final List<String> targetCountries;
  final String sophistication;
  final DateTime firstSeen;
  final DateTime lastActivity;
  final Map<String, dynamic> attributes;

  ThreatActor({
    required this.id,
    required this.name,
    required this.aliases,
    required this.description,
    required this.motivations,
    required this.capabilities,
    required this.targetSectors,
    required this.targetCountries,
    required this.sophistication,
    required this.firstSeen,
    required this.lastActivity,
    required this.attributes,
  });

  factory ThreatActor.fromJson(Map<String, dynamic> json) {
    return ThreatActor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      aliases: List<String>.from(json['aliases'] ?? []),
      description: json['description'] ?? '',
      motivations: List<String>.from(json['motivations'] ?? []),
      capabilities: List<String>.from(json['capabilities'] ?? []),
      targetSectors: List<String>.from(json['targetSectors'] ?? []),
      targetCountries: List<String>.from(json['targetCountries'] ?? []),
      sophistication: json['sophistication'] ?? '',
      firstSeen: DateTime.tryParse(json['firstSeen'] ?? '') ?? DateTime.now(),
      lastActivity: DateTime.tryParse(json['lastActivity'] ?? '') ?? DateTime.now(),
      attributes: Map<String, dynamic>.from(json['attributes'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'aliases': aliases,
      'description': description,
      'motivations': motivations,
      'capabilities': capabilities,
      'targetSectors': targetSectors,
      'targetCountries': targetCountries,
      'sophistication': sophistication,
      'firstSeen': firstSeen.toIso8601String(),
      'lastActivity': lastActivity.toIso8601String(),
      'attributes': attributes,
    };
  }
}

class AttackPattern {
  final String id;
  final String name;
  final String description;
  final List<String> killChainPhases;
  final List<String> platforms;
  final List<String> tactics;
  final List<String> techniques;
  final Map<String, dynamic> mitigations;
  final Map<String, dynamic> detections;

  AttackPattern({
    required this.id,
    required this.name,
    required this.description,
    required this.killChainPhases,
    required this.platforms,
    required this.tactics,
    required this.techniques,
    required this.mitigations,
    required this.detections,
  });

  factory AttackPattern.fromJson(Map<String, dynamic> json) {
    return AttackPattern(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      killChainPhases: List<String>.from(json['killChainPhases'] ?? []),
      platforms: List<String>.from(json['platforms'] ?? []),
      tactics: List<String>.from(json['tactics'] ?? []),
      techniques: List<String>.from(json['techniques'] ?? []),
      mitigations: Map<String, dynamic>.from(json['mitigations'] ?? {}),
      detections: Map<String, dynamic>.from(json['detections'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'killChainPhases': killChainPhases,
      'platforms': platforms,
      'tactics': tactics,
      'techniques': techniques,
      'mitigations': mitigations,
      'detections': detections,
    };
  }
}
