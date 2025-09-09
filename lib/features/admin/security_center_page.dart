import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:intl/intl.dart';
import '../../locator.dart';
import 'services/logging_service.dart';
import '../auth/services/auth_service.dart';
import '../../core/services/security_data_service.dart';
import '../../generated/app_localizations.dart';
import 'package:clean_flutter/core/services/language_service.dart';
import 'package:clean_flutter/core/services/rbac_service.dart' as legacy_rbac;
import 'threat_intelligence_dashboard.dart';
import 'view_logs_page.dart';
import 'security_settings_page.dart';
import 'summary_emails_page.dart';
import 'pages/ai_assistant_page.dart' as ai_page;
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import '../auth/login_page.dart';
import 'services/summary_email_scheduler.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
// Profile and Security Hub imports
import '../profile/personal_information_page.dart';
import '../profile/notifications_page.dart';
import '../profile/appearance_page.dart';
import '../profile/help_center_page.dart';
import '../profile/send_feedback_page.dart';
import '../profile/security_hub_page.dart';
import '../profile/change_password_page.dart';
import '../profile/active_sessions_page.dart';
import '../profile/security_alerts_page.dart';
import '../profile/account_recovery_page.dart';
import 'package:clean_flutter/features/admin/user_management_page.dart';
import 'package:clean_flutter/features/admin/security_analytics_page.dart';
import '../../core/services/migration_service.dart';
import '../../core/services/backend_sync_service.dart';
import 'package:clean_flutter/features/admin/real_time_monitoring_page.dart';
import 'screens/database_migration_screen.dart';
import 'package:clean_flutter/features/admin/pages/quantum_crypto_dashboard.dart';
import 'package:clean_flutter/features/admin/pages/advanced_services_dashboard.dart' as advanced;
import 'package:clean_flutter/core/services/enhanced_rbac_service.dart';
import 'pages/forensics_investigation_page.dart';
import 'pages/third_party_integrations_page.dart';
import 'pages/compliance_reporting_page.dart';
import 'pages/security_orchestration_page.dart';
import 'pages/performance_monitoring_page.dart';
import 'pages/role_management_page.dart';
import 'pages/emerging_threats_page.dart';
import 'screens/ai_workflows_screen.dart';
import 'package:clean_flutter/features/admin/ui/admin_security_center_page.dart';

class SecurityCenterPage extends StatefulWidget {
  const SecurityCenterPage({super.key});

  @override
  State<SecurityCenterPage> createState() => _SecurityCenterPageState();
}

