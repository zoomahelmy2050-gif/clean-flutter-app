// Admin-specific model classes and enums

export 'package:device_info_plus/device_info_plus.dart';

// Enums
enum DevicePlatform {
  android,
  ios,
  windows,
  macos,
  linux,
  other,
}

enum DeviceStatus {
  active,
  inactive,
  quarantined,
  wiped,
  pending,
  error,
}

enum DeviceActionType {
  lock,
  wipe,
  resetPassword,
  enableLostMode,
  disableLostMode,
  sync,
  restart,
  shutdown,
  installApp,
  uninstallApp,
  updatePolicy,
  customCommand,
}

enum NotificationChannel {
  email,
  sms,
  push,
  inApp,
  webhook,
  slack,
  teams,
  other,
}

enum NotificationPriority {
  low,
  medium,
  high,
  critical,
}

enum NotificationStatus {
  pending,
  sent,
  delivered,
  failed,
  read,
  acknowledged,
}

// Model classes

enum ThreatSeverity {
  low,
  medium,
  high,
  critical,
}

enum KPITrendStatus {
  improving,
  declining,
  on_track,
  needs_attention,
}

enum MdmEventType {
  // Device lifecycle events
  deviceEnrolled,
  deviceUnenrolled,
  deviceCheckIn,
  deviceCheckOut,
  
  // Compliance events
  complianceCheck,
  complianceViolation,
  complianceStatusChanged,
  
  // Policy events
  policyApplied,
  policyUpdated,
  policyRemoved,
  
  // Device actions
  deviceAction,
  deviceWipe,
  deviceLock,
  deviceUnlock,
  deviceRestart,
  deviceShutdown,
  
  // Application management
  appInstalled,
  appUpdated,
  appRemoved,
  
  // Security events
  securityThreatDetected,
  securityThreatResolved,
  
  // Other events
  errorOccurred,
  infoMessage,
  syncCompleted,
}

enum ForensicAlertSeverity {
  low,
  medium,
  high,
  critical,
}

enum ForensicCaseStatus {
  active,
  pending,
  closed,
  archived,
}

enum ComplianceSeverity {
  low,
  medium,
  high,
  critical,
}

class ComplianceStatus {
  final double complianceScore;
  final int violationCount;
  final DateTime lastCheckTime;

  ComplianceStatus({
    required this.complianceScore,
    required this.violationCount,
    required this.lastCheckTime,
  });
}


enum ForensicCaseType {
  incident,
  investigation,
  compliance,
  security,
}

class MdmResult<T> {
  final bool success;
  final T? data;
  final String? error;
  final String provider;

  MdmResult({
    required this.success,
    this.data,
    this.error,
    required this.provider,
  });
}

class MdmEvent {
  final String id;
  final MdmEventType type;
  final String deviceId;
  final String provider;
  final String title;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  MdmEvent({
    required this.id,
    required this.type,
    required this.deviceId,
    required this.provider,
    required this.title,
    required this.description,
    required this.timestamp,
    this.data = const {},
  });

  factory MdmEvent.fromJson(Map<String, dynamic> json) {
    return MdmEvent(
      id: json['id'],
      type: MdmEventType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => MdmEventType.deviceAction,
      ),
      deviceId: json['deviceId'],
      provider: json['provider'],
      title: json['title'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      data: json['data'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'deviceId': deviceId,
      'provider': provider,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }
}

class ForensicAlert {
  final String id;
  final String title;
  final String description;
  final ForensicAlertSeverity severity;
  final DateTime timestamp;
  final String source;
  final Map<String, dynamic> data;
  final List<String> tags;
  final bool isAcknowledged;

  ForensicAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.timestamp,
    required this.source,
    this.data = const {},
    this.tags = const [],
    this.isAcknowledged = false,
  });

