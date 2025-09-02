import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UsageEventType {
  appLaunch,
  totpGenerated,
  totpCopied,
  qrScanned,
  backupUsed,
  syncPerformed,
  searchUsed,
  favoriteToggled,
  bulkOperation,
  settingsChanged,
  errorOccurred,
}

class UsageEvent {
  final String id;
  final UsageEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final String? category;
  final double? duration;

  UsageEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    this.metadata = const {},
    this.category,
    this.duration,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
    'category': category,
    'duration': duration,
  };

  factory UsageEvent.fromJson(Map<String, dynamic> json) {
    return UsageEvent(
      id: json['id'],
      type: UsageEventType.values.firstWhere((e) => e.name == json['type']),
      timestamp: DateTime.parse(json['timestamp']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      category: json['category'],
      duration: json['duration']?.toDouble(),
    );
  }
}

class UsageSession {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  final List<UsageEvent> events;
  final String deviceInfo;

  UsageSession({
    required this.id,
    required this.startTime,
    this.endTime,
    List<UsageEvent>? events,
    required this.deviceInfo,
  }) : events = events ?? [];

  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);
  bool get isActive => endTime == null;
  int get eventCount => events.length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'events': events.map((e) => e.toJson()).toList(),
    'deviceInfo': deviceInfo,
  };

  factory UsageSession.fromJson(Map<String, dynamic> json) {
    return UsageSession(
      id: json['id'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      events: (json['events'] as List?)?.map((e) => UsageEvent.fromJson(e)).toList(),
      deviceInfo: json['deviceInfo'] ?? 'Unknown',
    );
  }
}

class UsageAnalyticsService extends ChangeNotifier {
  List<UsageEvent> _events = [];
  List<UsageSession> _sessions = [];
  UsageSession? _currentSession;
  Timer? _sessionTimer;
  bool _analyticsEnabled = true;
  DateTime? _lastEventTime;
  
  static const String _eventsKey = 'usage_events';
  static const String _sessionsKey = 'usage_sessions';
  static const String _enabledKey = 'analytics_enabled';
  static const int _maxEvents = 10000;
  static const int _maxSessions = 100;
  static const Duration _sessionTimeout = Duration(minutes: 30);

  // Getters
  List<UsageEvent> get events => List.unmodifiable(_events);
  List<UsageSession> get sessions => List.unmodifiable(_sessions);
  UsageSession? get currentSession => _currentSession;
  bool get analyticsEnabled => _analyticsEnabled;
  bool get hasActiveSession => _currentSession?.isActive ?? false;

  /// Initialize analytics service
  Future<void> initialize() async {
    await _loadData();
    await _startNewSession();
    _startSessionTimer();
  }

  /// Load data from storage
  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load events
      final eventsJson = prefs.getString(_eventsKey);
      if (eventsJson != null) {
        final eventsList = jsonDecode(eventsJson) as List;
        _events = eventsList.map((json) => UsageEvent.fromJson(json)).toList();
      }
      
      // Load sessions
      final sessionsJson = prefs.getString(_sessionsKey);
      if (sessionsJson != null) {
        final sessionsList = jsonDecode(sessionsJson) as List;
        _sessions = sessionsList.map((json) => UsageSession.fromJson(json)).toList();
      }
      
      // Load enabled setting
      _analyticsEnabled = prefs.getBool(_enabledKey) ?? true;
      
