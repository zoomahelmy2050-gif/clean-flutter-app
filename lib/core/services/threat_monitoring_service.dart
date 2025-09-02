import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThreatLevel {
  low,
  medium,
  high,
  critical,
}

enum ThreatType {
  bruteForce,
  credentialStuffing,
  suspiciousLogin,
  anomalousActivity,
  rateLimitExceeded,
  maliciousIP,
  deviceFingerprint,
  geolocationAnomaly,
  dataExfiltration,
  privilegeEscalation,
}

class ThreatEvent {
  final String id;
  final ThreatType type;
  final ThreatLevel level;
  final String description;
  final DateTime timestamp;
  final String? sourceIP;
  final String? userEmail;
  final String? deviceId;
  final Map<String, dynamic> metadata;
  final bool resolved;
  final String? resolvedBy;
  final DateTime? resolvedAt;

  ThreatEvent({
    required this.id,
    required this.type,
    required this.level,
    required this.description,
    required this.timestamp,
    this.sourceIP,
    this.userEmail,
    this.deviceId,
    this.metadata = const {},
    this.resolved = false,
    this.resolvedBy,
    this.resolvedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'level': level.name,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
    'sourceIP': sourceIP,
    'userEmail': userEmail,
    'deviceId': deviceId,
    'metadata': metadata,
    'resolved': resolved,
    'resolvedBy': resolvedBy,
    'resolvedAt': resolvedAt?.toIso8601String(),
  };

  factory ThreatEvent.fromJson(Map<String, dynamic> json) {
    return ThreatEvent(
      id: json['id'],
      type: ThreatType.values.firstWhere((e) => e.name == json['type']),
      level: ThreatLevel.values.firstWhere((e) => e.name == json['level']),
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      sourceIP: json['sourceIP'],
      userEmail: json['userEmail'],
      deviceId: json['deviceId'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      resolved: json['resolved'] ?? false,
      resolvedBy: json['resolvedBy'],
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
    );
  }

  ThreatEvent copyWith({
    bool? resolved,
    String? resolvedBy,
    DateTime? resolvedAt,
  }) {
    return ThreatEvent(
      id: id,
      type: type,
      level: level,
      description: description,
      timestamp: timestamp,
      sourceIP: sourceIP,
      userEmail: userEmail,
      deviceId: deviceId,
      metadata: metadata,
      resolved: resolved ?? this.resolved,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}

class ThreatRule {
  final String id;
  final String name;
  final ThreatType type;
  final bool enabled;
  final Map<String, dynamic> conditions;
  final ThreatLevel severity;
  final List<String> actions;

  ThreatRule({
    required this.id,
    required this.name,
    required this.type,
    required this.enabled,
    required this.conditions,
    required this.severity,
    required this.actions,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'enabled': enabled,
    'conditions': conditions,
    'severity': severity.name,
    'actions': actions,
  };

  factory ThreatRule.fromJson(Map<String, dynamic> json) {
    return ThreatRule(
      id: json['id'],
      name: json['name'],
      type: ThreatType.values.firstWhere((e) => e.name == json['type']),
      enabled: json['enabled'],
      conditions: Map<String, dynamic>.from(json['conditions']),
      severity: ThreatLevel.values.firstWhere((e) => e.name == json['severity']),
      actions: List<String>.from(json['actions']),
    );
  }
}

class ThreatMonitoringService extends ChangeNotifier {
  final List<ThreatEvent> _threats = [];
  final List<ThreatRule> _rules = [];
  Timer? _monitoringTimer;
  bool _isMonitoring = false;
  
  static const String _threatsKey = 'threat_events';
  static const String _rulesKey = 'threat_rules';

  // Getters
  List<ThreatEvent> get threats => List.unmodifiable(_threats);
  List<ThreatRule> get rules => List.unmodifiable(_rules);
  bool get isMonitoring => _isMonitoring;
  
  List<ThreatEvent> get activeThreatsByLevel {
    final active = _threats.where((t) => !t.resolved).toList();
    active.sort((a, b) => _getThreatLevelPriority(b.level).compareTo(_getThreatLevelPriority(a.level)));
    return active;
  }

  /// Initialize threat monitoring service
  Future<void> initialize() async {
    await _loadThreats();
    await _loadRules();
    await _initializeDefaultRules();
    await startMonitoring();
  }

  /// Load threats from storage
  Future<void> _loadThreats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final threatsJson = prefs.getStringList(_threatsKey) ?? [];
      
      _threats.clear();
      for (final threatJson in threatsJson) {
        final Map<String, dynamic> data = jsonDecode(threatJson);
        _threats.add(ThreatEvent.fromJson(data));
      }
    } catch (e) {
      debugPrint('Error loading threats: $e');
    }
  }

  /// Save threats to storage
  Future<void> _saveThreats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final threatsJson = _threats.map((t) => jsonEncode(t.toJson())).toList();
      await prefs.setStringList(_threatsKey, threatsJson);
    } catch (e) {
      debugPrint('Error saving threats: $e');
    }
  }

  /// Load rules from storage
  Future<void> _loadRules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rulesJson = prefs.getStringList(_rulesKey) ?? [];
      
      _rules.clear();
      for (final ruleJson in rulesJson) {
        final Map<String, dynamic> data = jsonDecode(ruleJson);
        _rules.add(ThreatRule.fromJson(data));
      }
    } catch (e) {
      debugPrint('Error loading rules: $e');
    }
  }

  /// Save rules to storage
  Future<void> _saveRules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rulesJson = _rules.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList(_rulesKey, rulesJson);
    } catch (e) {
      debugPrint('Error saving rules: $e');
    }
  }

  /// Initialize default threat detection rules
  Future<void> _initializeDefaultRules() async {
    if (_rules.isNotEmpty) return;

    final defaultRules = [
      ThreatRule(
        id: 'brute_force_detection',
        name: 'Brute Force Detection',
        type: ThreatType.bruteForce,
        enabled: true,
        conditions: {'failed_attempts': 5, 'time_window': 300},
        severity: ThreatLevel.high,
        actions: ['block_ip', 'alert_admin'],
      ),
      ThreatRule(
        id: 'suspicious_login_location',
        name: 'Suspicious Login Location',
        type: ThreatType.geolocationAnomaly,
        enabled: true,
        conditions: {'distance_threshold': 1000, 'time_threshold': 3600},
        severity: ThreatLevel.medium,
        actions: ['require_mfa', 'alert_user'],
      ),
      ThreatRule(
        id: 'rate_limit_exceeded',
        name: 'Rate Limit Exceeded',
        type: ThreatType.rateLimitExceeded,
        enabled: true,
        conditions: {'requests_per_minute': 100},
        severity: ThreatLevel.medium,
        actions: ['throttle_requests', 'alert_admin'],
      ),
      ThreatRule(
        id: 'anomalous_device',
        name: 'Anomalous Device Detection',
        type: ThreatType.deviceFingerprint,
        enabled: true,
        conditions: {'new_device': true, 'risk_score': 0.7},
        severity: ThreatLevel.medium,
        actions: ['require_verification', 'alert_user'],
      ),
    ];

    _rules.addAll(defaultRules);
    await _saveRules();
  }

  /// Start real-time threat monitoring
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _performThreatScan();
    });
    
    notifyListeners();
  }

  /// Stop threat monitoring
  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    notifyListeners();
  }

  /// Perform threat scan
  void _performThreatScan() {
    // Simulate threat detection - in real implementation, this would analyze logs, network traffic, etc.
    final random = Random();
    
    // Randomly generate threats for demonstration
    if (random.nextDouble() < 0.1) { // 10% chance of detecting a threat
      final threatTypes = ThreatType.values;
      final threatType = threatTypes[random.nextInt(threatTypes.length)];
      
      _generateSimulatedThreat(threatType);
    }
  }

  /// Generate simulated threat for demonstration
  void _generateSimulatedThreat(ThreatType type) {
    final random = Random();
    final levels = [ThreatLevel.low, ThreatLevel.medium, ThreatLevel.high];
    final level = levels[random.nextInt(levels.length)];
    
    final threat = ThreatEvent(
      id: 'threat_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      level: level,
      description: _getThreatDescription(type, level),
      timestamp: DateTime.now(),
      sourceIP: _generateRandomIP(),
      userEmail: random.nextBool() ? 'user${random.nextInt(100)}@example.com' : null,
      deviceId: random.nextBool() ? 'device_${random.nextInt(1000)}' : null,
      metadata: _generateThreatMetadata(type),
    );

    addThreat(threat);
  }

  /// Add new threat event
  Future<void> addThreat(ThreatEvent threat) async {
    _threats.insert(0, threat);
    
    // Keep only last 1000 threats
    if (_threats.length > 1000) {
      _threats.removeRange(1000, _threats.length);
    }
    
    await _saveThreats();
    notifyListeners();
    
    // Execute automated responses
    await _executeAutomatedResponse(threat);
  }

  /// Resolve threat
  Future<void> resolveThreat(String threatId, String resolvedBy) async {
    final index = _threats.indexWhere((t) => t.id == threatId);
    if (index != -1) {
      _threats[index] = _threats[index].copyWith(
        resolved: true,
        resolvedBy: resolvedBy,
        resolvedAt: DateTime.now(),
      );
      
      await _saveThreats();
      notifyListeners();
    }
  }

  /// Execute automated response to threat
  Future<void> _executeAutomatedResponse(ThreatEvent threat) async {
    final applicableRules = _rules.where((rule) => 
      rule.enabled && rule.type == threat.type
    ).toList();

    for (final rule in applicableRules) {
      for (final action in rule.actions) {
        await _executeAction(action, threat);
      }
    }
  }

  /// Execute specific action
  Future<void> _executeAction(String action, ThreatEvent threat) async {
    switch (action) {
      case 'block_ip':
        debugPrint('Blocking IP: ${threat.sourceIP}');
        break;
      case 'alert_admin':
        debugPrint('Alerting admin about threat: ${threat.description}');
        break;
      case 'require_mfa':
        debugPrint('Requiring MFA for user: ${threat.userEmail}');
        break;
      case 'alert_user':
        debugPrint('Alerting user: ${threat.userEmail}');
        break;
      case 'throttle_requests':
        debugPrint('Throttling requests from: ${threat.sourceIP}');
        break;
      case 'require_verification':
        debugPrint('Requiring verification for device: ${threat.deviceId}');
        break;
    }
  }

  /// Get threat statistics
  Map<String, dynamic> getThreatStatistics() {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));
    final last7d = now.subtract(const Duration(days: 7));
    
    final threats24h = _threats.where((t) => t.timestamp.isAfter(last24h)).toList();
    final threats7d = _threats.where((t) => t.timestamp.isAfter(last7d)).toList();
    
    return {
      'total_threats': _threats.length,
      'active_threats': _threats.where((t) => !t.resolved).length,
      'threats_24h': threats24h.length,
      'threats_7d': threats7d.length,
      'critical_threats': _threats.where((t) => t.level == ThreatLevel.critical && !t.resolved).length,
      'high_threats': _threats.where((t) => t.level == ThreatLevel.high && !t.resolved).length,
      'by_type': _getThreatsByType(),
      'resolution_rate': _getResolutionRate(),
    };
  }

  /// Get threats grouped by type
  Map<String, int> _getThreatsByType() {
    final Map<String, int> byType = {};
    for (final threat in _threats.where((t) => !t.resolved)) {
      byType[threat.type.name] = (byType[threat.type.name] ?? 0) + 1;
    }
    return byType;
  }

  /// Get threat resolution rate
  double _getResolutionRate() {
    if (_threats.isEmpty) return 0.0;
    final resolved = _threats.where((t) => t.resolved).length;
    return resolved / _threats.length;
  }

  /// Get threat level priority for sorting
  int _getThreatLevelPriority(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.critical:
        return 4;
      case ThreatLevel.high:
        return 3;
      case ThreatLevel.medium:
        return 2;
      case ThreatLevel.low:
        return 1;
    }
  }

  /// Generate threat description
  String _getThreatDescription(ThreatType type, ThreatLevel level) {
    switch (type) {
      case ThreatType.bruteForce:
        return 'Multiple failed login attempts detected from same source';
      case ThreatType.credentialStuffing:
        return 'Credential stuffing attack detected';
      case ThreatType.suspiciousLogin:
        return 'Login from suspicious location or device';
      case ThreatType.anomalousActivity:
        return 'Unusual user activity pattern detected';
      case ThreatType.rateLimitExceeded:
        return 'Rate limit exceeded for API endpoints';
      case ThreatType.maliciousIP:
        return 'Request from known malicious IP address';
      case ThreatType.deviceFingerprint:
        return 'Suspicious device fingerprint detected';
      case ThreatType.geolocationAnomaly:
        return 'Login from unusual geographic location';
      case ThreatType.dataExfiltration:
        return 'Potential data exfiltration attempt';
      case ThreatType.privilegeEscalation:
        return 'Unauthorized privilege escalation attempt';
    }
  }

  /// Generate threat metadata
  Map<String, dynamic> _generateThreatMetadata(ThreatType type) {
    final random = Random();
    
    switch (type) {
      case ThreatType.bruteForce:
        return {
          'failed_attempts': random.nextInt(20) + 5,
          'time_window': random.nextInt(300) + 60,
        };
      case ThreatType.geolocationAnomaly:
        return {
          'previous_location': 'New York, US',
          'current_location': 'Moscow, RU',
          'distance_km': random.nextInt(10000) + 1000,
        };
      case ThreatType.rateLimitExceeded:
        return {
          'requests_per_minute': random.nextInt(500) + 100,
          'endpoint': '/api/auth/login',
        };
      default:
        return {
          'severity_score': random.nextDouble(),
          'confidence': random.nextDouble(),
        };
    }
  }

  /// Generate random IP for simulation
  String _generateRandomIP() {
    final random = Random();
    return '${random.nextInt(256)}.${random.nextInt(256)}.${random.nextInt(256)}.${random.nextInt(256)}';
  }

  /// Export threat data
  Map<String, dynamic> exportThreatData() {
    return {
      'threats': _threats.map((t) => t.toJson()).toList(),
      'rules': _rules.map((r) => r.toJson()).toList(),
      'statistics': getThreatStatistics(),
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  /// Clear old threats
  Future<void> clearOldThreats({int daysToKeep = 30}) async {
    final cutoff = DateTime.now().subtract(Duration(days: daysToKeep));
    _threats.removeWhere((threat) => threat.timestamp.isBefore(cutoff));
    await _saveThreats();
    notifyListeners();
  }

  @override
  void dispose() {
    _monitoringTimer?.cancel();
    super.dispose();
  }
}
