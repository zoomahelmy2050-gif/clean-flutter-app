import 'dart:async';
import 'dart:developer' as developer;

class TenantConfiguration {
  final String tenantId;
  final String name;
  final String domain;
  final Map<String, dynamic> settings;
  final List<String> features;
  final Map<String, dynamic> branding;
  final Map<String, dynamic> securityPolicies;
  final DateTime createdAt;
  final bool isActive;

  TenantConfiguration({
    required this.tenantId,
    required this.name,
    required this.domain,
    required this.settings,
    required this.features,
    required this.branding,
    required this.securityPolicies,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'tenant_id': tenantId,
    'name': name,
    'domain': domain,
    'settings': settings,
    'features': features,
    'branding': branding,
    'security_policies': securityPolicies,
    'created_at': createdAt.toIso8601String(),
    'is_active': isActive,
  };
}

class TenantUser {
  final String userId;
  final String tenantId;
  final String email;
  final List<String> roles;
  final Map<String, dynamic> permissions;
  final DateTime joinedAt;
  final bool isActive;

  TenantUser({
    required this.userId,
    required this.tenantId,
    required this.email,
    required this.roles,
    required this.permissions,
    required this.joinedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'tenant_id': tenantId,
    'email': email,
    'roles': roles,
    'permissions': permissions,
    'joined_at': joinedAt.toIso8601String(),
    'is_active': isActive,
  };
}

class TenantMetrics {
  final String tenantId;
  final int userCount;
  final int activeUsers;
  final Map<String, int> featureUsage;
  final Map<String, double> securityScores;
  final DateTime lastActivity;

  TenantMetrics({
    required this.tenantId,
    required this.userCount,
    required this.activeUsers,
    required this.featureUsage,
    required this.securityScores,
    required this.lastActivity,
  });

  Map<String, dynamic> toJson() => {
    'tenant_id': tenantId,
    'user_count': userCount,
    'active_users': activeUsers,
    'feature_usage': featureUsage,
    'security_scores': securityScores,
    'last_activity': lastActivity.toIso8601String(),
  };
}

class MultiTenantService {
  static final MultiTenantService _instance = MultiTenantService._internal();
  factory MultiTenantService() => _instance;
  MultiTenantService._internal();

  final Map<String, TenantConfiguration> _tenants = {};
  final Map<String, List<TenantUser>> _tenantUsers = {};
  final Map<String, TenantMetrics> _tenantMetrics = {};
  
  String? _currentTenantId;
  
  final StreamController<TenantConfiguration> _tenantController = StreamController.broadcast();
  final StreamController<String> _currentTenantController = StreamController.broadcast();

  Stream<TenantConfiguration> get tenantStream => _tenantController.stream;
  Stream<String> get currentTenantStream => _currentTenantController.stream;

  String? get currentTenantId => _currentTenantId;
  TenantConfiguration? get currentTenant => _currentTenantId != null ? _tenants[_currentTenantId] : null;

  Future<void> initialize() async {
    await _createDefaultTenants();
    await _loadTenantMetrics();
    
    developer.log('Multi-Tenant Service initialized', name: 'MultiTenantService');
  }

