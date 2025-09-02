import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SecurityEventType {
  loginAttempt,
  loginSuccess,
  loginFailure,
  passwordChange,
  backupCodeUsed,
  suspiciousActivity,
  dataExport,
  settingsChange,
  deviceChange,
  syncActivity,
  totpAccess,
  unauthorizedAccess,
}

enum ThreatLevel {
  low,
  medium,
  high,
  critical,
}

enum SecurityStatus {
  secure,
  warning,
  compromised,
  unknown,
}

class SecurityEvent {
  final String id;
  final SecurityEventType type;
  final DateTime timestamp;
  final ThreatLevel threatLevel;
  final String description;
  final Map<String, dynamic> metadata;
  final String? ipAddress;
  final String? userAgent;
  final bool resolved;

  SecurityEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.threatLevel,
    required this.description,
    this.metadata = const {},
    this.ipAddress,
    this.userAgent,
    this.resolved = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'threatLevel': threatLevel.name,
    'description': description,
    'metadata': metadata,
    'ipAddress': ipAddress,
    'userAgent': userAgent,
    'resolved': resolved,
  };

  factory SecurityEvent.fromJson(Map<String, dynamic> json) {
    return SecurityEvent(
      id: json['id'],
      type: SecurityEventType.values.firstWhere((e) => e.name == json['type']),
      timestamp: DateTime.parse(json['timestamp']),
      threatLevel: ThreatLevel.values.firstWhere((e) => e.name == json['threatLevel']),
      description: json['description'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      ipAddress: json['ipAddress'],
      userAgent: json['userAgent'],
      resolved: json['resolved'] ?? false,
    );
  }

  SecurityEvent copyWith({bool? resolved}) {
    return SecurityEvent(
      id: id,
      type: type,
      timestamp: timestamp,
      threatLevel: threatLevel,
      description: description,
      metadata: metadata,
      ipAddress: ipAddress,
      userAgent: userAgent,
      resolved: resolved ?? this.resolved,
    );
  }
}

class SecurityMetrics {
  final int totalEvents;
  final int criticalEvents;
  final int unresolvedEvents;
  final double securityScore;
  final SecurityStatus status;
  final DateTime lastUpdate;
  final Map<String, int> threatBreakdown;
  final Map<String, int> eventTypeBreakdown;

  SecurityMetrics({
    required this.totalEvents,
    required this.criticalEvents,
    required this.unresolvedEvents,
    required this.securityScore,
    required this.status,
    required this.lastUpdate,
    required this.threatBreakdown,
    required this.eventTypeBreakdown,
  });
}

class SecurityAnalyticsService extends ChangeNotifier {
  List<SecurityEvent> _events = [];
  SecurityMetrics? _currentMetrics;
  Timer? _analysisTimer;
  bool _realTimeMonitoring = true;
  DateTime? _lastAnalysis;
  
  // Threat detection settings
  int _maxFailedLogins = 5;
  Duration _suspiciousActivityWindow = const Duration(minutes: 15);
  double _minimumSecurityScore = 70.0;
  
  static const String _eventsKey = 'security_events';
  static const String _settingsKey = 'security_settings';
  static const int _maxEvents = 5000;

  // Getters
  List<SecurityEvent> get events => List.unmodifiable(_events);
  SecurityMetrics? get currentMetrics => _currentMetrics;
  bool get realTimeMonitoring => _realTimeMonitoring;
  int get unresolvedEventsCount => _events.where((e) => !e.resolved).length;
  int get criticalEventsCount => _events.where((e) => e.threatLevel == ThreatLevel.critical).length;
  SecurityStatus get currentStatus => _currentMetrics?.status ?? SecurityStatus.unknown;

  /// Initialize security analytics
  Future<void> initialize() async {
    await _loadData();
    await _analyzeSecurityMetrics();
    _startRealTimeMonitoring();
  }

  /// Load data from storage
  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load events
      final eventsJson = prefs.getString(_eventsKey);
      if (eventsJson != null) {
        final eventsList = jsonDecode(eventsJson) as List;
        _events = eventsList.map((json) => SecurityEvent.fromJson(json)).toList();
      }
      
