import 'package:clean_flutter/features/auth/backup_codes/backup_codes_page.dart';
import 'package:clean_flutter/features/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../generated/app_localizations.dart';
import '../../core/services/language_service.dart';
import 'dart:async';
import 'package:clean_flutter/locator.dart';
import 'package:clean_flutter/features/auth/services/auth_service.dart';
import 'package:clean_flutter/core/models/rbac_models.dart';
import 'package:clean_flutter/features/admin/pages/staff_user_management_page.dart';
import 'package:clean_flutter/features/admin/pages/superuser_approval_dashboard.dart';
import 'package:clean_flutter/features/admin/security_center_page.dart';
import 'package:clean_flutter/features/auth/services/biometric_service.dart';
import 'package:clean_flutter/features/auth/security_account_center_page.dart';
import 'package:clean_flutter/features/profile/profile_page.dart';
import 'package:clean_flutter/features/auth/totp/totp_enroll_page.dart';
import 'package:clean_flutter/features/auth/totp/totp_verify_page.dart';
import 'package:clean_flutter/features/admin/screens/ai_workflows_screen.dart';
import 'package:clean_flutter/features/admin/screens/ai_assistant_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'widgets/totp_home_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.initialTab});
  static const routeName = '/home';
  final int? initialTab;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _AccountSettingsTab extends StatefulWidget {
  const _AccountSettingsTab({required this.email});
  final String email;

  @override
  State<_AccountSettingsTab> createState() => _AccountSettingsTabState();
}

