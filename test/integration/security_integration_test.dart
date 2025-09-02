import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:clean_flutter/main.dart' as app;
import 'package:clean_flutter/locator.dart';
import 'package:clean_flutter/core/services/ai_powered_security_service.dart';
import 'package:clean_flutter/core/services/advanced_biometrics_service.dart';
import 'package:clean_flutter/core/services/feature_flag_service.dart';
import 'package:clean_flutter/core/services/advanced_encryption_service.dart';
import 'package:clean_flutter/core/services/device_security_service.dart';
import 'package:clean_flutter/core/services/threat_intelligence_platform.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Advanced Security Integration Tests', () {
    setUpAll(() async {
      // Initialize the app
      setupLocator();
    });

    testWidgets('Complete security workflow integration test', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Test 1: Login and navigate to Security Center
      await _performLogin(tester);
      await _navigateToSecurityCenter(tester);

      // Test 2: Access Advanced Services Dashboard
      await _accessAdvancedServicesDashboard(tester);

      // Test 3: Verify service status monitoring
      await _verifyServiceStatusMonitoring(tester);

      // Test 4: Test biometric enrollment flow
      await _testBiometricEnrollment(tester);

      // Test 5: Test feature flag functionality
      await _testFeatureFlagFunctionality(tester);

      // Test 6: Test security threat simulation
      await _testSecurityThreatSimulation(tester);
    });

    testWidgets('Service initialization and health checks', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify all services are initialized
      final aiService = locator<AiPoweredSecurityService>();
      final biometricsService = locator<AdvancedBiometricsService>();
      final featureFlagService = locator<FeatureFlagService>();
      final encryptionService = locator<AdvancedEncryptionService>();
      final deviceSecurityService = locator<DeviceSecurityService>();
      final threatIntelService = locator<ThreatIntelligencePlatform>();

      expect(aiService.isInitialized, isTrue);
      expect(biometricsService.isInitialized, isTrue);
      expect(featureFlagService.isInitialized, isTrue);
      expect(encryptionService.isInitialized, isTrue);
      expect(deviceSecurityService.isInitialized, isTrue);
      expect(threatIntelService.isInitialized, isTrue);
    });

    testWidgets('Real-time security monitoring integration', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      await _performLogin(tester);
      await _navigateToSecurityCenter(tester);

      // Find and tap Advanced Services
      final advancedServicesButton = find.text('Advanced Services');
      expect(advancedServicesButton, findsOneWidget);
      await tester.tap(advancedServicesButton);
      await tester.pumpAndSettle();

      // Verify real-time monitoring is active
      expect(find.text('System Health:'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Wait for service status updates
      await tester.pump(const Duration(seconds: 2));

      // Verify service cards are displayed
      expect(find.text('AI-Powered Security'), findsOneWidget);
      expect(find.text('Advanced Biometrics'), findsOneWidget);
      expect(find.text('Threat Intelligence'), findsOneWidget);
    });

    testWidgets('Error handling and recovery integration', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      await _performLogin(tester);

      // Simulate network error by accessing a service that might fail
      final deviceSecurityService = locator<DeviceSecurityService>();
      
      // Trigger a potential error scenario
      try {
        deviceSecurityService.getDeviceInfo();
      } catch (e) {
        // Verify error handling UI appears
        await tester.pump();
        // Look for error indicators or retry buttons
        expect(find.byIcon(Icons.error_outline), findsWidgets);
      }
    });

    testWidgets('Performance under load integration', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      await _performLogin(tester);
      await _navigateToSecurityCenter(tester);

      // Simulate multiple concurrent operations
      final encryptionService = locator<AdvancedEncryptionService>();
      final aiService = locator<AiPoweredSecurityService>();

      // Start multiple operations simultaneously
      final futures = <Future>[];
      
      for (int i = 0; i < 10; i++) {
        futures.add(encryptionService.generateKey(algorithm: 'AES-256-GCM', keyType: 'stream'));
        futures.add(aiService.analyzeSecurityEvent({
          'user_id': 'test_user_$i',
          'activity': 'concurrent_test',
        }));
      }

      // Wait for all operations to complete
      await Future.wait(futures);

      // Verify UI remains responsive
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}

Future<void> _performLogin(WidgetTester tester) async {
  // Look for login fields
  final emailField = find.byType(TextFormField).first;
  final passwordField = find.byType(TextFormField).last;

  if (emailField != passwordField) {
    await tester.enterText(emailField, 'admin@example.com');
    await tester.enterText(passwordField, 'admin123');
    
    // Find and tap login button
    final loginButton = find.text('Login');
    if (loginButton.evaluate().isNotEmpty) {
      await tester.tap(loginButton);
      await tester.pumpAndSettle();
    }
  }
}

