import 'package:flutter/material.dart';
import 'package:clean_flutter/locator.dart';
import 'package:clean_flutter/features/auth/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Setup locator
  setupLocator();
  
  // Initialize AuthService
  final authService = locator<AuthService>();
  await authService.init();
  
  print('\n========== TESTING USER BLOCK SYSTEM ==========\n');
  
  // Test email
  final testEmail = 'test@gmail.com';
  
  // Check initial state
  print('1. Initial blocked users: ${authService.getBlockedUsers()}');
  print('   Is $testEmail blocked? ${authService.isUserBlocked(testEmail)}');
  
  // Block the user
  print('\n2. Blocking $testEmail...');
  await authService.blockUser(testEmail);
  
  // Check immediately after blocking
  print('3. After blocking:');
  print('   Blocked users: ${authService.getBlockedUsers()}');
  print('   Is $testEmail blocked? ${authService.isUserBlocked(testEmail)}');
  
  // Force reload and check again
  print('\n4. After forced reload:');
  await authService.reloadBlockedUsers();
  print('   Blocked users: ${authService.getBlockedUsers()}');
  print('   Is $testEmail blocked? ${authService.isUserBlocked(testEmail)}');
  
  // Create a new instance to simulate app restart
  print('\n5. Simulating app restart with new AuthService instance...');
  final newAuthService = AuthService();
  await newAuthService.init();
  print('   New instance blocked users: ${newAuthService.getBlockedUsers()}');
  print('   New instance - Is $testEmail blocked? ${newAuthService.isUserBlocked(testEmail)}');
  
  print('\n========== TEST COMPLETE ==========\n');
}