  Future<void> _createDefaultTenants() async {
    // Enterprise tenant
    await createTenant(TenantConfiguration(
      tenantId: 'enterprise_corp',
      name: 'Enterprise Corporation',
      domain: 'enterprise.com',
      settings: {
        'max_users': 10000,
        'storage_limit_gb': 1000,
        'api_rate_limit': 10000,
        'session_timeout_minutes': 30,
        'password_policy': 'strict',
        'mfa_required': true,
        'audit_retention_days': 365,
      },
      features: [
        'advanced_analytics',
        'threat_intelligence',
        'siem_integration',
        'compliance_reporting',
        'custom_branding',
        'api_access',
        'sso_integration',
        'advanced_encryption',
        'incident_response',
        'executive_dashboard',
      ],
      branding: {
        'logo_url': 'https://enterprise.com/logo.png',
        'primary_color': '#1976D2',
        'secondary_color': '#FFC107',
        'theme': 'corporate',
        'custom_css': '',
      },
      securityPolicies: {
        'password_min_length': 12,
        'password_complexity': true,
        'mfa_enforcement': 'required',
        'session_timeout': 1800,
        'ip_whitelist': ['192.168.1.0/24', '10.0.0.0/8'],
        'device_trust_required': true,
        'encryption_level': 'aes256',
      },
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
    ));

    // SMB tenant
    await createTenant(TenantConfiguration(
      tenantId: 'smb_tech',
      name: 'SMB Tech Solutions',
      domain: 'smbtech.com',
      settings: {
        'max_users': 100,
        'storage_limit_gb': 50,
        'api_rate_limit': 1000,
        'session_timeout_minutes': 60,
        'password_policy': 'standard',
        'mfa_required': false,
        'audit_retention_days': 90,
      },
      features: [
        'basic_analytics',
        'threat_detection',
        'user_management',
        'basic_reporting',
        'email_notifications',
      ],
      branding: {
        'logo_url': 'https://smbtech.com/logo.png',
        'primary_color': '#4CAF50',
        'secondary_color': '#FF9800',
        'theme': 'modern',
        'custom_css': '',
      },
      securityPolicies: {
        'password_min_length': 8,
        'password_complexity': false,
        'mfa_enforcement': 'optional',
        'session_timeout': 3600,
        'ip_whitelist': [],
        'device_trust_required': false,
        'encryption_level': 'aes128',
      },
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
    ));

    // Startup tenant
    await createTenant(TenantConfiguration(
      tenantId: 'startup_inc',
      name: 'Startup Inc',
      domain: 'startup.io',
      settings: {
        'max_users': 25,
        'storage_limit_gb': 10,
        'api_rate_limit': 500,
        'session_timeout_minutes': 120,
        'password_policy': 'basic',
        'mfa_required': false,
        'audit_retention_days': 30,
      },
      features: [
        'basic_security',
        'user_management',
        'basic_notifications',
      ],
      branding: {
        'logo_url': 'https://startup.io/logo.png',
        'primary_color': '#9C27B0',
        'secondary_color': '#E91E63',
        'theme': 'startup',
        'custom_css': '',
      },
      securityPolicies: {
        'password_min_length': 6,
        'password_complexity': false,
        'mfa_enforcement': 'disabled',
        'session_timeout': 7200,
        'ip_whitelist': [],
        'device_trust_required': false,
        'encryption_level': 'basic',
      },
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ));
  }

  Future<void> _loadTenantMetrics() async {
    for (final tenantId in _tenants.keys) {
      _tenantMetrics[tenantId] = TenantMetrics(
        tenantId: tenantId,
        userCount: _tenantUsers[tenantId]?.length ?? 0,
        activeUsers: _tenantUsers[tenantId]?.where((u) => u.isActive).length ?? 0,
        featureUsage: _generateMockFeatureUsage(),
        securityScores: _generateMockSecurityScores(),
        lastActivity: DateTime.now().subtract(Duration(hours: DateTime.now().hour % 24)),
      );
    }
  }

  Map<String, int> _generateMockFeatureUsage() {
    return {
      'login_attempts': 150 + DateTime.now().day * 10,
      'security_scans': 25 + DateTime.now().day * 2,
      'threat_detections': 5 + DateTime.now().day,
      'reports_generated': 12 + DateTime.now().day,
      'api_calls': 1000 + DateTime.now().day * 50,
    };
  }

  Map<String, double> _generateMockSecurityScores() {
    return {
      'overall_score': 85.0 + (DateTime.now().day % 15),
      'password_strength': 90.0 + (DateTime.now().day % 10),
      'mfa_adoption': 75.0 + (DateTime.now().day % 25),
      'threat_response': 88.0 + (DateTime.now().day % 12),
      'compliance_score': 92.0 + (DateTime.now().day % 8),
    };
  }

  Future<TenantConfiguration> createTenant(TenantConfiguration tenant) async {
    _tenants[tenant.tenantId] = tenant;
    _tenantUsers[tenant.tenantId] = [];
    
    _tenantController.add(tenant);
    
    developer.log('Created tenant: ${tenant.name} (${tenant.tenantId})', name: 'MultiTenantService');
    
    return tenant;
  }

  Future<void> setCurrentTenant(String tenantId) async {
    if (_tenants.containsKey(tenantId)) {
      _currentTenantId = tenantId;
      _currentTenantController.add(tenantId);
      
      developer.log('Switched to tenant: $tenantId', name: 'MultiTenantService');
    } else {
      throw Exception('Tenant not found: $tenantId');
    }
  }

  Future<TenantConfiguration?> getTenant(String tenantId) async {
    return _tenants[tenantId];
  }

  Future<List<TenantConfiguration>> getAllTenants() async {
    return _tenants.values.toList();
  }

