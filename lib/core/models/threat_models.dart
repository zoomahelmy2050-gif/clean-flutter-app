enum ThreatSeverity { critical, high, medium, low }
enum IPReputation { malicious, suspicious, clean, unknown }
enum RiskLevel { critical, high, medium, low }
enum AlertSeverity { critical, high, medium, low }
enum AlertType { suspiciousLogin, bruteForce, malwareDetection, dataExfiltration, anomalousActivity }

class ThreatFeed {
  final String id;
  final String title;
  final String description;
  final ThreatSeverity severity;
  final String source;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  ThreatFeed({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.source,
    required this.timestamp,
    this.metadata = const {},
  });

  factory ThreatFeed.fromJson(Map<String, dynamic> json) {
    return ThreatFeed(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      severity: ThreatSeverity.values.byName(json['severity']),
      source: json['source'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'severity': severity.name,
      'source': source,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

class IPReputationResult {
  final String ipAddress;
  final IPReputation reputation;
  final String country;
  final String? provider;
  final bool isBlocked;
  final DateTime checkedAt;
  final List<String> threatCategories;
  final double riskScore;

  IPReputationResult({
    required this.ipAddress,
    required this.reputation,
    required this.country,
    this.provider,
    required this.isBlocked,
    required this.checkedAt,
    this.threatCategories = const [],
    required this.riskScore,
  });

  factory IPReputationResult.fromJson(Map<String, dynamic> json) {
    return IPReputationResult(
      ipAddress: json['ipAddress'],
      reputation: IPReputation.values.byName(json['reputation']),
      country: json['country'],
      provider: json['provider'],
      isBlocked: json['isBlocked'],
      checkedAt: DateTime.parse(json['checkedAt']),
      threatCategories: List<String>.from(json['threatCategories'] ?? []),
      riskScore: json['riskScore'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ipAddress': ipAddress,
      'reputation': reputation.name,
      'country': country,
      'provider': provider,
      'isBlocked': isBlocked,
      'checkedAt': checkedAt.toIso8601String(),
      'threatCategories': threatCategories,
      'riskScore': riskScore,
    };
  }
}

class GeolocationAnomaly {
  final String id;
  final String userEmail;
  final String location;
  final double latitude;
  final double longitude;
  final double distanceFromUsual;
  final RiskLevel riskLevel;
  final DateTime timestamp;
  final String ipAddress;
  final bool isBlocked;

  GeolocationAnomaly({
    required this.id,
    required this.userEmail,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.distanceFromUsual,
    required this.riskLevel,
    required this.timestamp,
    required this.ipAddress,
    required this.isBlocked,
  });

  factory GeolocationAnomaly.fromJson(Map<String, dynamic> json) {
    return GeolocationAnomaly(
      id: json['id'],
      userEmail: json['userEmail'],
      location: json['location'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      distanceFromUsual: json['distanceFromUsual'].toDouble(),
      riskLevel: RiskLevel.values.byName(json['riskLevel']),
      timestamp: DateTime.parse(json['timestamp']),
      ipAddress: json['ipAddress'],
      isBlocked: json['isBlocked'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userEmail': userEmail,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'distanceFromUsual': distanceFromUsual,
      'riskLevel': riskLevel.name,
      'timestamp': timestamp.toIso8601String(),
      'ipAddress': ipAddress,
      'isBlocked': isBlocked,
    };
  }
}

class ThreatAlert {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final AlertType type;
  final DateTime timestamp;
  final String? userEmail;
  final String? ipAddress;
  final bool isAcknowledged;
  final Map<String, dynamic> metadata;

  ThreatAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.type,
    required this.timestamp,
    this.userEmail,
    this.ipAddress,
    required this.isAcknowledged,
    this.metadata = const {},
  });

  factory ThreatAlert.fromJson(Map<String, dynamic> json) {
    return ThreatAlert(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      severity: AlertSeverity.values.byName(json['severity']),
      type: AlertType.values.byName(json['type']),
      timestamp: DateTime.parse(json['timestamp']),
      userEmail: json['userEmail'],
      ipAddress: json['ipAddress'],
      isAcknowledged: json['isAcknowledged'],
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'severity': severity.name,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'userEmail': userEmail,
      'ipAddress': ipAddress,
      'isAcknowledged': isAcknowledged,
      'metadata': metadata,
    };
  }
}

class UserRiskProfile {
  final String userEmail;
  final double riskScore;
  final RiskLevel riskLevel;
  final DateTime lastUpdated;
  final List<RiskFactor> riskFactors;
  final List<RiskScoreHistory> scoreHistory;

  UserRiskProfile({
    required this.userEmail,
    required this.riskScore,
    required this.riskLevel,
    required this.lastUpdated,
    this.riskFactors = const [],
    this.scoreHistory = const [],
  });

  factory UserRiskProfile.fromJson(Map<String, dynamic> json) {
    return UserRiskProfile(
      userEmail: json['userEmail'],
      riskScore: json['riskScore'].toDouble(),
      riskLevel: RiskLevel.values.byName(json['riskLevel']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      riskFactors: (json['riskFactors'] as List?)
          ?.map((e) => RiskFactor.fromJson(e))
          .toList() ?? [],
      scoreHistory: (json['scoreHistory'] as List?)
          ?.map((e) => RiskScoreHistory.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userEmail': userEmail,
      'riskScore': riskScore,
      'riskLevel': riskLevel.name,
      'lastUpdated': lastUpdated.toIso8601String(),
      'riskFactors': riskFactors.map((e) => e.toJson()).toList(),
      'scoreHistory': scoreHistory.map((e) => e.toJson()).toList(),
    };
  }
}

class RiskFactor {
  final String type;
  final String description;
  final double impact;
  final DateTime detectedAt;

  RiskFactor({
    required this.type,
    required this.description,
    required this.impact,
    required this.detectedAt,
  });

  factory RiskFactor.fromJson(Map<String, dynamic> json) {
    return RiskFactor(
      type: json['type'],
      description: json['description'],
      impact: json['impact'].toDouble(),
      detectedAt: DateTime.parse(json['detectedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'impact': impact,
      'detectedAt': detectedAt.toIso8601String(),
    };
  }
}

class RiskScoreHistory {
  final DateTime timestamp;
  final double score;
  final String reason;

  RiskScoreHistory({
    required this.timestamp,
    required this.score,
    required this.reason,
  });

  factory RiskScoreHistory.fromJson(Map<String, dynamic> json) {
    return RiskScoreHistory(
      timestamp: DateTime.parse(json['timestamp']),
      score: json['score'].toDouble(),
      reason: json['reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'score': score,
      'reason': reason,
    };
  }
}

class SecurityIncident {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final IncidentStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String assignedTo;
  final List<String> affectedUsers;
  final List<IncidentAction> actions;
  final Map<String, dynamic> metadata;

  SecurityIncident({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    required this.assignedTo,
    this.affectedUsers = const [],
    this.actions = const [],
    this.metadata = const {},
  });

  factory SecurityIncident.fromJson(Map<String, dynamic> json) {
    return SecurityIncident(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      severity: AlertSeverity.values.byName(json['severity']),
      status: IncidentStatus.values.byName(json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
      assignedTo: json['assignedTo'],
      affectedUsers: List<String>.from(json['affectedUsers'] ?? []),
      actions: (json['actions'] as List?)
          ?.map((e) => IncidentAction.fromJson(e))
          .toList() ?? [],
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'severity': severity.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'assignedTo': assignedTo,
      'affectedUsers': affectedUsers,
      'actions': actions.map((e) => e.toJson()).toList(),
      'metadata': metadata,
    };
  }
}

enum IncidentStatus { open, investigating, resolved, closed }

class IncidentAction {
  final String id;
  final String action;
  final String performedBy;
  final DateTime timestamp;
  final String notes;

  IncidentAction({
    required this.id,
    required this.action,
    required this.performedBy,
    required this.timestamp,
    required this.notes,
  });

  factory IncidentAction.fromJson(Map<String, dynamic> json) {
    return IncidentAction(
      id: json['id'],
      action: json['action'],
      performedBy: json['performedBy'],
      timestamp: DateTime.parse(json['timestamp']),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'performedBy': performedBy,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }
}
