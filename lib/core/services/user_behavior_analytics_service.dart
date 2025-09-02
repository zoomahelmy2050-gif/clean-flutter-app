import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BehaviorPattern {
  loginTimes,
  sessionDuration,
  featureUsage,
  navigationFlow,
  deviceUsage,
  locationAccess,
}

enum AnomalyType {
  timeAnomaly,
  locationAnomaly,
  deviceAnomaly,
  usageAnomaly,
  navigationAnomaly,
}

class UserBehaviorEvent {
  final String id;
  final String userId;
  final String eventType;
  final DateTime timestamp;
  final Map<String, dynamic> properties;
  final String? sessionId;
  final String? deviceId;
  final String? location;

  UserBehaviorEvent({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.timestamp,
    required this.properties,
    this.sessionId,
    this.deviceId,
    this.location,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'eventType': eventType,
    'timestamp': timestamp.toIso8601String(),
    'properties': properties,
    'sessionId': sessionId,
    'deviceId': deviceId,
    'location': location,
  };

  factory UserBehaviorEvent.fromJson(Map<String, dynamic> json) {
    return UserBehaviorEvent(
      id: json['id'],
      userId: json['userId'],
      eventType: json['eventType'],
      timestamp: DateTime.parse(json['timestamp']),
      properties: Map<String, dynamic>.from(json['properties']),
      sessionId: json['sessionId'],
      deviceId: json['deviceId'],
      location: json['location'],
    );
  }
}

class BehaviorAnomaly {
  final String id;
  final String userId;
  final AnomalyType type;
  final String description;
  final double severity;
  final DateTime detectedAt;
  final Map<String, dynamic> context;
  final double confidence;
  final bool resolved;

  BehaviorAnomaly({
    required this.id,
    required this.userId,
    required this.type,
    required this.description,
    required this.severity,
    required this.detectedAt,
    required this.context,
    required this.confidence,
    this.resolved = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'type': type.name,
    'description': description,
    'severity': severity,
    'detectedAt': detectedAt.toIso8601String(),
    'context': context,
    'confidence': confidence,
    'resolved': resolved,
  };

  factory BehaviorAnomaly.fromJson(Map<String, dynamic> json) {
    return BehaviorAnomaly(
      id: json['id'],
      userId: json['userId'],
      type: AnomalyType.values.firstWhere((e) => e.name == json['type']),
      description: json['description'],
      severity: json['severity'].toDouble(),
      detectedAt: DateTime.parse(json['detectedAt']),
      context: Map<String, dynamic>.from(json['context']),
      confidence: json['confidence'].toDouble(),
      resolved: json['resolved'] ?? false,
    );
  }
}

class UserBehaviorAnalyticsService extends ChangeNotifier {
  final List<UserBehaviorEvent> _events = [];
  final List<BehaviorAnomaly> _anomalies = [];
  Timer? _analysisTimer;
  
  static const String _eventsKey = 'behavior_events';
  static const String _anomaliesKey = 'behavior_anomalies';

  List<UserBehaviorEvent> get events => List.unmodifiable(_events);
  List<BehaviorAnomaly> get anomalies => List.unmodifiable(_anomalies);

  Future<void> initialize() async {
    await _loadEvents();
    await _loadAnomalies();
    await _startAnalysisTimer();
  }

  Future<void> _loadEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getStringList(_eventsKey) ?? [];
      
      _events.clear();
      for (final eventJson in eventsJson) {
        final Map<String, dynamic> data = jsonDecode(eventJson);
        _events.add(UserBehaviorEvent.fromJson(data));
      }
    } catch (e) {
      debugPrint('Error loading behavior events: $e');
    }
  }

