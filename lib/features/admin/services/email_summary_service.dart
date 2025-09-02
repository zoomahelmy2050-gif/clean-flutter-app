import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:clean_flutter/locator.dart';
import 'package:clean_flutter/features/admin/services/logging_service.dart';
import 'package:clean_flutter/core/services/email_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum EmailFrequency { daily, weekly, monthly }

class EmailSummaryService extends ChangeNotifier {
  static const String _lastSentKey = 'email_summary_last_sent';
  Timer? _scheduleTimer;
  bool _isEnabled = false;
  DateTime? _lastSentAt;
  
  // Default settings
  EmailFrequency _frequency = EmailFrequency.daily;
  String _defaultRecipient = 'env.hygiene@gmail.com';
  
  bool get isEnabled => _isEnabled;
  DateTime? get lastSentAt => _lastSentAt;
  EmailFrequency get frequency => _frequency;
  String get defaultRecipient => _defaultRecipient;
  
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSentMillis = prefs.getInt(_lastSentKey);
    if (lastSentMillis != null) {
      _lastSentAt = DateTime.fromMillisecondsSinceEpoch(lastSentMillis);
    }
    
    // Start the scheduler
    startScheduler();
  }
  
  void startScheduler() {
    stopScheduler();
    _isEnabled = true;
    
    // Check every hour if we should send an email
    _scheduleTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _checkAndSendSummary();
    });
    
    // Initial check
    _checkAndSendSummary();
    notifyListeners();
  }
  
  void stopScheduler() {
    _scheduleTimer?.cancel();
    _scheduleTimer = null;
    _isEnabled = false;
    notifyListeners();
  }
  
  Future<void> _checkAndSendSummary() async {
    try {
      final now = DateTime.now();
      
      // Check if we should send based on frequency
      if (_lastSentAt != null) {
        final timeSinceLastSent = now.difference(_lastSentAt!);
        
        switch (_frequency) {
          case EmailFrequency.daily:
            if (timeSinceLastSent.inHours < 24) return;
            break;
          case EmailFrequency.weekly:
            if (timeSinceLastSent.inDays < 7) return;
            break;
          case EmailFrequency.monthly:
            if (timeSinceLastSent.inDays < 30) return;
            break;
        }
      }
      
      await sendSummaryNow();
    } catch (e) {
      debugPrint('Error checking summary email schedule: $e');
    }
  }
  
  Future<bool> sendSummaryNow({String? recipientEmail}) async {
    try {
      final emailService = locator<EmailService>();
      final loggingService = locator<LoggingService>();
      
      // Determine recipient
      final recipient = recipientEmail ?? _defaultRecipient;
      if (recipient.isEmpty) {
        debugPrint('No recipient configured for summary email');
        return false;
      }
      
      // Determine time window
      final now = DateTime.now();
      Duration window;
      switch (_frequency) {
        case EmailFrequency.daily:
          window = const Duration(days: 1);
          break;
        case EmailFrequency.weekly:
          window = const Duration(days: 7);
          break;
        case EmailFrequency.monthly:
          window = const Duration(days: 30);
          break;
      }
      
      final since = _lastSentAt ?? now.subtract(window);
      
      // Gather security metrics
      final summaryData = await _gatherSecurityMetrics(since, now);
      
      // Send the email
      final subject = 'Security Summary - ${_formatDate(now)}';
      
      final success = await emailService.sendSummaryEmail(
        to: recipient,
        subject: subject,
        summaryData: summaryData,
      );
      
      if (success) {
        _lastSentAt = now;
        await _saveLastSentTime();
        notifyListeners();
        debugPrint('Summary email sent successfully to $recipient');
        return true;
      } else {
        debugPrint('Failed to send summary email');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending summary email: $e');
      return false;
    }
  }
  
  Future<Map<String, dynamic>> _gatherSecurityMetrics(DateTime since, DateTime now) async {
    final loggingService = locator<LoggingService>();
    
    // Filter logs within the time window
    bool isWithinWindow(DateTime timestamp) {
      return timestamp.isAfter(since) && timestamp.isBefore(now);
    }
    
    final failedAttempts = loggingService.failedAttempts
        .where((e) => isWithinWindow(e.timestamp))
        .toList();
    
    final successfulLogins = loggingService.successfulLogins
        .where((e) => isWithinWindow(e.timestamp))
        .toList();
    
    final signUps = loggingService.signUps
        .where((e) => isWithinWindow(e.timestamp))
        .toList();
    
    final mfaUsed = loggingService.mfaUsed
        .where((e) => isWithinWindow(e.timestamp))
        .toList();
    
    final adminActions = loggingService.adminActions
        .where((e) => isWithinWindow(e.timestamp))
        .toList();
    
    // Prepare alerts
    final alerts = <Map<String, dynamic>>[];
    
    // Add alert for multiple failed attempts
    if (failedAttempts.length > 5) {
      alerts.add({
        'type': 'High Failed Attempts',
        'message': '${failedAttempts.length} failed login attempts detected',
        'timestamp': now.toIso8601String(),
        'severity': 'warning',
      });
    }
    
    // Add alert for unusual activity patterns
    final uniqueIPs = failedAttempts.map((e) => e.ip).toSet().length;
    if (uniqueIPs > 10) {
      alerts.add({
        'type': 'Multiple IPs',
        'message': 'Login attempts from $uniqueIPs different IP addresses',
        'timestamp': now.toIso8601String(),
        'severity': 'warning',
      });
    }
    
    return {
      'reportPeriod': {
        'from': since.toIso8601String(),
        'to': now.toIso8601String(),
      },
      'metrics': {
        'failedAttempts': failedAttempts.length,
        'successfulLogins': successfulLogins.length,
        'newSignups': signUps.length,
        'mfaUsage': mfaUsed.length,
        'adminActions': adminActions.length,
        'uniqueUsers': _getUniqueUsers(successfulLogins),
        'uniqueDevices': _getUniqueDevices(successfulLogins),
      },
      'alerts': alerts,
      'topFailedUsers': _getTopUsers(failedAttempts, 5),
      'topActiveUsers': _getTopUsers(successfulLogins, 5),
      'recentAdminActions': adminActions.take(10).map((e) => {
        'user': e.username,
        'action': 'Admin action',
        'timestamp': e.timestamp.toIso8601String(),
        'device': e.device,
      }).toList(),
    };
  }
  
  int _getUniqueUsers(List<dynamic> logs) {
    return logs.map((e) => e.username).toSet().length;
  }
  
  int _getUniqueDevices(List<dynamic> logs) {
    return logs.where((e) => e.device != null).map((e) => e.device).toSet().length;
  }
  
  List<Map<String, dynamic>> _getTopUsers(List<dynamic> logs, int limit) {
    final userCounts = <String, int>{};
    for (final log in logs) {
      userCounts[log.username] = (userCounts[log.username] ?? 0) + 1;
    }
    
    final sortedUsers = userCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedUsers.take(limit).map((e) => {
      'username': e.key,
      'count': e.value,
    }).toList();
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  Future<void> _saveLastSentTime() async {
    if (_lastSentAt != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSentKey, _lastSentAt!.millisecondsSinceEpoch);
    }
  }
  
  @override
  void dispose() {
    stopScheduler();
    super.dispose();
  }
}
