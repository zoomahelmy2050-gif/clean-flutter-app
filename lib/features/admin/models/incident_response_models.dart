// Security Incident Response Models
class SecurityIncident {
  final String id;
  final String title;
  final String description;
  final String severity;
  final String status;
  final DateTime timestamp;
  final String? assignedTo;
  final List<String> affectedSystems;
  final Map<String, dynamic>? metadata;
  
  SecurityIncident({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.status,
    required this.timestamp,
    this.assignedTo,
    this.affectedSystems = const [],
    this.metadata,
  });
  
  factory SecurityIncident.fromJson(Map<String, dynamic> json) {
    return SecurityIncident(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      severity: json['severity'],
      status: json['status'],
      timestamp: DateTime.parse(json['timestamp']),
      assignedTo: json['assignedTo'],
      affectedSystems: List<String>.from(json['affectedSystems'] ?? []),
      metadata: json['metadata'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'severity': severity,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'assignedTo': assignedTo,
      'affectedSystems': affectedSystems,
      'metadata': metadata,
    };
  }
}

class SecurityEvent {
  final String id;
  final String type;
  final String message;
  final String severity;
  final DateTime timestamp;
  final String? source;
  final Map<String, dynamic>? details;
  
  SecurityEvent({
    required this.id,
    required this.type,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.source,
    this.details,
  });
  
  factory SecurityEvent.fromJson(Map<String, dynamic> json) {
    return SecurityEvent(
      id: json['id'],
      type: json['type'],
      message: json['message'],
      severity: json['severity'],
      timestamp: DateTime.parse(json['timestamp']),
      source: json['source'],
      details: json['details'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'message': message,
      'severity': severity,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'details': details,
    };
  }
}

class ThreatIndicator {
  final String id;
  final String type;
  final String value;
  final String riskLevel;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final String? description;
  final Map<String, dynamic>? metadata;
  
  ThreatIndicator({
    required this.id,
    required this.type,
    required this.value,
    required this.riskLevel,
    required this.firstSeen,
    required this.lastSeen,
    this.description,
    this.metadata,
  });
  
  factory ThreatIndicator.fromJson(Map<String, dynamic> json) {
    return ThreatIndicator(
      id: json['id'],
      type: json['type'],
      value: json['value'],
      riskLevel: json['riskLevel'],
      firstSeen: DateTime.parse(json['firstSeen']),
      lastSeen: DateTime.parse(json['lastSeen']),
      description: json['description'],
      metadata: json['metadata'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'value': value,
      'riskLevel': riskLevel,
      'firstSeen': firstSeen.toIso8601String(),
      'lastSeen': lastSeen.toIso8601String(),
      'description': description,
      'metadata': metadata,
    };
  }
}
