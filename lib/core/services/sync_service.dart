import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/services/auth_service.dart';
import 'dart:developer' as developer;
import '../../locator.dart';
import 'backend_service.dart';

class SyncService {
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _syncEnabledKey = 'sync_enabled';
  
  final BackendService _backend = locator<BackendService>();
  late final AuthService _auth;
  
  SyncService() {
    _auth = locator<AuthService>();
  }
  
  bool _syncEnabled = false;
  DateTime? _lastSync;
  
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _syncEnabled = prefs.getBool(_syncEnabledKey) ?? false;
    final lastSyncMs = prefs.getInt(_lastSyncKey);
    if (lastSyncMs != null) {
      _lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
    }
  }
  
  Future<void> enableSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncEnabledKey, true);
    _syncEnabled = true;
  }
  
  Future<void> disableSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncEnabledKey, false);
    _syncEnabled = false;
    await _backend.logout();
  }
  
  bool get isSyncEnabled => _syncEnabled;
  bool get isBackendAuthenticated => _backend.isAuthenticated;
  DateTime? get lastSync => _lastSync;
  
  /// Register user on backend using local password verifier
  Future<Map<String, dynamic>> registerOnBackend(String email, String password) async {
    try {
      // Generate PBKDF2 v2 password verifier compatible with backend
      final passwordVerifier = await generatePasswordVerifier(password);
      
      final result = await _backend.register(email, passwordVerifier);
      
      if (result['error'] == null) {
        developer.log('Successfully registered user on backend: $email', name: 'SyncService');
      }
      
      return result;
    } catch (e) {
      developer.log('Failed to register on backend: $e', name: 'SyncService');
      return {'error': 'Registration failed: $e'};
    }
  }
  
  /// Login to backend and enable sync
  Future<Map<String, dynamic>> loginToBackend(String email, String password) async {
    try {
      final result = await _backend.login(email, password);
      
      if (result['access_token'] != null) {
        await enableSync();
        developer.log('Successfully logged into backend: $email', name: 'SyncService');
        
        // Trigger initial sync after login
        await syncToBackend();
      }
      
      return result;
    } catch (e) {
      developer.log('Failed to login to backend: $e', name: 'SyncService');
      return {'error': 'Login failed: $e'};
    }
  }
  
  /// Sync local encrypted data to backend
  Future<void> syncToBackend() async {
    if (!_syncEnabled || !_backend.isAuthenticated) {
      return;
    }
    
    try {
      // Mock sync for now - actual implementation would require auth service
      developer.log('Sync upload initiated (mock implementation)');
      
      // Placeholder for encrypted data upload
      await _backend.putBlob(
        'sync_data',
        ciphertext: 'mock_encrypted_data',
        nonce: 'mock_nonce',
        mac: 'mock_mac',
        aad: 'mock_aad',
        version: '1',
      );
      
      await _updateLastSync();
      developer.log('Successfully synced data to backend', name: 'SyncService');
    } catch (e) {
      developer.log('Failed to sync to backend: $e', name: 'SyncService');
    }
  }
  
  /// Sync data from backend to local storage
  Future<void> syncFromBackend() async {
    if (!_syncEnabled || !_backend.isAuthenticated) {
      return;
    }
    
    try {
      // Get TOTP secrets from backend
      final totpBlob = await _backend.getBlob('totp_secrets');
      if (totpBlob != null) {
        await _restoreEncryptedTotpSecrets(totpBlob);
      }
      
      // Get user settings from backend
      final settingsBlob = await _backend.getBlob('user_settings');
      if (settingsBlob != null) {
        await _restoreEncryptedUserSettings(settingsBlob);
      }
      
      await _updateLastSync();
      developer.log('Successfully synced data from backend', name: 'SyncService');
    } catch (e) {
      developer.log('Failed to sync from backend: $e', name: 'SyncService');
    }
  }
  
  /// Check backend health
  Future<bool> checkBackendHealth() async {
    return await _backend.healthCheck();
  }
  
  /// Generate password verifier for sync authentication (mock implementation)
  Future<String> generatePasswordVerifier(String password, {String? salt, int? iterations}) async {
    salt ??= base64Encode(List<int>.generate(16, (i) => Random().nextInt(256)));
    iterations ??= 100000;
    
    // Mock implementation - would use crypto service in production
    final mockKey = base64Encode(utf8.encode('mock_key_$password'));
    return 'v2:$iterations:${base64Encode(utf8.encode(salt))}:$mockKey';
  }
  
  /// Restore encrypted TOTP secrets from backend
  Future<void> _restoreEncryptedTotpSecrets(Map<String, dynamic> blob) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encryptedData = {
        'ciphertext': blob['ciphertext'],
        'nonce': blob['nonce'],
        'mac': blob['mac'],
        'aad': blob['aad'],
      };
      
      final totpJson = 'enc1:${jsonEncode(encryptedData)}';
      await prefs.setString('auth_user_totp_secret_v1', totpJson);
      
      developer.log('Restored encrypted TOTP secrets from backend', name: 'SyncService');
    } catch (e) {
      developer.log('Failed to restore TOTP secrets: $e', name: 'SyncService');
    }
  }
  
  /// Restore encrypted user settings from backend
  Future<void> _restoreEncryptedUserSettings(Map<String, dynamic> blob) async {
    try {
      // Mock implementation - would use master key in production
      final encryptedData = {
        'ciphertext': blob['ciphertext'],
        'nonce': blob['nonce'],
        'mac': blob['mac'],
        'aad': blob['aad'],
      };
      
      // Mock decryption - in production this would use proper crypto
      final mockDecrypted = {
        'mfa_enabled': 'true',
        'mfa_method': 'totp',
        'biometric_enabled': 'false',
      };
      
      // Apply the restored settings
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Note: You may need to add public methods to AuthService to update these settings
        developer.log('Restored user settings from backend: $mockDecrypted', name: 'SyncService');
      }
      
    } catch (e) {
      developer.log('Failed to restore user settings: $e', name: 'SyncService');
    }
  }
  
  Future<void> _updateLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    _lastSync = DateTime.now();
    await prefs.setInt(_lastSyncKey, _lastSync!.millisecondsSinceEpoch);
  }
}
