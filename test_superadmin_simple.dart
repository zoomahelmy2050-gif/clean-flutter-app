import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'lib/core/services/enhanced_rbac_service.dart';
import 'lib/features/auth/services/auth_service.dart';
import 'lib/core/services/rbac_audit_service.dart';

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
  
  // Test superadmin email
  print('\n=== Testing SuperAdmin Access ===\n');
  
  final authService = locator<AuthService>();
  await authService.setCurrentUser('env.hygiene@gmail.com');
  
  final rbacService = locator<EnhancedRBACService>();
  await rbacService.initialize('env.hygiene@gmail.com');
  
  print('Current user: ${authService.currentUser}');
  print('Current role: ${rbacService.currentRole}');
  
  // Test a few key permissions
  final hasViewDashboard = await rbacService.hasPermission(Permission.viewDashboard);
  final hasManageUsers = await rbacService.hasPermission(Permission.manageUsers);
  final hasManageRoles = await rbacService.hasPermission(Permission.manageRoles);
  final hasViewAnalytics = await rbacService.hasPermission(Permission.viewAnalytics);
  
  print('\nPermission Checks:');
  print('viewDashboard: ${hasViewDashboard ? "✓ GRANTED" : "✗ DENIED"}');
  print('manageUsers: ${hasManageUsers ? "✓ GRANTED" : "✗ DENIED"}');
  print('manageRoles: ${hasManageRoles ? "✓ GRANTED" : "✗ DENIED"}');
  print('viewAnalytics: ${hasViewAnalytics ? "✓ GRANTED" : "✗ DENIED"}');
  
  if (hasViewDashboard && hasManageUsers && hasManageRoles && hasViewAnalytics) {
    print('\n✓ SUCCESS: SuperAdmin has all tested permissions!');
  } else {
    print('\n✗ FAILURE: SuperAdmin is missing permissions');
  }
}
