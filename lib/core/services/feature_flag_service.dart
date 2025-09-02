import 'dart:async';
import 'dart:developer' as developer;

class FeatureFlag {
  final String flagId;
  final String name;
  final String description;
  final bool isEnabled;
  final Map<String, dynamic> conditions;
  final Map<String, dynamic> variants;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;

  FeatureFlag({
    required this.flagId,
    required this.name,
    required this.description,
    required this.isEnabled,
    required this.conditions,
    required this.variants,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
  });

  Map<String, dynamic> toJson() => {
    'flag_id': flagId,
    'name': name,
    'description': description,
    'is_enabled': isEnabled,
    'conditions': conditions,
    'variants': variants,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'created_by': createdBy,
  };
}

class UserContext {
  final String userId;
  final String userRole;
  final String tenantId;
  final Map<String, dynamic> attributes;
  final DateTime timestamp;

  UserContext({
    required this.userId,
    required this.userRole,
    required this.tenantId,
    required this.attributes,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'user_role': userRole,
    'tenant_id': tenantId,
    'attributes': attributes,
    'timestamp': timestamp.toIso8601String(),
  };
}

class ExperimentResult {
  final String experimentId;
  final String userId;
  final String variant;
  final Map<String, dynamic> metrics;
  final DateTime timestamp;

  ExperimentResult({
    required this.experimentId,
    required this.userId,
    required this.variant,
    required this.metrics,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'experiment_id': experimentId,
    'user_id': userId,
    'variant': variant,
    'metrics': metrics,
    'timestamp': timestamp.toIso8601String(),
  };
}

class FeatureFlagService {
  static final FeatureFlagService _instance = FeatureFlagService._internal();
  factory FeatureFlagService() => _instance;
  FeatureFlagService._internal();

  final Map<String, FeatureFlag> _flags = {};
  final Map<String, List<ExperimentResult>> _experimentResults = {};
  final Map<String, Map<String, dynamic>> _userVariants = {};
  
  final StreamController<FeatureFlag> _flagController = StreamController.broadcast();
  final StreamController<ExperimentResult> _experimentController = StreamController.broadcast();

  Stream<FeatureFlag> get flagStream => _flagController.stream;
  Stream<ExperimentResult> get experimentStream => _experimentController.stream;
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    await _createDefaultFlags();
    _isInitialized = true;
    
    developer.log('Feature Flag Service initialized', name: 'FeatureFlagService');
  }

