import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:clean_flutter/locator.dart';
import 'auth_service.dart';

class EmailOtpService {
  final DotEnv _dotenv;
  EmailOtpService({required DotEnv dotenv}) : _dotenv = dotenv;

  // Simple in-memory store for OTPs. Replace with backend/DB in production.
  final Map<String, _OtpEntry> _store = {};
  // Rate limiting state (in-memory)
  final Map<String, DateTime> _lastSend = {};
  final Map<String, int> _windowCount = {}; // per email count
  final Map<String, DateTime> _windowStart = {};

  static const Duration _minResendInterval = Duration(seconds: 60);
  static const Duration _window = Duration(hours: 1);
  static const int _maxPerWindow = 5;

  String _generateOtp({int length = 6}) {
    final rand = Random.secure();
    final code = List.generate(length, (_) => rand.nextInt(10)).join();
    return code;
  }

  void _recordSend(String email) {
    _lastSend[email] = DateTime.now();
    _windowCount[email] = (_windowCount[email] ?? 0) + 1;
  }

  int getResendRemainingSeconds(String email) {
    email = email.toLowerCase();
    final last = _lastSend[email];
    if (last == null) return 0;
    final diff = DateTime.now().difference(last);
    if (diff >= _minResendInterval) return 0;
    return _minResendInterval.inSeconds - diff.inSeconds;
  }

  Future<String> testSmtp(String toEmail) async {
    final username = _dotenv.env['SMTP_USERNAME'];
    final password = _dotenv.env['SMTP_PASSWORD'];
    final fromEmail = _dotenv.env['OTP_FROM_EMAIL'] ?? username;
    final fromName = _dotenv.env['OTP_FROM_NAME'] ?? 'Your App';
    if (username == null || password == null) {
      throw StateError('SMTP_USERNAME/SMTP_PASSWORD missing in .env');
    }
    if (fromEmail == null) {
      throw StateError('OTP_FROM_EMAIL or SMTP_USERNAME must be set in .env');
    }
    final server = gmail(username, password);
    final message = Message()
      ..from = Address(fromEmail, fromName)
      ..recipients.add(toEmail)
      ..subject = 'SMTP test from $fromName'
      ..text = 'This is a test email.'
      ..html = '<p>This is a <b>test</b> email from $fromName.</p>';
    final report = await send(message, server);
    return report.toString();
  }

  String _buildOtpHtml({required String otp, required String securityKey, required String appName}) {
    return '''
<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Security Verification</title>
  </head>
  <body style="margin:0; padding:0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh;">
    <div style="padding: 40px 20px;">
      <div style="max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 16px; box-shadow: 0 20px 40px rgba(0,0,0,0.1); overflow: hidden;">
        
        <!-- Header -->
        <div style="background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%); padding: 40px 30px; text-align: center;">
          <div style="width: 80px; height: 80px; background: rgba(255,255,255,0.2); border-radius: 50%; margin: 0 auto 20px; display: flex; align-items: center; justify-content: center; backdrop-filter: blur(10px);">
            <div style="width: 40px; height: 40px; background: #ffffff; border-radius: 50%; position: relative;">
              <div style="position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); width: 20px; height: 20px; background: #1e3c72; border-radius: 50%;"></div>
            </div>
          </div>
          <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: 700; text-shadow: 0 2px 4px rgba(0,0,0,0.1);">$appName</h1>
          <p style="color: rgba(255,255,255,0.9); margin: 8px 0 0; font-size: 16px;">Security Verification Required</p>
        </div>
        
        <!-- Content -->
        <div style="padding: 40px 30px;">
          <div style="text-align: center; margin-bottom: 40px;">
            <h2 style="color: #2d3748; margin: 0 0 16px; font-size: 24px; font-weight: 600;">Verification Code</h2>
            <p style="color: #718096; margin: 0; font-size: 16px; line-height: 1.5;">Enter this code in your app to complete the verification process</p>
          </div>
          
          <!-- OTP Code -->
          <div style="background: linear-gradient(135deg, #f7fafc 0%, #edf2f7 100%); border: 2px solid #e2e8f0; border-radius: 12px; padding: 30px; text-align: center; margin-bottom: 30px;">
            <div style="font-size: 48px; font-weight: 800; color: #1e3c72; letter-spacing: 8px; font-family: 'Courier New', monospace; text-shadow: 0 2px 4px rgba(0,0,0,0.1);">$otp</div>
          </div>
          
          <!-- Security Key Section -->
          <div style="background: #fff5f5; border: 1px solid #fed7d7; border-radius: 12px; padding: 24px; margin-bottom: 30px;">
            <div style="display: flex; align-items: center; margin-bottom: 12px;">
              <div style="width: 24px; height: 24px; background: #e53e3e; border-radius: 50%; margin-right: 12px; display: flex; align-items: center; justify-content: center;">
                <div style="width: 12px; height: 12px; background: #ffffff; border-radius: 2px;"></div>
              </div>
              <h3 style="color: #c53030; margin: 0; font-size: 18px; font-weight: 600;">Security Key Verification</h3>
            </div>
            <div style="background: #ffffff; border: 1px solid #fed7d7; border-radius: 8px; padding: 16px; margin-bottom: 12px;">
              <div style="font-size: 24px; font-weight: 700; color: #c53030; letter-spacing: 3px; font-family: 'Courier New', monospace; text-align: center;">$securityKey</div>
            </div>
            <p style="color: #742a2a; margin: 0; font-size: 14px; line-height: 1.4;"><strong>Important:</strong> Verify this security key matches exactly in your app. This prevents phishing attacks and ensures you're communicating with the authentic $appName service.</p>
          </div>
          
          <!-- Warning Box -->
          <div style="background: #fffbeb; border: 1px solid #fbd38d; border-radius: 12px; padding: 20px; margin-bottom: 30px;">
            <div style="display: flex; align-items: flex-start;">
              <div style="width: 20px; height: 20px; background: #ed8936; border-radius: 50%; margin-right: 12px; margin-top: 2px; flex-shrink: 0; display: flex; align-items: center; justify-content: center;">
                <div style="width: 2px; height: 8px; background: #ffffff; border-radius: 1px;"></div>
              </div>
              <div>
                <h4 style="color: #c05621; margin: 0 0 8px; font-size: 16px; font-weight: 600;">Security Notice</h4>
                <ul style="color: #9c4221; margin: 0; padding-left: 16px; font-size: 14px; line-height: 1.4;">
                  <li>This code expires in <strong>5 minutes</strong></li>
                  <li>Never share this code with anyone</li>
                  <li>$appName will never ask for this code via phone or email</li>
                  <li>If you didn't request this code, ignore this email</li>
                </ul>
              </div>
            </div>
          </div>
          
          <!-- Footer -->
          <div style="text-align: center; padding-top: 20px; border-top: 1px solid #e2e8f0;">
            <p style="color: #a0aec0; margin: 0; font-size: 14px;">This is an automated message from $appName Security System</p>
            <p style="color: #a0aec0; margin: 8px 0 0; font-size: 12px;">© ${DateTime.now().year} $appName. All rights reserved.</p>
          </div>
        </div>
      </div>
    </div>
  </body>
</html>
''';
  }