  Future<void> updateTenantSettings(String tenantId, Map<String, dynamic> settings) async {
    final tenant = _tenants[tenantId];
    if (tenant == null) throw Exception('Tenant not found: $tenantId');

    final updatedTenant = TenantConfiguration(
      tenantId: tenant.tenantId,
      name: tenant.name,
      domain: tenant.domain,
      settings: {...tenant.settings, ...settings},
      features: tenant.features,
      branding: tenant.branding,
      securityPolicies: tenant.securityPolicies,
      createdAt: tenant.createdAt,
      isActive: tenant.isActive,
    );

    _tenants[tenantId] = updatedTenant;
    _tenantController.add(updatedTenant);

    developer.log('Updated settings for tenant: $tenantId', name: 'MultiTenantService');
  }

  Future<void> updateTenantBranding(String tenantId, Map<String, dynamic> branding) async {
    final tenant = _tenants[tenantId];
    if (tenant == null) throw Exception('Tenant not found: $tenantId');

    final updatedTenant = TenantConfiguration(
      tenantId: tenant.tenantId,
      name: tenant.name,
      domain: tenant.domain,
      settings: tenant.settings,
      features: tenant.features,
      branding: {...tenant.branding, ...branding},
      securityPolicies: tenant.securityPolicies,
      createdAt: tenant.createdAt,
      isActive: tenant.isActive,
    );

    _tenants[tenantId] = updatedTenant;
    _tenantController.add(updatedTenant);

    developer.log('Updated branding for tenant: $tenantId', name: 'MultiTenantService');
  }

  Future<void> updateSecurityPolicies(String tenantId, Map<String, dynamic> policies) async {
    final tenant = _tenants[tenantId];
    if (tenant == null) throw Exception('Tenant not found: $tenantId');

    final updatedTenant = TenantConfiguration(
      tenantId: tenant.tenantId,
      name: tenant.name,
      domain: tenant.domain,
      settings: tenant.settings,
      features: tenant.features,
      branding: tenant.branding,
      securityPolicies: {...tenant.securityPolicies, ...policies},
      createdAt: tenant.createdAt,
      isActive: tenant.isActive,
    );

    _tenants[tenantId] = updatedTenant;
    _tenantController.add(updatedTenant);

    developer.log('Updated security policies for tenant: $tenantId', name: 'MultiTenantService');
  }

  Future<void> addUserToTenant(String tenantId, TenantUser user) async {
    if (!_tenants.containsKey(tenantId)) {
      throw Exception('Tenant not found: $tenantId');
    }

    _tenantUsers[tenantId] ??= [];
    _tenantUsers[tenantId]!.add(user);

    developer.log('Added user ${user.email} to tenant: $tenantId', name: 'MultiTenantService');
  }

  Future<void> removeUserFromTenant(String tenantId, String userId) async {
    final users = _tenantUsers[tenantId];
    if (users != null) {
      users.removeWhere((user) => user.userId == userId);
      
      developer.log('Removed user $userId from tenant: $tenantId', name: 'MultiTenantService');
    }
  }

  Future<List<TenantUser>> getTenantUsers(String tenantId) async {
    return _tenantUsers[tenantId] ?? [];
  }

  Future<bool> hasFeature(String tenantId, String feature) async {
    final tenant = _tenants[tenantId];
    return tenant?.features.contains(feature) ?? false;
  }

  Future<bool> checkPermission(String tenantId, String userId, String permission) async {
    final users = _tenantUsers[tenantId];
    if (users == null) return false;

    final user = users.firstWhere(
      (u) => u.userId == userId,
      orElse: () => throw Exception('User not found in tenant'),
    );

    return user.permissions[permission] == true;
  }

  Future<Map<String, dynamic>> getTenantSettings(String tenantId) async {
    final tenant = _tenants[tenantId];
    return tenant?.settings ?? {};
  }

  Future<Map<String, dynamic>> getSecurityPolicies(String tenantId) async {
    final tenant = _tenants[tenantId];
    return tenant?.securityPolicies ?? {};
  }

  Future<TenantMetrics?> getTenantMetrics(String tenantId) async {
    return _tenantMetrics[tenantId];
  }

  Future<Map<String, dynamic>> getTenantAnalytics(String tenantId) async {
    final metrics = _tenantMetrics[tenantId];
    final tenant = _tenants[tenantId];
    
    if (metrics == null || tenant == null) {
      return {};
    }

    return {
      'tenant_info': tenant.toJson(),
      'metrics': metrics.toJson(),
      'utilization': {
        'users': (metrics.userCount / (tenant.settings['max_users'] ?? 1)) * 100,
        'storage': 45.0, // Mock storage usage percentage
        'api_calls': (metrics.featureUsage['api_calls'] ?? 0) / (tenant.settings['api_rate_limit'] ?? 1) * 100,
      },
      'growth_metrics': {
        'user_growth_rate': 15.5,
        'feature_adoption_rate': 78.2,
        'security_improvement': 12.3,
      },
    };
  }

