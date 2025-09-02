import 'package:flutter/foundation.dart';

class ProductionConfig {
  static const String _prodApiBaseUrl = 'https://your-production-api.com';
  static const String _stagingApiBaseUrl = 'https://staging-api.com';
  static const String _devApiBaseUrl = 'http://192.168.100.21:3000';

  // API Configuration
  static String get apiBaseUrl {
    if (kReleaseMode) {
      return _prodApiBaseUrl;
    } else if (kProfileMode) {
      return _stagingApiBaseUrl;
    } else {
      return _devApiBaseUrl;
    }
  }

  // Security Configuration
  static const Map<String, dynamic> securityConfig = {
    'encryption': {
      'default_algorithm': 'AES-256-GCM',
      'key_rotation_interval_days': 30,
      'quantum_resistant_enabled': true,
      'backup_encryption_enabled': true,
    },
    'authentication': {
      'session_timeout_minutes': 60,
      'max_failed_attempts': 5,
      'lockout_duration_minutes': 30,
      'mfa_required': true,
      'biometric_enabled': true,
    },
    'monitoring': {
      'real_time_alerts': true,
      'threat_detection_enabled': true,
      'behavioral_analysis': true,
      'device_fingerprinting': true,
      'continuous_monitoring': true,
    },
    'compliance': {
      'gdpr_enabled': true,
      'hipaa_enabled': false,
      'sox_enabled': false,
      'audit_logging': true,
      'data_retention_days': 2555, // 7 years
    },
  };

  // Feature Flags for Production
  static const Map<String, bool> productionFeatureFlags = {
    'advanced_ai_security': true,
    'quantum_encryption': false, // Disabled until fully tested
    'dark_web_monitoring': true,
    'behavioral_biometrics': true,
    'automated_incident_response': true,
    'executive_reporting': true,
    'multi_tenant_support': true,
    'offline_security': true,
    'threat_intelligence': true,
    'business_intelligence': true,
    'smart_onboarding': true,
    'enhanced_accessibility': true,
    'localization_support': true,
    'integration_hub': true,
    'api_gateway': true,
    'health_monitoring': true,
    'security_testing': false, // Disabled in production
  };

  // Performance Configuration
  static const Map<String, dynamic> performanceConfig = {
    'api_timeout_seconds': 30,
    'websocket_reconnect_attempts': 5,
    'cache_duration_minutes': 15,
    'batch_size_limit': 100,
    'concurrent_requests_limit': 10,
    'memory_cache_size_mb': 50,
    'disk_cache_size_mb': 200,
  };

  // Logging Configuration
  static const Map<String, dynamic> loggingConfig = {
    'log_level': kReleaseMode ? 'ERROR' : 'DEBUG',
    'remote_logging_enabled': true,
    'crash_reporting_enabled': true,
    'analytics_enabled': true,
    'performance_monitoring': true,
    'security_event_logging': true,
    'audit_trail_enabled': true,
  };

  // Notification Configuration
  static const Map<String, dynamic> notificationConfig = {
    'push_notifications_enabled': true,
    'email_notifications_enabled': true,
    'sms_notifications_enabled': false,
    'in_app_notifications_enabled': true,
    'webhook_notifications_enabled': true,
    'slack_integration_enabled': false,
    'teams_integration_enabled': false,
  };

  // Database Configuration
  static const Map<String, dynamic> databaseConfig = {
    'connection_pool_size': 20,
    'query_timeout_seconds': 30,
    'backup_enabled': true,
    'backup_interval_hours': 6,
    'encryption_at_rest': true,
    'encryption_in_transit': true,
    'audit_logging': true,
  };

  // Rate Limiting Configuration
  static const Map<String, dynamic> rateLimitingConfig = {
    'api_requests_per_minute': 1000,
    'login_attempts_per_hour': 10,
    'password_reset_per_day': 5,
    'biometric_attempts_per_minute': 20,
    'file_upload_per_hour': 50,
    'report_generation_per_hour': 10,
  };

  // Security Thresholds
  static const Map<String, dynamic> securityThresholds = {
    'threat_score_critical': 9.0,
    'threat_score_high': 7.0,
    'threat_score_medium': 5.0,
    'device_trust_minimum': 8.0,
    'biometric_confidence_minimum': 0.95,
    'anomaly_detection_sensitivity': 0.8,
    'fraud_detection_threshold': 0.7,
  };

  // Backup and Recovery Configuration
  static const Map<String, dynamic> backupConfig = {
    'automated_backups': true,
    'backup_retention_days': 90,
    'point_in_time_recovery': true,
    'cross_region_backup': true,
    'backup_encryption': true,
    'backup_compression': true,
    'disaster_recovery_enabled': true,
  };

  // Monitoring and Alerting
  static const Map<String, dynamic> monitoringConfig = {
    'health_check_interval_seconds': 30,
    'metric_collection_interval_seconds': 60,
    'alert_escalation_minutes': 15,
    'incident_auto_creation': true,
    'sla_monitoring': true,
    'performance_baseline_enabled': true,
    'anomaly_detection_enabled': true,
  };

  // Compliance and Audit
  static const Map<String, dynamic> complianceConfig = {
    'audit_log_retention_years': 7,
    'compliance_reporting_enabled': true,
    'data_classification_enabled': true,
    'privacy_controls_enabled': true,
    'consent_management': true,
    'data_subject_rights': true,
    'breach_notification_enabled': true,
  };

  // Environment-specific settings
  static bool get isProduction => kReleaseMode;
  static bool get isStaging => kProfileMode;
  static bool get isDevelopment => kDebugMode;

  // Get configuration based on environment
  static T getConfigValue<T>(String key, T defaultValue) {
    final configs = {
      'production': productionFeatureFlags,
      'staging': productionFeatureFlags,
      'development': productionFeatureFlags,
    };

    final currentConfig = isProduction 
        ? configs['production']
        : isStaging 
            ? configs['staging'] 
            : configs['development'];

    return currentConfig?[key] as T? ?? defaultValue;
  }

  // Validate production readiness
  static List<String> validateProductionReadiness() {
    final issues = <String>[];

    // Check API configuration
    if (apiBaseUrl.contains('localhost') || apiBaseUrl.contains('192.168')) {
      issues.add('API URL points to local/development server');
    }

    // Check security settings
    if (!securityConfig['authentication']['mfa_required']) {
      issues.add('MFA is not required in production');
    }

    if (!securityConfig['monitoring']['threat_detection_enabled']) {
      issues.add('Threat detection is disabled');
    }

    // Check compliance
    if (!securityConfig['compliance']['audit_logging']) {
      issues.add('Audit logging is disabled');
    }

    // Check backup configuration
    if (!backupConfig['automated_backups']) {
      issues.add('Automated backups are disabled');
    }

    // Check monitoring
    if (!monitoringConfig['health_check_interval_seconds']) {
      issues.add('Health checks are disabled');
    }

    return issues;
  }

  // Get environment info
  static Map<String, dynamic> getEnvironmentInfo() {
    return {
      'environment': isProduction ? 'production' : isStaging ? 'staging' : 'development',
      'api_base_url': apiBaseUrl,
      'debug_mode': kDebugMode,
      'profile_mode': kProfileMode,
      'release_mode': kReleaseMode,
      'build_timestamp': DateTime.now().toIso8601String(),
    };
  }
}
