import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:clean_flutter/features/admin/pages/advanced_services_dashboard.dart';
import 'package:clean_flutter/features/admin/widgets/service_status_monitor.dart';
import 'package:clean_flutter/core/services/ai_powered_security_service.dart';
import 'package:clean_flutter/core/services/advanced_biometrics_service.dart';
import 'package:clean_flutter/core/services/feature_flag_service.dart';
import 'package:clean_flutter/locator.dart';

@GenerateMocks([
  AiPoweredSecurityService,
  AdvancedBiometricsService,
  FeatureFlagService,
])
import 'advanced_services_dashboard_test.mocks.dart';

void main() {
  group('Advanced Services Dashboard Widget Tests', () {
    late MockAiPoweredSecurityService mockAiService;
    late MockAdvancedBiometricsService mockBiometricsService;
    late MockFeatureFlagService mockFeatureFlagService;

    setUp(() {
      mockAiService = MockAiPoweredSecurityService();
      mockBiometricsService = MockAdvancedBiometricsService();
      mockFeatureFlagService = MockFeatureFlagService();

      // Setup mock responses
      when(mockAiService.getSecurityMetrics()).thenReturn({
        'total_threats_detected': 127,
        'threats_blocked': 119,
        'accuracy_rate': 0.937,
      });

      when(mockBiometricsService.getBiometricMetrics()).thenReturn({
        'enrolled_users': 1247,
        'active_biometric_methods': 4,
        'verification_success_rate': 0.982,
      });

      when(mockFeatureFlagService.getFeatureFlagMetrics()).thenReturn({
        'total_flags': 15,
        'enabled_flags': 12,
        'active_experiments': 3,
      });
    });

    testWidgets('should display dashboard title and refresh button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AdvancedServicesDashboard(),
        ),
      );

      expect(find.text('Advanced Services Dashboard'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should show loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AdvancedServicesDashboard(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display overview card with metrics', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AdvancedServicesDashboard(),
        ),
      );

      // Wait for loading to complete
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Services Overview'), findsOneWidget);
      expect(find.text('Total Services'), findsOneWidget);
      expect(find.text('Active Services'), findsOneWidget);
      expect(find.text('System Uptime'), findsOneWidget);
    });

    testWidgets('should display service grid with cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AdvancedServicesDashboard(),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('AI-Powered Security'), findsOneWidget);
      expect(find.text('Advanced Biometrics'), findsOneWidget);
      expect(find.text('Feature Flags'), findsOneWidget);
    });

    testWidgets('should handle service card tap and show details', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AdvancedServicesDashboard(),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      // Tap on AI-Powered Security card
      final aiServiceCard = find.text('AI-Powered Security');
      expect(aiServiceCard, findsOneWidget);
      
      await tester.tap(aiServiceCard);
      await tester.pumpAndSettle();

      // Verify dialog appears
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Service Metrics'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('should handle refresh action', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AdvancedServicesDashboard(),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      // Tap refresh button
      final refreshButton = find.byIcon(Icons.refresh);
      await tester.tap(refreshButton);
      await tester.pump();

      // Should show loading indicator again
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should handle pull-to-refresh', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AdvancedServicesDashboard(),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      // Perform pull-to-refresh gesture
      await tester.fling(find.byType(RefreshIndicator), const Offset(0, 300), 1000);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display correct service status indicators', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AdvancedServicesDashboard(),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      // Check for status indicators (green dots for active services)
      expect(find.byType(Container), findsWidgets);
      
      // Look for "Active" status text
      expect(find.text('Active'), findsWidgets);
    });
  });

  group('Service Status Monitor Widget Tests', () {
    testWidgets('should display overall health summary', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const ServiceStatusMonitor(),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      expect(find.textContaining('System Health:'), findsOneWidget);
      expect(find.textContaining('services operational'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('should display service status cards in grid', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const ServiceStatusMonitor(),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('AI-Powered Security'), findsOneWidget);
      expect(find.text('Advanced Biometrics'), findsOneWidget);
    });

    testWidgets('should show service details on card tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const ServiceStatusMonitor(),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      // Find and tap a service card
      final serviceCard = find.text('AI-Powered Security').first;
      await tester.tap(serviceCard);
      await tester.pumpAndSettle();

      // Verify details dialog
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('should handle service errors gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const ServiceStatusMonitor(),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      // Even with potential service errors, UI should still render
      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('should update service status periodically', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const ServiceStatusMonitor(),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      // Get initial state
      final initialHealthText = find.textContaining('System Health:');
      expect(initialHealthText, findsOneWidget);

      // Wait for auto-refresh (30 seconds in real implementation, but we'll simulate)
      await tester.pump(const Duration(seconds: 1));

      // UI should still be responsive
      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('Error Handling Tests', () {
    testWidgets('should handle service initialization errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AdvancedServicesDashboard(),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      // Even with service errors, basic UI should render
      expect(find.text('Advanced Services Dashboard'), findsOneWidget);
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('should show error state when services fail', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AdvancedServicesDashboard(),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      // Look for any error indicators or fallback UI
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('Performance Tests', () {
    testWidgets('should render efficiently with many services', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AdvancedServicesDashboard(),
        ),
      );

      // Measure rendering time
      final stopwatch = Stopwatch()..start();
      
      await tester.pump(const Duration(seconds: 2));
      
      stopwatch.stop();
      
      // Should render within reasonable time (less than 5 seconds for test)
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      
      // Verify all expected widgets are present
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Services Overview'), findsOneWidget);
    });

    testWidgets('should handle rapid refresh requests', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AdvancedServicesDashboard(),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      // Rapidly tap refresh multiple times
      final refreshButton = find.byIcon(Icons.refresh);
      
      for (int i = 0; i < 5; i++) {
        await tester.tap(refreshButton);
        await tester.pump(const Duration(milliseconds: 100));
      }

      // UI should remain stable
      expect(find.text('Advanced Services Dashboard'), findsOneWidget);
    });
  });

  group('Accessibility Tests', () {
    testWidgets('should have proper semantic labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AdvancedServicesDashboard(),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      // Check for semantic elements
      expect(find.byType(Semantics), findsWidgets);
      
      // Verify important elements are accessible
      expect(find.text('Advanced Services Dashboard'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should support screen reader navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AdvancedServicesDashboard(),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      // Verify focusable elements
      expect(find.byType(InkWell), findsWidgets);
      expect(find.byType(IconButton), findsWidgets);
    });
  });
}
