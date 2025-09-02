import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:developer' as developer;
import '../config/app_config.dart';
import 'database_service.dart';

class HybridAuthService with ChangeNotifier {
  static const _passwordKey = 'auth_password';
  static const _usersKey = 'auth_users_map';
  static const _securityKeysKey = 'auth_security_keys_map';
  static const _mfaEnabledKey = 'auth_user_mfa_map';
  static const _biometricEnabledKey = 'auth_user_biometric_map';
  static const _mfaMethodPrefKey = 'auth_user_mfa_method_pref_v2';
  static const _totpSecretsKey = 'auth_user_totp_secret_v1';
  static const _userBackupCodesKey = 'auth_user_backup_codes_v1';
  static const _usedUserBackupCodesKey = 'auth_used_user_backup_codes_v1';
  static const _blockedUsersKey = 'auth_blocked_users_v1';
  static const _rememberMeKey = 'auth_remember_me';
  static const _rememberedEmailKey = 'auth_remembered_email';
  static const _currentUserKey = 'auth_current_user';
  static const _useDatabaseKey = 'auth_use_database';

  late SharedPreferences _prefs;
  late DatabaseService _databaseService;
  
  String _password = 'password';
  final Map<String, String> _users = {};
  final Map<String, String> _securityKeys = {};
  final Map<String, bool> _userMfa = {};
  final Map<String, bool> _userBiometric = {};
  final Map<String, String> _userMfaMethodPref = {};
  final Map<String, String> _userTotpSecret = {};
  final Map<String, List<String>> _userBackupCodes = {};
  final Map<String, List<String>> _usedUserBackupCodes = {};
  final Map<String, bool> _blockedUsers = {};
  
  bool _isInitialized = false;
  bool _useDatabase = false;
  bool _rememberMe = false;
  String? _currentUser;
  String? _rememberedEmail;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get useDatabase => _useDatabase;
  String? get currentUser => _currentUser;
  bool get rememberMe => _rememberMe;
  String? get rememberedEmail => _rememberedEmail;

  HybridAuthService() {
    _initialize();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    _databaseService = DatabaseService(
      baseUrl: AppConfig.backendUrl,
      useMockMode: AppConfig.useLocalStorage,
    );
    await _databaseService.initialize();
    
    // Check if we should use database
    _useDatabase = _prefs.getBool(_useDatabaseKey) ?? false;
    
    // Load local data
    await _loadLocalData();
    
    // Test database connection if enabled
    if (_useDatabase) {
      final isHealthy = await _databaseService.isServerHealthy();
      if (!isHealthy) {
        developer.log('Database server not available, falling back to local storage', name: 'HybridAuthService');
        _useDatabase = false;
        await _prefs.setBool(_useDatabaseKey, false);
      }
    }
    
    // Ensure default admin user exists
    await _ensureDefaultAdminUser();
    
    _isInitialized = true;
    notifyListeners();
  }

  void _initialize() {
    initialize();
  }

  Future<void> _loadLocalData() async {
    // Load password
    _password = _prefs.getString(_passwordKey) ?? 'password';
    
    // Load users
    final usersJson = _prefs.getString(_usersKey);
    if (usersJson != null) {
      final Map<String, dynamic> usersMap = jsonDecode(usersJson);
      _users.clear();
      usersMap.forEach((key, value) => _users[key] = value.toString());
    }
    
    // Load security keys
    final keysJson = _prefs.getString(_securityKeysKey);
    if (keysJson != null) {
      final Map<String, dynamic> keysMap = jsonDecode(keysJson);
      _securityKeys.clear();
      keysMap.forEach((key, value) => _securityKeys[key] = value.toString());
    }
    
    // Load other settings
    _rememberMe = _prefs.getBool(_rememberMeKey) ?? false;
    _rememberedEmail = _prefs.getString(_rememberedEmailKey);
    _currentUser = _prefs.getString(_currentUserKey);
  }

  Future<void> _ensureDefaultAdminUser() async {
    const adminEmail = 'env.hygiene@gmail.com';
    const adminPassword = 'password';
    
    if (!_users.containsKey(adminEmail)) {
      _users[adminEmail] = _hashPassword(adminPassword, adminEmail);
      _securityKeys[adminEmail] = _generateSecurityKey();
      await _saveUsers();
      await _saveSecurityKeys();
    }
  }

  String _generateSecurityKey() {
    final random = Random.secure();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
  }

  String _hashPassword(String password, String email) {
    final saltedPassword = password + email + 'security_app_salt_2024';
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _saveUsers() async {
    await _prefs.setString(_usersKey, jsonEncode(_users));
  }

  Future<void> _saveSecurityKeys() async {
    await _prefs.setString(_securityKeysKey, jsonEncode(_securityKeys));
  }

  Future<void> _saveBlockedUsers() async {
    await _prefs.setString(_blockedUsersKey, jsonEncode(_blockedUsers));
  }

  // Simplified auth methods
  bool isAccountLocked(String email) => false;
  void clearLoginAttempts(String email) {}
  int getFailedAttempts(String email) => 0;
  
  // Basic auth functionality
  bool isEmailRegistered(String email) => _users.containsKey(email);
  String? getSecurityKey(String email) => _securityKeys[email];
  
  Future<String> regenerateSecurityKey(String email) async {
    if (!_users.containsKey(email)) {
      throw Exception('Email not registered');
    }
    
    final newKey = _generateSecurityKey();
    _securityKeys[email] = newKey;
    await _saveSecurityKeys();
    return newKey;
  }
}
