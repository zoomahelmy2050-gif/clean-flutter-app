// User Management Models

class UserRiskScore {
  final String userId;
  final double score;
  final String level;
  final List<String> riskFactors;
  final Map<String, dynamic> details;
  final DateTime calculatedAt;
  final DateTime expiresAt;

  UserRiskScore({
    required this.userId,
    required this.score,
    required this.level,
    required this.riskFactors,
    required this.details,
    required this.calculatedAt,
    required this.expiresAt,
  });

  factory UserRiskScore.fromJson(Map<String, dynamic> json) {
    return UserRiskScore(
      userId: json['userId'] ?? '',
      score: (json['score'] ?? 0.0).toDouble(),
      level: json['level'] ?? 'low',
      riskFactors: List<String>.from(json['riskFactors'] ?? []),
      details: Map<String, dynamic>.from(json['details'] ?? {}),
      calculatedAt: DateTime.tryParse(json['calculatedAt'] ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(json['expiresAt'] ?? '') ?? DateTime.now().add(const Duration(hours: 24)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'score': score,
      'level': level,
      'riskFactors': riskFactors,
      'details': details,
      'calculatedAt': calculatedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }
}

class UserPermission {
  final String id;
  final String userId;
  final String resource;
  final String action;
  final bool granted;
  final String? condition;
  final DateTime grantedAt;
  final DateTime? expiresAt;
  final String grantedBy;

  UserPermission({
    required this.id,
    required this.userId,
    required this.resource,
    required this.action,
    required this.granted,
    this.condition,
    required this.grantedAt,
    this.expiresAt,
    required this.grantedBy,
  });

  factory UserPermission.fromJson(Map<String, dynamic> json) {
    return UserPermission(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      resource: json['resource'] ?? '',
      action: json['action'] ?? '',
      granted: json['granted'] ?? false,
      condition: json['condition'],
      grantedAt: DateTime.tryParse(json['grantedAt'] ?? '') ?? DateTime.now(),
      expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt']) : null,
      grantedBy: json['grantedBy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'resource': resource,
      'action': action,
      'granted': granted,
      'condition': condition,
      'grantedAt': grantedAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'grantedBy': grantedBy,
    };
  }
}