      // Find active session
      _currentSession = _sessions.firstWhere(
        (session) => session.isActive,
        orElse: () => null as UsageSession,
      );
    } catch (e) {
      debugPrint('Error loading analytics data: $e');
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
      
      // Save sessions (keep only recent ones)
      if (_sessions.length > _maxSessions) {
        _sessions = _sessions.take(_maxSessions).toList();
      }
      await prefs.setString(_sessionsKey, jsonEncode(_sessions.map((s) => s.toJson()).toList()));
      
      // Save enabled setting
      await prefs.setBool(_enabledKey, _analyticsEnabled);
    } catch (e) {
      debugPrint('Error saving analytics data: $e');
    }
  }

  /// Start new session
  Future<void> _startNewSession() async {
    // End current session if exists
    if (_currentSession != null && _currentSession!.isActive) {
      _currentSession!.endTime = DateTime.now();
    }

    // Create new session
    _currentSession = UsageSession(
      id: _generateId(),
      startTime: DateTime.now(),
      deviceInfo: await _getDeviceInfo(),
    );

    _sessions.insert(0, _currentSession!);
    await _trackEvent(UsageEventType.appLaunch);
    notifyListeners();
  }

  /// Track usage event
  Future<void> trackEvent(
    UsageEventType type, {
    Map<String, dynamic>? metadata,
    String? category,
    double? duration,
  }) async {
    if (!_analyticsEnabled) return;

    await _trackEvent(type, metadata: metadata, category: category, duration: duration);
  }

  /// Internal track event
  Future<void> _trackEvent(
    UsageEventType type, {
    Map<String, dynamic>? metadata,
    String? category,
    double? duration,
  }) async {
    final event = UsageEvent(
      id: _generateId(),
      type: type,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
      category: category,
      duration: duration,
    );

    _events.insert(0, event);
    _currentSession?.events.add(event);
    _lastEventTime = DateTime.now();

    await _saveData();
    notifyListeners();
  }

  /// Start session timer
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkSessionTimeout();
    });
  }

  /// Check for session timeout
  void _checkSessionTimeout() {
    if (_lastEventTime != null) {
      final timeSinceLastEvent = DateTime.now().difference(_lastEventTime!);
      if (timeSinceLastEvent > _sessionTimeout && _currentSession?.isActive == true) {
        _endCurrentSession();
      }
    }
  }

  /// End current session
  void _endCurrentSession() {
    if (_currentSession != null && _currentSession!.isActive) {
      _currentSession!.endTime = DateTime.now();
      _saveData();
      notifyListeners();
    }
  }

  /// Toggle analytics
  Future<void> toggleAnalytics() async {
    _analyticsEnabled = !_analyticsEnabled;
    await _saveData();
    notifyListeners();
  }

  /// Get usage statistics
  Map<String, dynamic> getUsageStatistics({DateTime? startDate, DateTime? endDate}) {
    final filteredEvents = _filterEventsByDate(_events, startDate, endDate);
    final filteredSessions = _filterSessionsByDate(_sessions, startDate, endDate);

    // Event type breakdown
    final eventTypeCount = <String, int>{};
    for (final event in filteredEvents) {
      eventTypeCount[event.type.name] = (eventTypeCount[event.type.name] ?? 0) + 1;
    }

    // Category breakdown
    final categoryCount = <String, int>{};
    for (final event in filteredEvents) {
      if (event.category != null) {
        categoryCount[event.category!] = (categoryCount[event.category!] ?? 0) + 1;
      }
    }

    // Session statistics
    final totalSessions = filteredSessions.length;
    final activeSessions = filteredSessions.where((s) => s.isActive).length;
    final avgSessionDuration = filteredSessions.isNotEmpty
        ? filteredSessions.map((s) => s.duration.inMinutes).reduce((a, b) => a + b) / totalSessions
        : 0.0;

    // Daily usage
    final dailyUsage = <String, int>{};
    for (final session in filteredSessions) {
      final dateKey = _formatDate(session.startTime);
      dailyUsage[dateKey] = (dailyUsage[dateKey] ?? 0) + 1;
    }

    // Peak usage hours
    final hourlyUsage = <int, int>{};
    for (final event in filteredEvents) {
      final hour = event.timestamp.hour;
      hourlyUsage[hour] = (hourlyUsage[hour] ?? 0) + 1;
    }

    return {
      'totalEvents': filteredEvents.length,
      'totalSessions': totalSessions,
      'activeSessions': activeSessions,
      'avgSessionDuration': avgSessionDuration,
      'eventTypeBreakdown': eventTypeCount,
      'categoryBreakdown': categoryCount,
      'dailyUsage': dailyUsage,
      'hourlyUsage': hourlyUsage,
      'dateRange': {
        'start': startDate?.toIso8601String(),
        'end': endDate?.toIso8601String(),
      },
    };
  }

  /// Get most used features
  List<Map<String, dynamic>> getMostUsedFeatures({int limit = 10}) {
    final featureCount = <String, int>{};
    
    for (final event in _events) {
      final feature = _getFeatureName(event.type);
      featureCount[feature] = (featureCount[feature] ?? 0) + 1;
    }

    final sortedFeatures = featureCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedFeatures.take(limit).map((entry) => {
      'feature': entry.key,
      'usage': entry.value,
      'percentage': (_events.isNotEmpty ? (entry.value / _events.length * 100) : 0.0),
    }).toList();
  }

  /// Get usage trends
  Map<String, List<Map<String, dynamic>>> getUsageTrends({int days = 30}) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    
    final trends = <String, List<Map<String, dynamic>>>{};
    
    // Daily event count trend
    final dailyEvents = <String, int>{};
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey = _formatDate(date);
      dailyEvents[dateKey] = 0;
    }
    
    for (final event in _events) {
      if (event.timestamp.isAfter(startDate) && event.timestamp.isBefore(endDate)) {
        final dateKey = _formatDate(event.timestamp);
        dailyEvents[dateKey] = (dailyEvents[dateKey] ?? 0) + 1;
      }
    }
    
    trends['dailyEvents'] = dailyEvents.entries.map((entry) => {
      'date': entry.key,
      'count': entry.value,
    }).toList();

    return trends;
  }

  /// Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    final durations = _events
        .where((e) => e.duration != null)
        .map((e) => e.duration!)
        .toList();

    if (durations.isEmpty) {
      return {
        'avgDuration': 0.0,
        'minDuration': 0.0,
        'maxDuration': 0.0,
        'totalOperations': 0,
      };
    }

    durations.sort();
    
    return {
      'avgDuration': durations.reduce((a, b) => a + b) / durations.length,
      'minDuration': durations.first,
      'maxDuration': durations.last,
      'medianDuration': durations[durations.length ~/ 2],
      'totalOperations': durations.length,
    };
  }

  /// Export analytics data
  Map<String, dynamic> exportData() {
    return {
      'events': _events.map((e) => e.toJson()).toList(),
      'sessions': _sessions.map((s) => s.toJson()).toList(),
      'statistics': getUsageStatistics(),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  /// Clear analytics data
  Future<void> clearData() async {
    _events.clear();
    _sessions.clear();
    _currentSession = null;
    await _saveData();
    notifyListeners();
  }

  /// Helper methods
  List<UsageEvent> _filterEventsByDate(List<UsageEvent> events, DateTime? start, DateTime? end) {
    return events.where((event) {
      if (start != null && event.timestamp.isBefore(start)) return false;
      if (end != null && event.timestamp.isAfter(end)) return false;
      return true;
    }).toList();
  }

  List<UsageSession> _filterSessionsByDate(List<UsageSession> sessions, DateTime? start, DateTime? end) {
    return sessions.where((session) {
      if (start != null && session.startTime.isBefore(start)) return false;
      if (end != null && session.startTime.isAfter(end)) return false;
      return true;
    }).toList();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getFeatureName(UsageEventType type) {
    switch (type) {
      case UsageEventType.appLaunch:
        return 'App Launch';
      case UsageEventType.totpGenerated:
        return 'TOTP Generation';
      case UsageEventType.totpCopied:
        return 'TOTP Copy';
      case UsageEventType.qrScanned:
        return 'QR Scanner';
      case UsageEventType.backupUsed:
        return 'Backup Codes';
      case UsageEventType.syncPerformed:
        return 'Data Sync';
      case UsageEventType.searchUsed:
        return 'Search';
      case UsageEventType.favoriteToggled:
        return 'Favorites';
      case UsageEventType.bulkOperation:
        return 'Bulk Operations';
      case UsageEventType.settingsChanged:
        return 'Settings';
      case UsageEventType.errorOccurred:
        return 'Errors';
    }
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }

  Future<String> _getDeviceInfo() async {
    // Simple device info - could be enhanced with device_info_plus package
    return 'Flutter App';
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _endCurrentSession();
    super.dispose();
  }
}
