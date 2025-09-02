import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../../features/auth/services/auth_service.dart';
import '../../locator.dart';

class SecurityReminderService {
  static const String _lastReminderKey = 'last_security_reminder';
  static const String _reminderCountKey = 'security_reminder_count';
  static const String _skipCountKey = 'security_skip_count';
  
  // Reminder intervals in days
  static const List<int> _reminderIntervals = [1, 3, 7, 14, 30];
  static const int _maxReminders = 5;

  Future<void> recordSecuritySkip(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final skipCount = prefs.getInt('${_skipCountKey}_$email') ?? 0;
    await prefs.setInt('${_skipCountKey}_$email', skipCount + 1);
    await prefs.setInt('${_lastReminderKey}_$email', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> recordSecuritySetupComplete(String email) async {
    final prefs = await SharedPreferences.getInstance();
    // Clear all reminder data when security setup is completed
    await prefs.remove('${_lastReminderKey}_$email');
    await prefs.remove('${_reminderCountKey}_$email');
    await prefs.remove('${_skipCountKey}_$email');
  }

  Future<bool> shouldShowReminder(String email) async {
    final authService = locator<AuthService>();
    
    // Don't show reminders if user has completed security setup
    if (!authService.needsSecuritySetup(email)) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastReminder = prefs.getInt('${_lastReminderKey}_$email');
    final reminderCount = prefs.getInt('${_reminderCountKey}_$email') ?? 0;
    final skipCount = prefs.getInt('${_skipCountKey}_$email') ?? 0;

    // Don't show more reminders if we've reached the maximum
    if (reminderCount >= _maxReminders) {
      return false;
    }

    // Don't show reminders if user hasn't skipped setup yet
    if (skipCount == 0) {
      return false;
    }

    if (lastReminder == null) {
      return true;
    }

    final lastReminderDate = DateTime.fromMillisecondsSinceEpoch(lastReminder);
    final daysSinceLastReminder = DateTime.now().difference(lastReminderDate).inDays;
    
    // Use progressive intervals based on reminder count
    final intervalIndex = reminderCount < _reminderIntervals.length 
        ? reminderCount 
        : _reminderIntervals.length - 1;
    final requiredInterval = _reminderIntervals[intervalIndex];

    return daysSinceLastReminder >= requiredInterval;
  }

  Future<void> showSecurityReminder(BuildContext context, String email) async {
    final prefs = await SharedPreferences.getInstance();
    final reminderCount = prefs.getInt('${_reminderCountKey}_$email') ?? 0;
    final skipCount = prefs.getInt('${_skipCountKey}_$email') ?? 0;

    String title;
    String message;
    IconData icon;

    if (skipCount == 1) {
      title = 'Secure Your Account';
      message = 'Your account security could be improved. Setting up additional security methods helps protect your data.';
      icon = Icons.security;
    } else if (skipCount <= 3) {
      title = 'Account Security Reminder';
      message = 'We noticed you haven\'t set up additional security methods yet. This takes just a few minutes and significantly improves your account protection.';
      icon = Icons.shield;
    } else {
      title = 'Important Security Notice';
      message = 'Your account is using basic security. Consider enabling two-factor authentication to prevent unauthorized access.';
      icon = Icons.warning_amber;
    }

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                const Expanded(child: Text('Authenticator App', style: TextStyle(fontSize: 12))),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                const Expanded(child: Text('Backup Codes', style: TextStyle(fontSize: 12))),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                const Expanded(child: Text('Biometric Authentication', style: TextStyle(fontSize: 12))),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('later'),
            child: const Text('Remind Me Later'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop('setup'),
            child: const Text('Set Up Now'),
          ),
        ],
      ),
    );

    // Record that we showed a reminder
    await prefs.setInt('${_reminderCountKey}_$email', reminderCount + 1);
    await prefs.setInt('${_lastReminderKey}_$email', DateTime.now().millisecondsSinceEpoch);

    if (result == 'setup') {
      // Navigate to security setup
      Navigator.of(context).pushNamed('/security-setup', arguments: email);
    }
  }

  Future<Map<String, dynamic>> getReminderStats(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'skipCount': prefs.getInt('${_skipCountKey}_$email') ?? 0,
      'reminderCount': prefs.getInt('${_reminderCountKey}_$email') ?? 0,
      'lastReminder': prefs.getInt('${_lastReminderKey}_$email'),
    };
  }
}
