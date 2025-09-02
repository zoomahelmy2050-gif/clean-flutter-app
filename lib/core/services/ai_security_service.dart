import 'dart:async';
import 'dart:math';
import 'dart:developer' as developer;

class AnomalyDetection {
  final String id;
  final String type;
  final double severity;
  final double confidence;
  final Map<String, dynamic> features;
  final DateTime timestamp;
  final String description;

  AnomalyDetection({
    required this.id,
    required this.type,
    required this.severity,
    required this.confidence,
    required this.features,
    required this.timestamp,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'severity': severity,
    'confidence': confidence,
    'features': features,
    'timestamp': timestamp.toIso8601String(),
    'description': description,
  };
}

class ThreatPrediction {
  final String id;
  final String threatType;
  final double probability;
  final DateTime predictedTime;
  final Map<String, dynamic> indicators;
  final List<String> recommendations;

  ThreatPrediction({
    required this.id,
    required this.threatType,
    required this.probability,
    required this.predictedTime,
    required this.indicators,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'threat_type': threatType,
    'probability': probability,
    'predicted_time': predictedTime.toIso8601String(),
    'indicators': indicators,
    'recommendations': recommendations,
  };
}

class BehaviorPattern {
  final String userId;
  final Map<String, double> baseline;
  final Map<String, double> current;
  final double deviationScore;
  final DateTime lastUpdated;

  BehaviorPattern({
    required this.userId,
    required this.baseline,
    required this.current,
    required this.deviationScore,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'baseline': baseline,
    'current': current,
    'deviation_score': deviationScore,
    'last_updated': lastUpdated.toIso8601String(),
  };
}

class MLModel {
  final String id;
  final String name;
  final String type;
  final double accuracy;
  final DateTime trainedAt;
  final Map<String, dynamic> parameters;
  final bool isActive;

  MLModel({
    required this.id,
    required this.name,
    required this.type,
    required this.accuracy,
    required this.trainedAt,
    required this.parameters,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'accuracy': accuracy,
    'trained_at': trainedAt.toIso8601String(),
    'parameters': parameters,
    'is_active': isActive,
  };
}

class AISecurityService {
  static final AISecurityService _instance = AISecurityService._internal();
  factory AISecurityService() => _instance;
  AISecurityService._internal();

  final List<AnomalyDetection> _anomalies = [];
  final List<ThreatPrediction> _predictions = [];
  final Map<String, BehaviorPattern> _behaviorPatterns = {};
  final List<MLModel> _models = [];
  
  final StreamController<AnomalyDetection> _anomalyController = StreamController.broadcast();
  final StreamController<ThreatPrediction> _predictionController = StreamController.broadcast();
  
  Timer? _analysisTimer;
  final Random _random = Random();

  Stream<AnomalyDetection> get anomalyStream => _anomalyController.stream;
  Stream<ThreatPrediction> get predictionStream => _predictionController.stream;

  Future<void> initialize() async {
    await _initializeModels();
    _startContinuousAnalysis();
    
    developer.log('AI Security Service initialized', name: 'AISecurityService');
  }

  Future<void> _initializeModels() async {
    _models.addAll([
      MLModel(
        id: 'anomaly_detector_v1',
        name: 'User Behavior Anomaly Detector',
        type: 'isolation_forest',
        accuracy: 0.92,
        trainedAt: DateTime.now().subtract(const Duration(days: 7)),
        parameters: {
          'contamination': 0.1,
          'n_estimators': 100,
          'max_samples': 256,
        },
      ),
      MLModel(
        id: 'threat_predictor_v1',
        name: 'Threat Prediction Model',
        type: 'lstm',
        accuracy: 0.87,
        trainedAt: DateTime.now().subtract(const Duration(days: 3)),
        parameters: {
          'sequence_length': 50,
          'hidden_units': 128,
          'dropout_rate': 0.2,
        },
      ),
      MLModel(
        id: 'malware_classifier_v1',
        name: 'Malware Classification Model',
        type: 'random_forest',
        accuracy: 0.95,
        trainedAt: DateTime.now().subtract(const Duration(days: 1)),
        parameters: {
          'n_estimators': 200,
          'max_depth': 15,
          'min_samples_split': 5,
        },
      ),
    ]);
  }

  void _startContinuousAnalysis() {
    _analysisTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _performAnomalyDetection();
      _generateThreatPredictions();
      _analyzeBehaviorPatterns();
    });
  }