  Future<List<Map<String, dynamic>>> getTenantComparison() async {
    final comparisons = <Map<String, dynamic>>[];
    
    for (final tenant in _tenants.values) {
      final metrics = _tenantMetrics[tenant.tenantId];
      if (metrics != null) {
        comparisons.add({
          'tenant_id': tenant.tenantId,
          'name': tenant.name,
          'user_count': metrics.userCount,
          'security_score': metrics.securityScores['overall_score'],
          'feature_count': tenant.features.length,
          'last_activity': metrics.lastActivity.toIso8601String(),
        });
      }
    }
    
    return comparisons;
  }

  Future<void> activateTenant(String tenantId) async {
    final tenant = _tenants[tenantId];
    if (tenant == null) throw Exception('Tenant not found: $tenantId');

    final updatedTenant = TenantConfiguration(
      tenantId: tenant.tenantId,
      name: tenant.name,
      domain: tenant.domain,
      settings: tenant.settings,
      features: tenant.features,
      branding: tenant.branding,
      securityPolicies: tenant.securityPolicies,
      createdAt: tenant.createdAt,
      isActive: true,
    );

    _tenants[tenantId] = updatedTenant;
    _tenantController.add(updatedTenant);

    developer.log('Activated tenant: $tenantId', name: 'MultiTenantService');
  }

  Future<void> deactivateTenant(String tenantId) async {
    final tenant = _tenants[tenantId];
    if (tenant == null) throw Exception('Tenant not found: $tenantId');

    final updatedTenant = TenantConfiguration(
      tenantId: tenant.tenantId,
      name: tenant.name,
      domain: tenant.domain,
      settings: tenant.settings,
      features: tenant.features,
      branding: tenant.branding,
      securityPolicies: tenant.securityPolicies,
      createdAt: tenant.createdAt,
      isActive: false,
    );

    _tenants[tenantId] = updatedTenant;
    _tenantController.add(updatedTenant);

    developer.log('Deactivated tenant: $tenantId', name: 'MultiTenantService');
  }

  Future<void> deleteTenant(String tenantId) async {
    _tenants.remove(tenantId);
    _tenantUsers.remove(tenantId);
    _tenantMetrics.remove(tenantId);

    developer.log('Deleted tenant: $tenantId', name: 'MultiTenantService');
  }

  Map<String, dynamic> getMultiTenantMetrics() {
    return {
      'total_tenants': _tenants.length,
      'active_tenants': _tenants.values.where((t) => t.isActive).length,
      'total_users': _tenantUsers.values.fold(0, (sum, users) => sum + users.length),
      'tenants_by_size': _getTenantsBySize(),
      'feature_adoption': _getFeatureAdoption(),
      'security_scores': _getAverageSecurityScores(),
    };
  }

  Map<String, int> _getTenantsBySize() {
    final sizeCategories = {'small': 0, 'medium': 0, 'large': 0, 'enterprise': 0};
    
    for (final tenant in _tenants.values) {
      final maxUsers = tenant.settings['max_users'] ?? 0;
      if (maxUsers <= 50) {
        sizeCategories['small'] = (sizeCategories['small'] ?? 0) + 1;
      } else if (maxUsers <= 500) {
        sizeCategories['medium'] = (sizeCategories['medium'] ?? 0) + 1;
      } else if (maxUsers <= 5000) {
        sizeCategories['large'] = (sizeCategories['large'] ?? 0) + 1;
      } else {
        sizeCategories['enterprise'] = (sizeCategories['enterprise'] ?? 0) + 1;
      }
    }
    
    return sizeCategories;
  }

  Map<String, double> _getFeatureAdoption() {
    final featureCounts = <String, int>{};
    final totalTenants = _tenants.length;
    
    for (final tenant in _tenants.values) {
      for (final feature in tenant.features) {
        featureCounts[feature] = (featureCounts[feature] ?? 0) + 1;
      }
    }
    
    return featureCounts.map((feature, count) => 
      MapEntry(feature, totalTenants > 0 ? (count / totalTenants) * 100 : 0));
  }

  Map<String, double> _getAverageSecurityScores() {
    final scores = <String, List<double>>{};
    
    for (final metrics in _tenantMetrics.values) {
      for (final entry in metrics.securityScores.entries) {
        scores[entry.key] ??= [];
        scores[entry.key]!.add(entry.value);
      }
    }
    
    return scores.map((key, values) => 
      MapEntry(key, values.isNotEmpty ? values.reduce((a, b) => a + b) / values.length : 0));
  }

  void dispose() {
    _tenantController.close();
    _currentTenantController.close();
  }
}
