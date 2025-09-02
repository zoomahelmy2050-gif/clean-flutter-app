import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

class RealTimeAnalyticsService {
  static final RealTimeAnalyticsService _instance = RealTimeAnalyticsService._internal();
  factory RealTimeAnalyticsService() => _instance;
  RealTimeAnalyticsService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Stream controllers for real-time data
  final StreamController<SecurityMetrics> _metricsController = StreamController<SecurityMetrics>.broadcast();
  final StreamController<ThreatEvent> _threatController = StreamController<ThreatEvent>.broadcast();
  final StreamController<UserActivity> _activityController = StreamController<UserActivity>.broadcast();
  final StreamController<SystemHealth> _healthController = StreamController<SystemHealth>.broadcast();
  final StreamController<ComplianceStatus> _complianceController = StreamController<ComplianceStatus>.broadcast();

  // Streams for real-time updates
  Stream<SecurityMetrics> get metricsStream => _metricsController.stream;
  Stream<ThreatEvent> get threatStream => _threatController.stream;
  Stream<UserActivity> get activityStream => _activityController.stream;
  Stream<SystemHealth> get healthStream => _healthController.stream;
  Stream<ComplianceStatus> get complianceStream => _complianceController.stream;

  // Data storage
  final List<SecurityMetrics> _metricsHistory = [];
  final List<ThreatEvent> _threatHistory = [];
  final List<UserActivity> _activityHistory = [];
  final List<SystemHealth> _healthHistory = [];
  final List<ComplianceStatus> _complianceHistory = [];

  // Timers for data generation
  Timer? _metricsTimer;
  Timer? _threatTimer;
  Timer? _activityTimer;
  Timer? _healthTimer;
  Timer? _complianceTimer;

  final Random _random = Random();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Start real-time data generation
      _startMetricsGeneration();
      _startThreatGeneration();
      _startActivityGeneration();
      _startHealthGeneration();
      _startComplianceGeneration();