  Future<AnomalyDetection?> detectAnomaly(Map<String, dynamic> data) async {
    final model = _models.firstWhere((m) => m.type == 'isolation_forest');
    
    // Simulate ML model inference
    final features = _extractFeatures(data);
    final anomalyScore = _calculateAnomalyScore(features);
    
    if (anomalyScore > 0.7) {
      final anomaly = AnomalyDetection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: _classifyAnomalyType(features),
        severity: anomalyScore,
        confidence: model.accuracy,
        features: features,
        timestamp: DateTime.now(),
        description: _generateAnomalyDescription(features, anomalyScore),
      );
      
      _anomalies.add(anomaly);
      _anomalyController.add(anomaly);
      
      developer.log('Anomaly detected: ${anomaly.type} (severity: ${anomaly.severity})', name: 'AISecurityService');
      
      return anomaly;
    }
    
    return null;
  }

  Map<String, double> _extractFeatures(Map<String, dynamic> data) {
    return {
      'login_frequency': (data['login_count'] as num?)?.toDouble() ?? 0.0,
      'session_duration': (data['session_duration'] as num?)?.toDouble() ?? 0.0,
      'failed_attempts': (data['failed_attempts'] as num?)?.toDouble() ?? 0.0,
      'location_change': data['location_changed'] == true ? 1.0 : 0.0,
      'device_change': data['device_changed'] == true ? 1.0 : 0.0,
      'time_of_day': (data['hour'] as num?)?.toDouble() ?? 12.0,
      'data_access_volume': (data['data_volume'] as num?)?.toDouble() ?? 0.0,
    };
  }

  double _calculateAnomalyScore(Map<String, double> features) {
    // Simplified anomaly scoring algorithm
    double score = 0.0;
    
    // Check for suspicious patterns
    if (features['failed_attempts']! > 5) score += 0.3;
    if (features['location_change']! > 0) score += 0.2;
    if (features['device_change']! > 0) score += 0.2;
    if (features['time_of_day']! < 6 || features['time_of_day']! > 22) score += 0.1;
    if (features['data_access_volume']! > 1000) score += 0.2;
    
    // Add some randomness to simulate ML model uncertainty
    score += (_random.nextDouble() - 0.5) * 0.1;
    
    return score.clamp(0.0, 1.0);
  }

  String _classifyAnomalyType(Map<String, double> features) {
    if (features['failed_attempts']! > 5) return 'brute_force_attack';
    if (features['location_change']! > 0 && features['device_change']! > 0) return 'account_takeover';
    if (features['data_access_volume']! > 1000) return 'data_exfiltration';
    if (features['time_of_day']! < 6 || features['time_of_day']! > 22) return 'off_hours_access';
    return 'behavioral_anomaly';
  }

  String _generateAnomalyDescription(Map<String, double> features, double score) {
    final List<String> indicators = [];
    
    if (features['failed_attempts']! > 5) indicators.add('multiple failed login attempts');
    if (features['location_change']! > 0) indicators.add('unusual location');
    if (features['device_change']! > 0) indicators.add('new device');
    if (features['data_access_volume']! > 1000) indicators.add('high data access volume');
    
    return 'Anomaly detected with ${indicators.join(', ')}. Severity: ${(score * 100).toInt()}%';
  }

  Future<List<ThreatPrediction>> predictThreats({
    Duration? timeHorizon,
    double? minProbability,
  }) async {
    final horizon = timeHorizon ?? const Duration(hours: 24);
    final minProb = minProbability ?? 0.5;
    
    final predictions = <ThreatPrediction>[];
    
    // Analyze current threat landscape
    final threatTypes = ['malware', 'phishing', 'ddos', 'data_breach', 'insider_threat'];
    
    for (final threatType in threatTypes) {
      final probability = _calculateThreatProbability(threatType);
      
      if (probability >= minProb) {
        final prediction = ThreatPrediction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          threatType: threatType,
          probability: probability,
          predictedTime: DateTime.now().add(horizon),
          indicators: _getThreatIndicators(threatType),
          recommendations: _getThreatRecommendations(threatType),
        );
        
        predictions.add(prediction);
        _predictionController.add(prediction);
      }
    }
    
    _predictions.addAll(predictions);
    
    developer.log('Generated ${predictions.length} threat predictions', name: 'AISecurityService');
    
    return predictions;
  }

