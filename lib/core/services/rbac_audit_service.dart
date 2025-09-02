import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clean_flutter/locator.dart';
import 'package:clean_flutter/features/admin/services/logging_service.dart';

enum AuditActionType {
  permissionCheck,
  permissionGranted,
  permissionDenied,
  roleChanged,
  roleAssigned,
  roleRemoved,
  customPermissionAdded,
  customPermissionRemoved,
  roleTemplateCreated,
  roleTemplateModified,
  roleTemplateDeleted,
  bulkRoleAssignment,
  emergencyAccess,
  temporaryPermission,
}

class AuditLogEntry {
  final String id;
  final DateTime timestamp;
  final String userId;
  final String userEmail;
  final AuditActionType action;
  final String targetResource;
  final Map<String, dynamic> metadata;
  final bool success;
  final String? failureReason;
  final String? ipAddress;
  final String? userAgent;
  final String? sessionId;

  AuditLogEntry({
    required this.id,
    required this.timestamp,
    required this.userId,
    required this.userEmail,
    required this.action,
    required this.targetResource,
    required this.metadata,
    required this.success,
    this.failureReason,
    this.ipAddress,
    this.userAgent,
    this.sessionId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'userId': userId,
    'userEmail': userEmail,
    'action': action.toString(),
    'targetResource': targetResource,
    'metadata': metadata,
    'success': success,
    'failureReason': failureReason,
    'ipAddress': ipAddress,
    'userAgent': userAgent,
    'sessionId': sessionId,
  };

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) => AuditLogEntry(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    userId: json['userId'],
    userEmail: json['userEmail'],
    action: AuditActionType.values.firstWhere(
      (e) => e.toString() == json['action'],
    ),
    targetResource: json['targetResource'],
    metadata: json['metadata'],
    success: json['success'],
    failureReason: json['failureReason'],
    ipAddress: json['ipAddress'],
    userAgent: json['userAgent'],
    sessionId: json['sessionId'],
  );
}

class RBACPermissionCache {
  final Map<String, Map<String, bool>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration cacheDuration;

  RBACPermissionCache({
    this.cacheDuration = const Duration(minutes: 5),
  });

  bool? getCachedPermission(String userId, String permission) {
    final timestamp = _cacheTimestamps[userId];
    if (timestamp != null && 
        DateTime.now().difference(timestamp) < cacheDuration) {
      return _cache[userId]?[permission];
    }
    // Cache expired
    _cache.remove(userId);
    _cacheTimestamps.remove(userId);
    return null;
  }

  void cachePermission(String userId, String permission, bool hasPermission) {
    _cache.putIfAbsent(userId, () => {});
    _cache[userId]![permission] = hasPermission;
    _cacheTimestamps[userId] = DateTime.now();
  }

  void invalidateUser(String userId) {
    _cache.remove(userId);
    _cacheTimestamps.remove(userId);
  }

  void invalidateAll() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  Map<String, dynamic> getCacheStats() {
    final totalUsers = _cache.length;
    final totalPermissions = _cache.values
        .fold(0, (sum, userCache) => sum + userCache.length);
    final oldestCache = _cacheTimestamps.values.isEmpty 
        ? null 
        : _cacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b);
    
    return {
      'totalUsers': totalUsers,
      'totalPermissions': totalPermissions,
      'oldestCache': oldestCache?.toIso8601String(),
      'cacheSize': _estimateCacheSize(),
    };
  }

  int _estimateCacheSize() {
    // Rough estimate in bytes
    return jsonEncode(_cache).length;
  }
}

class RBACAuditService extends ChangeNotifier {
  static const String _auditLogsKey = 'rbac_audit_logs';
  static const int _maxLogsInMemory = 1000;
  static const int _maxLogsInStorage = 10000;
  
  final List<AuditLogEntry> _logs = [];
  final RBACPermissionCache _permissionCache = RBACPermissionCache();
  final Map<String, int> _actionCounts = {};
  final Map<String, DateTime> _lastActionTime = {};
  
  bool _isInitialized = false;
  String? _currentSessionId;

