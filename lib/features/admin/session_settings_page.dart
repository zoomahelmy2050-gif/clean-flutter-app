import 'package:flutter/material.dart';
import '../../core/services/session_service.dart';
import '../../locator.dart';
import '../../generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:clean_flutter/core/services/language_service.dart';

class SessionSettingsPage extends StatefulWidget {
  const SessionSettingsPage({super.key});

  @override
  State<SessionSettingsPage> createState() => _SessionSettingsPageState();
}

class _SessionSettingsPageState extends State<SessionSettingsPage> {
  late SessionService _sessionService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _sessionService = locator<SessionService>();
  }

  Future<void> _updateTimeout(int minutes) async {
    setState(() => _isLoading = true);
    try {
      await _sessionService.setSessionTimeout(minutes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              minutes == 0 
                ? 'Session timeout disabled' 
                : 'Session timeout set to $minutes minutes',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update timeout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<LanguageService>(
          builder: (context, languageService, child) {
            final l10n = AppLocalizations.of(context)!;
            return Text(l10n.sessionSettings);
          },
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  _buildCurrentSettingsCard(),
                  const SizedBox(height: 16),
                  _buildTimeoutOptionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'About Session Timeout',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Session timeout automatically logs you out after a period of inactivity to protect your account. '
              'You will receive a warning 2 minutes before timeout.',
            ),
            const SizedBox(height: 8),
            const Text(
              '• Activity includes taps, scrolling, and navigation\n'
              '• Warning appears 2 minutes before timeout\n'
              '• You can extend your session when warned\n'
              '• Timeout can be disabled for convenience',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSettingsCard() {
    final isEnabled = _sessionService.isTimeoutEnabled;
    final timeoutMinutes = _sessionService.timeoutMinutes;
    final lastActivity = _sessionService.lastActivity;
    final remainingMinutes = _sessionService.remainingMinutes;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isEnabled ? Icons.timer : Icons.timer_off,
                  color: isEnabled ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Status:'),
                Text(
                  isEnabled ? 'Enabled' : 'Disabled',
                  style: TextStyle(
                    color: isEnabled ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (isEnabled) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Timeout Duration:'),
                  Text(
                    '$timeoutMinutes minutes',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (lastActivity != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Last Activity:'),
                    Text(
                      _formatTime(lastActivity),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Time Remaining:'),
                    Text(
                      remainingMinutes > 0 ? '$remainingMinutes minutes' : 'Expired',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: remainingMinutes <= 2 ? Colors.orange : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeoutOptionsCard() {
    final currentTimeout = _sessionService.timeoutMinutes;
    
    final options = [
      {'label': 'Disabled', 'minutes': 0, 'description': 'Never timeout automatically'},
      {'label': '5 minutes', 'minutes': 5, 'description': 'Very short timeout'},
      {'label': '15 minutes', 'minutes': 15, 'description': 'Default timeout'},
      {'label': '30 minutes', 'minutes': 30, 'description': 'Medium timeout'},
      {'label': '60 minutes', 'minutes': 60, 'description': 'Long timeout'},
      {'label': '2 hours', 'minutes': 120, 'description': 'Very long timeout'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Timeout Options',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...options.map((option) {
              final minutes = option['minutes'] as int;
              final label = option['label'] as String;
              final description = option['description'] as String;
              final isSelected = currentTimeout == minutes;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Radio<int>(
                    value: minutes,
                    groupValue: currentTimeout,
                    onChanged: (value) {
                      if (value != null) {
                        _updateTimeout(value);
                      }
                    },
                  ),
                  title: Text(
                    label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(description),
                  onTap: () => _updateTimeout(minutes),
                  tileColor: isSelected ? Colors.blue.withOpacity(0.1) : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            if (_sessionService.isTimeoutEnabled) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _sessionService.extendSession(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset Session Timer'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
