import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RateLimitType {
  perIP,
  perUser,
  perEndpoint,
  global,
}

enum RateLimitAction {
  allow,
  throttle,
  block,
  challenge,
}

class RateLimitRule {
  final String id;
  final String name;
  final RateLimitType type;
  final String pattern; // IP pattern, user pattern, or endpoint pattern
  final int maxRequests;
  final Duration timeWindow;
  final RateLimitAction action;
  final bool enabled;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  RateLimitRule({
    required this.id,
    required this.name,
    required this.type,
    required this.pattern,
    required this.maxRequests,
    required this.timeWindow,
    required this.action,
    this.enabled = true,
    required this.createdAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'pattern': pattern,
    'maxRequests': maxRequests,
    'timeWindow': timeWindow.inMilliseconds,
    'action': action.name,
    'enabled': enabled,
    'createdAt': createdAt.toIso8601String(),
    'metadata': metadata,
  };

  factory RateLimitRule.fromJson(Map<String, dynamic> json) {
    return RateLimitRule(
      id: json['id'],
      name: json['name'],
      type: RateLimitType.values.firstWhere((e) => e.name == json['type']),
      pattern: json['pattern'],
      maxRequests: json['maxRequests'],
      timeWindow: Duration(milliseconds: json['timeWindow']),
      action: RateLimitAction.values.firstWhere((e) => e.name == json['action']),
      enabled: json['enabled'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

class RateLimitViolation {
  final String id;
  final String ruleId;
  final String identifier; // IP, user, or endpoint
  final int requestCount;
  final Duration timeWindow;
  final RateLimitAction action;
  final DateTime timestamp;
  final Map<String, dynamic> context;

  RateLimitViolation({
    required this.id,
    required this.ruleId,
    required this.identifier,
    required this.requestCount,
    required this.timeWindow,
    required this.action,
    required this.timestamp,
    this.context = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'ruleId': ruleId,
    'identifier': identifier,
    'requestCount': requestCount,
    'timeWindow': timeWindow.inMilliseconds,
    'action': action.name,
    'timestamp': timestamp.toIso8601String(),
    'context': context,
  };

  factory RateLimitViolation.fromJson(Map<String, dynamic> json) {
    return RateLimitViolation(
      id: json['id'],
      ruleId: json['ruleId'],
      identifier: json['identifier'],
      requestCount: json['requestCount'],
      timeWindow: Duration(milliseconds: json['timeWindow']),
      action: RateLimitAction.values.firstWhere((e) => e.name == json['action']),
      timestamp: DateTime.parse(json['timestamp']),
      context: Map<String, dynamic>.from(json['context'] ?? {}),
    );
  }
}

class RequestRecord {
  final DateTime timestamp;
  final String endpoint;
  final String? userAgent;
  final Map<String, dynamic> headers;

  RequestRecord({
    required this.timestamp,
    required this.endpoint,
    this.userAgent,
    this.headers = const {},
  });
}

class RateLimitingService extends ChangeNotifier {
  final List<RateLimitRule> _rules = [];
  final List<RateLimitViolation> _violations = [];
  final Map<String, List<RequestRecord>> _requestHistory = {};
  final Map<String, DateTime> _blockedUntil = {};
  Timer? _cleanupTimer;
  
  static const String _rulesKey = 'rate_limit_rules';
  static const String _violationsKey = 'rate_limit_violations';

  // Getters
  List<RateLimitRule> get rules => List.unmodifiable(_rules);
  List<RateLimitViolation> get violations => List.unmodifiable(_violations);
  Map<String, DateTime> get blockedIdentifiers => Map.unmodifiable(_blockedUntil);

  /// Initialize rate limiting service
  Future<void> initialize() async {
    await _loadRules();
    await _loadViolations();
    await _initializeDefaultRules();
    await _startCleanupTimer();
  }

  /// Load rules from storage
  Future<void> _loadRules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rulesJson = prefs.getStringList(_rulesKey) ?? [];
      
      _rules.clear();
      for (final ruleJson in rulesJson) {
        final Map<String, dynamic> data = jsonDecode(ruleJson);
        _rules.add(RateLimitRule.fromJson(data));
      }
    } catch (e) {
      debugPrint('Error loading rate limit rules: $e');
    }
  }

  /// Save rules to storage
  Future<void> _saveRules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rulesJson = _rules.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList(_rulesKey, rulesJson);
    } catch (e) {
      debugPrint('Error saving rate limit rules: $e');
    }
  }

  /// Load violations from storage
  Future<void> _loadViolations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final violationsJson = prefs.getStringList(_violationsKey) ?? [];
      
      _violations.clear();
      for (final violationJson in violationsJson) {
        final Map<String, dynamic> data = jsonDecode(violationJson);
        _violations.add(RateLimitViolation.fromJson(data));
      }
    } catch (e) {
      debugPrint('Error loading rate limit violations: $e');
    }
  }

