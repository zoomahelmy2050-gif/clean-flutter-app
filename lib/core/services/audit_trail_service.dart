import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuditEventType {
  authentication,
  authorization,
  dataAccess,
  dataModification,
  systemConfiguration,
  userManagement,
  securityEvent,
  adminAction,
  apiCall,
  fileAccess,
}

enum AuditSeverity {
  info,
  warning,
  error,
  critical,
}

class AuditEvent {
  final String id;
  final AuditEventType eventType;
  final String action;
  final String? userId;
  final String? targetUserId;
  final String? resourceId;
  final DateTime timestamp;
  final String? ipAddress;
  final String? userAgent;
  final String? sessionId;
  final Map<String, dynamic> details;
  final AuditSeverity severity;
  final bool success;
  final String? errorMessage;
  final Map<String, dynamic> metadata;

  AuditEvent({
    required this.id,
    required this.eventType,
    required this.action,
    this.userId,
    this.targetUserId,
    this.resourceId,
    required this.timestamp,
    this.ipAddress,
    this.userAgent,
    this.sessionId,
    this.details = const {},
    this.severity = AuditSeverity.info,
    this.success = true,
    this.errorMessage,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventType': eventType.name,
    'action': action,
    'userId': userId,
    'targetUserId': targetUserId,
    'resourceId': resourceId,
    'timestamp': timestamp.toIso8601String(),
    'ipAddress': ipAddress,
    'userAgent': userAgent,
    'sessionId': sessionId,
    'details': details,
    'severity': severity.name,
    'success': success,
    'errorMessage': errorMessage,
    'metadata': metadata,
  };

  factory AuditEvent.fromJson(Map<String, dynamic> json) {
    return AuditEvent(
      id: json['id'],
      eventType: AuditEventType.values.firstWhere((e) => e.name == json['eventType']),
      action: json['action'],
      userId: json['userId'],
      targetUserId: json['targetUserId'],
      resourceId: json['resourceId'],
      timestamp: DateTime.parse(json['timestamp']),
      ipAddress: json['ipAddress'],
      userAgent: json['userAgent'],
      sessionId: json['sessionId'],
      details: Map<String, dynamic>.from(json['details'] ?? {}),
      severity: AuditSeverity.values.firstWhere((e) => e.name == json['severity']),
      success: json['success'] ?? true,
      errorMessage: json['errorMessage'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

class ForensicsQuery {
  final String id;
  final String name;
  final String description;
  final Map<String, dynamic> filters;
  final DateTime createdAt;
  final String createdBy;
  final List<String> resultIds;

  ForensicsQuery({
    required this.id,
    required this.name,
    required this.description,
    required this.filters,
    required this.createdAt,
    required this.createdBy,
    this.resultIds = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'filters': filters,
    'createdAt': createdAt.toIso8601String(),
    'createdBy': createdBy,
    'resultIds': resultIds,
  };

  factory ForensicsQuery.fromJson(Map<String, dynamic> json) {
    return ForensicsQuery(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      filters: Map<String, dynamic>.from(json['filters']),
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: json['createdBy'],
      resultIds: List<String>.from(json['resultIds'] ?? []),
    );
  }
}

class AuditTrailService extends ChangeNotifier {
  final List<AuditEvent> _auditEvents = [];
  final List<ForensicsQuery> _savedQueries = [];
  Timer? _cleanupTimer;
  
  static const String _auditEventsKey = 'audit_events';
  static const String _savedQueriesKey = 'forensics_queries';
  static const int _maxEvents = 100000; // Keep last 100k events

  // Getters
  List<AuditEvent> get auditEvents => List.unmodifiable(_auditEvents);
  List<ForensicsQuery> get savedQueries => List.unmodifiable(_savedQueries);

  /// Initialize audit trail service
  Future<void> initialize() async {
    await _loadAuditEvents();
    await _loadSavedQueries();
    await _startCleanupTimer();
    await _generateSampleData();
  }

  /// Load audit events from storage
  Future<void> _loadAuditEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getStringList(_auditEventsKey) ?? [];
      
      _auditEvents.clear();
      for (final eventJson in eventsJson) {
        final Map<String, dynamic> data = jsonDecode(eventJson);
        _auditEvents.add(AuditEvent.fromJson(data));
      }
    } catch (e) {
      debugPrint('Error loading audit events: $e');
    }
  }

  /// Save audit events to storage
  Future<void> _saveAuditEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = _auditEvents.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_auditEventsKey, eventsJson);
    } catch (e) {
      debugPrint('Error saving audit events: $e');
    }
  }

  /// Load saved queries from storage
  Future<void> _loadSavedQueries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queriesJson = prefs.getStringList(_savedQueriesKey) ?? [];
      
      _savedQueries.clear();
      for (final queryJson in queriesJson) {
        final Map<String, dynamic> data = jsonDecode(queryJson);
        _savedQueries.add(ForensicsQuery.fromJson(data));
      }
    } catch (e) {
      debugPrint('Error loading saved queries: $e');
    }
  }

  /// Save queries to storage
  Future<void> _saveSavedQueries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queriesJson = _savedQueries.map((q) => jsonEncode(q.toJson())).toList();
      await prefs.setStringList(_savedQueriesKey, queriesJson);
    } catch (e) {
      debugPrint('Error saving queries: $e');
    }
  }

  /// Start cleanup timer
  Future<void> _startCleanupTimer() async {
    _cleanupTimer = Timer.periodic(const Duration(hours: 24), (_) {
      _cleanupOldEvents();
    });
  }

  /// Cleanup old events
  void _cleanupOldEvents() {
    if (_auditEvents.length > _maxEvents) {
      _auditEvents.removeRange(_maxEvents, _auditEvents.length);
      _saveAuditEvents();
    }
  }

  /// Log audit event
  Future<void> logEvent({
    required AuditEventType eventType,
    required String action,
    String? userId,
    String? targetUserId,
    String? resourceId,
    String? ipAddress,
    String? userAgent,
    String? sessionId,
    Map<String, dynamic> details = const {},
    AuditSeverity severity = AuditSeverity.info,
    bool success = true,
    String? errorMessage,
    Map<String, dynamic> metadata = const {},
  }) async {
    final event = AuditEvent(
      id: 'audit_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
      eventType: eventType,
      action: action,
      userId: userId,
      targetUserId: targetUserId,
      resourceId: resourceId,
      timestamp: DateTime.now(),
      ipAddress: ipAddress,
      userAgent: userAgent,
      sessionId: sessionId,
      details: details,
      severity: severity,
      success: success,
      errorMessage: errorMessage,
      metadata: metadata,
    );

    _auditEvents.insert(0, event);
    
    // Cleanup if needed
    if (_auditEvents.length > _maxEvents) {
      _auditEvents.removeRange(_maxEvents, _auditEvents.length);
    }
    
    await _saveAuditEvents();
    notifyListeners();
    
    debugPrint('Audit event logged: ${event.action} by ${event.userId ?? 'system'}');
  }

  /// Search audit events
  List<AuditEvent> searchEvents({
    String? userId,
    String? targetUserId,
    String? resourceId,
    String? action,
    AuditEventType? eventType,
    AuditSeverity? severity,
    bool? success,
    DateTime? startDate,
    DateTime? endDate,
    String? ipAddress,
    String? sessionId,
    String? searchText,
    int limit = 1000,
  }) {
    var results = _auditEvents.where((event) {
      if (userId != null && event.userId != userId) return false;
      if (targetUserId != null && event.targetUserId != targetUserId) return false;
      if (resourceId != null && event.resourceId != resourceId) return false;
      if (action != null && !event.action.toLowerCase().contains(action.toLowerCase())) return false;
      if (eventType != null && event.eventType != eventType) return false;
      if (severity != null && event.severity != severity) return false;
      if (success != null && event.success != success) return false;
      if (startDate != null && event.timestamp.isBefore(startDate)) return false;
      if (endDate != null && event.timestamp.isAfter(endDate)) return false;
      if (ipAddress != null && event.ipAddress != ipAddress) return false;
      if (sessionId != null && event.sessionId != sessionId) return false;
      
      if (searchText != null && searchText.isNotEmpty) {
        final searchLower = searchText.toLowerCase();
        final eventJson = jsonEncode(event.toJson()).toLowerCase();
        if (!eventJson.contains(searchLower)) return false;
      }
      
      return true;
    }).toList();

    return results.take(limit).toList();
  }

  /// Save forensics query
  Future<String> saveForensicsQuery({
    required String name,
    required String description,
    required Map<String, dynamic> filters,
    required String createdBy,
  }) async {
    final query = ForensicsQuery(
      id: 'query_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      filters: filters,
      createdAt: DateTime.now(),
      createdBy: createdBy,
    );

    _savedQueries.insert(0, query);
    await _saveSavedQueries();
    notifyListeners();

    return query.id;
  }

  /// Execute forensics query
  List<AuditEvent> executeForensicsQuery(String queryId) {
    final query = _savedQueries.firstWhere((q) => q.id == queryId);
    final filters = query.filters;
    
    return searchEvents(
      userId: filters['userId'],
      targetUserId: filters['targetUserId'],
      resourceId: filters['resourceId'],
      action: filters['action'],
      eventType: filters['eventType'] != null 
        ? AuditEventType.values.firstWhere((e) => e.name == filters['eventType'])
        : null,
      severity: filters['severity'] != null
        ? AuditSeverity.values.firstWhere((e) => e.name == filters['severity'])
        : null,
      success: filters['success'],
      startDate: filters['startDate'] != null ? DateTime.parse(filters['startDate']) : null,
      endDate: filters['endDate'] != null ? DateTime.parse(filters['endDate']) : null,
      ipAddress: filters['ipAddress'],
      sessionId: filters['sessionId'],
      searchText: filters['searchText'],
      limit: filters['limit'] ?? 1000,
    );
  }

  /// Generate audit trail report
  Map<String, dynamic> generateAuditReport({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? userIds,
    List<AuditEventType>? eventTypes,
  }) {
    final now = DateTime.now();
    final start = startDate ?? now.subtract(const Duration(days: 30));
    final end = endDate ?? now;
    
    final events = _auditEvents.where((e) => 
      e.timestamp.isAfter(start) && 
      e.timestamp.isBefore(end) &&
      (userIds == null || userIds.contains(e.userId)) &&
      (eventTypes == null || eventTypes.contains(e.eventType))
    ).toList();

    final totalEvents = events.length;
    final successfulEvents = events.where((e) => e.success).length;
    final failedEvents = totalEvents - successfulEvents;
    
    final eventTypeBreakdown = <String, int>{};
    final severityBreakdown = <String, int>{};
    final userActivityBreakdown = <String, int>{};
    final dailyActivity = <String, int>{};
    
    for (final event in events) {
      // Event type breakdown
      eventTypeBreakdown[event.eventType.name] = 
        (eventTypeBreakdown[event.eventType.name] ?? 0) + 1;
      
      // Severity breakdown
      severityBreakdown[event.severity.name] = 
        (severityBreakdown[event.severity.name] ?? 0) + 1;
      
      // User activity breakdown
      if (event.userId != null) {
        userActivityBreakdown[event.userId!] = 
          (userActivityBreakdown[event.userId!] ?? 0) + 1;
      }
      
      // Daily activity
      final dayKey = '${event.timestamp.year}-${event.timestamp.month.toString().padLeft(2, '0')}-${event.timestamp.day.toString().padLeft(2, '0')}';
      dailyActivity[dayKey] = (dailyActivity[dayKey] ?? 0) + 1;
    }

    return {
      'report_period': {
        'start_date': start.toIso8601String(),
        'end_date': end.toIso8601String(),
      },
      'summary': {
        'total_events': totalEvents,
        'successful_events': successfulEvents,
        'failed_events': failedEvents,
        'success_rate': totalEvents > 0 ? (successfulEvents / totalEvents * 100).toStringAsFixed(2) : '0.00',
      },
      'breakdowns': {
        'event_types': eventTypeBreakdown,
        'severities': severityBreakdown,
        'user_activity': userActivityBreakdown,
        'daily_activity': dailyActivity,
      },
      'top_users': _getTopUsers(events),
      'security_events': _getSecurityEvents(events),
      'generated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Get top users by activity
  List<Map<String, dynamic>> _getTopUsers(List<AuditEvent> events) {
    final userCounts = <String, int>{};
    for (final event in events) {
      if (event.userId != null) {
        userCounts[event.userId!] = (userCounts[event.userId!] ?? 0) + 1;
      }
    }
    
    final sorted = userCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(10).map((entry) => {
      'user_id': entry.key,
      'event_count': entry.value,
    }).toList();
  }

  /// Get security events
  List<Map<String, dynamic>> _getSecurityEvents(List<AuditEvent> events) {
    final securityEvents = events.where((e) => 
      e.eventType == AuditEventType.securityEvent ||
      e.severity == AuditSeverity.critical ||
      e.severity == AuditSeverity.error ||
      !e.success
    ).toList();
    
    return securityEvents.take(50).map((event) => {
      'id': event.id,
      'action': event.action,
      'user_id': event.userId,
      'timestamp': event.timestamp.toIso8601String(),
      'severity': event.severity.name,
      'success': event.success,
      'error_message': event.errorMessage,
    }).toList();
  }

  /// Get audit statistics
  Map<String, dynamic> getAuditStatistics() {
    final totalEvents = _auditEvents.length;
    final now = DateTime.now();
    
    final last24h = now.subtract(const Duration(hours: 24));
    final events24h = _auditEvents.where((e) => e.timestamp.isAfter(last24h)).length;
    
    final last7days = now.subtract(const Duration(days: 7));
    final events7days = _auditEvents.where((e) => e.timestamp.isAfter(last7days)).length;
    
    final criticalEvents = _auditEvents.where((e) => e.severity == AuditSeverity.critical).length;
    final failedEvents = _auditEvents.where((e) => !e.success).length;
    
    return {
      'total_events': totalEvents,
      'events_24h': events24h,
      'events_7days': events7days,
      'critical_events': criticalEvents,
      'failed_events': failedEvents,
      'success_rate': totalEvents > 0 ? ((totalEvents - failedEvents) / totalEvents * 100).toStringAsFixed(2) : '100.00',
      'saved_queries': _savedQueries.length,
      'storage_size_mb': (totalEvents * 0.5 / 1024).toStringAsFixed(2), // Rough estimate
    };
  }

  /// Generate sample audit data for demonstration
  Future<void> _generateSampleData() async {
    if (_auditEvents.isNotEmpty) return;
    
    final random = Random();
    final sampleUsers = ['admin', 'user1', 'user2', 'user3', 'system'];
    final sampleActions = [
      'login', 'logout', 'create_user', 'delete_user', 'update_profile',
      'access_sensitive_data', 'export_data', 'change_permissions',
      'backup_database', 'restore_database', 'system_config_change'
    ];
    
    for (int i = 0; i < 100; i++) {
      final eventType = AuditEventType.values[random.nextInt(AuditEventType.values.length)];
      final severity = AuditSeverity.values[random.nextInt(AuditSeverity.values.length)];
      final success = random.nextDouble() > 0.1; // 90% success rate
      
      await logEvent(
        eventType: eventType,
        action: sampleActions[random.nextInt(sampleActions.length)],
        userId: sampleUsers[random.nextInt(sampleUsers.length)],
        targetUserId: random.nextBool() ? sampleUsers[random.nextInt(sampleUsers.length)] : null,
        resourceId: 'resource_${random.nextInt(1000)}',
        ipAddress: '192.168.1.${random.nextInt(255)}',
        userAgent: 'Mozilla/5.0 (Sample Browser)',
        sessionId: 'session_${random.nextInt(10000)}',
        details: {
          'sample_detail': 'value_${random.nextInt(100)}',
          'timestamp_detail': DateTime.now().subtract(Duration(hours: random.nextInt(720))).toIso8601String(),
        },
        severity: severity,
        success: success,
        errorMessage: success ? null : 'Sample error message',
        metadata: {
          'generated': true,
          'sample_metadata': random.nextInt(1000),
        },
      );
    }
  }

  /// Export audit data
  Map<String, dynamic> exportAuditData({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final now = DateTime.now();
    final start = startDate ?? now.subtract(const Duration(days: 30));
    final end = endDate ?? now;
    
    final events = _auditEvents.where((e) => 
      e.timestamp.isAfter(start) && e.timestamp.isBefore(end)
    ).toList();

    return {
      'audit_events': events.map((e) => e.toJson()).toList(),
      'saved_queries': _savedQueries.map((q) => q.toJson()).toList(),
      'statistics': getAuditStatistics(),
      'export_period': {
        'start_date': start.toIso8601String(),
        'end_date': end.toIso8601String(),
      },
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    super.dispose();
  }
}
