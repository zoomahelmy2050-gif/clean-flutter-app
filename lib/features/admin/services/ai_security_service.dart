import 'dart:async';
import '../../../core/services/rbac_service.dart';
import '../../auth/services/auth_service.dart';

/// AI Security Service for permission control and action validation
class AISecurityService {
  final RBACService _rbacService;
  final AuthService _authService;
  
  // Security configurations
  final Map<String, SecurityPolicy> _securityPolicies = {};
  final Map<String, AuditLog> _auditLogs = {};
  final Set<String> _blockedUsers = {};
  final Map<String, int> _rateLimits = {};
  final Map<String, DateTime> _lastActionTime = {};
  
  // Sensitive action categories
  static const Set<String> _sensitiveActions = {
    'delete_data',
    'modify_security',
    'access_admin',
    'export_sensitive',
    'modify_system',
    'execute_workflow',
    'sync_devices',
    'monitor_system',
    'manage_users',
    'manage_rbac',
  };
  
  // Action risk levels
  static const Map<String, RiskLevel> _actionRiskLevels = {
    'view_analytics': RiskLevel.low,
    'check_security': RiskLevel.low,
    'navigate': RiskLevel.low,
    'search': RiskLevel.low,
    'view_data': RiskLevel.medium,
    'create_data': RiskLevel.medium,
    'modify_data': RiskLevel.high,
    'delete_data': RiskLevel.critical,
    'manage_users': RiskLevel.critical,
    'modify_security': RiskLevel.critical,
    'execute_workflow': RiskLevel.high,
    'sync_devices': RiskLevel.high,
  };
  
  AISecurityService({
    required RBACService rbacService,
    required AuthService authService,
  }) : _rbacService = rbacService,
       _authService = authService {
    _initializeSecurityPolicies();
  }
  
  /// Initialize default security policies
  void _initializeSecurityPolicies() {
    // User role policies
    _securityPolicies['user'] = SecurityPolicy(
      allowedActions: {'view_data', 'search', 'navigate', 'view_analytics'},
      deniedActions: _sensitiveActions,
      requiresAuth: true,
      requiresMFA: false,
      maxRiskLevel: RiskLevel.low,
    );
    
    _securityPolicies['staff'] = SecurityPolicy(
      allowedActions: {
        'view_data', 'search', 'navigate', 'view_analytics',
        'create_data', 'modify_data', 'check_security'
      },
      deniedActions: {'modify_security', 'manage_users', 'manage_rbac'},
      requiresAuth: true,
      requiresMFA: false,
      maxRiskLevel: RiskLevel.medium,
    );
    
    _securityPolicies['manager'] = SecurityPolicy(
      allowedActions: {
        'view_data', 'search', 'navigate', 'view_analytics',
        'create_data', 'modify_data', 'delete_data', 'check_security',
        'export_sensitive', 'monitor_system'
      },
      deniedActions: {'modify_security', 'manage_rbac'},
      requiresAuth: true,
      requiresMFA: true,
      maxRiskLevel: RiskLevel.high,
    );
    
    _securityPolicies['admin'] = SecurityPolicy(
      allowedActions: _sensitiveActions.union({
        'view_data', 'search', 'navigate', 'view_analytics',
        'create_data', 'modify_data', 'delete_data', 'check_security',
        'export_sensitive', 'access_admin'
      }),
      deniedActions: {},
      requiresAuth: true,
      requiresMFA: true,
      maxRiskLevel: RiskLevel.critical,
    );
    
    _securityPolicies['super_admin'] = SecurityPolicy(
      allowedActions: {}, // All actions allowed
      deniedActions: {},
      requiresAuth: true,
      requiresMFA: true,
      maxRiskLevel: RiskLevel.critical,
      bypassAllChecks: true,
    );
  }
  
