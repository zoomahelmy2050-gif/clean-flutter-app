import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SecurityPolicy {
  final String id;
  final String name;
  final String description;
  final bool isEnabled;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  SecurityPolicy({
    required this.id,
    required this.name,
    required this.description,
    required this.isEnabled,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'isEnabled': isEnabled,
    'settings': settings,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SecurityPolicy.fromJson(Map<String, dynamic> json) => SecurityPolicy(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    isEnabled: json['isEnabled'],
    settings: Map<String, dynamic>.from(json['settings']),
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  SecurityPolicy copyWith({
    String? id,
    String? name,
    String? description,
    bool? isEnabled,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SecurityPolicy(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    isEnabled: isEnabled ?? this.isEnabled,
    settings: settings ?? this.settings,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class SecuritySettingsService extends ChangeNotifier {
  static const String _settingsKey = 'security_settings';
  
  List<SecurityPolicy> _policies = [];
  bool _isLoading = false;

  List<SecurityPolicy> get policies => _policies;
  bool get isLoading => _isLoading;

  // Default security policies
  static final List<SecurityPolicy> defaultPolicies = [
    SecurityPolicy(
      id: 'password_policy',
      name: 'Password Policy',
      description: 'Enforce strong password requirements',
      isEnabled: true,
      settings: {
        'minLength': 8,
        'requireUppercase': true,
        'requireLowercase': true,
        'requireNumbers': true,
        'requireSpecialChars': true,
        'maxAge': 90,
        'preventReuse': 5,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    SecurityPolicy(
      id: 'session_policy',
      name: 'Session Management',
      description: 'Control user session behavior',
      isEnabled: true,
      settings: {
        'maxSessionDuration': 480, // 8 hours in minutes
        'idleTimeout': 30, // 30 minutes
        'maxConcurrentSessions': 3,
        'requireReauth': true,
        'logoutOnClose': false,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    SecurityPolicy(
      id: 'login_policy',
      name: 'Login Security',
      description: 'Control login attempts and security',
      isEnabled: true,
      settings: {
        'maxFailedAttempts': 5,
        'lockoutDuration': 15, // minutes
        'requireMFA': false,
        'allowRememberMe': true,
        'ipWhitelist': <String>[],
        'geoBlocking': false,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    SecurityPolicy(
      id: 'data_protection',
      name: 'Data Protection',
      description: 'Protect sensitive data',
      isEnabled: true,
      settings: {
        'encryptionEnabled': true,
        'backupEncryption': true,
        'dataRetention': 365, // days
        'anonymizeData': false,
        'auditTrail': true,
        'exportRestrictions': true,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    SecurityPolicy(
      id: 'network_security',
      name: 'Network Security',
      description: 'Network-level security controls',
      isEnabled: true,
      settings: {
        'httpsOnly': true,
        'rateLimiting': true,
        'requestsPerMinute': 60,
        'blockSuspiciousIPs': true,
        'enableCORS': false,
        'allowedOrigins': <String>[],
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    SecurityPolicy(
      id: 'monitoring_policy',
      name: 'Security Monitoring',
      description: 'Monitor and alert on security events',
      isEnabled: true,
      settings: {
        'realTimeAlerts': true,
        'emailNotifications': true,
        'smsNotifications': false,
        'alertThreshold': 'medium',
        'logRetention': 90, // days
        'anomalyDetection': true,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    SecurityPolicy(
      id: 'compliance_policy',
      name: 'Compliance Settings',
      description: 'Regulatory compliance controls',
      isEnabled: false,
      settings: {
        'gdprCompliance': true,
        'ccpaCompliance': false,
        'hipaaCompliance': false,
        'soxCompliance': false,
        'dataProcessingConsent': true,
        'rightToErasure': true,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadPolicies();
      
      // Initialize with default policies if none exist
      if (_policies.isEmpty) {
        _policies = List.from(defaultPolicies);
        await _savePolicies();
      }
    } catch (e) {
      debugPrint('Error initializing security settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadPolicies() async {
    final prefs = await SharedPreferences.getInstance();
    final policiesJson = prefs.getString(_settingsKey);
    
    if (policiesJson != null) {
      final policiesList = jsonDecode(policiesJson) as List;
      _policies = policiesList.map((json) => SecurityPolicy.fromJson(json)).toList();
    }
  }

  Future<void> _savePolicies() async {
    final prefs = await SharedPreferences.getInstance();
    final policiesJson = jsonEncode(_policies.map((policy) => policy.toJson()).toList());
    await prefs.setString(_settingsKey, policiesJson);
  }

  // Policy Management
  Future<bool> updatePolicy(String policyId, SecurityPolicy updatedPolicy) async {
    try {
      final index = _policies.indexWhere((policy) => policy.id == policyId);
      if (index != -1) {
        _policies[index] = updatedPolicy.copyWith(updatedAt: DateTime.now());
        await _savePolicies();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating policy: $e');
      return false;
    }
  }

  Future<bool> togglePolicy(String policyId, bool enabled) async {
    try {
      final index = _policies.indexWhere((policy) => policy.id == policyId);
      if (index != -1) {
        _policies[index] = _policies[index].copyWith(
          isEnabled: enabled,
          updatedAt: DateTime.now(),
        );
        await _savePolicies();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error toggling policy: $e');
      return false;
    }
  }

  Future<bool> updatePolicySetting(String policyId, String settingKey, dynamic value) async {
    try {
      final index = _policies.indexWhere((policy) => policy.id == policyId);
      if (index != -1) {
        final currentSettings = Map<String, dynamic>.from(_policies[index].settings);
        currentSettings[settingKey] = value;
        
        _policies[index] = _policies[index].copyWith(
          settings: currentSettings,
          updatedAt: DateTime.now(),
        );
        
        await _savePolicies();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating policy setting: $e');
      return false;
    }
  }

  // Getters for specific policies
  SecurityPolicy? getPolicy(String policyId) {
    try {
      return _policies.firstWhere((policy) => policy.id == policyId);
    } catch (e) {
      return null;
    }
  }

  List<SecurityPolicy> getEnabledPolicies() {
    return _policies.where((policy) => policy.isEnabled).toList();
  }

  List<SecurityPolicy> getDisabledPolicies() {
    return _policies.where((policy) => !policy.isEnabled).toList();
  }

  // Validation methods
  bool validatePassword(String password) {
    final policy = getPolicy('password_policy');
    if (policy == null || !policy.isEnabled) return true;

    final settings = policy.settings;
    
    // Check minimum length
    if (password.length < (settings['minLength'] ?? 8)) return false;
    
    // Check uppercase requirement
    if (settings['requireUppercase'] == true && !password.contains(RegExp(r'[A-Z]'))) return false;
    
    // Check lowercase requirement
    if (settings['requireLowercase'] == true && !password.contains(RegExp(r'[a-z]'))) return false;
    
    // Check numbers requirement
    if (settings['requireNumbers'] == true && !password.contains(RegExp(r'[0-9]'))) return false;
    
    // Check special characters requirement
    if (settings['requireSpecialChars'] == true && !password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    
    return true;
  }

  bool isSessionValid(DateTime sessionStart, DateTime? lastActivity) {
    final policy = getPolicy('session_policy');
    if (policy == null || !policy.isEnabled) return true;

    final settings = policy.settings;
    final now = DateTime.now();
    
    // Check max session duration
    final maxDuration = Duration(minutes: settings['maxSessionDuration'] ?? 480);
    if (now.difference(sessionStart) > maxDuration) return false;
    
    // Check idle timeout
    if (lastActivity != null) {
      final idleTimeout = Duration(minutes: settings['idleTimeout'] ?? 30);
      if (now.difference(lastActivity) > idleTimeout) return false;
    }
    
    return true;
  }

  bool canAttemptLogin(int failedAttempts) {
    final policy = getPolicy('login_policy');
    if (policy == null || !policy.isEnabled) return true;

    final maxAttempts = policy.settings['maxFailedAttempts'] ?? 5;
    return failedAttempts < maxAttempts;
  }

  Duration getLockoutDuration() {
    final policy = getPolicy('login_policy');
    if (policy == null || !policy.isEnabled) return Duration.zero;

    return Duration(minutes: policy.settings['lockoutDuration'] ?? 15);
  }

  bool requiresMFA() {
    final policy = getPolicy('login_policy');
    if (policy == null || !policy.isEnabled) return false;

    return policy.settings['requireMFA'] ?? false;
  }

  // Security scoring
  int calculateSecurityScore() {
    int score = 0;
    int maxScore = 0;

    for (final policy in _policies) {
      maxScore += 100;
      
      if (policy.isEnabled) {
        score += 50; // Base score for being enabled
        
        // Additional scoring based on policy type and settings
        switch (policy.id) {
          case 'password_policy':
            final settings = policy.settings;
            if (settings['minLength'] >= 12) score += 10;
            if (settings['requireUppercase'] == true) score += 10;
            if (settings['requireLowercase'] == true) score += 10;
            if (settings['requireNumbers'] == true) score += 10;
            if (settings['requireSpecialChars'] == true) score += 10;
            break;
            
          case 'session_policy':
            final settings = policy.settings;
            if ((settings['maxSessionDuration'] ?? 480) <= 240) score += 15;
            if ((settings['idleTimeout'] ?? 30) <= 15) score += 15;
            if ((settings['maxConcurrentSessions'] ?? 3) <= 2) score += 10;
            if (settings['requireReauth'] == true) score += 10;
            break;
            
          case 'login_policy':
            final settings = policy.settings;
            if ((settings['maxFailedAttempts'] ?? 5) <= 3) score += 15;
            if (settings['requireMFA'] == true) score += 25;
            if ((settings['ipWhitelist'] as List?)?.isNotEmpty == true) score += 10;
            break;
            
          case 'data_protection':
            final settings = policy.settings;
            if (settings['encryptionEnabled'] == true) score += 20;
            if (settings['backupEncryption'] == true) score += 15;
            if (settings['auditTrail'] == true) score += 15;
            break;
            
          case 'network_security':
            final settings = policy.settings;
            if (settings['httpsOnly'] == true) score += 20;
            if (settings['rateLimiting'] == true) score += 15;
            if (settings['blockSuspiciousIPs'] == true) score += 15;
            break;
            
          case 'monitoring_policy':
            final settings = policy.settings;
            if (settings['realTimeAlerts'] == true) score += 20;
            if (settings['anomalyDetection'] == true) score += 20;
            if (settings['alertThreshold'] == 'high') score += 10;
            break;
            
          case 'compliance_policy':
            final settings = policy.settings;
            if (settings['gdprCompliance'] == true) score += 25;
            if (settings['dataProcessingConsent'] == true) score += 15;
            if (settings['rightToErasure'] == true) score += 10;
            break;
        }
      }
    }

    return maxScore > 0 ? ((score / maxScore) * 100).round() : 0;
  }

  // Export/Import settings
  Map<String, dynamic> exportSettings() {
    return {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'policies': _policies.map((policy) => policy.toJson()).toList(),
    };
  }

  Future<bool> importSettings(Map<String, dynamic> settings) async {
    try {
      if (settings['version'] != '1.0') {
        debugPrint('Unsupported settings version');
        return false;
      }

      final policiesList = settings['policies'] as List;
      final importedPolicies = policiesList.map((json) => SecurityPolicy.fromJson(json)).toList();
      
      _policies = importedPolicies;
      await _savePolicies();
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('Error importing settings: $e');
      return false;
    }
  }

  Future<void> resetToDefaults() async {
    _policies = List.from(defaultPolicies);
    await _savePolicies();
    notifyListeners();
  }

  // Compliance checks
  bool isGDPRCompliant() {
    final policy = getPolicy('compliance_policy');
    return policy?.isEnabled == true && policy?.settings['gdprCompliance'] == true;
  }

  bool isCCPACompliant() {
    final policy = getPolicy('compliance_policy');
    return policy?.isEnabled == true && policy?.settings['ccpaCompliance'] == true;
  }

  bool isHIPAACompliant() {
    final policy = getPolicy('compliance_policy');
    return policy?.isEnabled == true && policy?.settings['hipaaCompliance'] == true;
  }

  // Audit methods
  List<String> getSecurityRecommendations() {
    final recommendations = <String>[];
    
    for (final policy in _policies) {
      if (!policy.isEnabled) {
        recommendations.add('Enable ${policy.name} for better security');
        continue;
      }
      
      switch (policy.id) {
        case 'password_policy':
          final settings = policy.settings;
          if ((settings['minLength'] ?? 8) < 12) {
            recommendations.add('Increase minimum password length to 12+ characters');
          }
          if (settings['requireMFA'] != true) {
            recommendations.add('Enable multi-factor authentication requirement');
          }
          break;
          
        case 'session_policy':
          final settings = policy.settings;
          if ((settings['maxSessionDuration'] ?? 480) > 240) {
            recommendations.add('Reduce maximum session duration to 4 hours or less');
          }
          break;
          
        case 'login_policy':
          final settings = policy.settings;
          if (settings['requireMFA'] != true) {
            recommendations.add('Enable mandatory multi-factor authentication');
          }
          break;
          
        case 'data_protection':
          final settings = policy.settings;
          if (settings['encryptionEnabled'] != true) {
            recommendations.add('Enable data encryption for sensitive information');
          }
          break;
          
        case 'monitoring_policy':
          final settings = policy.settings;
          if (settings['realTimeAlerts'] != true) {
            recommendations.add('Enable real-time security alerts');
          }
          break;
      }
    }
    
    return recommendations;
  }
}
