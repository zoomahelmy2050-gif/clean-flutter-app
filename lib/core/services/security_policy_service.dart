import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PolicyType {
  password,
  session,
  access,
  mfa,
  device,
  network,
  data,
  audit,
}

enum PolicyStatus {
  active,
  inactive,
  draft,
  deprecated,
}

enum EnforcementLevel {
  advisory,
  warning,
  blocking,
  critical,
}

class SecurityPolicy {
  final String id;
  final String name;
  final String description;
  final PolicyType type;
  final PolicyStatus status;
  final EnforcementLevel enforcementLevel;
  final Map<String, dynamic> rules;
  final List<String> applicableRoles;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final DateTime? effectiveDate;
  final DateTime? expiryDate;
  final String? createdBy;
  final int version;

  SecurityPolicy({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.status,
    required this.enforcementLevel,
    required this.rules,
    this.applicableRoles = const [],
    required this.createdAt,
    required this.lastUpdated,
    this.effectiveDate,
    this.expiryDate,
    this.createdBy,
    this.version = 1,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type.name,
    'status': status.name,
    'enforcementLevel': enforcementLevel.name,
    'rules': rules,
    'applicableRoles': applicableRoles,
    'createdAt': createdAt.toIso8601String(),
    'lastUpdated': lastUpdated.toIso8601String(),
    'effectiveDate': effectiveDate?.toIso8601String(),
    'expiryDate': expiryDate?.toIso8601String(),
    'createdBy': createdBy,
    'version': version,
  };

  factory SecurityPolicy.fromJson(Map<String, dynamic> json) {
    return SecurityPolicy(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: PolicyType.values.firstWhere((e) => e.name == json['type']),
      status: PolicyStatus.values.firstWhere((e) => e.name == json['status']),
      enforcementLevel: EnforcementLevel.values.firstWhere((e) => e.name == json['enforcementLevel']),
      rules: Map<String, dynamic>.from(json['rules']),
      applicableRoles: List<String>.from(json['applicableRoles'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      effectiveDate: json['effectiveDate'] != null ? DateTime.parse(json['effectiveDate']) : null,
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
      createdBy: json['createdBy'],
      version: json['version'] ?? 1,
    );
  }
}

class PolicyViolation {
  final String id;
  final String policyId;
  final String userId;
  final String violationType;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> context;
  final String? remedialAction;
  final bool resolved;

  PolicyViolation({
    required this.id,
    required this.policyId,
    required this.userId,
    required this.violationType,
    required this.description,
    required this.timestamp,
    this.context = const {},
    this.remedialAction,
    this.resolved = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'policyId': policyId,
    'userId': userId,
    'violationType': violationType,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
    'context': context,
    'remedialAction': remedialAction,
    'resolved': resolved,
  };

  factory PolicyViolation.fromJson(Map<String, dynamic> json) {
    return PolicyViolation(
      id: json['id'],
      policyId: json['policyId'],
      userId: json['userId'],
      violationType: json['violationType'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      context: Map<String, dynamic>.from(json['context'] ?? {}),
      remedialAction: json['remedialAction'],
      resolved: json['resolved'] ?? false,
    );
  }
}

class SecurityPolicyService extends ChangeNotifier {
  final List<SecurityPolicy> _policies = [];
  final List<PolicyViolation> _violations = [];
  Timer? _enforcementTimer;
  
  static const String _policiesKey = 'security_policies';
  static const String _violationsKey = 'policy_violations';

  // Getters
  List<SecurityPolicy> get policies => List.unmodifiable(_policies);
  List<PolicyViolation> get violations => List.unmodifiable(_violations);
  List<SecurityPolicy> get activePolicies => 
    _policies.where((p) => p.status == PolicyStatus.active).toList();

  /// Initialize security policy service
  Future<void> initialize() async {
    await _loadPolicies();
    await _loadViolations();
    await _initializeDefaultPolicies();
    await _startEnforcementTimer();
  }

  /// Load policies from storage
  Future<void> _loadPolicies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final policiesJson = prefs.getStringList(_policiesKey) ?? [];
      
      _policies.clear();
      for (final policyJson in policiesJson) {
        final Map<String, dynamic> data = jsonDecode(policyJson);
        _policies.add(SecurityPolicy.fromJson(data));
      }
    } catch (e) {
      debugPrint('Error loading security policies: $e');
    }
  }

  /// Save policies to storage
  Future<void> _savePolicies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final policiesJson = _policies.map((p) => jsonEncode(p.toJson())).toList();
      await prefs.setStringList(_policiesKey, policiesJson);
    } catch (e) {
      debugPrint('Error saving security policies: $e');
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
        _violations.add(PolicyViolation.fromJson(data));
      }
    } catch (e) {
      debugPrint('Error loading policy violations: $e');
    }
  }

