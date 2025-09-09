import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:clean_flutter/core/services/crypto_service.dart';
import 'package:clean_flutter/core/services/secure_storage_service.dart';
import 'package:clean_flutter/core/services/enhanced_auth_service.dart';
import 'package:clean_flutter/locator.dart';
import 'package:clean_flutter/core/models/rbac_models.dart';

class AuthService with ChangeNotifier {
  static const _passwordKey = 'auth_password';
  static const _usersKey = 'auth_users_map'; // JSON map: email -> password
  static const _securityKeysKey =
      'auth_security_keys_map'; // JSON map: email -> securityKey
  static const _mfaEnabledKey = 'auth_user_mfa_map'; // JSON map: email -> bool
  static const _biometricEnabledKey =
      'auth_user_biometric_map'; // JSON map: email -> bool
  static const _mfaMethodPrefKey =
      'auth_user_mfa_method_pref_v2'; // JSON map: email -> 'otp' | 'biometric' | 'totp' | 'magic_link'
  static const _totpSecretsKey =
      'auth_user_totp_secret_v1'; // JSON map: email -> base32 secret
  static const _userBackupCodesKey =
      'auth_user_backup_codes_v1'; // JSON map: email -> List<String> of hashed codes
  static const _usedUserBackupCodesKey =
      'auth_used_user_backup_codes_v1'; // JSON map: email -> List<String> of used hashed codes
  static const _blockedUsersKey =
      'auth_blocked_users_v1'; // StringList of blocked emails (lowercased)
  static const _rememberMeKey = 'auth_remember_me';
  static const _rememberedEmailKey = 'auth_remembered_email';
  static const _currentUserKey = 'auth_current_user';
  static const _userRolesKey = 'auth_user_roles_v1'; // JSON map: email -> role
  late SharedPreferences _prefs;
  String _password = 'password';
  final Map<String, String> _users = {}; // in-memory cache
  final Map<String, String> _securityKeys = {}; // email -> securityKey
  final Map<String, bool> _userMfa = {}; // email -> mfaEnabled
  final Map<String, bool> _userBiometric =
      {}; // email -> biometric enabled on this device
  final Map<String, String> _userMfaMethodPref =
      {}; // email -> 'otp' | 'biometric' | 'totp' | 'magic_link'
  final Map<String, String> _userTotpSecret = {}; // email -> base32 secret
  final Map<String, List<String>> _userBackupCodes =
      {}; // email -> hashed backup codes
  final Map<String, List<String>> _usedUserBackupCodes =
      {}; // email -> used hashed backup codes
  final Set<String> _blockedUsers = {}; // lowercased blocked emails
  final Map<String, UserRole> _userRoles = {}; // email -> role
  bool _rememberMe = false;
  String? _rememberedEmail;
  String? _currentUser;
  late final CryptoService _crypto;
  late final SecureStorageService _secure;
  Uint8List? _masterKey;

