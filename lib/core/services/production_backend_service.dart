import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProductionBackendService {
  static const String _baseUrl =
      'https://e2ee-server-clean-production.up.railway.app/api';

  String? _authToken;
  String? _refreshToken;
  late final http.Client _client;
  bool _isConnected = false;

  ProductionBackendService() {
    _client = http.Client();
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _refreshToken = prefs.getString('refresh_token');

    // Test database connection
    await _testConnection();
  }

  Future<void> _testConnection() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/health'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        _isConnected = true;
        developer.log(
          'Database connection successful',
          name: 'ProductionBackendService',
        );
      } else {
        _isConnected = false;
        developer.log(
          'Database connection failed: ${response.statusCode}',
          name: 'ProductionBackendService',
        );
      }
    } catch (e) {
      _isConnected = false;
      developer.log(
        'Database connection error: $e',
        name: 'ProductionBackendService',
      );
    }
  }

  bool get isConnected => _isConnected;

  Future<Map<String, dynamic>> getConnectionStatus() async {
    await _testConnection();
    return {
      'connected': _isConnected,
      'serverUrl': _baseUrl,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // Authentication endpoints
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _authToken = data['accessToken'];
        _refreshToken = data['refreshToken'];
        await _saveTokens();
        return {'success': true, 'user': data['user']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      developer.log('Login error: $e', name: 'ProductionBackendService');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'fullName': fullName,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'user': data['user']};
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      developer.log('Registration error: $e', name: 'ProductionBackendService');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> sendOTP(String email) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'OTP sent successfully'};
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      developer.log('Send OTP error: $e', name: 'ProductionBackendService');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyOTP(String email, String otp) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['accessToken'] != null) {
          _authToken = data['accessToken'];
          _refreshToken = data['refreshToken'];
          await _saveTokens();
        }
        return {'success': true, 'verified': true};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Invalid OTP'};
      }
    } catch (e) {
      developer.log('Verify OTP error: $e', name: 'ProductionBackendService');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // User management endpoints
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/user/profile'),
        headers: _headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'user': data};
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to get profile',
        };
      }
    } catch (e) {
      developer.log('Get profile error: $e', name: 'ProductionBackendService');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await _client.put(
        Uri.parse('$_baseUrl/user/profile'),
        headers: _headers,
        body: jsonEncode(profileData),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'user': data};
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      developer.log(
        'Update profile error: $e',
        name: 'ProductionBackendService',
      );
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Security endpoints
  Future<Map<String, dynamic>> getSecurityEvents({
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final uri = Uri.parse(
        '$_baseUrl/security/events',
      ).replace(queryParameters: queryParams);
      final response = await _client.get(uri, headers: _headers);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'events': data['events'],
          'total': data['total'],
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to get security events',
        };
      }
    } catch (e) {
      developer.log(
        'Get security events error: $e',
        name: 'ProductionBackendService',
      );
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> reportSecurityEvent(
    Map<String, dynamic> eventData,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/security/events'),
        headers: _headers,
        body: jsonEncode(eventData),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'event': data};
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to report event',
        };
      }
    } catch (e) {
      developer.log(
        'Report security event error: $e',
        name: 'ProductionBackendService',
      );
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // TOTP endpoints
  Future<Map<String, dynamic>> generateTOTPSecret() async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/totp/generate'),
        headers: _headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'secret': data['secret'],
          'qrCode': data['qrCode'],
          'backupCodes': data['backupCodes'],
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to generate TOTP',
        };
      }
    } catch (e) {
      developer.log(
        'Generate TOTP error: $e',
        name: 'ProductionBackendService',
      );
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyTOTP(String code) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/totp/verify'),
        headers: _headers,
        body: jsonEncode({'code': code}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'verified': data['verified']};
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Invalid TOTP code',
        };
      }
    } catch (e) {
      developer.log('Verify TOTP error: $e', name: 'ProductionBackendService');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Backup codes endpoints
  Future<Map<String, dynamic>> generateBackupCodes() async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/backup-codes/generate'),
        headers: _headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'codes': data['codes']};
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to generate backup codes',
        };
      }
    } catch (e) {
      developer.log(
        'Generate backup codes error: $e',
        name: 'ProductionBackendService',
      );
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyBackupCode(String code) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/backup-codes/verify'),
        headers: _headers,
        body: jsonEncode({'code': code}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'verified': data['verified']};
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Invalid backup code',
        };
      }
    } catch (e) {
      developer.log(
        'Verify backup code error: $e',
        name: 'ProductionBackendService',
      );
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Token management
  Future<void> _saveTokens() async {
    final prefs = await SharedPreferences.getInstance();
    if (_authToken != null) {
      await prefs.setString('auth_token', _authToken!);
    }
    if (_refreshToken != null) {
      await prefs.setString('refresh_token', _refreshToken!);
    }
  }

  Future<bool> refreshAuthToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['accessToken'];
        await _saveTokens();
        return true;
      }
    } catch (e) {
      developer.log(
        'Token refresh error: $e',
        name: 'ProductionBackendService',
      );
    }

    return false;
  }

  Future<void> logout() async {
    try {
      await _client.post(
        Uri.parse('$_baseUrl/auth/logout'),
        headers: _headers,
        body: jsonEncode({'refreshToken': _refreshToken}),
      );
    } catch (e) {
      developer.log('Logout error: $e', name: 'ProductionBackendService');
    }

    _authToken = null;
    _refreshToken = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
  }

  void dispose() {
    _client.close();
  }
}
