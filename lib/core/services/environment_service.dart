import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnvironmentService extends ChangeNotifier {
  static EnvironmentService? _instance;
  static EnvironmentService get instance => _instance ??= EnvironmentService._();
  EnvironmentService._();

  bool _isInitialized = false;
  late SharedPreferences _prefs;

  // Backend Configuration
  String _backendUrl = 'http://192.168.100.21:3000';
  String _apiVersion = 'v1';
  
  // Authentication Configuration
  String _jwtSecret = 'your-jwt-secret-key';
  int _jwtExpirationHours = 24;
  
  // Database Configuration
  String _databaseUrl = 'postgresql://user:password@localhost:5432/security_app';
  
  // External API Keys
  String _twilioAccountSid = '';
  String _twilioAuthToken = '';
  String _twilioVerifyServiceSid = '';
  
  // Threat Intelligence APIs
  String _virusTotalApiKey = '';
  String _alienVaultApiKey = '';
  String _shodanApiKey = '';
  String _abuseIpDbApiKey = '';
  
  // Cloud Storage
  String _awsAccessKeyId = '';
  String _awsSecretAccessKey = '';
  String _awsRegion = 'us-east-1';
  String _awsS3Bucket = '';
  
  // Firebase Configuration
  String _firebaseProjectId = '';
  String _firebaseApiKey = '';
  String _firebaseMessagingSenderId = '';
  
  // Email Service
  String _sendGridApiKey = '';
  String _fromEmail = 'noreply@securityapp.com';
  
  // Push Notifications
  String _fcmServerKey = '';
  
  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    await _loadConfiguration();
    
    _isInitialized = true;
    developer.log('Environment service initialized');
  }

  Future<void> _loadConfiguration() async {
    try {
      // Load backend configuration
      _backendUrl = _prefs.getString('backend_url') ?? _backendUrl;
      _apiVersion = _prefs.getString('api_version') ?? _apiVersion;
      
      // Load authentication configuration
      _jwtSecret = _prefs.getString('jwt_secret') ?? _jwtSecret;
      _jwtExpirationHours = _prefs.getInt('jwt_expiration_hours') ?? _jwtExpirationHours;
      
      // Load database configuration
      _databaseUrl = _prefs.getString('database_url') ?? _databaseUrl;
      
      // Load Twilio configuration
      _twilioAccountSid = _prefs.getString('twilio_account_sid') ?? '';
      _twilioAuthToken = _prefs.getString('twilio_auth_token') ?? '';
      _twilioVerifyServiceSid = _prefs.getString('twilio_verify_service_sid') ?? '';
      
      // Load threat intelligence API keys
      _virusTotalApiKey = _prefs.getString('virustotal_api_key') ?? '';
      _alienVaultApiKey = _prefs.getString('alienvault_api_key') ?? '';
      _shodanApiKey = _prefs.getString('shodan_api_key') ?? '';
      _abuseIpDbApiKey = _prefs.getString('abuseipdb_api_key') ?? '';
      
      // Load AWS configuration
      _awsAccessKeyId = _prefs.getString('aws_access_key_id') ?? '';
      _awsSecretAccessKey = _prefs.getString('aws_secret_access_key') ?? '';
      _awsRegion = _prefs.getString('aws_region') ?? _awsRegion;
      _awsS3Bucket = _prefs.getString('aws_s3_bucket') ?? '';
      
      // Load Firebase configuration
      _firebaseProjectId = _prefs.getString('firebase_project_id') ?? '';
      _firebaseApiKey = _prefs.getString('firebase_api_key') ?? '';
      _firebaseMessagingSenderId = _prefs.getString('firebase_messaging_sender_id') ?? '';
      
      // Load email service configuration
      _sendGridApiKey = _prefs.getString('sendgrid_api_key') ?? '';
      _fromEmail = _prefs.getString('from_email') ?? _fromEmail;
      
      // Load push notification configuration
      _fcmServerKey = _prefs.getString('fcm_server_key') ?? '';
      
      developer.log('Configuration loaded successfully');
    } catch (e) {
      developer.log('Error loading configuration: $e');
    }
  }

  // Backend Configuration Getters
  String get backendUrl => _backendUrl;
  String get apiVersion => _apiVersion;
  String get fullBackendUrl => '$_backendUrl/api/$_apiVersion';
  
  // Authentication Configuration Getters
  String get jwtSecret => _jwtSecret;
  int get jwtExpirationHours => _jwtExpirationHours;
  
  // Database Configuration Getters
  String get databaseUrl => _databaseUrl;
  
  // Twilio Configuration Getters
  String get twilioAccountSid => _twilioAccountSid;
  String get twilioAuthToken => _twilioAuthToken;
  String get twilioVerifyServiceSid => _twilioVerifyServiceSid;
  bool get isTwilioConfigured => _twilioAccountSid.isNotEmpty && _twilioAuthToken.isNotEmpty;
  
  // Threat Intelligence API Getters
  String get virusTotalApiKey => _virusTotalApiKey;
  String get alienVaultApiKey => _alienVaultApiKey;
  String get shodanApiKey => _shodanApiKey;
  String get abuseIpDbApiKey => _abuseIpDbApiKey;
  
  // AWS Configuration Getters
  String get awsAccessKeyId => _awsAccessKeyId;
  String get awsSecretAccessKey => _awsSecretAccessKey;
  String get awsRegion => _awsRegion;
  String get awsS3Bucket => _awsS3Bucket;
  bool get isAwsConfigured => _awsAccessKeyId.isNotEmpty && _awsSecretAccessKey.isNotEmpty;
  
  // Firebase Configuration Getters
  String get firebaseProjectId => _firebaseProjectId;
  String get firebaseApiKey => _firebaseApiKey;
  String get firebaseMessagingSenderId => _firebaseMessagingSenderId;
  bool get isFirebaseConfigured => _firebaseProjectId.isNotEmpty && _firebaseApiKey.isNotEmpty;
  
  // Email Service Configuration Getters
  String get sendGridApiKey => _sendGridApiKey;
  String get fromEmail => _fromEmail;
  bool get isEmailConfigured => _sendGridApiKey.isNotEmpty;
  
  // Push Notification Configuration Getters
  String get fcmServerKey => _fcmServerKey;
  bool get isPushNotificationConfigured => _fcmServerKey.isNotEmpty;

  // Configuration Setters
  Future<void> setBackendConfiguration({
    required String url,
    String? apiVersion,
  }) async {
    _backendUrl = url;
    if (apiVersion != null) _apiVersion = apiVersion;
    
    await _prefs.setString('backend_url', _backendUrl);
    await _prefs.setString('api_version', _apiVersion);
    
    notifyListeners();
    developer.log('Backend configuration updated');
  }

  Future<void> setTwilioConfiguration({
    required String accountSid,
    required String authToken,
    required String verifyServiceSid,
  }) async {
    _twilioAccountSid = accountSid;
    _twilioAuthToken = authToken;
    _twilioVerifyServiceSid = verifyServiceSid;
    
    await _prefs.setString('twilio_account_sid', _twilioAccountSid);
    await _prefs.setString('twilio_auth_token', _twilioAuthToken);
    await _prefs.setString('twilio_verify_service_sid', _twilioVerifyServiceSid);
    
    notifyListeners();
    developer.log('Twilio configuration updated');
  }

  Future<void> setThreatIntelligenceApiKeys({
    String? virusTotalKey,
    String? alienVaultKey,
    String? shodanKey,
    String? abuseIpDbKey,
  }) async {
    if (virusTotalKey != null) {
      _virusTotalApiKey = virusTotalKey;
      await _prefs.setString('virustotal_api_key', _virusTotalApiKey);
    }
    
    if (alienVaultKey != null) {
      _alienVaultApiKey = alienVaultKey;
      await _prefs.setString('alienvault_api_key', _alienVaultApiKey);
    }
    
    if (shodanKey != null) {
      _shodanApiKey = shodanKey;
      await _prefs.setString('shodan_api_key', _shodanApiKey);
    }
    
    if (abuseIpDbKey != null) {
      _abuseIpDbApiKey = abuseIpDbKey;
      await _prefs.setString('abuseipdb_api_key', _abuseIpDbApiKey);
    }
    
    notifyListeners();
    developer.log('Threat intelligence API keys updated');
  }

  Future<void> setAwsConfiguration({
    required String accessKeyId,
    required String secretAccessKey,
    String? region,
    String? s3Bucket,
  }) async {
    _awsAccessKeyId = accessKeyId;
    _awsSecretAccessKey = secretAccessKey;
    if (region != null) _awsRegion = region;
    if (s3Bucket != null) _awsS3Bucket = s3Bucket;
    
    await _prefs.setString('aws_access_key_id', _awsAccessKeyId);
    await _prefs.setString('aws_secret_access_key', _awsSecretAccessKey);
    await _prefs.setString('aws_region', _awsRegion);
    if (s3Bucket != null) await _prefs.setString('aws_s3_bucket', _awsS3Bucket);
    
    notifyListeners();
    developer.log('AWS configuration updated');
  }

  Future<void> setFirebaseConfiguration({
    required String projectId,
    required String apiKey,
    required String messagingSenderId,
  }) async {
    _firebaseProjectId = projectId;
    _firebaseApiKey = apiKey;
    _firebaseMessagingSenderId = messagingSenderId;
    
    await _prefs.setString('firebase_project_id', _firebaseProjectId);
    await _prefs.setString('firebase_api_key', _firebaseApiKey);
    await _prefs.setString('firebase_messaging_sender_id', _firebaseMessagingSenderId);
    
    notifyListeners();
    developer.log('Firebase configuration updated');
  }

  Future<void> setEmailConfiguration({
    required String sendGridApiKey,
    String? fromEmail,
  }) async {
    _sendGridApiKey = sendGridApiKey;
    if (fromEmail != null) _fromEmail = fromEmail;
    
    await _prefs.setString('sendgrid_api_key', _sendGridApiKey);
    await _prefs.setString('from_email', _fromEmail);
    
    notifyListeners();
    developer.log('Email configuration updated');
  }

  Future<void> setPushNotificationConfiguration({
    required String fcmServerKey,
  }) async {
    _fcmServerKey = fcmServerKey;
    
    await _prefs.setString('fcm_server_key', _fcmServerKey);
    
    notifyListeners();
    developer.log('Push notification configuration updated');
  }

  // Validation Methods
  bool get isBackendConfigured => _backendUrl.isNotEmpty;
  
  bool get areExternalApisConfigured {
    return _virusTotalApiKey.isNotEmpty ||
           _alienVaultApiKey.isNotEmpty ||
           _shodanApiKey.isNotEmpty ||
           _abuseIpDbApiKey.isNotEmpty;
  }

  Map<String, bool> get configurationStatus {
    return {
      'backend': isBackendConfigured,
      'twilio': isTwilioConfigured,
      'aws': isAwsConfigured,
      'firebase': isFirebaseConfigured,
      'email': isEmailConfigured,
      'push_notifications': isPushNotificationConfigured,
      'threat_intelligence': areExternalApisConfigured,
    };
  }

  // Clear Configuration
  Future<void> clearAllConfiguration() async {
    await _prefs.clear();
    await _loadConfiguration();
    notifyListeners();
    developer.log('All configuration cleared');
  }

  bool get isInitialized => _isInitialized;
}
