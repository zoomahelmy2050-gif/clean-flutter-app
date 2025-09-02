import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum ActivityType {
  login,
  logout,
  passwordChange,
  profileUpdate,
  securitySettingChange,
  roleAssignment,
  dataExport,
  dataImport,
  userCreation,
  userDeletion,
  systemAccess,
  apiCall,
  fileUpload,
  fileDownload,
  securityAlert,
  failedLogin,
  suspiciousActivity,
}

enum ActivitySeverity {
  low,
  medium,
  high,
  critical,
}

class ActivityLog {
  final String id;
  final String userId;
  final String userEmail;
  final ActivityType type;
  final ActivitySeverity severity;
  final String description;
  final Map<String, dynamic> metadata;
  final String ipAddress;
  final String userAgent;
  final String deviceInfo;
  final DateTime timestamp;
  final String? sessionId;
  final bool isSuccessful;
  final String? errorMessage;

  ActivityLog({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.type,
    required this.severity,
    required this.description,
    this.metadata = const {},
    required this.ipAddress,
    required this.userAgent,
    required this.deviceInfo,
    required this.timestamp,
    this.sessionId,
    this.isSuccessful = true,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userEmail': userEmail,
    'type': type.name,
    'severity': severity.name,
    'description': description,
    'metadata': metadata,
    'ipAddress': ipAddress,
    'userAgent': userAgent,
    'deviceInfo': deviceInfo,
    'timestamp': timestamp.toIso8601String(),
    'sessionId': sessionId,
    'isSuccessful': isSuccessful,
    'errorMessage': errorMessage,
  };

  factory ActivityLog.fromJson(Map<String, dynamic> json) => ActivityLog(
    id: json['id'],
    userId: json['userId'],
    userEmail: json['userEmail'],
    type: ActivityType.values.firstWhere((t) => t.name == json['type']),
    severity: ActivitySeverity.values.firstWhere((s) => s.name == json['severity']),
    description: json['description'],
    metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    ipAddress: json['ipAddress'],
    userAgent: json['userAgent'],
    deviceInfo: json['deviceInfo'],
    timestamp: DateTime.parse(json['timestamp']),
    sessionId: json['sessionId'],
    isSuccessful: json['isSuccessful'] ?? true,
    errorMessage: json['errorMessage'],
  );
}

class UserSession {
  final String id;
  final String userId;
  final String userEmail;
  final DateTime startTime;
  final DateTime? endTime;
  final String ipAddress;
  final String userAgent;
  final String deviceInfo;
  final bool isActive;
  final List<String> activityIds;

  UserSession({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.startTime,
    this.endTime,
    required this.ipAddress,
    required this.userAgent,
    required this.deviceInfo,
    this.isActive = true,
    this.activityIds = const [],
  });

  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userEmail': userEmail,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'ipAddress': ipAddress,
    'userAgent': userAgent,
    'deviceInfo': deviceInfo,
    'isActive': isActive,
    'activityIds': activityIds,
  };

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
    id: json['id'],
    userId: json['userId'],
    userEmail: json['userEmail'],
    startTime: DateTime.parse(json['startTime']),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    ipAddress: json['ipAddress'],
    userAgent: json['userAgent'],
    deviceInfo: json['deviceInfo'],
    isActive: json['isActive'] ?? true,
    activityIds: List<String>.from(json['activityIds'] ?? []),
  );
}

class UserActivityService extends ChangeNotifier {
  static const String _activityLogsKey = 'activity_logs';
  static const String _userSessionsKey = 'user_sessions';
  static const int _maxLogsToKeep = 1000;
  
  List<ActivityLog> _activityLogs = [];
  List<UserSession> _userSessions = [];
  bool _isLoading = false;

