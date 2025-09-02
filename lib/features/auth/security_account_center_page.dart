import 'package:flutter/material.dart';
import 'package:clean_flutter/locator.dart';
import 'services/auth_service.dart';
import 'services/biometric_service.dart';
import '../admin/services/mfa_settings_service.dart';
import 'totp/totp_enroll_page.dart';
import 'totp/totp_verify_page.dart';
import 'backup_codes/backup_codes_page.dart';
import '../home/home_page.dart';

class UserSecurityAccountCenterPage extends StatefulWidget {
  const UserSecurityAccountCenterPage({super.key, required this.email});
  static const routeName = '/security-account-center';
  final String email;

  @override
  State<UserSecurityAccountCenterPage> createState() => _UserSecurityAccountCenterPageState();
}

class _UserSecurityAccountCenterPageState extends State<UserSecurityAccountCenterPage> {
  late bool _mfaEnabled;
  late String _pref; // 'otp' | 'biometric' | 'totp'
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometrics not available on this device.')));
      return;
    }
    final enabled = locator<AuthService>().isUserBiometricEnabled(widget.email);
    if (!enabled) {
      final ok = await bio.authenticateBiometricOnly('Enable biometric sign-in');
      if (ok) {
        await locator<AuthService>().setUserBiometricEnabled(widget.email, true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometric sign-in enabled.')));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometric enrollment cancelled.')));
      }
    } else {
      await locator<AuthService>().setUserBiometricEnabled(widget.email, false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometric sign-in disabled.')));
    }
    setState(() {});
  }

  Future<void> _manageTotp() async {
    // Always show enroll page first; it will reuse existing secret if present
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => TotpEnrollPage(email: widget.email)));
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => TotpVerifyPage(email: widget.email)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Account Center'),
      ),
      body: SafeArea(
        child: UserSecurityAccountCenterBody(
          email: widget.email,
          mfaEnabled: _mfaEnabled,
          pref: _pref,
          busy: _busy,
          onToggleMfa: _toggleMfa,
          onSetPref: _setPref,
          onManageTotp: _manageTotp,
          onManageBiometric: _manageBiometric,
        ),
      ),
    );
  }
}

class UserSecurityAccountCenterBody extends StatelessWidget {
  const UserSecurityAccountCenterBody({
    super.key,
    required this.email,
    required this.mfaEnabled,
    required this.pref,
    required this.busy,
    required this.onToggleMfa,
    required this.onSetPref,
    required this.onManageTotp,
    required this.onManageBiometric,
  });

  final String email;
  final bool mfaEnabled;
  final String pref;
  final bool busy;
  final Future<void> Function(bool) onToggleMfa;
  final Future<void> Function(String) onSetPref;
  final Future<void> Function() onManageTotp;
  final Future<void> Function() onManageBiometric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mfaSettings = locator<MfaSettingsService>();
    final bioEnabledForUser = locator<AuthService>().isUserBiometricEnabled(email);
    final isTotpEnrolled = locator<AuthService>().isUserTotpEnrolled(email);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Choose your preferred MFA method', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Protect your account with a second step. You can change this anytime.', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        Card(
          child: SwitchListTile(
            title: const Text('Enable Multi-Factor Authentication'),
            subtitle: const Text('Require a second step at login'),
            value: mfaEnabled,
            onChanged: busy ? null : onToggleMfa,
          ),
        ),
        const SizedBox(height: 16),
        Text('Preferred method', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _MethodTile(
          icon: Icons.email_outlined,
          title: 'Email OTP',
          subtitle: 'Receive 6-digit codes by email',
          selected: pref == 'otp',
          enabled: mfaSettings.isEmailOtpEnabled,
          onTap: busy ? null : () => onSetPref('otp'),
        ),
        const SizedBox(height: 8),
        _MethodTile(
          icon: Icons.key_outlined,
          title: 'Authenticator App (TOTP)',
          subtitle: isTotpEnrolled ? 'Enrolled — Manage or verify' : 'Use Google Authenticator, Authy, etc.',
          selected: pref == 'totp',
          enabled: true,
          trailing: TextButton(
            onPressed: busy ? null : onManageTotp,
            child: Text(isTotpEnrolled ? 'Manage' : 'Enroll'),
          ),
          onTap: busy ? null : () => onSetPref('totp'),
        ),
        const SizedBox(height: 8),
        _MethodTile(
          icon: Icons.fingerprint_outlined,
          title: 'Biometric',
          subtitle: bioEnabledForUser ? 'Enabled on this device' : 'Use Face ID / fingerprint on this device',
          selected: pref == 'biometric',
          enabled: true,
          trailing: TextButton(
            onPressed: busy ? null : onManageBiometric,
            child: Text(bioEnabledForUser ? 'Disable' : 'Enable'),
          ),
          onTap: busy ? null : () => onSetPref('biometric'),
        ),
        const SizedBox(height: 16),
        if (mfaSettings.isBackupCodesEnabled)
          Card(
            child: ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Backup codes'),
              subtitle: const Text('Generate or view one-time backup codes'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pushNamed(BackupCodesPage.routeName),
            ),
          ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(HomePage.routeName, (route) => false),
          icon: const Icon(Icons.check),
          label: const Text('Continue to app'),
        ),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _MethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Icon(icon, color: selected ? theme.colorScheme.primary : Colors.black54),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing ?? (selected ? const Icon(Icons.check_circle, color: Colors.green) : null),
        enabled: enabled,
        onTap: enabled ? onTap : null,
      ),
    );
  }
}
