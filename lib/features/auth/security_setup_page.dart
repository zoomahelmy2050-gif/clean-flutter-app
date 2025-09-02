import 'package:flutter/material.dart';
import 'package:clean_flutter/locator.dart';
import 'package:clean_flutter/features/auth/services/auth_service.dart';
import 'package:clean_flutter/features/home/home_page.dart';
import 'package:clean_flutter/features/admin/security_center_page.dart';
import 'package:clean_flutter/features/auth/services/biometric_service.dart';
import 'package:clean_flutter/features/auth/totp/totp_enroll_page.dart';
import 'package:clean_flutter/features/admin/backup_codes_page.dart';
import 'package:clean_flutter/core/services/theme_service.dart';
import 'package:clean_flutter/core/services/security_reminder_service.dart';

class SecuritySetupPage extends StatefulWidget {
  final String email;
  final bool isAdmin;

  const SecuritySetupPage({
    super.key,
    required this.email,
    this.isAdmin = false,
  });

  static const routeName = '/security-setup';

  @override
  State<SecuritySetupPage> createState() => _SecuritySetupPageState();
}

class _SecuritySetupPageState extends State<SecuritySetupPage> with TickerProviderStateMixin {
  final authService = locator<AuthService>();
  bool _isSettingUp = false;
  late AnimationController _celebrationController;
  late Animation<double> _celebrationAnimation;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _celebrationAnimation = CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  int get _securityScore {
    int score = 0;
    if (authService.isUserTotpEnrolled(widget.email)) score += 30;
    if (authService.hasUserBackupCodes(widget.email)) score += 20;
    if (authService.isUserBiometricEnabled(widget.email)) score += 25;
    score += 25; // Email OTP is always active
    return score;
  }

  int get _completedMethods {
    int count = 1; // Email OTP is always active
    if (authService.isUserTotpEnrolled(widget.email)) count++;
    if (authService.hasUserBackupCodes(widget.email)) count++;
    if (authService.isUserBiometricEnabled(widget.email)) count++;
    return count;
  }

  String get _securityLevel {
    final score = _securityScore;
    if (score >= 90) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Fair';
    return 'Basic';
  }