  /// Validate if an action is allowed for the current user
  Future<ValidationResult> validateAction({
    required String action,
    required Map<String, dynamic> parameters,
    String? reason,
  }) async {
    try {
      final currentUserEmail = _authService.currentUser;
      if (currentUserEmail == null) {
        return ValidationResult(
          isValid: false,
          message: 'Authentication required to perform this action',
          metadata: {'requires_auth': true},
        );
      }
      
      // Check if user is blocked
      if (_blockedUsers.contains(currentUserEmail)) {
        _logSecurityEvent(
          userId: currentUserEmail,
          action: action,
          result: 'blocked',
          reason: 'User is blocked',
        );
        return ValidationResult(
          isValid: false,
          message: 'User access is blocked',
        );
      }
      
      // Check rate limiting
      if (!_checkRateLimit(currentUserEmail, action)) {
        _logSecurityEvent(
          userId: currentUserEmail,
          action: action,
          result: 'rate_limited',
          reason: 'Exceeded rate limit',
        );
        return ValidationResult(
          isValid: false,
          message: 'Rate limit exceeded. Please wait before trying again.',
        );
      }
      
      // Get user's role and security policy
      final userRoleString = await _authService.getUserRole(currentUserEmail);
      final userRole = userRoleString.toString().toLowerCase();
      final policy = _securityPolicies[userRole] ?? _securityPolicies['user']!;
      
      // Check if bypass is enabled for super admin
      if (policy.bypassAllChecks == true) {
        _logSecurityEvent(
          userId: currentUserEmail,
          action: action,
          result: 'allowed',
          reason: 'Super admin bypass',
        );
        return ValidationResult(
          isValid: true,
          message: 'Action allowed with super admin bypass',
        );
      }
      
      // Check action risk level
      final riskLevel = _actionRiskLevels[action] ?? RiskLevel.medium;
      if (riskLevel.index > policy.maxRiskLevel.index) {
        _logSecurityEvent(
          userId: currentUserEmail,
          action: action,
          result: 'denied',
          reason: 'Risk level too high',
        );
        return ValidationResult(
          isValid: false,
          message: 'Action risk level exceeds user permissions',
        );
      }
      
      // Check if action is explicitly denied
      if (policy.deniedActions.contains(action)) {
        _logSecurityEvent(
          userId: currentUserEmail,
          action: action,
          result: 'denied',
          reason: 'Action explicitly denied for role',
        );
        return ValidationResult(
          isValid: false,
          message: 'You do not have permission to perform this action',
        );
      }
      
      // Check if action is allowed (if allowedActions is not empty)
      if (policy.allowedActions.isNotEmpty && 
          !policy.allowedActions.contains(action)) {
        _logSecurityEvent(
          userId: currentUserEmail,
          action: action,
          result: 'denied',
          reason: 'Action not in allowed list',
        );
        return ValidationResult(
          isValid: false,
          message: 'This action is not permitted for your role',
        );
      }
      
      // Check MFA requirement for sensitive actions
      if (policy.requiresMFA && _sensitiveActions.contains(action)) {
        // TODO: Implement MFA check
        // For now, log and allow with warning
        _logSecurityEvent(
          userId: currentUserEmail,
          action: action,
          result: 'allowed_with_warning',
          reason: 'MFA required but not enforced',
        );
      }
      
      // Check RBAC permissions
      final permission = _mapActionToPermission(action);
      final hasPermission = _rbacService.hasPermission(permission);
      
      if (!hasPermission) {
        _logSecurityEvent(
          userId: currentUserEmail,
          action: action,
          result: 'denied',
          reason: 'RBAC permission check failed',
        );
        return ValidationResult(
          isValid: false,
          message: 'Insufficient RBAC permissions',
        );
      }
      
      // Additional parameter validation
      final paramValidation = _validateParameters(action, parameters, userRole);
      if (!paramValidation.isValid) {
        _logSecurityEvent(
          userId: currentUserEmail,
          action: action,
          result: 'denied',
          reason: paramValidation.message,
        );
        return paramValidation;
      }
      
      // Log successful validation
      _logSecurityEvent(
        userId: currentUserEmail,
        action: action,
        result: 'allowed',
        reason: reason ?? 'All checks passed',
        parameters: parameters,
      );
      
      // Update last action time
      _lastActionTime['${currentUserEmail}_$action'] = DateTime.now();
      
      return ValidationResult(
        isValid: true,
        message: 'Action validated successfully',
      );
      
    } catch (e) {
      _logSecurityEvent(
        userId: 'unknown',
        action: action,
        result: 'error',
        reason: e.toString(),
      );
      return ValidationResult(
        isValid: false,
        message: 'An error occurred during validation',
      );
    }
  }
  
  /// Check rate limiting for user actions
  bool _checkRateLimit(String userId, String action) {
    final key = '${userId}_$action';
    final limit = _rateLimits[action] ?? 10; // Default 10 actions per minute
    final lastTime = _lastActionTime[key];
    
    if (lastTime == null) return true;
    
    final timeDiff = DateTime.now().difference(lastTime);
    if (timeDiff.inSeconds < 60 / limit) {
      return false;
    }
    
    return true;
  }
  
  /// Map action names to RBAC permissions
  Permission _mapActionToPermission(String action) {
    // Map AI actions to RBAC permissions
    switch (action) {
      case 'view_data':
      case 'search_data':
      case 'check_status':
        return Permission.viewDashboard;
      case 'manage_users':
      case 'create_user':
      case 'delete_user':
        return Permission.manageUsers;
      case 'manage_security':
      case 'modify_security':
      case 'configure_security':
        return Permission.manageSecurity;
      case 'execute_workflow':
      case 'create_workflow':
      case 'schedule_workflow':
        return Permission.executePlaybooks;
      case 'sync_devices':
      case 'manage_devices':
        return Permission.configureSettings;
      case 'view_analytics':
      case 'generate_report':
        return Permission.viewAnalytics;
      case 'manage_rbac':
      case 'modify_rbac':
        return Permission.manageSettings;
      case 'delete_data':
      case 'purge_data':
        return Permission.manageSettings;
      case 'monitor_system':
      case 'view_monitoring':
        return Permission.viewDashboard;
      default:
        return Permission.viewProfile; // Default minimal permission
    }
  }
  
