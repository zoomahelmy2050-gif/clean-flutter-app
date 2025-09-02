import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lib/core/services/advanced_login_monitor.dart';
import 'lib/core/services/enhanced_auth_service.dart';
import 'lib/locator.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await setupLocator();
  
  // Get services
  final monitor = locator<AdvancedLoginMonitor>();
  final authService = locator<EnhancedAuthService>();
  
  // Test data
  const testEmail = 'test@example.com';
  const adminEmail = 'env.hygiene@gmail.com';
  const testPassword = 'Test123!@#';
  const wrongPassword = 'WrongPass123';
  const testIp = '192.168.1.100';
  const testUserAgent = 'Flutter Test App';
  
  print('\n=== Advanced Login Monitor Test Suite ===\n');
  
  // Test 1: Register test user
  print('Test 1: Registering test user...');
  final regResult = await authService.register(
    email: testEmail,
    password: testPassword,
  );
  print('Registration result: ${regResult['success'] ? 'SUCCESS' : 'FAILED'}');
  if (!regResult['success']) {
    print('Error: ${regResult['error']}');
  }
  
  // Test 2: Check initial permission (should be allowed)
  print('\nTest 2: Checking initial login permission...');
  final initialCheck = await monitor.checkLoginPermission(
    email: testEmail,
    ipAddress: testIp,
    userAgent: testUserAgent,
  );
  print('Initial permission: ${initialCheck.allowed ? 'ALLOWED' : 'DENIED'}');
  print('Risk score: ${initialCheck.riskScore}');
  print('Risk level: ${initialCheck.riskLevel}');
  
  // Test 3: Simulate failed login attempts
  print('\nTest 3: Simulating failed login attempts...');
  for (int i = 1; i <= 5; i++) {
    print('\nAttempt $i:');
    
    // Check permission before attempt
    final preCheck = await monitor.checkLoginPermission(
      email: testEmail,
      ipAddress: testIp,
      userAgent: testUserAgent,
    );
    
    if (!preCheck.allowed) {
      print('  Login blocked: ${preCheck.reason}');
      if (preCheck.lockoutMinutes != null) {
        print('  Lockout duration: ${preCheck.lockoutMinutes} minutes');
      }
      break;
    }
    
    // Try login with wrong password
    final loginResult = await authService.login(
      email: testEmail,
      password: wrongPassword,
      ipAddress: testIp,
      userAgent: testUserAgent,
    );
    
    print('  Login result: ${loginResult['success'] ? 'SUCCESS' : 'FAILED'}');
    print('  Error: ${loginResult['error']}');
    print('  Attempts remaining: ${loginResult['attemptsRemaining']}');
    print('  Risk score: ${loginResult['riskScore']}');
    print('  Risk level: ${loginResult['riskLevel']}');
    
    if (loginResult['progressiveDelay'] != null) {
      print('  Progressive delay: ${loginResult['progressiveDelay']} seconds');
    }
    
    if (loginResult['requiresCaptcha'] == true) {
      print('  CAPTCHA required: YES');
    }
  }
  
  // Test 4: Check lockout status
  print('\nTest 4: Checking lockout status...');
  final lockoutCheck = await monitor.checkLoginPermission(
    email: testEmail,
    ipAddress: testIp,
    userAgent: testUserAgent,
  );
  print('Permission after failed attempts: ${lockoutCheck.allowed ? 'ALLOWED' : 'DENIED'}');
  print('Reason: ${lockoutCheck.reason}');
  if (lockoutCheck.lockoutMinutes != null) {
    print('Lockout remaining: ${lockoutCheck.lockoutMinutes} minutes');
  }
  
  // Test 5: Get security statistics
  print('\nTest 5: Getting security statistics...');
  final stats = await monitor.getStatistics();
  print('Total attempts: ${stats['totalAttempts']}');
  print('Failed attempts: ${stats['failedAttempts']}');
  print('Locked users: ${stats['lockedUsers']}');
  print('Blacklisted IPs: ${stats['blacklistedIPs']}');
  print('Average risk score: ${stats['averageRiskScore']}');
  
  // Test 6: Admin exemption test
  print('\nTest 6: Testing admin exemption...');
  
  // Register admin if not exists
  if (!authService.isEmailRegistered(adminEmail)) {
    await authService.register(
      email: adminEmail,
      password: testPassword,
    );
  }
  
  // Simulate multiple failed attempts for admin
  for (int i = 1; i <= 10; i++) {
    final adminLogin = await authService.login(
      email: adminEmail,
      password: wrongPassword,
      ipAddress: testIp,
      userAgent: testUserAgent,
    );
    
    if (i == 1 || i == 5 || i == 10) {
      print('Admin attempt $i: ${adminLogin['error']}');
      print('  Admin locked out: ${adminLogin['lockoutMinutes'] != null ? 'YES' : 'NO (exempt)'}');
    }
  }
  
  // Test 7: Unlock user
  print('\nTest 7: Unlocking test user...');
  await monitor.unlockUser(testEmail);
  
  final unlockedCheck = await monitor.checkLoginPermission(
    email: testEmail,
    ipAddress: testIp,
    userAgent: testUserAgent,
  );
  print('Permission after unlock: ${unlockedCheck.allowed ? 'ALLOWED' : 'DENIED'}');
  
  // Test 8: Test successful login
  print('\nTest 8: Testing successful login...');
  final successLogin = await authService.login(
    email: testEmail,
    password: testPassword,
    ipAddress: testIp,
    userAgent: testUserAgent,
  );
  print('Login result: ${successLogin['success'] ? 'SUCCESS' : 'FAILED'}');
  print('Risk score: ${successLogin['riskScore']}');
  print('Risk level: ${successLogin['riskLevel']}');
  
  // Test 9: Get recent attempts
  print('\nTest 9: Getting recent login attempts...');
  final recentAttempts = await monitor.getRecentAttempts(testEmail, limit: 5);
  print('Recent attempts for $testEmail:');
  for (final attempt in recentAttempts) {
    final timestamp = DateTime.parse(attempt['timestamp']);
    print('  ${timestamp.toLocal()}: ${attempt['successful'] ? 'SUCCESS' : 'FAILED'} from ${attempt['ipAddress']}');
  }
  
  // Test 10: Clear attempts
  print('\nTest 10: Clearing attempts for test user...');
  await monitor.clearAttempts(testEmail);
  
  final clearedStats = await monitor.getStatistics();
  print('Total attempts after clear: ${clearedStats['totalAttempts']}');
  
  print('\n=== Test Suite Complete ===\n');
  
  // Clean up
  await authService.deleteAccount(testEmail);
  print('Test user cleaned up.');
}