  /// Save violations to storage
  Future<void> _saveViolations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final violationsJson = _violations.map((v) => jsonEncode(v.toJson())).toList();
      await prefs.setStringList(_violationsKey, violationsJson);
    } catch (e) {
      debugPrint('Error saving policy violations: $e');
    }
  }

  /// Initialize default policies
  Future<void> _initializeDefaultPolicies() async {
    if (_policies.isNotEmpty) return;

    final now = DateTime.now();
    final defaultPolicies = [
      SecurityPolicy(
        id: 'password_policy',
        name: 'Password Policy',
        description: 'Enforces strong password requirements',
        type: PolicyType.password,
        status: PolicyStatus.active,
        enforcementLevel: EnforcementLevel.blocking,
        rules: {
          'min_length': 12,
          'require_uppercase': true,
          'require_lowercase': true,
          'require_numbers': true,
          'require_special_chars': true,
          'prevent_common_passwords': true,
          'prevent_personal_info': true,
          'password_history': 5,
          'max_age_days': 90,
        },
        createdAt: now,
        lastUpdated: now,
        effectiveDate: now,
      ),
      SecurityPolicy(
        id: 'session_policy',
        name: 'Session Management Policy',
        description: 'Controls user session behavior and timeouts',
        type: PolicyType.session,
        status: PolicyStatus.active,
        enforcementLevel: EnforcementLevel.blocking,
        rules: {
          'max_session_duration': 480, // 8 hours in minutes
          'idle_timeout': 30, // 30 minutes
          'concurrent_sessions_limit': 3,
          'require_reauth_for_sensitive': true,
          'session_fixation_protection': true,
          'secure_cookies': true,
        },
        createdAt: now,
        lastUpdated: now,
        effectiveDate: now,
      ),
      SecurityPolicy(
        id: 'mfa_policy',
        name: 'Multi-Factor Authentication Policy',
        description: 'Enforces MFA requirements for users',
        type: PolicyType.mfa,
        status: PolicyStatus.active,
        enforcementLevel: EnforcementLevel.blocking,
        rules: {
          'require_mfa_all_users': true,
          'mfa_grace_period_days': 7,
          'allowed_mfa_methods': ['totp', 'sms', 'email', 'biometric'],
          'backup_codes_required': true,
          'mfa_remember_device_days': 30,
        },
        createdAt: now,
        lastUpdated: now,
        effectiveDate: now,
      ),
      SecurityPolicy(
        id: 'access_control_policy',
        name: 'Access Control Policy',
        description: 'Defines access control requirements',
        type: PolicyType.access,
        status: PolicyStatus.active,
        enforcementLevel: EnforcementLevel.blocking,
        rules: {
          'principle_of_least_privilege': true,
          'regular_access_review': true,
          'access_review_interval_days': 90,
          'automatic_deprovisioning': true,
          'privileged_access_monitoring': true,
          'failed_login_lockout_attempts': 5,
          'lockout_duration_minutes': 15,
        },
        createdAt: now,
        lastUpdated: now,
        effectiveDate: now,
      ),
      SecurityPolicy(
        id: 'device_policy',
        name: 'Device Security Policy',
        description: 'Controls device access and security requirements',
        type: PolicyType.device,
        status: PolicyStatus.active,
        enforcementLevel: EnforcementLevel.warning,
        rules: {
          'device_registration_required': true,
          'trusted_device_limit': 5,
          'device_encryption_required': true,
          'jailbreak_detection': true,
          'remote_wipe_capability': true,
          'device_compliance_check': true,
        },
        createdAt: now,
        lastUpdated: now,
        effectiveDate: now,
      ),
    ];

    _policies.addAll(defaultPolicies);
    await _savePolicies();
  }

  /// Start enforcement timer
  Future<void> _startEnforcementTimer() async {
    _enforcementTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _performPolicyEnforcement();
    });
  }

  /// Perform policy enforcement
  void _performPolicyEnforcement() {
    for (final policy in activePolicies) {
      _enforcePolicy(policy);
    }
  }

  /// Enforce specific policy
  void _enforcePolicy(SecurityPolicy policy) {
    switch (policy.type) {
      case PolicyType.password:
        _enforcePasswordPolicy(policy);
        break;
      case PolicyType.session:
        _enforceSessionPolicy(policy);
        break;
      case PolicyType.mfa:
        _enforceMfaPolicy(policy);
        break;
      case PolicyType.access:
        _enforceAccessPolicy(policy);
        break;
      case PolicyType.device:
        _enforceDevicePolicy(policy);
        break;
      default:
        break;
    }
  }

  /// Enforce password policy
  void _enforcePasswordPolicy(SecurityPolicy policy) {
    // In a real implementation, this would check user passwords against policy
    debugPrint('Enforcing password policy: ${policy.name}');
  }

  /// Enforce session policy
  void _enforceSessionPolicy(SecurityPolicy policy) {
    // In a real implementation, this would check active sessions
    debugPrint('Enforcing session policy: ${policy.name}');
  }

  /// Enforce MFA policy
  void _enforceMfaPolicy(SecurityPolicy policy) {
    // In a real implementation, this would check MFA compliance
    debugPrint('Enforcing MFA policy: ${policy.name}');
  }

  /// Enforce access policy
  void _enforceAccessPolicy(SecurityPolicy policy) {
    // In a real implementation, this would check access permissions
    debugPrint('Enforcing access policy: ${policy.name}');
  }

  /// Enforce device policy
  void _enforceDevicePolicy(SecurityPolicy policy) {
    // In a real implementation, this would check device compliance
    debugPrint('Enforcing device policy: ${policy.name}');
  }

  /// Check policy compliance
  Future<bool> checkCompliance(String userId, PolicyType policyType, Map<String, dynamic> context) async {
    final policy = _policies.firstWhere(
      (p) => p.type == policyType && p.status == PolicyStatus.active,
      orElse: () => throw Exception('No active policy found for type: $policyType'),
    );

    final isCompliant = await _evaluateCompliance(policy, userId, context);
    
    if (!isCompliant) {
      await _recordViolation(policy, userId, context);
    }
    
    return isCompliant;
  }

  /// Evaluate compliance
  Future<bool> _evaluateCompliance(SecurityPolicy policy, String userId, Map<String, dynamic> context) async {
    switch (policy.type) {
      case PolicyType.password:
        return _evaluatePasswordCompliance(policy, context);
      case PolicyType.session:
        return _evaluateSessionCompliance(policy, context);
      case PolicyType.mfa:
        return _evaluateMfaCompliance(policy, context);
      case PolicyType.access:
        return _evaluateAccessCompliance(policy, context);
      case PolicyType.device:
        return _evaluateDeviceCompliance(policy, context);
      default:
        return true;
    }
  }

  /// Evaluate password compliance
  bool _evaluatePasswordCompliance(SecurityPolicy policy, Map<String, dynamic> context) {
    final password = context['password'] as String?;
    if (password == null) return false;

    final rules = policy.rules;
    
    // Check minimum length
    if (password.length < (rules['min_length'] ?? 8)) return false;
    
    // Check character requirements
    if (rules['require_uppercase'] == true && !password.contains(RegExp(r'[A-Z]'))) return false;
    if (rules['require_lowercase'] == true && !password.contains(RegExp(r'[a-z]'))) return false;
    if (rules['require_numbers'] == true && !password.contains(RegExp(r'[0-9]'))) return false;
    if (rules['require_special_chars'] == true && !password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    
    return true;
  }

  /// Evaluate session compliance
  bool _evaluateSessionCompliance(SecurityPolicy policy, Map<String, dynamic> context) {
    final sessionDuration = context['session_duration'] as Duration?;
    final idleTime = context['idle_time'] as Duration?;
    
    final rules = policy.rules;
    final maxDuration = Duration(minutes: rules['max_session_duration'] ?? 480);
    final maxIdle = Duration(minutes: rules['idle_timeout'] ?? 30);
    
    if (sessionDuration != null && sessionDuration > maxDuration) return false;
    if (idleTime != null && idleTime > maxIdle) return false;
    
    return true;
  }

  /// Evaluate MFA compliance
  bool _evaluateMfaCompliance(SecurityPolicy policy, Map<String, dynamic> context) {
    final hasMfa = context['has_mfa'] as bool? ?? false;
    final rules = policy.rules;
    
    if (rules['require_mfa_all_users'] == true && !hasMfa) return false;
    
    return true;
  }

  /// Evaluate access compliance
  bool _evaluateAccessCompliance(SecurityPolicy policy, Map<String, dynamic> context) {
    final failedAttempts = context['failed_attempts'] as int? ?? 0;
    final rules = policy.rules;
    
    final maxFailedAttempts = rules['failed_login_lockout_attempts'] ?? 5;
    if (failedAttempts >= maxFailedAttempts) return false;
    
    return true;
  }

  /// Evaluate device compliance
  bool _evaluateDeviceCompliance(SecurityPolicy policy, Map<String, dynamic> context) {
    final isJailbroken = context['is_jailbroken'] as bool? ?? false;
    final isEncrypted = context['is_encrypted'] as bool? ?? true;
    
    final rules = policy.rules;
    
    if (rules['jailbreak_detection'] == true && isJailbroken) return false;
    if (rules['device_encryption_required'] == true && !isEncrypted) return false;
    
    return true;
  }

  /// Record policy violation
  Future<void> _recordViolation(SecurityPolicy policy, String userId, Map<String, dynamic> context) async {
    final violation = PolicyViolation(
      id: 'violation_${DateTime.now().millisecondsSinceEpoch}',
      policyId: policy.id,
      userId: userId,
      violationType: policy.type.name,
      description: 'Policy violation: ${policy.name}',
      timestamp: DateTime.now(),
      context: context,
    );

    _violations.insert(0, violation);
    
    // Keep only last 5000 violations
    if (_violations.length > 5000) {
      _violations.removeRange(5000, _violations.length);
    }
    
    await _saveViolations();
    notifyListeners();
    
    // Execute enforcement action
    await _executeEnforcementAction(policy, violation);
  }

  /// Execute enforcement action
  Future<void> _executeEnforcementAction(SecurityPolicy policy, PolicyViolation violation) async {
    switch (policy.enforcementLevel) {
      case EnforcementLevel.advisory:
        debugPrint('Advisory: ${violation.description}');
        break;
      case EnforcementLevel.warning:
        debugPrint('Warning: ${violation.description}');
        // Could send notification to user
        break;
      case EnforcementLevel.blocking:
        debugPrint('Blocking: ${violation.description}');
        // Could block user action
        break;
      case EnforcementLevel.critical:
        debugPrint('Critical: ${violation.description}');
        // Could trigger incident response
        break;
    }
  }

  /// Add security policy
  Future<void> addPolicy(SecurityPolicy policy) async {
    _policies.add(policy);
    await _savePolicies();
    notifyListeners();
  }

  /// Update security policy
  Future<void> updatePolicy(SecurityPolicy policy) async {
    final index = _policies.indexWhere((p) => p.id == policy.id);
    if (index != -1) {
      _policies[index] = policy;
      await _savePolicies();
      notifyListeners();
    }
  }

  /// Remove security policy
  Future<void> removePolicy(String policyId) async {
    _policies.removeWhere((p) => p.id == policyId);
    await _savePolicies();
    notifyListeners();
  }

  /// Get policy statistics
  Map<String, dynamic> getPolicyStatistics() {
    final totalPolicies = _policies.length;
    final activePolicies = _policies.where((p) => p.status == PolicyStatus.active).length;
    final totalViolations = _violations.length;
    final unresolvedViolations = _violations.where((v) => !v.resolved).length;
    
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));
    final violations24h = _violations.where((v) => v.timestamp.isAfter(last24h)).length;
    
    return {
      'total_policies': totalPolicies,
      'active_policies': activePolicies,
      'total_violations': totalViolations,
      'unresolved_violations': unresolvedViolations,
      'violations_24h': violations24h,
      'by_type': _getPoliciesByType(),
      'by_enforcement_level': _getPoliciesByEnforcementLevel(),
      'violation_trends': _getViolationTrends(),
    };
  }

  /// Get policies by type
  Map<String, int> _getPoliciesByType() {
    final Map<String, int> byType = {};
    for (final policy in _policies) {
      byType[policy.type.name] = (byType[policy.type.name] ?? 0) + 1;
    }
    return byType;
  }

  /// Get policies by enforcement level
  Map<String, int> _getPoliciesByEnforcementLevel() {
    final Map<String, int> byLevel = {};
    for (final policy in _policies) {
      byLevel[policy.enforcementLevel.name] = (byLevel[policy.enforcementLevel.name] ?? 0) + 1;
    }
    return byLevel;
  }

  /// Get violation trends
  Map<String, int> _getViolationTrends() {
    final Map<String, int> trends = {};
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayKey = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      trends[dayKey] = _violations.where((v) => 
        v.timestamp.isAfter(dayStart) && v.timestamp.isBefore(dayEnd)
      ).length;
    }
    
    return trends;
  }

  /// Export policy data
  Map<String, dynamic> exportPolicyData() {
    return {
      'policies': _policies.map((p) => p.toJson()).toList(),
      'violations': _violations.map((v) => v.toJson()).toList(),
      'statistics': getPolicyStatistics(),
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  void dispose() {
    _enforcementTimer?.cancel();
    super.dispose();
  }
}