Future<void> _navigateToSecurityCenter(WidgetTester tester) async {
  // Look for Security Center navigation
  final securityCenterButton = find.text('Security Center');
  if (securityCenterButton.evaluate().isNotEmpty) {
    await tester.tap(securityCenterButton);
    await tester.pumpAndSettle();
  } else {
    // Alternative navigation path
    final drawerButton = find.byIcon(Icons.menu);
    if (drawerButton.evaluate().isNotEmpty) {
      await tester.tap(drawerButton);
      await tester.pumpAndSettle();
      
      final securityOption = find.text('Security Center');
      if (securityOption.evaluate().isNotEmpty) {
        await tester.tap(securityOption);
        await tester.pumpAndSettle();
      }
    }
  }
}

Future<void> _accessAdvancedServicesDashboard(WidgetTester tester) async {
  // Look for Advanced Services card or button
  final advancedServicesCard = find.text('Advanced Services');
  expect(advancedServicesCard, findsOneWidget);
  
  await tester.tap(advancedServicesCard);
  await tester.pumpAndSettle();
  
  // Verify we're on the Advanced Services Dashboard
  expect(find.text('Advanced Services Dashboard'), findsOneWidget);
}

Future<void> _verifyServiceStatusMonitoring(WidgetTester tester) async {
  // Verify service status indicators
  expect(find.text('System Health:'), findsOneWidget);
  expect(find.byType(LinearProgressIndicator), findsOneWidget);
  
  // Check for service cards
  expect(find.text('AI-Powered Security'), findsOneWidget);
  expect(find.text('Advanced Biometrics'), findsOneWidget);
  expect(find.text('Feature Flags'), findsOneWidget);
  expect(find.text('Advanced Encryption'), findsOneWidget);
  
  // Tap on a service card to view details
  final aiServiceCard = find.text('AI-Powered Security');
  await tester.tap(aiServiceCard);
  await tester.pumpAndSettle();
  
  // Verify service details dialog
  expect(find.text('Service Metrics'), findsOneWidget);
  expect(find.text('Close'), findsOneWidget);
  
  // Close the dialog
  await tester.tap(find.text('Close'));
  await tester.pumpAndSettle();
}

Future<void> _testBiometricEnrollment(WidgetTester tester) async {
  // Navigate back to main security area
  final backButton = find.byIcon(Icons.arrow_back);
  if (backButton.evaluate().isNotEmpty) {
    await tester.tap(backButton);
    await tester.pumpAndSettle();
  }
  
  // Look for biometric setup option
  final biometricOption = find.text('Biometric');
  if (biometricOption.evaluate().isNotEmpty) {
    await tester.tap(biometricOption);
    await tester.pumpAndSettle();
    
    // Simulate biometric enrollment
    final enrollButton = find.text('Enroll');
    if (enrollButton.evaluate().isNotEmpty) {
      await tester.tap(enrollButton);
      await tester.pumpAndSettle();
    }
  }
}

Future<void> _testFeatureFlagFunctionality(WidgetTester tester) async {
  final featureFlagService = locator<FeatureFlagService>();
  
  // Test feature flag evaluation
  final userContext = UserContext(
    userId: 'integration_test_user',
    userRole: 'admin',
    tenantId: 'default_tenant',
    attributes: {
      'email': 'test@example.com',
      'permissions': ['read', 'write', 'admin'],
      'sessionId': 'test_session_123',
      'deviceId': 'test_device_456',
      'ipAddress': '127.0.0.1',
      'userAgent': 'Test Agent',
      'lastActivity': DateTime.now(),
    },
    timestamp: DateTime.now(),
  );
  
  final isAdvancedMfaEnabled = await featureFlagService.isFeatureEnabled(
    'advanced_mfa',
    userContext,
  );
  
  expect(isAdvancedMfaEnabled, isA<bool>());
  
  // Test experiment variant assignment
  final variant = featureFlagService.getExperimentVariant(
    'ui_redesign_experiment',
    userContext,
  );
  
  expect(variant, isNotNull);
}

Future<void> _testSecurityThreatSimulation(WidgetTester tester) async {
  final aiService = locator<AiPoweredSecurityService>();
  final deviceSecurityService = locator<DeviceSecurityService>();
  
  // Simulate a security event
  final threatData = {
    'user_id': 'integration_test_user',
    'activity': 'suspicious_login',
    'ip_address': '192.168.1.100',
    'user_agent': 'Suspicious Browser',
    'timestamp': DateTime.now().toIso8601String(),
  };
  
  // Analyze the threat
  final analysisResult = await aiService.analyzeSecurityEvent(threatData);
  expect(analysisResult, isNotNull);
  expect(analysisResult.containsKey('threat_score'), isTrue);
  
  // Check device security
  final deviceInfo = deviceSecurityService.getDeviceInfo();
  expect(deviceInfo, isNotNull);
  expect(deviceInfo?.deviceId, isNotNull);
  
  // Verify threat appears in monitoring
  await tester.pump(const Duration(seconds: 1));
}
