enum ThreatLevel { low, medium, high, critical }
enum AttackType { 
  brute_force, 
  ddos, 
  malware, 
  phishing, 
  sql_injection, 
  xss, 
  ransomware, 
  data_breach,
  insider_threat,
  advanced_persistent_threat
}
enum GeographicRegion { 
  north_america, 
  south_america, 
  europe, 
  asia_pacific, 
  middle_east, 
  africa, 
  oceania 
}

class ThreatLocation {
  final String id;
  final double latitude;
  final double longitude;
  final String country;
  final String city;
  final GeographicRegion region;
  final String ipAddress;
  final AttackType attackType;
  final ThreatLevel threatLevel;
  final DateTime detectedAt;
  final int attackCount;
  final bool isBlocked;
  final Map<String, dynamic> metadata;

  ThreatLocation({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.country,
    required this.city,
    required this.region,
    required this.ipAddress,
    required this.attackType,
    required this.threatLevel,
    required this.detectedAt,
    this.attackCount = 1,
    this.isBlocked = false,
    this.metadata = const {},
  });

  factory ThreatLocation.fromJson(Map<String, dynamic> json) {
    return ThreatLocation(
      id: json['id'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      country: json['country'],
      city: json['city'],
      region: GeographicRegion.values.byName(json['region']),
      ipAddress: json['ipAddress'],
      attackType: AttackType.values.byName(json['attackType']),
      threatLevel: ThreatLevel.values.byName(json['threatLevel']),
      detectedAt: DateTime.parse(json['detectedAt']),
      attackCount: json['attackCount'] ?? 1,
      isBlocked: json['isBlocked'] ?? false,
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
      'region': region.name,
      'ipAddress': ipAddress,
      'attackType': attackType.name,
      'threatLevel': threatLevel.name,
      'detectedAt': detectedAt.toIso8601String(),
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
  final Map<String, dynamic> metrics;

  SecurityScoreTrend({
    required this.id,
    required this.timestamp,
    required this.overallScore,
    required this.previousScore,
    required this.changePercent,
    this.categoryScores = const {},
    this.improvementAreas = const [],
    this.riskFactors = const [],
    required this.predictedScore,
    required this.predictionDate,
    this.metrics = const {},
  });

  factory SecurityScoreTrend.fromJson(Map<String, dynamic> json) {
    return SecurityScoreTrend(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      overallScore: json['overallScore'].toDouble(),
      previousScore: json['previousScore'].toDouble(),
      changePercent: json['changePercent'].toDouble(),
      categoryScores: Map<String, double>.from(json['categoryScores'] ?? {}),
      improvementAreas: List<String>.from(json['improvementAreas'] ?? []),
      riskFactors: List<String>.from(json['riskFactors'] ?? []),
      predictedScore: json['predictedScore'].toDouble(),
      predictionDate: DateTime.parse(json['predictionDate']),
      metrics: json['metrics'] ?? {},
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
      'metrics': metrics,
    };
  }
}

class ThreatHuntQuery {
  final String id;
  final String name;
  final String description;
  final String query;
  final String queryLanguage;
  final List<String> dataSource;
  final DateTime createdAt;
  final String createdBy;
  final DateTime? lastExecuted;
  final int executionCount;
  final Map<String, dynamic> parameters;
  final List<String> tags;
  final bool isSaved;
  final bool isScheduled;
  final String? schedule;

  ThreatHuntQuery({
    required this.id,
    required this.name,
    required this.description,
    required this.query,
    required this.queryLanguage,
    this.dataSource = const [],
    required this.createdAt,
    required this.createdBy,
    this.lastExecuted,
    this.executionCount = 0,
    this.parameters = const {},
    this.tags = const [],
    this.isSaved = false,
    this.isScheduled = false,
    this.schedule,
  });

  factory ThreatHuntQuery.fromJson(Map<String, dynamic> json) {
    return ThreatHuntQuery(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      query: json['query'],
      queryLanguage: json['queryLanguage'],
      dataSource: List<String>.from(json['dataSource'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: json['createdBy'],
      lastExecuted: json['lastExecuted'] != null ? DateTime.parse(json['lastExecuted']) : null,
      executionCount: json['executionCount'] ?? 0,
      parameters: json['parameters'] ?? {},
      tags: List<String>.from(json['tags'] ?? []),
      isSaved: json['isSaved'] ?? false,
      isScheduled: json['isScheduled'] ?? false,
      schedule: json['schedule'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'query': query,
      'queryLanguage': queryLanguage,
      'dataSource': dataSource,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'lastExecuted': lastExecuted?.toIso8601String(),
      'executionCount': executionCount,
      'parameters': parameters,
      'tags': tags,
      'isSaved': isSaved,
      'isScheduled': isScheduled,
      'schedule': schedule,
    };
  }
}

class ThreatHuntResult {
  final String id;
  final String queryId;
  final DateTime executedAt;
  final Duration executionTime;
  final int resultCount;
  final List<Map<String, dynamic>> results;
  final Map<String, dynamic> statistics;
  final List<String> warnings;
  final String? errorMessage;
  final bool isSuccessful;
  final Map<String, dynamic> metadata;

  ThreatHuntResult({
    required this.id,
    required this.queryId,
    required this.executedAt,
    required this.executionTime,
    required this.resultCount,
    this.results = const [],
    this.statistics = const {},
    this.warnings = const [],
    this.errorMessage,
    required this.isSuccessful,
    this.metadata = const {},
  });

  factory ThreatHuntResult.fromJson(Map<String, dynamic> json) {
    return ThreatHuntResult(
      id: json['id'],
      queryId: json['queryId'],
      executedAt: DateTime.parse(json['executedAt']),
      executionTime: Duration(milliseconds: json['executionTime']),
      resultCount: json['resultCount'],
      results: List<Map<String, dynamic>>.from(json['results'] ?? []),
      statistics: json['statistics'] ?? {},
      warnings: List<String>.from(json['warnings'] ?? []),
      errorMessage: json['errorMessage'],
      isSuccessful: json['isSuccessful'],
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'queryId': queryId,
      'executedAt': executedAt.toIso8601String(),
      'executionTime': executionTime.inMilliseconds,
      'resultCount': resultCount,
      'results': results,
      'statistics': statistics,
      'warnings': warnings,
      'errorMessage': errorMessage,
      'isSuccessful': isSuccessful,
      'metadata': metadata,
    };
  }
}

class ExecutiveKPI {
  final String id;
  final String name;
  final String description;
  final double currentValue;
  final double targetValue;
  final double previousValue;
  final String unit;
  final String category;
  final ThreatLevel riskLevel;
  final DateTime lastUpdated;
  final List<double> trendData;
  final String status;
  final Map<String, dynamic> breakdown;

  ExecutiveKPI({
    required this.id,
    required this.name,
    required this.description,
    required this.currentValue,
    required this.targetValue,
    required this.previousValue,
    required this.unit,
    required this.category,
    required this.riskLevel,
    required this.lastUpdated,
    this.trendData = const [],
    required this.status,
    this.breakdown = const {},
  });

  factory ExecutiveKPI.fromJson(Map<String, dynamic> json) {
    return ExecutiveKPI(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      currentValue: json['currentValue'].toDouble(),
      targetValue: json['targetValue'].toDouble(),
      previousValue: json['previousValue'].toDouble(),
      unit: json['unit'],
      category: json['category'],
      riskLevel: ThreatLevel.values.byName(json['riskLevel']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      trendData: List<double>.from(json['trendData'] ?? []),
      status: json['status'],
      breakdown: json['breakdown'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'previousValue': previousValue,
      'unit': unit,
      'category': category,
      'riskLevel': riskLevel.name,
      'lastUpdated': lastUpdated.toIso8601String(),
      'trendData': trendData,
      'status': status,
      'breakdown': breakdown,
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
    this.threatsByType = const {},
    this.threatsBySeverity = const {},
    this.threatsByRegion = const {},
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
      threatsByType: Map<AttackType, int>.from(
        (json['threatsByType'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(AttackType.values.byName(key), value),
        ) ?? {},
      ),
      threatsBySeverity: Map<ThreatLevel, int>.from(
        (json['threatsBySeverity'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(ThreatLevel.values.byName(key), value),
        ) ?? {},
      ),
      threatsByRegion: Map<GeographicRegion, int>.from(
        (json['threatsByRegion'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(GeographicRegion.values.byName(key), value),
        ) ?? {},
      ),
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
      'threatsByType': threatsByType.map((key, value) => MapEntry(key.name, value)),
      'threatsBySeverity': threatsBySeverity.map((key, value) => MapEntry(key.name, value)),
      'threatsByRegion': threatsByRegion.map((key, value) => MapEntry(key.name, value)),
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
  final Map<String, dynamic> attributes;
  final bool isVerified;
  final double confidence;
  final List<String> tags;

  LiveThreatFeed({
    required this.id,
    required this.source,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.timestamp,
    this.indicators = const [],
    this.attributes = const {},
    this.isVerified = false,
    required this.confidence,
    this.tags = const [],
  });

  factory LiveThreatFeed.fromJson(Map<String, dynamic> json) {
    return LiveThreatFeed(
      id: json['id'],
      source: json['source'],
      type: AttackType.values.byName(json['type']),
      severity: ThreatLevel.values.byName(json['severity']),
      title: json['title'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      indicators: List<String>.from(json['indicators'] ?? []),
      attributes: json['attributes'] ?? {},
      isVerified: json['isVerified'] ?? false,
      confidence: json['confidence'].toDouble(),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'type': type.name,
      'severity': severity.name,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'indicators': indicators,
      'attributes': attributes,
      'isVerified': isVerified,
      'confidence': confidence,
      'tags': tags,
    };
  }
}
