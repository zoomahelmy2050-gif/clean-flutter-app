import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class EnhancedBackupCodesService extends ChangeNotifier {
  final ApiService _apiService;
  static const String _codesKey = 'backup_codes';
  static const String _usedCodesKey = 'used_backup_codes';
  
  List<String> _backupCodes = [];
  Set<String> _usedCodes = {};
  bool _isLoading = false;
  String? _error;

  EnhancedBackupCodesService(this._apiService);

  List<String> get backupCodes => _backupCodes;
  Set<String> get usedCodes => _usedCodes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasBackupCodes => _backupCodes.isNotEmpty;
  int get remainingCodes => _backupCodes.length - _usedCodes.length;

  Future<List<String>> generateBackupCodes(String userId, {int count = 10}) async {
    _setLoading(true);
    _error = null;

    try {
      // Generate codes locally first
      final codes = _generateSecureCodes(count);
      
      // Send to backend for storage
      final response = await _apiService.post('/api/users/$userId/backup-codes', body: {
        'codes': codes.map((code) => _hashCode(code)).toList(),
      });

      if (response.isSuccess) {
        _backupCodes = codes;
        _usedCodes.clear();
        await _saveCodesToLocal();
        notifyListeners();
        return codes;
      } else {
        _error = response.error ?? 'Failed to generate backup codes';
        notifyListeners();
        return [];
      }
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
      return [];
    } finally {
      _setLoading(false);
    }
  }

  List<String> _generateSecureCodes(int count) {
    final random = Random.secure();
    final codes = <String>[];
    
    for (int i = 0; i < count; i++) {
      // Generate 8-character alphanumeric code
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      String code = '';
      for (int j = 0; j < 8; j++) {
        code += chars[random.nextInt(chars.length)];
      }
      // Format as XXXX-XXXX for better readability
      final formattedCode = '${code.substring(0, 4)}-${code.substring(4)}';
      codes.add(formattedCode);
    }
    
    return codes;
  }

  String _hashCode(String code) {
    final bytes = utf8.encode(code);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> verifyBackupCode(String userId, String code) async {
    try {
      final hashedCode = _hashCode(code.toUpperCase().replaceAll('-', '').replaceAll(' ', ''));
      
      final response = await _apiService.post('/api/users/$userId/backup-codes/verify', body: {
        'codeHash': hashedCode,
      });

      if (response.isSuccess) {
        _usedCodes.add(code);
        await _saveUsedCodesToLocal();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> loadBackupCodes(String userId) async {
    _setLoading(true);
    _error = null;

    try {
      // Load from local storage first
      await _loadCodesFromLocal();
      
      // Check with backend for status
      final response = await _apiService.get('/api/users/$userId/backup-codes/status');
      
      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final hasBackupCodes = data['hasBackupCodes'] ?? false;
        final usedCount = data['usedCount'] ?? 0;
        
        if (!hasBackupCodes) {
          _backupCodes.clear();
          _usedCodes.clear();
        }
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to load backup codes: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> revokeAllBackupCodes(String userId) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.delete('/api/users/$userId/backup-codes');
      
      if (response.isSuccess) {
        _backupCodes.clear();
        _usedCodes.clear();
        await _clearLocalStorage();
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Failed to revoke backup codes';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _saveCodesToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_codesKey, _backupCodes);
  }

  Future<void> _saveUsedCodesToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_usedCodesKey, _usedCodes.toList());
  }

  Future<void> _loadCodesFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    _backupCodes = prefs.getStringList(_codesKey) ?? [];
    final usedCodesList = prefs.getStringList(_usedCodesKey) ?? [];
    _usedCodes = Set.from(usedCodesList);
  }

  Future<void> _clearLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_codesKey);
    await prefs.remove(_usedCodesKey);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Utility methods
  bool isCodeUsed(String code) {
    return _usedCodes.contains(code);
  }

  List<String> getUnusedCodes() {
    // Count used codes for potential future use
    // final usedCount = codes.where((code) => code.isUsed).length;
    return _backupCodes.where((code) => !_usedCodes.contains(code)).toList();
  }

  double getUsagePercentage() {
    if (_backupCodes.isEmpty) return 0.0;
    return _usedCodes.length / _backupCodes.length;
  }

  bool shouldRegenerateCodes() {
    return getUsagePercentage() > 0.8; // Suggest regeneration when 80% used
  }
}
