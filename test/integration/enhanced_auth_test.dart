import 'package:flutter_test/flutter_test.dart';
import 'package:clean_flutter/core/services/enhanced_auth_service.dart';
import 'package:clean_flutter/core/services/advanced_login_security_service.dart';
import 'package:clean_flutter/locator.dart';

void main() {
  group('Enhanced Authentication System Tests', () {
    late EnhancedAuthService enhancedAuth;
    late AdvancedLoginSecurityService securityService;

    setUpAll(() async {
      await setupLocator();
      enhancedAuth = locator<EnhancedAuthService>();
      securityService = locator<AdvancedLoginSecurityService>();
      await enhancedAuth.initialize();
      await securityService.initialize();
    });

    test('Admin user should bypass all security restrictions', () async {
      const adminEmail = 'env.hygiene@gmail.com';
      const adminPassword = 'password';

      // Admin should always be able to login
      final result = await enhancedAuth.login(
        email: adminEmail,
        password: adminPassword,
        ipAddress: '127.0.0.1',
        userAgent: 'Test',
      );

      expect(result['success'], true);
      expect(result['isAdmin'], true);
    });

    test('Regular user should be locked out after failed attempts', () async {
      const testEmail = 'test@example.com';
      const testPassword = 'testpassword';

      // Register test user
      await enhancedAuth.register(email: testEmail, password: testPassword);

      // Make multiple failed attempts
      for (int i = 1; i <= 6; i++) {
        final result = await enhancedAuth.login(
          email: testEmail,
          password: 'wrongpassword',
          ipAddress: '192.168.1.100',
          userAgent: 'Test',
        );

        expect(result['success'], false);

        if (i >= 5) {
          // Should be locked out after 5 failed attempts
          expect(result['lockoutDuration'], isNotNull);
        }
      }

      // Check that user is locked out
      final status = await enhancedAuth.checkLoginAllowed(
        email: testEmail,
        ipAddress: '192.168.1.100',
      );
      expect(status['allowed'], false);
    });

    test('Progressive delays should be applied', () async {
      const testEmail = 'delay@example.com';
      const testPassword = 'testpassword';

      // Register test user
      await enhancedAuth.register(email: testEmail, password: testPassword);

      // Make 3 failed attempts to trigger delay
      for (int i = 1; i <= 3; i++) {
        final result = await enhancedAuth.login(
          email: testEmail,
          password: 'wrongpassword',
          ipAddress: '10.0.0.1',
          userAgent: 'Test',
        );

        expect(result['success'], false);

        if (i == 3) {
          // Should have delay after 3 attempts
          expect(result['delaySeconds'], greaterThan(0));
        }
      }
    });

    test('CAPTCHA should be required after multiple attempts', () async {
      const testEmail = 'captcha@example.com';
      const testPassword = 'testpassword';

      // Register test user
      await enhancedAuth.register(email: testEmail, password: testPassword);

      // Make 4 failed attempts to trigger CAPTCHA
      for (int i = 1; i <= 4; i++) {
        final result = await enhancedAuth.login(
          email: testEmail,
          password: 'wrongpassword',
          ipAddress: '172.16.0.1',
          userAgent: 'Test',
        );

        expect(result['success'], false);

        if (i == 4) {
          // Should require CAPTCHA after 4 attempts
          expect(result['requiresCaptcha'], true);
        }
      }
    });

    test('Risk scoring should work correctly', () async {
      // Test low risk scenario
      final lowRisk = await securityService.calculateRiskScore(
        email: 'user@example.com',
        ipAddress: '127.0.0.1',
        userAgent: 'Chrome',
        failedAttempts: 0,
      );
      expect(lowRisk, lessThan(30));

      // Test high risk scenario
      final highRisk = await securityService.calculateRiskScore(
        email: 'user@example.com',
        ipAddress: '1.2.3.4', // Unknown IP
        userAgent: 'Bot',
        failedAttempts: 5,
      );
      expect(highRisk, greaterThan(70));
    });

    test('IP blocking should work', () async {
      const maliciousIp = '1.2.3.4';
      
      // Block IP
      await securityService.blockIp(maliciousIp, 'Test block');
      
      // Check that login is blocked for this IP
      final status = await enhancedAuth.checkLoginAllowed(
        email: 'any@example.com',
        ipAddress: maliciousIp,
      );
      expect(status['allowed'], false);
      expect(status['reason'], contains('IP address is blocked'));
    });

    test('Admin functions should work', () async {
      const testEmail = 'unlock@example.com';
      
      // Register and lock user
      await enhancedAuth.register(email: testEmail, password: 'password');
      
      // Make failed attempts to lock user
      for (int i = 0; i < 6; i++) {
        await enhancedAuth.login(
          email: testEmail,
          password: 'wrong',
          ipAddress: '192.168.1.1',
          userAgent: 'Test',
        );
      }
      
      // Verify user is locked
      var status = await enhancedAuth.checkLoginAllowed(
        email: testEmail,
        ipAddress: '192.168.1.1',
      );
      expect(status['allowed'], false);
      
      // Admin unlock
      await enhancedAuth.unlockUser(testEmail);
      
      // Verify user is unlocked
      status = await enhancedAuth.checkLoginAllowed(
        email: testEmail,
        ipAddress: '192.168.1.1',
      );
      expect(status['allowed'], true);
    });
  });
}
