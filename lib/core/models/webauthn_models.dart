// WebAuthn/Passkeys Models
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
