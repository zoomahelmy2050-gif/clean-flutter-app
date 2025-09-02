import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'api_client.dart';
import 'backend_config.dart';
import '../models/risk_based_auth_models.dart';

class BackendAuthService {
  static final BackendAuthService _instance = BackendAuthService._internal();
  factory BackendAuthService() => _instance;
  BackendAuthService._internal();

  final ApiClient _apiClient = ApiClient();
  String? _currentToken;
  String? _refreshToken;
  Timer? _tokenRefreshTimer;

  Future<void> initialize() async {
    _apiClient.initialize(
      baseUrl: BackendConfig.baseUrl,
      defaultHeaders: BackendConfig.defaultHeaders,
    );
    
    developer.log('Backend Auth Service initialized', name: 'BackendAuthService');
  }

  Future<ApiResponse<Map<String, dynamic>>> login(String email, String password) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        BackendConfig.loginEndpoint,
        body: {
          'email': email,
          'password': password,
          'deviceInfo': await _getDeviceInfo(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        _currentToken = data['accessToken'];
        _refreshToken = data['refreshToken'];
        
        if (_currentToken != null) {
          _apiClient.setAuthToken(_currentToken!);
          _scheduleTokenRefresh(data['expiresIn'] ?? 3600);
        }
      }

      return response;
    } catch (e) {
      developer.log('Login failed: $e', name: 'BackendAuthService');
      return ApiResponse.error('Login failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> register(String email, String password, {
    String? name,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        BackendConfig.registerEndpoint,
        body: {
          'email': email,
          'password': password,
          'name': name,
          'deviceInfo': await _getDeviceInfo(),
          'timestamp': DateTime.now().toIso8601String(),
          ...?additionalData,
        },
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        _currentToken = data['accessToken'];
        _refreshToken = data['refreshToken'];
        
        if (_currentToken != null) {
          _apiClient.setAuthToken(_currentToken!);
          _scheduleTokenRefresh(data['expiresIn'] ?? 3600);
        }
      }

      return response;
    } catch (e) {
      developer.log('Registration failed: $e', name: 'BackendAuthService');
      return ApiResponse.error('Registration failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> verifyMFA(String code, String method) async {
    try {
      return await _apiClient.post<Map<String, dynamic>>(
        BackendConfig.mfaEndpoint,
        body: {
          'code': code,
          'method': method,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      developer.log('MFA verification failed: $e', name: 'BackendAuthService');
      return ApiResponse.error('MFA verification failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> authenticateBiometric(String biometricData) async {
    try {
      return await _apiClient.post<Map<String, dynamic>>(
        BackendConfig.biometricEndpoint,
        body: {
          'biometricData': biometricData,
          'deviceInfo': await _getDeviceInfo(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      developer.log('Biometric authentication failed: $e', name: 'BackendAuthService');
      return ApiResponse.error('Biometric authentication failed: $e');
    }
  }

  Future<ApiResponse<RiskAssessment>> getRiskAssessment(String userId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${BackendConfig.riskAssessmentEndpoint}/$userId',
      );

      if (response.success && response.data != null) {
        final riskAssessment = RiskAssessment.fromJson(response.data!);
        return ApiResponse.success(riskAssessment);
      }

      return ApiResponse.error(response.error ?? 'Failed to get risk assessment');
    } catch (e) {
      developer.log('Risk assessment failed: $e', name: 'BackendAuthService');
      return ApiResponse.error('Risk assessment failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updateRiskFactors(String userId, List<RiskFactor> factors) async {
    try {
      return await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.riskAssessmentEndpoint}/$userId/factors',
        body: {
          'factors': factors.map((f) => f.toJson()).toList(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      developer.log('Risk factors update failed: $e', name: 'BackendAuthService');
      return ApiResponse.error('Risk factors update failed: $e');
    }
  }

  Future<ApiResponse<List<TrustedDevice>>> getTrustedDevices(String userId) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${BackendConfig.userDevicesEndpoint}/$userId',
      );

      if (response.success && response.data != null) {
        final devices = response.data!.map((d) => TrustedDevice.fromJson(d)).toList();
        return ApiResponse.success(devices);
      }

      return ApiResponse.error(response.error ?? 'Failed to get trusted devices');
    } catch (e) {
      developer.log('Get trusted devices failed: $e', name: 'BackendAuthService');
      return ApiResponse.error('Get trusted devices failed: $e');
    }
  }

  Future<ApiResponse<TrustedDevice>> registerDevice(String userId, Map<String, dynamic> deviceInfo) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.userDevicesEndpoint}/$userId',
        body: {
          'deviceInfo': deviceInfo,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.success && response.data != null) {
        final device = TrustedDevice.fromJson(response.data!);
        return ApiResponse.success(device);
      }

      return ApiResponse.error(response.error ?? 'Failed to register device');
    } catch (e) {
      developer.log('Device registration failed: $e', name: 'BackendAuthService');
      return ApiResponse.error('Device registration failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> recordBehavioralData(String userId, BehavioralBiometrics data) async {
    try {
      return await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.userBehaviorEndpoint}/$userId',
        body: {
          'behavioralData': data.toJson(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      developer.log('Behavioral data recording failed: $e', name: 'BackendAuthService');
      return ApiResponse.error('Behavioral data recording failed: $e');
    }
  }

  Future<ApiResponse<GeolocationData>> verifyLocation(String userId, double latitude, double longitude) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.riskAssessmentEndpoint}/$userId/location',
        body: {
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.success && response.data != null) {
        final locationData = GeolocationData.fromJson(response.data!);
        return ApiResponse.success(locationData);
      }

      return ApiResponse.error(response.error ?? 'Location verification failed');
    } catch (e) {
      developer.log('Location verification failed: $e', name: 'BackendAuthService');
      return ApiResponse.error('Location verification failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> refreshToken() async {
    if (_refreshToken == null) {
      return ApiResponse.error('No refresh token available');
    }

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        BackendConfig.refreshTokenEndpoint,
        body: {
          'refreshToken': _refreshToken,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        _currentToken = data['accessToken'];
        _refreshToken = data['refreshToken'];
        
        if (_currentToken != null) {
          _apiClient.setAuthToken(_currentToken!);
          _scheduleTokenRefresh(data['expiresIn'] ?? 3600);
        }
      }

      return response;
    } catch (e) {
      developer.log('Token refresh failed: $e', name: 'BackendAuthService');
      return ApiResponse.error('Token refresh failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> logout() async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        BackendConfig.logoutEndpoint,
        body: {
          'refreshToken': _refreshToken,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      _clearTokens();
      return response;
    } catch (e) {
      developer.log('Logout failed: $e', name: 'BackendAuthService');
      _clearTokens();
      return ApiResponse.error('Logout failed: $e');
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getUserSessions(String userId) async {
    try {
      return await _apiClient.get<List<Map<String, dynamic>>>(
        '${BackendConfig.userSessionsEndpoint}/$userId',
      );
    } catch (e) {
      developer.log('Get user sessions failed: $e', name: 'BackendAuthService');
      return ApiResponse.error('Get user sessions failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> terminateSession(String sessionId) async {
    try {
      return await _apiClient.delete<Map<String, dynamic>>(
        '${BackendConfig.userSessionsEndpoint}/$sessionId',
      );
    } catch (e) {
      developer.log('Terminate session failed: $e', name: 'BackendAuthService');
      return ApiResponse.error('Terminate session failed: $e');
    }
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    // This would collect actual device information in a real implementation
    return {
      'platform': 'flutter',
      'deviceId': 'device_${DateTime.now().millisecondsSinceEpoch}',
      'userAgent': 'Flutter App 1.0.0',
      'screenResolution': '1920x1080',
      'timezone': DateTime.now().timeZoneName,
      'language': 'en',
    };
  }

  void _scheduleTokenRefresh(int expiresInSeconds) {
    _tokenRefreshTimer?.cancel();
    
    // Refresh token 5 minutes before expiry
    final refreshDelay = Duration(seconds: expiresInSeconds - 300);
    
    _tokenRefreshTimer = Timer(refreshDelay, () async {
      final result = await refreshToken();
      if (!result.success) {
        developer.log('Automatic token refresh failed', name: 'BackendAuthService');
        _clearTokens();
      }
    });
  }

  void _clearTokens() {
    _currentToken = null;
    _refreshToken = null;
    _tokenRefreshTimer?.cancel();
    _apiClient.clearAuthToken();
  }

  bool get isAuthenticated => _currentToken != null;
  String? get currentToken => _currentToken;

  void dispose() {
    _tokenRefreshTimer?.cancel();
    _apiClient.dispose();
  }
}