  double _calculateThreatProbability(String threatType) {
    // Simulate ML-based threat probability calculation
    final baseProb = {
      'malware': 0.3,
      'phishing': 0.4,
      'ddos': 0.2,
      'data_breach': 0.25,
      'insider_threat': 0.15,
    }[threatType] ?? 0.1;
    
    // Add temporal and contextual factors
    final hour = DateTime.now().hour;
    double timeFactor = 1.0;
    if (hour < 6 || hour > 22) timeFactor = 1.2; // Higher risk during off-hours
    
    // Add some randomness
    final randomFactor = 0.8 + (_random.nextDouble() * 0.4);
    
    return (baseProb * timeFactor * randomFactor).clamp(0.0, 1.0);
  }

  Map<String, dynamic> _getThreatIndicators(String threatType) {
    switch (threatType) {
      case 'malware':
        return {
          'suspicious_file_activity': 0.8,
          'network_anomalies': 0.6,
          'process_injection': 0.7,
        };
      case 'phishing':
        return {
          'suspicious_emails': 0.9,
          'domain_spoofing': 0.7,
          'credential_harvesting': 0.8,
        };
      case 'ddos':
        return {
          'traffic_spikes': 0.9,
          'connection_anomalies': 0.8,
          'resource_exhaustion': 0.7,
        };
      default:
        return {'general_indicators': 0.5};
    }
  }

  List<String> _getThreatRecommendations(String threatType) {
    switch (threatType) {
      case 'malware':
        return [
          'Update antivirus definitions',
          'Scan all endpoints',
          'Monitor file system activity',
          'Review email attachments',
        ];
      case 'phishing':
        return [
          'Increase email security filtering',
          'Conduct user awareness training',
          'Monitor for credential compromise',
          'Verify suspicious communications',
        ];
      case 'ddos':
        return [
          'Activate DDoS protection',
          'Monitor network traffic',
          'Prepare incident response',
          'Contact ISP if needed',
        ];
      default:
        return ['Monitor security alerts', 'Review access logs'];
    }
  }

  Future<BehaviorPattern> analyzeBehaviorPattern(String userId, List<Map<String, dynamic>> activities) async {
    final features = _extractBehaviorFeatures(activities);
    
    // Get or create baseline
    final existingPattern = _behaviorPatterns[userId];
    final baseline = existingPattern?.baseline ?? _createBaselinePattern(features);
    
    // Calculate deviation
    final deviation = _calculateBehaviorDeviation(baseline, features);
    
    final pattern = BehaviorPattern(
      userId: userId,
      baseline: baseline,
      current: features,
      deviationScore: deviation,
      lastUpdated: DateTime.now(),
    );
    
    _behaviorPatterns[userId] = pattern;
    
    // Check for significant deviations
    if (deviation > 0.7) {
      await detectAnomaly({
        'user_id': userId,
        'behavior_deviation': deviation,
        'pattern_type': 'behavioral',
      });
    }
    
    developer.log('Analyzed behavior pattern for $userId (deviation: $deviation)', name: 'AISecurityService');
    
    return pattern;
  }

  Map<String, double> _extractBehaviorFeatures(List<Map<String, dynamic>> activities) {
    if (activities.isEmpty) return {};
    
    final loginTimes = activities.where((a) => a['type'] == 'login').map((a) => DateTime.parse(a['timestamp'])).toList();
    final sessionDurations = activities.where((a) => a['type'] == 'session').map((a) => a['duration'] as int).toList();
    
    return {
      'avg_login_hour': loginTimes.isNotEmpty ? loginTimes.map((t) => t.hour).reduce((a, b) => a + b) / loginTimes.length : 12.0,
      'avg_session_duration': sessionDurations.isNotEmpty ? sessionDurations.reduce((a, b) => a + b) / sessionDurations.length : 0.0,
      'login_frequency': loginTimes.length.toDouble(),
      'weekend_activity': activities.where((a) => DateTime.parse(a['timestamp']).weekday > 5).length.toDouble(),
    };
  }

  Map<String, double> _createBaselinePattern(Map<String, double> features) {
    // Create baseline from current features (in real implementation, this would use historical data)
    return Map.from(features);
  }

