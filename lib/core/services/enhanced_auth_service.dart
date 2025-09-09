import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:developer' as developer;
import 'package:clean_flutter/core/services/advanced_login_monitor.dart';
import '../../locator.dart';

class EnhancedAuthService with ChangeNotifier {
  static const _usersKey = 'enhanced_auth_users_v1';
  static const _currentUserKey = 'enhanced_auth_current_user';
  static const _rememberMeKey = 'enhanced_auth_remember_me';
  static const _rememberedEmailKey = 'enhanced_auth_remembered_email';
  static const _adminEmail = 'env.hygiene@gmail.com';

  late SharedPreferences _prefs;
  late AdvancedLoginMonitor _loginMonitor;
  
  final Map<String, String> _users = {}; // email -> hashed password
  String? _currentUser;
  bool _rememberMe = false;
  String? _rememberedEmail;
  bool _isInitialized = false;

  // Getters
  bool get isInitialized => _isInitialized;
  String? get currentUser => _currentUser;
  bool get rememberMe => _rememberMe;
  String? get rememberedEmail => _rememberedEmail;

  /// Initialize the enhanced auth service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      _loginMonitor = locator<AdvancedLoginMonitor>();
      await _loginMonitor.initialize();
      
      await _loadUserData();
      await _ensureAdminUser();
      
