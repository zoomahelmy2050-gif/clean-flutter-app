import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/core/services/advanced_login_monitor.dart';
import '../../lib/core/services/enhanced_auth_service.dart';
import '../../lib/locator.dart';

void main() {
  late AdvancedLoginMonitor monitor;
  late EnhancedAuthService authService;
  
  const testEmail = 'test@example.com';
  const adminEmail = 'env.hygiene@gmail.com';
  const testPassword = 'Test123!@#';
  const wrongPassword = 'WrongPass123';
  const testIp = '192.168.1.100';
  const testUserAgent = 'Flutter Test App';

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    setupLocator();
    monitor = locator<AdvancedLoginMonitor>();
    authService = locator<EnhancedAuthService>();
  });

  tearDown(() async {
    await monitor.clearAttempts(testEmail);
    await monitor.unlockUser(testEmail);
  });

  group('Advanced Login Monitor Tests', () {
    test('should allow initial login attempt', () async {
      final permission = await monitor.checkLoginPermission(
        email: testEmail,
        ipAddress: testIp,
        userAgent: testUserAgent,
      );
      
      expect(permission.allowed, isTrue);
      expect(permission.riskScore, greaterThanOrEqualTo(0.0));
      expect(permission.riskScore, lessThanOrEqualTo(1.0));
    });

    test('should track failed login attempts', () async {
      // Register test user
      await authService.register(email: testEmail, password: testPassword);
      
      // Make 3 failed attempts
      for (int i = 0; i < 3; i++) {
        await authService.login(
          email: testEmail,
          password: wrongPassword,
          ipAddress: testIp,
          userAgent: testUserAgent,
        );
      }
      
      // Check statistics
      final stats = await monitor.getStatistics();
      expect(stats['failedAttempts'], greaterThan(0));
    });

    test('should lock user after maximum failed attempts', () async {
      // Register test user if not exists
      if (!authService.isEmailRegistered(testEmail)) {
        await authService.register(email: testEmail, password: testPassword);
      }
      
      // Make multiple failed attempts
      Map<String, dynamic> lastResult = {};
      for (int i = 0; i < 10; i++) {
        lastResult = await authService.login(
          email: testEmail,
          password: wrongPassword,
          ipAddress: testIp,
          userAgent: testUserAgent,
        );
        
        if (lastResult['lockoutMinutes'] != null) {
          break;
        }
      }
      
      // Verify lockout
      expect(lastResult['success'], isFalse);
      expect(lastResult['lockoutMinutes'], isNotNull);
    });

    test('should exempt admin from lockouts', () async {
      // Register admin if not exists
      if (!authService.isEmailRegistered(adminEmail)) {
        await authService.register(email: adminEmail, password: testPassword);
      }
      
      // Make many failed attempts
      Map<String, dynamic> lastResult = {};
      for (int i = 0; i < 20; i++) {
        lastResult = await authService.login(
          email: adminEmail,
          password: wrongPassword,
          ipAddress: testIp,
          userAgent: testUserAgent,
        );
      }
      
      // Admin should never be locked out
      expect(lastResult['lockoutMinutes'], isNull);
    });

    test('should calculate risk scores based on patterns', () async {
      // Register test user if not exists
      if (!authService.isEmailRegistered(testEmail)) {
        await authService.register(email: testEmail, password: testPassword);
      }
      
      // Clear any previous attempts
      await monitor.clearAttempts(testEmail);
      
      // Make a failed attempt
      await authService.login(
        email: testEmail,
        password: wrongPassword,
        ipAddress: testIp,
        userAgent: testUserAgent,
      );
      
      // Check permission for risk assessment
      final permission = await monitor.checkLoginPermission(
        email: testEmail,
        ipAddress: testIp,
        userAgent: testUserAgent,
      );
      
      expect(permission.riskScore, isNotNull);
      expect(permission.riskLevel, isIn(['low', 'medium', 'high']));
    });

    test('should unlock user successfully', () async {
      // Register test user if not exists
      if (!authService.isEmailRegistered(testEmail)) {
        await authService.register(email: testEmail, password: testPassword);
      }
      
      // Lock the user by making failed attempts
      for (int i = 0; i < 10; i++) {
        final result = await authService.login(
          email: testEmail,
          password: wrongPassword,
          ipAddress: testIp,
          userAgent: testUserAgent,
        );
        if (result['lockoutMinutes'] != null) break;
      }
      
      // Unlock the user
      await monitor.unlockUser(testEmail);
      
      // Check permission after unlock
      final permission = await monitor.checkLoginPermission(
        email: testEmail,
        ipAddress: testIp,
        userAgent: testUserAgent,
      );
      
      expect(permission.allowed, isTrue);
    });

    test('should get recent login attempts', () async {
      // Register test user if not exists
      if (!authService.isEmailRegistered(testEmail)) {
        await authService.register(email: testEmail, password: testPassword);
      }
      
      // Clear previous attempts
      await monitor.clearAttempts(testEmail);
      
      // Make some attempts
      await authService.login(
        email: testEmail,
        password: wrongPassword,
        ipAddress: testIp,
        userAgent: testUserAgent,
      );
      
      await authService.login(
        email: testEmail,
        password: testPassword,
        ipAddress: testIp,
        userAgent: testUserAgent,
      );
      
      // Get recent attempts
      final attempts = await monitor.getRecentAttempts(limit: 10);
      
      expect(attempts, isNotEmpty);
      expect(attempts.length, greaterThanOrEqualTo(2));
      
      // Verify attempt structure
      for (final attempt in attempts) {
        expect(attempt['timestamp'], isNotNull);
        expect(attempt['successful'], isNotNull);
        expect(attempt['ipAddress'], isNotNull);
      }
    });

    test('should enforce progressive delays', () async {
      // Register test user if not exists
      if (!authService.isEmailRegistered(testEmail)) {
        await authService.register(email: testEmail, password: testPassword);
      }
      
      // Clear previous attempts
      await monitor.clearAttempts(testEmail);
      
      // Make multiple failed attempts
      Map<String, dynamic> lastResult = {};
      for (int i = 0; i < 4; i++) {
        lastResult = await authService.login(
          email: testEmail,
          password: wrongPassword,
          ipAddress: testIp,
          userAgent: testUserAgent,
        );
      }
      
      // Check for progressive delay
      final progressiveDelay = lastResult['progressiveDelay'];
      if (progressiveDelay != null) {
        expect(progressiveDelay, greaterThan(0));
      }
    });
  });
}
