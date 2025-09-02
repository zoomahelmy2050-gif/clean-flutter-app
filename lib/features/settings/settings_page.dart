import 'package:clean_flutter/features/auth/login_page.dart';
import 'package:clean_flutter/features/auth/services/auth_service.dart';
import 'package:clean_flutter/locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  static const routeName = '/settings';

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settingsService = locator<SettingsService>();
  final _authService = locator<AuthService>();

  bool? _isMfaEnabled;
  MfaType? _selectedMfa;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final isMfaEnabled = await _settingsService.isMfaEnabled();
    final selectedMfa = await _settingsService.getMfaType();
    if (mounted) {
      setState(() {
        _isMfaEnabled = isMfaEnabled;
        _selectedMfa = selectedMfa;
      });
    }
  }

  Future<void> _onMfaEnabledChanged(bool value) async {
    HapticFeedback.lightImpact();
    await _settingsService.setMfaEnabled(value);
    setState(() {
      _isMfaEnabled = value;
    });
  }

  Future<void> _onMfaMethodChanged(MfaType value) async {
    HapticFeedback.lightImpact();
    await _settingsService.setMfaType(value);
    setState(() {
      _selectedMfa = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _isMfaEnabled == null || _selectedMfa == null
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  title: const Text('Environmental Center'),
                  pinned: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () async {
                        await _authService.logout();
                        if (mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(LoginPage.routeName, (route) => false);
                        }
                      },
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Choose your preferred MFA method', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Protect your account with a second step. You can change this anytime.', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
                        const SizedBox(height: 24),
                        _buildMfaToggleCard(),
                        const SizedBox(height: 24),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.fastOutSlowIn,
                          child: _isMfaEnabled!
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Preferred method', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 16),
                                    _buildMfaMethodCard(icon: Icons.email_outlined, title: 'Email OTP', subtitle: 'Receive 6-digit codes by email', type: MfaType.email),
                                    const SizedBox(height: 12),
                                    _buildMfaMethodCard(icon: Icons.shield_outlined, title: 'Authenticator App (TOTP)', subtitle: 'Enrolled - Manage or verify', type: MfaType.totp),
                                    const SizedBox(height: 12),
                                    _buildMfaMethodCard(icon: Icons.fingerprint, title: 'Biometric', subtitle: 'Use Face ID / fingerprint on this device', type: MfaType.biometric),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMfaToggleCard() {
    return Card(
      elevation: 2.0,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: const Text('Enable Multi-Factor Authentication', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Require a second step at login'),
        value: _isMfaEnabled!,
        onChanged: _onMfaEnabledChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildMfaMethodCard({required IconData icon, required String title, required String subtitle, required MfaType type}) {
    final theme = Theme.of(context);
    final isSelected = _selectedMfa == type;
    final isEnrolled = type == MfaType.totp; // Placeholder
    final isDeviceEnabled = type == MfaType.biometric; // Placeholder

    Widget trailing;
    if (isSelected) {
      trailing = Icon(Icons.check_circle, color: theme.primaryColor);
    } else if (isEnrolled) {
      trailing = TextButton(onPressed: () {}, child: const Text('Manage'));
    } else if (isDeviceEnabled) {
      trailing = TextButton(onPressed: () {}, child: const Text('Enable'));
    } else {
      trailing = const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _onMfaMethodChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor.withOpacity(0.1) : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.primaryColor, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