  // Analytics
  int _totalPermissionChecks = 0;
  int _totalPermissionsDenied = 0;
  int _cacheHits = 0;
  int _cacheMisses = 0;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    final logsJson = prefs.getString(_auditLogsKey);
    
    if (logsJson != null) {
      try {
        final List<dynamic> logsList = jsonDecode(logsJson);
        _logs.addAll(
          logsList.map((json) => AuditLogEntry.fromJson(json))
              .take(_maxLogsInMemory)
        );
      } catch (e) {
        debugPrint('Error loading audit logs: $e');
      }
    }
    
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> logPermissionCheck({
    required String userId,
    required String userEmail,
    required String permission,
    required bool granted,
    String? resource,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    _totalPermissionChecks++;
    if (!granted) _totalPermissionsDenied++;
    
    final entry = AuditLogEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}_${userId}_$permission',
      timestamp: DateTime.now(),
      userId: userId,
      userEmail: userEmail,
      action: granted ? AuditActionType.permissionGranted : AuditActionType.permissionDenied,
      targetResource: resource ?? permission,
      metadata: {
        'permission': permission,
        'cacheHit': false,
        ...?additionalMetadata,
      },
      success: granted,
      failureReason: granted ? null : 'Insufficient permissions',
      sessionId: _currentSessionId,
    );
    
    await _addLog(entry);
    
