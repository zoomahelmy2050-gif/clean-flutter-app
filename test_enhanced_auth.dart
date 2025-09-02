import 'dart:developer' as developer;
import 'lib/locator.dart';
import 'lib/core/services/enhanced_auth_service.dart';
import 'lib/core/services/advanced_login_security_service.dart';

/// Simple test script to verify the enhanced authentication system
void main() async {
  print('=== Enhanced Authentication System Test ===\n');
  
  try {
    // Initialize services
    await setupLocator();
    
    final enhancedAuth = locator<EnhancedAuthService>();
    final securityService = locator<AdvancedLoginSecurityService>();
    
    await enhancedAuth.initialize();
    await securityService.initialize();
    
    print('✓ Services initialized successfully\n');
    
    // Test 1: Admin user login
    print('Test 1: Admin user login');
    final adminResult = await enhancedAuth.login(
      email: 'env.hygiene@gmail.com',
      password: 'password',
      ipAddress: '127.0.0.1',
      userAgent: 'Test Script',
    );
    print('Admin login result: ${adminResult['success'] ? 'SUCCESS' : 'FAILED'}');
    if (!adminResult['success']) {
      print('Error: ${adminResult['error']}');
    }
    print('');
    
    // Test 2: Regular user failed attempts
    print('Test 2: Failed login attempts for regular user');
    const testEmail = 'test@example.com';
    
    // Register test user first
    final registerResult = await enhancedAuth.register(
      email: testEmail,
      password: 'correctpassword',
    );
    print('Test user registration: ${registerResult['success'] ? 'SUCCESS' : 'FAILED'}');
    
    // Try wrong password multiple times
    for (int i = 1; i <= 6; i++) {
      final result = await enhancedAuth.login(
        email: testEmail,
        password: 'wrongpassword$i',
        ipAddress: '192.168.1.100',
        userAgent: 'Test Script',
      );
      
      print('Attempt $i: ${result['success'] ? 'SUCCESS' : 'FAILED'}');
      if (!result['success']) {
        print('  Error: ${result['error']}');
        if (result['remainingAttempts'] != null) {
          print('  Remaining attempts: ${result['remainingAttempts']}');
        }
        if (result['delaySeconds'] != null) {
          print('  Delay required: ${result['delaySeconds']} seconds');
        }
        if (result['lockoutDuration'] != null) {
          print('  Lockout duration: ${result['lockoutDuration']} seconds');
        }
        if (result['requiresCaptcha'] == true) {
          print('  CAPTCHA required');
        }
      }
      print('');
    }
    
    // Test 3: Check lockout status
    print('Test 3: Check lockout status');
    final lockoutStatus = await enhancedAuth.checkLoginAllowed(
      email: testEmail,
      ipAddress: '192.168.1.100',
    );
    print('Login allowed: ${lockoutStatus['allowed']}');
    if (!lockoutStatus['allowed']) {
      print('Lockout reason: ${lockoutStatus['reason']}');
      print('Lockout duration: ${lockoutStatus['lockoutDuration']} seconds');
    }
    print('');
    
    // Test 4: Admin unlock user
    print('Test 4: Admin unlock user');
    await enhancedAuth.unlockUser(testEmail);
    print('✓ User unlocked by admin');
    
    // Test 5: Successful login after unlock
    print('\nTest 5: Login after unlock');
    final successResult = await enhancedAuth.login(
      email: testEmail,
      password: 'correctpassword',
      ipAddress: '192.168.1.100',
      userAgent: 'Test Script',
    );
    print('Login after unlock: ${successResult['success'] ? 'SUCCESS' : 'FAILED'}');
    print('');
    
    // Test 6: Risk scoring
    print('Test 6: Risk scoring examples');
    final riskScore1 = await securityService.calculateRiskScore(
      email: testEmail,
      ipAddress: '127.0.0.1', // Local IP - low risk
      userAgent: 'Test Script',
      failedAttempts: 0,
    );
    print('Risk score for local IP, no failed attempts: $riskScore1');
    
    final riskScore2 = await securityService.calculateRiskScore(
      email: testEmail,
      ipAddress: '192.168.1.100', // Different IP
      userAgent: 'Test Script',
      failedAttempts: 3,
    );
    print('Risk score for different IP, 3 failed attempts: $riskScore2');
    
    print('\n=== Test completed successfully ===');
    
  } catch (e, stackTrace) {
    print('❌ Test failed with error: $e');
    print('Stack trace: $stackTrace');
  }
}