  /// Validate action parameters based on user role and action type
  ValidationResult _validateParameters(
    String action,
    Map<String, dynamic> parameters,
    String userRole,
  ) {
    // Validate sensitive data access
    if (action == 'export_sensitive' && userRole != 'admin' && userRole != 'super_admin') {
      if (parameters['includePersonalData'] == true) {
        return ValidationResult(
          isValid: false,
          message: 'Only admins can export personal data',
        );
      }
    }
    
    // Validate user management actions
    if (action == 'manage_users') {
      final targetRole = parameters['targetRole'] as String?;
      if (targetRole == 'admin' && userRole != 'super_admin') {
        return ValidationResult(
          isValid: false,
          message: 'Only super admins can manage admin accounts',
        );
      }
    }
    
    // Validate workflow execution
    if (action == 'execute_workflow') {
      final workflowType = parameters['type'] as String?;
      if (workflowType == 'system' && userRole != 'admin' && userRole != 'super_admin') {
        return ValidationResult(
          isValid: false,
          message: 'System workflows require admin privileges',
        );
      }
    }
    
    // Validate device sync
    if (action == 'sync_devices') {
      final deviceCount = (parameters['devices'] as List?)?.length ?? 0;
      if (deviceCount > 10 && userRole != 'admin' && userRole != 'super_admin') {
        return ValidationResult(
          isValid: false,
          message: 'Bulk device sync requires admin privileges',
        );
      }
    }
    
    return ValidationResult(isValid: true, message: 'Validation successful');
  }
  
  /// Log security events for audit trail
  void _logSecurityEvent({
    required String userId,
    required String action,
    required String result,
    String? reason,
    Map<String, dynamic>? parameters,
  }) async {
    final logEntry = AuditLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      action: action,
      result: result,
      reason: reason,
      parameters: parameters,
      timestamp: DateTime.now(),
    );
    
    _auditLogs[logEntry.id] = logEntry;
    
    // Keep only last 1000 entries
    if (_auditLogs.length > 1000) {
      final oldestKey = _auditLogs.keys.first;
      _auditLogs.remove(oldestKey);
    }
  }
  
  /// Get audit logs for a specific user or action
  List<AuditLog> getAuditLogs({
    String? userId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _auditLogs.values.where((log) {
      if (userId != null && log.userId != userId) return false;
      if (action != null && log.action != action) return false;
      if (startDate != null && log.timestamp.isBefore(startDate)) return false;
      if (endDate != null && log.timestamp.isAfter(endDate)) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
  
  /// Block a user from using AI assistant
  Future<void> blockUser(String userId, String reason) async {
    _blockedUsers.add(userId);
    _logSecurityEvent(
      userId: 'system',
      action: 'block_user',
      result: 'success',
      reason: 'Blocked user $userId: $reason',
    );
  }
  
  /// Unblock a user
  Future<void> unblockUser(String userId) async {
    _blockedUsers.remove(userId);
    _logSecurityEvent(
      userId: 'system',
      action: 'unblock_user',
      result: 'success',
      reason: 'Unblocked user $userId',
    );
  }
  
  /// Set custom rate limit for specific actions
  void setRateLimit(String action, int maxPerMinute) {
    _rateLimits[action] = maxPerMinute;
  }
  
  /// Get security policy for a role
  SecurityPolicy? getSecurityPolicy(String role) {
    return _securityPolicies[role.toLowerCase()];
  }
  
  /// Update security policy for a role
  void updateSecurityPolicy(String role, SecurityPolicy policy) {
    _securityPolicies[role.toLowerCase()] = policy;
    _logSecurityEvent(
      userId: 'system',
      action: 'update_security_policy',
      result: 'success',
      reason: 'Updated policy for role: $role',
    );
  }
}

/// Security policy for user roles
class SecurityPolicy {
  final Set<String> allowedActions;
  final Set<String> deniedActions;
  final bool requiresAuth;
  final bool requiresMFA;
  final RiskLevel maxRiskLevel;
  final bool bypassAllChecks;
  
  SecurityPolicy({
    required this.allowedActions,
    required this.deniedActions,
    required this.requiresAuth,
    required this.requiresMFA,
    required this.maxRiskLevel,
    this.bypassAllChecks = false,
  });
}

/// Risk levels for actions
enum RiskLevel {
  low,
  medium,
  high,
  critical,
}

/// Validation result
class ValidationResult {
  final bool isValid;
  final String message;
  final Map<String, dynamic>? metadata;
  
  ValidationResult({
    required this.isValid,
    required this.message,
    this.metadata,
  });
}

/// Audit log entry
class AuditLog {
  final String id;
  final String userId;
  final String action;
  final String result;
  final String? reason;
  final Map<String, dynamic>? parameters;
  final DateTime timestamp;
  
  AuditLog({
    required this.id,
    required this.userId,
    required this.action,
    required this.result,
    this.reason,
    this.parameters,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'action': action,
    'result': result,
    'reason': reason,
    'parameters': parameters,
    'timestamp': timestamp.toIso8601String(),
  };
}