  double _calculateBehaviorDeviation(Map<String, double> baseline, Map<String, double> current) {
    if (baseline.isEmpty || current.isEmpty) return 0.0;
    
    double totalDeviation = 0.0;
    int count = 0;
    
    for (final key in baseline.keys) {
      if (current.containsKey(key)) {
        final baseValue = baseline[key]!;
        final currentValue = current[key]!;
        
        if (baseValue != 0) {
          final deviation = (currentValue - baseValue).abs() / baseValue;
          totalDeviation += deviation;
          count++;
        }
      }
    }
    
    return count > 0 ? (totalDeviation / count).clamp(0.0, 1.0) : 0.0;
  }

  void _performAnomalyDetection() {
    // Simulate continuous anomaly detection
    final mockData = {
      'login_count': _random.nextInt(10),
      'failed_attempts': _random.nextInt(8),
      'location_changed': _random.nextBool(),
      'device_changed': _random.nextBool(),
      'hour': DateTime.now().hour,
      'data_volume': _random.nextInt(2000),
    };
    
    detectAnomaly(mockData);
  }

  void _generateThreatPredictions() {
    predictThreats(
      timeHorizon: const Duration(hours: 6),
      minProbability: 0.6,
    );
  }

  void _analyzeBehaviorPatterns() {
    // Simulate behavior analysis for active users
    for (int i = 0; i < 3; i++) {
      final userId = 'user_$i';
      final mockActivities = List.generate(5, (index) => {
        'type': ['login', 'session', 'action'][_random.nextInt(3)],
        'timestamp': DateTime.now().subtract(Duration(hours: index)).toIso8601String(),
        'duration': _random.nextInt(3600),
      });
      
      analyzeBehaviorPattern(userId, mockActivities);
    }
  }

  Future<Map<String, dynamic>> classifyThreat(Map<String, dynamic> data) async {
    final model = _models.firstWhere((m) => m.type == 'random_forest');
    
    // Simulate threat classification
    final features = _extractThreatFeatures(data);
    final classification = _performThreatClassification(features);
    
    return {
      'threat_type': classification['type'],
      'confidence': classification['confidence'],
      'severity': classification['severity'],
      'model_accuracy': model.accuracy,
      'features_used': features.keys.toList(),
    };
  }

  Map<String, double> _extractThreatFeatures(Map<String, dynamic> data) {
    return {
      'file_entropy': (data['file_entropy'] as num?)?.toDouble() ?? 0.0,
      'network_connections': (data['network_connections'] as num?)?.toDouble() ?? 0.0,
      'api_calls': (data['api_calls'] as num?)?.toDouble() ?? 0.0,
      'registry_modifications': (data['registry_mods'] as num?)?.toDouble() ?? 0.0,
      'process_injections': (data['process_injections'] as num?)?.toDouble() ?? 0.0,
    };
  }

  Map<String, dynamic> _performThreatClassification(Map<String, double> features) {
    // Simplified classification logic
    if (features['file_entropy']! > 0.8) {
      return {'type': 'malware', 'confidence': 0.9, 'severity': 'high'};
    } else if (features['network_connections']! > 100) {
      return {'type': 'botnet', 'confidence': 0.8, 'severity': 'medium'};
    } else if (features['registry_modifications']! > 10) {
      return {'type': 'trojan', 'confidence': 0.85, 'severity': 'high'};
    }
    
    return {'type': 'benign', 'confidence': 0.7, 'severity': 'low'};
  }

  List<AnomalyDetection> getAnomalies({
    String? type,
    DateTime? startTime,
    DateTime? endTime,
    double? minSeverity,
  }) {
    return _anomalies.where((anomaly) {
      if (type != null && anomaly.type != type) return false;
      if (startTime != null && anomaly.timestamp.isBefore(startTime)) return false;
      if (endTime != null && anomaly.timestamp.isAfter(endTime)) return false;
      if (minSeverity != null && anomaly.severity < minSeverity) return false;
      return true;
    }).toList();
  }

  Map<String, dynamic> getAIMetrics() {
    return {
      'total_anomalies': _anomalies.length,
      'active_models': _models.where((m) => m.isActive).length,
      'avg_model_accuracy': _models.map((m) => m.accuracy).reduce((a, b) => a + b) / _models.length,
      'behavior_patterns_tracked': _behaviorPatterns.length,
      'threat_predictions': _predictions.length,
      'last_analysis': DateTime.now().toIso8601String(),
    };
  }

  void dispose() {
    _analysisTimer?.cancel();
    _anomalyController.close();
    _predictionController.close();
  }
}
