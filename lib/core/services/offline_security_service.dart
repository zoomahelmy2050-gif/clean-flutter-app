import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:developer' as developer;

class OfflineThreat {
  final String threatId;
  final String type;
  final String severity;
  final String description;
  final Map<String, dynamic> indicators;
  final DateTime detectedAt;
  final bool requiresOnlineVerification;

  OfflineThreat({
    required this.threatId,
    required this.type,
    required this.severity,
    required this.description,
    required this.indicators,
    required this.detectedAt,
    this.requiresOnlineVerification = false,
  });

  Map<String, dynamic> toJson() => {
    'threat_id': threatId,
    'type': type,
    'severity': severity,
    'description': description,
    'indicators': indicators,
    'detected_at': detectedAt.toIso8601String(),
    'requires_online_verification': requiresOnlineVerification,
  };
}

class LocalSecurityRule {
  final String ruleId;
  final String name;
  final String category;
  final Map<String, dynamic> conditions;
  final String action;
  final int priority;
  final bool isEnabled;

  LocalSecurityRule({
    required this.ruleId,
    required this.name,
    required this.category,
    required this.conditions,
    required this.action,
    required this.priority,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() => {
    'rule_id': ruleId,
    'name': name,
    'category': category,
    'conditions': conditions,
    'action': action,
    'priority': priority,
    'is_enabled': isEnabled,
  };
}

class SecurityEvent {
  final String eventId;
  final String type;
  final String source;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String severity;

  SecurityEvent({
    required this.eventId,
    required this.type,
    required this.source,
    required this.data,
    required this.timestamp,
    required this.severity,
  });

  Map<String, dynamic> toJson() => {
    'event_id': eventId,
    'type': type,
    'source': source,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'severity': severity,
  };
}

class OfflineSecurityService {
  static final OfflineSecurityService _instance = OfflineSecurityService._internal();
  factory OfflineSecurityService() => _instance;
  OfflineSecurityService._internal();

  final List<OfflineThreat> _detectedThreats = [];
  final List<LocalSecurityRule> _securityRules = [];
  final List<SecurityEvent> _securityEvents = [];
  final Map<String, List<String>> _threatSignatures = {};
  final Map<String, dynamic> _behaviorBaseline = {};
  
  final StreamController<OfflineThreat> _threatController = StreamController.broadcast();
  final StreamController<SecurityEvent> _eventController = StreamController.broadcast();

  Stream<OfflineThreat> get threatStream => _threatController.stream;
  Stream<SecurityEvent> get eventStream => _eventController.stream;

  Timer? _monitoringTimer;
  final Random _random = Random();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _loadThreatSignatures();
    await _setupSecurityRules();
    await _establishBehaviorBaseline();
    _startOfflineMonitoring();
    
    _isInitialized = true;
    developer.log('Offline Security Service initialized', name: 'OfflineSecurityService');
  }

  Future<void> _loadThreatSignatures() async {
    // Load known threat signatures for offline detection
    _threatSignatures.addAll({
      'malware_signatures': [
        'suspicious_file_hash_1',
        'suspicious_file_hash_2',
        'malicious_pattern_1',
      ],
      'phishing_indicators': [
        'fake_login_pattern',
        'credential_harvesting_attempt',
        'suspicious_url_pattern',
      ],
      'data_exfiltration_patterns': [
        'large_data_transfer',
        'unusual_network_activity',
        'unauthorized_file_access',
      ],
      'privilege_escalation_indicators': [
        'admin_access_attempt',
        'system_modification_attempt',
        'unauthorized_permission_request',
      ],
      'injection_attack_patterns': [
        'sql_injection_pattern',
        'xss_attack_pattern',
        'command_injection_pattern',
      ],
    });
  }

  Future<void> _setupSecurityRules() async {
    // Authentication Rules
    _securityRules.add(LocalSecurityRule(
      ruleId: 'auth_failed_attempts',
      name: 'Failed Authentication Attempts',
      category: 'Authentication',
      conditions: {
        'event_type': 'auth_failure',
        'threshold': 5,
        'time_window_minutes': 15,
      },
      action: 'block_user',
      priority: 1,
    ));

    _securityRules.add(LocalSecurityRule(
      ruleId: 'unusual_login_time',
      name: 'Unusual Login Time',
      category: 'Authentication',
      conditions: {
        'event_type': 'login',
        'time_deviation_hours': 6,
        'baseline_required': true,
      },
      action: 'require_additional_verification',
      priority: 2,
    ));

    // Data Access Rules
    _securityRules.add(LocalSecurityRule(
      ruleId: 'bulk_data_access',
      name: 'Bulk Data Access',
      category: 'Data Protection',
      conditions: {
        'event_type': 'data_access',
        'records_threshold': 100,
        'time_window_minutes': 10,
      },
      action: 'alert_and_log',
      priority: 1,
    ));

    _securityRules.add(LocalSecurityRule(
      ruleId: 'sensitive_data_access',
      name: 'Sensitive Data Access',
      category: 'Data Protection',
      conditions: {
        'event_type': 'data_access',
        'data_classification': 'sensitive',
        'outside_business_hours': true,
      },
      action: 'block_and_alert',
      priority: 1,
    ));

    // Network Security Rules
    _securityRules.add(LocalSecurityRule(
      ruleId: 'suspicious_network_activity',
      name: 'Suspicious Network Activity',
      category: 'Network Security',
      conditions: {
        'event_type': 'network_request',
        'unusual_destination': true,
        'data_volume_mb': 50,
      },
      action: 'block_and_investigate',
      priority: 1,
    ));

    // Application Security Rules
    _securityRules.add(LocalSecurityRule(
      ruleId: 'code_injection_attempt',
      name: 'Code Injection Attempt',
      category: 'Application Security',
      conditions: {
        'event_type': 'user_input',
        'contains_injection_pattern': true,
      },
      action: 'block_request',
      priority: 1,
    ));
  }

  Future<void> _establishBehaviorBaseline() async {
    // Establish baseline behavior patterns for anomaly detection
    _behaviorBaseline.addAll({
      'typical_login_hours': [8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
      'average_session_duration_minutes': 45,
      'typical_data_access_volume': 25,
      'common_app_features': ['dashboard', 'profile', 'settings'],
      'normal_network_destinations': ['api.company.com', 'cdn.company.com'],
      'baseline_established_at': DateTime.now().toIso8601String(),
    });
  }

  void _startOfflineMonitoring() {
    _monitoringTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _performOfflineSecurityCheck();
    });
  }

