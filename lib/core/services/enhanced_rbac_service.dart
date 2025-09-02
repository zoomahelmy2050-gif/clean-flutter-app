import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clean_flutter/locator.dart';
import 'package:clean_flutter/core/services/rbac_audit_service.dart';
import 'package:clean_flutter/features/auth/services/auth_service.dart';

/// Enhanced Permission system with granular control
enum Permission {
  // Dashboard & Analytics
  viewDashboard,
  viewAnalytics,
  viewReports,
  exportReports,
  viewExecutiveSummary,
  
  // User Management
  viewUsers,
  manageUsers,
  deleteUsers,
  blockUsers,
  resetPasswords,
  viewUserActivity,
  manageRoles,
  exportUserData,
  
  // Security Center
  accessSecurityCenter,
  viewSecurityAlerts,
  acknowledgeAlerts,
  resolveAlerts,
  createSecurityPolicies,
  updateSecurityPolicies,
  deleteSecurityPolicies,
  viewThreats,
  mitigateThreats,
  quarantineThreats,
  viewThreatIntelligence,
  manageThreatFeeds,
  
  // Incident Management
  viewIncidents,
  createIncidents,
  manageIncidents,
  closeIncidents,
  escalateIncidents,
  commentOnIncidents,
  executePlaybooks,
  createPlaybooks,
  editPlaybooks,
  deletePlaybooks,
  
  // Compliance & Audit
  viewAuditLogs,
  exportAuditLogs,
  deleteAuditLogs,
  viewCompliance,
  generateComplianceReports,
  updateComplianceSettings,
  performAudits,
  
  // System Configuration
  viewSystemSettings,
  viewSecuritySettings,
  manageSecuritySettings,
  manageMFA,
  manageEncryption,
  managePasswordPolicies,
  manageSessionSettings,
  
  // AI & Automation
  accessAIAssistant,
  configureAISettings,
  viewAutomationRules,
  createAutomationRules,
  editAutomationRules,
  deleteAutomationRules,
  
  // Device Management
  viewDevices,
  manageDevices,
  blockDevices,
  trustDevices,
  remoteWipe,
  
  // Backup & Recovery
  performBackups,
  restoreBackups,
  manageDatabaseMigrations,
  accessDisasterRecovery,
  
  // Advanced Features
  accessForensics,
  performVulnerabilityScans,
  accessPenetrationTesting,
  manageSIEMIntegration,
  accessZeroTrust,
  manageAPIAccess,
  viewBusinessIntelligence,
  
  // Communication
  sendNotifications,
  sendEmails,
  manageBroadcasts,
  accessSupportTickets,
}

/// User roles with hierarchical structure
enum UserRole {
  superAdmin,    // Full system access
  admin,         // Administrative access
  securityAdmin, // Security-focused admin
  moderator,     // Content and user moderation
  analyst,       // Security analyst
  securityAnalyst, // Security analyst
  auditor,       // Compliance auditor
  operator,      // System operator
  viewer,        // Read-only access
  user,          // Standard user
  guest,         // Limited guest access
}

/// Role hierarchy for inheritance
class RoleHierarchy {
  static const Map<UserRole, Set<UserRole>> hierarchy = {
    UserRole.superAdmin: {
      UserRole.admin,
      UserRole.securityAdmin,
      UserRole.moderator,
      UserRole.analyst,
      UserRole.securityAnalyst,
      UserRole.auditor,
      UserRole.operator,
      UserRole.viewer,
      UserRole.user,
      UserRole.guest,
    },
    UserRole.admin: {
      UserRole.moderator,
      UserRole.analyst,
      UserRole.operator,
      UserRole.viewer,
      UserRole.user,
    },
    UserRole.securityAdmin: {
      UserRole.analyst,
      UserRole.operator,
      UserRole.viewer,
    },
    UserRole.moderator: {
      UserRole.viewer,
      UserRole.user,
    },
    UserRole.analyst: {
      UserRole.viewer,
    },
    UserRole.securityAnalyst: {
      UserRole.viewer,
    },
    UserRole.auditor: {
      UserRole.viewer,
    },
    UserRole.operator: {
      UserRole.viewer,
    },
    UserRole.viewer: {
      UserRole.guest,
    },
    UserRole.user: {},
    UserRole.guest: {},
  };
}

/// Enhanced RBAC Service with comprehensive permission management
class EnhancedRBACService extends ChangeNotifier {
  static const String _roleKey = 'user_role';
  static const String _permissionsKey = 'user_permissions';
  // static const String _featureFlagsKey = 'feature_flags'; // Unused, commented out
  static const String _temporaryPermissionsKey = 'temp_permissions';
  
