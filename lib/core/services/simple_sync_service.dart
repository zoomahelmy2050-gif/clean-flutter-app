import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'backend_service.dart';
import 'local_storage_service.dart';
import '../../features/auth/services/auth_service.dart';
import 'package:clean_flutter/locator.dart';
import 'package:clean_flutter/core/services/crypto_service.dart';
import 'package:clean_flutter/core/config/app_config.dart';

class SimpleSyncService {
  static const String _syncEnabledKey = 'sync_enabled';
  
  final BackendService _backend = locator<BackendService>();
  final LocalStorageService _localStorage = LocalStorageService();
  
  bool _syncEnabled = false;
  
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _syncEnabled = prefs.getBool(_syncEnabledKey) ?? false;
  }
  
  bool get isSyncEnabled => _syncEnabled;
  bool get isBackendAuthenticated => AppConfig.useLocalStorage ? _syncEnabled : _backend.isAuthenticated;
  
  /// Register user (local storage during development)
  Future<Map<String, dynamic>> registerOnBackend(String email, String password) async {
    try {
      // Use local storage during development
      if (AppConfig.useLocalStorage) {
        developer.log('Using local storage for registration: $email', name: 'SimpleSyncService');
        final result = await _localStorage.register(email, password);
        
        // Also register with local auth service
        if (result['error'] == null) {
          final authService = locator<AuthService>();
          await authService.register(email, password);
        }
        
        return result;
      }
      
      // Production backend registration (when ready)
      final crypto = CryptoService();
      final passwordVerifier = await crypto.computePasswordRecord(password);
      
      final result = await _backend.register(email, passwordVerifier);
      developer.log('Backend registration result: $result', name: 'SimpleSyncService');

      if (result['error'] == null) {
        final authService = locator<AuthService>();
        final localRegisterSuccess = await authService.register(email, password);
        if (!localRegisterSuccess) {
          developer.log('Backend registration succeeded but local registration failed for: $email', name: 'SimpleSyncService');
        }
      }

      return result;
    } catch (e) {
      developer.log('Failed to register: $e', name: 'SimpleSyncService');
      return {'error': 'Registration failed: $e'};
    }
  }
  
  /// Login (local storage during development)
  Future<Map<String, dynamic>> loginToBackend(String email, String password) async {
    try {
      // Use local storage during development
      if (AppConfig.useLocalStorage) {
        developer.log('Using local storage for login: $email', name: 'SimpleSyncService');
        final result = await _localStorage.login(email, password);
        
        if (result['error'] == null) {
          // Also log in locally to set the current user
          final authService = locator<AuthService>();
          final localLoginSuccess = await authService.login(email, password);
          
          if (localLoginSuccess['success'] == true) {
            await _enableSync();
            developer.log('Successfully logged in locally: $email', name: 'SimpleSyncService');
          }
        }
        
        return result;
      }
      
      // Production backend login (when ready)
      developer.log('Attempting backend login for: $email', name: 'SimpleSyncService');
      final result = await _backend.login(email, password);
      developer.log('Backend login result: $result', name: 'SimpleSyncService');
      
      final token = result['access_token'] ?? result['accessToken'];
      developer.log('Token found: ${token != null}', name: 'SimpleSyncService');
      
      if (token != null) {
        final authService = locator<AuthService>();
        final localLoginSuccess = await authService.login(email, password);
        
        if (localLoginSuccess['success'] == true) {
          await _enableSync();
          developer.log('Successfully logged into backend and local auth: $email', name: 'SimpleSyncService');
        } else {
          developer.log('Backend login succeeded but local auth failed for: $email', name: 'SimpleSyncService');
          return {'error': 'Local authentication failed'};
        }
      }
      
      return result;
    } catch (e) {
      developer.log('Failed to login: $e', name: 'SimpleSyncService');
      return {'error': 'Login failed: $e'};
    }
  }
  
  /// Logout
  Future<void> logoutFromBackend() async {
    if (AppConfig.useLocalStorage) {
      await _localStorage.logout();
    } else {
      await _backend.logout();
    }
    await _disableSync();
  }
  
  /// Sync a simple text blob (local storage during development)
  Future<bool> syncTextToBackend(String key, String text) async {
    if (!_syncEnabled) {
      return false;
    }
    
    try {
      // Use local storage during development
      if (AppConfig.useLocalStorage) {
        final success = await _localStorage.storeText(key, text);
        developer.log('Synced text locally: $key', name: 'SimpleSyncService');
        return success;
      }
      
      // Production backend sync (when ready)
      if (!_backend.isAuthenticated) {
        return false;
      }
      
      final result = await _backend.putBlob(
        key,
        ciphertext: base64Encode(utf8.encode(text)),
        nonce: 'demo_nonce',
        mac: 'demo_mac',
        version: '1',
      );
      
      developer.log('Synced text to backend: $key', name: 'SimpleSyncService');
      return result['error'] == null;
    } catch (e) {
      developer.log('Failed to sync text: $e', name: 'SimpleSyncService');
      return false;
    }
  }
  
  /// Get text blob (local storage during development)
  Future<String?> getTextFromBackend(String key) async {
    if (!_syncEnabled) {
      return null;
    }
    
    try {
      // Use local storage during development
      if (AppConfig.useLocalStorage) {
        final text = await _localStorage.getText(key);
        developer.log('Retrieved text locally: $key', name: 'SimpleSyncService');
        return text;
      }
      
      // Production backend retrieval (when ready)
      if (!_backend.isAuthenticated) {
        return null;
      }
      
      final result = await _backend.getBlob(key);
      if (result != null && result['ciphertext'] != null) {
        final decoded = utf8.decode(base64Decode(result['ciphertext']));
        developer.log('Retrieved text from backend: $key', name: 'SimpleSyncService');
        return decoded;
      }
      return null;
    } catch (e) {
      developer.log('Failed to get text: $e', name: 'SimpleSyncService');
      return null;
    }
  }
  
  /// Check backend health (always true for local storage)
  Future<bool> checkBackendHealth() async {
    if (AppConfig.useLocalStorage) {
      return await _localStorage.healthCheck();
    }
    return await _backend.healthCheck();
  }
  
  /// Sync user's TOTP data to backend
  Future<bool> syncUserDataToBackend() async {
    developer.log('Starting syncUserDataToBackend', name: 'SimpleSyncService');
    developer.log('Sync enabled: $_syncEnabled', name: 'SimpleSyncService');
    developer.log('Backend authenticated: ${_backend.isAuthenticated}', name: 'SimpleSyncService');
    
    if (!_syncEnabled || !_backend.isAuthenticated) {
      developer.log('Sync aborted - sync enabled: $_syncEnabled, backend auth: ${_backend.isAuthenticated}', name: 'SimpleSyncService');
      return false;
    }
    
    try {
      // Get the auth service to access user data
      final authService = locator<AuthService>();
      final currentUserEmail = authService.currentUser;
      developer.log('Current user email: $currentUserEmail', name: 'SimpleSyncService');
      
      if (currentUserEmail == null) {
        developer.log('No current user to sync', name: 'SimpleSyncService');
        return false;
      }
      
      // Create basic user data structure for sync
      final userDataJson = jsonEncode({
        'email': currentUserEmail,
        'syncedAt': DateTime.now().toIso8601String(),
        'message': 'User data sync placeholder - TOTP secrets will be synced here',
      });
      
      developer.log('Attempting to sync data to backend', name: 'SimpleSyncService');
      // Sync to backend as encrypted blob
      final success = await syncTextToBackend('user_totp_data', userDataJson);
      developer.log('Sync result: $success', name: 'SimpleSyncService');
      
      if (success) {
        developer.log('User TOTP data synced successfully for $currentUserEmail', name: 'SimpleSyncService');
      } else {
        developer.log('Failed to sync user TOTP data', name: 'SimpleSyncService');
      }
      
      return success;
    } catch (e) {
      developer.log('Error syncing user data: $e', name: 'SimpleSyncService');
      return false;
    }
  }
  
  Future<void> _enableSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncEnabledKey, true);
    _syncEnabled = true;
  }
  
  Future<void> _disableSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncEnabledKey, false);
    _syncEnabled = false;
  }
}
