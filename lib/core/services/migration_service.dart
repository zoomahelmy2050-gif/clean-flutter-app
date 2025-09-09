import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'database_service.dart';

class MigrationService extends ChangeNotifier {
  final DatabaseService _databaseService;
  
  List<Migration> _migrations = [];
  bool _isLoading = false;
  String? _error;
  MigrationStatus? _status;
  
  MigrationService(this._databaseService);
  
  List<Migration> get migrations => _migrations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  MigrationStatus? get status => _status;
  bool get hasAuthToken => _databaseService.authToken != null;
  
  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    final token = _databaseService.authToken;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
  
  Future<void> fetchMigrationStatus() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // First ensure we have auth token
      if (_databaseService.authToken == null) {
        // Try to login with default admin credentials
        await _loginToBackend();
      }
      
      final response = await http.get(
        Uri.parse('${AppConfig.backendUrl}/migrations/status'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 401) {
        // Token expired, try to login again
        await _loginToBackend();
        // Retry with new token
        final retryResponse = await http.get(
          Uri.parse('${AppConfig.backendUrl}/migrations/status'),
          headers: _headers,
        ).timeout(const Duration(seconds: 10));
        if (retryResponse.statusCode == 200) {
          final data = json.decode(retryResponse.body);
          _status = MigrationStatus.fromJson(data);
          _migrations = (data['migrations'] as List?)
              ?.map((m) => Migration.fromJson(m))
              .toList() ?? [];
        } else {
          throw Exception('Authentication failed. Please login first.');
        }
      } else if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _status = MigrationStatus.fromJson(data);
        _migrations = (data['migrations'] as List?)
            ?.map((m) => Migration.fromJson(m))
            .toList() ?? [];
      } else {
        throw Exception('Failed to fetch migration status: ${response.statusCode}');
      }
    } on TimeoutException catch (_) {
      _error = 'Connection timeout - Backend server not responding';
      _status = MigrationStatus(
        migrations: [],
        databaseConnected: false,
        error: 'Connection timeout',
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _loginToBackend() async {
    try {
      // Login with admin credentials (same as Security Center)
      final loginResponse = await http.post(
        Uri.parse('${AppConfig.backendUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': 'env.hygiene@gmail.com',
          'password': 'password',
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (loginResponse.statusCode == 200) {
        final loginData = json.decode(loginResponse.body);
        final token = loginData['accessToken'];
        if (token != null) {
          await _databaseService.saveAuthToken(token);
        } else {
          throw Exception('No access token in login response');
        }
      } else {
        throw Exception('Backend login failed: ${loginResponse.statusCode} - ${loginResponse.body}');
      }
    } on TimeoutException catch (_) {
      throw Exception('Connection timeout - Backend server not responding');
    } catch (e) {
      throw Exception('Failed to authenticate with backend: $e');
    }
  }
  
  Future<bool> loginToBackend(String email, String password) async {
    try {
      final loginResponse = await http.post(
        Uri.parse('${AppConfig.backendUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (loginResponse.statusCode == 200) {
        final loginData = json.decode(loginResponse.body);
        final token = loginData['accessToken'];
        if (token != null) {
          await _databaseService.saveAuthToken(token);
          // Fetch status after successful login
          await fetchMigrationStatus();
          return true;
        }
      }
      return false;
    } on TimeoutException catch (_) {
      _error = 'Connection timeout - Backend server not responding';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Login failed: $e';
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> applyMigrations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.backendUrl}/migrations/apply'),
        headers: _headers,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchMigrationStatus(); // Refresh status
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to apply migrations');
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> resetDatabase() async {
    if (AppConfig.environment == 'production') {
      _error = 'Database reset not allowed in production';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.backendUrl}/migrations/reset'),
        headers: _headers,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchMigrationStatus();
        return true;
      } else {
        throw Exception('Failed to reset database');
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class Migration {
  final String id;
  final String version;
  final String name;
  final String status;
  final DateTime? appliedAt;
  final DateTime? rolledBackAt;
  final String? error;
  final DateTime createdAt;
  
  Migration({
    required this.id,
    required this.version,
    required this.name,
    required this.status,
    this.appliedAt,
    this.rolledBackAt,
    this.error,
    required this.createdAt,
  });
  
  factory Migration.fromJson(Map<String, dynamic> json) {
    return Migration(
      id: json['id'],
      version: json['version'],
      name: json['name'],
      status: json['status'],
      appliedAt: json['appliedAt'] != null 
          ? DateTime.parse(json['appliedAt']) 
          : null,
      rolledBackAt: json['rolledBackAt'] != null 
          ? DateTime.parse(json['rolledBackAt']) 
          : null,
      error: json['error'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
  
  bool get isApplied => status == 'applied';
  bool get isFailed => status == 'failed';
  bool get isPending => status == 'pending';
  bool get isRolledBack => status == 'rolled_back';
}

class MigrationStatus {
  final List<Migration> migrations;
  final String? prismaStatus;
  final bool databaseConnected;
  final String? error;
  
  MigrationStatus({
    required this.migrations,
    this.prismaStatus,
    required this.databaseConnected,
    this.error,
  });
  
  factory MigrationStatus.fromJson(Map<String, dynamic> json) {
    return MigrationStatus(
      migrations: (json['migrations'] as List?)
          ?.map((m) => Migration.fromJson(m))
          .toList() ?? [],
      prismaStatus: json['prismaStatus'],
      databaseConnected: json['databaseConnected'] ?? false,
      error: json['error'],
    );
  }
}