  Future<String> sendOtp(String email) async {
    email = email.toLowerCase();
    // Resend cooldown
    final now = DateTime.now();
    final last = _lastSend[email];
    if (last != null) {
      final diff = now.difference(last);
      if (diff < _minResendInterval) {
        final remaining = _minResendInterval.inSeconds - diff.inSeconds;
        throw Exception('Please wait ${remaining}s before requesting another code.');
      }
    }
    // Hourly cap
    final ws = _windowStart[email];
    if (ws == null || now.difference(ws) >= _window) {
      _windowStart[email] = now;
      _windowCount[email] = 0;
    }
    if ((_windowCount[email] ?? 0) >= _maxPerWindow) {
      throw Exception('Too many requests. Try again later.');
    }
    final otp = _generateOtp();
    // In a real app, you would save this OTP with an expiry time.
    // For now, we'll just send it.
    final expiresAt = DateTime.now().add(const Duration(minutes: 5));
    _store[email] = _OtpEntry(code: otp, expiresAt: expiresAt);

    // Fetch per-email security key
    final securityKey = locator<AuthService>().getSecurityKey(email);

    // Delivery mode: 'email' (default) or 'console' for local testing
    final delivery = (_dotenv.env['OTP_DELIVERY'] ?? 'email').toLowerCase();
    if (delivery == 'console') {
      debugPrint('[OTP] Email: $email, Code: $otp, SecurityKey: $securityKey');
      return otp;
    }

    final username = _dotenv.env['SMTP_USERNAME'];
    final password = _dotenv.env['SMTP_PASSWORD'];
    final fromEmail = _dotenv.env['OTP_FROM_EMAIL'] ?? username;
    final fromName = _dotenv.env['OTP_FROM_NAME'] ?? 'Security Center';

    debugPrint('--- SMTP CONFIG ---');
    debugPrint('USERNAME: $username');
    debugPrint('PASSWORD: ${password != null ? "(set)" : "(not set)"}');
    debugPrint('FROM_EMAIL: $fromEmail');
    debugPrint('FROM_NAME: $fromName');
    debugPrint('-------------------');

    if (username == null || password == null) {
      throw StateError('SMTP_USERNAME/SMTP_PASSWORD missing in .env');
    }

    if (fromEmail == null) {
      throw StateError('OTP_FROM_EMAIL or SMTP_USERNAME must be set in .env');
    }

    final server = gmail(username, password);

    final message = Message()
      ..from = Address(fromEmail, fromName)
      ..recipients.add(email)
      ..subject = 'Your OTP Code • Security Key: $securityKey'
      ..text = 'Your verification code is: $otp\nSecurity Key: $securityKey\nIt expires in 5 minutes.'
      ..html = _buildOtpHtml(otp: otp, securityKey: securityKey, appName: fromName);

    try {
      final sendReport = await send(message, server);
      debugPrint('Message sent: ${sendReport.toString()}');
      _recordSend(email);
      return otp;
    } on MailerException catch (e) {
      // Optional auto-fallback to console for local dev
      final fallback = (_dotenv.env['OTP_FALLBACK_CONSOLE_ON_ERROR'] ?? 'false').toLowerCase() == 'true';
      if (fallback) {
        debugPrint('[OTP:FALLBACK] Email delivery failed, printing code. Email: $email, Code: $otp');
        _recordSend(email);
        return otp;
      }
      // Build detailed error message
      final details = e.problems.map((p) => '[code=${p.code}] ${p.msg}').join('; ');
      throw Exception('OTP email send failed: $details');
    }
  }

  bool verifyOtp(String email, String code) {
    final e = email.toLowerCase();
    final entry = _store[e];
    if (entry == null) return false;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _store.remove(e);
      return false;
    }
    final ok = entry.code == code.trim();
    if (ok) {
      _store.remove(e);
    }
    return ok;
  }
}

class _OtpEntry {
  final String code;
  final DateTime expiresAt;
  _OtpEntry({required this.code, required this.expiresAt});
}
