import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Role-Based Access Control Service
class RBACService extends ChangeNotifier {
  static final RBACService _instance = RBACService._internal();
  factory RBACService() => _instance;
  RBACService._internal();

  // Current user role and permissions
  UserRole? _currentRole;
  Set<Permission> _permissions = {};
  Map<String, dynamic> _customAttributes = {};
  
  UserRole? get currentRole => _currentRole;
  Set<Permission> get permissions => _permissions;
  Map<String, dynamic> get customAttributes => _customAttributes;
  
  // Role definitions with their permissions
  static final Map<UserRole, Set<Permission>> _rolePermissions = {
    UserRole.superAdmin: Permission.values.toSet(),
    UserRole.admin: {
      Permission.viewDashboard,
      Permission.viewSecurityCenter,
      Permission.viewAnalytics,
      Permission.viewReports,
      Permission.manageSecurity,
      Permission.manageUsers,
      Permission.viewAuditLogs,
      Permission.executePlaybooks,
      Permission.acknowledgeAlerts,
      Permission.viewThreats,
      Permission.mitigateThreats,
      Permission.exportData,
      Permission.configureSettings,
    },
    UserRole.securityAnalyst: {
      Permission.viewDashboard,
      Permission.viewSecurityCenter,
      Permission.viewAnalytics,
      Permission.viewReports,
      Permission.viewAuditLogs,
      Permission.executePlaybooks,
      Permission.acknowledgeAlerts,
      Permission.viewThreats,
      Permission.mitigateThreats,
    },
    UserRole.auditor: {
      Permission.viewDashboard,
      Permission.viewReports,
      Permission.viewAuditLogs,
      Permission.exportData,
      Permission.viewCompliance,
    },
    UserRole.viewer: {
      Permission.viewDashboard,
      Permission.viewReports,
      Permission.viewAnalytics,
    },
    UserRole.user: {
      Permission.viewProfile,
      Permission.editProfile,
      Permission.viewNotifications,
      Permission.changePassword,
    },
  };
  
  // Feature access mapping
  static final Map<String, Set<Permission>> _featurePermissions = {
    'security_orchestration': {Permission.viewSecurityCenter, Permission.executePlaybooks},
    'performance_monitoring': {Permission.viewAnalytics, Permission.viewDashboard},
    'emerging_threats': {Permission.viewThreats, Permission.mitigateThreats},
    'audit_trail': {Permission.viewAuditLogs},
    'user_management': {Permission.manageUsers},
    'compliance_reporting': {Permission.viewCompliance, Permission.viewReports},
    'vulnerability_scanning': {Permission.manageSecurity},
    'incident_response': {Permission.executePlaybooks, Permission.mitigateThreats},
    'security_analytics': {Permission.viewAnalytics},
    'threat_intelligence': {Permission.viewThreats},
    'export_features': {Permission.exportData},
    'system_configuration': {Permission.configureSettings},
  };
  
  /// Initialize RBAC with user role
  Future<void> initialize(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load user role from storage or API
    final roleString = prefs.getString('user_role_$userId') ?? 'user';
    _currentRole = UserRole.values.firstWhere(
      (role) => role.toString().split('.').last == roleString,
      orElse: () => UserRole.user,
    );
    
    // Load custom attributes
    final attributesJson = prefs.getString('user_attributes_$userId');
    if (attributesJson != null) {
      _customAttributes = json.decode(attributesJson);
    }
    
    // Set permissions based on role
    _permissions = _rolePermissions[_currentRole] ?? {};
    
    // Load any custom permissions
    final customPermissions = prefs.getStringList('custom_permissions_$userId');
    if (customPermissions != null) {
      for (final perm in customPermissions) {
        final permission = Permission.values.firstWhere(
          (p) => p.toString() == perm,
          orElse: () => Permission.viewProfile,
        );
        _permissions.add(permission);
      }
    }
    
    notifyListeners();
  }
  
  /// Check if user has permission
  bool hasPermission(Permission permission) {
    return _permissions.contains(permission);
  }
  
  /// Check if user has any of the permissions
  bool hasAnyPermission(Set<Permission> permissions) {
    return permissions.any((p) => hasPermission(p));
  }
  
  /// Check if user has all permissions
  bool hasAllPermissions(Set<Permission> permissions) {
    return permissions.every((p) => hasPermission(p));
  }
  
  /// Check if user can access a feature
  bool canAccessFeature(String featureName) {
    final requiredPermissions = _featurePermissions[featureName];
    if (requiredPermissions == null) return true; // No restrictions
    return hasAnyPermission(requiredPermissions);
  }
  
