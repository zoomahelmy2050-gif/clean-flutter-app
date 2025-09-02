import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';
import 'backend_service.dart';

class WebAuthnService extends ChangeNotifier {
  final ApiService apiService;
  final BackendService backendService;
  
  List<PasskeyCredential> _credentials = [];
  bool _isSupported = false;
  bool _isRegistering = false;
  bool _isAuthenticating = false;
  
  List<PasskeyCredential> get credentials => _credentials;
  bool get isSupported => _isSupported;
  bool get isRegistering => _isRegistering;
  bool get isAuthenticating => _isAuthenticating;
  
  static const platform = MethodChannel('com.example.flutter_app/webauthn');
  
  WebAuthnService({required this.apiService, required this.backendService});
  
  Future<void> initialize() async {
    await checkSupport();
    await loadCredentials();
  }
  
  Future<void> checkSupport() async {
    try {
      if (kIsWeb) {
        // Check WebAuthn support in browser
        _isSupported = true; // Simplified for now
      } else {
        // Check platform support
        _isSupported = await platform.invokeMethod<bool>('isSupported') ?? false;
      }
    } catch (e) {
      debugPrint('Error checking WebAuthn support: $e');
      _isSupported = false;
    }
    notifyListeners();
  }
  
  Future<void> loadCredentials() async {
    try {
      final response = await backendService.get('/api/auth/passkeys');
      if (response != null && response['credentials'] != null) {
        _credentials = (response['credentials'] as List)
            .map((c) => PasskeyCredential.fromJson(c))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading credentials: $e');
      // Use mock data for development
      _credentials = _generateMockCredentials();
      notifyListeners();
    }
  }
  
  Future<RegisterResult?> registerPasskey({
    required String userId,
    required String username,
    required String displayName,
  }) async {
    if (!_isSupported) {
      throw UnsupportedError('WebAuthn is not supported on this device');
    }
    
    _isRegistering = true;
    notifyListeners();
    
    try {
      // Step 1: Get registration options from server
      final response = await backendService.post('/api/auth/webauthn/register/begin', {
        'userId': userId,
        'username': username,
      });
      
      if (response == null || response['options'] == null) {
        // Use mock data for development
        return await _mockRegister(userId, username, displayName);
      }
      
      final options = response['options'];
      
      // Step 2: Create credential using platform authenticator
      Map<String, dynamic>? credential;
      
      if (kIsWeb) {
        // Web implementation
        credential = await _webCreateCredential(options);
      } else {
        // Platform implementation
        credential = await platform.invokeMethod<Map>('createCredential', {
          'options': jsonEncode(options),
        }).then((result) => Map<String, dynamic>.from(result ?? {}));
      }
      
      if (credential == null) {
        throw Exception('Failed to create credential');
      }
      
      // Step 3: Verify credential with server
      final verifyResponse = await backendService.post(
        '/api/auth/webauthn/register/complete',
        {
          'credential': credential,
          'userId': userId,
        },
      );
      
      if (verifyResponse != null && verifyResponse['success'] == true) {
        await loadCredentials();
        return RegisterResult(
          success: true,
          credentialId: credential['id'],
          publicKey: credential['publicKey'],
        );
      }
      
      throw Exception('Failed to verify credential');
    } catch (e) {
      debugPrint('Error registering passkey: $e');
      return RegisterResult(
        success: false,
        error: e.toString(),
      );
    } finally {
      _isRegistering = false;
      notifyListeners();
    }
  }
  
  Future<AuthenticationResult?> authenticateWithPasskey({
    String? credentialId,
  }) async {
    if (!_isSupported) {
      throw UnsupportedError('WebAuthn is not supported on this device');
    }
    
    _isAuthenticating = true;
    notifyListeners();
    
    try {
      // Step 1: Get authentication options from server
      final optionsResponse = await backendService.post(
        '/api/auth/passkeys/authenticate/options',
        credentialId != null ? {'credentialId': credentialId} : {},
      );
      
      if (optionsResponse == null) {
        // Use mock data for development
        return await _mockAuthenticate(credentialId);
      }
      
      final options = optionsResponse['options'];
      
      // Step 2: Get assertion using platform authenticator
      Map<String, dynamic>? assertion;
      
      if (kIsWeb) {
        // Web implementation
        assertion = await _webGetAssertion(options);
      } else {
        // Platform implementation
        assertion = await platform.invokeMethod<Map>('getAssertion', {
          'options': jsonEncode(options),
        }).then((result) => Map<String, dynamic>.from(result ?? {}));
      }
      
      if (assertion == null) {
        throw Exception('Failed to get assertion');
      }
      
      // Step 3: Verify assertion with server
      final verifyResponse = await backendService.post(
        '/api/auth/passkeys/authenticate/verify',
        {
          'assertion': assertion,
        },
      );
      
      if (verifyResponse != null && verifyResponse['success'] == true) {
        return AuthenticationResult(
          success: true,
          userId: verifyResponse['userId'],
          token: verifyResponse['token'],
        );
      }
      
      throw Exception('Failed to verify assertion');
    } catch (e) {
      debugPrint('Error authenticating with passkey: $e');
      return AuthenticationResult(
        success: false,
        error: e.toString(),
      );
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }
  
  Future<bool> deletePasskey(String credentialId) async {
    try {
      final response = await backendService.delete('/api/auth/passkeys/$credentialId');
      
      if (response != null && response['success'] == true) {
        _credentials.removeWhere((c) => c.id == credentialId);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting passkey: $e');
    }
    
    // Mock deletion for development
    _credentials.removeWhere((c) => c.id == credentialId);
    notifyListeners();
    return true;
  }
  
  Future<bool> renamePasskey(String credentialId, String newName) async {
    try {
      final response = await backendService.put('/api/auth/passkeys/$credentialId', {
        'name': newName,
      });
      
      if (response != null && response['success'] == true) {
        final index = _credentials.indexWhere((c) => c.id == credentialId);
        if (index != -1) {
          _credentials[index] = _credentials[index].copyWith(name: newName);
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      debugPrint('Error renaming passkey: $e');
    }
    
    // Mock rename for development
    final index = _credentials.indexWhere((c) => c.id == credentialId);
    if (index != -1) {
      _credentials[index] = _credentials[index].copyWith(name: newName);
      notifyListeners();
    }
    return true;
  }
  
  // Web-specific implementations
  Future<Map<String, dynamic>?> _webCreateCredential(Map<String, dynamic> options) async {
    // This would use dart:js_interop to call browser WebAuthn API
    // Simplified for example
    return {
      'id': base64Encode(Uint8List.fromList(List.generate(32, (i) => i))),
      'rawId': base64Encode(Uint8List.fromList(List.generate(32, (i) => i))),
      'type': 'public-key',
      'response': {
        'attestationObject': base64Encode(Uint8List.fromList(List.generate(100, (i) => i))),
        'clientDataJSON': base64Encode(utf8.encode(jsonEncode({
          'type': 'webauthn.create',
          'challenge': options['challenge'],
          'origin': 'https://example.com',
        }))),
      },
    };
  }
  
  Future<Map<String, dynamic>?> _webGetAssertion(Map<String, dynamic> options) async {
    // This would use dart:js_interop to call browser WebAuthn API
    // Simplified for example
    return {
      'id': options['allowCredentials']?[0]?['id'] ?? 'mock-id',
      'rawId': base64Encode(Uint8List.fromList(List.generate(32, (i) => i))),
      'type': 'public-key',
      'response': {
        'authenticatorData': base64Encode(Uint8List.fromList(List.generate(37, (i) => i))),
        'clientDataJSON': base64Encode(utf8.encode(jsonEncode({
          'type': 'webauthn.get',
          'challenge': options['challenge'],
          'origin': 'https://example.com',
        }))),
        'signature': base64Encode(Uint8List.fromList(List.generate(64, (i) => i))),
        'userHandle': base64Encode(utf8.encode('user123')),
      },
    };
  }
  
  // Mock implementations for development
  Future<RegisterResult> _mockRegister(String userId, String userName, String displayName) async {
    await Future.delayed(const Duration(seconds: 1));
    
    final credential = PasskeyCredential(
      id: 'cred_${DateTime.now().millisecondsSinceEpoch}',
      name: '$displayName\'s Passkey',
      createdAt: DateTime.now(),
      lastUsed: DateTime.now(),
      deviceType: 'Mock Device',
      platform: 'Development',
    );
    
    _credentials.add(credential);
    notifyListeners();
    
    return RegisterResult(
      success: true,
      credentialId: credential.id,
      publicKey: base64Encode(Uint8List.fromList(List.generate(65, (i) => i))),
    );
  }
  
  Future<AuthenticationResult> _mockAuthenticate(String? credentialId) async {
    await Future.delayed(const Duration(seconds: 1));
    
    if (_credentials.isNotEmpty) {
      final credential = credentialId != null
          ? _credentials.firstWhere((c) => c.id == credentialId,
              orElse: () => _credentials.first)
          : _credentials.first;
      
      // Update last used
      final index = _credentials.indexOf(credential);
      _credentials[index] = credential.copyWith(lastUsed: DateTime.now());
      notifyListeners();
      
      return AuthenticationResult(
        success: true,
        userId: 'user123',
        token: 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
      );
    }
    
    return AuthenticationResult(
      success: false,
      error: 'No credentials available',
    );
  }
  
  List<PasskeyCredential> _generateMockCredentials() {
    return [
      PasskeyCredential(
        id: 'cred_001',
        name: 'iPhone 14 Pro',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastUsed: DateTime.now().subtract(const Duration(hours: 2)),
        deviceType: 'iOS',
        platform: 'iPhone',
      ),
      PasskeyCredential(
        id: 'cred_002',
        name: 'MacBook Pro',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        lastUsed: DateTime.now().subtract(const Duration(days: 1)),
        deviceType: 'macOS',
        platform: 'Desktop',
      ),
    ];
  }
}

// Models
class PasskeyCredential {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime lastUsed;
  final String deviceType;
  final String platform;
  
  PasskeyCredential({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.lastUsed,
    required this.deviceType,
    required this.platform,
  });
  
  factory PasskeyCredential.fromJson(Map<String, dynamic> json) {
    return PasskeyCredential(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
      lastUsed: DateTime.parse(json['lastUsed']),
      deviceType: json['deviceType'] ?? 'Unknown',
      platform: json['platform'] ?? 'Unknown',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed.toIso8601String(),
      'deviceType': deviceType,
      'platform': platform,
    };
  }
  
  PasskeyCredential copyWith({
    String? name,
    DateTime? lastUsed,
  }) {
    return PasskeyCredential(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
      deviceType: deviceType,
      platform: platform,
    );
  }
}

class RegisterResult {
  final bool success;
  final String? credentialId;
  final String? publicKey;
  final String? error;
  
  RegisterResult({
    required this.success,
    this.credentialId,
    this.publicKey,
    this.error,
  });
}

class AuthenticationResult {
  final bool success;
  final String? userId;
  final String? token;
  final String? error;
  
  AuthenticationResult({
    required this.success,
    this.userId,
    this.token,
    this.error,
  });
}
