import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clean_flutter/core/services/enhanced_rbac_service.dart';

class RolePersistenceService {
  static const String _userRolesKey = 'user_roles_mapping';
  static const String _rolePermissionsKey = 'role_permissions_mapping';
  static const String _temporalAccessKey = 'temporal_access_grants';
  static const String _roleTemplatesKey = 'role_templates';
  static const String _auditLogsKey = 'role_audit_logs';
  
  final SharedPreferences _prefs;
  
  RolePersistenceService(this._prefs);
  
  // Save user role mappings
  Future<bool> saveUserRoles(Map<String, UserRole> userRoles) async {
    try {
      final Map<String, String> stringMap = {};
      userRoles.forEach((userId, role) {
        stringMap[userId] = role.toString().split('.').last;
      });
      
      final jsonString = jsonEncode(stringMap);
      return await _prefs.setString(_userRolesKey, jsonString);
    } catch (e) {
      print('Error saving user roles: $e');
      return false;
    }
  }
  
  // Load user role mappings
  Map<String, UserRole> loadUserRoles() {
    try {
      final jsonString = _prefs.getString(_userRolesKey);
      if (jsonString == null) return {};
      
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      final Map<String, UserRole> userRoles = {};
      
      jsonMap.forEach((userId, roleString) {
        try {
          final role = UserRole.values.firstWhere(
            (r) => r.toString().split('.').last == roleString,
          );
          userRoles[userId] = role;
        } catch (e) {
          // Skip invalid role
        }
      });
      
      return userRoles;
    } catch (e) {
      print('Error loading user roles: $e');
      return {};
    }
  }
  
  // Save role permissions (for custom role configurations)
  Future<bool> saveRolePermissions(Map<UserRole, List<Permission>> rolePermissions) async {
    try {
      final Map<String, List<String>> stringMap = {};
      rolePermissions.forEach((role, permissions) {
        stringMap[role.toString().split('.').last] = 
          permissions.map((p) => p.toString().split('.').last).toList();
      });
      
      final jsonString = jsonEncode(stringMap);
      return await _prefs.setString(_rolePermissionsKey, jsonString);
    } catch (e) {
      print('Error saving role permissions: $e');
      return false;
    }
  }
  
  // Load role permissions
  Map<UserRole, List<Permission>> loadRolePermissions() {
    try {
      final jsonString = _prefs.getString(_rolePermissionsKey);
      if (jsonString == null) return {};
      
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      final Map<UserRole, List<Permission>> rolePermissions = {};
      
      jsonMap.forEach((roleString, permissionsList) {
        try {
          final role = UserRole.values.firstWhere(
            (r) => r.toString().split('.').last == roleString,
          );
          
          final permissions = (permissionsList as List<dynamic>)
            .map((permString) {
              try {
                return Permission.values.firstWhere(
                  (p) => p.toString().split('.').last == permString,
                );
              } catch (e) {
                return null;
              }
            })
            .where((p) => p != null)
            .cast<Permission>()
            .toList();
          
          rolePermissions[role] = permissions;
        } catch (e) {
          // Skip invalid role
        }
      });
      
      return rolePermissions;
    } catch (e) {
      print('Error loading role permissions: $e');
      return {};
    }
  }
  
  // Save temporal access grants
  Future<bool> saveTemporalAccess(List<Map<String, dynamic>> temporalAccess) async {
    try {
      // Convert DateTime objects to ISO strings
      final processedList = temporalAccess.map((grant) {
        final processed = Map<String, dynamic>.from(grant);
        if (processed['startDate'] is DateTime) {
          processed['startDate'] = (processed['startDate'] as DateTime).toIso8601String();
        }
        if (processed['endDate'] is DateTime) {
          processed['endDate'] = (processed['endDate'] as DateTime).toIso8601String();
        }
        if (processed['grantedRole'] is UserRole) {
          processed['grantedRole'] = processed['grantedRole'].toString().split('.').last;
        }
        return processed;
      }).toList();
      
      final jsonString = jsonEncode(processedList);
      return await _prefs.setString(_temporalAccessKey, jsonString);
    } catch (e) {
      print('Error saving temporal access: $e');
      return false;
    }
  }
  
  // Load temporal access grants
  List<Map<String, dynamic>> loadTemporalAccess() {
    try {
      final jsonString = _prefs.getString(_temporalAccessKey);
      if (jsonString == null) return [];
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((grant) {
        final processed = Map<String, dynamic>.from(grant);
        
        // Convert ISO strings back to DateTime
        if (processed['startDate'] is String) {
          processed['startDate'] = DateTime.parse(processed['startDate']);
        }
        if (processed['endDate'] is String) {
          processed['endDate'] = DateTime.parse(processed['endDate']);
        }
        
        // Convert role string back to UserRole
        if (processed['grantedRole'] is String) {
          try {
            processed['grantedRole'] = UserRole.values.firstWhere(
              (r) => r.toString().split('.').last == processed['grantedRole'],
            );
          } catch (e) {
            processed['grantedRole'] = UserRole.user;
          }
        }
        
        return processed;
      }).toList();
    } catch (e) {
      print('Error loading temporal access: $e');
      return [];
    }
  }
  