class _AccountSettingsTabState extends State<_AccountSettingsTab> {
  bool _mfaEnabled = false;
  String _pref = 'otp';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final auth = locator<AuthService>();
    _mfaEnabled = auth.isUserMfaEnabled(widget.email);
    _pref = auth.getUserMfaMethodPreference(widget.email);
  }

  Future<void> _toggleMfa(bool value) async {
    setState(() => _busy = true);
    try {
      await locator<AuthService>().setUserMfaEnabled(widget.email, value);
      setState(() => _mfaEnabled = value);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setPref(String method) async {
    setState(() => _busy = true);
    try {
      await locator<AuthService>().setUserMfaMethodPreference(widget.email, method);
      setState(() => _pref = method);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _manageBiometric() async {
    final bio = BiometricService();
    if (!await bio.canAuthenticate()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Consumer<LanguageService>(
            builder: (context, languageService, child) {
              final l10n = AppLocalizations.of(context)!;
              return Text(l10n.biometricsNotAvailable);
            },
          ),
        ),
      );
      return;
    }
    final enabled = locator<AuthService>().isUserBiometricEnabled(widget.email);
    if (!enabled) {
      final ok = await bio.authenticateBiometricOnly('Enable biometric sign-in');
      if (ok) {
        await locator<AuthService>().setUserBiometricEnabled(widget.email, true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Consumer<LanguageService>(
              builder: (context, languageService, child) {
                final l10n = AppLocalizations.of(context)!;
                return Text(l10n.biometricSigninEnabled);
              },
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Consumer<LanguageService>(
              builder: (context, languageService, child) {
                final l10n = AppLocalizations.of(context)!;
                return Text(l10n.biometricEnrollmentCancelled);
              },
            ),
          ),
        );
      }
    } else {
      await locator<AuthService>().setUserBiometricEnabled(widget.email, false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Consumer<LanguageService>(
            builder: (context, languageService, child) {
              final l10n = AppLocalizations.of(context)!;
              return Text(l10n.biometricSigninDisabled);
            },
          ),
        ),
      );
    }
    setState(() {});
  }

  Future<void> _manageTotp() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => TotpEnrollPage(email: widget.email)));
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => TotpVerifyPage(email: widget.email)));
  }

  @override
  Widget build(BuildContext context) {
    return UserSecurityAccountCenterBody(
      email: widget.email,
      mfaEnabled: _mfaEnabled,
      pref: _pref,
      busy: _busy,
      onToggleMfa: _toggleMfa,
      onSetPref: _setPref,
      onManageTotp: _manageTotp,
      onManageBiometric: _manageBiometric,
    );
  }
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;
  double _dailyGoal = 6; // hours of green activities goal
  double _progress = 2.5; // simulated current progress
  late Timer _timer;
  double _aqi = 42; // simulated Air Quality Index
  double _energy = 3.2; // simulated kWh today
  UserRole? _userRole;

  @override
  void initState() {
    super.initState();
    _tab = (widget.initialTab ?? 0).clamp(0, 3);
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      setState(() {
        // Simple simulation of live metrics
        _aqi = (35 + (DateTime.now().second % 30)).toDouble();
        _energy = (_energy + 0.1) % 7.5;
        _progress = (_progress + 0.2).clamp(0, _dailyGoal);
      });
    });
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final authService = locator<AuthService>();
    if (authService.currentUser != null) {
      final role = authService.getUserRole(authService.currentUser!);
      print('DEBUG: Current user: ${authService.currentUser}');
      print('DEBUG: User role: ${role.name} (level: ${role.level})');
      print('DEBUG: Superuser level: ${UserRole.superuser.level}');
      setState(() {
        _userRole = role;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _DashboardTab(
        progress: _progress,
        goal: _dailyGoal,
        onGoalChanged: (v) => setState(() => _dailyGoal = v),
        onManageBackup: () => Navigator.of(context).pushNamed(BackupCodesPage.routeName),
        onOpenTips: () => setState(() => _tab = 2),
      ),
      _SensorsTab(aqi: _aqi, energy: _energy),
      const _TipsTab(),
      const ProfilePage(),
    ];

    // Build dynamic pages and destinations based on user role
    final allPages = [...pages];
    final l10n = AppLocalizations.of(context)!;
    final allDestinations = <NavigationDestination>[
      NavigationDestination(
        icon: const Icon(Icons.dashboard_outlined),
        selectedIcon: const Icon(Icons.dashboard),
        label: l10n.dashboard,
      ),
      NavigationDestination(
        icon: const Icon(Icons.sensors_outlined),
        selectedIcon: const Icon(Icons.sensors),
        label: l10n.dashboard,
      ),
      NavigationDestination(
        icon: const Icon(Icons.eco_outlined),
        selectedIcon: const Icon(Icons.eco),
        label: l10n.analytics,
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outlined),
        selectedIcon: const Icon(Icons.person),
        label: l10n.profile,
      ),
      NavigationDestination(
        icon: const Icon(Icons.smart_toy_outlined),
        selectedIcon: const Icon(Icons.smart_toy),
        label: 'AI Assistant',
      ),
    ];
    
    // Add AI Assistant page
    allPages.add(const AIAssistantScreen());

    // Add role-based navigation items
    final authService = locator<AuthService>();
    
    // Debug logging
    print('DEBUG: Building navigation with role: ${_userRole?.name} (level: ${_userRole?.level})');
    print('DEBUG: Current user email: ${authService.currentUser}');
    print('DEBUG: Is superuser check: ${_userRole?.level} >= ${UserRole.superuser.level}');
    
    if (_userRole != null) {
      if (_userRole!.level >= UserRole.staff.level) {
        // Staff and above can access user management
        print('DEBUG: Adding Users tab for staff level');
        allDestinations.add(
          const NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: 'Users',
          ),
        );
        allPages.add(const StaffUserManagementPage());
      }
      
      // Force add AI Workflows for env.hygiene@gmail.com
      if (_userRole!.level >= UserRole.superuser.level || 
          authService.currentUser?.toLowerCase() == 'env.hygiene@gmail.com') {
        print('DEBUG: User qualifies for superuser features');
        print('DEBUG: Adding superuser tabs...');
        
        // Only superusers can access approval dashboard
        allDestinations.add(
          const NavigationDestination(
            icon: Icon(Icons.approval_outlined),
            selectedIcon: Icon(Icons.approval),
            label: 'Approvals',
          ),
        );
        allPages.add(const SuperuserApprovalDashboard());
        
        // Add Security Center for superusers
        allDestinations.add(
          const NavigationDestination(
            icon: Icon(Icons.security_outlined),
            selectedIcon: Icon(Icons.security),
            label: 'Security',
          ),
        );
        allPages.add(const SecurityCenterPage());
        
        // Add AI Workflows for superusers
        print('DEBUG: Adding AI Workflows tab');
        allDestinations.add(
          const NavigationDestination(
            icon: Icon(Icons.account_tree_outlined),
            selectedIcon: Icon(Icons.account_tree),
            label: 'AI Workflows',
          ),
        );
        allPages.add(const AIWorkflowsScreen());
      }
    }
    
    print('DEBUG: Total destinations: ${allDestinations.length}');
    print('DEBUG: Total pages: ${allPages.length}');

    return Scaffold(
      appBar: AppBar(
        title: Consumer<LanguageService>(
          builder: (context, languageService, child) {
            final l10n = AppLocalizations.of(context)!;
            return Text(l10n.environmentalCenter);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(LoginPage.routeName, (route) => false);
            },
          ),
        ],
      ),
      body: SafeArea(child: _tab < allPages.length ? allPages[_tab] : allPages[0]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i.clamp(0, allPages.length - 1)),
        destinations: allDestinations,
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({
    required this.progress,
    required this.goal,
    required this.onGoalChanged,
    required this.onManageBackup,
    required this.onOpenTips,
  });

  final double progress;
  final double goal;
  final ValueChanged<double> onGoalChanged;
  final VoidCallback onManageBackup;
  final VoidCallback onOpenTips;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (goal == 0) ? 0.0 : (progress / goal).clamp(0.0, 1.0);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Consumer<LanguageService>(
          builder: (context, languageService, child) {
            final l10n = AppLocalizations.of(context)!;
            return Text(
              l10n.welcomeBack,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            );
          },
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(value: pct, strokeWidth: 10),
                      Text('${(pct * 100).round()}%', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer<LanguageService>(
                        builder: (context, languageService, child) {
                          final l10n = AppLocalizations.of(context)!;
                          return Text(
                            l10n.dailyGreenGoal,
                            style: theme.textTheme.titleMedium,
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text('${progress.toStringAsFixed(1)} h of ${goal.toStringAsFixed(0)} h', style: theme.textTheme.bodyMedium),
                      Slider(
                        min: 1,
                        max: 12,
                        divisions: 11,
                        value: goal.clamp(1, 12),
                        label: '${goal.toStringAsFixed(0)}h',
                        onChanged: onGoalChanged,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // TOTP Quick Access Widget
        const TotpHomeWidget(),
        const SizedBox(height: 12),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
          ),
          children: [
            Consumer<LanguageService>(
              builder: (context, languageService, child) {
                final l10n = AppLocalizations.of(context)!;
                return _ActionTile(
                  icon: Icons.recycling,
                  color: Colors.green,
                  title: l10n.scanWaste,
                  onTap: () {},
                );
              },
            ),
            Consumer<LanguageService>(
              builder: (context, languageService, child) {
                final l10n = AppLocalizations.of(context)!;
                return _ActionTile(
                  icon: Icons.directions_bike,
                  color: Colors.teal,
                  title: l10n.logCommute,
                  onTap: () {},
                );
              },
            ),
            Consumer<LanguageService>(
              builder: (context, languageService, child) {
                final l10n = AppLocalizations.of(context)!;
                return _ActionTile(
                  icon: Icons.lightbulb_outline,
                  color: Colors.amber,
                  title: l10n.energyTips,
                  onTap: onOpenTips,
                );
              },
            ),
            Consumer<LanguageService>(
              builder: (context, languageService, child) {
                final l10n = AppLocalizations.of(context)!;
                return _ActionTile(
                  icon: Icons.key,
                  color: Colors.blue,
                  title: l10n.backupCodes,
                  onTap: onManageBackup,
                );
              },
            ),
            _ActionTile(
              icon: Icons.security,
              color: Colors.deepPurple,
              title: 'TOTP Codes',
              onTap: () {
                Navigator.pushNamed(context, '/totp-codes');
              },
            ),
            Consumer<AuthService>(
              builder: (context, auth, child) {
                return _ActionTile(
                  icon: Icons.lock_clock,
                  color: Colors.orange,
                  title: 'Security',
                  onTap: () {
                    final email = auth.currentUser ?? '';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserSecurityAccountCenterPage(email: email),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _SensorsTab extends StatefulWidget {
  const _SensorsTab({required this.aqi, required this.energy});
  final double aqi;
  final double energy;

  @override
  State<_SensorsTab> createState() => _SensorsTabState();
}

enum _Range { h24, d7, d30 }

class _SensorsTabState extends State<_SensorsTab> {
  _Range _range = _Range.h24;
  late List<DateTime> _times;
  late List<double> _energySeries;
  late List<double> _energyAvg;
  late RangeValues _view;
  final _chartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _regenerate();
  }

  void _regenerate() {
    final now = DateTime.now();
    int count;
    Duration step;
    switch (_range) {
      case _Range.h24:
        count = 24;
        step = const Duration(hours: 1);
        break;
      case _Range.d7:
        count = 7 * 24;
        step = const Duration(hours: 1);
        break;
      case _Range.d30:
        count = 30;
        step = const Duration(days: 1);
        break;
    }
    _times = List.generate(count, (i) => now.subtract(step * (count - 1 - i)));
    // Simulate energy values with small noise
    _energySeries = List.generate(count, (i) {
      final base = 2.0 + 1.5 * (1 + (i % 24) / 24.0);
      final wobble = (i * 37 % 10) / 50.0;
      return (base + wobble);
    });
    // Simple moving average (window 6)
    _energyAvg = List.generate(count, (i) {
      final start = (i - 5).clamp(0, count - 1);
      final end = i;
      double sum = 0;
      for (int j = start; j <= end; j++) sum += _energySeries[j];
      return sum / (end - start + 1);
    });
    _view = RangeValues(0, (count - 1).toDouble());
    setState(() {});
  }

  String _fmtX(int i) {
    final t = _times[i];
    switch (_range) {
      case _Range.h24:
      case _Range.d7:
        return '${t.hour.toString().padLeft(2, '0')}:00\n${t.month}/${t.day}';
      case _Range.d30:
        return '${t.month}/${t.day}';
    }
  }

  Future<void> _exportCsv() async {
    final buffer = StringBuffer('timestamp,energy,avg\n');
    for (int i = 0; i < _times.length; i++) {
      buffer.writeln('${_times[i].toIso8601String()},${_energySeries[i].toStringAsFixed(3)},${_energyAvg[i].toStringAsFixed(3)}');
    }
    // Use path_provider + flutter_file_dialog to save
    final bytes = Uint8List.fromList(buffer.toString().codeUnits);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/energy_export.csv');
    await file.writeAsBytes(bytes, flush: true);
    await FlutterFileDialog.saveFile(params: SaveFileDialogParams(sourceFilePath: file.path, fileName: 'energy_export.csv'));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Consumer<LanguageService>(
          builder: (context, languageService, child) {
            final l10n = AppLocalizations.of(context)!;
            return Text(l10n.csvExported);
          },
        ),
      ),
    );
  }

  Future<void> _exportImage() async {
    try {
      final boundary = _chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/energy_chart.png');
      await file.writeAsBytes(bytes, flush: true);
      await FlutterFileDialog.saveFile(params: SaveFileDialogParams(sourceFilePath: file.path, fileName: 'energy_chart.png'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Consumer<LanguageService>(
            builder: (context, languageService, child) {
              final l10n = AppLocalizations.of(context)!;
              return Text(l10n.chartImageExported);
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Consumer<LanguageService>(
            builder: (context, languageService, child) {
              final l10n = AppLocalizations.of(context)!;
              return Text('${l10n.exportFailed}: $e');
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = _view.start.round();
    final end = _view.end.round();
    final visibleX = [for (int i = start; i <= end; i++) i];
    final visibleEnergy = [for (final i in visibleX) _energySeries[i]];
    final visibleAvg = [for (final i in visibleX) _energyAvg[i]];
    final maxY = (visibleEnergy.followedBy(visibleAvg).reduce((a, b) => a > b ? a : b) + 0.8);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          Icon(Icons.sensors, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Consumer<LanguageService>(
            builder: (context, languageService, child) {
              final l10n = AppLocalizations.of(context)!;
              return Text(
                l10n.liveMetrics,
                style: theme.textTheme.titleLarge,
              );
            },
          ),
          const Spacer(),
          SegmentedButton<_Range>(
            segments: const [
              ButtonSegment(value: _Range.h24, label: Text('24h')),
              ButtonSegment(value: _Range.d7, label: Text('7d')),
              ButtonSegment(value: _Range.d30, label: Text('30d')),
            ],
            selected: {_range},
            onSelectionChanged: (s) {
              setState(() => _range = s.first);
              _regenerate();
            },
          )
        ]),
        const SizedBox(height: 12),
        Consumer<LanguageService>(
          builder: (context, languageService, child) {
            final l10n = AppLocalizations.of(context)!;
            return _MetricCard(
              title: l10n.airQualityIndex,
              value: widget.aqi.toStringAsFixed(0),
              unit: 'AQI',
              color: Colors.green,
            );
          },
        ),
        const SizedBox(height: 12),
        Consumer<LanguageService>(
          builder: (context, languageService, child) {
            final l10n = AppLocalizations.of(context)!;
            return _MetricCard(
              title: l10n.energyUsage,
              value: widget.energy.toStringAsFixed(1),
              unit: 'kWh',
              color: Colors.orange,
            );
          },
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Consumer<LanguageService>(
                      builder: (context, languageService, child) {
                        final l10n = AppLocalizations.of(context)!;
                        return Text(
                          l10n.energyOverTime,
                          style: theme.textTheme.titleMedium,
                        );
                      },
                    ),
                    const Spacer(),
                    Consumer<LanguageService>(
                      builder: (context, languageService, child) {
                        final l10n = AppLocalizations.of(context)!;
                        return IconButton(
                          onPressed: _exportImage,
                          tooltip: l10n.exportImage,
                          icon: const Icon(Icons.image_outlined),
                        );
                      },
                    ),
                    Consumer<LanguageService>(
                      builder: (context, languageService, child) {
                        final l10n = AppLocalizations.of(context)!;
                        return IconButton(
                          onPressed: _exportCsv,
                          tooltip: l10n.exportCsv,
                          icon: const Icon(Icons.table_view),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RepaintBoundary(
                  key: _chartKey,
                  child: SizedBox(
                    height: 260,
                    child: LineChart(
                      LineChartData(
                        minX: start.toDouble(),
                        maxX: end.toDouble(),
                        minY: 0,
                        maxY: maxY,
                        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 0.5),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: ((end - start) / 6).clamp(1, 24).toDouble(),
                              getTitlesWidget: (value, meta) {
                                final i = value.round().clamp(0, _times.length - 1);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(_fmtX(i), textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)),
                                );
                              },
                            ),
                          ),
                        ),
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(y: 2.5, color: Colors.green, strokeWidth: 1, dashArray: [6, 4]),
                            HorizontalLine(y: 3.5, color: Colors.orange, strokeWidth: 1, dashArray: [6, 4]),
                            HorizontalLine(y: 4.5, color: Colors.red, strokeWidth: 1, dashArray: [6, 4]),
                          ],
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [for (final i in visibleX) FlSpot(i.toDouble(), visibleEnergy[i - start])],
                            isCurved: true,
                            color: theme.colorScheme.primary,
                            barWidth: 3,
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(colors: [theme.colorScheme.primary.withValues(alpha: 0.35), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                            ),
                          ),
                          LineChartBarData(
                            spots: [for (final i in visibleX) FlSpot(i.toDouble(), visibleAvg[i - start])],
                            isCurved: true,
                            color: Colors.teal,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          handleBuiltInTouches: true,
                          touchTooltipData: LineTouchTooltipData(
                            tooltipBgColor: Colors.black87,
                            getTooltipItems: (touchedSpots) {
                              // Group by x to show multi-series values
                              if (touchedSpots.isEmpty) return [];
                              final x = touchedSpots.first.x.round();
                              final idx = x.clamp(0, _times.length - 1);
                              final ts = _times[idx];
                              final energy = _energySeries[idx];
                              final avg = _energyAvg[idx];
                              return [
                                LineTooltipItem('${ts.month}/${ts.day} ${ts.hour.toString().padLeft(2, '0')}:00\n', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                LineTooltipItem('Energy: ${energy.toStringAsFixed(2)} kWh\n', const TextStyle(color: Colors.white)),
                                LineTooltipItem('Avg:    ${avg.toStringAsFixed(2)} kWh', const TextStyle(color: Colors.white70)),
                              ];
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Consumer<LanguageService>(
                      builder: (context, languageService, child) {
                        final l10n = AppLocalizations.of(context)!;
                        return Text(l10n.zoomPan);
                      },
                    ),
                    Expanded(
                      child: RangeSlider(
                        values: _view,
                        min: 0,
                        max: (_times.length - 1).toDouble(),
                        divisions: _times.length - 1,
                        onChanged: (v) => setState(() => _view = v.start < v.end ? v : _view),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: [
                    Consumer<LanguageService>(
                      builder: (context, languageService, child) {
                        final l10n = AppLocalizations.of(context)!;
                        return _LegendDot(color: Colors.blue, label: l10n.energy);
                      },
                    ),
                    Consumer<LanguageService>(
                      builder: (context, languageService, child) {
                        final l10n = AppLocalizations.of(context)!;
                        return _LegendDot(color: Colors.teal, label: l10n.average);
                      },
                    ),
                    Consumer<LanguageService>(
                      builder: (context, languageService, child) {
                        final l10n = AppLocalizations.of(context)!;
                        return _LegendDot(color: Colors.green, label: l10n.goodThreshold);
                      },
                    ),
                    Consumer<LanguageService>(
                      builder: (context, languageService, child) {
                        final l10n = AppLocalizations.of(context)!;
                        return _LegendDot(color: Colors.orange, label: l10n.warning);
                      },
                    ),
                    Consumer<LanguageService>(
                      builder: (context, languageService, child) {
                        final l10n = AppLocalizations.of(context)!;
                        return _LegendDot(color: Colors.red, label: l10n.high);
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _EnergyBreakdownPie(
          segments: {
            'Solar': 38,
            'Grid': 46,
            'Battery': 16,
          },
        ),
      ],
    );
  }
}

class _TipsTab extends StatelessWidget {
  const _TipsTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Consumer<LanguageService>(
          builder: (context, languageService, child) {
            final l10n = AppLocalizations.of(context)!;
            return _TipTile(
              icon: Icons.eco,
              title: l10n.reducePlastics,
              body: l10n.reducePlasticsBody,
            );
          },
        ),
        Consumer<LanguageService>(
          builder: (context, languageService, child) {
            final l10n = AppLocalizations.of(context)!;
            return _TipTile(
              icon: Icons.lightbulb,
              title: l10n.saveEnergyHome,
              body: l10n.saveEnergyHomeBody,
            );
          },
        ),
        Consumer<LanguageService>(
          builder: (context, languageService, child) {
            final l10n = AppLocalizations.of(context)!;
            return _TipTile(
              icon: Icons.directions_bike,
              title: l10n.greenerCommute,
              body: l10n.greenerCommuteBody,
            );
          },
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.color, required this.title, required this.onTap});
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value, required this.unit, required this.color});
  final String title;
  final String value;
  final String unit;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(Icons.insights, color: color)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('$value $unit', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _EnergyBreakdownPie extends StatelessWidget {
  const _EnergyBreakdownPie({required this.segments});
  final Map<String, int> segments;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = segments.values.fold<int>(0, (p, e) => p + e);
    final colors = [
      theme.colorScheme.primary,
      Colors.orange,
      Colors.teal,
      Colors.purple,
      Colors.blueGrey,
    ];
    final sections = <PieChartSectionData>[];
    int i = 0;
    segments.forEach((label, value) {
      final pct = total == 0 ? 0.0 : (value * 100 / total);
      sections.add(
        PieChartSectionData(
          value: value.toDouble(),
          title: '${pct.toStringAsFixed(0)}%',
          color: colors[i % colors.length],
          radius: 60,
          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
      i++;
    });
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<LanguageService>(
              builder: (context, languageService, child) {
                final l10n = AppLocalizations.of(context)!;
                return Text(
                  l10n.energySourceBreakdown,
                  style: theme.textTheme.titleMedium,
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (int j = 0; j < segments.length; j++)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 12, height: 12, color: colors[j % colors.length]),
                              const SizedBox(width: 6),
                              Text(segments.keys.elementAt(j)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipTile extends StatelessWidget {
  const _TipTile({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ExpansionTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: theme.textTheme.titleMedium),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(body),
          )
        ],
      ),
    );
  }
}
