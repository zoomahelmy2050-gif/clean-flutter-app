import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clean_flutter/core/config/app_config.dart';

class BackendService {
  // Use AppConfig for dynamic backend URL
  String get _baseUrl => AppConfig.backendUrl;
  static const String _tokenKey = 'auth_token';
  
  String? _authToken;
  
  BackendService() {
    _loadToken();
  }
  
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_tokenKey);
  }
  
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    _authToken = token;
  }
  
  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _authToken = null;
  }
  
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };
  
  Future<Map<String, dynamic>> register(String email, String passwordRecordV2) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'passwordRecordV2': passwordRecordV2,
        }),
      ).timeout(AppConfig.networkTimeout);
      
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Connection timeout or network error: $e'};
    }
  }
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(AppConfig.networkTimeout);
      
      final result = jsonDecode(response.body);
      
      // Accept both snake_case and camelCase token keys
      final token = result['access_token'] ?? result['accessToken'];
      if (response.statusCode == 200 && token != null) {
        await _saveToken(token);
      }
      
      return result;
    } catch (e) {
      return {'error': 'Connection timeout or network error: $e'};
    }
  }
  
  Future<void> logout() async {
    await _clearToken();
  }
  
  Future<Map<String, dynamic>> rotateVerifier(String passwordRecordV2) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/rotate-verifier'),
      headers: _headers,
      body: jsonEncode({
        'passwordRecordV2': passwordRecordV2,
      }),
    );
    
    return jsonDecode(response.body);
  }
  
  Future<Map<String, dynamic>> listBlobs() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/blobs/list'),
      headers: _headers,
    );
    
    return jsonDecode(response.body);
  }
  
  Future<Map<String, dynamic>?> getBlob(String key) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/blobs/$key'),
      headers: _headers,
    );
    
    if (response.statusCode == 404) {
      return null;
    }
    
    return jsonDecode(response.body);
  }
  
  Future<Map<String, dynamic>> putBlob(String key, {
    required String ciphertext,
    required String nonce,
    required String mac,
    String? aad,
    required String version,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/blobs/$key'),
      headers: _headers,
      body: jsonEncode({
        'ciphertext': ciphertext,
        'nonce': nonce,
        'mac': mac,
        'aad': aad,
        'version': version,
      }),
    );
    
    return jsonDecode(response.body);
  }
  
  bool get isAuthenticated => _authToken != null;
  
  Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health')).timeout(AppConfig.healthCheckTimeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  // Generic authenticated request methods for admin services
  Future<Map<String, dynamic>?> makeAuthenticatedRequest(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'POST':
          response = await http.post(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(AppConfig.networkTimeout);
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(AppConfig.networkTimeout);
          break;
        case 'DELETE':
          response = await http.delete(
            uri,
            headers: _headers,
          ).timeout(AppConfig.networkTimeout);
          break;
        case 'GET':
        default:
          response = await http.get(
            uri,
            headers: _headers,
          ).timeout(AppConfig.networkTimeout);
      }
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        print('Request failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error making authenticated request: $e');
      return null;
    }
  }
  
  // Additional helper methods for admin services
  Future<Map<String, dynamic>?> get(String endpoint) async {
    return makeAuthenticatedRequest(endpoint, method: 'GET');
  }
  
  Future<Map<String, dynamic>?> post(String endpoint, Map<String, dynamic> body) async {
    return makeAuthenticatedRequest(endpoint, method: 'POST', body: body);
  }
  
  Future<Map<String, dynamic>?> put(String endpoint, Map<String, dynamic> body) async {
    return makeAuthenticatedRequest(endpoint, method: 'PUT', body: body);
  }
  
  Future<Map<String, dynamic>?> delete(String endpoint) async {
    return makeAuthenticatedRequest(endpoint, method: 'DELETE');
  }
}