  Future<void> _performOfflineSecurityCheck() async {
    try {
      // Simulate various security events for monitoring
      await _simulateSecurityEvents();
      
      // Process events against security rules
      await _processSecurityRules();
      
      // Perform behavioral analysis
      await _performBehavioralAnalysis();
      
    } catch (e) {
      developer.log('Error during offline security check: $e', name: 'OfflineSecurityService');
    }
  }

  Future<void> _simulateSecurityEvents() async {
    // Simulate authentication events
    if (_random.nextDouble() < 0.3) {
      await _generateSecurityEvent('auth_attempt', 'authentication', {
        'user_id': 'user_${_random.nextInt(100)}',
        'success': _random.nextBool(),
        'ip_address': _generateRandomIP(),
        'user_agent': 'Mobile App',
      });
    }

    // Simulate data access events
    if (_random.nextDouble() < 0.4) {
      await _generateSecurityEvent('data_access', 'data_protection', {
        'user_id': 'user_${_random.nextInt(100)}',
        'resource': 'user_data',
        'records_accessed': _random.nextInt(150),
        'data_classification': _random.nextBool() ? 'sensitive' : 'normal',
      });
    }

    // Simulate network events
    if (_random.nextDouble() < 0.2) {
      await _generateSecurityEvent('network_request', 'network_security', {
        'destination': _random.nextBool() ? 'api.company.com' : 'suspicious-site.com',
        'data_volume_mb': _random.nextInt(100),
        'protocol': 'HTTPS',
      });
    }

    // Simulate user input events
    if (_random.nextDouble() < 0.1) {
      await _generateSecurityEvent('user_input', 'application_security', {
        'input_field': 'search_query',
        'input_value': _random.nextBool() ? 'normal search' : "'; DROP TABLE users; --",
        'contains_special_chars': _random.nextBool(),
      });
    }
  }

  Future<void> _generateSecurityEvent(String type, String source, Map<String, dynamic> data) async {
    final event = SecurityEvent(
      eventId: 'event_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
      type: type,
      source: source,
      data: data,
      timestamp: DateTime.now(),
      severity: _determineSeverity(type, data),
    );

    _securityEvents.add(event);
    _eventController.add(event);

    // Check if event triggers any threats
    await _analyzeEventForThreats(event);
  }