  UserRole _currentRole = UserRole.user;
  Set<Permission> _customPermissions = {};
  Map<Permission, DateTime> _temporaryPermissions = {};
  late RBACAuditService _auditService;
  late AuthService _authService;
  bool _isInitialized = false;
  Map<String, dynamic> _customAttributes = {};
  Map<String, bool> _featureFlags = {};
  
  // Role to permissions mapping
  static final Map<UserRole, List<Permission>> _rolePermissions = {
    UserRole.superAdmin: Permission.values, // All permissions
    UserRole.admin: [
      Permission.viewDashboard,
      Permission.viewAnalytics,
      Permission.viewReports,
      Permission.manageUsers,
      Permission.viewUsers,
      Permission.updateSecurityPolicies,
      Permission.deleteSecurityPolicies,
      Permission.viewThreats,
      Permission.mitigateThreats,
      Permission.viewIncidents,
      Permission.manageIncidents,
      Permission.viewThreatIntelligence,
      Permission.manageSIEMIntegration,
      Permission.viewCompliance,
    ],
    UserRole.moderator: [
      Permission.viewDashboard,
      Permission.viewUsers,
      Permission.viewSecurityAlerts,
      Permission.viewAuditLogs,
      Permission.viewIncidents,
      Permission.viewReports,
    ],
    UserRole.securityAnalyst: [
      Permission.viewDashboard,
      Permission.viewThreats,
      Permission.viewIncidents,
      Permission.performVulnerabilityScans,
      Permission.viewSecurityAlerts,
      Permission.viewThreatIntelligence,
    ],
    UserRole.auditor: [
      Permission.viewAuditLogs,
      Permission.viewCompliance,
      Permission.viewReports,
      Permission.exportReports,
    ],
    UserRole.viewer: [
      Permission.viewDashboard,
      Permission.viewReports,
    ],
    UserRole.user: [
      Permission.viewDashboard,
    ],
    UserRole.guest: [],
  };
  
  UserRole? get currentRole => _currentRole;
  Set<Permission> get permissions => _customPermissions;
  
  Future<void> initialize(String userEmail) async {
    // Force re-initialization for superadmin
    if (userEmail.toLowerCase() == 'env.hygiene@gmail.com') {
      _isInitialized = false;
    }
    
    if (_isInitialized) return;
    
    print('RBAC: Initializing for email: $userEmail');
    
    final prefs = await SharedPreferences.getInstance();
    
    // Initialize services
    _auditService = locator<RBACAuditService>();
    _authService = locator<AuthService>();
    await _auditService.initialize();
    
    // Check if this is the admin email - always gets superAdmin role
    if (userEmail.toLowerCase() == 'env.hygiene@gmail.com') {
      _currentRole = UserRole.superAdmin;
      await prefs.setString(_roleKey, UserRole.superAdmin.toString());
      print('RBAC: Assigned superAdmin role to $userEmail');
    } else {
      // Load saved role for other users
      final savedRole = prefs.getString(_roleKey);
      if (savedRole != null) {
        _currentRole = UserRole.values.firstWhere(
          (role) => role.toString() == savedRole,
          orElse: () => UserRole.user,
        );
      }
    }
    
    print('RBAC: Current role is $_currentRole');
    
    // Set permissions based on role
    final rolePermissions = _rolePermissions[_currentRole] ?? [];
    _customPermissions = rolePermissions.toSet();
    
    // Load custom attributes
    final attributesJson = prefs.getString('user_attributes_$userEmail');
    if (attributesJson != null) {
      _customAttributes = json.decode(attributesJson);
    }
    
    // Load feature flags
    final flagsJson = prefs.getString('feature_flags_$userEmail');
    if (flagsJson != null) {
      _featureFlags = Map<String, bool>.from(json.decode(flagsJson));
    }
    
    // Load temporary permissions
    final tempPermsJson = prefs.getString(_temporaryPermissionsKey);
    if (tempPermsJson != null) {
      final tempPermsMap = json.decode(tempPermsJson);
      _temporaryPermissions = tempPermsMap.map(
        (key, value) => MapEntry(Permission.values.firstWhere((p) => p.toString() == key), DateTime.parse(value)),
      );
    }
    
    _isInitialized = true;
    notifyListeners();
  }
  
