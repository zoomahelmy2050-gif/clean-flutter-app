import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'database_service.dart';
import 'login_attempts_service.dart';
import 'role_management_service.dart';
import '../../locator.dart';
import 'dart:developer' as developer;

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
  // Removed unused _saltKey

  late SharedPreferences _prefs;
  final DatabaseService _databaseService = DatabaseService();
  final LoginAttemptsService _loginAttemptsService = LoginAttemptsService();
  
  String _password = 'password';
  final Map<String, String> _users = {};
  final Map<String, String> _securityKeys = {};
  final Map<String, bool> _userMfa = {};
  final Map<String, bool> _userBiometric = {};
  final Map<String, String> _userMfaMethodPref = {};
  final Map<String, String> _userTotpSecret = {};
  final Map<String, List<String>> _userBackupCodes = {};
  final Map<String, List<String>> _usedUserBackupCodes = {};
  final Set<String> _blockedUsers = {};
  bool _rememberMe = false;
  String? _rememberedEmail;
  String? _currentUser;
  bool _useDatabase = false;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  bool get useDatabase => _useDatabase;
  String? get currentUser => _currentUser;
  bool get rememberMe => _rememberMe;
  String? get rememberedEmail => _rememberedEmail;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    await _databaseService.initialize();
    await _loginAttemptsService.initialize();
    
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

  Future<void> _loadLocalData() async {
    try {
      _password = _prefs.getString(_passwordKey) ?? 'password';
      _rememberMe = _prefs.getBool(_rememberMeKey) ?? false;
      _rememberedEmail = _prefs.getString(_rememberedEmailKey);
      _currentUser = _prefs.getString(_currentUserKey);

      // Load users map
      final usersJson = _prefs.getString(_usersKey);
      if (usersJson != null && !usersJson.startsWith('enc1:')) {
        try {
          final Map<String, dynamic> usersMap = jsonDecode(usersJson);
          _users.clear();
          usersMap.forEach((key, value) => _users[key] = value.toString());
        } catch (e) {
          developer.log('Error parsing users JSON: $e', name: 'HybridAuthService');
          // Clear corrupted data
          await _prefs.remove(_usersKey);
        }
      }

      // Load security keys
      final securityKeysJson = _prefs.getString(_securityKeysKey);
      if (securityKeysJson != null && !securityKeysJson.startsWith('enc1:')) {
        try {
          final Map<String, dynamic> keysMap = jsonDecode(securityKeysJson);
          _securityKeys.clear();
          keysMap.forEach((key, value) => _securityKeys[key] = value.toString());
        } catch (e) {
          developer.log('Error parsing security keys JSON: $e', name: 'HybridAuthService');
          // Clear corrupted data
          await _prefs.remove(_securityKeysKey);
        }
      }
    } catch (e) {
      developer.log('Error in _loadLocalData: $e', name: 'HybridAuthService');
    }

    // Load other data...
    await _loadMfaData();
    await _loadBlockedUsers();
  }

  Future<void> _loadMfaData() async {
    try {
      // Load MFA enabled map
      final mfaJson = _prefs.getString(_mfaEnabledKey);
      if (mfaJson != null && !mfaJson.startsWith('enc1:')) {
        try {
          final Map<String, dynamic> mfaMap = jsonDecode(mfaJson);
          _userMfa.clear();
          mfaMap.forEach((key, value) => _userMfa[key] = value as bool);
        } catch (e) {
          developer.log('Error parsing MFA JSON: $e', name: 'HybridAuthService');
          await _prefs.remove(_mfaEnabledKey);
        }
      }

      // Load biometric enabled map
      final biometricJson = _prefs.getString(_biometricEnabledKey);
      if (biometricJson != null && !biometricJson.startsWith('enc1:')) {
        try {
          final Map<String, dynamic> bioMap = jsonDecode(biometricJson);
          _userBiometric.clear();
          bioMap.forEach((key, value) => _userBiometric[key] = value as bool);
        } catch (e) {
          developer.log('Error parsing biometric JSON: $e', name: 'HybridAuthService');
          await _prefs.remove(_biometricEnabledKey);
        }
      }
    } catch (e) {
      developer.log('Error in _loadMfaData: $e', name: 'HybridAuthService');
    }

      // Load MFA method preferences
      final mfaMethodJson = _prefs.getString(_mfaMethodPrefKey);
      if (mfaMethodJson != null && !mfaMethodJson.startsWith('enc1:')) {
        try {
          final Map<String, dynamic> methodMap = jsonDecode(mfaMethodJson);
          _userMfaMethodPref.clear();
          methodMap.forEach((key, value) => _userMfaMethodPref[key] = value.toString());
        } catch (e) {
          developer.log('Error parsing MFA method JSON: $e', name: 'HybridAuthService');
          await _prefs.remove(_mfaMethodPrefKey);
        }
      }
  }

  Future<void> _loadBlockedUsers() async {
    final blockedList = _prefs.getStringList(_blockedUsersKey) ?? [];
    _blockedUsers.clear();
    _blockedUsers.addAll(blockedList);
  }

  // Ensure default admin user exists
  Future<void> _ensureDefaultAdminUser() async {
    const adminEmail = 'env.hygiene@gmail.com';
    const adminPassword = 'password';
    
    // Always ensure admin user exists with correct password
    final hashedPassword = _hashPassword(adminPassword, adminEmail);
    _users[adminEmail] = hashedPassword;
    _securityKeys[adminEmail] = _generateSecurityKey();
    
    // Save to local storage
    await _saveUsers();
    await _saveSecurityKeys();
    
    developer.log('Default admin user ensured: $adminEmail with password hash: $hashedPassword', name: 'HybridAuthService');
    
    // Assign admin role to the default admin user
    try {
      final roleService = locator<RoleManagementService>();
      await roleService.assignRoleToUser(
        adminEmail, 
        adminEmail, 
        UserRole.superAdmin,
        assignedBy: 'system'
      );
      developer.log('Admin role assigned to default admin user', name: 'HybridAuthService');
    } catch (e) {
      developer.log('Could not assign admin role: $e', name: 'HybridAuthService');
    }
  }

  // Enable database mode
  Future<bool> enableDatabaseMode() async {
    final isHealthy = await _databaseService.isServerHealthy();
    if (!isHealthy) {
      return false;
    }

    _useDatabase = true;
    await _prefs.setBool(_useDatabaseKey, true);
    notifyListeners();
    return true;
  }

  // Disable database mode
  Future<void> disableDatabaseMode() async {
    _useDatabase = false;
    await _prefs.setBool(_useDatabaseKey, false);
    await _databaseService.clearAuthToken();
    notifyListeners();
  }

  // Migrate local data to database
  Future<Map<String, dynamic>> migrateToDatabase() async {
    if (!_useDatabase) {
      return {'success': false, 'error': 'Database mode not enabled'};
    }

    final results = <String, dynamic>{
      'migrated': 0,
      'failed': 0,
      'errors': <String>[],
    };

    // Migrate users
    for (final entry in _users.entries) {
      final email = entry.key;
      final password = entry.value;
      
      final result = await _databaseService.register(email, password);
      if (result['success']) {
        results['migrated']++;
      } else {
        results['failed']++;
        results['errors'].add('Failed to migrate $email: ${result['error']}');
      }
    }

    return {
      'success': true,
      'data': results,
    };
  }

  // Authentication methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    final e = email.toLowerCase();
    
    developer.log('Login attempt for: $e', name: 'HybridAuthService');
    
    // Check if user is locked due to failed attempts
    if (_loginAttemptsService.isInitialized) {
      final lockStatus = _loginAttemptsService.checkLoginAllowed(e);
      if (!lockStatus['allowed']) {
        await _loginAttemptsService.recordAttempt(
          email: e,
          successful: false,
        );
        developer.log('User $e is locked out', name: 'HybridAuthService');
        return {
          'success': false,
          'error': 'Account temporarily locked due to too many failed attempts',
          'lockoutMinutes': lockStatus['remainingLockoutTime'],
          'attemptsRemaining': 0,
        };
      }
    }
    
    bool loginSuccess = false;
    String? errorMessage;
    
    if (_useDatabase) {
      final result = await _databaseService.login(e, password);
      loginSuccess = result['success'];
      errorMessage = result['error'];
    } else {
      // Local authentication with proper password hashing
      final storedPasswordHash = _users[e];
      if (storedPasswordHash != null) {
        final passwordHash = _hashPassword(password, e);
        loginSuccess = storedPasswordHash == passwordHash;
        developer.log('Password check for $e: stored=$storedPasswordHash, computed=$passwordHash, match=$loginSuccess', name: 'HybridAuthService');
        
        // Debug: List all stored users
        developer.log('All stored users: ${_users.keys.toList()}', name: 'HybridAuthService');
        
        // Special handling for admin user - ensure it exists
        if (e == 'env.hygiene@gmail.com' && !loginSuccess) {
          developer.log('Admin login failed, re-ensuring admin user...', name: 'HybridAuthService');
          await _ensureDefaultAdminUser();
          // Retry with refreshed data
          final refreshedHash = _users[e];
          if (refreshedHash != null) {
            loginSuccess = refreshedHash == passwordHash;
            developer.log('Retry admin login: stored=$refreshedHash, computed=$passwordHash, match=$loginSuccess', name: 'HybridAuthService');
          }
        }
      } else {
        loginSuccess = false;
        errorMessage = 'User not found';
        developer.log('User $e not found in local storage', name: 'HybridAuthService');
        developer.log('Available users: ${_users.keys.toList()}', name: 'HybridAuthService');
      }
    }
    
    // Record the login attempt if service is initialized
    if (_loginAttemptsService.isInitialized) {
      await _loginAttemptsService.recordAttempt(
        email: e,
        successful: loginSuccess,
      );
      developer.log('Login attempt recorded for $e: success=$loginSuccess', name: 'HybridAuthService');
    }
    
    if (loginSuccess) {
      _currentUser = e;
      await _prefs.setString(_currentUserKey, e);
      if (_rememberMe) {
        await _prefs.setString(_rememberedEmailKey, e);
      }
      notifyListeners();
      developer.log('Login successful for $e', name: 'HybridAuthService');
      return {
        'success': true,
        'user': e,
      };
    } else {
      if (_loginAttemptsService.isInitialized) {
        final updatedLockStatus = _loginAttemptsService.checkLoginAllowed(e);
        return {
          'success': false,
          'error': errorMessage ?? 'Invalid email or password',
          'attemptsRemaining': updatedLockStatus['attemptsRemaining'],
          'failedAttempts': updatedLockStatus['failedAttempts'],
        };
      } else {
        return {
          'success': false,
          'error': errorMessage ?? 'Invalid email or password',
        };
      }
    }
  }

  Future<Map<String, dynamic>> register(String email, String password) async {
    final e = email.toLowerCase();
    
    if (_useDatabase) {
      final result = await _databaseService.register(e, password);
      if (result['success']) {
        _currentUser = e;
        await _prefs.setString(_currentUserKey, e);
        notifyListeners();
        return {'success': true, 'user': e};
      }
      return {'success': false, 'error': result['error']};
    } else {
      // Local registration
      if (_users.containsKey(e)) {
        return {'success': false, 'error': 'User already exists'};
      }
      
      // Hash the password before storing
      final hashedPassword = _hashPassword(password, e);
      _users[e] = hashedPassword;
      _securityKeys[e] = _generateSecurityKey();
      await _saveUsers();
      await _saveSecurityKeys();
      
      _currentUser = e;
      await _prefs.setString(_currentUserKey, e);
      notifyListeners();
      return {'success': true, 'user': e};
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await _prefs.remove(_currentUserKey);
    if (_useDatabase) {
      await _databaseService.clearAuthToken();
    }
    notifyListeners();
  }

  // User management methods
  List<String> getAllUsers() {
    return _users.keys.toList();
  }

  Future<List<Map<String, dynamic>>> getAllUsersDetailed() async {
    if (_useDatabase) {
      final result = await _databaseService.getAllUsers();
      if (result['success']) {
        return List<Map<String, dynamic>>.from(result['data']);
      }
      return [];
    } else {
      return _users.keys.map((email) => {
        'id': email,
        'email': email,
        'createdAt': DateTime.now().toIso8601String(),
        'blocked': _blockedUsers.contains(email),
      }).toList();
    }
  }

  Future<String> resetUserPassword(String email) async {
    final e = email.toLowerCase();
    
    if (_useDatabase) {
      final result = await _databaseService.resetUserPassword(e);
      if (result['success']) {
        return result['data']['newPassword'];
      }
      throw Exception(result['error']);
    } else {
      if (!_users.containsKey(e)) {
        throw Exception('User not found');
      }
      
      final newPassword = _generateRandomPassword();
      final hashedPassword = _hashPassword(newPassword, e);
      _users[e] = hashedPassword;
      await _saveUsers();
      
      // Clear any lockouts for this user
      await _loginAttemptsService.clearUserAttempts(e);
      
      notifyListeners();
      return newPassword;
    }
  }

  Future<void> updateUserPassword(String email, String newPassword) async {
    final e = email.toLowerCase();
    
    if (_useDatabase) {
      // For database mode, just reset the password (database doesn't have updatePassword)
      final result = await _databaseService.resetUserPassword(e);
      if (!result['success']) {
        throw Exception(result['error'] ?? 'Failed to update password');
      }
    } else {
      // If user doesn't exist, create them
      if (!_users.containsKey(e)) {
        _users[e] = _hashPassword(newPassword, e);
        _securityKeys[e] = _generateSecurityKey();
      } else {
        // Update existing user's password
        _users[e] = _hashPassword(newPassword, e);
      }
      await _saveUsers();
      await _saveSecurityKeys();
    }
    
    // Clear any lockouts for this user
    if (_loginAttemptsService.isInitialized) {
      await _loginAttemptsService.clearUserAttempts(e);
    }
    
    developer.log('Password updated for user $e', name: 'HybridAuthService');
    notifyListeners();
  }

  Future<void> blockUser(String email) async {
    final e = email.toLowerCase();
    
    if (_useDatabase) {
      // Find user ID first (simplified - in real app you'd have proper user lookup)
      final result = await _databaseService.blockUser(e);
      if (!result['success']) {
        throw Exception(result['error']);
      }
    } else {
      _blockedUsers.add(e);
      await _saveBlockedUsers();
    }
    notifyListeners();
  }

  Future<void> unblockUser(String email) async {
    final e = email.toLowerCase();
    
    if (_useDatabase) {
      final result = await _databaseService.unblockUser(e);
      if (!result['success']) {
        throw Exception(result['error']);
      }
    } else {
      _blockedUsers.remove(e);
      await _saveBlockedUsers();
    }
    notifyListeners();
  }

  bool isUserBlocked(String email) {
    return _blockedUsers.contains(email.toLowerCase());
  }

  bool isEmailRegistered(String email) {
    return _users.containsKey(email.toLowerCase());
  }

  String getSecurityKey(String email) {
    return _securityKeys[email.toLowerCase()] ?? '';
  }

  List<String> getBlockedUsers() {
    return _blockedUsers.toList();
  }

  // MFA and security methods (keeping local for now)
  bool isMfaEnabled(String email) {
    return _userMfa[email.toLowerCase()] ?? false;
  }

  bool isBiometricEnabled(String email) {
    return _userBiometric[email.toLowerCase()] ?? false;
  }

  String getMfaMethodPreference(String email) {
    return _userMfaMethodPref[email.toLowerCase()] ?? 'otp';
  }

  // Statistics methods
  int getMfaEnabledCount() => _userMfa.values.where((enabled) => enabled).length;
  int getBiometricEnabledCount() => _userBiometric.values.where((enabled) => enabled).length;
  int getBiometricPreferenceCount() => _userMfaMethodPref.values.where((pref) => pref == 'biometric').length;
  int getOtpPreferenceCount() => _userMfaMethodPref.values.where((pref) => pref == 'otp').length;
  int getTotpEnrolledCount() => _userTotpSecret.length;
  int getTotpPreferenceCount() => _userMfaMethodPref.values.where((pref) => pref == 'totp').length;

  // Private helper methods
  String _generateSecurityKey() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(16, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  String _generateRandomPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(12, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  /// Hash password with salt using SHA-256 (simplified for now)
  String _hashPassword(String password, String email) {
    // Use email as part of salt for uniqueness
    final saltedPassword = password + email + 'security_app_salt_2024';
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }


  /// Get login attempts service for admin access
  LoginAttemptsService get loginAttemptsService => _loginAttemptsService;

  /// Check if user account is locked
  bool isUserLocked(String email) {
    return _loginAttemptsService.checkIfUserLocked(email);
  }

  /// Get failed login attempts count
  int getFailedLoginAttempts(String email) {
    return _loginAttemptsService.getFailedAttemptsCount(email);
  }

  /// Unlock user account (admin function)
  Future<void> unlockUserAccount(String email) async {
    await _loginAttemptsService.unlockUser(email);
  }

  Future<void> _saveUsers() async {
    await _prefs.setString(_usersKey, jsonEncode(_users));
  }

  Future<void> _saveSecurityKeys() async {
    await _prefs.setString(_securityKeysKey, jsonEncode(_securityKeys));
  }

  Future<void> _saveBlockedUsers() async {
    await _prefs.setStringList(_blockedUsersKey, _blockedUsers.toList());
  }

  // Migration status
  Future<Map<String, dynamic>> getMigrationStatus() async {
    final localUserCount = _users.length;
    final databaseUserCount = _useDatabase ? (await getAllUsersDetailed()).length : 0;
    
    return {
      'useDatabase': _useDatabase,
      'localUsers': localUserCount,
      'databaseUsers': databaseUserCount,
      'serverHealthy': await _databaseService.isServerHealthy(),
    };
  }
}
