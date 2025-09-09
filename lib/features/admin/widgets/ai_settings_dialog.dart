import 'package:flutter/material.dart';
import '../services/ai_settings_service.dart';
import '../services/ai_security_copilot_service.dart';
import 'package:provider/provider.dart';

class AISettingsDialog extends StatefulWidget {
  const AISettingsDialog({Key? key}) : super(key: key);

  @override
  State<AISettingsDialog> createState() => _AISettingsDialogState();
}

class _AISettingsDialogState extends State<AISettingsDialog> {
  late AISettings _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await AISettings.load();
    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await _settings.save();
    final aiService = context.read<AISecurityCopilotService>();
    await aiService.updateSettings(_settings);
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI settings updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AI Assistant Settings',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Core Features'),
                          _buildSwitch(
                            'Deep Reasoning',
                            'Enable advanced analysis with multi-layered reasoning chains',
                            _settings.deepReasoningEnabled,
                            (value) => setState(() => _settings.deepReasoningEnabled = value),
                            Icons.psychology,
                          ),
                          _buildSwitch(
                            'Self-Learning',
                            'Allow AI to learn from interactions and improve over time',
                            _settings.selfLearningEnabled,
                            (value) => setState(() => _settings.selfLearningEnabled = value),
                            Icons.school,
                          ),
                          _buildSwitch(
                            'Suspicious Activity Detection',
                            'Automatically detect and alert on anomalous behavior',
                            _settings.suspiciousActivityDetectionEnabled,
                            (value) => setState(() => _settings.suspiciousActivityDetectionEnabled = value),
                            Icons.warning_amber,
                          ),
                          _buildSwitch(
                            'Policy Recommendations',
                            'Suggest security policy improvements based on analysis',
                            _settings.policyRecommendationsEnabled,
                            (value) => setState(() => _settings.policyRecommendationsEnabled = value),
                            Icons.policy,
                          ),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Automated Actions'),
                          _buildSwitch(
                            'Enable Auto Actions',
                            'Allow AI to execute approved actions automatically',
                            _settings.autoActionsEnabled,
                            (value) => setState(() => _settings.autoActionsEnabled = value),
                            Icons.auto_mode,
                            isImportant: true,
                          ),
                          _buildSwitch(
                            'Enable Requested Actions',
                            'Allow AI to suggest actions for manual approval',
                            _settings.requestedActionsEnabled,
                            (value) => setState(() => _settings.requestedActionsEnabled = value),
                            Icons.touch_app,
                          ),
                          if (_settings.autoActionsEnabled) ...[
                            const SizedBox(height: 16),
                            _buildSlider(
                              'Auto Action Delay',
                              'Seconds to wait before executing auto actions',
                              _settings.autoActionDelaySeconds.toDouble(),
                              10,
                              120,
                              (value) => setState(() => _settings.autoActionDelaySeconds = value.toInt()),
                            ),
                            _buildSlider(
                              'Confidence Threshold',
                              'Minimum confidence required for auto actions',
                              _settings.autoActionThreshold * 100,
                              50,
                              100,
                              (value) => setState(() => _settings.autoActionThreshold = value / 100),
                              suffix: '%',
                            ),
                            const SizedBox(height: 16),
                            _buildSectionTitle('Allowed Action Types'),
                            ..._settings.actionTypeSettings.entries.map((entry) =>
                              _buildActionTypeSwitch(
                                _getActionTypeLabel(entry.key),
                                entry.value,
                                (value) => setState(() => _settings.actionTypeSettings[entry.key] = value),
                                _getActionTypeIcon(entry.key),
                                _getActionTypeRisk(entry.key),
                              ),
                            ).toList(),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Settings'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildSwitch(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon, {
    bool isImportant = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isImportant ? 3 : 1,
      color: isImportant ? Colors.amber.shade50 : null,
      child: ListTile(
        leading: Icon(icon, color: isImportant ? Colors.orange : Colors.blue),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isImportant ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: isImportant ? Colors.orange : Colors.blue,
        ),
      ),
    );
  }

  Widget _buildActionTypeSwitch(
    String title,
    bool value,
    Function(bool) onChanged,
    IconData icon,
    String riskLevel,
  ) {
    Color riskColor;
    switch (riskLevel) {
      case 'high':
        riskColor = Colors.red;
        break;
      case 'medium':
        riskColor = Colors.orange;
        break;
      default:
        riskColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: Icon(icon, size: 20),
        title: Text(title),
        subtitle: Text(
          'Risk: $riskLevel',
          style: TextStyle(color: riskColor, fontSize: 12),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildSlider(
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    Function(double) onChanged, {
    String suffix = '',
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${value.toInt()}$suffix',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).toInt(),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  String _getActionTypeLabel(String type) {
    switch (type) {
      case 'block_ip':
        return 'Block IP Address';
      case 'disable_account':
        return 'Disable User Account';
      case 'force_mfa':
        return 'Force MFA Activation';
      case 'isolate_system':
        return 'Isolate System';
      case 'reset_password':
        return 'Reset Password';
      case 'enable_monitoring':
        return 'Enable Monitoring';
      case 'update_firewall':
        return 'Update Firewall Rules';
      case 'quarantine_file':
        return 'Quarantine Files';
      default:
        return type;
    }
  }

  IconData _getActionTypeIcon(String type) {
    switch (type) {
      case 'block_ip':
        return Icons.block;
      case 'disable_account':
        return Icons.person_off;
      case 'force_mfa':
        return Icons.security;
      case 'isolate_system':
        return Icons.offline_bolt;
      case 'reset_password':
        return Icons.lock_reset;
      case 'enable_monitoring':
        return Icons.visibility;
      case 'update_firewall':
        return Icons.shield;
      case 'quarantine_file':
        return Icons.folder_off;
      default:
        return Icons.settings;
    }
  }

  String _getActionTypeRisk(String type) {
    switch (type) {
      case 'isolate_system':
      case 'disable_account':
      case 'quarantine_file':
        return 'high';
      case 'block_ip':
      case 'reset_password':
      case 'update_firewall':
        return 'medium';
      case 'force_mfa':
      case 'enable_monitoring':
        return 'low';
      default:
        return 'medium';
    }
  }
}