class _RecentActivityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logging = locator<LoggingService>();
    final fmt = DateFormat.yMMMd().add_jm();

    // Build a merged list of recent events (type, username, timestamp, device, ip)
    final List<_Activity> items = [
      ...logging.failedAttempts.map((e) => _Activity('Failed', e.username, e.timestamp, e.device, e.ip, Icons.warning_amber_rounded, theme.colorScheme.error)),
      ...logging.successfulLogins.map((e) => _Activity('Login', e.username, e.timestamp, e.device, e.ip, Icons.login, theme.colorScheme.primary)),
      ...logging.signUps.map((e) => _Activity('Signup', e.username, e.timestamp, e.device, e.ip, Icons.person_add_alt, theme.colorScheme.secondary)),
    ];
    // Sort by most recent
    items.sort((a, b) => b.time.compareTo(a.time));

    final latest = items.take(8).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Recent Activity', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ViewLogsPage()));
                  },
                  icon: const Icon(Icons.list_alt),
                  label: const Text('View all logs'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (latest.isEmpty)
              Text('No recent activity yet.', style: theme.textTheme.bodyMedium)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (ctx, i) {
                  final a = latest[i];
                  return Row(
                    children: [
                      Icon(a.icon, color: a.color, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${a.type}: ${a.user}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Device: ${a.device ?? '-'}\nIP: ${a.ip ?? '-'}',
                        child: const Icon(Icons.info_outline, size: 16, color: Colors.black45),
                      ),
                      const SizedBox(width: 8),
                      Text(fmt.format(a.time), style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
                    ],
                  );
                },
                separatorBuilder: (context, _) => const Divider(height: 12),
                itemCount: latest.length,
              ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withAlpha((255 * 0.1).round()), borderRadius: BorderRadius.circular(6)),
            child: Text(value, style: theme.textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _Activity {
  final String type; // Failed/Login/Signup
  final String user;
  final DateTime time;
  final String? device;
  final String? ip;
  final IconData icon;
  final Color color;
  _Activity(this.type, this.user, this.time, this.device, this.ip, this.icon, this.color);
}

class _SecurityCenterPageState extends State<SecurityCenterPage> {
  final _emailCtrl = TextEditingController();
  String? _emailError;
  String? _inlineStatus;
  String? _lookedUpKey;
  
  final _securityDataService = locator<SecurityDataService>();
  final rbacService = locator<legacy_rbac.RBACService>();
  
  // Busy state for preventing multiple API calls
  bool _busyKey = false;
  
  // Infograph state
  int _chartDays = 7; // 7, 14, 30
  final GlobalKey _chartKey = GlobalKey();
  int _viewStart = 0;
  int _viewEnd = 6;

  bool _isValidEmail(String email) {
    final r = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return r.hasMatch(email);
  }

  Future<void> _logout() async {
    final auth = locator<AuthService>();
    await auth.logout();
    if (mounted) {
      // Replace the entire page stack with the login page
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _viewEnd = _chartDays - 1;
    _loadSecurityData();
    _initializeRBAC();
  }

  Future<void> _initializeRBAC() async {
    final authService = locator<AuthService>();
    final currentUser = authService.currentUser;
    
    if (currentUser != null) {
      final enhancedRbac = locator<EnhancedRBACService>();
      await enhancedRbac.initialize(currentUser);
    }
  }

  Future<void> _loadSecurityData() async {
    final authService = locator<AuthService>();
    final currentUser = authService.currentUser;
    
    if (currentUser != null) {
      await _securityDataService.loadSecurityData(currentUser);
    }
  }

  void _lookupKey() {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() {
        _emailError = 'Email is required';
        _inlineStatus = null;
        _lookedUpKey = null;
      });
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() {
        _emailError = 'Enter a valid email address';
        _inlineStatus = null;
        _lookedUpKey = null;
      });
      return;
    }
    final auth = locator<AuthService>();
    if (!auth.isEmailRegistered(email)) {
      setState(() {
        _lookedUpKey = null;
        _inlineStatus = 'Email is not registered: $email';
        _emailError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email is not registered')));
      return;
    }
    setState(() {
      _lookedUpKey = auth.getSecurityKey(email);
      _inlineStatus = 'Security Key loaded';
      _emailError = null;
    });
  }

  Future<void> _regenerateKey() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _emailError = 'Enter a valid email address');
      return;
    }
    final auth = locator<AuthService>();
    if (!auth.isEmailRegistered(email)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email is not registered')));
      return;
    }
    setState(() => _busyKey = true);
    try {
      final newKey = await auth.regenerateSecurityKey(email);
      if (!mounted) return;
      setState(() {
        _lookedUpKey = newKey;
        _inlineStatus = 'Security Key regenerated';
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Security Key regenerated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to regenerate: $e')));
    } finally {
      if (mounted) setState(() => _busyKey = false);
    }
  }

  Future<void> _emailKey() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || _lookedUpKey == null) return;
    final host = dotenv.env['SMTP_HOST'] ?? 'smtp.gmail.com';
    final ssl = (dotenv.env['SMTP_SSL'] ?? 'false').toLowerCase() == 'true';
    final port = int.tryParse(dotenv.env['SMTP_PORT'] ?? (ssl ? '465' : '587')) ?? (ssl ? 465 : 587);
    final username = dotenv.env['SMTP_USERNAME'];
    final password = dotenv.env['SMTP_PASSWORD'];
    final fromEmail = dotenv.env['OTP_FROM_EMAIL'] ?? username;
    final fromName = dotenv.env['OTP_FROM_NAME'] ?? 'Your App';
    if (username == null || password == null || fromEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SMTP not configured')));
      return;
    }
    final server = SmtpServer(host, port: port, username: username, password: password, ssl: ssl);
    final message = Message()
      ..from = Address(fromEmail, fromName)
      ..recipients.add(email)
      ..subject = 'Your Security Key'
      ..text = 'Security Key for $email: $_lookedUpKey';
    setState(() => _busyKey = true);
    try {
      await send(message, server);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Security Key emailed')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Email failed: $e')));
    } finally {
      if (mounted) setState(() => _busyKey = false);
    }
  }

  Widget _buildEnhancedRBACCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Permission permission,
    required String requiredRoleText,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    final authService = locator<AuthService>();
    final currentUser = authService.currentUser;
    
    // Always grant access to superadmin email
    if (currentUser != null && currentUser.toLowerCase() == 'env.hygiene@gmail.com') {
      return _ActionCard(
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: onTap,
      );
    }
    
    // For other users, check permissions
    final enhancedRbac = locator<EnhancedRBACService>();
    
    return FutureBuilder<bool>(
      future: enhancedRbac.hasPermission(permission),
      builder: (context, snapshot) {
        final bool hasPermission = snapshot.data ?? false;
    
        return _ActionCard(
          icon: icon,
          title: title,
          subtitle: hasPermission ? subtitle : requiredRoleText,
          onTap: hasPermission
              ? onTap
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Access denied: $requiredRoleText')),
                  );
                },
        );
      },
    );
  }

  List<_DayMetric> _collectMetrics(int days) {
    final logging = locator<LoggingService>();
    final now = DateTime.now();
    List<_DayMetric> list = [];
    for (int i = days - 1; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final next = day.add(const Duration(days: 1));
      int failed = logging.failedAttempts.where((e) => !e.timestamp.isBefore(day) && e.timestamp.isBefore(next)).length;
      int logins = logging.successfulLogins.where((e) => !e.timestamp.isBefore(day) && e.timestamp.isBefore(next)).length;
      int mfa = logging.mfaUsed.where((e) => !e.timestamp.isBefore(day) && e.timestamp.isBefore(next)).length;
      list.add(_DayMetric(day: day, failed: failed, logins: logins, mfa: mfa));
    }
    return list;
  }

  Future<void> _exportChartPng() async {
    try {
      final boundary = _chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chart not ready')));
        return;
      }
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw StateError('Failed to encode chart');
      final pngBytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/infograph_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(pngBytes, flush: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chart saved: $path')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _exportChartCsv() async {
    try {
      final data = _collectMetrics(_chartDays);
      final start = _viewStart.clamp(0, _chartDays - 1);
      final end = _viewEnd.clamp(start, _chartDays - 1);
      final slice = data.sublist(start, end + 1);
      final buf = StringBuffer('date,failed,logins,mfa\n');
      final df = DateFormat('yyyy-MM-dd');
      for (final d in slice) {
        buf.writeln('${df.format(d.day)},${d.failed},${d.logins},${d.mfa}');
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/infograph_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(buf.toString(), flush: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV saved: $path')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV export failed: $e')));
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loggingService = locator<LoggingService>();
    final authService = locator<AuthService>();
    final enhancedRbac = locator<EnhancedRBACService>();
    
    // Initialize RBAC if not already done
    final currentUser = locator<AuthService>().currentUser;
    if (currentUser != null && !enhancedRbac.isInitialized) {
      enhancedRbac.initialize(currentUser);
    }
    
    final failedAttempts = loggingService.getFailedAttemptsCount().toString();
    // These will be used in the dashboard cards
    final activeAlerts = loggingService.getActiveAlertsCount().toString();
    final securityScore = loggingService.getSecurityScore().toStringAsFixed(1);
    final criticalEvents = loggingService.getCriticalEventsCount().toString();
    final biometricEnabled = authService.getBiometricEnabledCount().toString();
    final prefBio = authService.getBiometricPreferenceCount().toString();
    final prefOtp = authService.getOtpPreferenceCount().toString();
    final totpEnrolled = authService.getTotpEnrolledCount().toString();
    final prefTotp = authService.getTotpPreferenceCount().toString();
    final mfaEnabled = loggingService.getMfaUsedCount().toString();
    final mfaUsed = loggingService.getMfaUsedCount().toString();

    return DefaultTabController(
      length: 8,
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<LanguageService>(
            builder: (context, languageService, child) {
              final l10n = AppLocalizations.of(context)!;
              return Text(l10n.securityCenter);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: _logout,
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Dashboard', icon: const Icon(Icons.dashboard_outlined)),
              Tab(text: 'Infograph', icon: const Icon(Icons.bar_chart_outlined)),
              Tab(text: 'TOTP', icon: const Icon(Icons.key_outlined)),
              Tab(text: 'Profile', icon: const Icon(Icons.person_outlined)),
              Tab(text: 'Security Hub', icon: const Icon(Icons.security_outlined)),
              Tab(text: 'Users', icon: const Icon(Icons.people)),
              Tab(text: 'Analytics', icon: const Icon(Icons.analytics)),
              Tab(text: 'Monitoring', icon: const Icon(Icons.monitor)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ===== Overview Tab (existing content) =====
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer<LanguageService>(
                    builder: (context, languageService, child) {
                      final l10n = AppLocalizations.of(context)!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.dashboard,
                            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'A quick snapshot of your site\'s sign-in safety.',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  GridView(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 140,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _StatCard(title: 'MFA enabled', value: mfaEnabled, icon: Icons.verified_user_outlined, color: theme.colorScheme.primary),
                      _StatCard(title: 'MFA used (24h)', value: mfaUsed, icon: Icons.shield_outlined, color: theme.colorScheme.secondary),
                      _StatCard(title: 'Failed attempts (24h)', value: failedAttempts, icon: Icons.warning_amber_outlined, color: theme.colorScheme.error),
                      _StatCard(title: 'Biometric enabled', value: biometricEnabled, icon: Icons.fingerprint, color: theme.colorScheme.primaryContainer),
                      _StatCard(title: 'Pref: Biometric', value: prefBio, icon: Icons.fingerprint_outlined, color: theme.colorScheme.tertiaryContainer),
                      _StatCard(title: 'Pref: Email OTP', value: prefOtp, icon: Icons.email_outlined, color: theme.colorScheme.surfaceContainerHighest),
                      _StatCard(title: 'TOTP enrolled', value: totpEnrolled, icon: Icons.key, color: theme.colorScheme.secondaryContainer),
                      _StatCard(title: 'Pref: TOTP', value: prefTotp, icon: Icons.key_outlined, color: theme.colorScheme.inversePrimary),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Builder(builder: (context) {
                    final compactButtonStyle = ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                    final compactOutlinedButtonStyle = OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                    return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            final host = dotenv.env['SMTP_HOST'] ?? 'smtp.gmail.com';
                            final ssl = (dotenv.env['SMTP_SSL'] ?? 'false').toLowerCase() == 'true';
                            final port = int.tryParse(dotenv.env['SMTP_PORT'] ?? (ssl ? '465' : '587')) ?? (ssl ? 465 : 587);
                            final username = dotenv.env['SMTP_USERNAME'];
                            final password = dotenv.env['SMTP_PASSWORD'];
                            final fromEmail = dotenv.env['OTP_FROM_EMAIL'] ?? username;
                            final fromName = dotenv.env['OTP_FROM_NAME'] ?? 'Your App';
                            if (username == null || password == null || fromEmail == null) {
                              throw StateError('SMTP not configured');
                            }
                            final server = SmtpServer(host, port: port, username: username, password: password, ssl: ssl);
                            final to = 'env.hygiene@gmail.com';
                            final msg = Message()
                              ..from = Address(fromEmail, fromName)
                              ..recipients.add(to)
                              ..subject = 'SMTP Test'
                              ..text = 'SMTP configuration test succeeded.';
                            final report = await send(msg, server);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('SMTP OK: ${report.toString()}')));
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('SMTP test failed: $e')));
                          }
                        },
                        icon: const Icon(Icons.email_outlined),
                        label: const Text('Test SMTP'),
                        style: compactButtonStyle,
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sending summary email...')),
                            );
                            await locator<SummaryEmailScheduler>().sendNow();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Summary email sent')),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Send failed: $e')),
                            );
                          }
                        },
                        icon: const Icon(Icons.send_outlined),
                        label: const Text('Send summary now'),
                        style: compactButtonStyle,
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            final path = await locator<LoggingService>().exportCsv();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Logs exported to: $path')),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Export failed: $e')),
                            );
                          }
                        },
                        icon: const Icon(Icons.save_alt_outlined),
                        label: const Text('Export logs (CSV)'),
                        style: compactOutlinedButtonStyle,
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AdminSecurityCenterPage()),
                          );
                        },
                        icon: const Icon(Icons.admin_panel_settings_outlined),
                        label: const Text('Admin Security Center'),
                        style: compactOutlinedButtonStyle,
                      ),
                    ],
                  ); // End Wrap
                  }), // End Builder
                ],
              ),
            ),
          ),
                SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                // Slightly taller tiles to avoid overflow
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildListDelegate([
                _buildEnhancedRBACCard(
                  context: context,
                  permission: Permission.manageRoles,
                  icon: Icons.admin_panel_settings,
                  title: 'Role Management',
                  subtitle: 'Configure roles and permissions',
                  requiredRoleText: 'Requires super admin role',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RoleManagementPage()),
                    );
                  },
                ),
                _buildEnhancedRBACCard(
                  context: context,
                  permission: Permission.manageSecuritySettings,
                  icon: Icons.security,
                  title: 'Security Settings',
                  subtitle: 'Manage MFA options',
                  requiredRoleText: 'Requires admin role',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SecuritySettingsPage()),
                    );
                  },
                ),
                _buildEnhancedRBACCard(
                  context: context,
                  permission: Permission.viewSecurityAlerts,
                  icon: Icons.email_outlined,
                  title: 'Summary Emails',
                  subtitle: 'Manage notifications',
                  requiredRoleText: 'Requires admin role',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SummaryEmailsPage()),
                    );
                  },
                ),
                // AI Workflows direct access
                _ActionCard(
                  icon: Icons.smart_toy,
                  title: 'AI Workflows',
                  subtitle: 'AI automation & chat',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AIWorkflowsScreen(),
                      ),
                    );
                  },
                ),
                _buildEnhancedRBACCard(
                  context: context,
                  permission: Permission.viewAuditLogs,
                  icon: Icons.view_list_outlined,
                  title: 'View Logs',
                  subtitle: 'Filter recent events',
                  requiredRoleText: 'Requires auditor role',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ViewLogsPage()),
                    );
                  },
                ),
                _ActionCard(
                  icon: Icons.refresh,
                  title: 'Refresh',
                  subtitle: 'Update dashboard',
                  onTap: () {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Dashboard refreshed!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                _buildEnhancedRBACCard(
                  context: context,
                  permission: Permission.manageSIEMIntegration,
                  icon: Icons.integration_instructions,
                  title: 'Third-Party Integrations',
                  subtitle: 'MISP, ServiceNow, CSPM, NVD',
                  requiredRoleText: 'Requires admin role',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ThirdPartyIntegrationsPage(),
                      ),
                    );
                  },
                ),
                _buildEnhancedRBACCard(
                  context: context,
                  permission: Permission.viewCompliance,
                  icon: Icons.assignment_turned_in,
                  title: 'Compliance & Reporting',
                  subtitle: 'Frameworks, audits, and automated assessments',
                  requiredRoleText: 'Requires auditor role',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ComplianceReportingPage(),
                      ),
                    );
                  },
                ),
                _buildEnhancedRBACCard(
                  context: context,
                  permission: Permission.executePlaybooks,
                  icon: Icons.account_tree,
                  title: 'Security Orchestration',
                  subtitle: 'Playbooks, case management, and automation',
                  requiredRoleText: 'Requires security admin role',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SecurityOrchestrationPage(),
                      ),
                    );
                  },
                ),
                _buildEnhancedRBACCard(
                  context: context,
                  permission: Permission.viewReports,
                  icon: Icons.speed,
                  title: 'Performance & Monitoring',
                  subtitle: 'System metrics and SLA tracking',
                  requiredRoleText: 'Requires analyst role',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PerformanceMonitoringPage(),
                      ),
                    );
                  },
                ),
                _buildEnhancedRBACCard(
                  context: context,
                  permission: Permission.viewThreats,
                  icon: Icons.security_update,
                  title: 'Emerging Threats',
                  subtitle: 'IoT, container, API & supply chain security',
                  requiredRoleText: 'Requires security analyst role',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmergingThreatsPage(),
                      ),
                    );
                  },
                ),
                // AI Security Chat - Implemented feature
                _ActionCard(
                  icon: Icons.smart_toy,
                  title: 'AI Security Chat',
                  subtitle: 'AI-powered security assistant',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ai_page.AIAssistantPage()),
                    );
                  },
                ),
                // Threat Intelligence - Implemented
                _ActionCard(
                  icon: Icons.analytics,
                  title: 'Threat Intelligence',
                  subtitle: 'Real-time threat feeds',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ThreatIntelligenceDashboard()),
                    );
                  },
                ),
              ]),
            ),
          ),
                // Blocked Users Management
                SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Blocked Users', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Users in this list cannot log in until unblocked.', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 12),
                      Builder(builder: (context) {
                        final auth = locator<AuthService>();
                        final blocked = auth.getBlockedUsers();
                        if (blocked.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text('No blocked users.', style: theme.textTheme.bodyMedium),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: blocked.length,
                          separatorBuilder: (context, _) => const Divider(height: 12),
                          itemBuilder: (ctx, i) {
                            final email = blocked[i];
                            return Row(
                              children: [
                                const Icon(Icons.person_off_outlined, size: 20, color: Colors.black54),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(email, style: theme.textTheme.bodyMedium),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await auth.unblockUser(email);
                                    await locator<LoggingService>().logAdminAction('unblock_user', email);
                                    if (!context.mounted) return;
                                    setState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unblocked $email')));
                                  },
                                  icon: const Icon(Icons.lock_open),
                                  label: const Text('Unblock'),
                                ),
                              ],
                            );
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
                // User Security Key management
                SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('User Security Key', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Lookup a user\'s Security Key or regenerate a new one to share with the user.', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.search,
                            autofillHints: const [AutofillHints.email],
                            decoration: InputDecoration(
                              labelText: 'User email',
                              hintText: 'name@example.com',
                              helperText: 'Enter a registered email to view or rotate the Security Key',
                              prefixIcon: const Icon(Icons.email_outlined),
                              errorText: _emailError,
                              filled: true,
                              fillColor: const Color(0xFFF7F7F7),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                              ),
                            ),
                            onChanged: (_) {
                              if (_emailError != null || _inlineStatus != null) {
                                setState(() {
                                  _emailError = null;
                                  _inlineStatus = null;
                                });
                              }
                            },
                            onSubmitted: (_) => _lookupKey(),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _busyKey ? null : _lookupKey,
                                icon: const Icon(Icons.search),
                                label: const Text('Lookup'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _busyKey || _lookedUpKey == null ? null : _regenerateKey,
                                icon: _busyKey
                                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.autorenew),
                                label: const Text('Regenerate'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_inlineStatus != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            _inlineStatus!,
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
                          ),
                        ),
                      if (_lookedUpKey != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Current Security Key', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(child: SelectableText(_lookedUpKey!, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2))),
                                  IconButton(
                                    tooltip: 'Copy',
                                    icon: const Icon(Icons.copy),
                                    onPressed: () async {
                                      await Clipboard.setData(ClipboardData(text: _lookedUpKey!));
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                                    },
                                  ),
                                  IconButton(
                                    tooltip: 'Email key',
                                    icon: const Icon(Icons.email_outlined),
                                    onPressed: _busyKey || _lookedUpKey == null ? null : () { _emailKey(); },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
                // Database Migration Section
                SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.cloud_sync, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('Database Migration', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Migrate user data from local storage to centralized database for better scalability.', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MultiProvider(
                                  providers: [
                                    ChangeNotifierProvider(
                                      create: (_) => locator<MigrationService>(),
                                    ),
                                    ChangeNotifierProvider(
                                      create: (_) => locator<BackendSyncService>(),
                                    ),
                                  ],
                                  child: const DatabaseMigrationScreen(),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.settings),
                          label: const Text('Manage Database Migration'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
                // Recent Activity Section
                SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: _RecentActivityCard(),
            ),
          ),
              ],
            ),
            // ===== Infograph Tab =====
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Electronic Infograph', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Daily counts: Failed Attempts, Successful Logins, MFA Used', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          DropdownButton<int>(
                            value: _chartDays,
                            items: const [7, 14, 30]
                                .map((d) => DropdownMenuItem<int>(value: d, child: Text('$d days')))
                                .toList(),
                            onChanged: (v) => setState(() {
                              _chartDays = v ?? 7;
                              _viewStart = 0;
                              _viewEnd = _chartDays - 1;
                            }),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Export chart (PNG)',
                            onPressed: _exportChartPng,
                            icon: const Icon(Icons.download_outlined),
                          ),
                          IconButton(
                            tooltip: 'Export data (CSV)',
                            onPressed: _exportChartCsv,
                            icon: const Icon(Icons.table_view_outlined),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 300,
                        width: double.infinity,
                        child: RepaintBoundary(
                          key: _chartKey,
                          child: Builder(builder: (context) {
                            final all = _collectMetrics(_chartDays);
                            final start = _viewStart.clamp(0, _chartDays - 1);
                            final end = _viewEnd.clamp(start, _chartDays - 1);
                            final visible = all.sublist(start, end + 1);
                            final maxY = [
                              ...visible.map((e) => e.failed),
                              ...visible.map((e) => e.logins),
                              ...visible.map((e) => e.mfa),
                            ].fold<int>(1, (p, e) => e > p ? e : p).toDouble();
                            final spotsFailed = <FlSpot>[];
                            final spotsLogins = <FlSpot>[];
                            final spotsMfa = <FlSpot>[];
                            for (int i = 0; i < visible.length; i++) {
                              spotsFailed.add(FlSpot(i.toDouble(), visible[i].failed.toDouble()));
                              spotsLogins.add(FlSpot(i.toDouble(), visible[i].logins.toDouble()));
                              spotsMfa.add(FlSpot(i.toDouble(), visible[i].mfa.toDouble()));
                            }
                            final df = DateFormat.MMMd();
                            String xLabel(double v) {
                              final idx = v.round().clamp(0, visible.length - 1);
                              return df.format(visible[idx].day);
                            }
                            return LineChart(
                              LineChartData(
                                minX: 0,
                                maxX: (visible.length - 1).toDouble(),
                                minY: 0,
                                maxY: (maxY * 1.2).clamp(1, 1e9),
                                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: (maxY / 4).clamp(1, maxY)),
                                titlesData: FlTitlesData(
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: (visible.length / 6).clamp(1, 6).toDouble(), getTitlesWidget: (v, m) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(xLabel(v), style: const TextStyle(fontSize: 10)),
                                      );
                                    }),
                                  ),
                                ),
                                extraLinesData: ExtraLinesData(
                                  horizontalLines: [
                                    HorizontalLine(y: (maxY * 0.25).clamp(1, maxY), color: Colors.green, strokeWidth: 1, dashArray: [6, 4]),
                                    HorizontalLine(y: (maxY * 0.5).clamp(1, maxY), color: Colors.orange, strokeWidth: 1, dashArray: [6, 4]),
                                    HorizontalLine(y: (maxY * 0.75).clamp(1, maxY), color: Colors.red, strokeWidth: 1, dashArray: [6, 4]),
                                  ],
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: spotsFailed,
                                    isCurved: true,
                                    color: const Color(0xFF00E5FF),
                                    barWidth: 3,
                                    dotData: const FlDotData(show: false),
                                  ),
                                  LineChartBarData(
                                    spots: spotsLogins,
                                    isCurved: true,
                                    color: const Color(0xFF00E676),
                                    barWidth: 3,
                                    dotData: const FlDotData(show: false),
                                  ),
                                  LineChartBarData(
                                    spots: spotsMfa,
                                    isCurved: true,
                                    color: const Color(0xFFFFEA00),
                                    barWidth: 3,
                                    dotData: const FlDotData(show: false),
                                  ),
                                ],
                                lineTouchData: LineTouchData(
                                  enabled: true,
                                  touchTooltipData: LineTouchTooltipData(
                                    tooltipBgColor: Colors.black87,
                                    getTooltipItems: (touchedSpots) {
                                      // Group by x
                                      final byX = <int, List<LineBarSpot>>{};
                                      for (final s in touchedSpots) {
                                        byX.putIfAbsent(s.x.round(), () => []).add(s);
                                      }
                                      final items = <LineTooltipItem>[];
                                      byX.forEach((x, list) {
                                        final dateLabel = xLabel(x.toDouble());
                                        final lines = list.map((s) {
                                          final label = s.bar.color == const Color(0xFF00E5FF)
                                              ? 'Failed'
                                              : s.bar.color == const Color(0xFF00E676)
                                                  ? 'Logins'
                                                  : 'MFA';
                                          return '$label: ${s.y.toStringAsFixed(0)}';
                                        }).join('  ');
                                        items.add(LineTooltipItem('$dateLabel\n$lines', const TextStyle(color: Colors.white)));
                                      });
                                      return items;
                                    },
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.zoom_in_outlined, size: 16, color: Colors.black54),
                          const SizedBox(width: 6),
                          Expanded(
                            child: SliderTheme(
                              data: const SliderThemeData(showValueIndicator: ShowValueIndicator.onDrag),
                              child: RangeSlider(
                                values: RangeValues(_viewStart.toDouble(), _viewEnd.toDouble()),
                                min: 0,
                                max: (_chartDays - 1).toDouble(),
                                divisions: (_chartDays - 1),
                                labels: RangeLabels((_viewStart + 1).toString(), (_viewEnd + 1).toString()),
                                onChanged: (rv) {
                                  setState(() {
                                    _viewStart = rv.start.round();
                                    _viewEnd = rv.end.round();
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        children: const [
                          _LegendDot(color: Color(0xFF00E5FF), label: 'Failed'),
                          _LegendDot(color: Color(0xFF00E676), label: 'Logins'),
                          _LegendDot(color: Color(0xFFFFEA00), label: 'MFA'),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
            // ===== TOTP Advanced Tab =====
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('TOTP MFA', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.list_alt),
                        label: const Text('View logs'),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ViewLogsPage()));
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      _StatChip(
                        icon: Icons.key_outlined,
                        label: 'TOTP used (24h)',
                        value: loggingService.getMfaTotpCount().toString(),
                        color: theme.colorScheme.primary,
                      ),
                      _StatChip(
                        icon: Icons.key,
                        label: 'TOTP enrolled',
                        value: locator<AuthService>().getTotpEnrolledCount().toString(),
                        color: theme.colorScheme.secondary,
                      ),
                      _StatChip(
                        icon: Icons.check_circle_outline,
                        label: 'Pref: TOTP',
                        value: locator<AuthService>().getTotpPreferenceCount().toString(),
                        color: theme.colorScheme.tertiary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.history, size: 18),
                                const SizedBox(width: 6),
                                Text('Recent TOTP events', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Builder(builder: (context) {
                                final logs = List.of(loggingService.mfaTotp)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
                                if (logs.isEmpty) {
                                  return Center(child: Text('No TOTP MFA events recorded yet.', style: theme.textTheme.bodyMedium));
                                }
                                final visible = logs.take(50).toList();
                                final fmt = DateFormat.yMMMd().add_jm();
                                return ListView.separated(
                                  itemCount: visible.length,
                                  separatorBuilder: (context, _) => const Divider(height: 8),
                                  itemBuilder: (ctx, i) {
                                    final e = visible[i];
                                    return ListTile(
                                      leading: const Icon(Icons.key_outlined),
                                      title: Text(e.username),
                                      subtitle: Text('${fmt.format(e.timestamp)} · Device: ${e.device ?? '-'} · IP: ${e.ip ?? '-'}'),
                                    );
                                  },
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ===== Profile Tab =====
            _buildProfileTab(),
            // ===== Security Hub Tab =====
            _buildSecurityHubTab(),
            // ===== User Management Tab =====
            const UserManagementPage(),
            // ===== Security Analytics Tab =====
            const SecurityAnalyticsPage(),
            // ===== Real-Time Monitoring Tab =====
            const RealTimeMonitoringPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Management',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage user profile features and settings',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          _buildProfileFeatureGrid(),
        ],
      ),
    );
  }

  Widget _buildSecurityHubTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security Hub Management',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Advanced security features and user management',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          _buildSecurityHubFeatureGrid(),
        ],
      ),
    );
  }

  Widget _buildProfileFeatureGrid() {
    final features = [
      _FeatureCard(
        title: 'Personal Information',
        subtitle: 'Manage user profile data and preferences',
        icon: Icons.person,
        color: Colors.blue,
        onTap: () => _navigateToPersonalInfo(),
      ),
      _FeatureCard(
        title: 'Notifications',
        subtitle: 'Configure notification preferences',
        icon: Icons.notifications,
        color: Colors.orange,
        onTap: () => _navigateToNotifications(),
      ),
      _FeatureCard(
        title: 'Appearance',
        subtitle: 'Theme and display settings',
        icon: Icons.palette,
        color: Colors.purple,
        onTap: () => _navigateToAppearance(),
      ),
      _FeatureCard(
        title: 'Help Center',
        subtitle: 'Support resources and documentation',
        icon: Icons.help,
        color: Colors.green,
        onTap: () => _navigateToHelpCenter(),
      ),
      _FeatureCard(
        title: 'Send Feedback',
        subtitle: 'Submit feedback and suggestions',
        icon: Icons.feedback,
        color: Colors.teal,
        onTap: () => _navigateToSendFeedback(),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) => features[index],
    );
  }

  Widget _buildSecurityHubFeatureGrid() {
    final features = [
      _FeatureCard(
        title: 'Security Overview',
        subtitle: 'View security metrics and status',
        icon: Icons.security,
        color: Colors.red,
        onTap: () => _navigateToSecurityHub(),
      ),
      _FeatureCard(
        title: 'Advanced Services',
        subtitle: 'Monitor all advanced security services',
        icon: Icons.dashboard,
        color: Colors.deepPurple,
        onTap: () => _navigateToAdvancedServices(),
      ),
      _FeatureCard(
        title: 'Quantum Cryptography',
        subtitle: 'Quantum-resistant encryption management',
        icon: Icons.security,
        color: Colors.purple,
        onTap: () => _navigateToQuantumCrypto(),
      ),
      _FeatureCard(
        title: 'Compliance Automation',
        subtitle: 'Automated compliance monitoring',
        icon: Icons.rule,
        color: Colors.green,
        onTap: () => _navigateToComplianceAutomation(),
      ),
      _FeatureCard(
        title: 'Device Management',
        subtitle: 'Mobile device management and policies',
        icon: Icons.devices,
        color: Colors.orange,
        onTap: () => _navigateToMdm(),
      ),
      _FeatureCard(
        title: 'Digital Forensics',
        subtitle: 'Forensic investigation and analysis',
        icon: Icons.search,
        color: Colors.red,
        onTap: () => _navigateToForensics(),
      ),
      _FeatureCard(
        title: 'Change Password',
        subtitle: 'Password management for users',
        icon: Icons.lock,
        color: Colors.indigo,
        onTap: () => _navigateToChangePassword(),
      ),
      _FeatureCard(
        title: 'Active Sessions',
        subtitle: 'Monitor and manage user sessions',
        icon: Icons.devices,
        color: Colors.cyan,
        onTap: () => _navigateToActiveSessions(),
      ),
      _FeatureCard(
        title: 'Security Alerts',
        subtitle: 'Configure security notifications',
        icon: Icons.warning,
        color: Colors.amber,
        onTap: () => _navigateToSecurityAlerts(),
      ),
      _FeatureCard(
        title: 'Account Recovery',
        subtitle: 'Recovery methods and backup options',
        icon: Icons.restore,
        color: Colors.lightGreen,
        onTap: () => _navigateToAccountRecovery(),
      ),
      _FeatureCard(
        title: '2FA Management',
        subtitle: 'Two-factor authentication settings',
        icon: Icons.verified_user,
        color: Colors.teal,
        onTap: () => _navigateToTwoFactor(),
      ),
      _FeatureCard(
        title: 'Test Summary Email',
        subtitle: 'Test and configure summary emails',
        icon: Icons.email,
        color: Colors.blue,
        onTap: () => _navigateToTestEmail(),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) => features[index],
    );
  }

  // Profile navigation methods
  void _navigateToPersonalInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PersonalInformationPage(),
      ),
    );
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsPage(),
      ),
    );
  }

  void _navigateToAppearance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AppearancePage(),
      ),
    );
  }

  void _navigateToHelpCenter() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HelpCenterPage(),
      ),
    );
  }

  void _navigateToSendFeedback() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SendFeedbackPage(),
      ),
    );
  }

  // Security Hub navigation methods
  void _navigateToSecurityHub() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SecurityHubPage(email: locator<AuthService>().currentUser ?? ''),
      ),
    );
  }

  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChangePasswordPage(),
      ),
    );
  }

  void _navigateToActiveSessions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ActiveSessionsPage(),
      ),
    );
  }

  void _navigateToSecurityAlerts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SecurityAlertsPage(),
      ),
    );
  }

  void _navigateToAccountRecovery() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AccountRecoveryPage(),
      ),
    );
  }

  void _navigateToTwoFactor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SecurityHubPage(email: locator<AuthService>().currentUser ?? ''),
      ),
    );
  }

  void _navigateToAdvancedServices() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const advanced.AdvancedServicesDashboard(),
      ),
    );
  }

  void _navigateToQuantumCrypto() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QuantumCryptoDashboard(),
      ),
    );
  }

  void _navigateToComplianceAutomation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ComplianceReportingPage(),
      ),
    );
  }

  void _navigateToMdm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const advanced.AdvancedServicesDashboard(),
      ),
    );
  }

  void _navigateToForensics() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ForensicsInvestigationPage(),
      ),
    );
  }

  void _navigateToTestEmail() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Summary email scheduler is running automatically. Check console for email logs.'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayMetric {
  final DateTime day;
  final int failed;
  final int logins;
  final int mfa;
  _DayMetric({required this.day, required this.failed, required this.logins, required this.mfa});
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6, spreadRadius: 1),
        ])),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 24, color: color),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: theme.textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Flexible(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  subtitle,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