  // Save role templates
  Future<bool> saveRoleTemplates(List<Map<String, dynamic>> templates) async {
    try {
      // Process permissions to strings
      final processedTemplates = templates.map((template) {
        final processed = Map<String, dynamic>.from(template);
        
        if (processed['permissions'] is List) {
          processed['permissions'] = (processed['permissions'] as List)
            .map((p) {
              if (p is Permission) {
                return p.toString().split('.').last;
              }
              return p.toString();
            })
            .toList();
        }
        
        return processed;
      }).toList();
      
      final jsonString = jsonEncode(processedTemplates);
      return await _prefs.setString(_roleTemplatesKey, jsonString);
    } catch (e) {
      print('Error saving role templates: $e');
      return false;
    }
  }
  
  // Load role templates
  List<Map<String, dynamic>> loadRoleTemplates() {
    try {
      final jsonString = _prefs.getString(_roleTemplatesKey);
      if (jsonString == null) return [];
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((template) {
        final processed = Map<String, dynamic>.from(template);
        
        // Convert permission strings back to Permission enums
        if (processed['permissions'] is List) {
          processed['permissions'] = (processed['permissions'] as List)
            .map((permString) {
              try {
                return Permission.values.firstWhere(
                  (p) => p.toString().split('.').last == permString.toString(),
                );
              } catch (e) {
                return null;
              }
            })
            .where((p) => p != null)
            .toList();
        }
        
        return processed;
      }).toList();
    } catch (e) {
      print('Error loading role templates: $e');
      return [];
    }
  }
  
  // Save audit logs
  Future<bool> saveAuditLogs(List<Map<String, dynamic>> logs) async {
    try {
      // Keep only last 1000 logs
      final logsToSave = logs.length > 1000 
        ? logs.sublist(logs.length - 1000) 
        : logs;
      
      // Process DateTime objects
      final processedLogs = logsToSave.map((log) {
        final processed = Map<String, dynamic>.from(log);
        if (processed['timestamp'] is DateTime) {
          processed['timestamp'] = (processed['timestamp'] as DateTime).toIso8601String();
        }
        return processed;
      }).toList();
      
      final jsonString = jsonEncode(processedLogs);
      return await _prefs.setString(_auditLogsKey, jsonString);
    } catch (e) {
      print('Error saving audit logs: $e');
      return false;
    }
  }
  
  // Load audit logs
  List<Map<String, dynamic>> loadAuditLogs() {
    try {
      final jsonString = _prefs.getString(_auditLogsKey);
      if (jsonString == null) return [];
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((log) {
        final processed = Map<String, dynamic>.from(log);
        
        // Convert ISO string back to DateTime
        if (processed['timestamp'] is String) {
          processed['timestamp'] = DateTime.parse(processed['timestamp']);
        }
        
        return processed;
      }).toList();
    } catch (e) {
      print('Error loading audit logs: $e');
      return [];
    }
  }
  
  // Add new audit log entry
  Future<bool> addAuditLog({
    required String action,
    required String user,
    required String details,
    String? targetUser,
    String? targetRole,
  }) async {
    try {
      final logs = loadAuditLogs();
      
      logs.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'timestamp': DateTime.now(),
        'action': action,
        'user': user,
        'details': details,
        'targetUser': targetUser,
        'targetRole': targetRole,
        'severity': _getSeverityForAction(action),
      });
      
      return await saveAuditLogs(logs);
    } catch (e) {
      print('Error adding audit log: $e');
      return false;
    }
  }
  
  String _getSeverityForAction(String action) {
    if (action.toLowerCase().contains('delete') || 
        action.toLowerCase().contains('remove') ||
        action.toLowerCase().contains('suspend')) {
      return 'high';
    } else if (action.toLowerCase().contains('create') || 
               action.toLowerCase().contains('assign') ||
               action.toLowerCase().contains('grant')) {
      return 'medium';
    }
    return 'low';
  }
  
  // Clear all persisted data
  Future<void> clearAll() async {
    await _prefs.remove(_userRolesKey);
    await _prefs.remove(_rolePermissionsKey);
    await _prefs.remove(_temporalAccessKey);
    await _prefs.remove(_roleTemplatesKey);
    await _prefs.remove(_auditLogsKey);
  }
}