      _isInitialized = true;
      developer.log('Real-time Analytics Service initialized', name: 'RealTimeAnalyticsService');
    } catch (e) {
      developer.log('Failed to initialize Real-time Analytics Service: $e', name: 'RealTimeAnalyticsService');
      throw Exception('Real-time Analytics Service initialization failed: $e');
    }
  }

  void _startMetricsGeneration() {
    _metricsTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final metrics = _generateSecurityMetrics();
      _metricsHistory.add(metrics);
      _metricsController.add(metrics);

      // Keep only last 100 entries
      if (_metricsHistory.length > 100) {
        _metricsHistory.removeAt(0);
      }
    });
  }

  void _startThreatGeneration() {
    _threatTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (_random.nextDouble() < 0.3) { // 30% chance of threat event
        final threat = _generateThreatEvent();
        _threatHistory.add(threat);
        _threatController.add(threat);

        // Keep only last 50 entries
        if (_threatHistory.length > 50) {
          _threatHistory.removeAt(0);
        }
      }
    });
  }

  void _startActivityGeneration() {
    _activityTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      final activity = _generateUserActivity();
      _activityHistory.add(activity);
      _activityController.add(activity);

      // Keep only last 200 entries
      if (_activityHistory.length > 200) {
        _activityHistory.removeAt(0);
      }
    });
  }

  void _startHealthGeneration() {
    _healthTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      final health = _generateSystemHealth();
      _healthHistory.add(health);
      _healthController.add(health);

      // Keep only last 50 entries
      if (_healthHistory.length > 50) {
        _healthHistory.removeAt(0);
      }
    });
  }

  void _startComplianceGeneration() {
    _complianceTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      final compliance = _generateComplianceStatus();
      _complianceHistory.add(compliance);
      _complianceController.add(compliance);

      // Keep only last 20 entries
      if (_complianceHistory.length > 20) {
        _complianceHistory.removeAt(0);
      }
    });
  }

  SecurityMetrics _generateSecurityMetrics() {
    final now = DateTime.now();
    return SecurityMetrics(
      timestamp: now,
      threatsDetected: _random.nextInt(10),
      threatsBlocked: _random.nextInt(8),
      activeUsers: 150 + _random.nextInt(50),
      failedLogins: _random.nextInt(5),
      successfulLogins: 20 + _random.nextInt(30),
      mfaUsage: 0.85 + _random.nextDouble() * 0.1,
      encryptionOperations: 100 + _random.nextInt(200),
      apiRequests: 500 + _random.nextInt(1000),
      responseTime: 50 + _random.nextDouble() * 100,
      cpuUsage: 0.3 + _random.nextDouble() * 0.4,
      memoryUsage: 0.4 + _random.nextDouble() * 0.3,
      networkTraffic: 1000 + _random.nextInt(5000),
      securityScore: 8.0 + _random.nextDouble() * 2.0,
    );
  }

  ThreatEvent _generateThreatEvent() {
    final threatTypes = [
      'Brute Force Attack',
      'SQL Injection Attempt',
      'Malware Detection',
      'Suspicious IP Activity',
      'Phishing Attempt',
      'DDoS Attack',
      'Insider Threat',
      'Data Exfiltration',
      'Privilege Escalation',
      'Zero-Day Exploit',
    ];

    final severities = ['Low', 'Medium', 'High', 'Critical'];
    final sources = ['External', 'Internal', 'Unknown'];
    final statuses = ['Detected', 'Investigating', 'Mitigated', 'Resolved'];

    return ThreatEvent(
      id: 'THREAT_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      type: threatTypes[_random.nextInt(threatTypes.length)],
      severity: severities[_random.nextInt(severities.length)],
      source: sources[_random.nextInt(sources.length)],
      targetAsset: 'Asset_${_random.nextInt(100)}',
      description: 'Automated threat detection alert',
      status: statuses[_random.nextInt(statuses.length)],
      riskScore: _random.nextDouble() * 10,
      affectedUsers: _random.nextInt(20),
      ipAddress: '192.168.${_random.nextInt(255)}.${_random.nextInt(255)}',
      userAgent: 'ThreatAgent/${_random.nextInt(10)}.0',
      mitigationSteps: [
        'Monitor network traffic',
        'Block suspicious IPs',
        'Update security policies',
        'Notify security team',
      ],
    );
  }

  UserActivity _generateUserActivity() {
    final activities = [
      'Login',
      'Logout',
      'File Access',
      'Data Export',
      'Password Change',
      'Profile Update',
      'API Call',
      'Report Generation',
      'Settings Change',
      'Admin Action',
    ];

    final locations = [
      'New York, US',
      'London, UK',
      'Tokyo, JP',
      'Sydney, AU',
      'Berlin, DE',
      'Toronto, CA',
      'Mumbai, IN',
      'São Paulo, BR',
    ];

    return UserActivity(
      id: 'ACTIVITY_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      userId: 'user_${_random.nextInt(1000)}',
      userName: 'User ${_random.nextInt(1000)}',
      activity: activities[_random.nextInt(activities.length)],
      ipAddress: '192.168.${_random.nextInt(255)}.${_random.nextInt(255)}',
      location: locations[_random.nextInt(locations.length)],
      deviceType: _random.nextBool() ? 'Mobile' : 'Desktop',
      riskScore: _random.nextDouble() * 10,
      success: _random.nextDouble() > 0.1, // 90% success rate
      duration: Duration(seconds: _random.nextInt(300)),
      dataAccessed: _random.nextInt(1000),
    );
  }

  SystemHealth _generateSystemHealth() {
    return SystemHealth(
      timestamp: DateTime.now(),
      overallHealth: 0.85 + _random.nextDouble() * 0.1,
      servicesOnline: 15 + _random.nextInt(3),
      totalServices: 17,
      cpuUsage: 0.3 + _random.nextDouble() * 0.4,
      memoryUsage: 0.4 + _random.nextDouble() * 0.3,
      diskUsage: 0.2 + _random.nextDouble() * 0.3,
      networkLatency: 10 + _random.nextDouble() * 40,
      errorRate: _random.nextDouble() * 0.05,
      throughput: 1000 + _random.nextInt(2000),
      activeConnections: 50 + _random.nextInt(100),
      queueLength: _random.nextInt(20),
      cacheHitRate: 0.8 + _random.nextDouble() * 0.15,
      databaseConnections: 10 + _random.nextInt(10),
    );
  }

  ComplianceStatus _generateComplianceStatus() {
    final frameworks = ['GDPR', 'HIPAA', 'SOX', 'PCI-DSS', 'ISO 27001'];
    
    return ComplianceStatus(
      timestamp: DateTime.now(),
      overallScore: 0.85 + _random.nextDouble() * 0.1,
      frameworkScores: {
        for (String framework in frameworks)
          framework: 0.8 + _random.nextDouble() * 0.15
      },
      violationsCount: _random.nextInt(5),
      auditTrailHealth: 0.9 + _random.nextDouble() * 0.08,
      dataRetentionCompliance: 0.95 + _random.nextDouble() * 0.04,
      accessControlCompliance: 0.88 + _random.nextDouble() * 0.1,
      encryptionCompliance: 0.92 + _random.nextDouble() * 0.06,
      incidentResponseReadiness: 0.85 + _random.nextDouble() * 0.1,
      lastAuditDate: DateTime.now().subtract(Duration(days: _random.nextInt(90))),
      nextAuditDate: DateTime.now().add(Duration(days: 30 + _random.nextInt(60))),
    );
  }

  // Analytics queries
  List<SecurityMetrics> getMetricsHistory({Duration? period}) {
    if (period == null) return List.from(_metricsHistory);
    
    final cutoff = DateTime.now().subtract(period);
    return _metricsHistory.where((m) => m.timestamp.isAfter(cutoff)).toList();
  }

  List<ThreatEvent> getThreatHistory({Duration? period, String? severity}) {
    var threats = List<ThreatEvent>.from(_threatHistory);
    
    if (period != null) {
      final cutoff = DateTime.now().subtract(period);
      threats = threats.where((t) => t.timestamp.isAfter(cutoff)).toList();
    }
    
    if (severity != null) {
      threats = threats.where((t) => t.severity == severity).toList();
    }
    
    return threats;
  }

  List<UserActivity> getActivityHistory({Duration? period, String? userId}) {
    var activities = List<UserActivity>.from(_activityHistory);
    
    if (period != null) {
      final cutoff = DateTime.now().subtract(period);
      activities = activities.where((a) => a.timestamp.isAfter(cutoff)).toList();
    }
    
    if (userId != null) {
      activities = activities.where((a) => a.userId == userId).toList();
    }
    
    return activities;
  }

  Map<String, dynamic> getAnalyticsSummary() {
    final lastHour = DateTime.now().subtract(const Duration(hours: 1));
    final recentMetrics = _metricsHistory.where((m) => m.timestamp.isAfter(lastHour)).toList();
    final recentThreats = _threatHistory.where((t) => t.timestamp.isAfter(lastHour)).toList();
    final recentActivities = _activityHistory.where((a) => a.timestamp.isAfter(lastHour)).toList();

    return {
      'summary_period': 'Last Hour',
      'total_threats': recentThreats.length,
      'critical_threats': recentThreats.where((t) => t.severity == 'Critical').length,
      'high_threats': recentThreats.where((t) => t.severity == 'High').length,
      'total_activities': recentActivities.length,
      'failed_activities': recentActivities.where((a) => !a.success).length,
      'average_response_time': recentMetrics.isNotEmpty 
          ? recentMetrics.map((m) => m.responseTime).reduce((a, b) => a + b) / recentMetrics.length
          : 0.0,
      'average_security_score': recentMetrics.isNotEmpty
          ? recentMetrics.map((m) => m.securityScore).reduce((a, b) => a + b) / recentMetrics.length
          : 0.0,
      'unique_users': recentActivities.map((a) => a.userId).toSet().length,
      'top_threat_types': _getTopThreatTypes(recentThreats),
      'top_user_activities': _getTopActivities(recentActivities),
    };
  }

  Map<String, int> _getTopThreatTypes(List<ThreatEvent> threats) {
    final counts = <String, int>{};
    for (final threat in threats) {
      counts[threat.type] = (counts[threat.type] ?? 0) + 1;
    }
    return Map.fromEntries(
      counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))
    );
  }

  Map<String, int> _getTopActivities(List<UserActivity> activities) {
    final counts = <String, int>{};
    for (final activity in activities) {
      counts[activity.activity] = (counts[activity.activity] ?? 0) + 1;
    }
    return Map.fromEntries(
      counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))
    );
  }

  Map<String, dynamic> getRealTimeAnalyticsMetrics() {
    return {
      'metrics_generated': _metricsHistory.length,
      'threats_detected': _threatHistory.length,
      'activities_logged': _activityHistory.length,
      'health_checks': _healthHistory.length,
      'compliance_checks': _complianceHistory.length,
      'streams_active': 5,
      'last_update': DateTime.now().toIso8601String(),
      'data_retention_hours': 24,
    };
  }

  void dispose() {
    _metricsTimer?.cancel();
    _threatTimer?.cancel();
    _activityTimer?.cancel();
    _healthTimer?.cancel();
    _complianceTimer?.cancel();
    
    _metricsController.close();
    _threatController.close();
    _activityController.close();
    _healthController.close();
    _complianceController.close();
  }
}