  Future<void> _createDefaultFlags() async {
    // Security Features
    await createFlag(FeatureFlag(
      flagId: 'advanced_threat_detection',
      name: 'Advanced Threat Detection',
      description: 'Enable AI-powered advanced threat detection capabilities',
      isEnabled: true,
      conditions: {
        'user_roles': ['admin', 'security_analyst'],
        'tenant_tiers': ['enterprise', 'premium'],
        'min_version': '2.0.0',
      },
      variants: {
        'control': {'enabled': false, 'ml_model': 'basic'},
        'treatment': {'enabled': true, 'ml_model': 'advanced'},
      },
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      createdBy: 'system',
    ));

    await createFlag(FeatureFlag(
      flagId: 'biometric_authentication',
      name: 'Biometric Authentication',
      description: 'Enable biometric authentication methods',
      isEnabled: true,
      conditions: {
        'user_roles': ['admin', 'user'],
        'device_capabilities': ['fingerprint', 'face_id'],
        'security_level': 'high',
      },
      variants: {
        'fingerprint_only': {'methods': ['fingerprint']},
        'face_id_only': {'methods': ['face_id']},
        'multi_modal': {'methods': ['fingerprint', 'face_id', 'voice']},
      },
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      createdBy: 'security_team',
    ));

    await createFlag(FeatureFlag(
      flagId: 'zero_trust_architecture',
      name: 'Zero Trust Architecture',
      description: 'Enable zero trust security model',
      isEnabled: false,
      conditions: {
        'tenant_tiers': ['enterprise'],
        'pilot_users': true,
        'region': ['us-east', 'eu-west'],
      },
      variants: {
        'pilot': {'trust_score_threshold': 0.8, 'continuous_verification': true},
        'full': {'trust_score_threshold': 0.9, 'continuous_verification': true, 'device_attestation': true},
      },
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      createdBy: 'security_architect',
    ));

    // UI/UX Features
    await createFlag(FeatureFlag(
      flagId: 'new_dashboard_layout',
      name: 'New Dashboard Layout',
      description: 'A/B test for new security dashboard design',
      isEnabled: true,
      conditions: {
        'user_roles': ['admin', 'analyst'],
        'experiment_group': 'dashboard_redesign',
      },
      variants: {
        'control': {'layout': 'classic', 'widgets': 'standard'},
        'variant_a': {'layout': 'modern', 'widgets': 'enhanced'},
        'variant_b': {'layout': 'compact', 'widgets': 'minimal'},
      },
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      createdBy: 'ux_team',
    ));

    await createFlag(FeatureFlag(
      flagId: 'dark_mode_theme',
      name: 'Dark Mode Theme',
      description: 'Enable dark mode theme option',
      isEnabled: true,
      conditions: {
        'user_preference': 'dark_mode',
        'time_of_day': 'evening',
      },
      variants: {
        'light': {'theme': 'light', 'contrast': 'normal'},
        'dark': {'theme': 'dark', 'contrast': 'high'},
        'auto': {'theme': 'auto', 'contrast': 'adaptive'},
      },
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      createdBy: 'ui_team',
    ));

    // Performance Features
    await createFlag(FeatureFlag(
      flagId: 'lazy_loading_optimization',
      name: 'Lazy Loading Optimization',
      description: 'Enable lazy loading for improved performance',
      isEnabled: true,
      conditions: {
        'device_type': ['mobile', 'tablet'],
        'network_speed': 'slow',
      },
      variants: {
        'disabled': {'lazy_loading': false},
        'basic': {'lazy_loading': true, 'chunk_size': 'small'},
        'aggressive': {'lazy_loading': true, 'chunk_size': 'micro', 'preload': false},
      },
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      createdBy: 'performance_team',
    ));

    // Integration Features
    await createFlag(FeatureFlag(
      flagId: 'slack_integration_v2',
      name: 'Slack Integration V2',
      description: 'New Slack integration with enhanced features',
      isEnabled: false,
      conditions: {
        'tenant_tiers': ['enterprise', 'premium'],
        'beta_program': true,
      },
      variants: {
        'v1': {'version': '1.0', 'features': ['basic_notifications']},
        'v2': {'version': '2.0', 'features': ['rich_notifications', 'interactive_buttons', 'slash_commands']},
      },
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      createdBy: 'integration_team',
    ));

    // Analytics Features
    await createFlag(FeatureFlag(
      flagId: 'real_time_analytics',
      name: 'Real-time Analytics',
      description: 'Enable real-time analytics processing',
      isEnabled: true,
      conditions: {
        'user_roles': ['admin', 'analyst'],
        'data_volume': 'high',
      },
      variants: {
        'batch': {'processing': 'batch', 'interval': '5min'},
        'streaming': {'processing': 'streaming', 'interval': 'real_time'},
        'hybrid': {'processing': 'hybrid', 'interval': 'adaptive'},
      },
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      createdBy: 'analytics_team',
    ));
  }

  Future<FeatureFlag> createFlag(FeatureFlag flag) async {
    _flags[flag.flagId] = flag;
    _flagController.add(flag);
    
    developer.log('Created feature flag: ${flag.name}', name: 'FeatureFlagService');
    
    return flag;
  }

  Future<bool> isFeatureEnabled(String flagId, UserContext userContext) async {
    final flag = _flags[flagId];
    if (flag == null || !flag.isEnabled) return false;

    return _evaluateConditions(flag, userContext);
  }

  Future<String> getFeatureVariant(String flagId, UserContext userContext) async {
    final flag = _flags[flagId];
    if (flag == null || !flag.isEnabled) return 'control';

    if (!_evaluateConditions(flag, userContext)) return 'control';

    // Check if user already has a variant assigned
    final userKey = '${userContext.userId}_$flagId';
    if (_userVariants.containsKey(userKey)) {
      return _userVariants[userKey]!['variant'];
    }

    // Assign variant based on user ID hash for consistency
    final variant = _assignVariant(flag, userContext);
    
    _userVariants[userKey] = {
      'variant': variant,
      'assigned_at': DateTime.now().toIso8601String(),
      'user_context': userContext.toJson(),
    };

    return variant;
  }