  List<ActivityLog> get activityLogs => _activityLogs;
  List<UserSession> get userSessions => _userSessions;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadActivityLogs();
      await _loadUserSessions();
    } catch (e) {
      debugPrint('Error initializing user activity service: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadActivityLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final logsJson = prefs.getString(_activityLogsKey);
    
    if (logsJson != null) {
      final logsList = jsonDecode(logsJson) as List;
      _activityLogs = logsList.map((json) => ActivityLog.fromJson(json)).toList();
      
      // Sort by timestamp (newest first)
      _activityLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
  }

  Future<void> _loadUserSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getString(_userSessionsKey);
    
    if (sessionsJson != null) {
      final sessionsList = jsonDecode(sessionsJson) as List;
      _userSessions = sessionsList.map((json) => UserSession.fromJson(json)).toList();
      
      // Sort by start time (newest first)
      _userSessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    }
  }

  Future<void> _saveActivityLogs() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Keep only the most recent logs to prevent storage bloat
    if (_activityLogs.length > _maxLogsToKeep) {
      _activityLogs = _activityLogs.take(_maxLogsToKeep).toList();
    }
    
    final logsJson = jsonEncode(_activityLogs.map((log) => log.toJson()).toList());
    await prefs.setString(_activityLogsKey, logsJson);
  }

  Future<void> _saveUserSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = jsonEncode(_userSessions.map((session) => session.toJson()).toList());
    await prefs.setString(_userSessionsKey, sessionsJson);
  }

  // Activity Logging
  Future<void> logActivity({
    required String userId,
    required String userEmail,
    required ActivityType type,
    required String description,
    ActivitySeverity severity = ActivitySeverity.low,
    Map<String, dynamic>? metadata,
    String? sessionId,
    bool isSuccessful = true,
    String? errorMessage,
  }) async {
    final activity = ActivityLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      userEmail: userEmail,
      type: type,
      severity: severity,
      description: description,
      metadata: metadata ?? {},
      ipAddress: _getCurrentIpAddress(),
      userAgent: _getCurrentUserAgent(),
      deviceInfo: _getCurrentDeviceInfo(),
      timestamp: DateTime.now(),
      sessionId: sessionId,
      isSuccessful: isSuccessful,
      errorMessage: errorMessage,
    );

    _activityLogs.insert(0, activity);
    
    // Update session activity if sessionId provided
    if (sessionId != null) {
      final sessionIndex = _userSessions.indexWhere((s) => s.id == sessionId);
      if (sessionIndex != -1) {
        final session = _userSessions[sessionIndex];
        final updatedActivityIds = List<String>.from(session.activityIds)..add(activity.id);
        _userSessions[sessionIndex] = UserSession(
          id: session.id,
          userId: session.userId,
          userEmail: session.userEmail,
          startTime: session.startTime,
          endTime: session.endTime,
          ipAddress: session.ipAddress,
          userAgent: session.userAgent,
          deviceInfo: session.deviceInfo,
          isActive: session.isActive,
          activityIds: updatedActivityIds,
        );
      }
    }

    await _saveActivityLogs();
    await _saveUserSessions();
    notifyListeners();
  }

  // Session Management
  Future<String> startSession(String userId, String userEmail) async {
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    
    final session = UserSession(
      id: sessionId,
      userId: userId,
      userEmail: userEmail,
      startTime: DateTime.now(),
      ipAddress: _getCurrentIpAddress(),
      userAgent: _getCurrentUserAgent(),
      deviceInfo: _getCurrentDeviceInfo(),
    );

    _userSessions.insert(0, session);
    await _saveUserSessions();
    
    // Log session start
    await logActivity(
      userId: userId,
      userEmail: userEmail,
      type: ActivityType.login,
      description: 'User session started',
      sessionId: sessionId,
    );

    notifyListeners();
    return sessionId;
  }

  Future<void> endSession(String sessionId, String userId, String userEmail) async {
    final sessionIndex = _userSessions.indexWhere((s) => s.id == sessionId);
    
    if (sessionIndex != -1) {
      final session = _userSessions[sessionIndex];
      _userSessions[sessionIndex] = UserSession(
        id: session.id,
        userId: session.userId,
        userEmail: session.userEmail,
        startTime: session.startTime,
        endTime: DateTime.now(),
        ipAddress: session.ipAddress,
        userAgent: session.userAgent,
        deviceInfo: session.deviceInfo,
        isActive: false,
        activityIds: session.activityIds,
      );

      await _saveUserSessions();
      
      // Log session end
      await logActivity(
        userId: userId,
        userEmail: userEmail,
        type: ActivityType.logout,
        description: 'User session ended',
        sessionId: sessionId,
      );

      notifyListeners();
    }
  }

  // Query Methods
  List<ActivityLog> getActivitiesByUser(String userId, {int? limit}) {
    var userActivities = _activityLogs.where((log) => log.userId == userId).toList();
    if (limit != null && userActivities.length > limit) {
      userActivities = userActivities.take(limit).toList();
    }
    return userActivities;
  }

  List<ActivityLog> getActivitiesByType(ActivityType type, {int? limit}) {
    var typeActivities = _activityLogs.where((log) => log.type == type).toList();
    if (limit != null && typeActivities.length > limit) {
      typeActivities = typeActivities.take(limit).toList();
    }
    return typeActivities;
  }

  List<ActivityLog> getActivitiesBySeverity(ActivitySeverity severity, {int? limit}) {
    var severityActivities = _activityLogs.where((log) => log.severity == severity).toList();
    if (limit != null && severityActivities.length > limit) {
      severityActivities = severityActivities.take(limit).toList();
    }
    return severityActivities;
  }

  List<ActivityLog> getActivitiesInDateRange(DateTime start, DateTime end) {
    return _activityLogs.where((log) => 
      log.timestamp.isAfter(start) && log.timestamp.isBefore(end)
    ).toList();
  }

  List<ActivityLog> searchActivities(String query) {
    final lowerQuery = query.toLowerCase();
    return _activityLogs.where((log) =>
      log.description.toLowerCase().contains(lowerQuery) ||
      log.userEmail.toLowerCase().contains(lowerQuery) ||
      log.type.name.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  List<UserSession> getActiveSessions() {
    return _userSessions.where((session) => session.isActive).toList();
  }

  List<UserSession> getSessionsByUser(String userId) {
    return _userSessions.where((session) => session.userId == userId).toList();
  }

  // Analytics
  Map<String, int> getActivityTypeDistribution({DateTime? since}) {
    var logs = _activityLogs;
    if (since != null) {
      logs = logs.where((log) => log.timestamp.isAfter(since)).toList();
    }

    final distribution = <String, int>{};
    for (final type in ActivityType.values) {
      distribution[type.name] = logs.where((log) => log.type == type).length;
    }
    return distribution;
  }

  Map<String, int> getSeverityDistribution({DateTime? since}) {
    var logs = _activityLogs;
    if (since != null) {
      logs = logs.where((log) => log.timestamp.isAfter(since)).toList();
    }

    final distribution = <String, int>{};
    for (final severity in ActivitySeverity.values) {
      distribution[severity.name] = logs.where((log) => log.severity == severity).length;
    }
    return distribution;
  }

  List<ActivityLog> getFailedActivities({int? limit}) {
    var failedActivities = _activityLogs.where((log) => !log.isSuccessful).toList();
    if (limit != null && failedActivities.length > limit) {
      failedActivities = failedActivities.take(limit).toList();
    }
    return failedActivities;
  }

  Map<String, int> getUserActivityCounts({DateTime? since}) {
    var logs = _activityLogs;
    if (since != null) {
      logs = logs.where((log) => log.timestamp.isAfter(since)).toList();
    }

    final userCounts = <String, int>{};
    for (final log in logs) {
      userCounts[log.userEmail] = (userCounts[log.userEmail] ?? 0) + 1;
    }
    return userCounts;
  }

  List<String> getSuspiciousIpAddresses() {
    final ipCounts = <String, int>{};
    final recentLogs = _activityLogs.where((log) => 
      log.timestamp.isAfter(DateTime.now().subtract(const Duration(hours: 24)))
    ).toList();

    for (final log in recentLogs) {
      ipCounts[log.ipAddress] = (ipCounts[log.ipAddress] ?? 0) + 1;
    }

    // Consider IPs with more than 100 activities in 24h as suspicious
    return ipCounts.entries
        .where((entry) => entry.value > 100)
        .map((entry) => entry.key)
        .toList();
  }

  // Cleanup
  Future<void> cleanupOldLogs({int daysToKeep = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    _activityLogs.removeWhere((log) => log.timestamp.isBefore(cutoffDate));
    await _saveActivityLogs();
    notifyListeners();
  }

  Future<void> cleanupOldSessions({int daysToKeep = 7}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    _userSessions.removeWhere((session) => 
      !session.isActive && session.startTime.isBefore(cutoffDate)
    );
    await _saveUserSessions();
    notifyListeners();
  }

  // Helper methods for device info (mock implementations)
  String _getCurrentIpAddress() {
    // In a real app, you'd get the actual IP address
    return '192.168.1.${DateTime.now().millisecond % 255}';
  }

  String _getCurrentUserAgent() {
    // In a real app, you'd get the actual user agent
    return 'Flutter App v1.0.0';
  }

  String _getCurrentDeviceInfo() {
    // In a real app, you'd get actual device info
    return 'Mobile Device - ${DateTime.now().millisecondsSinceEpoch}';
  }
}
