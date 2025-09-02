enum AnalyticsMetricType { 
  security, 
  performance, 
  user_behavior, 
  system_health, 
  compliance,
  threat_detection,
  access_control,
  data_protection
}

enum TrendDirection { up, down, stable }
enum AlertSeverity { low, medium, high, critical }
enum ReportFrequency { realtime, hourly, daily, weekly, monthly }

class SecurityMetric {
  final String id;
  final String name;
  final String category;
  final double value;
  final double previousValue;
  final String unit;
  final TrendDirection trend;
  final double changePercentage;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final double? threshold;
  final bool isAnomalous;

  SecurityMetric({
    required this.id,
    required this.name,
    required this.category,
    required this.value,
    required this.previousValue,
    required this.unit,
    required this.trend,
    required this.changePercentage,
    required this.timestamp,
    this.metadata = const {},
    this.threshold,
    required this.isAnomalous,
  });

  factory SecurityMetric.fromJson(Map<String, dynamic> json) {
    return SecurityMetric(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      value: json['value'].toDouble(),
      previousValue: json['previousValue'].toDouble(),
      unit: json['unit'],
      trend: TrendDirection.values.byName(json['trend']),
      changePercentage: json['changePercentage'].toDouble(),
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
      'previousValue': previousValue,
      'unit': unit,
      'trend': trend.name,
      'changePercentage': changePercentage,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'threshold': threshold,
      'isAnomalous': isAnomalous,
    };
  }
}

class SecurityTrend {
  final String metricId;
  final List<DataPoint> dataPoints;
  final TrendDirection overallTrend;
  final double trendStrength;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, dynamic> analysis;

  SecurityTrend({
    required this.metricId,
    required this.dataPoints,
    required this.overallTrend,
    required this.trendStrength,
    required this.startDate,
    required this.endDate,
    this.analysis = const {},
  });

  factory SecurityTrend.fromJson(Map<String, dynamic> json) {
    return SecurityTrend(
      metricId: json['metricId'],
      dataPoints: (json['dataPoints'] as List)
          .map((e) => DataPoint.fromJson(e))
          .toList(),
      overallTrend: TrendDirection.values.byName(json['overallTrend']),
      trendStrength: json['trendStrength'].toDouble(),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      analysis: json['analysis'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metricId': metricId,
      'dataPoints': dataPoints.map((e) => e.toJson()).toList(),
      'overallTrend': overallTrend.name,
      'trendStrength': trendStrength,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'analysis': analysis,
    };
  }
}

class DataPoint {
  final DateTime timestamp;
  final double value;
  final Map<String, dynamic> metadata;

  DataPoint({
    required this.timestamp,
    required this.value,
    this.metadata = const {},
  });

  factory DataPoint.fromJson(Map<String, dynamic> json) {
    return DataPoint(
      timestamp: DateTime.parse(json['timestamp']),
      value: json['value'].toDouble(),
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'value': value,
      'metadata': metadata,
    };
  }
}

class SecurityAlert {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final String category;
  final DateTime triggeredAt;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final bool isResolved;
  final Map<String, dynamic> context;
  final List<String> affectedSystems;
  final String? recommendedAction;

  SecurityAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.category,
    required this.triggeredAt,
    this.resolvedBy,
    this.resolvedAt,
    required this.isResolved,
    this.context = const {},
    this.affectedSystems = const [],
    this.recommendedAction,
  });

  factory SecurityAlert.fromJson(Map<String, dynamic> json) {
    return SecurityAlert(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      severity: AlertSeverity.values.byName(json['severity']),
      category: json['category'],
      triggeredAt: DateTime.parse(json['triggeredAt']),
      resolvedBy: json['resolvedBy'],
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
      isResolved: json['isResolved'],
      context: json['context'] ?? {},
      affectedSystems: List<String>.from(json['affectedSystems'] ?? []),
      recommendedAction: json['recommendedAction'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'severity': severity.name,
      'category': category,
      'triggeredAt': triggeredAt.toIso8601String(),
      'resolvedBy': resolvedBy,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'isResolved': isResolved,
      'context': context,
      'affectedSystems': affectedSystems,
      'recommendedAction': recommendedAction,
    };
  }
}

class AnalyticsReport {
  final String id;
  final String title;
  final String description;
  final AnalyticsMetricType type;
  final ReportFrequency frequency;
  final DateTime generatedAt;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Map<String, dynamic> summary;
  final List<SecurityMetric> metrics;
  final List<SecurityTrend> trends;
  final List<SecurityAlert> alerts;
  final Map<String, dynamic> insights;
  final List<String> recommendations;

  AnalyticsReport({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.frequency,
    required this.generatedAt,
    required this.periodStart,
    required this.periodEnd,
    this.summary = const {},
    this.metrics = const [],
    this.trends = const [],
    this.alerts = const [],
    this.insights = const {},
    this.recommendations = const [],
  });

  factory AnalyticsReport.fromJson(Map<String, dynamic> json) {
    return AnalyticsReport(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: AnalyticsMetricType.values.byName(json['type']),
      frequency: ReportFrequency.values.byName(json['frequency']),
      generatedAt: DateTime.parse(json['generatedAt']),
      periodStart: DateTime.parse(json['periodStart']),
      periodEnd: DateTime.parse(json['periodEnd']),
      summary: json['summary'] ?? {},
      metrics: (json['metrics'] as List?)
          ?.map((e) => SecurityMetric.fromJson(e))
          .toList() ?? [],
      trends: (json['trends'] as List?)
          ?.map((e) => SecurityTrend.fromJson(e))
          .toList() ?? [],
      alerts: (json['alerts'] as List?)
          ?.map((e) => SecurityAlert.fromJson(e))
          .toList() ?? [],
      insights: json['insights'] ?? {},
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'frequency': frequency.name,
      'generatedAt': generatedAt.toIso8601String(),
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'summary': summary,
      'metrics': metrics.map((e) => e.toJson()).toList(),
      'trends': trends.map((e) => e.toJson()).toList(),
      'alerts': alerts.map((e) => e.toJson()).toList(),
      'insights': insights,
      'recommendations': recommendations,
    };
  }
}