  bool _evaluateConditions(FeatureFlag flag, UserContext userContext) {
    for (final entry in flag.conditions.entries) {
      final condition = entry.key;
      final value = entry.value;

      switch (condition) {
        case 'user_roles':
          if (value is List && !value.contains(userContext.userRole)) {
            return false;
          }
          break;

        case 'tenant_tiers':
          final tenantTier = userContext.attributes['tenant_tier'];
          if (value is List && !value.contains(tenantTier)) {
            return false;
          }
          break;

        case 'min_version':
          final userVersion = userContext.attributes['app_version'] ?? '1.0.0';
          if (!_isVersionGreaterOrEqual(userVersion, value)) {
            return false;
          }
          break;

        case 'device_capabilities':
          final deviceCapabilities = userContext.attributes['device_capabilities'] ?? [];
          if (value is List && !value.any((cap) => deviceCapabilities.contains(cap))) {
            return false;
          }
          break;

        case 'security_level':
          final securityLevel = userContext.attributes['security_level'];
          if (securityLevel != value) {
            return false;
          }
          break;

        case 'pilot_users':
          final isPilotUser = userContext.attributes['pilot_user'] ?? false;
          if (value == true && !isPilotUser) {
            return false;
          }
          break;

        case 'region':
          final userRegion = userContext.attributes['region'];
          if (value is List && !value.contains(userRegion)) {
            return false;
          }
          break;

        case 'experiment_group':
          final experimentGroup = userContext.attributes['experiment_group'];
          if (experimentGroup != value) {
            return false;
          }
          break;

        case 'user_preference':
          final preference = userContext.attributes[value];
          if (preference != true) {
            return false;
          }
          break;

        case 'time_of_day':
          final currentHour = DateTime.now().hour;
          if (value == 'evening' && (currentHour < 18 || currentHour > 23)) {
            return false;
          }
          break;

        case 'device_type':
          final deviceType = userContext.attributes['device_type'];
          if (value is List && !value.contains(deviceType)) {
            return false;
          }
          break;

        case 'network_speed':
          final networkSpeed = userContext.attributes['network_speed'];
          if (networkSpeed != value) {
            return false;
          }
          break;

        case 'beta_program':
          final isBetaUser = userContext.attributes['beta_program'] ?? false;
          if (value == true && !isBetaUser) {
            return false;
          }
          break;

        case 'data_volume':
          final dataVolume = userContext.attributes['data_volume'];
          if (dataVolume != value) {
            return false;
          }
          break;
      }
    }

    return true;
  }

  String _assignVariant(FeatureFlag flag, UserContext userContext) {
    final variants = flag.variants.keys.toList();
    if (variants.isEmpty) return 'control';

    // Use consistent hashing based on user ID and flag ID
    final hash = '${userContext.userId}_${flag.flagId}'.hashCode.abs();
    final variantIndex = hash % variants.length;
    
    return variants[variantIndex];
  }

  bool _isVersionGreaterOrEqual(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();
    
    for (int i = 0; i < 3; i++) {
      final v1Part = i < v1Parts.length ? v1Parts[i] : 0;
      final v2Part = i < v2Parts.length ? v2Parts[i] : 0;
      
      if (v1Part > v2Part) return true;
      if (v1Part < v2Part) return false;
    }
    
    return true; // Equal versions
  }

  Future<void> recordExperimentResult({
    required String experimentId,
    required String userId,
    required String variant,
    required Map<String, dynamic> metrics,
  }) async {
    final result = ExperimentResult(
      experimentId: experimentId,
      userId: userId,
      variant: variant,
      metrics: metrics,
      timestamp: DateTime.now(),
    );

    _experimentResults[experimentId] ??= [];
    _experimentResults[experimentId]!.add(result);
    _experimentController.add(result);

    developer.log('Recorded experiment result for $experimentId', name: 'FeatureFlagService');
  }

