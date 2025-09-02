import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:cryptography/cryptography.dart' as crypto;

class EncryptionService {
  static const String _keyStorageKey = 'encryption_master_key';
  static const String _saltStorageKey = 'encryption_salt';
  static const int _keyLength = 32; // 256 bits
  static const int _ivLength = 16; // 128 bits
  static const int _saltLength = 32; // 256 bits
  static const int _iterations = 100000; // PBKDF2 iterations
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  final Logger _logger = Logger();
  Encrypter? _encrypter;
  Key? _masterKey;
  
  /// Initialize encryption service
  Future<void> initialize({String? userPassword}) async {
    try {
      // Try to load existing master key
      final existingKey = await _secureStorage.read(key: _keyStorageKey);
      
      if (existingKey != null) {
        _masterKey = Key.fromBase64(existingKey);
      } else if (userPassword != null) {
        // Generate new master key from user password
        await _generateMasterKey(userPassword);
      } else {
        // Generate random master key
        await _generateRandomMasterKey();
      }
      
      if (_masterKey != null) {
        _encrypter = Encrypter(AES(_masterKey!));
        _logger.i('Encryption service initialized successfully');
      }
    } catch (e) {
      _logger.e('Failed to initialize encryption service: $e');
      throw Exception('Encryption initialization failed: $e');
    }
  }
  
  /// Generate master key from user password using PBKDF2
  Future<void> _generateMasterKey(String password) async {
    try {
      // Get or generate salt
      String? saltBase64 = await _secureStorage.read(key: _saltStorageKey);
      Uint8List salt;
      
      if (saltBase64 != null) {
        salt = base64Decode(saltBase64);
      } else {
        salt = _generateRandomBytes(_saltLength);
        await _secureStorage.write(key: _saltStorageKey, value: base64Encode(salt));
      }
      
      // Derive key using PBKDF2
      final pbkdf2 = crypto.Pbkdf2(
        macAlgorithm: crypto.Hmac.sha256(),
        iterations: _iterations,
        bits: _keyLength * 8,
      );
      
      final keyBytes = await pbkdf2.deriveKey(
        secretKey: crypto.SecretKey(utf8.encode(password)),
        nonce: salt,
      );
      
      final keyData = await keyBytes.extractBytes();
      _masterKey = Key(Uint8List.fromList(keyData));
      
      // Store encrypted master key
      await _secureStorage.write(
        key: _keyStorageKey,
        value: _masterKey!.base64,
      );
      
      _logger.i('Master key generated from password');
    } catch (e) {
      _logger.e('Failed to generate master key from password: $e');
      throw Exception('Key generation failed: $e');
    }
  }
  
  /// Generate random master key
  Future<void> _generateRandomMasterKey() async {
    try {
      final keyBytes = _generateRandomBytes(_keyLength);
      _masterKey = Key(keyBytes);
      
      await _secureStorage.write(
        key: _keyStorageKey,
        value: _masterKey!.base64,
      );
      
      _logger.i('Random master key generated');
    } catch (e) {
      _logger.e('Failed to generate random master key: $e');
      throw Exception('Random key generation failed: $e');
    }
  }
  
  /// Encrypt string data
  String encryptString(String plaintext) {
    if (_encrypter == null) {
      throw Exception('Encryption service not initialized');
    }
    
    try {
      final iv = IV.fromSecureRandom(_ivLength);
      final encrypted = _encrypter!.encrypt(plaintext, iv: iv);
      
      // Combine IV and encrypted data
      final combined = iv.bytes + encrypted.bytes;
      return base64Encode(combined);
    } catch (e) {
      _logger.e('String encryption failed: $e');
      throw Exception('Encryption failed: $e');
    }
  }
  
  /// Decrypt string data
  String decryptString(String encryptedData) {
    if (_encrypter == null) {
      throw Exception('Encryption service not initialized');
    }
    
    try {
      final combined = base64Decode(encryptedData);
      
      // Extract IV and encrypted data
      final iv = IV(Uint8List.fromList(combined.take(_ivLength).toList()));
      final encryptedBytes = combined.skip(_ivLength).toList();
      
      final encrypted = Encrypted(Uint8List.fromList(encryptedBytes));
      return _encrypter!.decrypt(encrypted, iv: iv);
    } catch (e) {
      _logger.e('String decryption failed: $e');
      throw Exception('Decryption failed: $e');
    }
  }
  
