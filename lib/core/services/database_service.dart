import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:developer' as developer;

class DatabaseService {
  final String baseUrl;
  final bool useMockMode;
  String? _authToken;

  DatabaseService({required this.baseUrl, required this.useMockMode});

  // Getter for auth token
  String? get authToken => _authToken;

  // Initialize and get auth token
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  // Save auth token
  Future<void> saveAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Clear auth token
  Future<void> clearAuthToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Close database
  Future<void> close() async {
    // await _database?.close();
    // _database = null;
  }

  // Sync helper methods
  Future<List<Map<String, dynamic>>> getAllDevices() async {
    // Return mock data for now
    return [];
  }

  Future<Map<String, dynamic>?> getDevice(String deviceId) async {
    // Return mock data for now
    return null;
  }

  Future<List<Map<String, dynamic>>> getUnsyncedSecurityLogs() async {
    // Return mock data for now
    return [];
  }

  Future<List<Map<String, dynamic>>> getUnsyncedBlobs() async {
    // Return mock data for now
    return [];
  }

  Future<Map<String, dynamic>?> getBlob(String blobId) async {
    // Return mock data for now
    return null;
  }

  Future<void> markAsSynced(String table, String id) async {
    // Mock implementation for now
  }

  // Get headers with auth token
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // User Authentication
  Future<Map<String, dynamic>> register(String email, String password) async {
    if (useMockMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        'success': true,
        'data': {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'email': email,
          'token': 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}'
        }
      };
    }
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['message'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    if (useMockMode) {
      await Future.delayed(const Duration(milliseconds: 400));
      final token = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
      await saveAuthToken(token);
      return {
        'success': true,
        'data': {
          'id': '1',
          'email': email,
          'token': token,
          'role': 'admin'
        }
      };
    }
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveAuthToken(data['token']);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['message'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // User Management
  Future<Map<String, dynamic>> getAllUsers() async {
    if (useMockMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      return {
        'success': true,
        'data': [
          {'id': '1', 'email': 'admin@example.com', 'role': 'admin', 'status': 'active'},
          {'id': '2', 'email': 'user1@example.com', 'role': 'user', 'status': 'active'},
          {'id': '3', 'email': 'user2@example.com', 'role': 'user', 'status': 'blocked'},
        ]
      };
    }
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['message'] ?? 'Failed to fetch users'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> createUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['message'] ?? 'Failed to create user'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> blockUser(String userId) async {
    if (useMockMode) {
      await Future.delayed(const Duration(milliseconds: 200));
      return {'success': true, 'data': {'message': 'User blocked successfully'}};
    }
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/block'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['message'] ?? 'Failed to block user'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> unblockUser(String userId) async {
    if (useMockMode) {
      await Future.delayed(const Duration(milliseconds: 200));
      return {'success': true, 'data': {'message': 'User unblocked successfully'}};
    }
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/unblock'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['message'] ?? 'Failed to unblock user'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> resetUserPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/reset-password'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['message'] ?? 'Failed to reset password'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteUser(String userId) async {
    if (useMockMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      return {'success': true, 'data': {'message': 'User deleted successfully'}};
    }
    
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['message'] ?? 'Failed to delete user'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Health check
  Future<bool> isServerHealthy() async {
    if (useMockMode) {
      developer.log('🔧 Mock mode enabled - simulating healthy server', name: 'DatabaseService');
      return true;
    }
    
    try {
      developer.log('🔍 Checking server health at: $baseUrl/health', name: 'DatabaseService');
      
      // Try multiple IP addresses for Android emulator
      final List<String> testUrls = [
        'http://10.0.2.2:3000/api/health',
        'http://127.0.0.1:3000/api/health',
        'http://localhost:3000/api/health',
        'http://192.168.100.21:3000/api/health',
      ];
      
      for (String url in testUrls) {
        try {
          developer.log('🔍 Trying: $url', name: 'DatabaseService');
          final response = await http.get(
            Uri.parse(url),
            headers: _headers,
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            developer.log('✅ Success with: $url', name: 'DatabaseService');
            developer.log('📊 Response: ${response.body}', name: 'DatabaseService');
            return true;
          }
        } catch (e) {
          developer.log('❌ Failed $url: $e', name: 'DatabaseService');
          continue;
        }
      }
      
      return false;
    } catch (e) {
      developer.log('❌ Health check failed: $e', name: 'DatabaseService');
      return false;
    }
  }

  // Methods for BackgroundSyncService
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString('user_data');
    if (dataString != null) {
      return json.decode(dataString);
    }
    return null;
  }

  Future<Map<String, dynamic>?> getSecuritySettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsString = prefs.getString('security_settings');
    if (settingsString != null) {
      return json.decode(settingsString);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getUnsyncdLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final logsString = prefs.getString('unsynced_logs');
    if (logsString != null) {
      final logs = json.decode(logsString);
      return List<Map<String, dynamic>>.from(logs);
    }
    return [];
  }

  Future<void> markLogsAsSynced(List<Map<String, dynamic>> logs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('unsynced_logs');
  }

  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString('last_sync_time');
    if (timeString != null) {
      return DateTime.parse(timeString);
    }
    return null;
  }

  Future<void> updateLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_sync_time', time.toIso8601String());
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileString = prefs.getString('user_profile');
    if (profileString != null) {
      return json.decode(profileString);
    }
    return null;
  }

  Future<void> updateUserProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', json.encode(profile));
  }

  Future<void> updateSecuritySettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('security_settings', json.encode(settings));
  }
}