  factory ForensicAlert.fromJson(Map<String, dynamic> json) {
    return ForensicAlert(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      severity: ForensicAlertSeverity.values.firstWhere(
        (e) => e.toString().split('.').last == json['severity'],
        orElse: () => ForensicAlertSeverity.medium,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      source: json['source'],
      data: json['data'] ?? {},
      tags: List<String>.from(json['tags'] ?? []),
      isAcknowledged: json['isAcknowledged'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'severity': severity.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'data': data,
      'tags': tags,
      'isAcknowledged': isAcknowledged,
    };
  }
}

class UserRiskScore {
  final String userId;
  final double score;
  final DateTime lastUpdated;
  final List<String> riskFactors;

  UserRiskScore({
    required this.userId,
    required this.score,
    required this.lastUpdated,
    this.riskFactors = const [],
  });

  factory UserRiskScore.fromJson(Map<String, dynamic> json) {
    return UserRiskScore(
      userId: json['userId'],
      score: json['score'].toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      riskFactors: List<String>.from(json['riskFactors'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'score': score,
      'lastUpdated': lastUpdated.toIso8601String(),
      'riskFactors': riskFactors,
    };
  }
}

class UserPermission {
  final String id;
  final String name;
  final String description;
  final bool isGranted;
  final DateTime? grantedAt;
  final String? grantedBy;

  UserPermission({
    required this.id,
    required this.name,
    required this.description,
    required this.isGranted,
    this.grantedAt,
    this.grantedBy,
  });

  factory UserPermission.fromJson(Map<String, dynamic> json) {
    return UserPermission(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      isGranted: json['isGranted'],
      grantedAt: json['grantedAt'] != null ? DateTime.parse(json['grantedAt']) : null,
      grantedBy: json['grantedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isGranted': isGranted,
      'grantedAt': grantedAt?.toIso8601String(),
      'grantedBy': grantedBy,
    };
  }
}

enum GeographicRegion {
  north_america,
  europe,
  asia_pacific,
  south_america,
  africa,
  oceania,
  middle_east,
}

enum AttackType {
  phishing,
  malware,
  ddos,
  insider_threat,
  sql_injection,
  brute_force,
  other
}

enum ThreatLevel {
  low,
  medium,
  high,
  critical,
  info,
}

class ThreatLocation {
  final String id;
  final double latitude;
  final double longitude;
  final String country;
  final String city;
  final GeographicRegion region;
  final AttackType attackType;
  final ThreatLevel threatLevel;
  final int threatCount;
  final DateTime timestamp;
  final String? ipAddress;
  final DateTime? detectedAt;
  final int? attackCount;
  final bool? isBlocked;
  final Map<String, dynamic> metadata;

  ThreatLocation({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.country,
    required this.city,
    required this.region,
    required this.attackType,
    required this.threatLevel,
    required this.threatCount,
    required this.timestamp,
    this.ipAddress,
    this.detectedAt,
    this.attackCount,
    this.isBlocked,
    this.metadata = const {},
  });

  factory ThreatLocation.fromJson(Map<String, dynamic> json) {
    return ThreatLocation(
      id: json['id'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      country: json['country'],
      city: json['city'],
      region: GeographicRegion.values.firstWhere((e) => e.toString() == 'GeographicRegion.${json['region']}'),
      attackType: AttackType.values.firstWhere((e) => e.toString() == 'AttackType.${json['attackType']}'),
      threatLevel: ThreatLevel.values.firstWhere((e) => e.toString() == 'ThreatLevel.${json['threatLevel']}'),
      threatCount: json['threatCount'],
      timestamp: DateTime.parse(json['timestamp']),
      ipAddress: json['ipAddress'],
      detectedAt: json['detectedAt'] != null ? DateTime.parse(json['detectedAt']) : null,
      attackCount: json['attackCount'],
      isBlocked: json['isBlocked'],
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'country': country,
      'city': city,
      'region': region.toString().split('.').last,
      'attackType': attackType.toString().split('.').last,
      'threatLevel': threatLevel.toString().split('.').last,
      'threatCount': threatCount,
      'timestamp': timestamp.toIso8601String(),
      'ipAddress': ipAddress,
      'detectedAt': detectedAt?.toIso8601String(),
      'attackCount': attackCount,
      'isBlocked': isBlocked,
      'metadata': metadata,
    };
  }
}

class SecurityScoreTrend {
  final String id;
  final DateTime timestamp;
  final double overallScore;
  final double previousScore;
  final double changePercent;
  final Map<String, double> categoryScores;
  final List<String> improvementAreas;
  final List<String> riskFactors;
  final double predictedScore;
  final DateTime predictionDate;
  final List<SecurityScore> scores;

  SecurityScoreTrend({
    required this.id,
    required this.timestamp,
    required this.overallScore,
    required this.previousScore,
    required this.changePercent,
    required this.categoryScores,
    required this.improvementAreas,
    required this.riskFactors,
    required this.predictedScore,
    required this.predictionDate,
    required this.scores,
  });

  factory SecurityScoreTrend.fromJson(Map<String, dynamic> json) {
    return SecurityScoreTrend(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      overallScore: json['overallScore'].toDouble(),
      previousScore: json['previousScore'].toDouble(),
      changePercent: json['changePercent'].toDouble(),
      categoryScores: Map<String, double>.from(json['categoryScores']),
      improvementAreas: List<String>.from(json['improvementAreas']),
      riskFactors: List<String>.from(json['riskFactors']),
      predictedScore: json['predictedScore'].toDouble(),
      predictionDate: DateTime.parse(json['predictionDate']),
      scores: List<SecurityScore>.from(json['scores'].map((x) => SecurityScore.fromJson(x))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'overallScore': overallScore,
      'previousScore': previousScore,
      'changePercent': changePercent,
      'categoryScores': categoryScores,
      'improvementAreas': improvementAreas,
      'riskFactors': riskFactors,
      'predictedScore': predictedScore,
      'predictionDate': predictionDate.toIso8601String(),
      'scores': scores.map((x) => x.toJson()).toList(),
    };
  }
}

class SecurityScore {
  final double score;
  final String category;
  final String description;
  final DateTime timestamp;

  SecurityScore({
    required this.score,
    required this.category,
    required this.description,
    required this.timestamp,
  });

  factory SecurityScore.fromJson(Map<String, dynamic> json) {
    return SecurityScore(
      score: json['score'].toDouble(),
      category: json['category'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'category': category,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class ExecutiveKPI {
  final String id;
  final String name;
  final String description;
  final double currentValue;
  final double target;
  final double previousValue;
  final String unit;
  final String category;
  final ThreatLevel status;
  final DateTime lastUpdated;
  final List<double> trendData;
  final Map<String, double>? breakdown;

  ExecutiveKPI({
    required this.id,
    required this.name,
    required this.description,
    required this.currentValue,
    required this.target,
    required this.previousValue,
    required this.unit,
    required this.category,
    required this.status,
    required this.lastUpdated,
    required this.trendData,
    this.breakdown,
  });

  factory ExecutiveKPI.fromJson(Map<String, dynamic> json) {
    return ExecutiveKPI(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      currentValue: json['currentValue'].toDouble(),
      target: json['target'].toDouble(),
      previousValue: json['previousValue'].toDouble(),
      unit: json['unit'],
      category: json['category'],
      status: ThreatLevel.values.firstWhere((e) => e.toString() == 'ThreatLevel.${json['status']}'),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      trendData: List<double>.from(json['trendData'].map((x) => x.toDouble())),
      breakdown: json['breakdown'] != null ? Map<String, double>.from(json['breakdown'].map((k, v) => MapEntry<String, double>(k, v.toDouble()))) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'currentValue': currentValue,
      'target': target,
      'previousValue': previousValue,
      'unit': unit,
      'category': category,
      'status': status.toString().split('.').last,
      'lastUpdated': lastUpdated.toIso8601String(),
      'trendData': trendData,
      'breakdown': breakdown,
    };
  }
}

class ThreatHunterQuery {
  final String id;
  final String name;
  final String query;
  final String description;
  final List<String> dataSource;
  final DateTime createdAt;
  final String createdBy;
  final bool isActive;
  final String queryLanguage;
  final List<String> tags;
  final int executionCount;
  final DateTime? lastExecuted;
  final bool isSaved;
  final Map<String, dynamic>? parameters;
  final bool isScheduled;
  final String? schedule;

  ThreatHunterQuery({
    required this.id,
    required this.name,
    required this.query,
    required this.description,
    required this.dataSource,
    required this.createdAt,
    required this.createdBy,
    this.isActive = true,
    required this.queryLanguage,
    required this.tags,
    required this.executionCount,
    this.lastExecuted,
    required this.isSaved,
    this.parameters,
    this.isScheduled = false,
    this.schedule,
  });

  factory ThreatHunterQuery.fromJson(Map<String, dynamic> json) {
    return ThreatHunterQuery(
      id: json['id'],
      name: json['name'],
      query: json['query'],
      description: json['description'],
      dataSource: List<String>.from(json['dataSource']),
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: json['createdBy'],
      isActive: json['isActive'],
      queryLanguage: json['queryLanguage'],
      tags: List<String>.from(json['tags']),
      executionCount: json['executionCount'],
      lastExecuted: json['lastExecuted'] != null ? DateTime.parse(json['lastExecuted']) : null,
      isSaved: json['isSaved'],
      parameters: json['parameters'],
      isScheduled: json['isScheduled'],
      schedule: json['schedule'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'query': query,
      'description': description,
      'dataSource': dataSource,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'isActive': isActive,
      'queryLanguage': queryLanguage,
      'tags': tags,
      'executionCount': executionCount,
      'lastExecuted': lastExecuted?.toIso8601String(),
      'isSaved': isSaved,
      'parameters': parameters,
      'isScheduled': isScheduled,
      'schedule': schedule,
    };
  }
}

class ThreatHuntResult {
  final String id;
  final String queryId;
  final String title;
  final String description;
  final ThreatLevel severity;
  final List<String> indicators;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final DateTime executedAt;
  final Duration executionTime;
  final int resultCount;
  final List<Map<String, dynamic>> results;
  final bool isSuccessful;
  final Map<String, dynamic> statistics;

  ThreatHuntResult({
    required this.id,
    required this.queryId,
    required this.title,
    required this.description,
    required this.severity,
    required this.indicators,
    required this.metadata,
    required this.timestamp,
    required this.executedAt,
    required this.executionTime,
    required this.resultCount,
    required this.results,
    required this.isSuccessful,
    required this.statistics,
  });

  factory ThreatHuntResult.fromJson(Map<String, dynamic> json) {
    return ThreatHuntResult(
      id: json['id'],
      queryId: json['queryId'],
      title: json['title'],
      description: json['description'],
      severity: ThreatLevel.values.firstWhere((e) => e.toString() == 'ThreatLevel.${json['severity']}'),
      indicators: List<String>.from(json['indicators']),
      metadata: Map<String, dynamic>.from(json['metadata']),
      timestamp: DateTime.parse(json['timestamp']),
      executedAt: DateTime.parse(json['executedAt']),
      executionTime: Duration(milliseconds: json['executionTime']),
      resultCount: json['resultCount'],
      results: List<Map<String, dynamic>>.from(json['results']),
      isSuccessful: json['isSuccessful'],
      statistics: Map<String, dynamic>.from(json['statistics']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'queryId': queryId,
      'title': title,
      'description': description,
      'severity': severity.toString().split('.').last,
      'indicators': indicators,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'executedAt': executedAt.toIso8601String(),
      'executionTime': executionTime.inMilliseconds,
      'resultCount': resultCount,
      'results': results,
      'isSuccessful': isSuccessful,
      'statistics': statistics,
    };
  }
}

class SecurityOperationsMetrics {
  final String id;
  final DateTime timestamp;
  final int totalThreats;
  final int activeThreatHunts;
  final int resolvedIncidents;
  final int pendingAlerts;
  final double meanTimeToDetection;
  final double meanTimeToResponse;
  final double meanTimeToResolution;
  final Map<AttackType, int> threatsByType;
  final Map<ThreatLevel, int> threatsBySeverity;
  final Map<GeographicRegion, int> threatsByRegion;
  final double systemAvailability;
  final double securityEffectiveness;

  SecurityOperationsMetrics({
    required this.id,
    required this.timestamp,
    required this.totalThreats,
    required this.activeThreatHunts,
    required this.resolvedIncidents,
    required this.pendingAlerts,
    required this.meanTimeToDetection,
    required this.meanTimeToResponse,
    required this.meanTimeToResolution,
    required this.threatsByType,
    required this.threatsBySeverity,
    required this.threatsByRegion,
    required this.systemAvailability,
    required this.securityEffectiveness,
  });

  factory SecurityOperationsMetrics.fromJson(Map<String, dynamic> json) {
    return SecurityOperationsMetrics(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      totalThreats: json['totalThreats'],
      activeThreatHunts: json['activeThreatHunts'],
      resolvedIncidents: json['resolvedIncidents'],
      pendingAlerts: json['pendingAlerts'],
      meanTimeToDetection: json['meanTimeToDetection'].toDouble(),
      meanTimeToResponse: json['meanTimeToResponse'].toDouble(),
      meanTimeToResolution: json['meanTimeToResolution'].toDouble(),
      threatsByType: Map<AttackType, int>.from(json['threatsByType'].map((k, v) => MapEntry(AttackType.values.firstWhere((e) => e.toString() == 'AttackType.${k}'), v))),
      threatsBySeverity: Map<ThreatLevel, int>.from(json['threatsBySeverity'].map((k, v) => MapEntry(ThreatLevel.values.firstWhere((e) => e.toString() == 'ThreatLevel.${k}'), v))),
      threatsByRegion: Map<GeographicRegion, int>.from(json['threatsByRegion'].map((k, v) => MapEntry(GeographicRegion.values.firstWhere((e) => e.toString() == 'GeographicRegion.${k}'), v))),
      systemAvailability: json['systemAvailability'].toDouble(),
      securityEffectiveness: json['securityEffectiveness'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'totalThreats': totalThreats,
      'activeThreatHunts': activeThreatHunts,
      'resolvedIncidents': resolvedIncidents,
      'pendingAlerts': pendingAlerts,
      'meanTimeToDetection': meanTimeToDetection,
      'meanTimeToResponse': meanTimeToResponse,
      'meanTimeToResolution': meanTimeToResolution,
      'threatsByType': threatsByType.map((k, v) => MapEntry(k.toString().split('.').last, v)),
      'threatsBySeverity': threatsBySeverity.map((k, v) => MapEntry(k.toString().split('.').last, v)),
      'threatsByRegion': threatsByRegion.map((k, v) => MapEntry(k.toString().split('.').last, v)),
      'systemAvailability': systemAvailability,
      'securityEffectiveness': securityEffectiveness,
    };
  }
}

class LiveThreatFeed {
  final String id;
  final String source;
  final AttackType type;
  final ThreatLevel severity;
  final String title;
  final String description;
  final DateTime timestamp;
  final List<String> indicators;
  final double confidence;
  final bool isVerified;
  final List<String> tags;

  LiveThreatFeed({
    required this.id,
    required this.source,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.indicators,
    required this.confidence,
    required this.isVerified,
    required this.tags,
  });

  factory LiveThreatFeed.fromJson(Map<String, dynamic> json) {
    return LiveThreatFeed(
      id: json['id'],
      source: json['source'],
      type: AttackType.values.firstWhere((e) => e.toString() == 'AttackType.${json['type']}'),
      severity: ThreatLevel.values.firstWhere((e) => e.toString() == 'ThreatLevel.${json['severity']}'),
      title: json['title'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      indicators: List<String>.from(json['indicators']),
      confidence: json['confidence'].toDouble(),
      isVerified: json['isVerified'],
      tags: List<String>.from(json['tags']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'type': type.toString().split('.').last,
      'severity': severity.toString().split('.').last,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'indicators': indicators,
      'confidence': confidence,
      'isVerified': isVerified,
      'tags': tags,
    };
  }
}
