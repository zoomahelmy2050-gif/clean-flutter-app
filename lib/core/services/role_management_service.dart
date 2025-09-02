import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum UserRole {
  superAdmin,
  admin,
  moderator,
  user,
  guest,
}

enum Permission {
  // User Management
  createUser,
  editUser,
  deleteUser,
  viewUsers,
  blockUser,
  unblockUser,
  
  // Role Management
  assignRoles,
  createRoles,
  editRoles,
  deleteRoles,
  
  // Security
  viewSecurityLogs,
  editSecuritySettings,
  manageBackups,
  viewAnalytics,
  
  // System
  systemSettings,
  databaseAccess,
  exportData,
  importData,
}

class RoleData {
  final String id;
  final String name;
  final String description;
  final List<Permission> permissions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSystemRole;
  final String color;

  RoleData({
    required this.id,
    required this.name,
    required this.description,
    required this.permissions,
    required this.createdAt,
    required this.updatedAt,
    this.isSystemRole = false,
    this.color = '#2196F3',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'permissions': permissions.map((p) => p.name).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isSystemRole': isSystemRole,
    'color': color,
  };

  factory RoleData.fromJson(Map<String, dynamic> json) => RoleData(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    permissions: (json['permissions'] as List)
        .map((p) => Permission.values.firstWhere((perm) => perm.name == p))
        .toList(),
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    isSystemRole: json['isSystemRole'] ?? false,
    color: json['color'] ?? '#2196F3',
  );
}

class UserRoleAssignment {
  final String userId;
  final String userEmail;
  final UserRole role;
  final List<String> customRoleIds;
  final DateTime assignedAt;
  final String assignedBy;
  final DateTime? expiresAt;

  UserRoleAssignment({
    required this.userId,
    required this.userEmail,
    required this.role,
    this.customRoleIds = const [],
    required this.assignedAt,
    required this.assignedBy,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userEmail': userEmail,
    'role': role.name,
    'customRoleIds': customRoleIds,
    'assignedAt': assignedAt.toIso8601String(),
    'assignedBy': assignedBy,
    'expiresAt': expiresAt?.toIso8601String(),
  };

  factory UserRoleAssignment.fromJson(Map<String, dynamic> json) => UserRoleAssignment(
    userId: json['userId'],
    userEmail: json['userEmail'],
    role: UserRole.values.firstWhere((r) => r.name == json['role']),
    customRoleIds: List<String>.from(json['customRoleIds'] ?? []),
    assignedAt: DateTime.parse(json['assignedAt']),
    assignedBy: json['assignedBy'],
    expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
  );
}

class RoleManagementService extends ChangeNotifier {
  static const String _rolesKey = 'custom_roles';
  static const String _assignmentsKey = 'role_assignments';
  
  List<RoleData> _customRoles = [];
  List<UserRoleAssignment> _roleAssignments = [];
  bool _isLoading = false;

  List<RoleData> get customRoles => _customRoles;
  List<UserRoleAssignment> get roleAssignments => _roleAssignments;
  bool get isLoading => _isLoading;