  /// Save violations to storage
  Future<void> _saveViolations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final violationsJson = _violations.map((v) => jsonEncode(v.toJson())).toList();
      await prefs.setStringList(_violationsKey, violationsJson);
    } catch (e) {
      debugPrint('Error saving rate limit violations: $e');
    }
  }

  /// Initialize default rules
  Future<void> _initializeDefaultRules() async {
    if (_rules.isNotEmpty) return;

    final defaultRules = [
      RateLimitRule(
        id: 'global_api_limit',
        name: 'Global API Rate Limit',
        type: RateLimitType.global,
        pattern: '*',
        maxRequests: 1000,
        timeWindow: const Duration(minutes: 1),
        action: RateLimitAction.throttle,
        createdAt: DateTime.now(),
      ),
      RateLimitRule(
        id: 'login_attempts',
        name: 'Login Attempts Limit',
        type: RateLimitType.perIP,
        pattern: '/api/auth/login',
        maxRequests: 5,
        timeWindow: const Duration(minutes: 15),
        action: RateLimitAction.block,
        createdAt: DateTime.now(),
      ),
      RateLimitRule(
        id: 'user_api_calls',
        name: 'User API Calls Limit',
        type: RateLimitType.perUser,
        pattern: '/api/*',
        maxRequests: 100,
        timeWindow: const Duration(minutes: 1),
        action: RateLimitAction.throttle,
        createdAt: DateTime.now(),
      ),
      RateLimitRule(
        id: 'registration_limit',
        name: 'Registration Rate Limit',
        type: RateLimitType.perIP,
        pattern: '/api/auth/register',
        maxRequests: 3,
        timeWindow: const Duration(hours: 1),
        action: RateLimitAction.block,
        createdAt: DateTime.now(),
      ),
    ];

    _rules.addAll(defaultRules);
    await _saveRules();
  }

  /// Start cleanup timer
  Future<void> _startCleanupTimer() async {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupOldRecords();
    });
  }

  /// Check rate limit for request
  Future<RateLimitAction> checkRateLimit({
    required String ip,
    String? userEmail,
    required String endpoint,
    String? userAgent,
    Map<String, String> headers = const {},
  }) async {
    final now = DateTime.now();
    
    // Check if IP is currently blocked
    if (_blockedUntil.containsKey(ip) && _blockedUntil[ip]!.isAfter(now)) {
      return RateLimitAction.block;
    }
    
    // Record the request
    await _recordRequest(ip, userEmail, endpoint, userAgent, headers);
    
    // Check applicable rules
    for (final rule in _rules.where((r) => r.enabled)) {
      final action = await _checkRule(rule, ip, userEmail, endpoint);
      if (action != RateLimitAction.allow) {
        return action;
      }
    }
    
    return RateLimitAction.allow;
  }

  /// Record request
  Future<void> _recordRequest(
    String ip,
    String? userEmail,
    String endpoint,
    String? userAgent,
    Map<String, String> headers,
  ) async {
    final record = RequestRecord(
      timestamp: DateTime.now(),
      endpoint: endpoint,
      userAgent: userAgent,
      headers: Map<String, dynamic>.from(headers),
    );
    
    // Record by IP
    _requestHistory.putIfAbsent(ip, () => []).add(record);
    
    // Record by user if available
    if (userEmail != null) {
      _requestHistory.putIfAbsent('user:$userEmail', () => []).add(record);
    }
    
    // Record by endpoint
    _requestHistory.putIfAbsent('endpoint:$endpoint', () => []).add(record);
    
    // Record globally
    _requestHistory.putIfAbsent('global', () => []).add(record);
  }

  /// Check specific rule
  Future<RateLimitAction> _checkRule(
    RateLimitRule rule,
    String ip,
    String? userEmail,
    String endpoint,
  ) async {
    String identifier;
    List<RequestRecord>? history;
    
    switch (rule.type) {
      case RateLimitType.perIP:
        identifier = ip;
        history = _requestHistory[ip];
        break;
      case RateLimitType.perUser:
        if (userEmail == null) return RateLimitAction.allow;
        identifier = 'user:$userEmail';
        history = _requestHistory[identifier];
        break;
      case RateLimitType.perEndpoint:
        identifier = 'endpoint:$endpoint';
        history = _requestHistory[identifier];
        break;
      case RateLimitType.global:
        identifier = 'global';
        history = _requestHistory[identifier];
        break;
    }
    
    if (history == null) return RateLimitAction.allow;
    
    // Check if pattern matches
    if (!_matchesPattern(rule.pattern, endpoint)) {
      return RateLimitAction.allow;
    }
    
    // Count requests within time window
    final cutoff = DateTime.now().subtract(rule.timeWindow);
    final recentRequests = history.where((r) => r.timestamp.isAfter(cutoff)).length;
    
    if (recentRequests > rule.maxRequests) {
      await _recordViolation(rule, identifier, recentRequests);
      
      // Apply blocking if action is block
      if (rule.action == RateLimitAction.block) {
        _blockedUntil[identifier] = DateTime.now().add(rule.timeWindow);
      }
      
      return rule.action;
    }
    
    return RateLimitAction.allow;
  }

  /// Check if endpoint matches pattern
  bool _matchesPattern(String pattern, String endpoint) {
    if (pattern == '*') return true;
    if (pattern == endpoint) return true;
    
    // Simple wildcard matching
    if (pattern.endsWith('*')) {
      final prefix = pattern.substring(0, pattern.length - 1);
      return endpoint.startsWith(prefix);
    }
    
    // Regex pattern matching could be added here
    return false;
  }

  /// Record rate limit violation
  Future<void> _recordViolation(
    RateLimitRule rule,
    String identifier,
    int requestCount,
  ) async {
    final violation = RateLimitViolation(
      id: 'violation_${DateTime.now().millisecondsSinceEpoch}',
      ruleId: rule.id,
      identifier: identifier,
      requestCount: requestCount,
      timeWindow: rule.timeWindow,
      action: rule.action,
      timestamp: DateTime.now(),
      context: {
        'rule_name': rule.name,
        'max_requests': rule.maxRequests,
      },
    );
    
    _violations.insert(0, violation);
    
    // Keep only last 10000 violations
    if (_violations.length > 10000) {
      _violations.removeRange(10000, _violations.length);
    }
    
    await _saveViolations();
    notifyListeners();
  }

  /// Clean up old records
  void _cleanupOldRecords() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    
    // Clean request history
    _requestHistory.forEach((key, records) {
      records.removeWhere((record) => record.timestamp.isBefore(cutoff));
    });
    
    // Remove empty histories
    _requestHistory.removeWhere((key, records) => records.isEmpty);
    
    // Clean expired blocks
    _blockedUntil.removeWhere((key, until) => until.isBefore(DateTime.now()));
  }

  /// Add rate limit rule
  Future<void> addRule(RateLimitRule rule) async {
    _rules.add(rule);
    await _saveRules();
    notifyListeners();
  }

  /// Update rate limit rule
  Future<void> updateRule(RateLimitRule rule) async {
    final index = _rules.indexWhere((r) => r.id == rule.id);
    if (index != -1) {
      _rules[index] = rule;
      await _saveRules();
      notifyListeners();
    }
  }

  /// Remove rate limit rule
  Future<void> removeRule(String ruleId) async {
    _rules.removeWhere((r) => r.id == ruleId);
    await _saveRules();
    notifyListeners();
  }

  /// Unblock identifier
  Future<void> unblockIdentifier(String identifier) async {
    _blockedUntil.remove(identifier);
    notifyListeners();
  }

  /// Get current request rates
  Map<String, Map<String, dynamic>> getCurrentRates() {
    final rates = <String, Map<String, dynamic>>{};
    final now = DateTime.now();
    
    for (final entry in _requestHistory.entries) {
      final identifier = entry.key;
      final records = entry.value;
      
      // Calculate rates for different time windows
      final last1min = records.where((r) => 
        r.timestamp.isAfter(now.subtract(const Duration(minutes: 1)))
      ).length;
      
      final last5min = records.where((r) => 
        r.timestamp.isAfter(now.subtract(const Duration(minutes: 5)))
      ).length;
      
      final last1hour = records.where((r) => 
        r.timestamp.isAfter(now.subtract(const Duration(hours: 1)))
      ).length;
      
      rates[identifier] = {
        'last_1min': last1min,
        'last_5min': last5min,
        'last_1hour': last1hour,
        'total_requests': records.length,
      };
    }
    
    return rates;
  }

  /// Get rate limiting statistics
  Map<String, dynamic> getRateLimitingStatistics() {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));
    final last7d = now.subtract(const Duration(days: 7));
    
    final violations24h = _violations.where((v) => v.timestamp.isAfter(last24h)).length;
    final violations7d = _violations.where((v) => v.timestamp.isAfter(last7d)).length;
    
    return {
      'total_rules': _rules.length,
      'active_rules': _rules.where((r) => r.enabled).length,
      'total_violations': _violations.length,
      'violations_24h': violations24h,
      'violations_7d': violations7d,
      'currently_blocked': _blockedUntil.length,
      'by_action': _getViolationsByAction(),
      'by_rule': _getViolationsByRule(),
      'top_violators': _getTopViolators(),
      'request_rates': getCurrentRates(),
    };
  }

  /// Get violations by action
  Map<String, int> _getViolationsByAction() {
    final Map<String, int> byAction = {};
    for (final violation in _violations) {
      byAction[violation.action.name] = (byAction[violation.action.name] ?? 0) + 1;
    }
    return byAction;
  }

  /// Get violations by rule
  Map<String, int> _getViolationsByRule() {
    final Map<String, int> byRule = {};
    for (final violation in _violations) {
      final ruleName = _rules.firstWhere(
        (r) => r.id == violation.ruleId,
        orElse: () => RateLimitRule(
          id: 'unknown',
          name: 'Unknown Rule',
          type: RateLimitType.global,
          pattern: '*',
          maxRequests: 0,
          timeWindow: Duration.zero,
          action: RateLimitAction.allow,
          createdAt: DateTime.now(),
        ),
      ).name;
      byRule[ruleName] = (byRule[ruleName] ?? 0) + 1;
    }
    return byRule;
  }

  /// Get top violators
  List<Map<String, dynamic>> _getTopViolators() {
    final Map<String, int> violatorCounts = {};
    for (final violation in _violations) {
      violatorCounts[violation.identifier] = (violatorCounts[violation.identifier] ?? 0) + 1;
    }
    
    final sorted = violatorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(10).map((entry) => {
      'identifier': entry.key,
      'violation_count': entry.value,
    }).toList();
  }

  /// Simulate DDoS attack for testing
  Future<void> simulateDDoSAttack({
    int attackerCount = 50,
    int requestsPerAttacker = 100,
    Duration duration = const Duration(minutes: 5),
  }) async {
    final random = Random();
    final attackers = List.generate(attackerCount, (i) => 
      '${random.nextInt(256)}.${random.nextInt(256)}.${random.nextInt(256)}.${random.nextInt(256)}'
    );
    
    debugPrint('Simulating DDoS attack with $attackerCount attackers');
    
    final requestInterval = Duration(
      milliseconds: duration.inMilliseconds ~/ (attackerCount * requestsPerAttacker)
    );
    
    for (int i = 0; i < requestsPerAttacker; i++) {
      for (final attackerIP in attackers) {
        await checkRateLimit(
          ip: attackerIP,
          endpoint: '/api/auth/login',
          userAgent: 'AttackBot/1.0',
        );
        
        // Small delay to spread requests
        await Future.delayed(requestInterval);
      }
    }
    
    debugPrint('DDoS attack simulation completed');
  }

  /// Export rate limiting data
  Map<String, dynamic> exportRateLimitingData() {
    return {
      'rules': _rules.map((r) => r.toJson()).toList(),
      'violations': _violations.map((v) => v.toJson()).toList(),
      'statistics': getRateLimitingStatistics(),
      'blocked_identifiers': _blockedUntil.map((k, v) => MapEntry(k, v.toIso8601String())),
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    super.dispose();
  }
}