  static const int maxAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 10);

  // Removed _failedAttempts and _lockoutTimestamps as they're now handled by EnhancedAuthService
  final List<String> _legacyRegisteredEmails = [
    'test@example.com',
    'user@example.com',
    'env.hygiene@gmail.com',
  ];

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _crypto = CryptoService();
    _secure = SecureStorageService();
    try {
      _masterKey = await _secure.getOrCreateMasterKey();
    } catch (e) {
      developer.log('Secure master key unavailable: $e', name: 'AuthService');
      _masterKey = null;
    }
    _password = _prefs.getString(_passwordKey) ?? 'password';
    // Load users map
    final usersJson = _prefs.getString(_usersKey);
    if (usersJson != null && usersJson.isNotEmpty) {
      try {
        final Map<String, dynamic> raw =
            jsonDecode(usersJson) as Map<String, dynamic>;
        _users
          ..clear()
          ..addAll(
            raw.map((k, v) => MapEntry(k.toLowerCase(), (v ?? '').toString())),
          );
      } catch (e) {
        developer.log('Failed to parse users map: $e', name: 'AuthService');
      }
      // Load security keys map
      final keysJson = _prefs.getString(_securityKeysKey);
      if (keysJson != null && keysJson.isNotEmpty) {
        try {
          if (keysJson.startsWith('enc1:') && _masterKey != null) {
            final payload =
                jsonDecode(keysJson.substring(5)) as Map<String, dynamic>;
            final Map<String, String> payloadStr = payload.map(
              (k, v) => MapEntry(k, (v ?? '').toString()),
            );
            final dec = await _crypto.decryptJson(
              payload: payloadStr,
              key: _masterKey!,
            );
            final Map<String, dynamic> raw = dec;
            _securityKeys
              ..clear()
              ..addAll(
                raw.map(
                  (k, v) => MapEntry(k.toLowerCase(), (v ?? '').toString()),
                ),
              );
          } else {
            final Map<String, dynamic> raw =
                jsonDecode(keysJson) as Map<String, dynamic>;
            _securityKeys
              ..clear()
              ..addAll(
                raw.map(
                  (k, v) => MapEntry(k.toLowerCase(), (v ?? '').toString()),
                ),
              );
          }
        } catch (e) {
          developer.log(
            'Failed to parse security keys map: $e',
            name: 'AuthService',
          );
        }
      }
      // Load per-user MFA enabled map
      final mfaJson = _prefs.getString(_mfaEnabledKey);
      if (mfaJson != null && mfaJson.isNotEmpty) {
        try {
          final Map<String, dynamic> raw =
              jsonDecode(mfaJson) as Map<String, dynamic>;
          _userMfa
            ..clear()
            ..addAll(raw.map((k, v) => MapEntry(k.toLowerCase(), v == true)));
        } catch (e) {
          developer.log('Failed to parse MFA map: $e', name: 'AuthService');
        }
      }
      // Load per-user biometric enabled map
      final bioJson = _prefs.getString(_biometricEnabledKey);
      if (bioJson != null && bioJson.isNotEmpty) {
        try {
          final Map<String, dynamic> raw =
              jsonDecode(bioJson) as Map<String, dynamic>;
          _userBiometric
            ..clear()
            ..addAll(raw.map((k, v) => MapEntry(k.toLowerCase(), v == true)));
        } catch (e) {
          developer.log(
            'Failed to parse biometric map: $e',
            name: 'AuthService',
          );
        }
      }
      // Load per-user MFA method preference
      final prefJson = _prefs.getString(_mfaMethodPrefKey);
      if (prefJson != null && prefJson.isNotEmpty) {
        try {
          final Map<String, dynamic> raw =
              jsonDecode(prefJson) as Map<String, dynamic>;
          _userMfaMethodPref
            ..clear()
            ..addAll(
              raw.map((k, v) {
                final val = (v as String?)?.toLowerCase();
                const allowed = {'otp', 'biometric', 'totp', 'magic_link'};
                return MapEntry(
                  k.toLowerCase(),
                  allowed.contains(val) ? val! : 'otp',
                );
              }),
            );
        } catch (e) {
          developer.log(
            'Failed to parse MFA method prefs: $e',
            name: 'AuthService',
          );
        }
      }
      // Load per-user TOTP secrets
      final totpJson = _prefs.getString(_totpSecretsKey);
      if (totpJson != null && totpJson.isNotEmpty) {
        try {
          if (totpJson.startsWith('enc1:') && _masterKey != null) {
            final payload =
                jsonDecode(totpJson.substring(5)) as Map<String, dynamic>;
            final Map<String, String> payloadStr = payload.map(
              (k, v) => MapEntry(k, (v ?? '').toString()),
            );
            final dec = await _crypto.decryptJson(
              payload: payloadStr,
              key: _masterKey!,
            );
            final Map<String, dynamic> raw = dec;
            _userTotpSecret
              ..clear()
              ..addAll(
                raw.map(
                  (k, v) => MapEntry(k.toLowerCase(), (v ?? '').toString()),
                ),
              );
          } else {
            final Map<String, dynamic> raw =
                jsonDecode(totpJson) as Map<String, dynamic>;
            _userTotpSecret
              ..clear()
              ..addAll(
                raw.map(
                  (k, v) => MapEntry(k.toLowerCase(), (v ?? '').toString()),
                ),
              );
          }
        } catch (e) {
          developer.log(
            'Failed to parse TOTP secrets: $e',
            name: 'AuthService',
          );
        }
      }
      // Load per-user backup codes
      final backupCodesJson = _prefs.getString(_userBackupCodesKey);
      if (backupCodesJson != null && backupCodesJson.isNotEmpty) {
        try {
          if (backupCodesJson.startsWith('enc1:') && _masterKey != null) {
            final payload =
                jsonDecode(backupCodesJson.substring(5))
                    as Map<String, dynamic>;
            final Map<String, String> payloadStr = payload.map(
              (k, v) => MapEntry(k, (v ?? '').toString()),
            );
            final dec = await _crypto.decryptJson(
              payload: payloadStr,
              key: _masterKey!,
            );
            final Map<String, dynamic> raw = dec;
            _userBackupCodes
              ..clear()
              ..addAll(
                raw.map(
                  (k, v) =>
                      MapEntry(k.toLowerCase(), List<String>.from(v as List)),
                ),
              );
          } else {
            final Map<String, dynamic> raw =
                jsonDecode(backupCodesJson) as Map<String, dynamic>;
            _userBackupCodes
              ..clear()
              ..addAll(
                raw.map(
                  (k, v) =>
                      MapEntry(k.toLowerCase(), List<String>.from(v as List)),
                ),
              );
          }
        } catch (e) {
          developer.log(
            'Failed to parse backup codes: $e',
            name: 'AuthService',
          );
        }
      }
      // Load per-user used backup codes
      final usedBackupCodesJson = _prefs.getString(_usedUserBackupCodesKey);
      if (usedBackupCodesJson != null && usedBackupCodesJson.isNotEmpty) {
        try {
          if (usedBackupCodesJson.startsWith('enc1:') && _masterKey != null) {
            final payload =
                jsonDecode(usedBackupCodesJson.substring(5))
                    as Map<String, dynamic>;
            final Map<String, String> payloadStr = payload.map(
              (k, v) => MapEntry(k, (v ?? '').toString()),
            );
            final dec = await _crypto.decryptJson(
              payload: payloadStr,
              key: _masterKey!,
            );
            final Map<String, dynamic> raw = dec;
            _usedUserBackupCodes
              ..clear()
              ..addAll(
                raw.map(
                  (k, v) =>
                      MapEntry(k.toLowerCase(), List<String>.from(v as List)),
                ),
              );
          } else {
            final Map<String, dynamic> raw =
                jsonDecode(usedBackupCodesJson) as Map<String, dynamic>;
            _usedUserBackupCodes
              ..clear()
              ..addAll(
                raw.map(
                  (k, v) =>
                      MapEntry(k.toLowerCase(), List<String>.from(v as List)),
                ),
              );
          }
        } catch (e) {
          developer.log(
            'Failed to parse used backup codes: $e',
            name: 'AuthService',
          );
        }
      }
      // Load blocked users
      final blocked = _prefs.getStringList(_blockedUsersKey);
      if (blocked != null) {
        _blockedUsers
          ..clear()
          ..addAll(blocked.map((e) => e.toLowerCase()));
      }
      // Load user roles
      final rolesJson = _prefs.getString(_userRolesKey);
      if (rolesJson != null && rolesJson.isNotEmpty) {
        try {
          final Map<String, dynamic> raw = jsonDecode(rolesJson) as Map<String, dynamic>;
          _userRoles
            ..clear()
            ..addAll(
              raw.map((k, v) {
                final roleStr = (v as String?)?.toLowerCase();
                UserRole role = UserRole.user;
                switch (roleStr) {
                  case 'superuser':
                    role = UserRole.superuser;
                    break;
                  case 'admin':
                    role = UserRole.admin;
                    break;
                  case 'staff':
                    role = UserRole.staff;
                    break;
                  default:
                    role = UserRole.user;
                }
                return MapEntry(k.toLowerCase(), role);
              }),
            );
        } catch (e) {
          developer.log('Failed to parse roles map: $e', name: 'AuthService');
        }
      }
      // Load remember-me state
      _rememberMe = _prefs.getBool(_rememberMeKey) ?? false;
      final remStr = _prefs.getString(_rememberedEmailKey);
      if (remStr != null && remStr.startsWith('enc1:') && _masterKey != null) {
        try {
          final payload =
              jsonDecode(remStr.substring(5)) as Map<String, dynamic>;
          final Map<String, String> payloadStr = payload.map(
            (k, v) => MapEntry(k, (v ?? '').toString()),
          );
          final dec = await _crypto.decryptJson(
            payload: payloadStr,
            key: _masterKey!,
          );
          _rememberedEmail = (dec['email'] as String?)?.toLowerCase();
        } catch (e) {
          developer.log(
            'Failed to decrypt remembered email: $e',
            name: 'AuthService',
          );
          _rememberedEmail = null;
        }
      } else {
        _rememberedEmail = remStr;
      }
      final curStr = _prefs.getString(_currentUserKey);
      if (curStr != null && curStr.startsWith('enc1:') && _masterKey != null) {
        try {
          final payload =
              jsonDecode(curStr.substring(5)) as Map<String, dynamic>;
          final Map<String, String> payloadStr = payload.map(
            (k, v) => MapEntry(k, (v ?? '').toString()),
          );
          final dec = await _crypto.decryptJson(
            payload: payloadStr,
            key: _masterKey!,
          );
          _currentUser = (dec['email'] as String?)?.toLowerCase();
        } catch (e) {
          developer.log(
            'Failed to decrypt current user: $e',
            name: 'AuthService',
          );
          _currentUser = null;
        }
      } else {
        _currentUser = curStr;
      }
    }
    // Seed legacy users if empty
    if (_users.isEmpty) {
      for (final e in _legacyRegisteredEmails) {
        _users[e.toLowerCase()] = _password; // use global password for legacy
      }
    }
    // Migrate old admin key to new email if present
    if (_users.containsKey('admin@example.com') &&
        !_users.containsKey('env.hygiene@gmail.com')) {
      _users['env.hygiene@gmail.com'] =
          _users['admin@example.com'] ?? 'password';
      _users.remove('admin@example.com');
    }
    // Ensure new admin user always exists
    if (!_users.containsKey('env.hygiene@gmail.com')) {
      _users['env.hygiene@gmail.com'] = 'password';
    }
    // Ensure every user has a security key
    for (final email in _users.keys) {
      _securityKeys.putIfAbsent(email, _generateSecurityKey);
      _userMfa.putIfAbsent(email, () => true); // default MFA enabled
      _userBiometric.putIfAbsent(
        email,
        () => false,
      ); // default biometrics disabled
      _userMfaMethodPref.putIfAbsent(email, () => 'otp'); // default preference
    }
    await _saveUsers();
    await _saveSecurityKeys();
    await _saveMfaEnabled();
    await _saveBiometricEnabled();
    await _saveMfaMethodPref();
    await _saveTotpSecrets();
    await _saveUserBackupCodes();
    await _saveUsedUserBackupCodes();
    await _saveBlockedUsers();
    developer.log(
      'AuthService initialized. Password loaded: "$_password"',
      name: 'AuthService',
    );
  }

  String get password => _password;

  Future<int> getRemainingAttempts(String email) async {
    // Delegate to enhanced auth service for advanced security tracking
    final enhancedAuth = locator<EnhancedAuthService>();
    final status = await enhancedAuth.checkLoginAllowed(
      email: email,
      ipAddress: '127.0.0.1',
    );
    return status['remainingAttempts'] ?? 0;
  }

  Future<bool> isLockedOut(String email) async {
    // Delegate to enhanced auth service for advanced security tracking
    final enhancedAuth = locator<EnhancedAuthService>();
    final status = await enhancedAuth.checkLoginAllowed(
      email: email,
      ipAddress: '127.0.0.1',
    );
    return !status['allowed'];
  }

  Future<Duration> getLockoutTimeRemaining(String email) async {
    // Delegate to enhanced auth service for advanced security tracking
    final enhancedAuth = locator<EnhancedAuthService>();
    final status = await enhancedAuth.checkLoginAllowed(
      email: email,
      ipAddress: '127.0.0.1',
    );
    final lockoutDuration = status['lockoutDuration'];
    return lockoutDuration != null ? Duration(seconds: lockoutDuration) : Duration.zero;
  }

  bool isEmailRegistered(String email) {
    // Check both local cache and enhanced auth service
    final enhancedAuth = locator<EnhancedAuthService>();
    return _users.containsKey(email.toLowerCase()) || enhancedAuth.isEmailRegistered(email);
  }

  Future<bool> register(String email, String password) async {
    final key = email.toLowerCase();
    if (_users.containsKey(key)) return false;
    
    try {
      // Use enhanced auth service for registration
      final enhancedAuth = locator<EnhancedAuthService>();
      final result = await enhancedAuth.register(email: email, password: password);
      final success = result['success'] == true;
      
      if (success == true) {
        // Update local cache
        _users[key] = await _crypto.computePasswordRecord(password);
        _securityKeys.putIfAbsent(key, _generateSecurityKey);
        _userMfa.putIfAbsent(key, () => true);
        await _saveUsers();
        await _saveSecurityKeys();
        await _saveMfaEnabled();
        developer.log('Registered new user: $key', name: 'AuthService');
        notifyListeners();
        return true;
      }
    } catch (e) {
      developer.log('Registration failed for $key: $e', name: 'AuthService');
      // Fallback to local registration
      _users[key] = await _crypto.computePasswordRecord(password);
      _securityKeys.putIfAbsent(key, _generateSecurityKey);
      _userMfa.putIfAbsent(key, () => true);
      await _saveUsers();
      await _saveSecurityKeys();
      await _saveMfaEnabled();
      developer.log('Registered new user locally: $key', name: 'AuthService');
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    // Delegate to EnhancedAuthService for secure authentication with advanced login security
    final enhancedAuth = locator<EnhancedAuthService>();
    final result = await enhancedAuth.login(
      email: email,
      password: password,
      ipAddress: '127.0.0.1', // Mock IP for local testing
      userAgent: 'Flutter App',
    );
    
    // If login successful, update current user in this service too
    if (result['success'] == true) {
      await setCurrentUser(email);
      developer.log('Login successful for $email via EnhancedAuthService.', name: 'AuthService');
    } else {
      developer.log('Login failed for $email: ${result['error']}', name: 'AuthService');
    }
    
    return result;
  }

  Future<bool> reauthenticateWithPassword(String email, String password) async {
    final e = email.toLowerCase();
    final stored = _users[e];
    if (stored == null) {
      return false;
    }
    
    // Check if this is a social user (Google or Facebook)
    if (stored == 'google') {
      developer.log(
        'Re-authentication attempted for Google user $email - password verification not applicable.',
        name: 'AuthService',
      );
      return false; // Google users don't have traditional passwords
    }
    
    if (stored == 'facebook') {
      developer.log(
        'Re-authentication attempted for Facebook user $email - password verification not applicable.',
        name: 'AuthService',
      );
      return false; // Facebook users don't have traditional passwords
    }
    
    if (await _verifyPasswordWithMigration(e, password, stored)) {
      developer.log(
        'Re-authentication successful for $email.',
        name: 'AuthService',
      );
      return true;
    }
    developer.log('Re-authentication failed for $email.', name: 'AuthService');
    return false;
  }

  bool isGoogleUser(String email) {
    final e = email.toLowerCase();
    final stored = _users[e];
    return stored == 'google';
  }

  bool isFacebookUser(String email) {
    final e = email.toLowerCase();
    final stored = _users[e];
    return stored == 'facebook';
  }

  bool isSocialUser(String email) {
    return isGoogleUser(email) || isFacebookUser(email);
  }

  // ========= Remember me helpers =========
  bool get rememberMe => _rememberMe;
  String? get rememberedEmail => _rememberedEmail;

  Future<void> setRememberedUser(String? email, bool remember) async {
    _rememberMe = remember;
    _rememberedEmail = remember ? email?.toLowerCase() : null;
    await _prefs.setBool(_rememberMeKey, _rememberMe);
    if (_rememberedEmail == null) {
      await _prefs.remove(_rememberedEmailKey);
    } else {
      if (_masterKey != null) {
        final enc = await _crypto.encryptJson(
          json: {'email': _rememberedEmail},
          key: _masterKey!,
        );
        await _prefs.setString(_rememberedEmailKey, 'enc1:' + jsonEncode(enc));
      } else {
        await _prefs.setString(_rememberedEmailKey, _rememberedEmail!);
      }
    }
    notifyListeners();
  }

  String? get currentUser => _currentUser;

  Future<void> setCurrentUser(String? email) async {
    _currentUser = email?.toLowerCase();
    if (_currentUser == null) {
      await _prefs.remove(_currentUserKey);
    } else {
      if (_masterKey != null) {
        final enc = await _crypto.encryptJson(
          json: {'email': _currentUser},
          key: _masterKey!,
        );
        await _prefs.setString(_currentUserKey, 'enc1:' + jsonEncode(enc));
      } else {
        await _prefs.setString(_currentUserKey, _currentUser!);
      }
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await setCurrentUser(null);
    // Optionally clear transient sensitive data from memory
    // Does not affect persisted encrypted stores
    // _securityKeys.clear(); // uncomment if you prefer not to keep in-memory cache
    // _userTotpSecret.clear();
    developer.log('User logged out.', name: 'AuthService');
  }

  // Trigger biometric auth (if available) and reload encrypted stores
  Future<bool> authenticateAndReloadSecureStores({
    String reason = 'Unlock secure data',
  }) async {
    final ok = await _secure.authenticate(reason: reason);
    if (!ok) return false;
    // Reload encrypted maps with master key
    try {
      // Security keys
      final keysJson = _prefs.getString(_securityKeysKey);
      if (keysJson != null &&
          keysJson.startsWith('enc1:') &&
          _masterKey != null) {
        final payload =
            jsonDecode(keysJson.substring(5)) as Map<String, dynamic>;
        final Map<String, String> payloadStr = payload.map(
          (k, v) => MapEntry(k, (v ?? '').toString()),
        );
        final dec = await _crypto.decryptJson(
          payload: payloadStr,
          key: _masterKey!,
        );
        final Map<String, dynamic> raw = dec;
        _securityKeys
          ..clear()
          ..addAll(
            raw.map((k, v) => MapEntry(k.toLowerCase(), (v ?? '').toString())),
          );
      }
      // TOTP secrets
      final totpJson = _prefs.getString(_totpSecretsKey);
      if (totpJson != null &&
          totpJson.startsWith('enc1:') &&
          _masterKey != null) {
        final payload =
            jsonDecode(totpJson.substring(5)) as Map<String, dynamic>;
        final Map<String, String> payloadStr = payload.map(
          (k, v) => MapEntry(k, (v ?? '').toString()),
        );
        final dec = await _crypto.decryptJson(
          payload: payloadStr,
          key: _masterKey!,
        );
        final Map<String, dynamic> raw = dec;
        _userTotpSecret
          ..clear()
          ..addAll(
            raw.map((k, v) => MapEntry(k.toLowerCase(), (v ?? '').toString())),
          );
      }
      notifyListeners();
      return true;
    } catch (e) {
      developer.log('Failed to reload secure stores: $e', name: 'AuthService');
      return false;
    }
  }

  // Method to check if the provided password is correct.
  bool verifyPassword(String password) {
    // Deprecated path (legacy global password); avoid logging sensitive data.
    return _password == password;
  }

  // Method to update the password.
  Future<void> updatePassword(String newPassword) async {
    developer.log('Updating legacy global password', name: 'AuthService');
    _password = newPassword;
    await _prefs.setString(_passwordKey, newPassword);
    notifyListeners();
  }

  /// Updates the password for a specific user identified by [email].
  /// The password is hashed before being stored. If the user does not exist,
  /// this is a no-op and returns false. Returns true on success.
  Future<bool> updateUserPassword(String email, String newPassword) async {
    final e = email.toLowerCase();
    
    // Update password in EnhancedAuthService which handles login
    final enhancedAuth = locator<EnhancedAuthService>();
    
    // Check if user exists in EnhancedAuthService
    if (!enhancedAuth.isEmailRegistered(e)) {
      developer.log(
        'updateUserPassword: user not found in EnhancedAuthService ($e)',
        name: 'AuthService',
      );
      return false;
    }
    
    // Update password in EnhancedAuthService
    await enhancedAuth.updateUserPassword(e, newPassword);
    
    // Also update in AuthService for consistency
    if (_users.containsKey(e)) {
      final record = await _crypto.computePasswordRecord(newPassword);
      _users[e] = record;
      await _saveUsers();
    }
    
    // Clear any login attempts/lockouts for this user using enhanced auth service
    await enhancedAuth.unlockUser(e);
    
    developer.log('Password updated for user $e in both services', name: 'AuthService');
    notifyListeners();
    return true;
  }

  // ========= Password hashing (v1 HMAC-SHA256 with random 16B salt) =========
  // v2 password records handled by CryptoService

  Future<bool> _verifyPasswordWithMigration(
    String email,
    String candidate,
    String stored,
  ) async {
    // v2 record
    if (stored.startsWith('v2:')) {
      return await _crypto.verifyPassword(candidate, stored);
    }
    // v1 record (HMAC with random salt)
    if (stored.startsWith('v1:')) {
      final parts = stored.split(':');
      if (parts.length != 3) return false;
      final salt = base64Decode(parts[1]);
      final hash = parts[2];
      final cand = Hmac(sha256, salt).convert(utf8.encode(candidate));
      final candB64 = base64Encode(cand.bytes);
      final ok = candB64 == hash;
      if (ok) {
        // migrate to v2
        _users[email] = await _crypto.computePasswordRecord(candidate);
        await _saveUsers();
      }
      return ok;
    }
    // Legacy plaintext: on success, migrate to v2
    if (stored == candidate) {
      _users[email] = await _crypto.computePasswordRecord(candidate);
      await _saveUsers();
      return true;
    }
    return false;
  }

  Future<void> _saveUsers() async {
    final jsonStr = jsonEncode(_users);
    await _prefs.setString(_usersKey, jsonStr);
  }

  Future<void> _saveSecurityKeys() async {
    try {
      final map = _securityKeys;
      if (_masterKey != null) {
        final enc = await _crypto.encryptJson(json: map, key: _masterKey!);
        await _prefs.setString(_securityKeysKey, 'enc1:' + jsonEncode(enc));
      } else {
        await _prefs.setString(_securityKeysKey, jsonEncode(map));
      }
    } catch (e) {
      developer.log('Failed to save security keys: $e', name: 'AuthService');
    }
  }

  Future<void> _saveMfaEnabled() async {
    final jsonStr = jsonEncode(_userMfa);
    await _prefs.setString(_mfaEnabledKey, jsonStr);
  }

  Future<void> _saveBiometricEnabled() async {
    final jsonStr = jsonEncode(_userBiometric);
    await _prefs.setString(_biometricEnabledKey, jsonStr);
  }

  Future<void> _saveMfaMethodPref() async {
    final jsonStr = jsonEncode(_userMfaMethodPref);
    await _prefs.setString(_mfaMethodPrefKey, jsonStr);
  }

  Future<void> _saveTotpSecrets() async {
    try {
      final map = _userTotpSecret;
      if (_masterKey != null) {
        final enc = await _crypto.encryptJson(json: map, key: _masterKey!);
        await _prefs.setString(_totpSecretsKey, 'enc1:' + jsonEncode(enc));
      } else {
        await _prefs.setString(_totpSecretsKey, jsonEncode(map));
      }
    } catch (e) {
      developer.log('Failed to save TOTP secrets: $e', name: 'AuthService');
    }
  }

  Future<void> _saveUserBackupCodes() async {
    try {
      final map = _userBackupCodes;
      if (_masterKey != null) {
        final enc = await _crypto.encryptJson(json: map, key: _masterKey!);
        await _prefs.setString(_userBackupCodesKey, 'enc1:' + jsonEncode(enc));
      } else {
        await _prefs.setString(_userBackupCodesKey, jsonEncode(map));
      }
    } catch (e) {
      developer.log('Failed to save backup codes: $e', name: 'AuthService');
    }
  }

  Future<void> _saveUsedUserBackupCodes() async {
    try {
      final map = _usedUserBackupCodes;
      if (_masterKey != null) {
        final enc = await _crypto.encryptJson(json: map, key: _masterKey!);
        await _prefs.setString(
          _usedUserBackupCodesKey,
          'enc1:' + jsonEncode(enc),
        );
      } else {
        await _prefs.setString(_usedUserBackupCodesKey, jsonEncode(map));
      }
    } catch (e) {
      developer.log(
        'Failed to save used backup codes: $e',
        name: 'AuthService',
      );
    }
  }

  Future<void> _saveBlockedUsers() async {
    final list = _blockedUsers.toList();
    print('💾 Saving blocked users to storage: $list');
    final success = await _prefs.setStringList(_blockedUsersKey, list);
    print('💾 Save result: $success');
    await _prefs.reload(); // Force reload to ensure persistence
  }

  // ========= MFA per-user helpers =========
  bool isUserMfaEnabled(String email) => _userMfa[email.toLowerCase()] ?? true;

  Future<void> setUserMfaEnabled(String email, bool enabled) async {
    _userMfa[email.toLowerCase()] = enabled;
    await _saveMfaEnabled();
    notifyListeners();
  }

  // ========= Biometrics per-user helpers =========
  bool isUserBiometricEnabled(String email) =>
      _userBiometric[email.toLowerCase()] ?? false;

  Future<void> setUserBiometricEnabled(String email, bool enabled) async {
    developer.log(
      'setUserBiometricEnabled called with email: $email, enabled: $enabled',
      name: 'AuthService',
    );
    _userBiometric[email.toLowerCase()] = enabled;
    developer.log('_userBiometric map updated: $_userBiometric', name: 'AuthService');
    await _saveBiometricEnabled();
    developer.log('_saveBiometricEnabled completed', name: 'AuthService');
    notifyListeners();
    developer.log('notifyListeners called', name: 'AuthService');
  }

  // ========= MFA method preference helpers =========
  String getUserMfaMethodPreference(String email) =>
      _userMfaMethodPref[email.toLowerCase()] ?? 'otp';

  Future<void> setUserMfaMethodPreference(String email, String method) async {
    final allowed = {'otp', 'biometric', 'totp', 'magic_link'};
    final m = allowed.contains(method) ? method : 'otp';
    _userMfaMethodPref[email.toLowerCase()] = m;
    await _saveMfaMethodPref();
    notifyListeners();
  }

  int getMfaEnabledCount() => _userMfa.values.where((e) => e).length;
  int getBiometricEnabledCount() =>
      _userBiometric.values.where((e) => e).length;
  int getBiometricPreferenceCount() =>
      _userMfaMethodPref.values.where((e) => e == 'biometric').length;
  int getOtpPreferenceCount() =>
      _userMfaMethodPref.values.where((e) => e == 'otp').length;
  int getTotpPreferenceCount() =>
      _userMfaMethodPref.values.where((e) => e == 'totp').length;
  int getMagicLinkPreferenceCount() =>
      _userMfaMethodPref.values.where((e) => e == 'magic_link').length;

  // ========= TOTP helpers =========
  bool isUserTotpEnrolled(String email) =>
      (_userTotpSecret[email.toLowerCase()] ?? '').isNotEmpty;

  String? getUserTotpSecret(String email) =>
      _userTotpSecret[email.toLowerCase()];

  Future<void> setUserTotpSecret(String email, String? base32Secret) async {
    final key = email.toLowerCase();
    if (base32Secret == null || base32Secret.isEmpty) {
      _userTotpSecret.remove(key);
    } else {
      _userTotpSecret[key] = base32Secret;
    }
    await _saveTotpSecrets();
    notifyListeners();
  }

  int getTotpEnrolledCount() =>
      _userTotpSecret.values.where((s) => (s).isNotEmpty).length;

  // ========= Blocked users helpers =========
  bool isUserBlocked(String email) {
    // Reload blocked users from storage to ensure we have latest data
    final blocked = _prefs.getStringList(_blockedUsersKey);
    if (blocked != null) {
      _blockedUsers
        ..clear()
        ..addAll(blocked.map((e) => e.toLowerCase()));
    }
    final isBlocked = _blockedUsers.contains(email.toLowerCase());
    print('🔍 Checking if $email is blocked: $isBlocked');
    print('📋 Current blocked users: ${_blockedUsers.toList()}');
    return isBlocked;
  }

  Future<void> blockUser(String email) async {
    final normalizedEmail = email.toLowerCase();
    print('🚫 Blocking user: $normalizedEmail');
    _blockedUsers.add(normalizedEmail);
    await _saveBlockedUsers();
    
    // Force immediate save and verify
    await _prefs.reload();
    final saved = _prefs.getStringList(_blockedUsersKey);
    print('✅ Blocked users saved to storage: $saved');
    
    notifyListeners();
  }

  Future<void> unblockUser(String email) async {
    _blockedUsers.remove(email.toLowerCase());
    await _saveBlockedUsers();
    notifyListeners();
  }
  
  Future<void> reloadBlockedUsers() async {
    print('🔄 Reloading blocked users from storage...');
    await _prefs.reload();
    final blocked = _prefs.getStringList(_blockedUsersKey);
    if (blocked != null) {
      _blockedUsers
        ..clear()
        ..addAll(blocked.map((e) => e.toLowerCase()));
      print('✅ Reloaded blocked users: ${_blockedUsers.toList()}');
    } else {
      print('⚠️ No blocked users found in storage');
    }
  }

  List<String> getBlockedUsers() => _blockedUsers.toList()..sort();

  String getSecurityKey(String email) {
    final key = email.toLowerCase();
    final existing = _securityKeys[key];
    if (existing != null && existing.isNotEmpty) return existing;
    final newKey = _generateSecurityKey();
    _securityKeys[key] = newKey;
    // Persist asynchronously; no need to await here
    _saveSecurityKeys();
    return newKey;
  }

  /// Regenerates and persists a new security key for the given email.
  /// Returns the new key, or throws if the user is not registered.
  Future<String> regenerateSecurityKey(String email) async {
    final e = email.toLowerCase();
    if (!_users.containsKey(e)) {
      throw StateError('Email is not registered');
    }
    final newKey = _generateSecurityKey();
    _securityKeys[e] = newKey;
    await _saveSecurityKeys();
    notifyListeners();
    return newKey;
  }

  String _generateSecurityKey() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no ambiguous chars
    final rnd = Random.secure();
    String block(int len) => List.generate(
      len,
      (_) => alphabet[rnd.nextInt(alphabet.length)],
    ).join();
    return '${block(4)}-${block(4)}';
  }

  /// Check if user has backup codes set up
  bool hasUserBackupCodes(String email) {
    final e = email.toLowerCase();
    final codes = _userBackupCodes[e];
    return codes != null && codes.isNotEmpty;
  }

  /// Check if user needs security setup (has no additional security methods beyond email/password)
  bool needsSecuritySetup(String email) {
    final e = email.toLowerCase();
    // A user needs additional security setup if they do not have TOTP or backup codes.
    // Biometrics are device-specific and not considered a primary remote recovery method.
    return !isUserTotpEnrolled(e) && !hasUserBackupCodes(e);
  }

  // ========= Backup Code Helpers =========

  String _hashBackupCode(String code) {
    // Normalize code by removing dashes and whitespace before hashing
    final bytes = utf8.encode(code.replaceAll('-', '').trim());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<List<String>> generateUserBackupCodes(String email) async {
    final e = email.toLowerCase();
    if (!_users.containsKey(e)) throw Exception('User not found');

    const int codeCount = 10;
    const int codeLength = 8;
    final codes = <String>[];
    final random = Random.secure();

    for (int i = 0; i < codeCount; i++) {
      String code = '';
      for (int j = 0; j < codeLength; j++) {
        code += random.nextInt(10).toString();
      }
      final formatted = '${code.substring(0, 4)}-${code.substring(4, 8)}';
      codes.add(formatted);
    }

    _userBackupCodes[e] = codes.map(_hashBackupCode).toList();
    _usedUserBackupCodes.remove(e); // Clear used codes on regeneration

    await _saveUserBackupCodes();
    await _saveUsedUserBackupCodes();
    notifyListeners();
    return codes;
  }

  Future<void> deleteUserBackupCodes(String email) async {
    final e = email.toLowerCase();
    _userBackupCodes.remove(e);
    _usedUserBackupCodes.remove(e);
    await _saveUserBackupCodes();
    await _saveUsedUserBackupCodes();
    notifyListeners();
  }

  Future<bool> verifyUserBackupCode(String email, String inputCode) async {
    final e = email.toLowerCase();
    final hashedInput = _hashBackupCode(inputCode);

    final availableCodes = _userBackupCodes[e] ?? [];
    if (!availableCodes.contains(hashedInput)) {
      return false; // Code does not exist
    }

    final usedCodes = _usedUserBackupCodes.putIfAbsent(e, () => []);
    if (usedCodes.contains(hashedInput)) {
      return false; // Code has already been used
    }

    usedCodes.add(hashedInput);
    await _saveUsedUserBackupCodes();
    notifyListeners();
    return true;
  }

  Future<Map<String, dynamic>> getUserBackupCodesStatus(String email) async {
    final e = email.toLowerCase();
    final totalCodes = _userBackupCodes[e] ?? [];
    final usedCodes = _usedUserBackupCodes[e] ?? [];
    final hasCodes = totalCodes.isNotEmpty;
    return {
      'total': totalCodes.length,
      'used': usedCodes.length,
      'remaining': totalCodes.length - usedCodes.length,
      'hasCodes': hasCodes,
    };
  }

  // ========= Role Management =========

  UserRole getUserRole(String email) {
    final e = email.toLowerCase();
    // Check for hardcoded superuser admin
    if (e == 'env.hygiene@gmail.com') {
      return UserRole.superuser;
    }
    
    final roleStr = _userRoles[e];
    if (roleStr == null) return UserRole.user;
    return UserRole.values.firstWhere((r) => r.name == roleStr, orElse: () => UserRole.user);
  }

  UserRole? getCurrentUserRole() {
    if (_currentUser == null) return null;
    return getUserRole(_currentUser!);
  }

  Future<void> setUserRole(String email, UserRole role) async {
    final e = email.toLowerCase();
    if (!_users.containsKey(e)) throw Exception('User not found');
    
    _userRoles[e] = role;
    await _saveUserRoles();
    notifyListeners();
  }

  Future<void> _saveUserRoles() async {
    final data = _userRoles.map((k, v) => MapEntry(k, v.name));
    await _prefs.setString(_userRolesKey, jsonEncode(data));
  }

  bool canPerformAction(String email, ActionType action) {
    final role = getUserRole(email);
    switch (action) {
      case ActionType.deleteUser:
        return role.canDelete();
      case ActionType.suspendUser:
        return role.level >= UserRole.admin.level;
      case ActionType.resetPassword:
        return role.level >= UserRole.staff.level;
      case ActionType.changeRole:
        return role.level >= UserRole.superuser.level;
      case ActionType.exportData:
        return role.level >= UserRole.admin.level;
      case ActionType.bulkDelete:
        return role.level >= UserRole.superuser.level;
    }
  }

  List<Map<String, dynamic>> getAllUsersWithRoles() {
    return _users.keys.map((email) => {
      'email': email,
      'role': getUserRole(email),
      'mfaEnabled': _userMfa[email] ?? false,
      'totpEnabled': isUserTotpEnrolled(email),
      'isBlocked': _blockedUsers.contains(email),
    }).toList();
  }

  // Additional methods for user management
  List<String> getAllUsers() {
    return _users.keys.toList();
  }

  Future<String> resetUserPassword(String email) async {
    final e = email.toLowerCase();
    if (!_users.containsKey(e)) {
      throw Exception('User not found');
    }
    
    // Generate a new random password
    final newPassword = _generateRandomPassword();
    _users[e] = newPassword;
    await _saveUsers();
    notifyListeners();
    return newPassword;
  }

  String _generateRandomPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(12, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }
}
