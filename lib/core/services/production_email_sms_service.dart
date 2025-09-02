import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProductionEmailSmsService extends ChangeNotifier {
  static ProductionEmailSmsService? _instance;
  static ProductionEmailSmsService get instance => _instance ??= ProductionEmailSmsService._();
  ProductionEmailSmsService._();

  final Dio _dio = Dio();
  bool _isInitialized = false;

  // API Configuration loaded from environment
  late String _sendGridApiKey;
  late String _twilioAccountSid;
  late String _twilioAuthToken;
  late String _twilioPhoneNumber;
  late String _fromEmail;
  late String _fromName;

  // API Endpoints
  static const String sendGridBaseUrl = 'https://api.sendgrid.com/v3';
  static const String twilioBaseUrl = 'https://api.twilio.com/2010-04-01';

  // Templates
  final Map<String, EmailTemplate> _emailTemplates = {};
  final Map<String, SmsTemplate> _smsTemplates = {};

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Load API keys from environment
    _sendGridApiKey = dotenv.env['SENDGRID_API_KEY'] ?? '';
    _twilioAccountSid = dotenv.env['TWILIO_ACCOUNT_SID'] ?? '';
    _twilioAuthToken = dotenv.env['TWILIO_AUTH_TOKEN'] ?? '';
    _twilioPhoneNumber = dotenv.env['TWILIO_PHONE_NUMBER'] ?? '+1234567890';
    _fromEmail = dotenv.env['SENDGRID_FROM_EMAIL'] ?? 'security@yourcompany.com';
    _fromName = dotenv.env['SENDGRID_FROM_NAME'] ?? 'Security System';

    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    await _loadTemplates();
    _isInitialized = true;
    
    if (_hasValidCredentials()) {
      developer.log('Production email/SMS service initialized with real APIs');
    } else {
      developer.log('Production email/SMS service initialized in mock mode - no API keys found');
    }
  }

  Future<void> _loadTemplates() async {
    // Security Alert Templates
    _emailTemplates['security_alert'] = EmailTemplate(
      id: 'security_alert',
      subject: 'Security Alert: {{alert_type}}',
      htmlContent: '''
      <html>
        <body style="font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5;">
          <div style="max-width: 600px; margin: 0 auto; background-color: white; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
            <div style="background-color: #dc3545; color: white; padding: 20px; border-radius: 8px 8px 0 0;">
              <h1 style="margin: 0; font-size: 24px;">🚨 Security Alert</h1>
            </div>
            <div style="padding: 30px;">
              <h2 style="color: #333; margin-top: 0;">{{alert_type}}</h2>
              <p style="color: #666; line-height: 1.6;">{{description}}</p>
              
              <div style="background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0;">
                <strong>Alert Details:</strong><br>
                <strong>Severity:</strong> {{severity}}<br>
                <strong>Time:</strong> {{timestamp}}<br>
                <strong>Source:</strong> {{source}}
              </div>

              {{#if recommendations}}
              <h3 style="color: #333;">Recommended Actions:</h3>
              <ul style="color: #666;">
                {{#each recommendations}}
                <li>{{this}}</li>
                {{/each}}
              </ul>
              {{/if}}

              <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee;">
                <p style="color: #999; font-size: 12px;">
                  This is an automated security alert from your security system.
                  If you believe this is a false positive, please contact your security administrator.
                </p>
              </div>
            </div>
          </div>
        </body>
      </html>
      ''',
      textContent: '''
      Security Alert: {{alert_type}}
      
      {{description}}
      
      Alert Details:
      Severity: {{severity}}
      Time: {{timestamp}}
      Source: {{source}}
      
      {{#if recommendations}}
      Recommended Actions:
      {{#each recommendations}}
      - {{this}}
      {{/each}}
      {{/if}}
      
      This is an automated security alert from your security system.
      ''',
    );

    _emailTemplates['compliance_violation'] = EmailTemplate(
      id: 'compliance_violation',
      subject: 'Compliance Violation Detected: {{framework}}',
      htmlContent: '''
      <html>
        <body style="font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5;">
          <div style="max-width: 600px; margin: 0 auto; background-color: white; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
            <div style="background-color: #ffc107; color: #212529; padding: 20px; border-radius: 8px 8px 0 0;">
              <h1 style="margin: 0; font-size: 24px;">⚠️ Compliance Violation</h1>
            </div>
            <div style="padding: 30px;">
              <h2 style="color: #333; margin-top: 0;">{{framework}} - {{rule_id}}</h2>
              <p style="color: #666; line-height: 1.6;">{{description}}</p>
              
              <div style="background-color: #fff3cd; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #ffc107;">
                <strong>Violation Details:</strong><br>
                <strong>Framework:</strong> {{framework}}<br>
                <strong>Rule:</strong> {{rule_id}}<br>
                <strong>Severity:</strong> {{severity}}<br>
                <strong>Detected:</strong> {{timestamp}}
              </div>

              {{#if remediation}}
              <h3 style="color: #333;">Remediation Steps:</h3>
              <div style="background-color: #d1ecf1; padding: 15px; border-radius: 5px; border-left: 4px solid #17a2b8;">
                <p style="margin: 0; color: #0c5460;">{{remediation}}</p>
              </div>
              {{/if}}
            </div>
          </div>
        </body>
      </html>
      ''',
      textContent: '''
      Compliance Violation Detected: {{framework}}
      
      {{framework}} - {{rule_id}}
      {{description}}
      
      Violation Details:
      Framework: {{framework}}
      Rule: {{rule_id}}
      Severity: {{severity}}
      Detected: {{timestamp}}
      
      {{#if remediation}}
      Remediation Steps:
      {{remediation}}
      {{/if}}
      ''',
    );

    // SMS Templates
    _smsTemplates['security_alert'] = SmsTemplate(
      id: 'security_alert',
      content: 'SECURITY ALERT: {{alert_type}} detected. Severity: {{severity}}. Check your security dashboard for details.',
    );

    _smsTemplates['compliance_violation'] = SmsTemplate(
      id: 'compliance_violation',
      content: 'COMPLIANCE VIOLATION: {{framework}} rule {{rule_id}} violated. Severity: {{severity}}. Immediate attention required.',
    );

    _smsTemplates['device_alert'] = SmsTemplate(
      id: 'device_alert',
      content: 'DEVICE ALERT: {{device_name}} - {{alert_type}}. Status: {{status}}. Action may be required.',
    );
  }

  // Email sending methods
  Future<EmailResult> sendSecurityAlert({
    required String toEmail,
    required String alertType,
    required String description,
    required String severity,
    required String source,
    List<String>? recommendations,
  }) async {
    final template = _emailTemplates['security_alert']!;
    final variables = {
      'alert_type': alertType,
      'description': description,
      'severity': severity,
      'source': source,
      'timestamp': DateTime.now().toString(),
      'recommendations': recommendations,
    };

    return await _sendEmail(
      to: toEmail,
      template: template,
      variables: variables,
    );
  }

  Future<EmailResult> sendComplianceViolation({
    required String toEmail,
    required String framework,
    required String ruleId,
    required String description,
    required String severity,
    String? remediation,
  }) async {
    final template = _emailTemplates['compliance_violation']!;
    final variables = {
      'framework': framework,
      'rule_id': ruleId,
      'description': description,
      'severity': severity,
      'timestamp': DateTime.now().toString(),
      'remediation': remediation,
    };

    return await _sendEmail(
      to: toEmail,
      template: template,
      variables: variables,
    );
  }

  Future<EmailResult> _sendEmail({
    required String to,
    required EmailTemplate template,
    required Map<String, dynamic> variables,
    String? fromEmail,
    String? fromName,
  }) async {
    try {
      final subject = _processTemplate(template.subject, variables);
      final htmlContent = _processTemplate(template.htmlContent, variables);
      final textContent = _processTemplate(template.textContent, variables);

      final response = await _dio.post(
        '$sendGridBaseUrl/mail/send',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_sendGridApiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'personalizations': [
            {
              'to': [
                {'email': to}
              ],
              'subject': subject,
            }
          ],
          'from': {
            'email': fromEmail ?? _fromEmail,
            'name': fromName ?? _fromName,
          },
          'content': [
            {
              'type': 'text/plain',
              'value': textContent,
            },
            {
              'type': 'text/html',
              'value': htmlContent,
            },
          ],
        },
      );

      if (response.statusCode == 202) {
        developer.log('Email sent successfully to $to');
        return EmailResult(success: true, messageId: response.headers['x-message-id']?.first);
      } else {
        developer.log('Email sending failed: ${response.statusCode}');
        return EmailResult(success: false, error: 'HTTP ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Email sending error: $e');
      return EmailResult(success: false, error: e.toString());
    }
  }

  // SMS sending methods
  Future<SmsResult> sendSecurityAlertSms({
    required String toPhone,
    required String alertType,
    required String severity,
  }) async {
    final template = _smsTemplates['security_alert']!;
    final variables = {
      'alert_type': alertType,
      'severity': severity,
    };

    return await _sendSms(
      to: toPhone,
      template: template,
      variables: variables,
    );
  }

  Future<SmsResult> sendComplianceViolationSms({
    required String toPhone,
    required String framework,
    required String ruleId,
    required String severity,
  }) async {
    final template = _smsTemplates['compliance_violation']!;
    final variables = {
      'framework': framework,
      'rule_id': ruleId,
      'severity': severity,
    };

    return await _sendSms(
      to: toPhone,
      template: template,
      variables: variables,
    );
  }

  Future<SmsResult> sendDeviceAlertSms({
    required String toPhone,
    required String deviceName,
    required String alertType,
    required String status,
  }) async {
    final template = _smsTemplates['device_alert']!;
    final variables = {
      'device_name': deviceName,
      'alert_type': alertType,
      'status': status,
    };

    return await _sendSms(
      to: toPhone,
      template: template,
      variables: variables,
    );
  }

  Future<SmsResult> _sendSms({
    required String to,
    required SmsTemplate template,
    required Map<String, dynamic> variables,
  }) async {
    try {
      final message = _processTemplate(template.content, variables);

      final response = await _dio.post(
        '$twilioBaseUrl/Accounts/$_twilioAccountSid/Messages.json',
        options: Options(
          headers: {
            'Authorization': 'Basic ${base64Encode(utf8.encode('$_twilioAccountSid:$_twilioAuthToken'))}',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
        data: {
          'From': _twilioPhoneNumber,
          'To': to,
          'Body': message,
        },
      );

      if (response.statusCode == 201) {
        developer.log('SMS sent successfully to $to');
        return SmsResult(success: true, messageId: response.data['sid']);
      } else {
        developer.log('SMS sending failed: ${response.statusCode}');
        return SmsResult(success: false, error: 'HTTP ${response.statusCode}');
      }
    } catch (e) {
      developer.log('SMS sending error: $e');
      return SmsResult(success: false, error: e.toString());
    }
  }

  // Bulk operations
  Future<List<EmailResult>> sendBulkEmails(List<BulkEmailRequest> requests) async {
    final results = <EmailResult>[];
    
    for (final request in requests) {
      final result = await _sendEmail(
        to: request.to,
        template: request.template,
        variables: request.variables,
        fromEmail: request.fromEmail,
        fromName: request.fromName,
      );
      results.add(result);
      
      // Rate limiting - SendGrid allows 600 emails per minute
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    return results;
  }

  Future<List<SmsResult>> sendBulkSms(List<BulkSmsRequest> requests) async {
    final results = <SmsResult>[];
    
    for (final request in requests) {
      final result = await _sendSms(
        to: request.to,
        template: request.template,
        variables: request.variables,
      );
      results.add(result);
      
      // Rate limiting - Twilio allows 1 message per second by default
      await Future.delayed(const Duration(seconds: 1));
    }
    
    return results;
  }

  // Template processing
  String _processTemplate(String template, Map<String, dynamic> variables) {
    String processed = template;
    
    variables.forEach((key, value) {
      if (value is List) {
        // Handle list variables (like recommendations)
        if (processed.contains('{{#each $key}}')) {
          final listItems = value.map((item) => '<li>$item</li>').join('\n');
          processed = processed.replaceAll(
            RegExp(r'\{\{#each ' + key + r'\}\}.*?\{\{/each\}\}', dotAll: true),
            listItems,
          );
        }
      } else if (value != null) {
        processed = processed.replaceAll('{{$key}}', value.toString());
      }
    });
    
    // Handle conditional blocks
    processed = processed.replaceAll(RegExp(r'\{\{#if \w+\}\}.*?\{\{/if\}\}', dotAll: true), '');
    
    return processed;
  }

  // Delivery status tracking
  Future<DeliveryStatus> getEmailDeliveryStatus(String messageId) async {
    try {
      final response = await _dio.get(
        '$sendGridBaseUrl/messages/$messageId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_sendGridApiKey',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return DeliveryStatus(
          messageId: messageId,
          status: data['status'],
          deliveredAt: data['delivered_at'] != null ? DateTime.parse(data['delivered_at']) : null,
          openedAt: data['opened_at'] != null ? DateTime.parse(data['opened_at']) : null,
          clickedAt: data['clicked_at'] != null ? DateTime.parse(data['clicked_at']) : null,
        );
      }
    } catch (e) {
      developer.log('Error getting email delivery status: $e');
    }

    return DeliveryStatus(messageId: messageId, status: 'unknown');
  }

  Future<DeliveryStatus> getSmsDeliveryStatus(String messageId) async {
    try {
      final response = await _dio.get(
        '$twilioBaseUrl/Accounts/$_twilioAccountSid/Messages/$messageId.json',
        options: Options(
          headers: {
            'Authorization': 'Basic ${base64Encode(utf8.encode('$_twilioAccountSid:$_twilioAuthToken'))}',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return DeliveryStatus(
          messageId: messageId,
          status: data['status'],
          deliveredAt: data['date_sent'] != null ? DateTime.parse(data['date_sent']) : null,
        );
      }
    } catch (e) {
      developer.log('Error getting SMS delivery status: $e');
    }

    return DeliveryStatus(messageId: messageId, status: 'unknown');
  }

  bool _hasValidCredentials() {
    return _sendGridApiKey.isNotEmpty || 
           (_twilioAccountSid.isNotEmpty && _twilioAuthToken.isNotEmpty);
  }

  // Mock fallback methods for when APIs are not configured
  Future<SmsResult> _sendMockSms(String to, String message) async {
    await Future.delayed(const Duration(milliseconds: 100));
    developer.log('Mock: SMS sent to $to: $message');
    return SmsResult(success: true, messageId: 'mock-${DateTime.now().millisecondsSinceEpoch}');
  }
}

// Data models
class EmailTemplate {
  final String id;
  final String subject;
  final String htmlContent;
  final String textContent;

  EmailTemplate({
    required this.id,
    required this.subject,
    required this.htmlContent,
    required this.textContent,
  });
}

class SmsTemplate {
  final String id;
  final String content;

  SmsTemplate({
    required this.id,
    required this.content,
  });
}

class EmailResult {
  final bool success;
  final String? messageId;
  final String? error;

  EmailResult({
    required this.success,
    this.messageId,
    this.error,
  });
}

class SmsResult {
  final bool success;
  final String? messageId;
  final String? error;

  SmsResult({
    required this.success,
    this.messageId,
    this.error,
  });
}

class BulkEmailRequest {
  final String to;
  final EmailTemplate template;
  final Map<String, dynamic> variables;
  final String? fromEmail;
  final String? fromName;

  BulkEmailRequest({
    required this.to,
    required this.template,
    required this.variables,
    this.fromEmail,
    this.fromName,
  });
}

class BulkSmsRequest {
  final String to;
  final SmsTemplate template;
  final Map<String, dynamic> variables;

  BulkSmsRequest({
    required this.to,
    required this.template,
    required this.variables,
  });
}

class DeliveryStatus {
  final String messageId;
  final String status;
  final DateTime? deliveredAt;
  final DateTime? openedAt;
  final DateTime? clickedAt;

  DeliveryStatus({
    required this.messageId,
    required this.status,
    this.deliveredAt,
    this.openedAt,
    this.clickedAt,
  });
}
