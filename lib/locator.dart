import 'package:get_it/get_it.dart';
import 'core/config/app_config.dart';
import 'core/services/api_service.dart';
import 'features/auth/services/biometric_service.dart';
import 'features/admin/services/threat_intelligence_service.dart';
import 'features/admin/services/incident_response_service.dart' as admin_incident;
import 'features/admin/services/enhanced_user_management_service.dart';
import 'core/services/admin_data_service.dart';
import 'features/admin/services/siem_integration_service.dart';
import 'features/admin/services/logging_service.dart';
import 'features/auth/services/risk_based_auth_service.dart';
import 'core/services/categories_service.dart';
import 'core/services/conflict_resolution_service.dart';
import 'core/services/keyboard_shortcuts_service.dart';
import 'features/admin/services/real_time_monitoring_service.dart';
import 'features/admin/services/security_drills_service.dart';
import 'package:clean_flutter/features/admin/services/ai_security_copilot_service.dart';
import 'package:clean_flutter/features/admin/services/dashboard_customization_service.dart';
import 'package:clean_flutter/features/admin/services/zero_trust_service.dart';
import 'features/admin/services/forensics_investigation_service.dart';
import 'features/admin/services/third_party_integrations_service.dart';
import 'features/admin/services/compliance_reporting_service.dart' as admin_compliance;
import 'features/admin/services/ai_assistant_service.dart';
import 'features/admin/services/ai_engineering_expert_service.dart';
import 'features/admin/services/security_orchestration_service.dart';
import 'features/admin/services/enhanced_security_orchestration_service.dart';
import 'features/admin/services/performance_monitoring_service.dart';
import 'features/admin/services/enhanced_performance_monitoring_service.dart';
import 'features/admin/services/emerging_threats_service.dart';
import 'features/admin/services/enhanced_emerging_threats_service.dart';
import 'core/services/captcha_service.dart';
import 'core/services/privacy_dashboard_service.dart';
import 'core/services/role_management_service.dart';
import 'core/services/user_activity_service.dart';
import 'core/services/security_settings_service.dart';
import 'core/services/database_migration_service.dart';
import 'core/services/backend_sync_service.dart';
import 'core/services/migration_service.dart';
import 'features/auth/services/auth_service.dart';
import 'package:clean_flutter/core/services/api_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/database_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/backend_auth_service.dart';
import 'core/services/realtime_notification_service.dart';
import 'core/services/background_sync_service.dart';
import 'core/services/webauthn_service.dart';
import 'package:clean_flutter/core/services/api_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/database_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/backend_auth_service.dart';
import 'core/services/backend_threat_intelligence_service.dart';
import 'core/services/backend_security_analytics_service.dart';
import 'core/services/backend_websocket_service.dart';
import 'core/services/smart_form_validation_service.dart';
import 'core/services/backend_user_management_service.dart';
import 'core/services/backend_notification_service.dart';
import 'core/services/user_profile_service.dart';
import 'core/services/session_management_service.dart';
import 'core/services/security_data_service.dart';
import 'core/services/file_export_service.dart';
import 'core/services/encrypted_storage_service.dart';
import 'core/services/totp_manager_service.dart';
import 'package:clean_flutter/features/admin/services/summary_email_scheduler.dart';
import 'package:clean_flutter/features/auth/services/phone_auth_service.dart';
import 'package:clean_flutter/core/services/theme_service.dart';
import 'package:clean_flutter/core/services/hybrid_auth_service.dart';
import 'package:clean_flutter/core/services/backend_service.dart';
import 'package:clean_flutter/core/services/simple_sync_service.dart';
import 'package:clean_flutter/core/services/encryption_service.dart';
import 'package:clean_flutter/core/services/threat_monitoring_service.dart';
import 'package:clean_flutter/core/services/ip_access_control_service.dart';
import 'package:clean_flutter/core/services/incident_response_service.dart' as core_incident;
import 'package:clean_flutter/core/services/device_fingerprinting_service.dart';
import 'package:clean_flutter/core/services/pending_actions_service.dart';
import 'package:clean_flutter/core/services/totp_overlay_service.dart';
import 'package:clean_flutter/core/services/rate_limiting_service.dart';
import 'package:clean_flutter/core/services/compliance_reporting_service.dart' as core_compliance;
import 'package:clean_flutter/core/services/security_policy_service.dart';
import 'package:clean_flutter/core/services/vulnerability_scanning_service.dart';
import 'package:clean_flutter/core/services/user_behavior_analytics_service.dart';
import 'package:clean_flutter/core/services/audit_trail_service.dart';
import 'package:clean_flutter/core/services/health_monitoring_service.dart';
import 'core/services/ai_powered_security_service.dart';
import 'core/services/advanced_biometrics_service.dart';
import 'core/services/smart_onboarding_service.dart';
import 'core/services/enhanced_accessibility_service.dart';
import 'core/services/localization_service.dart';
import 'core/services/multi_tenant_service.dart';
import 'core/services/executive_reporting_service.dart';
import 'core/services/integration_hub_service.dart';
import 'core/services/api_gateway_service.dart';
import 'core/services/feature_flag_service.dart';
import 'core/services/advanced_encryption_service.dart';
import 'core/services/security_testing_service.dart';
import 'core/services/device_security_service.dart';
import 'core/services/offline_security_service.dart';
import 'core/services/business_intelligence_service.dart';
import 'core/services/threat_intelligence_platform.dart';
import 'core/services/real_time_analytics_service.dart';
import 'core/services/automated_incident_response_service.dart';
import 'core/services/hardware_mfa_service.dart';
import 'core/services/zero_trust_network_service.dart';
import 'core/services/quantum_resistant_crypto_service.dart';
import 'core/services/security_compliance_automation_service.dart';
import 'core/services/mobile_device_management_service.dart';
import 'core/services/advanced_forensics_service.dart';
import 'core/services/production_database_service.dart';
import 'core/services/production_crypto_service.dart';
import 'core/services/environment_service.dart';
import 'core/services/real_phone_auth_service.dart';
import 'core/services/database_migration_service.dart';
import 'core/services/production_backend_service.dart' as prod_backend;
import 'package:clean_flutter/features/admin/services/email_settings_service.dart';
import 'package:clean_flutter/features/admin/services/mfa_settings_service.dart';
import 'package:clean_flutter/core/services/enhanced_backup_codes_service.dart';
import 'package:clean_flutter/core/services/email_service.dart';
import 'package:clean_flutter/core/services/language_service.dart';
import 'package:clean_flutter/core/services/enhanced_auth_service.dart';
import 'package:clean_flutter/core/services/advanced_login_monitor.dart';
import 'package:clean_flutter/core/services/rbac_service.dart';
import 'package:clean_flutter/core/services/enhanced_rbac_service.dart';
import 'package:clean_flutter/core/services/rbac_audit_service.dart';
import 'package:clean_flutter/core/services/role_persistence_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GetIt locator = GetIt.instance;

