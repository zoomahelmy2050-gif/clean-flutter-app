import 'package:flutter/material.dart';
import 'package:clean_flutter/locator.dart';
import 'package:clean_flutter/features/auth/services/auth_service.dart';

class SecurityAlertsPage extends StatefulWidget {
  const SecurityAlertsPage({super.key});

  @override
  State<SecurityAlertsPage> createState() => _SecurityAlertsPageState();
}

class _SecurityAlertsPageState extends State<SecurityAlertsPage> {
  final _authService = locator<AuthService>();

  // Alert settings
  bool _loginAlerts = true;
  bool _passwordChangeAlerts = true;
  bool _newDeviceAlerts = true;
  bool _suspiciousActivityAlerts = true;
  bool _accountRecoveryAlerts = true;
  bool _securitySettingsChanges = true;

  // Notification methods
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;

  // Advanced settings
  bool _realTimeAlerts = true;
  bool _weeklySecuritySummary = true;
  bool _monthlySecurityReport = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // In a real app, load these from user preferences or backend
    // For now, using default values
  }

  Future<void> _saveSettings() async {
    // In a real app, save these to user preferences or backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Security alert settings saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Alerts'),
        elevation: 0,
        actions: [
          TextButton(onPressed: _saveSettings, child: const Text('Save')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Security Notifications',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Configure when and how you want to be notified about security events on your account. '
                      'We recommend keeping critical alerts enabled for maximum security.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Alert Types Section
            Text(
              'Alert Types',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              child: Column(
                children: [
                  _buildAlertTile(
                    icon: Icons.login,
                    title: 'Login Alerts',
                    subtitle: 'Notify when someone signs into your account',
                    value: _loginAlerts,
                    onChanged: (value) => setState(() => _loginAlerts = value),
                    isRecommended: true,
                  ),
                  const Divider(height: 1),
                  _buildAlertTile(
                    icon: Icons.lock_reset,
                    title: 'Password Changes',
                    subtitle: 'Notify when your password is changed',
                    value: _passwordChangeAlerts,
                    onChanged: (value) =>
                        setState(() => _passwordChangeAlerts = value),
                    isRecommended: true,
                  ),
                  const Divider(height: 1),
                  _buildAlertTile(
                    icon: Icons.devices,
                    title: 'New Device Logins',
                    subtitle: 'Notify when signing in from a new device',
                    value: _newDeviceAlerts,
                    onChanged: (value) =>
                        setState(() => _newDeviceAlerts = value),
                    isRecommended: true,
                  ),
                  const Divider(height: 1),
                  _buildAlertTile(
                    icon: Icons.warning,
                    title: 'Suspicious Activity',
                    subtitle: 'Notify about unusual account activity',
                    value: _suspiciousActivityAlerts,
                    onChanged: (value) =>
                        setState(() => _suspiciousActivityAlerts = value),
                    isRecommended: true,
                  ),
                  const Divider(height: 1),
                  _buildAlertTile(
                    icon: Icons.restore,
                    title: 'Account Recovery',
                    subtitle: 'Notify about recovery attempts',
                    value: _accountRecoveryAlerts,
                    onChanged: (value) =>
                        setState(() => _accountRecoveryAlerts = value),
                    isRecommended: true,
                  ),
                  const Divider(height: 1),
                  _buildAlertTile(
                    icon: Icons.settings,
                    title: 'Security Settings Changes',
                    subtitle: 'Notify when security settings are modified',
                    value: _securitySettingsChanges,
                    onChanged: (value) =>
                        setState(() => _securitySettingsChanges = value),
                    isRecommended: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notification Methods Section
            Text(
              'Notification Methods',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              child: Column(
                children: [
                  _buildAlertTile(
                    icon: Icons.email,
                    title: 'Email Notifications',
                    subtitle: 'Receive alerts via email',
                    value: _emailNotifications,
                    onChanged: (value) =>
                        setState(() => _emailNotifications = value),
                  ),
                  const Divider(height: 1),
                  _buildAlertTile(
                    icon: Icons.notifications,
                    title: 'Push Notifications',
                    subtitle: 'Receive alerts as push notifications',
                    value: _pushNotifications,
                    onChanged: (value) =>
                        setState(() => _pushNotifications = value),
                  ),
                  const Divider(height: 1),
                  _buildAlertTile(
                    icon: Icons.sms,
                    title: 'SMS Notifications',
                    subtitle: 'Receive critical alerts via SMS',
                    value: _smsNotifications,
                    onChanged: (value) =>
                        setState(() => _smsNotifications = value),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Advanced Settings Section
            Text(
              'Advanced Settings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              child: Column(
                children: [
                  _buildAlertTile(
                    icon: Icons.speed,
                    title: 'Real-time Alerts',
                    subtitle:
                        'Receive immediate notifications for critical events',
                    value: _realTimeAlerts,
                    onChanged: (value) =>
                        setState(() => _realTimeAlerts = value),
                  ),
                  const Divider(height: 1),
                  _buildAlertTile(
                    icon: Icons.summarize,
                    title: 'Weekly Security Summary',
                    subtitle: 'Receive weekly summary of account activity',
                    value: _weeklySecuritySummary,
                    onChanged: (value) =>
                        setState(() => _weeklySecuritySummary = value),
                  ),
                  const Divider(height: 1),
                  _buildAlertTile(
                    icon: Icons.assessment,
                    title: 'Monthly Security Report',
                    subtitle: 'Detailed monthly security analysis',
                    value: _monthlySecurityReport,
                    onChanged: (value) =>
                        setState(() => _monthlySecurityReport = value),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Test Notifications Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.science, color: theme.colorScheme.secondary),
                        const SizedBox(width: 8),
                        Text(
                          'Test Notifications',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Send a test notification to verify your settings are working correctly.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _sendTestNotification,
                        icon: const Icon(Icons.send),
                        label: const Text('Send Test Notification'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Security Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Security Recommendation',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'We strongly recommend keeping login alerts, password change alerts, and suspicious activity alerts enabled for maximum account security.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isRecommended = false,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: value
              ? Colors.green.withOpacity(0.1)
              : theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: value ? Colors.green : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      title: Row(
        children: [
          Expanded(child: Text(title)),
          if (isRecommended)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Recommended',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(subtitle),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  Future<void> _sendTestNotification() async {
    // Simulate sending test notification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Test notification sent! Check your enabled notification methods.',
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