  /// Update user role (admin only)
  Future<bool> updateUserRole(String userId, UserRole newRole) async {
    if (!hasPermission(Permission.manageUsers)) {
      return false;
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role_$userId', newRole.toString().split('.').last);
    
    if (userId == await _getCurrentUserId()) {
      _currentRole = newRole;
      _permissions = _rolePermissions[newRole] ?? {};
      notifyListeners();
    }
    
    return true;
  }
  
  /// Grant custom permission to user
  Future<bool> grantPermission(String userId, Permission permission) async {
    if (!hasPermission(Permission.manageUsers)) {
      return false;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final customPermissions = prefs.getStringList('custom_permissions_$userId') ?? [];
    
    if (!customPermissions.contains(permission.toString())) {
      customPermissions.add(permission.toString());
      await prefs.setStringList('custom_permissions_$userId', customPermissions);
      
      if (userId == await _getCurrentUserId()) {
        _permissions.add(permission);
        notifyListeners();
      }
    }
    
    return true;
  }
  
  /// Revoke custom permission from user
  Future<bool> revokePermission(String userId, Permission permission) async {
    if (!hasPermission(Permission.manageUsers)) {
      return false;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final customPermissions = prefs.getStringList('custom_permissions_$userId') ?? [];
    
    customPermissions.remove(permission.toString());
    await prefs.setStringList('custom_permissions_$userId', customPermissions);
    
    if (userId == await _getCurrentUserId()) {
      _permissions.remove(permission);
      notifyListeners();
    }
    
    return true;
  }
  
  /// Set custom attribute for user
  Future<void> setAttribute(String key, dynamic value) async {
    _customAttributes[key] = value;
    
    final prefs = await SharedPreferences.getInstance();
    final userId = await _getCurrentUserId();
    await prefs.setString('user_attributes_$userId', json.encode(_customAttributes));
    
    notifyListeners();
  }
  
  /// Get custom attribute
  T? getAttribute<T>(String key) {
    return _customAttributes[key] as T?;
  }
  
  /// Check if user has specific attribute value
  bool hasAttributeValue(String key, dynamic value) {
    return _customAttributes[key] == value;
  }
  
  /// Get current user ID (mock implementation)
  Future<String> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_user_id') ?? 'default_user';
  }
  
  /// Clear all RBAC data
  Future<void> clear() async {
    _currentRole = null;
    _permissions.clear();
    _customAttributes.clear();
    notifyListeners();
  }
  
  /// Get role display name
  String getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super Administrator';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.securityAnalyst:
        return 'Security Analyst';
      case UserRole.auditor:
        return 'Auditor';
      case UserRole.viewer:
        return 'Viewer';
      case UserRole.user:
        return 'Standard User';
    }
  }
  
  /// Get permission display name
  String getPermissionDisplayName(Permission permission) {
    final name = permission.toString().split('.').last;
    // Convert camelCase to Title Case
    return name.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => ' ${match.group(0)}',
    ).trim().split(' ').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }
  
  /// Get feature restrictions for current user
  Map<String, bool> getFeatureAccess() {
    final access = <String, bool>{};
    for (final feature in _featurePermissions.keys) {
      access[feature] = canAccessFeature(feature);
    }
    return access;
  }
  
  /// Audit log for permission changes
  Future<void> _logPermissionChange(String action, String userId, String details) async {
    final prefs = await SharedPreferences.getInstance();
    final logs = prefs.getStringList('rbac_audit_logs') ?? [];
    
    final logEntry = json.encode({
      'timestamp': DateTime.now().toIso8601String(),
      'action': action,
      'userId': userId,
      'details': details,
      'performedBy': await _getCurrentUserId(),
    });
    
    logs.add(logEntry);
    
    // Keep only last 1000 entries
    if (logs.length > 1000) {
      logs.removeRange(0, logs.length - 1000);
    }
    
    await prefs.setStringList('rbac_audit_logs', logs);
  }
}

/// User roles enumeration
enum UserRole {
  superAdmin,
  admin,
  securityAnalyst,
  auditor,
  viewer,
  user,
}

/// Permissions enumeration
enum Permission {
  // View permissions
  viewDashboard,
  viewSecurityCenter,
  viewAnalytics,
  viewReports,
  viewAuditLogs,
  viewThreats,
  viewCompliance,
  viewProfile,
  viewNotifications,
  
  // Manage permissions
  manageSecurity,
  manageUsers,
  manageSettings,
  
  // Action permissions
  executePlaybooks,
  acknowledgeAlerts,
  mitigateThreats,
  exportData,
  configureSettings,
  
  // User permissions
  editProfile,
  changePassword,
}

/// RBAC-aware widget wrapper
class RBACGuard extends StatelessWidget {
  final Set<Permission>? requiredPermissions;
  final String? requiredFeature;
  final Widget child;
  final Widget? fallback;
  final bool requireAll;
  
  const RBACGuard({
    Key? key,
    this.requiredPermissions,
    this.requiredFeature,
    required this.child,
    this.fallback,
    this.requireAll = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RBACService(),
      builder: (context, _) {
        final rbac = RBACService();
        
        bool hasAccess = true;
        
        if (requiredFeature != null) {
          hasAccess = rbac.canAccessFeature(requiredFeature!);
        }
        
        if (requiredPermissions != null && requiredPermissions!.isNotEmpty) {
          if (requireAll) {
            hasAccess = hasAccess && rbac.hasAllPermissions(requiredPermissions!);
          } else {
            hasAccess = hasAccess && rbac.hasAnyPermission(requiredPermissions!);
          }
        }
        
        if (hasAccess) {
          return child;
        }
        
        return fallback ?? _buildDefaultFallback();
      },
    );
  }
  
  Widget _buildDefaultFallback() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Access Restricted',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You do not have permission to access this feature',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

/// Extension for easy RBAC checks in widgets
extension RBACContext on BuildContext {
  bool hasPermission(Permission permission) {
    return RBACService().hasPermission(permission);
  }
  
  bool canAccessFeature(String feature) {
    return RBACService().canAccessFeature(feature);
  }
  
  UserRole? get userRole => RBACService().currentRole;
}