// Data models
class SecurityMetrics {
  final DateTime timestamp;
  final int threatsDetected;
  final int threatsBlocked;
  final int activeUsers;
  final int failedLogins;
  final int successfulLogins;
  final double mfaUsage;
  final int encryptionOperations;
  final int apiRequests;
  final double responseTime;
  final double cpuUsage;
  final double memoryUsage;
  final int networkTraffic;
  final double securityScore;

  SecurityMetrics({
    required this.timestamp,
    required this.threatsDetected,
    required this.threatsBlocked,
    required this.activeUsers,
    required this.failedLogins,
    required this.successfulLogins,
    required this.mfaUsage,
    required this.encryptionOperations,
    required this.apiRequests,
    required this.responseTime,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.networkTraffic,
    required this.securityScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'threats_detected': threatsDetected,
      'threats_blocked': threatsBlocked,
      'active_users': activeUsers,
      'failed_logins': failedLogins,
      'successful_logins': successfulLogins,
      'mfa_usage': mfaUsage,
      'encryption_operations': encryptionOperations,
      'api_requests': apiRequests,
      'response_time': responseTime,
      'cpu_usage': cpuUsage,
      'memory_usage': memoryUsage,
      'network_traffic': networkTraffic,
      'security_score': securityScore,
    };
  }
}

