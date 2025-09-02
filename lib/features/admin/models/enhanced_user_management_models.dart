// Enhanced User Management Models
class UserAccount {
  final String id;
  final String email;
  final String? name;
  final String status;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final String role;
  final bool isBlocked;
  final Map<String, dynamic>? metadata;
  
  UserAccount({
    required this.id,
    required this.email,
    this.name,
    required this.status,
    required this.createdAt,
    this.lastLogin,
    required this.role,
    this.isBlocked = false,
    this.metadata,
  });
  
  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      role: json['role'] ?? 'user',
      isBlocked: json['isBlocked'] ?? false,
      metadata: json['metadata'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'role': role,
      'isBlocked': isBlocked,
      'metadata': metadata,
    };
  }
}

class UserSession {
  final String id;
  final String userId;
  final String deviceInfo;
  final String ipAddress;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isActive;
  
  UserSession({
    required this.id,
    required this.userId,
    required this.deviceInfo,
    required this.ipAddress,
    required this.startTime,
    this.endTime,
    this.isActive = true,
  });
  
  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id'],
      userId: json['userId'],
      deviceInfo: json['deviceInfo'],
      ipAddress: json['ipAddress'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      isActive: json['isActive'] ?? true,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'deviceInfo': deviceInfo,
      'ipAddress': ipAddress,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isActive': isActive,
    };
  }
}

class AuditLog {
  final String id;
  final String userId;
  final String action;
  final String resource;
  final DateTime timestamp;
  final String? details;
  final String? ipAddress;
  
  AuditLog({
    required this.id,
    required this.userId,
    required this.action,
    required this.resource,
    required this.timestamp,
    this.details,
    this.ipAddress,
  });
  
  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'],
      userId: json['userId'],
      action: json['action'],
      resource: json['resource'],
      timestamp: DateTime.parse(json['timestamp']),
      details: json['details'],
      ipAddress: json['ipAddress'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'action': action,
      'resource': resource,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
      'ipAddress': ipAddress,
    };
  }
}
