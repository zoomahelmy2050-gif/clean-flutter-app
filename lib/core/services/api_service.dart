import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  late final String _baseUrl;
  static const Duration _timeout = Duration(seconds: 5);
  
  String? _authToken;
  
  ApiService() {
    // Safely get the base URL, with fallback
    try {
      _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://192.168.100.21:3000';
    } catch (e) {
      // If dotenv isn't initialized, use default
      _baseUrl = 'http://192.168.100.21:3000';
      debugPrint('Using default API URL - dotenv not initialized: $e');
    }
    _loadAuthToken();
  }
  
  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }
  
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  
  Future<void> clearAuthToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
  
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }
  
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final uriWithParams = queryParams != null 
          ? uri.replace(queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())))
          : uri;
      
      final response = await http.get(uriWithParams, headers: _headers).timeout(_timeout);
      return _handleResponse<T>(response);
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }
  
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
        body: body != null ? json.encode(body) : null,
      ).timeout(_timeout);
      
      return _handleResponse<T>(response);
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }
  
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
        body: body != null ? json.encode(body) : null,
      ).timeout(_timeout);
      
      return _handleResponse<T>(response);
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }
  
  Future<ApiResponse<T>> delete<T>(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
      ).timeout(_timeout);
      
      return _handleResponse<T>(response);
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }
  
  ApiResponse<T> _handleResponse<T>(http.Response response) {
    try {
      final data = json.decode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(data);
      } else {
        final error = data['message'] ?? data['error'] ?? 'Unknown error occurred';
        return ApiResponse.error(error);
      }
    } catch (e) {
      return ApiResponse.error('Failed to parse response: $e');
    }
  }
  
  String _handleError(dynamic error) {
    if (error is SocketException) {
      return 'Backend server unavailable';
    } else if (error is HttpException) {
      return 'HTTP error: ${error.message}';
    } else if (error is FormatException) {
      return 'Invalid response format';
    } else if (error.toString().contains('TimeoutException')) {
      return 'Connection timeout - server unavailable';
    } else {
      return 'Network error: $error';
    }
  }

  // Methods for BackgroundSyncService
  Future<void> syncUserData(Map<String, dynamic> userData) async {
    try {
      await post('/sync/user-data', body: userData);
    } catch (e) {
      debugPrint('Error syncing user data: $e');
    }
  }

  Future<void> syncSecuritySettings(Map<String, dynamic> settings) async {
    try {
      await post('/sync/security-settings', body: settings);
    } catch (e) {
      debugPrint('Error syncing security settings: $e');
    }
  }

  Future<void> syncActivityLogs(List<Map<String, dynamic>> logs) async {
    try {
      await post('/sync/activity-logs', body: {'logs': logs});
    } catch (e) {
      debugPrint('Error syncing activity logs: $e');
    }
  }

  Future<void> uploadBackup(Map<String, dynamic> backupData) async {
    try {
      await post('/backup/upload', body: backupData);
    } catch (e) {
      debugPrint('Error uploading backup: $e');
    }
  }

  Future<Map<String, dynamic>?> downloadBackup([String? backupId]) async {
    try {
      final endpoint = backupId != null ? '/backup/download/$backupId' : '/backup/download';
      final response = await get<Map<String, dynamic>>(endpoint);
      return response.data;
    } catch (e) {
      debugPrint('Error downloading backup: $e');
      return null;
    }
  }

  // Methods for RealtimeNotificationService
  Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      debugPrint('Error getting auth token: $e');
      return null;
    }
  }

  String get baseUrl => _baseUrl;

  // Methods for BackgroundSyncService
  Future<void> syncTotpEntries(Map<String, dynamic> encryptedEntries) async {
    try {
      await post('/sync/totp-entries', body: encryptedEntries);
    } catch (e) {
      debugPrint('Error syncing TOTP entries: $e');
    }
  }

  Future<void> syncUserProfile(Map<String, dynamic> profile) async {
    try {
      await post('/sync/user-profile', body: profile);
    } catch (e) {
      debugPrint('Error syncing user profile: $e');
    }
  }
}

class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;
  
  ApiResponse.success(this.data) : error = null, isSuccess = true;
  ApiResponse.error(this.error) : data = null, isSuccess = false;
}

// User Profile Models
class UserProfile {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? bio;
  final String? location;
  final String? website;
  final String? timezone;
  final String? language;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.bio,
    this.location,
    this.website,
    this.timezone,
    this.language,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phone: json['phone'],
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth']) : null,
      gender: json['gender'],
      bio: json['bio'],
      location: json['location'],
      website: json['website'],
      timezone: json['timezone'],
      language: json['language'],
      profileImageUrl: json['profileImageUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'bio': bio,
      'location': location,
      'website': website,
      'timezone': timezone,
      'language': language,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

// User Session Model
class UserSession {
  final String id;
  final String userId;
  final String deviceName;
  final String deviceType;
  final String ipAddress;
  final String location;
  final String userAgent;
  final DateTime createdAt;
  final DateTime lastActivity;
  final bool isCurrent;
  
  UserSession({
    required this.id,
    required this.userId,
    required this.deviceName,
    required this.deviceType,
    required this.ipAddress,
    required this.location,
    required this.userAgent,
    required this.createdAt,
    required this.lastActivity,
    required this.isCurrent,
  });
  
  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id'],
      userId: json['userId'],
      deviceName: json['deviceName'],
      deviceType: json['deviceType'],
      ipAddress: json['ipAddress'],
      location: json['location'],
      userAgent: json['userAgent'],
      createdAt: DateTime.parse(json['createdAt']),
      lastActivity: DateTime.parse(json['lastActivity']),
      isCurrent: json['isCurrent'] ?? false,
    );
  }
}

// Security Data Model
class SecurityData {
  final int securityScore;
  final DateTime lastSecurityCheck;
  final int activeSessions;
  final int recentAlerts;
  final DateTime? backupCodesGenerated;
  final DateTime? passwordLastChanged;
  final List<SecurityAlert> alerts;
  
  SecurityData({
    required this.securityScore,
    required this.lastSecurityCheck,
    required this.activeSessions,
    required this.recentAlerts,
    this.backupCodesGenerated,
    this.passwordLastChanged,
    required this.alerts,
  });
  
  factory SecurityData.fromJson(Map<String, dynamic> json) {
    return SecurityData(
      securityScore: json['securityScore'],
      lastSecurityCheck: DateTime.parse(json['lastSecurityCheck']),
      activeSessions: json['activeSessions'],
      recentAlerts: json['recentAlerts'],
      backupCodesGenerated: json['backupCodesGenerated'] != null 
          ? DateTime.parse(json['backupCodesGenerated']) : null,
      passwordLastChanged: json['passwordLastChanged'] != null 
          ? DateTime.parse(json['passwordLastChanged']) : null,
      alerts: (json['alerts'] as List?)
          ?.map((alert) => SecurityAlert.fromJson(alert))
          .toList() ?? [],
    );
  }
}

class SecurityAlert {
  final String id;
  final String type;
  final String message;
  final String severity;
  final DateTime timestamp;
  final bool acknowledged;
  
  SecurityAlert({
    required this.id,
    required this.type,
    required this.message,
    required this.severity,
    required this.timestamp,
    required this.acknowledged,
  });
  
  factory SecurityAlert.fromJson(Map<String, dynamic> json) {
    return SecurityAlert(
      id: json['id'],
      type: json['type'],
      message: json['message'],
      severity: json['severity'],
      timestamp: DateTime.parse(json['timestamp']),
      acknowledged: json['acknowledged'] ?? false,
    );
  }
}