  /// Encrypt binary data
  Uint8List encryptBytes(Uint8List data) {
    if (_encrypter == null) {
      throw Exception('Encryption service not initialized');
    }
    
    try {
      final iv = IV.fromSecureRandom(_ivLength);
      final encrypted = _encrypter!.encryptBytes(data, iv: iv);
      
      // Combine IV and encrypted data
      final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
      combined.setRange(0, iv.bytes.length, iv.bytes);
      combined.setRange(iv.bytes.length, combined.length, encrypted.bytes);
      
      return combined;
    } catch (e) {
      _logger.e('Bytes encryption failed: $e');
      throw Exception('Encryption failed: $e');
    }
  }
  
  /// Decrypt binary data
  Uint8List decryptBytes(Uint8List encryptedData) {
    if (_encrypter == null) {
      throw Exception('Encryption service not initialized');
    }
    
    try {
      // Extract IV and encrypted data
      final iv = IV(encryptedData.sublist(0, _ivLength));
      final encryptedBytes = encryptedData.sublist(_ivLength);
      
      final encrypted = Encrypted(encryptedBytes);
      return Uint8List.fromList(_encrypter!.decryptBytes(encrypted, iv: iv));
    } catch (e) {
      _logger.e('Bytes decryption failed: $e');
      throw Exception('Decryption failed: $e');
    }
  }
  
  /// Encrypt file
  Future<void> encryptFile(String inputPath, String outputPath) async {
    try {
      final inputFile = File(inputPath);
      final outputFile = File(outputPath);
      
      if (!await inputFile.exists()) {
        throw Exception('Input file does not exist: $inputPath');
      }
      
      final data = await inputFile.readAsBytes();
      final encryptedData = encryptBytes(data);
      
      await outputFile.writeAsBytes(encryptedData);
      _logger.i('File encrypted: $inputPath -> $outputPath');
    } catch (e) {
      _logger.e('File encryption failed: $e');
      throw Exception('File encryption failed: $e');
    }
  }
  
  /// Decrypt file
  Future<void> decryptFile(String inputPath, String outputPath) async {
    try {
      final inputFile = File(inputPath);
      final outputFile = File(outputPath);
      
      if (!await inputFile.exists()) {
        throw Exception('Input file does not exist: $inputPath');
      }
      
      final encryptedData = await inputFile.readAsBytes();
      final decryptedData = decryptBytes(encryptedData);
      
      await outputFile.writeAsBytes(decryptedData);
      _logger.i('File decrypted: $inputPath -> $outputPath');
    } catch (e) {
      _logger.e('File decryption failed: $e');
      throw Exception('File decryption failed: $e');
    }
  }
  
  /// Encrypt JSON data
  String encryptJson(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    return encryptString(jsonString);
  }
  
  /// Decrypt JSON data
  Map<String, dynamic> decryptJson(String encryptedData) {
    final jsonString = decryptString(encryptedData);
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
  
  /// Generate secure hash of data
  String generateHash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Generate secure hash of file
  Future<String> generateFileHash(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File does not exist: $filePath');
    }
    
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Verify data integrity
  bool verifyHash(String data, String expectedHash) {
    final actualHash = generateHash(data);
    return actualHash == expectedHash;
  }
  
  /// Generate random bytes
  Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }
  
  /// Change master key password
  Future<void> changeMasterKeyPassword(String oldPassword, String newPassword) async {
    try {
      // Verify old password by attempting to derive the same key
      final oldSalt = base64Decode(await _secureStorage.read(key: _saltStorageKey) ?? '');
      final pbkdf2 = crypto.Pbkdf2(
        macAlgorithm: crypto.Hmac.sha256(),
        iterations: _iterations,
        bits: _keyLength * 8,
      );
      
      final oldKeyBytes = await pbkdf2.deriveKey(
        secretKey: crypto.SecretKey(utf8.encode(oldPassword)),
        nonce: oldSalt,
      );
      
      final oldKey = Key(Uint8List.fromList(await oldKeyBytes.extractBytes()));
      
      // Verify old key matches current key
      if (oldKey.base64 != _masterKey?.base64) {
        throw Exception('Invalid old password');
      }
      
      // Generate new key with new password
      await _generateMasterKey(newPassword);
      _encrypter = Encrypter(AES(_masterKey!));
      
      _logger.i('Master key password changed successfully');
    } catch (e) {
      _logger.e('Failed to change master key password: $e');
      throw Exception('Password change failed: $e');
    }
  }
  
  /// Clear encryption keys (logout)
  Future<void> clearKeys() async {
    try {
      _masterKey = null;
      _encrypter = null;
      _logger.i('Encryption keys cleared');
    } catch (e) {
      _logger.e('Failed to clear keys: $e');
    }
  }
  
  /// Check if encryption is ready
  bool get isReady => _encrypter != null && _masterKey != null;
  
  /// Get key strength indicator
  String get keyStrength {
    if (_masterKey == null) return 'Not initialized';
    return 'AES-256 with PBKDF2 ($_iterations iterations)';
  }
}
