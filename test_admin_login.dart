import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lib/core/services/hybrid_auth_service.dart';
import 'lib/core/services/login_attempts_service.dart';
import 'lib/locator.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Clear any existing data for clean test
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  
  // Setup services
  await setupLocator();
  
  // Get services
  final hybridAuthService = locator<HybridAuthService>();
  final loginAttemptsService = locator<LoginAttemptsService>();
  
  // Initialize services
  await hybridAuthService.initialize();
  await loginAttemptsService.initialize();
  
  print('\n=== Testing Admin Login ===\n');
  
  // Test 1: Check if admin user exists
  print('1. Admin user should be created on initialization');
  
  // Test 2: Try to login with correct credentials
  print('\n2. Testing login with correct credentials:');
  print('   Email: env.hygiene@gmail.com');
  print('   Password: password');
  
  final result = await hybridAuthService.login('env.hygiene@gmail.com', 'password');
  
  if (result['success']) {
    print('   ✓ Login successful!');
    print('   Current user: ${hybridAuthService.currentUser}');
  } else {
    print('   ✗ Login failed!');
    print('   Error: ${result['error']}');
    print('   Attempts remaining: ${result['attemptsRemaining']}');
  }
  
  // Test 3: Check login attempts
  print('\n3. Checking login attempts:');
  final attempts = loginAttemptsService.getRecentAttempts('env.hygiene@gmail.com');
  print('   Total attempts: ${attempts.length}');
  for (var attempt in attempts) {
    print('   - ${attempt.timestamp}: ${attempt.successful ? "Success" : "Failed"}');
  }
  
  // Test 4: Check lockout status
  print('\n4. Checking lockout status:');
  final lockStatus = loginAttemptsService.checkLoginAllowed('env.hygiene@gmail.com');
  print('   Allowed: ${lockStatus['allowed']}');
  print('   Failed attempts: ${lockStatus['failedAttempts']}');
  print('   Attempts remaining: ${lockStatus['attemptsRemaining']}');
  
  print('\n=== Test Complete ===\n');
}