      // Load settings
      final settingsJson = prefs.getString(_settingsKey);
      if (settingsJson != null) {
        final settings = jsonDecode(settingsJson);
        _maxFailedLogins = settings['maxFailedLogins'] ?? 5;
        _realTimeMonitoring = settings['realTimeMonitoring'] ?? true;
        _minimumSecurityScore = settings['minimumSecurityScore']?.toDouble() ?? 70.0;
      }
    } catch (e) {
      debugPrint('Error loading security analytics data: $e');
    }
  }

  /// Save data to storage
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save events (keep only recent ones)
      if (_events.length > _maxEvents) {
        _events = _events.take(_maxEvents).toList();
      }
      await prefs.setString(_eventsKey, jsonEncode(_events.map((e) => e.toJson()).toList()));
      
      // Save settings
      final settings = {
        'maxFailedLogins': _maxFailedLogins,
        'realTimeMonitoring': _realTimeMonitoring,
        'minimumSecurityScore': _minimumSecurityScore,
      };
      await prefs.setString(_settingsKey, jsonEncode(settings));
    } catch (e) {
      debugPrint('Error saving security analytics data: $e');
    }
  }

  /// Record security event
  Future<void> recordEvent(
    SecurityEventType type,
    String description, {
    ThreatLevel? threatLevel,
    Map<String, dynamic>? metadata,
    String? ipAddress,
    String? userAgent,
  }) async {
    final event = SecurityEvent(
      id: _generateId(),
      type: type,
      timestamp: DateTime.now(),
      threatLevel: threatLevel ?? _calculateThreatLevel(type, metadata),
      description: description,
      metadata: metadata ?? {},
      ipAddress: ipAddress,
      userAgent: userAgent,
    );

    _events.insert(0, event);
    await _saveData();
    
    // Trigger real-time analysis
    if (_realTimeMonitoring) {
      await _analyzeSecurityMetrics();
      _checkForThreats(event);
    }
    
    notifyListeners();
  }

  /// Calculate threat level based on event type and context
  ThreatLevel _calculateThreatLevel(SecurityEventType type, Map<String, dynamic>? metadata) {
    switch (type) {
      case SecurityEventType.loginFailure:
        final consecutiveFailures = _getConsecutiveFailures();
        if (consecutiveFailures >= _maxFailedLogins) return ThreatLevel.high;
        if (consecutiveFailures >= 3) return ThreatLevel.medium;
        return ThreatLevel.low;
        
      case SecurityEventType.suspiciousActivity:
      case SecurityEventType.unauthorizedAccess:
        return ThreatLevel.high;
        
      case SecurityEventType.deviceChange:
      case SecurityEventType.passwordChange:
        return ThreatLevel.medium;
        
      case SecurityEventType.backupCodeUsed:
        return ThreatLevel.medium;
        
      default:
        return ThreatLevel.low;
    }
  }

  /// Get consecutive login failures
  int _getConsecutiveFailures() {
    int count = 0;
    for (final event in _events) {
      if (event.type == SecurityEventType.loginFailure) {
        count++;
      } else if (event.type == SecurityEventType.loginSuccess) {
        break;
      }
    }
    return count;
  }

  /// Check for security threats
  void _checkForThreats(SecurityEvent event) {
    // Check for brute force attacks
    if (event.type == SecurityEventType.loginFailure) {
      final recentFailures = _getRecentEvents(SecurityEventType.loginFailure, _suspiciousActivityWindow);
      if (recentFailures.length >= _maxFailedLogins) {
        recordEvent(
          SecurityEventType.suspiciousActivity,
          'Possible brute force attack detected',
          threatLevel: ThreatLevel.critical,
          metadata: {'failureCount': recentFailures.length},
        );
      }
    }

    // Check for unusual access patterns
    if (event.type == SecurityEventType.totpAccess) {
      final recentAccess = _getRecentEvents(SecurityEventType.totpAccess, const Duration(minutes: 5));
      if (recentAccess.length > 20) {
        recordEvent(
          SecurityEventType.suspiciousActivity,
          'Unusual TOTP access pattern detected',
          threatLevel: ThreatLevel.medium,
          metadata: {'accessCount': recentAccess.length},
        );
      }
    }
  }

  /// Get recent events of specific type
  List<SecurityEvent> _getRecentEvents(SecurityEventType type, Duration window) {
    final cutoff = DateTime.now().subtract(window);
    return _events
        .where((e) => e.type == type && e.timestamp.isAfter(cutoff))
        .toList();
  }

  /// Analyze security metrics
  Future<void> _analyzeSecurityMetrics() async {
    final now = DateTime.now();
    final totalEvents = _events.length;
    final criticalEvents = _events.where((e) => e.threatLevel == ThreatLevel.critical).length;
    final unresolvedEvents = _events.where((e) => !e.resolved).length;
    
    // Calculate security score
    final securityScore = _calculateSecurityScore();
    
    // Determine status
    final status = _determineSecurityStatus(securityScore, criticalEvents, unresolvedEvents);
    
    // Create threat breakdown
    final threatBreakdown = <String, int>{};
    for (final level in ThreatLevel.values) {
      threatBreakdown[level.name] = _events.where((e) => e.threatLevel == level).length;
    }
    
    // Create event type breakdown
    final eventTypeBreakdown = <String, int>{};
    for (final type in SecurityEventType.values) {
      eventTypeBreakdown[type.name] = _events.where((e) => e.type == type).length;
    }
    
    _currentMetrics = SecurityMetrics(
      totalEvents: totalEvents,
      criticalEvents: criticalEvents,
      unresolvedEvents: unresolvedEvents,
      securityScore: securityScore,
      status: status,
      lastUpdate: now,
      threatBreakdown: threatBreakdown,
      eventTypeBreakdown: eventTypeBreakdown,
    );
    
    _lastAnalysis = now;
    notifyListeners();
  }

  /// Calculate security score (0-100)
  double _calculateSecurityScore() {
    if (_events.isEmpty) return 100.0;
    
    double score = 100.0;
    final recentEvents = _getEventsInPeriod(const Duration(days: 7));
    
    // Deduct points for critical events
    final criticalCount = recentEvents.where((e) => e.threatLevel == ThreatLevel.critical).length;
    score -= criticalCount * 20;
    
    // Deduct points for high threat events
    final highCount = recentEvents.where((e) => e.threatLevel == ThreatLevel.high).length;
    score -= highCount * 10;
    
    // Deduct points for unresolved events
    final unresolvedCount = recentEvents.where((e) => !e.resolved).length;
    score -= unresolvedCount * 5;
    
    // Deduct points for failed logins
    final failureCount = recentEvents.where((e) => e.type == SecurityEventType.loginFailure).length;
    score -= failureCount * 2;
    
    return max(0.0, min(100.0, score));
  }

  /// Determine security status
  SecurityStatus _determineSecurityStatus(double score, int criticalEvents, int unresolvedEvents) {
    if (criticalEvents > 0 || score < 30) {
      return SecurityStatus.compromised;
    } else if (unresolvedEvents > 5 || score < _minimumSecurityScore) {
      return SecurityStatus.warning;
    } else {
      return SecurityStatus.secure;
    }
  }

  /// Get events in time period
  List<SecurityEvent> _getEventsInPeriod(Duration period) {
    final cutoff = DateTime.now().subtract(period);
    return _events.where((e) => e.timestamp.isAfter(cutoff)).toList();
  }

  /// Resolve security event
  Future<void> resolveEvent(String eventId) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      _events[index] = _events[index].copyWith(resolved: true);
      await _saveData();
      await _analyzeSecurityMetrics();
      notifyListeners();
    }
  }

  /// Resolve all events of specific type
  Future<void> resolveEventsByType(SecurityEventType type) async {
    bool hasChanges = false;
    for (int i = 0; i < _events.length; i++) {
      if (_events[i].type == type && !_events[i].resolved) {
        _events[i] = _events[i].copyWith(resolved: true);
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      await _saveData();
      await _analyzeSecurityMetrics();
      notifyListeners();
    }
  }

  /// Get security recommendations
  List<String> getSecurityRecommendations() {
    final recommendations = <String>[];
    
    if (_currentMetrics == null) return recommendations;
    
    if (_currentMetrics!.securityScore < 50) {
      recommendations.add('Your security score is low. Review and resolve security events.');
    }
    
    if (_currentMetrics!.criticalEvents > 0) {
      recommendations.add('You have critical security events that need immediate attention.');
    }
    
    if (_currentMetrics!.unresolvedEvents > 10) {
      recommendations.add('You have many unresolved security events. Consider reviewing them.');
    }
    
    final recentFailures = _getRecentEvents(SecurityEventType.loginFailure, const Duration(hours: 24));
    if (recentFailures.length > 3) {
      recommendations.add('Multiple login failures detected. Consider changing your password.');
    }
    
    final backupUsage = _getRecentEvents(SecurityEventType.backupCodeUsed, const Duration(days: 7));
    if (backupUsage.isNotEmpty) {
      recommendations.add('Backup codes were used recently. Ensure your primary authentication is working.');
    }
    
    return recommendations;
  }

  /// Get security trends
  Map<String, List<Map<String, dynamic>>> getSecurityTrends({int days = 30}) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    
    final trends = <String, List<Map<String, dynamic>>>{};
    
    // Daily threat level counts
    final dailyThreats = <String, Map<String, int>>{};
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey = _formatDate(date);
      dailyThreats[dateKey] = {
        'low': 0,
        'medium': 0,
        'high': 0,
        'critical': 0,
      };
    }
    
    for (final event in _events) {
      if (event.timestamp.isAfter(startDate) && event.timestamp.isBefore(endDate)) {
        final dateKey = _formatDate(event.timestamp);
        if (dailyThreats.containsKey(dateKey)) {
          dailyThreats[dateKey]![event.threatLevel.name] = 
              (dailyThreats[dateKey]![event.threatLevel.name] ?? 0) + 1;
        }
      }
    }
    
    trends['dailyThreats'] = dailyThreats.entries.map((entry) => {
      'date': entry.key,
      ...entry.value,
    }).toList();
    
    return trends;
  }

  /// Toggle real-time monitoring
  Future<void> toggleRealTimeMonitoring() async {
    _realTimeMonitoring = !_realTimeMonitoring;
    
    if (_realTimeMonitoring) {
      _startRealTimeMonitoring();
    } else {
      _stopRealTimeMonitoring();
    }
    
    await _saveData();
    notifyListeners();
  }

  /// Start real-time monitoring
  void _startRealTimeMonitoring() {
    _stopRealTimeMonitoring();
    _analysisTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _analyzeSecurityMetrics();
    });
  }

  /// Stop real-time monitoring
  void _stopRealTimeMonitoring() {
    _analysisTimer?.cancel();
    _analysisTimer = null;
  }

  /// Update security settings
  Future<void> updateSettings({
    int? maxFailedLogins,
    Duration? suspiciousActivityWindow,
    double? minimumSecurityScore,
  }) async {
    if (maxFailedLogins != null) _maxFailedLogins = maxFailedLogins;
    if (suspiciousActivityWindow != null) _suspiciousActivityWindow = suspiciousActivityWindow;
    if (minimumSecurityScore != null) _minimumSecurityScore = minimumSecurityScore;
    
    await _saveData();
    await _analyzeSecurityMetrics();
    notifyListeners();
  }

  /// Export security data
  Map<String, dynamic> exportSecurityData() {
    return {
      'events': _events.map((e) => e.toJson()).toList(),
      'metrics': _currentMetrics != null ? {
        'totalEvents': _currentMetrics!.totalEvents,
        'criticalEvents': _currentMetrics!.criticalEvents,
        'unresolvedEvents': _currentMetrics!.unresolvedEvents,
        'securityScore': _currentMetrics!.securityScore,
        'status': _currentMetrics!.status.name,
        'lastUpdate': _currentMetrics!.lastUpdate.toIso8601String(),
      } : null,
      'settings': {
        'maxFailedLogins': _maxFailedLogins,
        'realTimeMonitoring': _realTimeMonitoring,
        'minimumSecurityScore': _minimumSecurityScore,
      },
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  /// Clear security data
  Future<void> clearSecurityData() async {
    _events.clear();
    _currentMetrics = null;
    await _saveData();
    notifyListeners();
  }

  /// Helper methods
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }

  @override
  void dispose() {
    _stopRealTimeMonitoring();
    super.dispose();
  }
}