  /// Check if user has specific permission
  Future<bool> hasPermission(Permission permission) async {
    final userId = _authService.currentUser ?? 'unknown';
    final userEmail = _authService.currentUser ?? 'unknown@example.com';
    
    print('RBAC hasPermission: Checking permission $permission for user $userEmail, role: $_currentRole');
    
    // ALWAYS grant all permissions to superadmin email, regardless of cache or initialization
    if (userEmail.toLowerCase() == 'env.hygiene@gmail.com') {
      print('RBAC hasPermission: SuperAdmin email detected, granting all permissions');
      return true;
    }
    
    // Check cache first for other users
    final cached = _auditService.getCachedPermission(userId, permission.toString());
    if (cached != null) {
      print('RBAC hasPermission: Using cached result: $cached');
      return cached;
    }
    
    // Check temporary permissions
    if (_temporaryPermissions.containsKey(permission)) {
      final expiry = _temporaryPermissions[permission]!;
      if (DateTime.now().isBefore(expiry)) {
        _cacheAndLog(userId, userEmail, permission, true, 'temporary');
        return true;
      } else {
        // Remove expired permission
        _temporaryPermissions.remove(permission);
        _saveTemporaryPermissions();
      }
    }
    
    // Super admin role has all permissions
    if (_currentRole == UserRole.superAdmin) {
      print('RBAC hasPermission: SuperAdmin role detected, granting permission');
      _cacheAndLog(userId, userEmail, permission, true, 'superadmin');
      return true;
    }
    
    // Check custom permissions
    if (_customPermissions.contains(permission)) {
      _cacheAndLog(userId, userEmail, permission, true, 'custom');
      return true;
    }
    
    // Check role-based permissions
    final rolePermissions = _rolePermissions[_currentRole] ?? [];
    final hasPermission = rolePermissions.contains(permission);
    
    _cacheAndLog(userId, userEmail, permission, hasPermission, 'role');
    return hasPermission;
  }
  
  void _cacheAndLog(String userId, String userEmail, Permission permission, bool granted, String source) {
    // Cache the result
    _auditService.cachePermission(userId, permission.toString(), granted);
    
    // Log the permission check
    _auditService.logPermissionCheck(
      userId: userId,
      userEmail: userEmail,
      permission: permission.toString(),
      granted: granted,
      additionalMetadata: {'source': source},
    );
  }
  
  /// Check if user has any of the specified permissions
  bool hasAnyPermission(List<Permission> permissions) {
    return permissions.any((p) => _customPermissions.contains(p));
  }
  
  /// Check if user has all of the specified permissions
  bool hasAllPermissions(List<Permission> permissions) {
    return permissions.every((p) => _customPermissions.contains(p));
  }
  
  /// Check if user can access a feature
  Future<bool> canAccessFeature(String featureName) async {
    // Check feature flags first
    if (_featureFlags.containsKey(featureName)) {
      return _featureFlags[featureName]!;
    }
    
    // Check role-based access
    switch (featureName) {
      case 'ai_assistant':
        return await hasPermission(Permission.accessAIAssistant);
      case 'user_management':
        return await hasPermission(Permission.manageUsers);
      case 'security_center':
        return await hasPermission(Permission.accessSecurityCenter);
      case 'threat_intelligence':
        return await hasPermission(Permission.viewThreatIntelligence);
      case 'incident_response':
        return await hasPermission(Permission.viewIncidents);
      case 'compliance':
        return await hasPermission(Permission.viewCompliance);
      case 'vulnerability_scanning':
        return await hasPermission(Permission.performVulnerabilityScans);
      case 'siem_integration':
        return await hasPermission(Permission.manageSIEMIntegration);
      case 'zero_trust':
        return await hasPermission(Permission.accessZeroTrust);
      default:
        return false;
    }
  }
  
  /// Get list of features user can access
  Future<List<String>> getAccessibleFeatures() async {
    List<String> features = [];
    
    if (await canAccessFeature('ai_assistant')) features.add('AI Assistant');
    if (await canAccessFeature('user_management')) features.add('User Management');
    if (await canAccessFeature('security_center')) features.add('Security Center');
    if (await canAccessFeature('threat_intelligence')) features.add('Threat Intelligence');
    if (await canAccessFeature('incident_response')) features.add('Incident Response');
    if (await canAccessFeature('compliance')) features.add('Compliance & Reporting');
    if (await canAccessFeature('vulnerability_scanning')) features.add('Vulnerability Scanning');
    if (await canAccessFeature('siem_integration')) features.add('SIEM Integration');
    if (await canAccessFeature('zero_trust')) features.add('Zero Trust Network');
    
    return features;
  }
  
  /// Update user role (admin only)
  Future<void> updateUserRole(String userId, UserRole newRole) async {
    final oldRole = _currentRole;
    // Only admins can change roles
    if (!await hasPermission(Permission.manageRoles)) {
      return;
    }
    
    // Cannot change super admin role
    if (userId.toLowerCase() == 'env.hygiene@gmail.com') {
      return;
    }
    
    _currentRole = newRole;
    notifyListeners();
    
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, newRole.toString());
    
    // Log role change
    await _auditService.logRoleChange(
      userId: userId,
      userEmail: _authService.currentUser ?? userId,
      oldRole: oldRole.toString(),
      newRole: newRole.toString(),
      changedBy: _authService.currentUser ?? 'system',
    );
    
