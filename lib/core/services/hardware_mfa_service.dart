import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:developer' as developer;

class HardwareMfaService {
  static final HardwareMfaService _instance = HardwareMfaService._internal();
  factory HardwareMfaService() => _instance;
  HardwareMfaService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  final Map<String, SecurityKey> _registeredKeys = {};
  final Map<String, WebAuthnCredential> _credentials = {};
  final Map<String, BiometricTemplate> _biometricTemplates = {};
  final Map<String, AuthenticationSession> _activeSessions = {};
  final List<AuthenticationAttempt> _authenticationHistory = [];

  final StreamController<SecurityKeyEvent> _keyEventController = StreamController<SecurityKeyEvent>.broadcast();
  final StreamController<AuthenticationEvent> _authEventController = StreamController<AuthenticationEvent>.broadcast();

  Stream<SecurityKeyEvent> get keyEventStream => _keyEventController.stream;
  Stream<AuthenticationEvent> get authEventStream => _authEventController.stream;

  final Random _random = Random();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadStoredCredentials();
      await _setupHardwareDetection();
      
      _isInitialized = true;
      developer.log('Hardware MFA Service initialized', name: 'HardwareMfaService');
    } catch (e) {
      developer.log('Failed to initialize Hardware MFA Service: $e', name: 'HardwareMfaService');
      throw Exception('Hardware MFA Service initialization failed: $e');
    }
  }

  Future<void> _loadStoredCredentials() async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    _credentials['demo_yubikey'] = WebAuthnCredential(
      id: 'demo_yubikey',
      userId: 'user123',
      publicKey: 'demo_public_key_data',
      privateKey: 'demo_private_key_data',
      keyType: SecurityKeyType.yubikey,
      algorithm: 'ES256',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastUsed: DateTime.now().subtract(const Duration(hours: 2)),
    );
  }

  Future<void> _setupHardwareDetection() async {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      _detectConnectedDevices();
    });
  }

  Future<void> _detectConnectedDevices() async {
    final connectedKeys = await _scanForSecurityKeys();
    
    for (final key in connectedKeys) {
      if (!_registeredKeys.containsKey(key.id)) {
        _keyEventController.add(SecurityKeyEvent(
          type: SecurityKeyEventType.connected,
          keyId: key.id,
          keyType: key.type,
          timestamp: DateTime.now(),
        ));
      }
    }
  }

  Future<List<SecurityKey>> _scanForSecurityKeys() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final keys = <SecurityKey>[];
    
    if (_random.nextDouble() < 0.3) {
      keys.add(SecurityKey(
        id: 'yubikey_${_random.nextInt(1000)}',
        type: SecurityKeyType.yubikey,
        name: 'YubiKey 5 NFC',
        version: '5.2.7',
        isConnected: true,
        capabilities: [
          SecurityKeyCapability.webauthn,
          SecurityKeyCapability.u2f,
          SecurityKeyCapability.oath,
          SecurityKeyCapability.piv,
        ],
      ));
    }
    
    return keys;
  }

  Future<RegistrationResult> registerSecurityKey({
    required String userId,
    required String userName,
    required SecurityKeyType keyType,
    Map<String, dynamic>? options,
  }) async {
    try {
      final challenge = _generateChallenge();
      final session = AuthenticationSession(
        id: 'reg_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        challenge: challenge,
        type: AuthenticationType.registration,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );
      
      _activeSessions[session.id] = session;
      
      final credential = await _performRegistration(challenge, keyType, userId);
      _credentials[credential.id] = credential;
      
      _authEventController.add(AuthenticationEvent(
        type: AuthenticationEventType.registration,
        userId: userId,
        keyId: credential.id,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      return RegistrationResult(
        success: true,
        credentialId: credential.id,
        attestationObject: credential.attestationObject,
        clientDataJSON: credential.clientDataJSON,
      );
      
    } catch (e) {
      developer.log('Registration failed: $e', name: 'HardwareMfaService');
      return RegistrationResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<WebAuthnCredential> _performRegistration(String challenge, SecurityKeyType keyType, String userId) async {
    await Future.delayed(const Duration(seconds: 2));
    
    final credentialId = _generateCredentialId();
    final keyPair = _generateKeyPair();
    
    return WebAuthnCredential(
      id: credentialId,
      userId: userId,
      publicKey: keyPair['publicKey']!,
      privateKey: keyPair['privateKey']!,
      keyType: keyType,
      algorithm: 'ES256',
      createdAt: DateTime.now(),
      attestationObject: _generateAttestationObject(),
      clientDataJSON: _generateClientDataJSON(challenge),
    );
  }

  Future<AuthenticationResult> authenticateWithSecurityKey({
    required String userId,
    String? credentialId,
    Map<String, dynamic>? options,
  }) async {
    try {
      final challenge = _generateChallenge();
      final session = AuthenticationSession(
        id: 'auth_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        challenge: challenge,
        type: AuthenticationType.authentication,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );
      
      _activeSessions[session.id] = session;
      
      final userCredentials = _getUserCredentials(userId);
      if (userCredentials.isEmpty) {
        throw Exception('No registered security keys found for user');
      }
      
      final authResponse = await _performAuthentication(challenge, userCredentials);
      final isValid = await _verifySignature(authResponse, challenge);
      
      if (isValid) {
        final credential = _credentials[authResponse.credentialId];
        if (credential != null) {
          credential.lastUsed = DateTime.now();
          credential.signCount++;
        }
        
        _authenticationHistory.add(AuthenticationAttempt(
          userId: userId,
          credentialId: authResponse.credentialId,
          success: true,
          timestamp: DateTime.now(),
          ipAddress: '192.168.1.100',
          userAgent: 'Flutter App',
        ));
        
        _authEventController.add(AuthenticationEvent(
          type: AuthenticationEventType.authentication,
          userId: userId,
          keyId: authResponse.credentialId,
          success: true,
          timestamp: DateTime.now(),
        ));
        
        return AuthenticationResult(
          success: true,
          credentialId: authResponse.credentialId,
          userHandle: authResponse.userHandle,
          signature: authResponse.signature,
        );
      } else {
        throw Exception('Invalid signature');
      }
      
    } catch (e) {
      developer.log('Authentication failed: $e', name: 'HardwareMfaService');
      
      _authenticationHistory.add(AuthenticationAttempt(
        userId: userId,
        success: false,
        timestamp: DateTime.now(),
        error: e.toString(),
        ipAddress: '192.168.1.100',
        userAgent: 'Flutter App',
      ));
      
      return AuthenticationResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<AuthenticatorAssertionResponse> _performAuthentication(String challenge, List<WebAuthnCredential> credentials) async {
    await Future.delayed(const Duration(seconds: 3));
    
    final credential = credentials.first;
    final authenticatorData = _generateAuthenticatorData();
    final signature = _generateSignature(credential, challenge, authenticatorData);
    
    return AuthenticatorAssertionResponse(
      credentialId: credential.id,
      authenticatorData: authenticatorData,
      signature: signature,
      userHandle: credential.userId,
      clientDataJSON: _generateClientDataJSON(challenge),
    );
  }

  Future<BiometricAuthResult> authenticateWithBiometrics({
    required String userId,
    required BiometricType type,
  }) async {
    try {
      final template = _biometricTemplates[userId];
      if (template == null) {
        throw Exception('No biometric template found for user');
      }
      
      await Future.delayed(const Duration(seconds: 2));
      
      final capturedData = await _captureBiometricData(type);
      final matchScore = await _compareBiometricData(template, capturedData);
      
      final success = matchScore > 0.85;
      
      _authEventController.add(AuthenticationEvent(
        type: AuthenticationEventType.biometric,
        userId: userId,
        success: success,
        timestamp: DateTime.now(),
        metadata: {'biometric_type': type.toString(), 'match_score': matchScore},
      ));
      
      return BiometricAuthResult(
        success: success,
        matchScore: matchScore,
        biometricType: type,
      );
      
    } catch (e) {
      return BiometricAuthResult(
        success: false,
        error: e.toString(),
        biometricType: type,
      );
    }
  }

  Future<BiometricRegistrationResult> registerBiometric({
    required String userId,
    required BiometricType type,
  }) async {
    try {
      await Future.delayed(const Duration(seconds: 3));
      
      final templateData = await _captureBiometricTemplate(type);
      final template = BiometricTemplate(
        userId: userId,
        type: type,
        templateData: templateData,
        quality: 0.9 + _random.nextDouble() * 0.1,
        createdAt: DateTime.now(),
      );
      
      _biometricTemplates[userId] = template;
      
      return BiometricRegistrationResult(
        success: true,
        templateId: template.id,
        quality: template.quality,
      );
      
    } catch (e) {
      return BiometricRegistrationResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Helper methods
  String _generateChallenge() {
    final bytes = List<int>.generate(32, (i) => _random.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _generateCredentialId() {
    final bytes = List<int>.generate(16, (i) => _random.nextInt(256));
    return base64Url.encode(bytes);
  }

  Map<String, String> _generateKeyPair() {
    return {
      'publicKey': 'demo_public_key_${_random.nextInt(10000)}',
      'privateKey': 'demo_private_key_${_random.nextInt(10000)}',
    };
  }

  String _generateAttestationObject() {
    return 'demo_attestation_object_${_random.nextInt(10000)}';
  }

  String _generateClientDataJSON(String challenge) {
    final clientData = {
      'type': 'webauthn.create',
      'challenge': challenge,
      'origin': 'https://secure-app.com',
    };
    return base64Url.encode(utf8.encode(jsonEncode(clientData)));
  }

  String _generateAuthenticatorData() {
    return 'demo_authenticator_data_${_random.nextInt(10000)}';
  }

  String _generateSignature(WebAuthnCredential credential, String challenge, String authenticatorData) {
    return 'demo_signature_${credential.id}_${challenge.hashCode}';
  }

  List<WebAuthnCredential> _getUserCredentials(String userId) {
    return _credentials.values.where((cred) => cred.userId == userId).toList();
  }

  Future<bool> _verifySignature(AuthenticatorAssertionResponse response, String challenge) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _random.nextDouble() > 0.1; // 90% success rate for demo
  }

  Future<String> _captureBiometricData(BiometricType type) async {
    await Future.delayed(const Duration(seconds: 1));
    return 'biometric_data_${type.toString()}_${_random.nextInt(10000)}';
  }

  Future<String> _captureBiometricTemplate(BiometricType type) async {
    await Future.delayed(const Duration(seconds: 2));
    return 'biometric_template_${type.toString()}_${_random.nextInt(10000)}';
  }

  Future<double> _compareBiometricData(BiometricTemplate template, String capturedData) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 0.8 + _random.nextDouble() * 0.2; // 80-100% match score
  }

  // Public API methods
  List<SecurityKey> getRegisteredKeys(String userId) {
    return _registeredKeys.values.where((key) => key.userId == userId).toList();
  }

  List<WebAuthnCredential> getUserCredentialsList(String userId) {
    return _getUserCredentials(userId);
  }

  List<AuthenticationAttempt> getAuthenticationHistory(String userId) {
    return _authenticationHistory.where((attempt) => attempt.userId == userId).toList();
  }

  Map<String, dynamic> getHardwareMfaMetrics() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    
    final recentAttempts = _authenticationHistory.where((a) => a.timestamp.isAfter(last24Hours)).toList();
    final successfulAttempts = recentAttempts.where((a) => a.success).toList();
    
    return {
      'total_registered_keys': _registeredKeys.length,
      'total_credentials': _credentials.length,
      'biometric_templates': _biometricTemplates.length,
      'authentication_attempts_24h': recentAttempts.length,
      'successful_authentications_24h': successfulAttempts.length,
      'success_rate_24h': recentAttempts.isNotEmpty ? successfulAttempts.length / recentAttempts.length : 0.0,
      'active_sessions': _activeSessions.length,
      'supported_key_types': ['yubikey', 'fido2', 'smart_card'],
      'supported_biometrics': ['fingerprint', 'face', 'iris', 'voice'],
    };
  }

  void dispose() {
    _keyEventController.close();
    _authEventController.close();
  }
}

// Enums and Data Classes
enum SecurityKeyType { yubikey, fido2, smartCard, tpm }
enum SecurityKeyCapability { webauthn, u2f, oath, piv, openpgp }
enum SecurityKeyEventType { connected, disconnected, error }
enum AuthenticationType { registration, authentication }
enum AuthenticationEventType { registration, authentication, biometric }
enum BiometricType { fingerprint, face, iris, voice }

class SecurityKey {
  final String id;
  final SecurityKeyType type;
  final String name;
  final String version;
  final bool isConnected;
  final List<SecurityKeyCapability> capabilities;
  final String? userId;

  SecurityKey({
    required this.id,
    required this.type,
    required this.name,
    required this.version,
    required this.isConnected,
    required this.capabilities,
    this.userId,
  });
}

class WebAuthnCredential {
  final String id;
  final String userId;
  final String publicKey;
  final String privateKey;
  final SecurityKeyType keyType;
  final String algorithm;
  final DateTime createdAt;
  DateTime? lastUsed;
  int signCount;
  final String? attestationObject;
  final String? clientDataJSON;

  WebAuthnCredential({
    required this.id,
    required this.userId,
    required this.publicKey,
    required this.privateKey,
    required this.keyType,
    required this.algorithm,
    required this.createdAt,
    this.lastUsed,
    this.signCount = 0,
    this.attestationObject,
    this.clientDataJSON,
  });
}

class BiometricTemplate {
  final String id;
  final String userId;
  final BiometricType type;
  final String templateData;
  final double quality;
  final DateTime createdAt;

  BiometricTemplate({
    required this.userId,
    required this.type,
    required this.templateData,
    required this.quality,
    required this.createdAt,
  }) : id = 'bio_${DateTime.now().millisecondsSinceEpoch}';
}

class AuthenticationSession {
  final String id;
  final String userId;
  final String challenge;
  final AuthenticationType type;
  final DateTime createdAt;
  final DateTime expiresAt;

  AuthenticationSession({
    required this.id,
    required this.userId,
    required this.challenge,
    required this.type,
    required this.createdAt,
    required this.expiresAt,
  });
}

class AuthenticationAttempt {
  final String userId;
  final String? credentialId;
  final bool success;
  final DateTime timestamp;
  final String? error;
  final String ipAddress;
  final String userAgent;

  AuthenticationAttempt({
    required this.userId,
    this.credentialId,
    required this.success,
    required this.timestamp,
    this.error,
    required this.ipAddress,
    required this.userAgent,
  });
}

class SecurityKeyEvent {
  final SecurityKeyEventType type;
  final String keyId;
  final SecurityKeyType keyType;
  final DateTime timestamp;

  SecurityKeyEvent({
    required this.type,
    required this.keyId,
    required this.keyType,
    required this.timestamp,
  });
}

class AuthenticationEvent {
  final AuthenticationEventType type;
  final String userId;
  final String? keyId;
  final bool success;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  AuthenticationEvent({
    required this.type,
    required this.userId,
    this.keyId,
    required this.success,
    required this.timestamp,
    this.metadata,
  });
}

class RegistrationResult {
  final bool success;
  final String? credentialId;
  final String? attestationObject;
  final String? clientDataJSON;
  final String? error;

  RegistrationResult({
    required this.success,
    this.credentialId,
    this.attestationObject,
    this.clientDataJSON,
    this.error,
  });
}

class AuthenticationResult {
  final bool success;
  final String? credentialId;
  final String? userHandle;
  final String? signature;
  final String? error;

  AuthenticationResult({
    required this.success,
    this.credentialId,
    this.userHandle,
    this.signature,
    this.error,
  });
}

class BiometricAuthResult {
  final bool success;
  final double? matchScore;
  final BiometricType biometricType;
  final String? error;

  BiometricAuthResult({
    required this.success,
    this.matchScore,
    required this.biometricType,
    this.error,
  });
}

class BiometricRegistrationResult {
  final bool success;
  final String? templateId;
  final double? quality;
  final String? error;

  BiometricRegistrationResult({
    required this.success,
    this.templateId,
    this.quality,
    this.error,
  });
}

class AuthenticatorAssertionResponse {
  final String credentialId;
  final String authenticatorData;
  final String signature;
  final String userHandle;
  final String clientDataJSON;

  AuthenticatorAssertionResponse({
    required this.credentialId,
    required this.authenticatorData,
    required this.signature,
    required this.userHandle,
    required this.clientDataJSON,
  });
}
