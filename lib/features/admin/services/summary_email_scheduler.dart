import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:clean_flutter/locator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'email_settings_service.dart';
import 'logging_service.dart';

/// Simple in-app scheduler that checks every 30 seconds whether it's time
/// to send the configured security summary email. This is app-lifecycle bound
/// and not a true background service.
class SummaryEmailScheduler {
  Timer? _timer;
  bool _running = false;

  // The recipient of the summary emails. For now, target the admin mailbox.
  // You can make this configurable later if needed.
  static const String _adminRecipient = 'env.hygiene@gmail.com';

  void start() {
    if (_running) return;
    _running = true;
    // Immediate check, then periodic
    _checkAndSend();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _checkAndSend());
    debugPrint('SummaryEmailScheduler started.');
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
    debugPrint('SummaryEmailScheduler stopped.');
  }

  /// Manually trigger sending the summary email immediately.
  /// If [markSent] is true, updates the last-sent timestamp so the scheduler
  /// won't send again until the next window.
  Future<void> sendNow({bool markSent = true}) async {
    await _sendSummaryEmail();
    if (markSent) {
      await locator<EmailSettingsService>().markSent(when: DateTime.now());
    }
  }

  Future<void> _checkAndSend() async {
    final settings = locator<EmailSettingsService>();
    if (!settings.isEnabled) return;

    final now = DateTime.now();
    final next = settings.nextScheduledDateTime(from: now);

    // If now is before the next scheduled time, nothing to do
    if (now.isBefore(next)) return;

    // Avoid double-sending: ensure we haven't already sent for this window
    final last = settings.lastSentAt;
    if (last != null) {
      // If last send time is after the computed next time, we already sent
      if (!last.isBefore(next)) {
        return;
      }
    }

    await _sendSummaryEmail();
    await settings.markSent(when: now);
  }

  Future<void> _sendSummaryEmail() async {
    try {
      final settings = locator<EmailSettingsService>();
      final host = dotenv.env['SMTP_HOST'];
      final portStr = dotenv.env['SMTP_PORT'];
      final username = dotenv.env['SMTP_USERNAME'];
      final password = dotenv.env['SMTP_PASSWORD'];

      // Prefer UI-configured overrides, else fall back to env
      final fromAddr = (settings.fromEmail.isNotEmpty ? settings.fromEmail : (dotenv.env['SMTP_FROM'] ?? username));
      final fromName = (settings.fromName.isNotEmpty ? settings.fromName : (dotenv.env['SMTP_FROM_NAME'] ?? 'Security Center'));
      final subjectPrefix = (settings.subjectPrefix.isNotEmpty ? settings.subjectPrefix : (dotenv.env['SUMMARY_SUBJECT_PREFIX'] ?? 'Security Summary'));

      // Recipients (comma/semicolon separated)
      List<String> _split(String? raw) {
        if (raw == null) return [];
        return raw
            .split(RegExp(r'[;,]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      List<String> toList = settings.to.isNotEmpty ? _split(settings.to) : _split(dotenv.env['SMTP_TO']);
      if (toList.isEmpty) toList.add(_adminRecipient);
      final ccList = settings.cc.isNotEmpty ? _split(settings.cc) : _split(dotenv.env['SMTP_CC']);
      final bccList = settings.bcc.isNotEmpty ? _split(settings.bcc) : _split(dotenv.env['SMTP_BCC']);

      if (host == null || username == null || password == null) {
        // Missing config -> simulate (still mark as sent to avoid spamming logs)
        await locator<LoggingService>().logSummarySent(toList.first);
        debugPrint('Simulated sending summary email to ${toList.first} (SMTP env not set)');
        return;
      }

      final port = int.tryParse(portStr ?? '') ?? 587;
      final server = SmtpServer(host, port: port, username: username, password: password, ignoreBadCertificate: true);

      // Determine reporting window based on settings
      final now = DateTime.now();
      Duration window;
      switch (settings.frequency) {
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
      final since = settings.lastSentAt ?? now.subtract(window);

      final html = generateHtmlPreview(since: since, now: now, subjectPrefix: subjectPrefix);

      final message = Message()
        ..from = Address(fromAddr ?? username, fromName)
        ..recipients.addAll(toList)
        ..ccRecipients.addAll(ccList)
        ..bccRecipients.addAll(bccList)
        ..subject = '$subjectPrefix — ${DateTime.now().toLocal()}'
        ..html = html
        ..text = 'Open this email in an HTML-capable client to view the full summary.';

      // Optional CSV attachment
      if (settings.attachCsv) {
        final logs = locator<LoggingService>();
        final path = await logs.exportCsv(since: since);
        final file = File(path);
        if (await file.exists()) {
          message.attachments = [FileAttachment(file)..fileName = 'security_logs.csv'];
        }
      }

      await send(message, server);
      await locator<LoggingService>().logSummarySent(toList.join(','));
      debugPrint('Summary email sent to ${toList.join(', ')} via SMTP.');
    } catch (e) {
      // Fallback to logging only
      await locator<LoggingService>().logSummarySent(_adminRecipient);
      debugPrint('Failed to send real email, simulated instead. Error: $e');
    }
  }

  /// Build the same HTML used in the email for on-screen preview.
  String generateHtmlPreview({required DateTime since, required DateTime now, required String subjectPrefix}) {
    // Gather metrics
    final logs = locator<LoggingService>();
    bool within(DateTime t) => t.isAfter(since);
    final failed = logs.failedAttempts.where((e) => within(e.timestamp)).toList();
    final logins = logs.successfulLogins.where((e) => within(e.timestamp)).toList();
    final signups = logs.signUps.where((e) => within(e.timestamp)).toList();
    final mfas = logs.mfaUsed.where((e) => within(e.timestamp)).toList();
    final adminActs = logs.adminActions.where((e) => within(e.timestamp)).toList();

    String row(List<String> cols) => '<tr>${cols.map((c) => '<td style="padding:6px 8px;border-bottom:1px solid #eee;">'+c+'</td>').join()}</tr>';
    String fmt(DateTime d) => d.toLocal().toString();
    String section(String title, List<List<String>> rows) {
      if (rows.isEmpty) {
        return '<h3 style="margin:16px 0 8px 0;">$title</h3><p style="color:#666;">No records.</p>';
      }
      final header = '<tr><th align="left" style="padding:6px 8px;border-bottom:2px solid #333;">User</th><th align="left" style="padding:6px 8px;border-bottom:2px solid #333;">When</th><th align="left" style="padding:6px 8px;border-bottom:2px solid #333;">Device</th><th align="left" style="padding:6px 8px;border-bottom:2px solid #333;">IP</th></tr>';
      final body = rows.map(row).join();
      return '<h3 style="margin:16px 0 8px 0;">$title</h3><table width="100%" cellspacing="0" cellpadding="0" style="border-collapse:collapse;">$header$body</table>';
    }

    List<List<String>> mapLogs(List<FailedAttempt> xs) {
      final xsSorted = List<FailedAttempt>.from(xs)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return xsSorted
          .take(20)
          .map((e) => [e.username, fmt(e.timestamp), e.device ?? '-', e.ip ?? '-'])
          .toList();
    }

    final html = '''
<!doctype html>
<html>
  <body style="font-family:Arial,Helvetica,sans-serif;background:#f6f6f6;padding:24px;">
    <div style="max-width:760px;margin:auto;background:#ffffff;border-radius:10px;padding:24px;box-shadow:0 1px 4px rgba(0,0,0,0.08)">
      <h2 style="margin:0 0 16px 0;">$subjectPrefix</h2>
      <p style="margin:0 0 8px 0;color:#555;">Window: ${fmt(since)} → ${fmt(now)}</p>
      <div style="display:flex;gap:12px;flex-wrap:wrap;margin:16px 0;">
        <div style="flex:1;min-width:140px;background:#f0f7ff;padding:12px;border-radius:8px;">Failed attempts: <b>${failed.length}</b></div>
        <div style="flex:1;min-width:140px;background:#f3fff0;padding:12px;border-radius:8px;">Successful logins: <b>${logins.length}</b></div>
        <div style="flex:1;min-width:140px;background:#fff8f0;padding:12px;border-radius:8px;">Signups: <b>${signups.length}</b></div>
        <div style="flex:1;min-width:140px;background:#f0fffb;padding:12px;border-radius:8px;">MFA used: <b>${mfas.length}</b></div>
        <div style="flex:1;min-width:140px;background:#f7f0ff;padding:12px;border-radius:8px;">Admin actions: <b>${adminActs.length}</b></div>
      </div>
      ${section('Recent failed attempts', mapLogs(failed))}
      ${section('Recent successful logins', mapLogs(logins))}
      ${section('Recent signups', mapLogs(signups))}
      ${section('Recent MFA usage', mapLogs(mfas))}
      ${section('Recent admin actions', mapLogs(adminActs))}
      <p style="color:#888;margin-top:24px;font-size:12px;">Generated at ${fmt(now)}</p>
    </div>
  </body>
</html>
''';
    return html;
  }
}