    // Invalidate cache for this user
    _auditService.invalidateUserCache(userId);
  }
  
  /// Get human-readable role name
  String getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super Administrator';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.securityAdmin:
        return 'Security Administrator';
      case UserRole.moderator:
        return 'Moderator';
      case UserRole.analyst:
        return 'Analyst';
      case UserRole.securityAnalyst:
        return 'Security Analyst';
      case UserRole.auditor:
        return 'Auditor';
      case UserRole.operator:
        return 'System Operator';
      case UserRole.viewer:
        return 'Viewer';
      case UserRole.guest:
        return 'Guest';
      case UserRole.user:
        return 'Standard User';
    }
  }
  
  bool isFeatureEnabled(String featureFlag) {
    return _featureFlags[featureFlag] ?? false;
  }
  
  Future<void> grantTemporaryPermission({
    required String userId,
    required Permission permission,
    required Duration duration,
    required String reason,
  }) async {
    final expiry = DateTime.now().add(duration);
    _temporaryPermissions[permission] = expiry;
    
    await _saveTemporaryPermissions();
    
    // Log emergency access
    await _auditService.logEmergencyAccess(
      userId: userId,
      userEmail: _authService.currentUser ?? userId,
      reason: reason,
      duration: duration,
      permissions: [permission.toString()],
    );
    
    // Invalidate cache
    _auditService.invalidateUserCache(userId);
    notifyListeners();
  }
  
  Future<void> _saveTemporaryPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final tempPermsMap = _temporaryPermissions.map(
      (key, value) => MapEntry(key.toString(), value.toIso8601String()),
    );
    await prefs.setString(_temporaryPermissionsKey, jsonEncode(tempPermsMap));
  }
  
  // Unused method, commented out for future use
  // void _cleanupExpiredPermissions() {
  //   final now = DateTime.now();
  //   _temporaryPermissions.removeWhere((permission, expiry) => expiry.isBefore(now));
  //   notifyListeners();
  // }
  
  /// Add custom permission to user
  Future<void> addCustomPermission(String userId, Permission permission) async {
    
    // Add custom permission
    _customPermissions.add(permission);
    
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_permissionsKey, jsonEncode(_customPermissions.map((p) => p.toString()).toList()));
    
    // Log custom permission addition
    await _auditService.logCustomPermission(
      userId: userId,
      userEmail: _authService.currentUser ?? userId,
      permission: permission.toString(),
      added: true,
      modifiedBy: _authService.currentUser ?? 'system',
    );
  }
  
  /// Remove custom permission from user
  Future<void> removeCustomPermission(String userId, Permission permission) async {
    _customPermissions.remove(permission);
    notifyListeners();
    await _saveCustomPermissions();
    
    // Log custom permission removal
    await _auditService.logCustomPermission(
      userId: userId,
      userEmail: _authService.currentUser ?? userId,
      permission: permission.toString(),
      added: false,
      modifiedBy: _authService.currentUser ?? 'system',
    );
    
    // Invalidate cache
    _auditService.invalidateUserCache(userId);
  }
  
  Future<void> _saveCustomPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final permissions = _customPermissions.map((p) => p.toString()).toList();
    await prefs.setString(_permissionsKey, jsonEncode(permissions));
  }
  
  Map<String, dynamic> getAuditAnalytics() {
    return _auditService.getAnalytics();
  }
  
  bool get isInitialized => _isInitialized;
  
  /// Get permissions for a specific role
  Set<Permission> getRolePermissions(UserRole role) {
    return _rolePermissions[role]?.toSet() ?? {};
  }
  
  /// Get color for a specific role
  Color getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return const Color(0xFFFF1744); // Red
      case UserRole.admin:
        return const Color(0xFFFF6D00); // Orange
      case UserRole.securityAdmin:
        return const Color(0xFFD500F9); // Purple
      case UserRole.securityAnalyst:
        return const Color(0xFF2196F3); // Blue
      case UserRole.moderator:
        return const Color(0xFF4CAF50); // Green
      case UserRole.analyst:
        return const Color(0xFF2979FF); // Blue
      case UserRole.auditor:
        return const Color(0xFF00BCD4); // Cyan
      case UserRole.operator:
        return const Color(0xFF651FFF); // Deep Purple
      case UserRole.viewer:
        return const Color(0xFF9E9E9E); // Grey
      case UserRole.user:
        return const Color(0xFF2196F3); // Default Blue
      case UserRole.guest:
        return const Color(0xFF757575); // Dark Grey
    }
  }
  
  /// Clear RBAC data on logout
  void clearSession() {
    _currentRole = UserRole.user; // Reset to default role instead of null
    _customPermissions.clear();
    _customAttributes.clear();
    _featureFlags.clear();
    notifyListeners();
  }
}
