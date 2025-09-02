import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'lib/core/services/enhanced_rbac_service.dart';
import 'lib/features/auth/services/auth_service.dart';
import 'lib/core/services/rbac_audit_service.dart';
import 'lib/core/models/permission.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up test preferences
  SharedPreferences.setMockInitialValues({});
  
  // Register services
  final locator = GetIt.instance;
  if (!locator.isRegistered<AuthService>()) {
    locator.registerSingleton<AuthService>(AuthService());
  }
  if (!locator.isRegistered<RBACAuditService>()) {
    locator.registerSingleton<RBACAuditService>(RBACAuditService());
  }
  if (!locator.isRegistered<EnhancedRBACService>()) {
    locator.registerSingleton<EnhancedRBACService>(EnhancedRBACService());
  }
  
  // Initialize auth service
  final authService = locator<AuthService>();
  await authService.initialize();
  
  // Set superadmin email as current user
  await authService.setCurrentUser('env.hygiene@gmail.com');
  
  // Initialize RBAC service
  final rbacService = locator<EnhancedRBACService>();
  await rbacService.initialize('env.hygiene@gmail.com');
  
  // Test all permissions
  print('\n=== Testing SuperAdmin Access ===\n');
  print('Current user: ${authService.currentUser}');
  print('Current role: ${rbacService.currentRole}');
  print('\n--- Permission Checks ---\n');
  
  final permissions = [
    Permission.viewDashboard,
    Permission.viewSecurityCenter,
    Permission.manageUsers,
    Permission.viewLogs,
    Permission.manageRoles,
    Permission.viewAnalytics,
    Permission.manageSecurity,
    Permission.exportData,
    Permission.viewReports,
    Permission.manageSettings,
    Permission.viewNotifications,
    Permission.manageNotifications,
    Permission.viewAuditTrail,
    Permission.manageBiometrics,
    Permission.viewIncidents,
    Permission.manageIncidents,
    Permission.viewCompliance,
    Permission.manageCompliance,
    Permission.viewThreatIntel,
    Permission.manageThreatIntel,
  ];
  
  bool allPermissionsGranted = true;
  
  for (final permission in permissions) {
    final hasPermission = await rbacService.hasPermission(permission);
    print('${permission.toString().split('.').last}: ${hasPermission ? "✓ GRANTED" : "✗ DENIED"}');
    
    if (!hasPermission) {
      allPermissionsGranted = false;
    }
  }
  
  print('\n=== Test Results ===\n');
  if (allPermissionsGranted) {
    print('✓ SUCCESS: SuperAdmin has all permissions!');
  } else {
    print('✗ FAILURE: SuperAdmin is missing some permissions');
  }
  
  // Test with a different email
  print('\n=== Testing Regular User ===\n');
  await authService.setCurrentUser('test@example.com');
  await rbacService.initialize('test@example.com');
  
  print('Current user: ${authService.currentUser}');
  print('Current role: ${rbacService.currentRole}');
  
  final regularUserPermission = await rbacService.hasPermission(Permission.manageUsers);
  print('manageUsers permission: ${regularUserPermission ? "✓ GRANTED" : "✗ DENIED (Expected)"}');
  
  print('\n=== All Tests Complete ===\n');
}