    // Update action counts
    _actionCounts[permission] = (_actionCounts[permission] ?? 0) + 1;
    _lastActionTime[permission] = DateTime.now();
  }

  Future<void> logRoleChange({
    required String userId,
    required String userEmail,
    required String oldRole,
    required String newRole,
    required String changedBy,
    String? reason,
  }) async {
    final entry = AuditLogEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}_role_$userId',
      timestamp: DateTime.now(),
      userId: userId,
      userEmail: userEmail,
      action: AuditActionType.roleChanged,
      targetResource: 'role',
      metadata: {
        'oldRole': oldRole,
        'newRole': newRole,
        'changedBy': changedBy,
        'reason': reason,
      },
      success: true,
      sessionId: _currentSessionId,
    );
    
    await _addLog(entry);
    
    // Invalidate cache for this user
    _permissionCache.invalidateUser(userId);
    
    // Log to main logging service
    final loggingService = locator<LoggingService>();
    await loggingService.logAdminAction(
      'role_change',
      'Changed role for $userEmail from $oldRole to $newRole',
    );
  }

  Future<void> logCustomPermission({
    required String userId,
    required String userEmail,
    required String permission,
    required bool added,
    required String modifiedBy,
  }) async {
    final entry = AuditLogEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}_custom_$userId',
      timestamp: DateTime.now(),
      userId: userId,
      userEmail: userEmail,
      action: added ? AuditActionType.customPermissionAdded : AuditActionType.customPermissionRemoved,
      targetResource: permission,
      metadata: {
        'permission': permission,
        'modifiedBy': modifiedBy,
        'operation': added ? 'added' : 'removed',
      },
      success: true,
      sessionId: _currentSessionId,
    );
    
    await _addLog(entry);
    _permissionCache.invalidateUser(userId);
  }

  Future<void> logEmergencyAccess({
    required String userId,
    required String userEmail,
    required String reason,
    required Duration duration,
    required List<String> permissions,
  }) async {
    final entry = AuditLogEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}_emergency_$userId',
      timestamp: DateTime.now(),
      userId: userId,
      userEmail: userEmail,
      action: AuditActionType.emergencyAccess,
      targetResource: 'emergency_access',
      metadata: {
        'reason': reason,
        'duration': duration.inMinutes,
        'permissions': permissions,
        'expiresAt': DateTime.now().add(duration).toIso8601String(),
      },
      success: true,
      sessionId: _currentSessionId,
    );
    
    await _addLog(entry);
  }

  bool? getCachedPermission(String userId, String permission) {
    final cached = _permissionCache.getCachedPermission(userId, permission);
    if (cached != null) {
      _cacheHits++;
    } else {
      _cacheMisses++;
    }
    return cached;
  }

  void cachePermission(String userId, String permission, bool hasPermission) {
    _permissionCache.cachePermission(userId, permission, hasPermission);
  }

  void invalidateUserCache(String userId) {
    _permissionCache.invalidateUser(userId);
  }

  void invalidateAllCache() {
    _permissionCache.invalidateAll();
    notifyListeners();
  }

  Future<void> _addLog(AuditLogEntry entry) async {
    _logs.insert(0, entry);
    
    // Keep only recent logs in memory
    if (_logs.length > _maxLogsInMemory) {
      _logs.removeRange(_maxLogsInMemory, _logs.length);
    }
    
    // Persist to storage
    await _persistLogs();
    notifyListeners();
  }

  Future<void> _persistLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsToSave = _logs.take(_maxLogsInStorage).toList();
      final logsJson = jsonEncode(
        logsToSave.map((log) => log.toJson()).toList()
      );
      await prefs.setString(_auditLogsKey, logsJson);
    } catch (e) {
      debugPrint('Error persisting audit logs: $e');
    }
  }

  List<AuditLogEntry> getRecentLogs({
    int limit = 100,
    AuditActionType? actionType,
    String? userId,
    DateTime? since,
  }) {
    var filtered = _logs.where((log) {
      if (actionType != null && log.action != actionType) return false;
      if (userId != null && log.userId != userId) return false;
      if (since != null && log.timestamp.isBefore(since)) return false;
      return true;
    });
    
    return filtered.take(limit).toList();
  }

  Map<String, dynamic> getAnalytics() {
    final denialRate = _totalPermissionChecks > 0 
        ? (_totalPermissionsDenied / _totalPermissionChecks * 100).toStringAsFixed(2)
        : '0.00';
    
    final cacheHitRate = (_cacheHits + _cacheMisses) > 0
        ? (_cacheHits / (_cacheHits + _cacheMisses) * 100).toStringAsFixed(2)
        : '0.00';
    
    return {
      'totalPermissionChecks': _totalPermissionChecks,
      'totalPermissionsDenied': _totalPermissionsDenied,
      'denialRate': '$denialRate%',
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'cacheHitRate': '$cacheHitRate%',
      'totalAuditLogs': _logs.length,
      'sessionId': _currentSessionId,
      'mostCheckedPermissions': _getMostCheckedPermissions(),
      'recentActivity': _getRecentActivity(),
      'cacheStats': _permissionCache.getCacheStats(),
    };
  }

  List<Map<String, dynamic>> _getMostCheckedPermissions() {
    final sorted = _actionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(10).map((entry) => {
      'permission': entry.key,
      'count': entry.value,
      'lastChecked': _lastActionTime[entry.key]?.toIso8601String(),
    }).toList();
  }

  List<Map<String, dynamic>> _getRecentActivity() {
    final now = DateTime.now();
    final hourAgo = now.subtract(const Duration(hours: 1));
    
    final recentLogs = _logs.where((log) => log.timestamp.isAfter(hourAgo));
    
    final Map<String, int> activityByType = {};
    for (final log in recentLogs) {
      final key = log.action.toString().split('.').last;
      activityByType[key] = (activityByType[key] ?? 0) + 1;
    }
    
    return activityByType.entries.map((entry) => {
      'type': entry.key,
      'count': entry.value,
    }).toList();
  }

  Future<void> exportAuditLogs({
    DateTime? startDate,
    DateTime? endDate,
    String? format = 'json',
  }) async {
    final filtered = _logs.where((log) {
      if (startDate != null && log.timestamp.isBefore(startDate)) return false;
      if (endDate != null && log.timestamp.isAfter(endDate)) return false;
      return true;
    }).toList();
    
    // TODO: Implement actual export functionality
    debugPrint('Exporting ${filtered.length} audit logs in $format format');
  }

  void clearOldLogs({Duration olderThan = const Duration(days: 30)}) {
    final cutoff = DateTime.now().subtract(olderThan);
    _logs.removeWhere((log) => log.timestamp.isBefore(cutoff));
    _persistLogs();
    notifyListeners();
  }
}