  // Default system roles
  static final Map<UserRole, RoleData> systemRoles = {
    UserRole.superAdmin: RoleData(
      id: 'super_admin',
      name: 'Super Administrator',
      description: 'Full system access with all permissions',
      permissions: Permission.values, // This includes ALL permissions
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSystemRole: true,
      color: '#F44336',
    ),
    UserRole.admin: RoleData(
      id: 'admin',
      name: 'Administrator',
      description: 'Administrative access with user and security management',
      permissions: [
        Permission.createUser,
        Permission.editUser,
        Permission.deleteUser,
        Permission.viewUsers,
        Permission.blockUser,
        Permission.unblockUser,
        Permission.assignRoles,
        Permission.viewSecurityLogs,
        Permission.editSecuritySettings,
        Permission.viewAnalytics,
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSystemRole: true,
      color: '#FF9800',
    ),
    UserRole.moderator: RoleData(
      id: 'moderator',
      name: 'Moderator',
      description: 'Content moderation and basic user management',
      permissions: [
        Permission.viewUsers,
        Permission.blockUser,
        Permission.unblockUser,
        Permission.viewSecurityLogs,
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSystemRole: true,
      color: '#4CAF50',
    ),
    UserRole.user: RoleData(
      id: 'user',
      name: 'User',
      description: 'Standard user with basic access',
      permissions: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSystemRole: true,
      color: '#2196F3',
    ),
    UserRole.guest: RoleData(
      id: 'guest',
      name: 'Guest',
      description: 'Limited access for temporary users',
      permissions: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSystemRole: true,
      color: '#9E9E9E',
    ),
  };

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadCustomRoles();
      await _loadRoleAssignments();
      
      // Automatically assign super admin role to admin email
      const adminEmail = 'env.hygiene@gmail.com';
      final hasAdminRole = _roleAssignments.any(
        (assignment) => assignment.userEmail.toLowerCase() == adminEmail.toLowerCase(),
      );
      
      if (!hasAdminRole) {
        await assignRoleToUser(
          adminEmail,
          adminEmail,
          UserRole.superAdmin,
          assignedBy: 'system',
        );
        debugPrint('Assigned Super Admin role to $adminEmail');
      }
    } catch (e) {
      debugPrint('Error initializing role management: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCustomRoles() async {
    final prefs = await SharedPreferences.getInstance();
    final rolesJson = prefs.getString(_rolesKey);
    
    if (rolesJson != null) {
      final rolesList = jsonDecode(rolesJson) as List;
      _customRoles = rolesList.map((json) => RoleData.fromJson(json)).toList();
    }
  }

  Future<void> _loadRoleAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    final assignmentsJson = prefs.getString(_assignmentsKey);
    
    if (assignmentsJson != null) {
      final assignmentsList = jsonDecode(assignmentsJson) as List;
      _roleAssignments = assignmentsList.map((json) => UserRoleAssignment.fromJson(json)).toList();
    }
  }

  Future<void> _saveCustomRoles() async {
    final prefs = await SharedPreferences.getInstance();
    final rolesJson = jsonEncode(_customRoles.map((role) => role.toJson()).toList());
    await prefs.setString(_rolesKey, rolesJson);
  }

  Future<void> _saveRoleAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    final assignmentsJson = jsonEncode(_roleAssignments.map((assignment) => assignment.toJson()).toList());
    await prefs.setString(_assignmentsKey, assignmentsJson);
  }

  // Role Management
  Future<bool> createCustomRole(RoleData role) async {
    try {
      _customRoles.add(role);
      await _saveCustomRoles();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error creating custom role: $e');
      return false;
    }
  }

