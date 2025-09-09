import 'package:flutter/foundation.dart';

enum UserRole {
  guest,
  user,
  moderator,
  admin,
  superAdmin,
}

class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final UserRole role;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.role = UserRole.user,
    this.isEmailVerified = false,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
    this.metadata,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    UserRole? role,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role.name,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.user,
      ),
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName &&
        other.photoUrl == photoUrl &&
        other.role == role &&
        other.isEmailVerified == isEmailVerified &&
        other.createdAt == createdAt &&
        other.lastLoginAt == lastLoginAt &&
        other.isActive == isActive &&
        mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      email,
      displayName,
      photoUrl,
      role,
      isEmailVerified,
      createdAt,
      lastLoginAt,
      isActive,
      metadata,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName, role: $role, isActive: $isActive)';
  }
}
