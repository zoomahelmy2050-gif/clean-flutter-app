import 'package:clean_flutter/features/admin/services/zero_trust_service.dart';
import 'package:clean_flutter/features/admin/services/logging_service.dart';
import 'package:clean_flutter/features/admin/services/forensics_investigation_service.dart';
import 'package:clean_flutter/features/admin/services/third_party_integrations_service.dart';
import 'features/admin/services/compliance_reporting_service.dart' as admin_compliance;
import 'features/admin/services/security_orchestration_service.dart';
import 'features/admin/services/performance_monitoring_service.dart';
import 'features/admin/services/emerging_threats_service.dart';
import 'features/auth/widgets/realtime_notification_widget.dart';
import 'core/services/background_sync_service.dart';
import 'core/services/realtime_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'features/auth/login_page.dart';
import 'features/auth/signup_page.dart';
import 'features/home/home_page.dart';
import 'features/auth/otp/otp_send_page.dart';
import 'features/auth/backup_codes/backup_codes_page.dart';
import 'features/auth/backup_codes/backup_code_login_page.dart';
import 'features/auth/password_reset/forgot_password_page.dart';
import 'package:clean_flutter/features/auth/password_reset/reset_password_page.dart';
import 'features/home/pages/totp_codes_page.dart';
import 'features/home/pages/add_totp_page.dart';
import 'package:clean_flutter/locator.dart';
import 'features/auth/services/auth_service.dart';
import 'core/services/hybrid_auth_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/encrypted_storage_service.dart';
import 'core/services/totp_manager_service.dart';
// Removed non-existent services
import 'features/admin/services/summary_email_scheduler.dart';
import 'features/admin/services/ai_security_copilot_service.dart';
import 'features/admin/services/dashboard_customization_service.dart';
import 'features/admin/security_center_page.dart';
import 'features/admin/pages/staff_user_management_page.dart';
import 'features/admin/pages/superuser_approval_dashboard.dart';
import 'package:clean_flutter/core/services/language_service.dart';
import 'package:clean_flutter/core/services/theme_service.dart';
import 'generated/app_localizations.dart';
import 'package:clean_flutter/core/services/simple_sync_service.dart';
import 'package:clean_flutter/core/services/threat_monitoring_service.dart';
import 'package:clean_flutter/core/services/ip_access_control_service.dart';
import 'package:clean_flutter/core/services/device_fingerprinting_service.dart';
import 'package:clean_flutter/core/services/incident_response_service.dart';
import 'package:clean_flutter/core/services/rate_limiting_service.dart';
import 'package:clean_flutter/core/services/compliance_reporting_service.dart';
import 'package:clean_flutter/core/services/security_policy_service.dart';
import 'package:clean_flutter/core/services/vulnerability_scanning_service.dart';
import 'package:clean_flutter/core/services/audit_trail_service.dart';
import 'package:clean_flutter/core/services/security_settings_service.dart';
import 'package:clean_flutter/core/services/connectivity_service.dart';
import 'package:clean_flutter/core/services/pending_actions_service.dart';
import 'package:clean_flutter/features/settings/pages/backend_sync_page.dart';
import 'package:clean_flutter/core/services/ai_powered_security_service.dart';
import 'package:clean_flutter/core/services/advanced_biometrics_service.dart';
import 'package:clean_flutter/core/services/smart_onboarding_service.dart';
import 'package:clean_flutter/core/services/enhanced_accessibility_service.dart';
import 'package:clean_flutter/core/services/localization_service.dart';
import 'package:clean_flutter/core/services/multi_tenant_service.dart';
import 'package:clean_flutter/core/services/executive_reporting_service.dart';
import 'package:clean_flutter/core/services/integration_hub_service.dart';
import 'package:clean_flutter/core/services/api_gateway_service.dart';
import 'package:clean_flutter/core/services/health_monitoring_service.dart';
import 'package:clean_flutter/core/services/feature_flag_service.dart';
import 'package:clean_flutter/core/services/threat_intelligence_platform.dart';
import 'package:clean_flutter/core/services/real_time_analytics_service.dart';
import 'package:clean_flutter/core/services/automated_incident_response_service.dart';
import 'package:clean_flutter/core/services/hardware_mfa_service.dart';
import 'package:clean_flutter/core/services/zero_trust_network_service.dart';
import 'package:clean_flutter/core/services/quantum_resistant_crypto_service.dart';
import 'package:clean_flutter/core/services/security_compliance_automation_service.dart';
import 'package:clean_flutter/core/services/mobile_device_management_service.dart';
import 'package:clean_flutter/core/services/advanced_forensics_service.dart';
import 'package:clean_flutter/core/services/production_database_service.dart';
import 'package:clean_flutter/core/services/production_crypto_service.dart';
import 'package:clean_flutter/core/services/advanced_login_monitor.dart';
import 'package:clean_flutter/core/services/enhanced_auth_service.dart';
import 'package:clean_flutter/core/services/rbac_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Failed to load .env file: $e');
    // Continue without .env file
  }
  
  // Initialize Firebase first
  try {
    await Firebase.initializeApp();
    
    // Initialize Firebase Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    debugPrint('App will continue without Firebase features');
  }
  
  await setupLocator();
  await locator<HybridAuthService>().initialize();
  await locator<AdvancedLoginMonitor>().initialize();
  await locator<EnhancedAuthService>().initialize();
  await locator<NotificationService>().initialize();
  
  // Initialize real-time notifications
  final realtimeNotifications = locator<RealtimeNotificationService>();
  realtimeNotifications.connect();
  
  // Initialize background sync
  await locator<BackgroundSyncService>().initialize();
  
  await locator<AuthService>().init();
  await locator<SimpleSyncService>().init();
  // Load persisted security logs
  await locator<LoggingService>().init();
  
  // Initialize TOTP services
  await locator<EncryptedStorageService>().initialize();
  await locator<TotpManagerService>().initialize();
  
  // Initialize RBAC service with mock user for development
  await locator<RBACService>().initialize('mock-user-id');
  
  // Initialize security services
  await locator<ThreatMonitoringService>().initialize();
  await locator<IPAccessControlService>().initialize();
  await locator<DeviceFingerprintingService>().initialize();
  await locator<IncidentResponseService>().initialize();
  await locator<RateLimitingService>().initialize();
  await locator<ComplianceReportingService>().initialize();
  await locator<SecurityPolicyService>().initialize();
  await locator<VulnerabilityScanningService>().initialize();
  await locator<AuditTrailService>().initialize();
  
  // Initialize advanced security services
  await locator<AiPoweredSecurityService>().initialize();
  await locator<AdvancedBiometricsService>().initialize();
  await locator<SmartOnboardingService>().initialize();
  await locator<EnhancedAccessibilityService>().initialize();
  await locator<LocalizationService>().initialize();
  await locator<MultiTenantService>().initialize();
  await locator<ExecutiveReportingService>().initialize();
  await locator<IntegrationHubService>().initialize();
  await locator<ApiGatewayService>().initialize();
  await locator<HealthMonitoringService>().initialize();
  await locator<FeatureFlagService>().initialize();
  await locator<ThreatIntelligencePlatform>().initialize();
  
  // Initialize new advanced security services
  await locator<RealTimeAnalyticsService>().initialize();
  await locator<AutomatedIncidentResponseService>().initialize();
  await locator<HardwareMfaService>().initialize();
  await locator<ZeroTrustNetworkService>().initialize();
  await locator<QuantumResistantCryptoService>().initialize();
  await locator<SecurityComplianceAutomationService>().initialize();
  await locator<MobileDeviceManagementService>().initialize();
  await locator<AdvancedForensicsService>().initialize();
  
  // Environment variables already loaded above
  
  // Initialize production backend services AFTER dotenv is loaded
  await locator<ProductionDatabaseService>().initialize();
  await locator<ProductionCryptoService>().initialize();
  // Start summary email scheduler (app-lifecycle bound) after env is loaded
  locator<SummaryEmailScheduler>().start();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeService>(
          create: (_) => locator<ThemeService>(),
        ),
        ChangeNotifierProvider<HybridAuthService>(
          create: (_) => locator<HybridAuthService>(),
        ),
        ChangeNotifierProvider<NotificationService>(
          create: (_) => locator<NotificationService>(),
        ),
        // Security Services Providers
        ChangeNotifierProvider<ThreatMonitoringService>(
          create: (_) => locator<ThreatMonitoringService>(),
        ),
        ChangeNotifierProvider<IPAccessControlService>(
          create: (_) => locator<IPAccessControlService>(),
        ),
        ChangeNotifierProvider<DeviceFingerprintingService>(
          create: (_) => locator<DeviceFingerprintingService>(),
        ),
        ChangeNotifierProvider<IncidentResponseService>(
          create: (_) => locator<IncidentResponseService>(),
        ),
        ChangeNotifierProvider<RateLimitingService>(
          create: (_) => locator<RateLimitingService>(),
        ),
        ChangeNotifierProvider<ComplianceReportingService>(
          create: (_) => locator<ComplianceReportingService>(),
        ),
        ChangeNotifierProvider<SecurityPolicyService>(
          create: (_) => locator<SecurityPolicyService>(),
        ),
        ChangeNotifierProvider<VulnerabilityScanningService>(
          create: (_) => locator<VulnerabilityScanningService>(),
        ),
        ChangeNotifierProvider<AuditTrailService>(
          create: (_) => locator<AuditTrailService>(),
        ),
        ChangeNotifierProvider<SecuritySettingsService>(
          create: (_) => locator<SecuritySettingsService>(),
        ),
        ChangeNotifierProvider<PendingActionsService>(
          create: (_) => locator<PendingActionsService>(),
        ),
        ChangeNotifierProvider<ConnectivityService>(
          create: (_) => locator<ConnectivityService>(),
        ),
        ChangeNotifierProvider<LanguageService>(
          create: (_) => locator<LanguageService>(),
        ),
        ChangeNotifierProvider<TotpManagerService>(
          create: (_) => locator<TotpManagerService>(),
        ),
        // Provider<EmailOtpService>(
        //   create: (_) => EmailOtpService(dotenv: dotenv),
        // ),
        ChangeNotifierProvider<AuthService>(
          create: (_) => locator<AuthService>(),
        ),
        ChangeNotifierProvider<AISecurityCopilotService>(
          create: (_) => locator<AISecurityCopilotService>(),
        ),
        ChangeNotifierProvider<DashboardCustomizationService>(
          create: (_) => locator<DashboardCustomizationService>(),
        ),
        ChangeNotifierProvider<ZeroTrustService>(
          create: (_) => locator<ZeroTrustService>(),
        ),
        ChangeNotifierProvider<ForensicsInvestigationService>(
          create: (_) => locator<ForensicsInvestigationService>(),
        ),
        ChangeNotifierProvider(
          create: (_) => locator<ThirdPartyIntegrationsService>(),
        ),
        ChangeNotifierProvider(
          create: (_) => locator<admin_compliance.ComplianceReportingService>(),
        ),
        ChangeNotifierProvider(
          create: (_) => locator<SecurityOrchestrationService>(),
        ),
        ChangeNotifierProvider(
          create: (_) => locator<PerformanceMonitoringService>(),
        ),
        ChangeNotifierProvider(
          create: (_) => locator<EmergingThreatsService>(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
        final auth = locator<AuthService>();
        final String? current = auth.currentUser;
        final bool hasSession = (current != null && current.isNotEmpty);
        final bool isAdmin = hasSession && current.toLowerCase() == 'env.hygiene@gmail.com';
        final Widget initialHome = hasSession
            ? (isAdmin ? const SecurityCenterPage() : const HomePage())
            : const LoginPage();
        return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return RealtimeNotificationWidget(
          child: MaterialApp(
            title: 'Security Center',
            theme: AppTheme.lightTheme,
          // Internationalization configuration
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English
            Locale('ar', ''), // Arabic
          ],
          locale: context.watch<LanguageService>().currentLocale,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.themeMode,
          home: initialHome,
          onGenerateRoute: (settings) {
            if (settings.name == ResetPasswordPage.routeName) {
              final args = settings.arguments as Map<String, String>;
              return MaterialPageRoute(
                builder: (context) {
                  return ResetPasswordPage(
                    email: args['email']!,
                    otp: args['otp']!,
                  );
                },
              );
            }
            return null;
          },
          routes: {
            LoginPage.routeName: (_) => const LoginPage(),
            SignupPage.routeName: (_) => const SignupPage(),
            HomePage.routeName: (_) => const HomePage(),
            OtpSendPage.routeName: (_) => const OtpSendPage(),
            BackupCodesPage.routeName: (_) => const BackupCodesPage(),
            BackupCodeLoginPage.routeName: (_) => const BackupCodeLoginPage(),
            ForgotPasswordPage.routeName: (_) => const ForgotPasswordPage(),
            '/backend-sync': (_) => const BackendSyncPage(),
            '/totp-codes': (_) => const TotpCodesPage(),
            '/add-totp': (_) => const AddTotpPage(),
            '/staff-user-management': (_) => const StaffUserManagementPage(),
            '/superuser-approval': (_) => const SuperuserApprovalDashboard(),
            // The ResetPasswordPage requires arguments, so we handle it in onGenerateRoute
            // OtpVerifyPage is created with arguments via MaterialPageRoute where needed
          },
        ),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
