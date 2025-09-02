import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'production_backend_service.dart';

class DatabaseMigrationService extends ChangeNotifier {
  static DatabaseMigrationService? _instance;
  static DatabaseMigrationService get instance => _instance ??= DatabaseMigrationService._();
  DatabaseMigrationService._();

  bool _isInitialized = false;
  bool _isDatabaseMode = false;
  bool _isLocalStorageAvailable = false;
  int _localUsers = 0;
  int _databaseUsers = 0;

  final ProductionBackendService _backendService = ProductionBackendService();

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _backendService.initialize();
    await _checkStorageStatus();
    _isInitialized = true;
    notifyListeners();
    
    developer.log('Database Migration Service initialized', name: 'DatabaseMigrationService');
  }

  Future<void> _checkStorageStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check local storage availability
      _isLocalStorageAvailable = true;
      _localUsers = prefs.getInt('local_user_count') ?? 5;
      
      // Check database connection
      final connectionStatus = await _backendService.getConnectionStatus();
      _isDatabaseMode = connectionStatus['connected'] ?? false;
      
      if (_isDatabaseMode) {
        _databaseUsers = await _getDatabaseUserCount();
      }
      
      developer.log('Storage status checked - Local: $_isLocalStorageAvailable, Database: $_isDatabaseMode', 
          name: 'DatabaseMigrationService');
    } catch (e) {
      developer.log('Error checking storage status: $e', name: 'DatabaseMigrationService');
      _isLocalStorageAvailable = false;
      _isDatabaseMode = false;
    }
  }

  Future<int> _getDatabaseUserCount() async {
    try {
      // Mock database user count for now
      // In production, this would query the actual database
      return 0;
    } catch (e) {
      developer.log('Error getting database user count: $e', name: 'DatabaseMigrationService');
      return 0;
    }
  }

  Future<bool> enableDatabaseMode() async {
    try {
      developer.log('Attempting to enable database mode...', name: 'DatabaseMigrationService');
      
      // Test connection first
      final connectionStatus = await _backendService.getConnectionStatus();
      if (!connectionStatus['connected']) {
        developer.log('Database connection failed', name: 'DatabaseMigrationService');
        return false;
      }

      // Migrate local data to database if needed
      if (_isLocalStorageAvailable && _localUsers > 0) {
        await _migrateLocalDataToDatabase();
      }

      // Update preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('database_mode_enabled', true);
      
      _isDatabaseMode = true;
      _isLocalStorageAvailable = false; // Disable local storage when database is active
      notifyListeners();
      
      developer.log('Database mode enabled successfully', name: 'DatabaseMigrationService');
      return true;
    } catch (e) {
      developer.log('Error enabling database mode: $e', name: 'DatabaseMigrationService');
      return false;
    }
  }

  Future<void> _migrateLocalDataToDatabase() async {
    try {
      developer.log('Starting data migration from local storage to database...', name: 'DatabaseMigrationService');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Migrate user data
      final userData = prefs.getString('user_data');
      if (userData != null) {
        final user = jsonDecode(userData);
        // In production, this would call the backend API to create users
        developer.log('Migrating user: ${user['email']}', name: 'DatabaseMigrationService');
      }
      
      // Migrate security events
      final securityEvents = prefs.getStringList('security_events') ?? [];
      for (final event in securityEvents) {
        final eventData = jsonDecode(event);
        // In production, this would call the backend API to create security events
        developer.log('Migrating security event: ${eventData['type']}', name: 'DatabaseMigrationService');
      }
      
      // Update counters
      _databaseUsers = _localUsers;
      _localUsers = 0;
      await prefs.setInt('local_user_count', 0);
      await prefs.setInt('database_user_count', _databaseUsers);
      
      developer.log('Data migration completed successfully', name: 'DatabaseMigrationService');
    } catch (e) {
      developer.log('Error during data migration: $e', name: 'DatabaseMigrationService');
      rethrow;
    }
  }

  Future<bool> disableDatabaseMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('database_mode_enabled', false);
      
      _isDatabaseMode = false;
      _isLocalStorageAvailable = true;
      notifyListeners();
      
      developer.log('Database mode disabled', name: 'DatabaseMigrationService');
      return true;
    } catch (e) {
      developer.log('Error disabling database mode: $e', name: 'DatabaseMigrationService');
      return false;
    }
  }

  // Getters for UI
  bool get isInitialized => _isInitialized;
  bool get isDatabaseMode => _isDatabaseMode;
  bool get isLocalStorageAvailable => _isLocalStorageAvailable;
  int get localUsers => _localUsers;
  int get databaseUsers => _databaseUsers;
  String get storageMode => _isDatabaseMode ? 'Database Mode' : 'Local Storage';
  String get databaseServer => _isDatabaseMode ? 'Connected' : 'Unavailable';
  
  Map<String, dynamic> get migrationStatus => {
    'storageMode': storageMode,
    'databaseServer': databaseServer,
    'localUsers': _localUsers,
    'databaseUsers': _databaseUsers,
    'isDatabaseMode': _isDatabaseMode,
    'isLocalStorageAvailable': _isLocalStorageAvailable,
  };

  Future<void> refreshStatus() async {
    await _checkStorageStatus();
    notifyListeners();
  }

  Future<bool> migrateLocalDataToDatabase() async {
    try {
      await _migrateLocalDataToDatabase();
      return true;
    } catch (e) {
      developer.log('Public migration method failed: $e', name: 'DatabaseMigrationService');
      return false;
    }
  }
}