  String _determineSeverity(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'auth_attempt':
        return data['success'] == false ? 'Medium' : 'Low';
      case 'data_access':
        if (data['data_classification'] == 'sensitive' || (data['records_accessed'] ?? 0) > 50) {
          return 'High';
        }
        return 'Medium';
      case 'network_request':
        if (data['destination']?.contains('suspicious') == true) {
          return 'High';
        }
        return 'Low';
      case 'user_input':
        if (data['input_value']?.contains('DROP TABLE') == true || 
            data['input_value']?.contains('<script>') == true) {
          return 'Critical';
        }
        return 'Low';
      default:
        return 'Low';
    }
  }

  Future<void> _processSecurityRules() async {
    for (final rule in _securityRules.where((r) => r.isEnabled)) {
      await _evaluateRule(rule);
    }
  }

  Future<void> _evaluateRule(LocalSecurityRule rule) async {
    final relevantEvents = _getRelevantEvents(rule);
    
    if (_ruleConditionsMet(rule, relevantEvents)) {
      await _executeRuleAction(rule, relevantEvents);
    }
  }

  List<SecurityEvent> _getRelevantEvents(LocalSecurityRule rule) {
    final eventType = rule.conditions['event_type'];
    final timeWindowMinutes = (rule.conditions['time_window_minutes'] as num?)?.toInt() ?? 60;
    final cutoffTime = DateTime.now().subtract(Duration(minutes: timeWindowMinutes));

    return _securityEvents.where((event) => 
      event.type == eventType && 
      event.timestamp.isAfter(cutoffTime)
    ).toList();
  }

  bool _ruleConditionsMet(LocalSecurityRule rule, List<SecurityEvent> events) {
    switch (rule.ruleId) {
      case 'auth_failed_attempts':
        final failedAttempts = events.where((e) => e.data['success'] == false).length;
        return failedAttempts >= ((rule.conditions['threshold'] as num?)?.toInt() ?? 5);
      
      case 'bulk_data_access':
        final totalRecords = events.fold<int>(0, (sum, e) => sum + ((e.data['records_accessed'] as num?)?.toInt() ?? 0));
        return totalRecords >= ((rule.conditions['records_threshold'] as num?)?.toInt() ?? 100);
      
      case 'suspicious_network_activity':
        return events.any((e) => 
          e.data['destination']?.toString().contains('suspicious') == true ||
          ((e.data['data_volume_mb'] as num?)?.toDouble() ?? 0) > ((rule.conditions['data_volume_mb'] as num?)?.toDouble() ?? 50)
        );
      
      case 'code_injection_attempt':
        return events.any((e) => _containsInjectionPattern(e.data['input_value']));
      
      default:
        return false;
    }
  }

  bool _containsInjectionPattern(dynamic input) {
    if (input == null) return false;
    final inputStr = input.toString().toLowerCase();
    
    final injectionPatterns = [
      'drop table',
      'union select',
      '<script>',
      'javascript:',
      'eval(',
      'exec(',
    ];
    
    return injectionPatterns.any((pattern) => inputStr.contains(pattern));
  }

  Future<void> _executeRuleAction(LocalSecurityRule rule, List<SecurityEvent> triggeringEvents) async {
    final threat = OfflineThreat(
      threatId: 'threat_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
      type: rule.category.toLowerCase().replaceAll(' ', '_'),
      severity: _calculateThreatSeverity(rule, triggeringEvents),
      description: 'Rule triggered: ${rule.name}',
      indicators: {
        'rule_id': rule.ruleId,
        'triggering_events': triggeringEvents.length,
        'action_taken': rule.action,
        'detection_time': DateTime.now().toIso8601String(),
      },
      detectedAt: DateTime.now(),
      requiresOnlineVerification: rule.priority == 1,
    );

    _detectedThreats.add(threat);
    _threatController.add(threat);

    developer.log('Offline threat detected: ${threat.type} - ${threat.severity}', 
                 name: 'OfflineSecurityService');
  }

  String _calculateThreatSeverity(LocalSecurityRule rule, List<SecurityEvent> events) {
    if (rule.priority == 1) return 'High';
    if (events.length > 10) return 'Medium';
    return 'Low';
  }

  Future<void> _performBehavioralAnalysis() async {
    final recentEvents = _securityEvents.where((event) => 
      event.timestamp.isAfter(DateTime.now().subtract(const Duration(hours: 1)))
    ).toList();

    await _analyzeLoginPatterns(recentEvents);
    await _analyzeDataAccessPatterns(recentEvents);
    await _analyzeNetworkPatterns(recentEvents);
  }

  Future<void> _analyzeLoginPatterns(List<SecurityEvent> events) async {
    final loginEvents = events.where((e) => e.type == 'auth_attempt').toList();
    final typicalHours = _behaviorBaseline['typical_login_hours'] as List<int>?;

    if (typicalHours == null) return;

    for (final event in loginEvents) {
      final loginHour = event.timestamp.hour;
      
      if (!typicalHours.contains(loginHour)) {
        await _generateBehavioralThreat('unusual_login_time', event);
      }
    }
  }

  Future<void> _analyzeDataAccessPatterns(List<SecurityEvent> events) async {
    final dataEvents = events.where((e) => e.type == 'data_access').toList();
    final totalRecords = dataEvents.fold<int>(0, (sum, e) => sum + ((e.data['records_accessed'] as num?)?.toInt() ?? 0));
    
    final typicalVolume = (_behaviorBaseline['typical_data_access_volume'] as num?)?.toDouble() ?? 25.0;

    if (totalRecords > (typicalVolume * 3)) {
      await _generateBehavioralThreat('excessive_data_access', dataEvents.first);
    }
  }

  Future<void> _analyzeNetworkPatterns(List<SecurityEvent> events) async {
    final networkEvents = events.where((e) => e.type == 'network_request').toList();
    final commonDestinations = _behaviorBaseline['normal_network_destinations'] as List<String>?;

    if (commonDestinations == null) return;

    for (final event in networkEvents) {
      final destination = event.data['destination']?.toString();
      if (destination != null && !commonDestinations.any((d) => destination.contains(d))) {
        await _generateBehavioralThreat('unusual_network_destination', event);
      }
    }
  }

  Future<void> _generateBehavioralThreat(String type, SecurityEvent triggeringEvent) async {
    final threat = OfflineThreat(
      threatId: 'behavioral_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      severity: 'Medium',
      description: 'Behavioral anomaly detected: $type',
      indicators: {
        'triggering_event': triggeringEvent.eventId,
        'baseline_deviation': true,
        'analysis_type': 'behavioral',
      },
      detectedAt: DateTime.now(),
      requiresOnlineVerification: true,
    );

    _detectedThreats.add(threat);
    _threatController.add(threat);
  }

  Future<void> _analyzeEventForThreats(SecurityEvent event) async {
    // Check against known threat signatures
    for (final entry in _threatSignatures.entries) {
      final category = entry.key;
      final signatures = entry.value;
      
      if (_eventMatchesSignatures(event, signatures)) {
        await _generateSignatureThreat(category, event);
      }
    }
  }

  bool _eventMatchesSignatures(SecurityEvent event, List<String> signatures) {
    final eventData = jsonEncode(event.data).toLowerCase();
    return signatures.any((signature) => eventData.contains(signature.toLowerCase()));
  }

  Future<void> _generateSignatureThreat(String category, SecurityEvent event) async {
    final threat = OfflineThreat(
      threatId: 'signature_${DateTime.now().millisecondsSinceEpoch}',
      type: category,
      severity: 'High',
      description: 'Threat signature match: $category',
      indicators: {
        'signature_category': category,
        'matching_event': event.eventId,
        'detection_method': 'signature_based',
      },
      detectedAt: DateTime.now(),
    );

    _detectedThreats.add(threat);
    _threatController.add(threat);
  }

  String _generateRandomIP() {
    return '${_random.nextInt(255)}.${_random.nextInt(255)}.${_random.nextInt(255)}.${_random.nextInt(255)}';
  }

  List<OfflineThreat> getDetectedThreats() {
    return List.from(_detectedThreats);
  }

  List<SecurityEvent> getSecurityEvents({int? limit}) {
    final events = List<SecurityEvent>.from(_securityEvents);
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    if (limit != null && limit > 0) {
      return events.take(limit).toList();
    }
    
    return events;
  }

  Future<void> addCustomRule(LocalSecurityRule rule) async {
    _securityRules.add(rule);
    developer.log('Custom security rule added: ${rule.name}', name: 'OfflineSecurityService');
  }

  Future<void> updateThreatSignatures(Map<String, List<String>> newSignatures) async {
    _threatSignatures.addAll(newSignatures);
    developer.log('Threat signatures updated', name: 'OfflineSecurityService');
  }

  Map<String, dynamic> getOfflineSecurityMetrics() {
    final threatsBySeverity = <String, int>{};
    final threatsByType = <String, int>{};
    
    for (final threat in _detectedThreats) {
      threatsBySeverity[threat.severity] = (threatsBySeverity[threat.severity] ?? 0) + 1;
      threatsByType[threat.type] = (threatsByType[threat.type] ?? 0) + 1;
    }

    return {
      'total_threats_detected': _detectedThreats.length,
      'threats_by_severity': threatsBySeverity,
      'threats_by_type': threatsByType,
      'total_security_events': _securityEvents.length,
      'active_rules': _securityRules.where((r) => r.isEnabled).length,
      'threat_signatures_loaded': _threatSignatures.length,
      'monitoring_active': _monitoringTimer?.isActive ?? false,
      'last_check': DateTime.now().toIso8601String(),
    };
  }

  void dispose() {
    _monitoringTimer?.cancel();
    _threatController.close();
    _eventController.close();
  }
}