class PredictiveModel {
  final String id;
  final String name;
  final String description;
  final String modelType;
  final double accuracy;
  final double confidence;
  final DateTime trainedAt;
  final DateTime lastUpdated;
  final Map<String, dynamic> parameters;
  final List<String> inputFeatures;
  final Map<String, dynamic> performance;

  PredictiveModel({
    required this.id,
    required this.name,
    required this.description,
    required this.modelType,
    required this.accuracy,
    required this.confidence,
    required this.trainedAt,
    required this.lastUpdated,
    this.parameters = const {},
    this.inputFeatures = const [],
    this.performance = const {},
  });

  factory PredictiveModel.fromJson(Map<String, dynamic> json) {
    return PredictiveModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      modelType: json['modelType'],
      accuracy: json['accuracy'].toDouble(),
      confidence: json['confidence'].toDouble(),
      trainedAt: DateTime.parse(json['trainedAt']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      parameters: json['parameters'] ?? {},
      inputFeatures: List<String>.from(json['inputFeatures'] ?? []),
      performance: json['performance'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'modelType': modelType,
      'accuracy': accuracy,
      'confidence': confidence,
      'trainedAt': trainedAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'parameters': parameters,
      'inputFeatures': inputFeatures,
      'performance': performance,
    };
  }
}

class SecurityPrediction {
  final String id;
  final String modelId;
  final String predictionType;
  final Map<String, dynamic> prediction;
  final double confidence;
  final DateTime predictedAt;
  final DateTime? validUntil;
  final Map<String, dynamic> inputData;
  final List<String> riskFactors;
  final String? recommendedAction;

  SecurityPrediction({
    required this.id,
    required this.modelId,
    required this.predictionType,
    required this.prediction,
    required this.confidence,
    required this.predictedAt,
    this.validUntil,
    this.inputData = const {},
    this.riskFactors = const [],
    this.recommendedAction,
  });

  factory SecurityPrediction.fromJson(Map<String, dynamic> json) {
    return SecurityPrediction(
      id: json['id'],
      modelId: json['modelId'],
      predictionType: json['predictionType'],
      prediction: json['prediction'],
      confidence: json['confidence'].toDouble(),
      predictedAt: DateTime.parse(json['predictedAt']),
      validUntil: json['validUntil'] != null ? DateTime.parse(json['validUntil']) : null,
      inputData: json['inputData'] ?? {},
      riskFactors: List<String>.from(json['riskFactors'] ?? []),
      recommendedAction: json['recommendedAction'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'modelId': modelId,
      'predictionType': predictionType,
      'prediction': prediction,
      'confidence': confidence,
      'predictedAt': predictedAt.toIso8601String(),
      'validUntil': validUntil?.toIso8601String(),
      'inputData': inputData,
      'riskFactors': riskFactors,
      'recommendedAction': recommendedAction,
    };
  }
}

class AnalyticsDashboard {
  final String id;
  final String name;
  final String description;
  final List<String> widgetIds;
  final Map<String, dynamic> layout;
  final DateTime createdAt;
  final DateTime lastModified;
  final String createdBy;
  final bool isDefault;
  final List<String> sharedWith;

  AnalyticsDashboard({
    required this.id,
    required this.name,
    required this.description,
    this.widgetIds = const [],
    this.layout = const {},
    required this.createdAt,
    required this.lastModified,
    required this.createdBy,
    required this.isDefault,
    this.sharedWith = const [],
  });

  factory AnalyticsDashboard.fromJson(Map<String, dynamic> json) {
    return AnalyticsDashboard(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      widgetIds: List<String>.from(json['widgetIds'] ?? []),
      layout: json['layout'] ?? {},
      createdAt: DateTime.parse(json['createdAt']),
      lastModified: DateTime.parse(json['lastModified']),
      createdBy: json['createdBy'],
      isDefault: json['isDefault'],
      sharedWith: List<String>.from(json['sharedWith'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'widgetIds': widgetIds,
      'layout': layout,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'createdBy': createdBy,
      'isDefault': isDefault,
      'sharedWith': sharedWith,
    };
  }
}

class CorrelationRule {
  final String id;
  final String name;
  final String description;
  final List<String> conditions;
  final String action;
  final AlertSeverity severity;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime? lastTriggered;
  final int triggerCount;
  final Map<String, dynamic> parameters;

  CorrelationRule({
    required this.id,
    required this.name,
    required this.description,
    required this.conditions,
    required this.action,
    required this.severity,
    required this.isEnabled,
    required this.createdAt,
    this.lastTriggered,
    required this.triggerCount,
    this.parameters = const {},
  });

  factory CorrelationRule.fromJson(Map<String, dynamic> json) {
    return CorrelationRule(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      conditions: List<String>.from(json['conditions']),
      action: json['action'],
      severity: AlertSeverity.values.byName(json['severity']),
      isEnabled: json['isEnabled'],
      createdAt: DateTime.parse(json['createdAt']),
      lastTriggered: json['lastTriggered'] != null ? DateTime.parse(json['lastTriggered']) : null,
      triggerCount: json['triggerCount'],
      parameters: json['parameters'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'conditions': conditions,
      'action': action,
      'severity': severity.name,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toIso8601String(),
      'lastTriggered': lastTriggered?.toIso8601String(),
      'triggerCount': triggerCount,
      'parameters': parameters,
    };
  }
}
