import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../locator.dart';
import 'services/email_settings_service.dart';
import 'services/logging_service.dart';
import 'services/summary_email_scheduler.dart';

class SummaryEmailsPage extends StatefulWidget {
  const SummaryEmailsPage({super.key});

  @override
  State<SummaryEmailsPage> createState() => _SummaryEmailsPageState();
}

class _SummaryEmailsPageState extends State<SummaryEmailsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _toCtrl;
  late final TextEditingController _ccCtrl;
  late final TextEditingController _bccCtrl;
  late final TextEditingController _fromNameCtrl;
  late final TextEditingController _fromEmailCtrl;
  late final TextEditingController _subjectCtrl;

  @override
  void initState() {
    super.initState();
    final s = locator<EmailSettingsService>();
    _toCtrl = TextEditingController(text: s.to);
    _ccCtrl = TextEditingController(text: s.cc);
    _bccCtrl = TextEditingController(text: s.bcc);
    _fromNameCtrl = TextEditingController(text: s.fromName);
    _fromEmailCtrl = TextEditingController(text: s.fromEmail);
    _subjectCtrl = TextEditingController(text: s.subjectPrefix);
  }

  Future<void> _showHtmlPreview(EmailSettingsService settings) async {
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
    final scheduler = locator<SummaryEmailScheduler>();
    final subjectPrefix = settings.subjectPrefix.isNotEmpty ? settings.subjectPrefix : 'Security Summary';
    final html = scheduler.generateHtmlPreview(since: since, now: now, subjectPrefix: subjectPrefix);
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Summary Preview (HTML)'),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(child: Html(data: html)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _toCtrl.dispose();
    _ccCtrl.dispose();
    _bccCtrl.dispose();
    _fromNameCtrl.dispose();
    _fromEmailCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  bool _isValidEmail(String e) {
    final r = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return r.hasMatch(e);
  }

  String? _validateEmails(String? v) {
    final raw = v?.trim() ?? '';
    if (raw.isEmpty) return null; // optional
    final parts = raw.split(RegExp(r'[;,]')).map((e) => e.trim()).where((e) => e.isNotEmpty);
    for (final p in parts) {
      if (!_isValidEmail(p)) return 'Invalid email: $p';
    }
    return null;
  }

  Future<void> _showPlainPreview(EmailSettingsService settings) async {
    final logs = locator<LoggingService>();
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
    bool within(DateTime t) => t.isAfter(since);
    final failed = logs.failedAttempts.where((e) => within(e.timestamp)).length;
    final logins = logs.successfulLogins.where((e) => within(e.timestamp)).length;
    final signups = logs.signUps.where((e) => within(e.timestamp)).length;
    final mfas = logs.mfaUsed.where((e) => within(e.timestamp)).length;
    final adminActs = logs.adminActions.where((e) => within(e.timestamp)).length;

    final content = 'Window: ${DateFormat.yMMMd().add_jm().format(since)} → ${DateFormat.yMMMd().add_jm().format(now)}\n'
        'Failed attempts: $failed\n'
        'Successful logins: $logins\n'
        'Signups: $signups\n'
        'MFA used: $mfas\n'
        'Admin actions: $adminActs';

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Summary Preview'),
        content: SingleChildScrollView(child: SelectableText(content)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChangeNotifierProvider.value(
      value: locator<EmailSettingsService>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Summary Emails'),
        ),
        body: SafeArea(
          child: Consumer<EmailSettingsService>(
            builder: (context, settingsService, child) {
              return Form(
                key: _formKey,
                child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Email Notifications',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage periodic security summaries sent to your email.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      title: const Text('Enable Summary Emails'),
                      subtitle: const Text('Receive periodic security summaries.'),
                      value: settingsService.isEnabled,
                      onChanged: (bool value) {
                        settingsService.setEnabled(value);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      enabled: settingsService.isEnabled,
                      title: const Text('Frequency'),
                      trailing: DropdownButton<EmailFrequency>(
                        value: settingsService.frequency,
                        onChanged: settingsService.isEnabled
                            ? (EmailFrequency? newValue) {
                                if (newValue != null) {
                                  settingsService.setFrequency(newValue);
                                }
                              }
                            : null,
                        items: EmailFrequency.values.map<DropdownMenuItem<EmailFrequency>>((EmailFrequency value) {
                          return DropdownMenuItem<EmailFrequency>(
                            value: value,
                            child: Text(value.toString().split('.').last.capitalize()),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      enabled: settingsService.isEnabled,
                      title: const Text('Send Time'),
                      subtitle: Text('Preferred time of day to send (device local time).'),
                      trailing: TextButton.icon(
                        onPressed: settingsService.isEnabled
                            ? () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay(hour: settingsService.sendHour, minute: settingsService.sendMinute),
                                );
                                if (picked != null) {
                                  await settingsService.setSendTime(hour: picked.hour, minute: picked.minute);
                                }
                              }
                            : null,
                        icon: const Icon(Icons.access_time),
                        label: Text(_fmtTime(settingsService.sendHour, settingsService.sendMinute)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Next scheduled send', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            settingsService.isEnabled
                                ? DateFormat.yMMMEd().add_jm().format(settingsService.nextScheduledDateTime())
                                : 'Disabled',
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          if (settingsService.isEnabled)
                            _CountdownText(service: settingsService),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Recipients & Branding', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 12),
                          TextFormField(
                            enabled: settingsService.isEnabled,
                            controller: _toCtrl,
                            decoration: const InputDecoration(
                              labelText: 'To',
                              hintText: 'email1@domain.com, email2@domain.com',
                              helperText: 'Comma or semicolon separated list of primary recipients.'
                            ),
                            validator: _validateEmails,
                            onChanged: (v) => settingsService.setTo(v),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            enabled: settingsService.isEnabled,
                            controller: _ccCtrl,
                            decoration: const InputDecoration(
                              labelText: 'CC (optional)',
                              hintText: 'name@domain.com; another@domain.com',
                            ),
                            validator: _validateEmails,
                            onChanged: (v) => settingsService.setCc(v),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            enabled: settingsService.isEnabled,
                            controller: _bccCtrl,
                            decoration: const InputDecoration(
                              labelText: 'BCC (optional)',
                              hintText: 'name@domain.com, another@domain.com',
                            ),
                            validator: _validateEmails,
                            onChanged: (v) => settingsService.setBcc(v),
                          ),
                          const Divider(height: 24),
                          TextFormField(
                            enabled: settingsService.isEnabled,
                            controller: _fromNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'From name',
                              hintText: 'Security Center',
                            ),
                            onChanged: (v) => settingsService.setFromName(v),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            enabled: settingsService.isEnabled,
                            controller: _fromEmailCtrl,
                            decoration: const InputDecoration(
                              labelText: 'From email',
                              hintText: 'no-reply@domain.com',
                              helperText: 'If empty, falls back to SMTP_FROM or SMTP_USERNAME from .env'
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              final t = v?.trim() ?? '';
                              if (t.isEmpty) return null;
                              return _isValidEmail(t) ? null : 'Invalid email';
                            },
                            onChanged: (v) => settingsService.setFromEmail(v),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            enabled: settingsService.isEnabled,
                            controller: _subjectCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Subject prefix',
                              hintText: 'Security Summary',
                              helperText: 'If empty, uses SUMMARY_SUBJECT_PREFIX from .env'
                            ),
                            onChanged: (v) => settingsService.setSubjectPrefix(v),
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Attach CSV of logs'),
                            subtitle: const Text('Attach a CSV export for the reporting window.'),
                            value: settingsService.attachCsv,
                            onChanged: settingsService.isEnabled ? (v) => settingsService.setAttachCsv(v) : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Note: SMTP host/port/username/password are taken from .env. Empty fields fall back to .env.',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {
                                    if (_formKey.currentState?.validate() ?? false) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recipient settings look good.')));
                                    }
                                  },
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Validate'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: settingsService.isEnabled ? () => _showPlainPreview(settingsService) : null,
                                  icon: const Icon(Icons.visibility_outlined),
                                  label: const Text('Preview summary (plain)'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: settingsService.isEnabled ? () => _showHtmlPreview(settingsService) : null,
                                  icon: const Icon(Icons.web_asset),
                                  label: const Text('Preview summary (HTML)'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: settingsService.isEnabled
                                      ? () async {
                                          if (!(_formKey.currentState?.validate() ?? false)) return;
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sending test email...')));
                                          try {
                                            await locator<SummaryEmailScheduler>().sendNow(markSent: false);
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test email sent.')));
                                          } catch (e) {
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Test failed: $e')));
                                          }
                                        }
                                      : null,
                                  icon: const Icon(Icons.mark_email_read_outlined),
                                  label: const Text('Send test email'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              );
            },
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

String _fmtTime(int h, int m) {
  final t = TimeOfDay(hour: h, minute: m);
  final now = DateTime.now();
  final dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
  return DateFormat.jm().format(dt);
}

class _CountdownText extends StatefulWidget {
  final EmailSettingsService service;
  const _CountdownText({required this.service});

  @override
  State<_CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<_CountdownText> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      _remaining = widget.service.timeRemaining();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(_remaining.inHours);
    final m = two(_remaining.inMinutes.remainder(60));
    final s = two(_remaining.inSeconds.remainder(60));
    return Text('Time remaining: $h:$m:$s', style: Theme.of(context).textTheme.bodyMedium);
  }
}
