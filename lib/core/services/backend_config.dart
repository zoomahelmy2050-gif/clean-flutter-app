class BackendConfig {
  static const String _baseUrl = 'http://192.168.100.21:3000';
  static const String _wsUrl = 'ws://192.168.100.21:3000';
  
  // API Endpoints
  static const String authEndpoint = '/api/auth';
  static const String usersEndpoint = '/api/users';
  static const String securityEndpoint = '/api/security';
  static const String threatIntelEndpoint = '/api/threat-intel';
  static const String incidentsEndpoint = '/api/incidents';
  static const String complianceEndpoint = '/api/compliance';
  static const String analyticsEndpoint = '/api/analytics';
  static const String notificationsEndpoint = '/api/notifications';
  static const String siemEndpoint = '/api/siem';
  static const String privacyEndpoint = '/api/privacy';
  static const String captchaEndpoint = '/api/captcha';
  static const String validationEndpoint = '/api/validation';
  
  // WebSocket Endpoints
  static const String wsSecurityEvents = '/ws/security-events';
  static const String wsThreatFeed = '/ws/threat-feed';
  static const String wsNotifications = '/ws/notifications';
  static const String wsAnalytics = '/ws/analytics';
  static const String wsIncidents = '/ws/incidents';
  
  // Authentication
  static const String loginEndpoint = '$authEndpoint/login';
  static const String registerEndpoint = '$authEndpoint/register';
  static const String refreshTokenEndpoint = '$authEndpoint/refresh';
  static const String logoutEndpoint = '$authEndpoint/logout';
  static const String mfaEndpoint = '$authEndpoint/mfa';
  static const String biometricEndpoint = '$authEndpoint/biometric';
  static const String riskAssessmentEndpoint = '$authEndpoint/risk-assessment';
  
  // User Management
  static const String userProfileEndpoint = '$usersEndpoint/profile';
  static const String userRiskScoreEndpoint = '$usersEndpoint/risk-score';
  static const String userSessionsEndpoint = '$usersEndpoint/sessions';
  static const String userDevicesEndpoint = '$usersEndpoint/devices';
  static const String userBehaviorEndpoint = '$usersEndpoint/behavior';
  
  // Security Operations
  static const String securityDashboardEndpoint = '$securityEndpoint/dashboard';
  static const String threatMapEndpoint = '$securityEndpoint/threat-map';
  static const String securityScoreEndpoint = '$securityEndpoint/score';
  static const String alertsEndpoint = '$securityEndpoint/alerts';
  static const String vulnerabilitiesEndpoint = '$securityEndpoint/vulnerabilities';
  
  // Threat Intelligence
  static const String threatFeedsEndpoint = '$threatIntelEndpoint/feeds';
  static const String ipReputationEndpoint = '$threatIntelEndpoint/ip-reputation';
  static const String iocEndpoint = '$threatIntelEndpoint/ioc';
  static const String threatHuntingEndpoint = '$threatIntelEndpoint/hunting';
  
  // Incident Response
  static const String incidentListEndpoint = '$incidentsEndpoint/list';
  static const String incidentCreateEndpoint = '$incidentsEndpoint/create';
  static const String incidentUpdateEndpoint = '$incidentsEndpoint/update';
  static const String playbooksEndpoint = '$incidentsEndpoint/playbooks';
  static const String forensicsEndpoint = '$incidentsEndpoint/forensics';
  
  // Analytics
  static const String metricsEndpoint = '$analyticsEndpoint/metrics';
  static const String trendsEndpoint = '$analyticsEndpoint/trends';
  static const String predictionsEndpoint = '$analyticsEndpoint/predictions';
  static const String reportsEndpoint = '$analyticsEndpoint/reports';
  static const String correlationEndpoint = '$analyticsEndpoint/correlation';
  
  // SIEM Integration
  static const String siemConnectionsEndpoint = '$siemEndpoint/connections';
  static const String siemSyncEndpoint = '$siemEndpoint/sync';
  static const String siemQueriesEndpoint = '$siemEndpoint/queries';
  static const String siemAlertsEndpoint = '$siemEndpoint/alerts';
  
  // Privacy & Compliance
  static const String privacyDashboardEndpoint = '$privacyEndpoint/dashboard';
  static const String consentEndpoint = '$privacyEndpoint/consent';
  static const String dataExportEndpoint = '$privacyEndpoint/export';
  static const String dataDeletionEndpoint = '$privacyEndpoint/deletion';
  static const String complianceReportsEndpoint = '$complianceEndpoint/reports';
  
  // Form Validation & Captcha
  static const String breachCheckEndpoint = '$validationEndpoint/breach-check';
  static const String passwordStrengthEndpoint = '$validationEndpoint/password-strength';
  static const String captchaGenerateEndpoint = '$captchaEndpoint/generate';
  static const String captchaVerifyEndpoint = '$captchaEndpoint/verify';
  
  // Configuration
  static String get baseUrl => _baseUrl;
  static String get wsUrl => _wsUrl;
  
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Version': '1.0',
    'X-Client-Type': 'flutter-app',
  };
  
  static Duration get defaultTimeout => const Duration(seconds: 30);
  static Duration get uploadTimeout => const Duration(minutes: 5);
  static Duration get longOperationTimeout => const Duration(minutes: 2);
  
  // Rate limiting
  static const int maxRequestsPerMinute = 100;
  static const int maxConcurrentRequests = 10;
  
  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);
  
  // WebSocket configuration
  static const Duration wsReconnectDelay = Duration(seconds: 5);
  static const int wsMaxReconnectAttempts = 10;
  static const Duration wsPingInterval = Duration(seconds: 30);
}