Future<void> setupLocator() async {
  // Register SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  locator.registerSingleton<SharedPreferences>(prefs);
  
  // Register RolePersistenceService
  locator.registerLazySingleton<RolePersistenceService>(
    () => RolePersistenceService(locator<SharedPreferences>()),
  );
  
  // Register API Client
  locator.registerLazySingleton<ApiService>(() => ApiService());
  
  // Register Backend Services
  locator.registerLazySingleton<BackendAuthService>(() => BackendAuthService());
  locator.registerLazySingleton<BackendThreatIntelligenceService>(() => BackendThreatIntelligenceService());
  locator.registerLazySingleton<BackendSecurityAnalyticsService>(() => BackendSecurityAnalyticsService());
  locator.registerLazySingleton<BackendWebSocketService>(() => BackendWebSocketService());
  locator.registerLazySingleton<BackendUserManagementService>(() => BackendUserManagementService());
  locator.registerLazySingleton<SmartOnboardingService>(() => SmartOnboardingService());
  locator.registerLazySingleton<EnhancedAccessibilityService>(() => EnhancedAccessibilityService());
  locator.registerLazySingleton<LocalizationService>(() => LocalizationService());
  locator.registerLazySingleton<MultiTenantService>(() => MultiTenantService());
  locator.registerLazySingleton<ExecutiveReportingService>(() => ExecutiveReportingService());
  locator.registerLazySingleton<IntegrationHubService>(() => IntegrationHubService());
  locator.registerLazySingleton<ApiGatewayService>(() => ApiGatewayService());
  locator.registerLazySingleton<BackendNotificationService>(() => BackendNotificationService());
  
  // Register Auth Services
  locator.registerLazySingleton<AuthService>(() => AuthService());
  locator.registerLazySingleton(() => PendingActionsService());
  locator.registerLazySingleton<BiometricService>(() => BiometricService());
  locator.registerLazySingleton<PhoneAuthService>(() => PhoneAuthService());
  locator.registerLazySingleton<BackendService>(() => BackendService());
  locator.registerSingleton<DatabaseService>(
    DatabaseService(
      baseUrl: AppConfig.backendUrl,
      useMockMode: AppConfig.useLocalStorage,
    ),
  );
  locator.registerLazySingleton<HybridAuthService>(() => HybridAuthService());
  locator.registerLazySingleton<AdvancedLoginMonitor>(() => AdvancedLoginMonitor());
  locator.registerLazySingleton<EnhancedAuthService>(() => EnhancedAuthService());
  locator.registerLazySingleton<SimpleSyncService>(() => SimpleSyncService());
  locator.registerLazySingleton<SummaryEmailScheduler>(() => SummaryEmailScheduler());
  locator.registerLazySingleton<LoggingService>(() => LoggingService());
  
  // Register Core Services
  locator.registerLazySingleton<NotificationService>(() => NotificationService(locator<ApiService>()));
  locator.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  
  // Register TOTP Services
  locator.registerLazySingleton<EncryptedStorageService>(() => EncryptedStorageService());
  locator.registerLazySingleton<TotpManagerService>(() => TotpManagerService());
  // locator.registerLazySingleton<SettingsService>(() => SettingsService());
  locator.registerLazySingleton<ThemeService>(() => ThemeService());
  
  // Register services with API dependencies
  locator.registerLazySingleton<RealtimeNotificationService>(
    () => RealtimeNotificationService(
      notificationService: locator<NotificationService>(),
      apiService: locator<ApiService>(),
    ),
  );
  
  locator.registerLazySingleton<BackgroundSyncService>(
    () => BackgroundSyncService(
      apiService: locator<ApiService>(),
      notificationService: locator<NotificationService>(),
      totpManager: locator<TotpManagerService>(),
      encryptedStorage: locator<EncryptedStorageService>(),
      databaseService: locator<DatabaseService>(),
      connectivityService: locator<ConnectivityService>(),
    ),
  );

  // Register Admin Data Service
  locator.registerLazySingleton<AdminDataService>(
    () => AdminDataService(
      apiService: locator<ApiService>(),
      backendService: locator<BackendService>(),
    ),
  );
  
  // Register WebAuthn Service
  locator.registerLazySingleton<WebAuthnService>(
    () => WebAuthnService(
      apiService: locator<ApiService>(),
      backendService: locator<BackendService>(),
    ),
  );

  locator.registerLazySingleton<UserProfileService>(() => UserProfileService(locator<ApiService>()));
  locator.registerLazySingleton<SessionManagementService>(() => SessionManagementService(locator<ApiService>()));
  locator.registerLazySingleton<SecurityDataService>(() => SecurityDataService(locator<ApiService>()));
  // locator.registerLazySingleton<EnhancedBackupCodesService>(() => EnhancedBackupCodesService(locator<ApiService>()));
  // locator.registerLazySingleton<EmailService>(() => EmailService(locator<ApiService>()));
  
  // Register other services
  locator.registerLazySingleton<FileExportService>(() => FileExportService());
  // locator.registerLazySingleton<EnhancedQRScannerService>(() => EnhancedQRScannerService());
  // locator.registerLazySingleton<WebSocketService>(() => WebSocketService());
  locator.registerLazySingleton<EncryptionService>(() => EncryptionService());
  locator.registerLazySingleton<TotpOverlayService>(() => TotpOverlayService());
  locator.registerLazySingleton<CategoriesService>(() => CategoriesService());
  locator.registerLazySingleton<ConflictResolutionService>(() => ConflictResolutionService());
  locator.registerLazySingleton<RoleManagementService>(() => RoleManagementService());
  locator.registerLazySingleton<UserActivityService>(() => UserActivityService());
  locator.registerLazySingleton<SecuritySettingsService>(() => SecuritySettingsService());
  
  // Register Enhanced User Management Service
  locator.registerLazySingleton<EnhancedUserManagementService>(
    () => EnhancedUserManagementService(),
  );


  // Register SIEM Integration Service
  locator.registerLazySingleton<SIEMIntegrationService>(() => SIEMIntegrationService());

  // Register Risk-Based Auth Service
  locator.registerLazySingleton<RiskBasedAuthService>(() => RiskBasedAuthService());

  // Register Keyboard Shortcuts Service
  locator.registerLazySingleton<KeyboardShortcutsService>(() => KeyboardShortcutsService());

  // Register Smart Form Validation Service
  locator.registerLazySingleton<SmartFormValidationService>(() => SmartFormValidationService());

  // Register Captcha Service
  locator.registerLazySingleton<CaptchaService>(() => CaptchaService());

  // Register Privacy Dashboard Service
  locator.registerLazySingleton<PrivacyDashboardService>(() => PrivacyDashboardService());

  // Register Threat Intelligence Service
  locator.registerLazySingleton<ThreatIntelligenceService>(() => ThreatIntelligenceService());

  // Register Incident Response Service
  locator.registerLazySingleton<admin_incident.IncidentResponseService>(() => admin_incident.IncidentResponseService());

  // Register Real Time Monitoring Service
  locator.registerLazySingleton<RealTimeMonitoringService>(() => RealTimeMonitoringService());

  // Register admin services
  locator.registerLazySingleton<IPAccessControlService>(() => IPAccessControlService());
  locator.registerLazySingleton<core_incident.IncidentResponseService>(() => core_incident.IncidentResponseService());
  locator.registerLazySingleton<DeviceFingerprintingService>(() => DeviceFingerprintingService());
  locator.registerLazySingleton<RateLimitingService>(() => RateLimitingService());
  locator.registerLazySingleton<core_compliance.ComplianceReportingService>(() => core_compliance.ComplianceReportingService());
  locator.registerLazySingleton<SecurityPolicyService>(() => SecurityPolicyService());
  locator.registerLazySingleton<HealthMonitoringService>(() => HealthMonitoringService());
  
  // Register missing core services
  locator.registerLazySingleton<SecurityComplianceAutomationService>(() => SecurityComplianceAutomationService());
  locator.registerLazySingleton<MobileDeviceManagementService>(() => MobileDeviceManagementService());
  locator.registerLazySingleton<AdvancedForensicsService>(() => AdvancedForensicsService());
  
  // Register security services
  locator.registerLazySingleton<ThreatMonitoringService>(() => ThreatMonitoringService());
  
  // Admin Security Services
  locator.registerLazySingleton<UserBehaviorAnalyticsService>(
      () => UserBehaviorAnalyticsService());
  locator.registerLazySingleton<AuditTrailService>(() => AuditTrailService());
  locator.registerLazySingleton<VulnerabilityScanningService>(
      () => VulnerabilityScanningService());
  locator.registerLazySingleton<admin_compliance.ComplianceReportingService>(
      () => admin_compliance.ComplianceReportingService());
  // SecurityOrchestrationService - Registered as enhanced version below
  // PerformanceMonitoringService - Registered as enhanced version below
  locator.registerLazySingleton<EmergingThreatsService>(
      () => EmergingThreatsService());
  
  // Register Feature Flag Service
  locator.registerLazySingleton<FeatureFlagService>(() => FeatureFlagService());
  
  // Register Advanced Encryption Service
  locator.registerLazySingleton<AdvancedEncryptionService>(() => AdvancedEncryptionService());
  
  // Register Security Testing Service
  locator.registerLazySingleton<SecurityTestingService>(() => SecurityTestingService());
  
  // Register Device Security Service
  locator.registerLazySingleton<DeviceSecurityService>(() => DeviceSecurityService());
  
  // Register Offline Security Service
  locator.registerLazySingleton<OfflineSecurityService>(() => OfflineSecurityService());
  
  // Register Business Intelligence Service
  locator.registerLazySingleton<BusinessIntelligenceService>(() => BusinessIntelligenceService());
  
  // Register Threat Intelligence Platform
  locator.registerLazySingleton<ThreatIntelligencePlatform>(() => ThreatIntelligencePlatform());
  
  // Register Advanced Security Services
  locator.registerLazySingleton<RealTimeAnalyticsService>(() => RealTimeAnalyticsService());
  locator.registerLazySingleton<AutomatedIncidentResponseService>(() => AutomatedIncidentResponseService());
  locator.registerLazySingleton<HardwareMfaService>(() => HardwareMfaService());
  locator.registerLazySingleton<ZeroTrustNetworkService>(() => ZeroTrustNetworkService());
  locator.registerLazySingleton<QuantumResistantCryptoService>(() => QuantumResistantCryptoService());
  
  // Register Security Drills Service
  locator.registerLazySingleton<SecurityDrillsService>(() => SecurityDrillsService());
  
  // Register AI Security Copilot Service
  locator.registerLazySingleton<AISecurityCopilotService>(() => AISecurityCopilotService());
  
  // Register AI Assistant Service
  locator.registerLazySingleton<AIAssistantService>(() => AIAssistantService());
  
  // Register AI Engineering Expert Service
  locator.registerLazySingleton<AIEngineeringExpertService>(() => AIEngineeringExpertService());
  
  // Register Dashboard Customization Service
  locator.registerLazySingleton<DashboardCustomizationService>(() => DashboardCustomizationService());
  
  // Admin Zero Trust Service
  locator.registerLazySingleton<ZeroTrustService>(
    () => ZeroTrustService(),
  );
  
  // Admin Forensics Investigation Service
  locator.registerLazySingleton<ForensicsInvestigationService>(
    () => ForensicsInvestigationService(),
  );

  // Third-Party Integrations Service
  locator.registerLazySingleton(() => ThirdPartyIntegrationsService());
  
  // Security Orchestration Service - Use enhanced version with API support
  locator.registerLazySingleton<SecurityOrchestrationService>(
    () => EnhancedSecurityOrchestrationService(),
  );
  
  // Performance Monitoring Service - Use enhanced version with API support
  locator.registerLazySingleton<PerformanceMonitoringService>(
    () => EnhancedPerformanceMonitoringService(),
  );
  
  // Register Production Backend Services
  locator.registerLazySingleton<EnvironmentService>(() => EnvironmentService.instance);
  locator.registerLazySingleton<RealPhoneAuthService>(() => RealPhoneAuthService());
  locator.registerLazySingleton<ProductionDatabaseService>(() => ProductionDatabaseService());
  locator.registerLazySingleton<ProductionCryptoService>(() => ProductionCryptoService.instance);
  locator.registerLazySingleton<DatabaseMigrationService>(() => DatabaseMigrationService.instance);
  locator.registerLazySingleton<MigrationService>(() => MigrationService(
    locator<DatabaseService>(),
  ));
  locator.registerLazySingleton<BackendSyncService>(() => BackendSyncService(
    locator<DatabaseService>(),
  ));
  locator.registerLazySingleton<prod_backend.ProductionBackendService>(() => prod_backend.ProductionBackendService());
  
  // Register EmailSettingsService
  locator.registerLazySingleton<EmailSettingsService>(() => EmailSettingsService());
  
  // Register MfaSettingsService
  locator.registerLazySingleton<MfaSettingsService>(() => MfaSettingsService());
  
  // Register EnhancedBackupCodesService
  locator.registerLazySingleton<EnhancedBackupCodesService>(() => EnhancedBackupCodesService(locator<ApiService>()));
  
  // Register EmailService
  locator.registerLazySingleton<EmailService>(() => EmailService(locator<ApiService>()));
  
  // Register Language Service
  locator.registerLazySingleton<LanguageService>(() => LanguageService());
  
  // Register RBAC Service
  locator.registerLazySingleton<RBACService>(() => RBACService());
  
  // Register Enhanced RBAC Service
  locator.registerLazySingleton<EnhancedRBACService>(() => EnhancedRBACService());
  
  // Register AI-Powered Security Service
  locator.registerLazySingleton<AiPoweredSecurityService>(() => AiPoweredSecurityService());
  
  // Register Advanced Biometrics Service
  locator.registerLazySingleton<AdvancedBiometricsService>(() => AdvancedBiometricsService());
  
  // Register RBAC Audit Service
  locator.registerLazySingleton<RBACAuditService>(() => RBACAuditService());
}
