import 'package:clean_flutter/core/services/enhanced_rbac_service.dart';

class RoleTemplate {
  final String id;
  final String name;
  final String description;
  final UserRole role;
  final Set<Permission> permissions;
  final String category;
  final bool isCustom;
  final DateTime createdAt;
  final String createdBy;

  const RoleTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.role,
    required this.permissions,
    required this.category,
    this.isCustom = false,
    required this.createdAt,
    required this.createdBy,
  });

  factory RoleTemplate.fromJson(Map<String, dynamic> json) {
    return RoleTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      role: UserRole.values.firstWhere((r) => r.toString() == json['role']),
      permissions: (json['permissions'] as List)
          .map((p) => Permission.values.firstWhere((perm) => perm.toString() == p))
          .toSet(),
      category: json['category'],
      isCustom: json['isCustom'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: json['createdBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'role': role.toString(),
      'permissions': permissions.map((p) => p.toString()).toList(),
      'category': category,
      'isCustom': isCustom,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  RoleTemplate copyWith({
    String? id,
    String? name,
    String? description,
    UserRole? role,
    Set<Permission>? permissions,
    String? category,
    bool? isCustom,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return RoleTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      category: category ?? this.category,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