  Future<bool> updateCustomRole(String roleId, RoleData updatedRole) async {
    try {
      final index = _customRoles.indexWhere((role) => role.id == roleId);
      if (index != -1) {
        _customRoles[index] = updatedRole;
        await _saveCustomRoles();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating custom role: $e');
      return false;
    }
  }

  Future<bool> deleteCustomRole(String roleId) async {
    try {
      _customRoles.removeWhere((role) => role.id == roleId);
      // Remove role assignments for deleted role
      _roleAssignments.forEach((assignment) {
        assignment.customRoleIds.remove(roleId);
      });
      await _saveCustomRoles();
      await _saveRoleAssignments();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting custom role: $e');
      return false;
    }
  }

  // User Role Assignment
  Future<bool> assignRoleToUser(String userId, String userEmail, UserRole role, {List<String>? customRoleIds, String? assignedBy, DateTime? expiresAt}) async {
    try {
      final existingIndex = _roleAssignments.indexWhere((assignment) => assignment.userId == userId);
      
      final assignment = UserRoleAssignment(
        userId: userId,
        userEmail: userEmail,
        role: role,
        customRoleIds: customRoleIds ?? [],
        assignedAt: DateTime.now(),
        assignedBy: assignedBy ?? 'system',
        expiresAt: expiresAt,
      );

      if (existingIndex != -1) {
        _roleAssignments[existingIndex] = assignment;
      } else {
        _roleAssignments.add(assignment);
      }

      await _saveRoleAssignments();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error assigning role to user: $e');
      return false;
    }
  }

  Future<bool> removeUserRole(String userId) async {
    try {
      _roleAssignments.removeWhere((assignment) => assignment.userId == userId);
      await _saveRoleAssignments();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error removing user role: $e');
      return false;
    }
  }

  // Permission Checking
  bool hasPermission(String userId, Permission permission) {
    final assignment = _roleAssignments.firstWhere(
      (assignment) => assignment.userId == userId,
      orElse: () => UserRoleAssignment(
        userId: userId,
        userEmail: '',
        role: UserRole.guest,
        assignedAt: DateTime.now(),
        assignedBy: 'system',
      ),
    );

    // Check if role assignment is expired
    if (assignment.expiresAt != null && assignment.expiresAt!.isBefore(DateTime.now())) {
      return false;
    }

    // Check system role permissions
    final systemRole = systemRoles[assignment.role];
    if (systemRole != null && systemRole.permissions.contains(permission)) {
      return true;
    }

    // Check custom role permissions
    for (final customRoleId in assignment.customRoleIds) {
      final customRole = _customRoles.firstWhere(
        (role) => role.id == customRoleId,
        orElse: () => RoleData(
          id: '',
          name: '',
          description: '',
          permissions: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      if (customRole.id.isNotEmpty && customRole.permissions.contains(permission)) {
        return true;
      }
    }

    return false;
  }

  UserRole getUserRole(String userId) {
    // Always return super admin for the admin email
    if (userId.toLowerCase() == 'env.hygiene@gmail.com') {
      return UserRole.superAdmin;
    }
    
    // Check by userId first
    var assignment = _roleAssignments.firstWhere(
      (assignment) => assignment.userId == userId,
      orElse: () => UserRoleAssignment(
        userId: '',
        userEmail: '',
        role: UserRole.user, // Default role is user instead of guest
        assignedAt: DateTime.now(),
        assignedBy: 'system',
      ),
    );
    
    // If not found by userId, try by email (userId might be the email)
    if (assignment.userId.isEmpty) {
      assignment = _roleAssignments.firstWhere(
        (assignment) => assignment.userEmail.toLowerCase() == userId.toLowerCase(),
        orElse: () => UserRoleAssignment(
          userId: userId,
          userEmail: userId,
          role: UserRole.user, // Default role is user
          assignedAt: DateTime.now(),
          assignedBy: 'system',
        ),
      );
    }
    
    return assignment.role;
  }

  List<RoleData> getAllRoles() {
    return [...systemRoles.values, ..._customRoles];
  }

  List<Permission> getUserPermissions(String userId) {
    final assignment = _roleAssignments.firstWhere(
      (assignment) => assignment.userId == userId,
      orElse: () => UserRoleAssignment(
        userId: userId,
        userEmail: '',
        role: UserRole.guest,
        assignedAt: DateTime.now(),
        assignedBy: 'system',
      ),
    );

    Set<Permission> permissions = {};

    // Add system role permissions
    final systemRole = systemRoles[assignment.role];
    if (systemRole != null) {
      permissions.addAll(systemRole.permissions);
    }

    // Add custom role permissions
    for (final customRoleId in assignment.customRoleIds) {
      final customRole = _customRoles.firstWhere(
        (role) => role.id == customRoleId,
        orElse: () => RoleData(
          id: '',
          name: '',
          description: '',
          permissions: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      if (customRole.id.isNotEmpty) {
        permissions.addAll(customRole.permissions);
      }
    }

    return permissions.toList();
  }

  // Analytics
  Map<String, int> getRoleDistribution() {
    final distribution = <String, int>{};
    
    for (final role in UserRole.values) {
      distribution[role.name] = _roleAssignments.where((assignment) => assignment.role == role).length;
    }
    
    for (final customRole in _customRoles) {
      final count = _roleAssignments.where((assignment) => assignment.customRoleIds.contains(customRole.id)).length;
      distribution[customRole.name] = count;
    }
    
    return distribution;
  }

  List<UserRoleAssignment> getExpiredRoleAssignments() {
    final now = DateTime.now();
    return _roleAssignments.where((assignment) => 
      assignment.expiresAt != null && assignment.expiresAt!.isBefore(now)
    ).toList();
  }

  Future<void> cleanupExpiredRoles() async {
    final now = DateTime.now();
    _roleAssignments.removeWhere((assignment) => 
      assignment.expiresAt != null && assignment.expiresAt!.isBefore(now)
    );
    await _saveRoleAssignments();
    notifyListeners();
  }
}
