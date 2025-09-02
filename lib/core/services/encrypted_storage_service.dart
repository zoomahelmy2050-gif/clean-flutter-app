import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';

class EncryptedStorageService {
  static const _storage = FlutterSecureStorage();
  static const _keyPrefix = 'encrypted_';
  static const _masterKeyName = 'master_encryption_key';
  
  late final Key _encryptionKey;
  late final IV _iv;
  late final Encrypter _encrypter;
  
  static final EncryptedStorageService _instance = EncryptedStorageService._internal();
  factory EncryptedStorageService() => _instance;
  
  EncryptedStorageService._internal();
  
  Future<void> initialize() async {
    // Get or create master key
    String? masterKey = await _storage.read(key: _masterKeyName);
    if (masterKey == null) {
      // Generate new master key
      final key = Key.fromSecureRandom(32);
      masterKey = base64.encode(key.bytes);
      await _storage.write(key: _masterKeyName, value: masterKey);
    }
    
    _encryptionKey = Key(base64.decode(masterKey));
    _iv = IV.fromSecureRandom(16);
    _encrypter = Encrypter(AES(_encryptionKey));
  }
  
  /// Store encrypted data
  Future<void> storeSecure(String key, String value) async {
    final encrypted = _encrypter.encrypt(value, iv: _iv);
    await _storage.write(
      key: '$_keyPrefix$key',
      value: encrypted.base64,
    );
  }
  
  /// Store encrypted JSON object
  Future<void> storeSecureJson(String key, Map<String, dynamic> value) async {
    final jsonString = jsonEncode(value);
    await storeSecure(key, jsonString);
  }
  
  /// Retrieve and decrypt data
  Future<String?> getSecure(String key) async {
    final encryptedValue = await _storage.read(key: '$_keyPrefix$key');
    if (encryptedValue == null) return null;
    
    try {
      final encrypted = Encrypted.fromBase64(encryptedValue);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      print('Error decrypting value for key $key: $e');
      return null;
    }
  }
  
  /// Retrieve and decrypt JSON object
  Future<Map<String, dynamic>?> getSecureJson(String key) async {
    final decrypted = await getSecure(key);
    if (decrypted == null) return null;
    
    try {
      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      print('Error parsing JSON for key $key: $e');
      return null;
    }
  }
  
  /// Delete encrypted data
  Future<void> deleteSecure(String key) async {
    await _storage.delete(key: '$_keyPrefix$key');
  }
  
  /// Check if key exists
  Future<bool> hasSecure(String key) async {
    final value = await _storage.read(key: '$_keyPrefix$key');
    return value != null;
  }
  
  /// Get all encrypted keys
  Future<List<String>> getAllSecureKeys() async {
    final allKeys = await _storage.readAll();
    return allKeys.keys
        .where((key) => key.startsWith(_keyPrefix))
        .map((key) => key.substring(_keyPrefix.length))
        .toList();
  }
  
  /// Clear all encrypted data
  Future<void> clearAll() async {
    final keys = await getAllSecureKeys();
    for (final key in keys) {
      await deleteSecure(key);
    }
  }
  
  /// Backup encrypted data
  Future<String> exportEncryptedBackup(String password) async {
    final allKeys = await getAllSecureKeys();
    final backup = <String, String>{};
    
    for (final key in allKeys) {
      final value = await _storage.read(key: '$_keyPrefix$key');
      if (value != null) {
        backup[key] = value;
      }
    }
    
    // Encrypt backup with password
    final passwordKey = Key.fromBase64(
      base64.encode(sha256.convert(utf8.encode(password)).bytes),
    );
    final backupEncrypter = Encrypter(AES(passwordKey));
    final backupIv = IV.fromSecureRandom(16);
    
    final backupData = {
      'data': backup,
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
    
    final encrypted = backupEncrypter.encrypt(
      jsonEncode(backupData),
      iv: backupIv,
    );
    
    return jsonEncode({
      'encrypted': encrypted.base64,
      'iv': backupIv.base64,
    });
  }
  
  /// Restore from encrypted backup
  Future<void> importEncryptedBackup(String backupString, String password) async {
    try {
      final backupJson = jsonDecode(backupString) as Map<String, dynamic>;
      final encryptedData = backupJson['encrypted'] as String;
      final ivString = backupJson['iv'] as String;
      
      // Decrypt backup with password
      final passwordKey = Key.fromBase64(
        base64.encode(sha256.convert(utf8.encode(password)).bytes),
      );
      final backupEncrypter = Encrypter(AES(passwordKey));
      final backupIv = IV.fromBase64(ivString);
      
      final decrypted = backupEncrypter.decrypt(
        Encrypted.fromBase64(encryptedData),
        iv: backupIv,
      );
      
      final backupData = jsonDecode(decrypted) as Map<String, dynamic>;
      final data = backupData['data'] as Map<String, dynamic>;
      
      // Restore all encrypted data
      for (final entry in data.entries) {
        await _storage.write(
          key: '$_keyPrefix${entry.key}',
          value: entry.value,
        );
      }
    } catch (e) {
      throw Exception('Failed to import backup: $e');
    }
  }

  // Methods for BackgroundSyncService
  Future<Map<String, dynamic>?> exportAllData() async {
    final allKeys = await getAllSecureKeys();
    final data = <String, dynamic>{};
    
    for (final key in allKeys) {
      final value = await getSecure(key);
      if (value != null) {
        data[key] = value;
      }
    }
    
    return data.isNotEmpty ? data : null;
  }

  Future<void> importData(Map<String, dynamic> data) async {
    for (final entry in data.entries) {
      await storeSecure(entry.key, entry.value.toString());
    }
  }

  Future<Map<String, dynamic>> encryptData(Map<String, dynamic> data) async {
    final encrypted = <String, dynamic>{};
    for (final entry in data.entries) {
      final encryptedValue = _encrypter.encrypt(entry.value.toString(), iv: _iv);
      encrypted[entry.key] = encryptedValue.base64;
    }
    return encrypted;
  }
}