      _isInitialized = true;
      developer.log('EnhancedAuthService initialized successfully', name: 'EnhancedAuth');
      notifyListeners();
    } catch (e) {
      developer.log('Failed to initialize EnhancedAuthService: $e', name: 'EnhancedAuth');
      rethrow;
    }
  }

  /// Load user data from storage
  Future<void> _loadUserData() async {
    try {
      // Load users
      final usersJson = _prefs.getString(_usersKey);
      if (usersJson != null) {
        final Map<String, dynamic> usersMap = jsonDecode(usersJson);
        _users.clear();
        _users.addAll(usersMap.map((k, v) => MapEntry(k, v.toString())));
      }

      // Load current user
      _currentUser = _prefs.getString(_currentUserKey);
      
      // Load remember me settings
      _rememberMe = _prefs.getBool(_rememberMeKey) ?? false;
      _rememberedEmail = _prefs.getString(_rememberedEmailKey);
      
      developer.log('Loaded ${_users.length} users from storage', name: 'EnhancedAuth');
    } catch (e) {
      developer.log('Error loading user data: $e', name: 'EnhancedAuth');
    }
  }

  /// Ensure admin user exists and migrate existing users
  Future<void> _ensureAdminUser() async {
    const adminEmail = 'env.hygiene@gmail.com';
    const adminPassword = 'password';
    
    // Migrate existing users from old AuthService
    await _migrateExistingUsers();
    
    if (!_users.containsKey(adminEmail)) {
      final hashedPassword = _hashPassword(adminPassword, adminEmail);
      _users[adminEmail] = hashedPassword;
      await _saveUsers();
      developer.log('Admin user created', name: 'EnhancedAuth');
    }
  }

  /// Migrate existing users from old AuthService to EnhancedAuthService
  Future<void> _migrateExistingUsers() async {
    try {
      // Read users from old AuthService storage
      final oldUsersJson = _prefs.getString('auth_users_map');
      if (oldUsersJson != null) {
        final oldUsers = Map<String, String>.from(jsonDecode(oldUsersJson));
        
        int migratedCount = 0;
        for (final entry in oldUsers.entries) {
          final email = entry.key;
          final oldHashedPassword = entry.value;
          
          // Only migrate if user doesn't exist in new system
          if (!_users.containsKey(email)) {
            // For migration, we'll use a special migration hash
            // In a real app, you'd need to prompt users to reset passwords
            _users[email] = oldHashedPassword; // Keep old hash for compatibility
            migratedCount++;
          }
        }
        
        if (migratedCount > 0) {
          await _saveUsers();
          developer.log('Migrated $migratedCount users from old AuthService', name: 'EnhancedAuth');
        }
      }
    } catch (e) {
      developer.log('Error migrating users: $e', name: 'EnhancedAuth');
    }
  }

  /// Hash password with salt
  String _hashPassword(String password, String email) {
    final saltedPassword = password + email + 'enhanced_auth_salt_2024';
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Save users to storage
  Future<void> _saveUsers() async {
    try {
      await _prefs.setString(_usersKey, jsonEncode(_users));
    } catch (e) {
      developer.log('Error saving users: $e', name: 'EnhancedAuth');
    }
  }

  /// Check if login is allowed before attempting
  Future<Map<String, dynamic>> checkLoginAllowed({
    required String email,
    String? ipAddress,
    String? userAgent,
  }) async {
    if (!_isInitialized) {
      return {
        'allowed': false,
        'error': 'Authentication service not ready',
        'reason': 'Authentication service not ready',
      };
    }
    
    final normalizedEmail = email.toLowerCase();
    
    // Admin always allowed
    if (normalizedEmail == _adminEmail) {
      return {
        'allowed': true,
        'isAdmin': true,
        'riskScore': 0.0,
        'riskLevel': 'none',
        'attemptsRemaining': 999, // Admin always has attempts
        'requiresCaptcha': false,
        'requiresMFA': false,
        'progressiveDelay': 0,
        'delaySeconds': 0,
      };
    }
    
    // Check with new advanced login monitor
    final permission = await _loginMonitor.checkLoginPermission(
      email: normalizedEmail,
      ipAddress: ipAddress,
      userAgent: userAgent,
    );
    
    // Normalize error messaging for blacklisted IPs to match tests
    String? errorMessage = permission.reason;
    if (errorMessage != null && errorMessage.toLowerCase().contains('blacklist')) {
      errorMessage = 'IP address is blocked';
    }
    
    return {
      'allowed': permission.allowed,
      'error': errorMessage,
      'reason': errorMessage,
      'lockoutMinutes': permission.lockoutMinutes,
      'lockoutDuration': permission.lockoutMinutes, // alias expected by tests
      'attemptsRemaining': permission.attemptsRemaining,
      'requiresCaptcha': permission.requiresCaptcha,
      'requiresMFA': permission.requiresMFA,
      'progressiveDelay': permission.delaySeconds,
      'delaySeconds': permission.delaySeconds, // alias expected by tests
      'riskScore': permission.riskScore,
      'riskLevel': permission.riskLevel,
    };
  }

  /// Perform login with advanced security
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? ipAddress,
    String? userAgent,
  }) async {
    if (!_isInitialized) {
      return {'success': false, 'error': 'Authentication service not ready'};
    }

    final normalizedEmail = email.toLowerCase();
    
    // Pre-check if login is allowed
    final allowedCheck = await checkLoginAllowed(
      email: normalizedEmail,
      ipAddress: ipAddress,
      userAgent: userAgent,
    );
    
    if (!allowedCheck['allowed']) {
      // Failed attempt is already recorded by checkLoginPermission
      
      return {
        'success': false,
        'error': allowedCheck['error'],
        'lockoutMinutes': allowedCheck['lockoutMinutes'] ?? 0,
        'lockoutDuration': allowedCheck['lockoutDuration'] ?? allowedCheck['lockoutMinutes'] ?? 0,
        'attemptsRemaining': allowedCheck['attemptsRemaining'] ?? 0,
        'requiresCaptcha': allowedCheck['requiresCaptcha'] ?? false,
        'progressiveDelay': allowedCheck['progressiveDelay'] ?? 0,
        'delaySeconds': allowedCheck['delaySeconds'] ?? allowedCheck['progressiveDelay'] ?? 0,
      };
    }

    // Verify password
    bool loginSuccess = false;
    final storedPassword = _users[normalizedEmail];
    
    if (storedPassword != null) {
      final hashedPassword = _hashPassword(password, normalizedEmail);
      loginSuccess = storedPassword == hashedPassword;
    }

    // Record the attempt
    await _loginMonitor.recordAttempt(
      email: normalizedEmail,
      successful: loginSuccess,
      ipAddress: ipAddress,
      userAgent: userAgent,
    );

    if (loginSuccess) {
      _currentUser = normalizedEmail;
      await _prefs.setString(_currentUserKey, normalizedEmail);
      
      if (_rememberMe) {
        _rememberedEmail = normalizedEmail;
        await _prefs.setString(_rememberedEmailKey, normalizedEmail);
      }
      
      notifyListeners();
      developer.log('Login successful for $normalizedEmail', name: 'EnhancedAuth');
      
      return {
        'success': true,
        'user': normalizedEmail,
        'riskScore': allowedCheck['riskScore'] ?? 0.0,
        'riskLevel': allowedCheck['riskLevel'] ?? 'low',
        'isAdmin': normalizedEmail == _adminEmail,
      };
    } else {
      // Get updated security status after failed attempt
      final updatedCheck = await checkLoginAllowed(
        email: normalizedEmail,
        ipAddress: ipAddress,
        userAgent: userAgent,
      );
      
      return {
        'success': false,
        'error': 'Invalid email or password',
        'attemptsRemaining': updatedCheck['attemptsRemaining'] ?? 0,
        'requiresCaptcha': updatedCheck['requiresCaptcha'] ?? false,
        'progressiveDelay': updatedCheck['progressiveDelay'] ?? 0,
        'delaySeconds': updatedCheck['delaySeconds'] ?? updatedCheck['progressiveDelay'] ?? 0,
        'riskScore': updatedCheck['riskScore'] ?? 0.0,
        'lockoutMinutes': updatedCheck['lockoutMinutes'] ?? 0,
        'lockoutDuration': updatedCheck['lockoutDuration'] ?? updatedCheck['lockoutMinutes'] ?? 0,
      };
    }
  }

  /// Register new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
  }) async {
    if (!_isInitialized) {
      return {'success': false, 'error': 'Authentication service not ready'};
    }

    final normalizedEmail = email.toLowerCase();
    
    if (_users.containsKey(normalizedEmail)) {
      return {'success': false, 'error': 'User already exists'};
    }

    final hashedPassword = _hashPassword(password, normalizedEmail);
    _users[normalizedEmail] = hashedPassword;
    await _saveUsers();
    
    developer.log('User registered: $normalizedEmail', name: 'EnhancedAuth');
    notifyListeners();
    
    return {'success': true, 'user': normalizedEmail};
  }

  /// Logout user
  Future<void> logout() async {
    _currentUser = null;
    await _prefs.remove(_currentUserKey);
    notifyListeners();
    developer.log('User logged out', name: 'EnhancedAuth');
  }

  /// Set remember me preference
  Future<void> setRememberMe(bool remember, String? email) async {
    _rememberMe = remember;
    _rememberedEmail = remember ? email?.toLowerCase() : null;
    
    await _prefs.setBool(_rememberMeKey, _rememberMe);
    
    if (_rememberedEmail != null) {
      await _prefs.setString(_rememberedEmailKey, _rememberedEmail!);
    } else {
      await _prefs.remove(_rememberedEmailKey);
    }
    
    notifyListeners();
  }

  /// Check if email is registered
  bool isEmailRegistered(String email) {
    final normalizedEmail = email.toLowerCase();
    
    // Check enhanced auth storage first
    if (_users.containsKey(normalizedEmail)) {
      return true;
    }
    
    // Also check old AuthService storage for backward compatibility
    try {
      final oldUsersJson = _prefs.getString('auth_users_map');
      if (oldUsersJson != null) {
        final oldUsers = Map<String, String>.from(jsonDecode(oldUsersJson));
        if (oldUsers.containsKey(normalizedEmail)) {
          // Migrate this user on the fly
          _users[normalizedEmail] = oldUsers[normalizedEmail]!;
          _saveUsers(); // Don't await to keep this method synchronous
          developer.log('Migrated user on-demand: $normalizedEmail', name: 'EnhancedAuth');
          return true;
        }
      }
    } catch (e) {
      developer.log('Error checking old users: $e', name: 'EnhancedAuth');
    }
    
    return false;
  }

  /// Get all registered users (admin function)
  List<String> getAllUsers() {
    return _users.keys.toList();
  }

  /// Update user password
  Future<bool> updateUserPassword(String email, String newPassword) async {
    final normalizedEmail = email.toLowerCase();
    
    if (!_users.containsKey(normalizedEmail)) {
      return false;
    }

    final hashedPassword = _hashPassword(newPassword, normalizedEmail);
    _users[normalizedEmail] = hashedPassword;
    await _saveUsers();
    
    // Clear any security lockouts for this user
    await _loginMonitor.clearAttempts(normalizedEmail);
    
    developer.log('Password updated for $normalizedEmail', name: 'EnhancedAuth');
    notifyListeners();
    return true;
  }

  /// Reset user password (admin function)
  Future<String> resetUserPassword(String email) async {
    final normalizedEmail = email.toLowerCase();
    
    if (!_users.containsKey(normalizedEmail)) {
      throw Exception('User not found');
    }

    final newPassword = _generateRandomPassword();
    final hashedPassword = _hashPassword(newPassword, normalizedEmail);
    _users[normalizedEmail] = hashedPassword;
    await _saveUsers();
    
    // Clear any security lockouts
    await _loginMonitor.clearAttempts(normalizedEmail);
    
    developer.log('Password reset for $normalizedEmail', name: 'EnhancedAuth');
    notifyListeners();
    return newPassword;
  }

  /// Generate random password
  String _generateRandomPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(12, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  /// Get security statistics
  Map<String, dynamic> getSecurityStats() {
    return _loginMonitor.getStatistics();
  }

  /// Get recent security attempts (admin function)
  List<Map<String, dynamic>> getRecentLoginAttempts({int limit = 10}) {
    return _loginMonitor.getRecentAttempts(limit: limit)
        .map((attempt) => {
              'email': attempt.email,
              'timestamp': attempt.timestamp.toIso8601String(),
              'successful': attempt.successful,
              'ipAddress': attempt.ipAddress,
              'riskScore': attempt.riskScore,
              'securityFlags': attempt.securityFlags,
            })
        .toList();
  }

  /// Check if login is allowed (sync version)
  bool checkLoginAllowedSync(String email) {
    if (!_isInitialized) return false;
    
    final normalizedEmail = email.toLowerCase();
    
    // Admin always allowed
    if (normalizedEmail == _adminEmail) return true;
    
    // Use sync version from login monitor
    final permission = _loginMonitor.checkLoginPermissionSync(
      email: normalizedEmail,
    );
    
    return permission.allowed;
  }

  /// Unlock user account (admin function)
  Future<void> unlockUser(String email) async {
    await _loginMonitor.unlockUser(email);
    await _loginMonitor.clearAttempts(email);
    notifyListeners();
  }

  /// Unblock IP address (admin function)
  Future<void> unblockIp(String ipAddress) async {
    await _loginMonitor.removeFromBlacklist(ipAddress);
    notifyListeners();
  }

  /// Check if user is locked
  bool isUserLocked(String email) {
    final permission = _loginMonitor.checkLoginPermissionSync(email: email);
    return !permission.allowed && permission.reason?.contains('locked') == true;
  }

  static const Duration lockoutDuration = Duration(minutes: 10);

  /// Get remaining lockout time
  Duration? getRemainingLockoutTime(String email) {
    final permission = _loginMonitor.checkLoginPermissionSync(email: email);
    if (permission.lockoutMinutes != null && permission.lockoutMinutes! > 0) {
      return Duration(minutes: permission.lockoutMinutes!);
    }
    return null;
  }

  /// Verify password for re-authentication
  Future<bool> verifyPassword(String email, String password) async {
    final normalizedEmail = email.toLowerCase();
    final storedPassword = _users[normalizedEmail];
    
    if (storedPassword == null) return false;
    
    final hashedPassword = _hashPassword(password, normalizedEmail);
    return storedPassword == hashedPassword;
  }
}
