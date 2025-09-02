import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class EmailService extends ChangeNotifier {
  final ApiService _apiService;
  bool _isLoading = false;
  String? _error;

  EmailService(this._apiService);

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> sendSummaryEmail({
    required String to,
    required String subject,
    required Map<String, dynamic> summaryData,
    String? cc,
    String? bcc,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final emailBody = _generateSummaryEmailBody(summaryData);
      
      final response = await _apiService.post('/api/email/send', body: {
        'to': to,
        'cc': cc,
        'bcc': bcc,
        'subject': subject,
        'body': emailBody,
        'type': 'summary',
        'data': summaryData,
      });

      if (response.isSuccess) {
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Failed to send email';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Email service error: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendSecurityAlert({
    required String to,
    required String alertType,
    required Map<String, dynamic> alertData,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final subject = _getSecurityAlertSubject(alertType);
      final emailBody = _generateSecurityAlertBody(alertType, alertData);
      
      final response = await _apiService.post('/api/email/send', body: {
        'to': to,
        'subject': subject,
        'body': emailBody,
        'type': 'security_alert',
        'priority': 'high',
        'data': alertData,
      });

      if (response.isSuccess) {
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Failed to send security alert';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Security alert email error: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordResetEmail(String to, String resetToken) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.post('/api/email/password-reset', body: {
        'to': to,
        'resetToken': resetToken,
      });

      if (response.isSuccess) {
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Failed to send password reset email';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Password reset email error: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendVerificationEmail(String to, String verificationCode) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.post('/api/email/verification', body: {
        'to': to,
        'verificationCode': verificationCode,
      });

      if (response.isSuccess) {
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Failed to send verification email';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Verification email error: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> scheduleRecurringEmail({
    required String to,
    required String subject,
    required String schedule, // 'daily', 'weekly', 'monthly'
    required Map<String, dynamic> templateData,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.post('/api/email/schedule', body: {
        'to': to,
        'subject': subject,
        'schedule': schedule,
        'templateData': templateData,
      });

      if (response.isSuccess) {
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Failed to schedule email';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Email scheduling error: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  String _generateSummaryEmailBody(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html><head><style>');
    buffer.writeln('body { font-family: Arial, sans-serif; margin: 20px; }');
    buffer.writeln('.header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }');
    buffer.writeln('.metric { margin: 10px 0; padding: 10px; border-left: 4px solid #007bff; }');
    buffer.writeln('.alert { background-color: #fff3cd; border-color: #ffeaa7; color: #856404; }');
    buffer.writeln('</style></head><body>');
    
    buffer.writeln('<div class="header">');
    buffer.writeln('<h2>Security Summary Report</h2>');
    buffer.writeln('<p>Generated: ${DateTime.now().toString()}</p>');
    buffer.writeln('</div>');
    
    buffer.writeln('<h3>Key Metrics</h3>');
    final metrics = data['metrics'] as Map<String, dynamic>? ?? {};
    metrics.forEach((key, value) {
      buffer.writeln('<div class="metric">');
      buffer.writeln('<strong>${_formatMetricName(key)}:</strong> $value');
      buffer.writeln('</div>');
    });
    
    final alerts = data['alerts'] as List<dynamic>? ?? [];
    if (alerts.isNotEmpty) {
      buffer.writeln('<h3>Recent Alerts</h3>');
      for (final alert in alerts) {
        buffer.writeln('<div class="metric alert">');
        buffer.writeln('<strong>${alert['type']}:</strong> ${alert['message']}');
        buffer.writeln('<br><small>${alert['timestamp']}</small>');
        buffer.writeln('</div>');
      }
    }
    
    buffer.writeln('</body></html>');
    return buffer.toString();
  }

  String _generateSecurityAlertBody(String alertType, Map<String, dynamic> data) {
    final buffer = StringBuffer();
    
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html><head><style>');
    buffer.writeln('body { font-family: Arial, sans-serif; margin: 20px; }');
    buffer.writeln('.alert { background-color: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; padding: 15px; border-radius: 5px; }');
    buffer.writeln('.details { margin-top: 15px; padding: 10px; background-color: #f8f9fa; border-radius: 3px; }');
    buffer.writeln('</style></head><body>');
    
    buffer.writeln('<div class="alert">');
    buffer.writeln('<h2>🚨 Security Alert: ${_formatAlertType(alertType)}</h2>');
    buffer.writeln('<p><strong>Time:</strong> ${data['timestamp'] ?? DateTime.now()}</p>');
    buffer.writeln('<p><strong>Severity:</strong> ${data['severity'] ?? 'High'}</p>');
    buffer.writeln('</div>');
    
    buffer.writeln('<div class="details">');
    buffer.writeln('<h3>Details</h3>');
    buffer.writeln('<p>${data['description'] ?? 'Security event detected'}</p>');
    
    if (data['ipAddress'] != null) {
      buffer.writeln('<p><strong>IP Address:</strong> ${data['ipAddress']}</p>');
    }
    if (data['location'] != null) {
      buffer.writeln('<p><strong>Location:</strong> ${data['location']}</p>');
    }
    if (data['userAgent'] != null) {
      buffer.writeln('<p><strong>User Agent:</strong> ${data['userAgent']}</p>');
    }
    
    buffer.writeln('<h3>Recommended Actions</h3>');
    buffer.writeln('<ul>');
    buffer.writeln('<li>Review your recent account activity</li>');
    buffer.writeln('<li>Change your password if you suspect unauthorized access</li>');
    buffer.writeln('<li>Enable two-factor authentication if not already active</li>');
    buffer.writeln('<li>Contact support if you need assistance</li>');
    buffer.writeln('</ul>');
    buffer.writeln('</div>');
    
    buffer.writeln('</body></html>');
    return buffer.toString();
  }

  String _getSecurityAlertSubject(String alertType) {
    switch (alertType) {
      case 'failed_login':
        return '🚨 Multiple Failed Login Attempts Detected';
      case 'new_device':
        return '🔐 New Device Login Detected';
      case 'password_change':
        return '🔑 Password Changed Successfully';
      case 'suspicious_activity':
        return '⚠️ Suspicious Account Activity Detected';
      default:
        return '🚨 Security Alert';
    }
  }

  String _formatMetricName(String key) {
    return key.split('_').map((word) => 
        word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  String _formatAlertType(String alertType) {
    return alertType.split('_').map((word) => 
        word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