  Future<void> updateFlag(String flagId, {
    bool? isEnabled,
    Map<String, dynamic>? conditions,
    Map<String, dynamic>? variants,
  }) async {
    final flag = _flags[flagId];
    if (flag == null) throw Exception('Flag not found: $flagId');

    final updatedFlag = FeatureFlag(
      flagId: flag.flagId,
      name: flag.name,
      description: flag.description,
      isEnabled: isEnabled ?? flag.isEnabled,
      conditions: conditions ?? flag.conditions,
      variants: variants ?? flag.variants,
      createdAt: flag.createdAt,
      updatedAt: DateTime.now(),
      createdBy: flag.createdBy,
    );

    _flags[flagId] = updatedFlag;
    _flagController.add(updatedFlag);

    developer.log('Updated feature flag: ${flag.name}', name: 'FeatureFlagService');
  }

  Future<void> deleteFlag(String flagId) async {
    _flags.remove(flagId);
    _experimentResults.remove(flagId);
    
    // Remove user variant assignments for this flag
    _userVariants.removeWhere((key, value) => key.endsWith('_$flagId'));

    developer.log('Deleted feature flag: $flagId', name: 'FeatureFlagService');
  }

  Future<List<FeatureFlag>> getAllFlags() async {
    return _flags.values.toList();
  }

  Future<FeatureFlag?> getFlag(String flagId) async {
    return _flags[flagId];
  }

  Future<Map<String, dynamic>> getExperimentAnalytics(String experimentId) async {
    final results = _experimentResults[experimentId] ?? [];
    if (results.isEmpty) return {};

    final variantGroups = <String, List<ExperimentResult>>{};
    for (final result in results) {
      variantGroups[result.variant] ??= [];
      variantGroups[result.variant]!.add(result);
    }

    final analytics = <String, dynamic>{
      'experiment_id': experimentId,
      'total_participants': results.length,
      'variants': {},
    };

    for (final entry in variantGroups.entries) {
      final variant = entry.key;
      final variantResults = entry.value;
      
      analytics['variants'][variant] = {
        'participant_count': variantResults.length,
        'conversion_rate': _calculateConversionRate(variantResults),
        'avg_engagement': _calculateAverageEngagement(variantResults),
        'retention_rate': _calculateRetentionRate(variantResults),
      };
    }

    return analytics;
  }

  double _calculateConversionRate(List<ExperimentResult> results) {
    if (results.isEmpty) return 0.0;
    
    final conversions = results.where((r) => r.metrics['converted'] == true).length;
    return (conversions / results.length) * 100;
  }

  double _calculateAverageEngagement(List<ExperimentResult> results) {
    if (results.isEmpty) return 0.0;
    
    final totalEngagement = results.fold<double>(0.0, (sum, r) => 
      sum + (r.metrics['engagement_score'] ?? 0.0));
    return totalEngagement / results.length;
  }

  double _calculateRetentionRate(List<ExperimentResult> results) {
    if (results.isEmpty) return 0.0;
    
    final retained = results.where((r) => r.metrics['retained'] == true).length;
    return (retained / results.length) * 100;
  }

  Map<String, dynamic> getFeatureFlagMetrics() {
    final totalFlags = _flags.length;
    final enabledFlags = _flags.values.where((f) => f.isEnabled).length;
    final experimentFlags = _flags.values.where((f) => f.variants.length > 1).length;
    
    final flagsByCategory = <String, int>{};
    for (final flag in _flags.values) {
      final category = flag.name.split(' ').first.toLowerCase();
      flagsByCategory[category] = (flagsByCategory[category] ?? 0) + 1;
    }

    return {
      'total_flags': totalFlags,
      'enabled_flags': enabledFlags,
      'disabled_flags': totalFlags - enabledFlags,
      'experiment_flags': experimentFlags,
      'flags_by_category': flagsByCategory,
      'total_experiments': _experimentResults.length,
      'total_participants': _experimentResults.values.fold(0, (sum, results) => sum + results.length),
      'user_variant_assignments': _userVariants.length,
    };
  }

  String? getExperimentVariant(String experimentId, UserContext userContext) {
    // Mock experiment variant assignment
    final variants = ['control', 'variant_a', 'variant_b'];
    final hash = (userContext.userId.hashCode + experimentId.hashCode).abs();
    return variants[hash % variants.length];
  }

  void dispose() {
    _flagController.close();
    _experimentController.close();
  }
}
