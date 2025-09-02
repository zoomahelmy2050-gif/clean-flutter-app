import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/security_settings_service.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({Key? key}) : super(key: key);

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SecuritySettingsService>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.policy), text: 'Policies'),
            Tab(icon: Icon(Icons.security), text: 'Security Score'),
            Tab(icon: Icon(Icons.settings), text: 'Advanced'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportSettings();
                  break;
                case 'import':
                  _importSettings();
                  break;
                case 'reset':
                  _resetToDefaults();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'export', child: Text('Export Settings')),
              const PopupMenuItem(value: 'import', child: Text('Import Settings')),
              const PopupMenuItem(value: 'reset', child: Text('Reset to Defaults')),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPoliciesTab(),
          _buildSecurityScoreTab(),
          _buildAdvancedTab(),
        ],
      ),
    );
  }

  Widget _buildPoliciesTab() {
    return Consumer<SecuritySettingsService>(
      builder: (context, settingsService, child) {
        if (settingsService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: settingsService.policies.length,
          itemBuilder: (context, index) {
            final policy = settingsService.policies[index];
            return _buildPolicyCard(policy, settingsService);
          },
        );
      },
    );
  }

  Widget _buildPolicyCard(SecurityPolicy policy, SecuritySettingsService settingsService) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: policy.isEnabled ? Colors.green : Colors.grey,
          child: Icon(
            _getPolicyIcon(policy.id),
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                policy.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Switch(
              value: policy.isEnabled,
              onChanged: (value) => settingsService.togglePolicy(policy.id, value),
            ),
          ],
        ),
        subtitle: Text(policy.description),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Settings:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._buildPolicySettings(policy, settingsService),
                const SizedBox(height: 16),
                Text(
                  'Last updated: ${_formatDate(policy.updatedAt)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPolicySettings(SecurityPolicy policy, SecuritySettingsService settingsService) {
    final settings = <Widget>[];
    
    switch (policy.id) {
      case 'password_policy':
        settings.addAll([
          _buildSliderSetting('Minimum Length', policy.settings['minLength']?.toDouble() ?? 8.0, 6, 20, (value) {
            settingsService.updatePolicySetting(policy.id, 'minLength', value.round());
          }),
          _buildSwitchSetting('Require Uppercase', policy.settings['requireUppercase'] ?? true, (value) {
            settingsService.updatePolicySetting(policy.id, 'requireUppercase', value);
          }),
          _buildSwitchSetting('Require Numbers', policy.settings['requireNumbers'] ?? true, (value) {
            settingsService.updatePolicySetting(policy.id, 'requireNumbers', value);
          }),
          _buildSwitchSetting('Require Special Characters', policy.settings['requireSpecialChars'] ?? true, (value) {
            settingsService.updatePolicySetting(policy.id, 'requireSpecialChars', value);
          }),
        ]);
        break;
        
      case 'session_policy':
        settings.addAll([
          _buildSliderSetting('Max Session Duration (hours)', (policy.settings['maxSessionDuration'] ?? 480) / 60.0, 1, 24, (value) {
            settingsService.updatePolicySetting(policy.id, 'maxSessionDuration', (value * 60).round());
          }),
          _buildSliderSetting('Idle Timeout (minutes)', policy.settings['idleTimeout']?.toDouble() ?? 30.0, 5, 120, (value) {
            settingsService.updatePolicySetting(policy.id, 'idleTimeout', value.round());
          }),
          _buildSliderSetting('Max Concurrent Sessions', policy.settings['maxConcurrentSessions']?.toDouble() ?? 3.0, 1, 10, (value) {
            settingsService.updatePolicySetting(policy.id, 'maxConcurrentSessions', value.round());
          }),
        ]);
        break;
        
      case 'login_policy':
        settings.addAll([
          _buildSliderSetting('Max Failed Attempts', policy.settings['maxFailedAttempts']?.toDouble() ?? 5.0, 1, 10, (value) {
            settingsService.updatePolicySetting(policy.id, 'maxFailedAttempts', value.round());
          }),
          _buildSliderSetting('Lockout Duration (minutes)', policy.settings['lockoutDuration']?.toDouble() ?? 15.0, 5, 60, (value) {
            settingsService.updatePolicySetting(policy.id, 'lockoutDuration', value.round());
          }),
          _buildSwitchSetting('Require MFA', policy.settings['requireMFA'] ?? false, (value) {
            settingsService.updatePolicySetting(policy.id, 'requireMFA', value);
          }),
        ]);
        break;
        
      case 'data_protection':
        settings.addAll([
          _buildSwitchSetting('Encryption Enabled', policy.settings['encryptionEnabled'] ?? true, (value) {
            settingsService.updatePolicySetting(policy.id, 'encryptionEnabled', value);
          }),
          _buildSwitchSetting('Backup Encryption', policy.settings['backupEncryption'] ?? true, (value) {
            settingsService.updatePolicySetting(policy.id, 'backupEncryption', value);
          }),
          _buildSwitchSetting('Audit Trail', policy.settings['auditTrail'] ?? true, (value) {
            settingsService.updatePolicySetting(policy.id, 'auditTrail', value);
          }),
        ]);
        break;
        
      case 'network_security':
        settings.addAll([
          _buildSwitchSetting('HTTPS Only', policy.settings['httpsOnly'] ?? true, (value) {
            settingsService.updatePolicySetting(policy.id, 'httpsOnly', value);
          }),
          _buildSwitchSetting('Rate Limiting', policy.settings['rateLimiting'] ?? true, (value) {
            settingsService.updatePolicySetting(policy.id, 'rateLimiting', value);
          }),
          _buildSliderSetting('Requests Per Minute', policy.settings['requestsPerMinute']?.toDouble() ?? 60.0, 10, 200, (value) {
            settingsService.updatePolicySetting(policy.id, 'requestsPerMinute', value.round());
          }),
        ]);
        break;
        
      case 'monitoring_policy':
        settings.addAll([
          _buildSwitchSetting('Real-time Alerts', policy.settings['realTimeAlerts'] ?? true, (value) {
            settingsService.updatePolicySetting(policy.id, 'realTimeAlerts', value);
          }),
          _buildSwitchSetting('Email Notifications', policy.settings['emailNotifications'] ?? true, (value) {
            settingsService.updatePolicySetting(policy.id, 'emailNotifications', value);
          }),
          _buildSwitchSetting('Anomaly Detection', policy.settings['anomalyDetection'] ?? true, (value) {
            settingsService.updatePolicySetting(policy.id, 'anomalyDetection', value);
          }),
        ]);
        break;
        
      case 'compliance_policy':
        settings.addAll([
          _buildSwitchSetting('GDPR Compliance', policy.settings['gdprCompliance'] ?? true, (value) {
            settingsService.updatePolicySetting(policy.id, 'gdprCompliance', value);
          }),
          _buildSwitchSetting('CCPA Compliance', policy.settings['ccpaCompliance'] ?? false, (value) {
            settingsService.updatePolicySetting(policy.id, 'ccpaCompliance', value);
          }),
          _buildSwitchSetting('Data Processing Consent', policy.settings['dataProcessingConsent'] ?? true, (value) {
            settingsService.updatePolicySetting(policy.id, 'dataProcessingConsent', value);
          }),
        ]);
        break;
    }
    
    return settings;
  }

  Widget _buildSwitchSetting(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      dense: true,
    );
  }

  Widget _buildSliderSetting(String title, double value, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$title: ${value.round()}'),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: (max - min).round(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSecurityScoreTab() {
    return Consumer<SecuritySettingsService>(
      builder: (context, settingsService, child) {
        if (settingsService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final score = settingsService.calculateSecurityScore();
        final recommendations = settingsService.getSecurityRecommendations();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(score)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '$score%',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Security Score',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getScoreDescription(score),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (recommendations.isNotEmpty) ...[
                const Text(
                  'Security Recommendations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...recommendations.map((recommendation) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.lightbulb, color: Colors.orange),
                    title: Text(recommendation),
                  ),
                )),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdvancedTab() {
    return Consumer<SecuritySettingsService>(
      builder: (context, settingsService, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Compliance Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildComplianceStatus('GDPR', settingsService.isGDPRCompliant()),
                    _buildComplianceStatus('CCPA', settingsService.isCCPACompliant()),
                    _buildComplianceStatus('HIPAA', settingsService.isHIPAACompliant()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _exportSettings,
                      icon: const Icon(Icons.download),
                      label: const Text('Export Settings'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _importSettings,
                      icon: const Icon(Icons.upload),
                      label: const Text('Import Settings'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _resetToDefaults,
                      icon: const Icon(Icons.restore),
                      label: const Text('Reset to Defaults'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildComplianceStatus(String name, bool isCompliant) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name),
          Chip(
            label: Text(isCompliant ? 'Compliant' : 'Non-compliant'),
            backgroundColor: isCompliant ? Colors.green[100] : Colors.red[100],
            avatar: Icon(
              isCompliant ? Icons.check : Icons.close,
              color: isCompliant ? Colors.green : Colors.red,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPolicyIcon(String policyId) {
    switch (policyId) {
      case 'password_policy':
        return Icons.lock;
      case 'session_policy':
        return Icons.timer;
      case 'login_policy':
        return Icons.login;
      case 'data_protection':
        return Icons.shield;
      case 'network_security':
        return Icons.network_check;
      case 'monitoring_policy':
        return Icons.monitor;
      case 'compliance_policy':
        return Icons.gavel;
      default:
        return Icons.policy;
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getScoreDescription(int score) {
    if (score >= 90) return 'Excellent security configuration';
    if (score >= 80) return 'Good security configuration';
    if (score >= 60) return 'Adequate security configuration';
    if (score >= 40) return 'Poor security configuration';
    return 'Critical security issues detected';
  }

  void _exportSettings() {
    final settingsService = context.read<SecuritySettingsService>();
    settingsService.exportSettings();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings exported successfully')),
    );
  }

  void _importSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import functionality would open file picker')),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text('This will reset all security settings to their default values. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await context.read<SecuritySettingsService>().resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