class ThreatEvent {
  final String id;
  final DateTime timestamp;
  final String type;
  final String severity;
  final String source;
  final String targetAsset;
  final String description;
  final String status;
  final double riskScore;
  final int affectedUsers;
  final String ipAddress;
  final String userAgent;
  final List<String> mitigationSteps;

  ThreatEvent({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.severity,
    required this.source,
    required this.targetAsset,
    required this.description,
    required this.status,
    required this.riskScore,
    required this.affectedUsers,
    required this.ipAddress,
    required this.userAgent,
    required this.mitigationSteps,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'severity': severity,
      'source': source,
      'target_asset': targetAsset,
      'description': description,
      'status': status,
      'risk_score': riskScore,
      'affected_users': affectedUsers,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'mitigation_steps': mitigationSteps,
    };
  }
}

class UserActivity {
  final String id;
  final DateTime timestamp;
  final String userId;
  final String userName;
  final String activity;
  final String ipAddress;
  final String location;
  final String deviceType;
  final double riskScore;
  final bool success;
  final Duration duration;
  final int dataAccessed;

  UserActivity({
    required this.id,
    required this.timestamp,
    required this.userId,
    required this.userName,
    required this.activity,
    required this.ipAddress,
    required this.location,
    required this.deviceType,
    required this.riskScore,
    required this.success,
    required this.duration,
    required this.dataAccessed,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'user_id': userId,
      'user_name': userName,
      'activity': activity,
      'ip_address': ipAddress,
      'location': location,
      'device_type': deviceType,
      'risk_score': riskScore,
      'success': success,
      'duration_seconds': duration.inSeconds,
      'data_accessed': dataAccessed,
    };
  }
}

class SystemHealth {
  final DateTime timestamp;
  final double overallHealth;
  final int servicesOnline;
  final int totalServices;
  final double cpuUsage;
  final double memoryUsage;
  final double diskUsage;
  final double networkLatency;
  final double errorRate;
  final int throughput;
  final int activeConnections;
  final int queueLength;
  final double cacheHitRate;
  final int databaseConnections;

  SystemHealth({
    required this.timestamp,
    required this.overallHealth,
    required this.servicesOnline,
    required this.totalServices,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.diskUsage,
    required this.networkLatency,
    required this.errorRate,
    required this.throughput,
    required this.activeConnections,
    required this.queueLength,
    required this.cacheHitRate,
    required this.databaseConnections,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'overall_health': overallHealth,
      'services_online': servicesOnline,
      'total_services': totalServices,
      'cpu_usage': cpuUsage,
      'memory_usage': memoryUsage,
      'disk_usage': diskUsage,
      'network_latency': networkLatency,
      'error_rate': errorRate,
      'throughput': throughput,
      'active_connections': activeConnections,
      'queue_length': queueLength,
      'cache_hit_rate': cacheHitRate,
      'database_connections': databaseConnections,
    };
  }
}

class ComplianceStatus {
  final DateTime timestamp;
  final double overallScore;
  final Map<String, double> frameworkScores;
  final int violationsCount;
  final double auditTrailHealth;
  final double dataRetentionCompliance;
  final double accessControlCompliance;
  final double encryptionCompliance;
  final double incidentResponseReadiness;
  final DateTime lastAuditDate;
  final DateTime nextAuditDate;

  ComplianceStatus({
    required this.timestamp,
    required this.overallScore,
    required this.frameworkScores,
    required this.violationsCount,
    required this.auditTrailHealth,
    required this.dataRetentionCompliance,
    required this.accessControlCompliance,
    required this.encryptionCompliance,
    required this.incidentResponseReadiness,
    required this.lastAuditDate,
    required this.nextAuditDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'overall_score': overallScore,
      'framework_scores': frameworkScores,
      'violations_count': violationsCount,
      'audit_trail_health': auditTrailHealth,
      'data_retention_compliance': dataRetentionCompliance,
      'access_control_compliance': accessControlCompliance,
      'encryption_compliance': encryptionCompliance,
      'incident_response_readiness': incidentResponseReadiness,
      'last_audit_date': lastAuditDate.toIso8601String(),
      'next_audit_date': nextAuditDate.toIso8601String(),
    };
  }
}
