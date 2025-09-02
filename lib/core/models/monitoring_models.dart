enum AnomalyType { 
  loginPattern, 
  dataAccess, 
  networkTraffic, 
  systemResource, 
  userBehavior,
  apiUsage,
  geolocation,
  deviceFingerprint
}

enum AnomalySeverity { low, medium, high, critical }
enum MonitoringStatus { active, paused, disabled, error }
enum AlertStatus { new_, acknowledged, investigating, resolved, falsePositive }

class SystemMetric {
  final String id;
  final String name;
  final String category;
  final double value;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final double? threshold;
  final bool isAnomalous;

  SystemMetric({
    required this.id,
    required this.name,
    required this.category,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.metadata = const {},
    this.threshold,
    required this.isAnomalous,
  });

  factory SystemMetric.fromJson(Map<String, dynamic> json) {
    return SystemMetric(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      value: json['value'].toDouble(),
      unit: json['unit'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'] ?? {},
      threshold: json['threshold']?.toDouble(),
      isAnomalous: json['isAnomalous'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'threshold': threshold,
      'isAnomalous': isAnomalous,
    };
  }
}

class AnomalyDetection {
  final String id;
  final AnomalyType type;
  final AnomalySeverity severity;
  final String title;
  final String description;
  final DateTime detectedAt;
  final String userId;
  final String? sessionId;
  final Map<String, dynamic> context;
  final double confidenceScore;
  final List<String> affectedSystems;
  final AlertStatus status;
  final String? assignedTo;
  final DateTime? resolvedAt;
  final String? resolution;

  AnomalyDetection({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.detectedAt,
    required this.userId,
    this.sessionId,
    this.context = const {},
    required this.confidenceScore,
    this.affectedSystems = const [],
    required this.status,
    this.assignedTo,
    this.resolvedAt,
    this.resolution,
  });

  factory AnomalyDetection.fromJson(Map<String, dynamic> json) {
    return AnomalyDetection(
      id: json['id'],
      type: AnomalyType.values.byName(json['type']),
      severity: AnomalySeverity.values.byName(json['severity']),
      title: json['title'],
      description: json['description'],
      detectedAt: DateTime.parse(json['detectedAt']),
      userId: json['userId'],
      sessionId: json['sessionId'],
      context: json['context'] ?? {},
      confidenceScore: json['confidenceScore'].toDouble(),
      affectedSystems: List<String>.from(json['affectedSystems'] ?? []),
      status: AlertStatus.values.byName(json['status']),
      assignedTo: json['assignedTo'],
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
      resolution: json['resolution'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'severity': severity.name,
      'title': title,
      'description': description,
      'detectedAt': detectedAt.toIso8601String(),
      'userId': userId,
      'sessionId': sessionId,
      'context': context,
      'confidenceScore': confidenceScore,
      'affectedSystems': affectedSystems,
      'status': status.name,
      'assignedTo': assignedTo,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolution': resolution,
    };
  }
}

class MonitoringRule {
  final String id;
  final String name;
  final String description;
  final String category;
  final bool isEnabled;
  final Map<String, dynamic> conditions;
  final List<String> actions;
  final AnomalySeverity severity;
  final double threshold;
  final DateTime createdAt;
  final DateTime? lastTriggered;
  final int triggerCount;

  MonitoringRule({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.isEnabled,
    this.conditions = const {},
    this.actions = const [],
    required this.severity,
    required this.threshold,
    required this.createdAt,
    this.lastTriggered,
    required this.triggerCount,
  });

  factory MonitoringRule.fromJson(Map<String, dynamic> json) {
    return MonitoringRule(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      isEnabled: json['isEnabled'],
      conditions: json['conditions'] ?? {},
      actions: List<String>.from(json['actions'] ?? []),
      severity: AnomalySeverity.values.byName(json['severity']),
      threshold: json['threshold'].toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      lastTriggered: json['lastTriggered'] != null ? DateTime.parse(json['lastTriggered']) : null,
      triggerCount: json['triggerCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'isEnabled': isEnabled,
      'conditions': conditions,
      'actions': actions,
      'severity': severity.name,
      'threshold': threshold,
      'createdAt': createdAt.toIso8601String(),
      'lastTriggered': lastTriggered?.toIso8601String(),
      'triggerCount': triggerCount,
    };
  }
}

class RealTimeAlert {
  final String id;
  final String title;
  final String message;
  final AnomalySeverity severity;
  final DateTime timestamp;
  final String source;
  final Map<String, dynamic> data;
  final bool isRead;
  final String? actionUrl;
  final List<String> tags;

  RealTimeAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.timestamp,
    required this.source,
    this.data = const {},
    required this.isRead,
    this.actionUrl,
    this.tags = const [],
  });

  factory RealTimeAlert.fromJson(Map<String, dynamic> json) {
    return RealTimeAlert(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      severity: AnomalySeverity.values.byName(json['severity']),
      timestamp: DateTime.parse(json['timestamp']),
      source: json['source'],
      data: json['data'] ?? {},
      isRead: json['isRead'],
      actionUrl: json['actionUrl'],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'severity': severity.name,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'data': data,
      'isRead': isRead,
      'actionUrl': actionUrl,
      'tags': tags,
    };
  }
}

class SystemHealthMetrics {
  final double cpuUsage;
  final double memoryUsage;
  final double diskUsage;
  final double networkLatency;
  final int activeConnections;
  final int requestsPerSecond;
  final double errorRate;
  final DateTime timestamp;
  final Map<String, double> customMetrics;

  SystemHealthMetrics({
    required this.cpuUsage,
    required this.memoryUsage,
    required this.diskUsage,
    required this.networkLatency,
    required this.activeConnections,
    required this.requestsPerSecond,
    required this.errorRate,
    required this.timestamp,
    this.customMetrics = const {},
  });

  factory SystemHealthMetrics.fromJson(Map<String, dynamic> json) {
    return SystemHealthMetrics(
      cpuUsage: json['cpuUsage'].toDouble(),
      memoryUsage: json['memoryUsage'].toDouble(),
      diskUsage: json['diskUsage'].toDouble(),
      networkLatency: json['networkLatency'].toDouble(),
      activeConnections: json['activeConnections'],
      requestsPerSecond: json['requestsPerSecond'],
      errorRate: json['errorRate'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      customMetrics: Map<String, double>.from(json['customMetrics'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cpuUsage': cpuUsage,
      'memoryUsage': memoryUsage,
      'diskUsage': diskUsage,
      'networkLatency': networkLatency,
      'activeConnections': activeConnections,
      'requestsPerSecond': requestsPerSecond,
      'errorRate': errorRate,
      'timestamp': timestamp.toIso8601String(),
      'customMetrics': customMetrics,
    };
  }
}

class UserBehaviorPattern {
  final String userId;
  final String sessionId;
  final DateTime startTime;
  final DateTime? endTime;
  final List<String> actionsPerformed;
  final Map<String, int> featureUsage;
  final String deviceInfo;
  final String ipAddress;
  final String location;
  final double riskScore;
  final bool isAnomalous;
  final List<String> anomalyReasons;

  UserBehaviorPattern({
    required this.userId,
    required this.sessionId,
    required this.startTime,
    this.endTime,
    this.actionsPerformed = const [],
    this.featureUsage = const {},
    required this.deviceInfo,
    required this.ipAddress,
    required this.location,
    required this.riskScore,
    required this.isAnomalous,
    this.anomalyReasons = const [],
  });

  factory UserBehaviorPattern.fromJson(Map<String, dynamic> json) {
    return UserBehaviorPattern(
      userId: json['userId'],
      sessionId: json['sessionId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      actionsPerformed: List<String>.from(json['actionsPerformed'] ?? []),
      featureUsage: Map<String, int>.from(json['featureUsage'] ?? {}),
      deviceInfo: json['deviceInfo'],
      ipAddress: json['ipAddress'],
      location: json['location'],
      riskScore: json['riskScore'].toDouble(),
      isAnomalous: json['isAnomalous'],
      anomalyReasons: List<String>.from(json['anomalyReasons'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'sessionId': sessionId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'actionsPerformed': actionsPerformed,
      'featureUsage': featureUsage,
      'deviceInfo': deviceInfo,
      'ipAddress': ipAddress,
      'location': location,
      'riskScore': riskScore,
      'isAnomalous': isAnomalous,
      'anomalyReasons': anomalyReasons,
    };
  }
}

class MonitoringDashboard {
  final String id;
  final String name;
  final String description;
  final List<String> widgetIds;
  final Map<String, dynamic> layout;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime lastModified;
  final String createdBy;

  MonitoringDashboard({
    required this.id,
    required this.name,
    required this.description,
    this.widgetIds = const [],
    this.layout = const {},
    required this.isDefault,
    required this.createdAt,
    required this.lastModified,
    required this.createdBy,
  });

  factory MonitoringDashboard.fromJson(Map<String, dynamic> json) {
    return MonitoringDashboard(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      widgetIds: List<String>.from(json['widgetIds'] ?? []),
      layout: json['layout'] ?? {},
      isDefault: json['isDefault'],
      createdAt: DateTime.parse(json['createdAt']),
      lastModified: DateTime.parse(json['lastModified']),
      createdBy: json['createdBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'widgetIds': widgetIds,
      'layout': layout,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'createdBy': createdBy,
    };
  }
}

class AIInsight {
  final String id;
  final String title;
  final String description;
  final String category;
  final double confidence;
  final DateTime generatedAt;
  final Map<String, dynamic> data;
  final List<String> recommendations;
  final String? impact;
  final bool isActionable;

  AIInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.confidence,
    required this.generatedAt,
    this.data = const {},
    this.recommendations = const [],
    this.impact,
    required this.isActionable,
  });

  factory AIInsight.fromJson(Map<String, dynamic> json) {
    return AIInsight(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      confidence: json['confidence'].toDouble(),
      generatedAt: DateTime.parse(json['generatedAt']),
      data: json['data'] ?? {},
      recommendations: List<String>.from(json['recommendations'] ?? []),
      impact: json['impact'],
      isActionable: json['isActionable'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'confidence': confidence,
      'generatedAt': generatedAt.toIso8601String(),
      'data': data,
      'recommendations': recommendations,
      'impact': impact,
      'isActionable': isActionable,
    };
  }
}