  Color get _securityColor {
    final score = _securityScore;
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.lightGreen;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateToMainApp,
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            onPressed: () {
              locator<ThemeService>().toggleTheme();
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Secure your account',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'These security methods help protect your account',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Security Score Card
              _buildSecurityScoreCard(theme),
              const SizedBox(height: 24),

              // Progress Indicator
              _buildProgressIndicator(theme),
              const SizedBox(height: 32),

              // Security Methods
              Expanded(
                child: ListView(
                  children: [
                    _buildSecurityMethod(
                      context,
                      icon: Icons.security,
                      title: 'Authenticator App (TOTP)',
                      subtitle: 'Use an app like Google Authenticator or Authy to generate time-based codes',
                      isSetUp: authService.isUserTotpEnrolled(widget.email),
                      onSetUp: () => _setupSecurityMethod('totp'),
                      onActive: () => _showActiveDialog('TOTP'),
                    ),
                    const SizedBox(height: 16),
                    _buildSecurityMethod(
                      context,
                      icon: Icons.email,
                      title: 'Email OTP',
                      subtitle: 'Security codes will be sent to your email address\n(${widget.email})',
                      isSetUp: true, // Email OTP is always available
                      onSetUp: () => _activateEmailOtp(context),
                      onActive: () => _showActiveDialog('Email OTP'),
                      isAlwaysActive: true,
                    ),
                    const SizedBox(height: 16),
                    _buildSecurityMethod(
                      context,
                      icon: Icons.backup,
                      title: 'Backup Codes',
                      subtitle: 'Use single-use codes to sign in if you lose access to your other methods',
                      isSetUp: false, // Always show as not set up initially
                      onSetUp: () => _setupSecurityMethod('backup_codes'),
                      onActive: () => _showActiveDialog('Backup Codes'),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<bool>(
                      future: BiometricService().canAuthenticate(),
                      builder: (context, snapshot) {
                        final canUseBiometric = snapshot.data ?? false;
                        if (!canUseBiometric) return const SizedBox.shrink();
                        
                        return Column(
                          children: [
                            _buildSecurityMethod(
                              context,
                              icon: Icons.fingerprint,
                              title: 'Passkeys',
                              subtitle: 'Use your device screen lock, a security key, or another device to sign in',
                              isSetUp: authService.isUserBiometricEnabled(widget.email),
                              onSetUp: () => _setupSecurityMethod('passkeys'),
                              onActive: () => _showActiveDialog('Passkeys'),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Skip Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: _isSettingUp ? null : _showSkipConfirmation,
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Skip for now',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityMethod(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSetUp,
    required VoidCallback onSetUp,
    required VoidCallback onActive,
    bool isAlwaysActive = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? const Color(0xFF3A3A3A) 
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (isSetUp || isAlwaysActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Active',
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: _isSettingUp ? null : onSetUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text(
                  'Set Up',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _activateEmailOtp(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email OTP is already active for your account'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _setupSecurityMethod(String method) async {
    setState(() {
      _isSettingUp = true;
    });

    try {
      switch (method) {
        case 'totp':
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TotpEnrollPage(email: widget.email),
            ),
          );
          if (result == 'enrolled') {
            await _showCelebration('Authenticator app successfully set up!');
          }
          break;
        case 'backup_codes':
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const BackupCodesPage(),
            ),
          );
          if (result == 'generated') {
            await _showCelebration('Backup codes generated successfully!');
          }
          break;
        case 'passkeys':
          final biometricService = locator<BiometricService>();
          final canAuth = await biometricService.canAuthenticate();
          if (canAuth) {
            final success = await biometricService.authenticate('Set up biometric authentication');
            if (success) {
              authService.setUserBiometricEnabled(widget.email, true);
              await _showCelebration('Biometric authentication enabled!');
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Biometric authentication not available on this device'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to set up $method: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSettingUp = false;
      });
    }
  }

  Future<void> _showCelebration(String message) async {
    // Show success message with animation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            ScaleTransition(
              scale: _celebrationAnimation,
              child: const Icon(Icons.celebration, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );

    // Trigger celebration animation
    await _celebrationController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _celebrationController.reset();
  }

  void _showActiveDialog(String method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$method Active'),
        content: Text('$method is already set up and active for your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityScoreCard(ThemeData theme) {
    final score = _securityScore;
    final level = _securityLevel;
    final color = _securityColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
            ),
            child: Center(
              child: Text(
                '$score',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security Score',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  level,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: score / 100,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    final completed = _completedMethods;
    const total = 4; // TOTP, Email OTP, Backup Codes, Biometric

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Setup Progress',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$completed/$total',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: completed / total,
            backgroundColor: theme.colorScheme.surface,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            completed == total 
                ? '🎉 All security methods configured!'
                : 'Set up ${total - completed} more method${total - completed == 1 ? '' : 's'} for better security',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showSkipConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber, size: 48, color: Colors.orange),
        title: const Text('Skip Security Setup?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to skip setting up additional security methods?'),
            SizedBox(height: 16),
            Text('Without additional security:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.close, color: Colors.red, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text('Your account is more vulnerable to unauthorized access')),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.close, color: Colors.red, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text('Password alone may not be enough protection')),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.close, color: Colors.red, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text('Recovery options are limited if you lose access')),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue Setup'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                // Record the skip for reminder purposes
                final reminderService = locator<SecurityReminderService>();
                await reminderService.recordSecuritySkip(widget.email);
              } catch (e) {
                // If recording fails, still allow navigation
                debugPrint('Failed to record security skip: $e');
              }
              _navigateToMainApp();
            },
            child: const Text('Skip Anyway'),
          ),
        ],
      ),
    );
  }

  void _navigateToMainApp() {
    if (widget.isAdmin) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SecurityCenterPage()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage(initialTab: 3)),
        (route) => false,
      );
    }
  }
}