  Future<void> _saveEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = _events.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_eventsKey, eventsJson);
    } catch (e) {
      debugPrint('Error saving behavior events: $e');
    }
  }

  Future<void> _loadAnomalies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final anomaliesJson = prefs.getStringList(_anomaliesKey) ?? [];
      
      _anomalies.clear();
      for (final anomalyJson in anomaliesJson) {
        final Map<String, dynamic> data = jsonDecode(anomalyJson);
        _anomalies.add(BehaviorAnomaly.fromJson(data));
      }
    } catch (e) {
      debugPrint('Error loading behavior anomalies: $e');
    }
  }

  Future<void> _saveAnomalies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final anomaliesJson = _anomalies.map((a) => jsonEncode(a.toJson())).toList();
      await prefs.setStringList(_anomaliesKey, anomaliesJson);
    } catch (e) {
      debugPrint('Error saving behavior anomalies: $e');
    }
  }

  Future<void> _startAnalysisTimer() async {
    _analysisTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _performBehaviorAnalysis();
    });
  }

  Future<void> trackEvent({
    required String userId,
    required String eventType,
    Map<String, dynamic> properties = const {},
    String? sessionId,
    String? deviceId,
    String? location,
  }) async {
    final event = UserBehaviorEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
      userId: userId,
      eventType: eventType,
      timestamp: DateTime.now(),
      properties: properties,
      sessionId: sessionId,
      deviceId: deviceId,
      location: location,
    );

    _events.insert(0, event);
    
    if (_events.length > 50000) {
      _events.removeRange(50000, _events.length);
    }
    
    await _saveEvents();
    
    if (_isCriticalEvent(eventType)) {
      await _checkForRealTimeAnomalies(event);
    }
    
    notifyListeners();
  }

  bool _isCriticalEvent(String eventType) {
    return ['login', 'failed_login', 'privilege_escalation', 'sensitive_data_access', 'admin_action'].contains(eventType);
  }

  Future<void> _checkForRealTimeAnomalies(UserBehaviorEvent event) async {
    // Simulate anomaly detection
    final random = Random();
    if (random.nextDouble() < 0.1) { // 10% chance of anomaly
      await _recordAnomaly(
        userId: event.userId,
        type: AnomalyType.values[random.nextInt(AnomalyType.values.length)],
        description: 'Unusual ${event.eventType} behavior detected',
        severity: random.nextDouble(),
        context: {'event_id': event.id},
        confidence: 0.8,
      );
    }
  }

  void _performBehaviorAnalysis() {
    // Periodic analysis logic
    debugPrint('Performing behavior analysis...');
  }

  Future<void> _recordAnomaly({
    required String userId,
    required AnomalyType type,
    required String description,
    required double severity,
    required Map<String, dynamic> context,
    required double confidence,
  }) async {
    final anomaly = BehaviorAnomaly(
      id: 'anomaly_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      type: type,
      description: description,
      severity: severity,
      detectedAt: DateTime.now(),
      context: context,
      confidence: confidence,
    );

    _anomalies.insert(0, anomaly);
    
    if (_anomalies.length > 5000) {
      _anomalies.removeRange(5000, _anomalies.length);
    }
    
    await _saveAnomalies();
    notifyListeners();
  }

  Map<String, dynamic> getBehaviorAnalyticsStatistics() {
    final totalEvents = _events.length;
    final totalAnomalies = _anomalies.length;
    final unresolvedAnomalies = _anomalies.where((a) => !a.resolved).length;
    
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));
    final events24h = _events.where((e) => e.timestamp.isAfter(last24h)).length;
    
    return {
      'total_events': totalEvents,
      'total_anomalies': totalAnomalies,
      'unresolved_anomalies': unresolvedAnomalies,
      'events_24h': events24h,
      'anomaly_types': _getAnomalyTypeBreakdown(),
      'top_event_types': _getTopEventTypes(),
    };
  }

  Map<String, int> _getAnomalyTypeBreakdown() {
    final breakdown = <String, int>{};
    for (final anomaly in _anomalies) {
      breakdown[anomaly.type.name] = (breakdown[anomaly.type.name] ?? 0) + 1;
    }
    return breakdown;
  }

  Map<String, int> _getTopEventTypes() {
    final eventCounts = <String, int>{};
    for (final event in _events) {
      eventCounts[event.eventType] = (eventCounts[event.eventType] ?? 0) + 1;
    }
    
    final sorted = eventCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sorted.take(10));
  }

  Map<String, dynamic> exportBehaviorData() {
    return {
      'events': _events.map((e) => e.toJson()).toList(),
      'anomalies': _anomalies.map((a) => a.toJson()).toList(),
      'statistics': getBehaviorAnalyticsStatistics(),
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    super.dispose();
  }
}
