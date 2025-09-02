import 'dart:async';
import 'dart:convert';
import 'api_client.dart';
import '../utils/error_handler.dart';
import 'dart:developer' as developer;

class AdvancedSecurityApiService {
  static final AdvancedSecurityApiService _instance = AdvancedSecurityApiService._internal();
  factory AdvancedSecurityApiService() => _instance;
  AdvancedSecurityApiService._internal();

  final ApiClient _apiClient = ApiClient();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize API client with backend URL
      _apiClient.initialize(
        baseUrl: 'http://192.168.100.21:3000',
        defaultHeaders: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      _isInitialized = true;
      developer.log('Advanced Security API Service initialized', name: 'AdvancedSecurityApiService');
    } catch (e) {
      developer.log('Failed to initialize Advanced Security API Service: $e', name: 'AdvancedSecurityApiService');
      throw ServiceUnavailableException('Failed to initialize API service', originalError: e);
    }
  }

  // AI-Powered Security Service API
  Future<Map<String, dynamic>> getAiSecurityMetrics() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/api/security/ai/metrics');
      if (response.success) {
        return response.data ?? {};
      }
      throw NetworkException('Failed to fetch AI security metrics: ${response.error}');
    } catch (e) {
      developer.log('Error fetching AI security metrics: $e', name: 'AdvancedSecurityApiService');
      return _getMockAiSecurityMetrics();
    }
  }

  Future<List<Map<String, dynamic>>> getAiThreatDetections() async {
    try {
      final response = await _apiClient.get<List<dynamic>>('/api/security/ai/threats');
      if (response.success) {
        return List<Map<String, dynamic>>.from(response.data ?? []);
      }
      throw NetworkException('Failed to fetch AI threat detections: ${response.error}');
    } catch (e) {
      developer.log('Error fetching AI threat detections: $e', name: 'AdvancedSecurityApiService');
      return [];
    }
  }

  Future<Map<String, dynamic>> runAiSecurityAnalysis(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>('/api/security/ai/analyze', body: data);
      if (response.success) {
        return response.data ?? {};
      }
      throw NetworkException('Failed to run AI security analysis: ${response.error}');
    } catch (e) {
      developer.log('Error running AI security analysis: $e', name: 'AdvancedSecurityApiService');
      throw NetworkException('AI security analysis failed', originalError: e);
    }
  }

  // Advanced Biometrics Service API
  Future<Map<String, dynamic>> getBiometricMetrics() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/api/security/biometrics/metrics');
      if (response.success) {
        return response.data ?? {};
      }
      throw NetworkException('Failed to fetch biometric metrics: ${response.error}');
    } catch (e) {
      developer.log('Error fetching biometric metrics: $e', name: 'AdvancedSecurityApiService');
      return _getMockBiometricMetrics();
    }
  }

  Future<bool> enrollBiometric(String userId, String biometricType, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>('/api/security/biometrics/enroll', body: {
        'userId': userId,
        'type': biometricType,
        'data': data,
      });
      return response.success;
    } catch (e) {
      developer.log('Error enrolling biometric: $e', name: 'AdvancedSecurityApiService');
      throw NetworkException('Biometric enrollment failed', originalError: e);
    }
  }

  Future<bool> verifyBiometric(String userId, String biometricType, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>('/api/security/biometrics/verify', body: {
        'userId': userId,
        'type': biometricType,
        'data': data,
      });
      return response.success && (response.data?['verified'] == true);
    } catch (e) {
      developer.log('Error verifying biometric: $e', name: 'AdvancedSecurityApiService');
      return false;
    }
  }

  // Feature Flag Service API
  Future<Map<String, dynamic>> getFeatureFlags(String userId, String tenantId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/api/security/feature-flags', queryParams: {
        'userId': userId,
        'tenantId': tenantId,
      });
      if (response.success) {
        return response.data ?? {};
      }
      throw NetworkException('Failed to fetch feature flags: ${response.error}');
    } catch (e) {
      developer.log('Error fetching feature flags: $e', name: 'AdvancedSecurityApiService');
      return _getMockFeatureFlags();
    }
  }

  Future<bool> updateFeatureFlag(String flagKey, bool enabled, Map<String, dynamic> config) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>('/api/security/feature-flags/$flagKey', body: {
        'enabled': enabled,
        'config': config,
      });
      return response.success;
    } catch (e) {
      developer.log('Error updating feature flag: $e', name: 'AdvancedSecurityApiService');
      throw NetworkException('Feature flag update failed', originalError: e);
    }
  }

  // Advanced Encryption Service API
  Future<Map<String, dynamic>> getEncryptionMetrics() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/api/security/encryption/metrics');
      if (response.success) {
        return response.data ?? {};
      }
      throw NetworkException('Failed to fetch encryption metrics: ${response.error}');
    } catch (e) {
      developer.log('Error fetching encryption metrics: $e', name: 'AdvancedSecurityApiService');
      return _getMockEncryptionMetrics();
    }
  }

  Future<String> generateEncryptionKey(String algorithm, int keySize) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>('/api/security/encryption/generate-key', body: {
        'algorithm': algorithm,
        'keySize': keySize,
      });
      if (response.success) {
        return response.data?['key'] ?? '';
      }
      throw NetworkException('Failed to generate encryption key: ${response.error}');
    } catch (e) {
      developer.log('Error generating encryption key: $e', name: 'AdvancedSecurityApiService');
      throw NetworkException('Key generation failed', originalError: e);
    }
  }

  Future<String> encryptData(String data, String keyId, String algorithm) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>('/api/security/encryption/encrypt', body: {
        'data': data,
        'keyId': keyId,
        'algorithm': algorithm,
      });
      if (response.success) {
        return response.data?['encryptedData'] ?? '';
      }
      throw NetworkException('Failed to encrypt data: ${response.error}');
    } catch (e) {
      developer.log('Error encrypting data: $e', name: 'AdvancedSecurityApiService');
      throw NetworkException('Data encryption failed', originalError: e);
    }
  }

  // Security Testing Service API
  Future<Map<String, dynamic>> getSecurityTestResults() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/api/security/testing/results');
      if (response.success) {
        return response.data ?? {};
      }
      throw NetworkException('Failed to fetch security test results: ${response.error}');
    } catch (e) {
      developer.log('Error fetching security test results: $e', name: 'AdvancedSecurityApiService');
      return _getMockSecurityTestResults();
    }
  }

  Future<String> startSecurityTest(String testType, Map<String, dynamic> config) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>('/api/security/testing/start', body: {
        'testType': testType,
        'config': config,
      });
      if (response.success) {
        return response.data?['testId'] ?? '';
      }
      throw NetworkException('Failed to start security test: ${response.error}');
    } catch (e) {
      developer.log('Error starting security test: $e', name: 'AdvancedSecurityApiService');
      throw NetworkException('Security test start failed', originalError: e);
    }
  }

  // Device Security Service API
  Future<Map<String, dynamic>> getDeviceSecurityStatus(String deviceId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/api/security/device/$deviceId/status');
      if (response.success) {
        return response.data ?? {};
      }
      throw NetworkException('Failed to fetch device security status: ${response.error}');
    } catch (e) {
      developer.log('Error fetching device security status: $e', name: 'AdvancedSecurityApiService');
      return _getMockDeviceSecurityStatus();
    }
  }

  Future<bool> reportDeviceThreat(String deviceId, Map<String, dynamic> threatData) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>('/api/security/device/$deviceId/threat', body: threatData);
      return response.success;
    } catch (e) {
      developer.log('Error reporting device threat: $e', name: 'AdvancedSecurityApiService');
      throw NetworkException('Device threat reporting failed', originalError: e);
    }
  }

  // Business Intelligence Service API
  Future<Map<String, dynamic>> getBusinessIntelligenceMetrics() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/api/security/business-intelligence/metrics');
      if (response.success) {
        return response.data ?? {};
      }
      throw NetworkException('Failed to fetch BI metrics: ${response.error}');
    } catch (e) {
      developer.log('Error fetching BI metrics: $e', name: 'AdvancedSecurityApiService');
      return _getMockBusinessIntelligenceMetrics();
    }
  }

  Future<Map<String, dynamic>> generateSecurityReport(String reportType, Map<String, dynamic> params) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>('/api/security/business-intelligence/report', body: {
        'reportType': reportType,
        'parameters': params,
      });
      if (response.success) {
        return response.data ?? {};
      }
      throw NetworkException('Failed to generate security report: ${response.error}');
    } catch (e) {
      developer.log('Error generating security report: $e', name: 'AdvancedSecurityApiService');
      throw NetworkException('Report generation failed', originalError: e);
    }
  }

  // Threat Intelligence Platform API
  Future<Map<String, dynamic>> getThreatIntelligence() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/api/security/threat-intelligence');
      if (response.success) {
        return response.data ?? {};
      }
      throw NetworkException('Failed to fetch threat intelligence: ${response.error}');
    } catch (e) {
      developer.log('Error fetching threat intelligence: $e', name: 'AdvancedSecurityApiService');
      return _getMockThreatIntelligence();
    }
  }

  Future<List<Map<String, dynamic>>> searchThreatActors(String query) async {
    try {
      final response = await _apiClient.get<List<dynamic>>('/api/security/threat-intelligence/actors', queryParams: {
        'query': query,
      });
      if (response.success) {
        return List<Map<String, dynamic>>.from(response.data ?? []);
      }
      throw NetworkException('Failed to search threat actors: ${response.error}');
    } catch (e) {
      developer.log('Error searching threat actors: $e', name: 'AdvancedSecurityApiService');
      return [];
    }
  }

  // WebSocket connections for real-time updates
  Stream<Map<String, dynamic>> getSecurityUpdatesStream() {
    try {
      return _apiClient.connectWebSocket<Map<String, dynamic>>(
        '/api/security/updates',
        parser: (data) => jsonDecode(data) as Map<String, dynamic>,
      );
    } catch (e) {
      developer.log('Error connecting to security updates stream: $e', name: 'AdvancedSecurityApiService');
      return Stream.empty();
    }
  }

  Stream<Map<String, dynamic>> getThreatFeedStream() {
    try {
      return _apiClient.connectWebSocket<Map<String, dynamic>>(
        '/api/security/threat-feed',
        parser: (data) => jsonDecode(data) as Map<String, dynamic>,
      );
    } catch (e) {
      developer.log('Error connecting to threat feed stream: $e', name: 'AdvancedSecurityApiService');
      return Stream.empty();
    }
  }

  // Health check
  Future<bool> healthCheck() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/api/health');
      return response.success;
    } catch (e) {
      developer.log('Health check failed: $e', name: 'AdvancedSecurityApiService');
      return false;
    }
  }

  // Mock data methods for fallback when API is unavailable
  Map<String, dynamic> _getMockAiSecurityMetrics() {
    return {
      'total_threats_detected': 127,
      'threats_blocked': 119,
      'false_positives': 8,
      'accuracy_rate': 0.937,
      'model_version': '2.1.3',
      'last_training': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'active_models': 3,
      'processing_time_avg': 45.2,
    };
  }

  Map<String, dynamic> _getMockBiometricMetrics() {
    return {
      'enrolled_users': 1247,
      'active_biometric_methods': 4,
      'verification_success_rate': 0.982,
      'false_acceptance_rate': 0.001,
      'false_rejection_rate': 0.017,
      'average_verification_time': 1.2,
      'supported_modalities': ['fingerprint', 'face', 'voice', 'iris'],
    };
  }

  Map<String, dynamic> _getMockFeatureFlags() {
    return {
      'advanced_mfa': true,
      'biometric_login': true,
      'threat_detection': true,
      'auto_lockout': false,
      'dark_web_monitoring': true,
      'behavioral_analysis': true,
      'quantum_encryption': false,
    };
  }

  Map<String, dynamic> _getMockEncryptionMetrics() {
    return {
      'active_keys': 156,
      'encryption_operations': 45231,
      'decryption_operations': 44987,
      'key_rotations': 23,
      'algorithms_supported': 8,
      'quantum_resistant_keys': 12,
      'average_encryption_time': 2.3,
      'key_strength_distribution': {
        'AES-256': 89,
        'RSA-4096': 34,
        'ChaCha20': 21,
        'Kyber-1024': 12,
      },
    };
  }

  Map<String, dynamic> _getMockSecurityTestResults() {
    return {
      'completed_tests': 89,
      'passed_tests': 76,
      'failed_tests': 13,
      'critical_vulnerabilities': 2,
      'high_vulnerabilities': 5,
      'medium_vulnerabilities': 11,
      'low_vulnerabilities': 18,
      'last_test_run': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
      'overall_security_score': 8.2,
    };
  }

  Map<String, dynamic> _getMockDeviceSecurityStatus() {
    return {
      'device_trusted': true,
      'jailbreak_detected': false,
      'emulator_detected': false,
      'debugger_detected': false,
      'hooking_detected': false,
      'security_score': 9.1,
      'last_check': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
      'threats_detected': 0,
      'security_features_active': 12,
    };
  }

  Map<String, dynamic> _getMockBusinessIntelligenceMetrics() {
    return {
      'total_security_investment': 2450000,
      'security_roi': 3.2,
      'cost_per_incident': 15000,
      'incidents_prevented': 47,
      'cost_savings': 705000,
      'net_roi_percentage': 28.8,
      'payback_period_months': 8.5,
      'risk_reduction_percentage': 67.3,
    };
  }

  Map<String, dynamic> _getMockThreatIntelligence() {
    return {
      'active_threats': 234,
      'new_threats_today': 12,
      'threat_actors_tracked': 89,
      'iocs_collected': 15672,
      'dark_web_mentions': 23,
      'collection_sources': 47,
      'threat_level': 'Medium',
      'last_update': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
    };
  }

  void dispose() {
    _apiClient.closeAllWebSockets();
  }
}
