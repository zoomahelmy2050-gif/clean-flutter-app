import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import '../../locator.dart';
import 'services/logging_service.dart';
import 'package:clean_flutter/features/auth/services/auth_service.dart';
import 'package:flutter/services.dart';
import '../../generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:clean_flutter/core/services/language_service.dart';

// Represents the type of log entry
enum LogType {
  failed, logins, signups, summaries, mfaOtp, mfaTotp, mfaBio
}

class ViewLogsPage extends StatefulWidget {
  const ViewLogsPage({super.key});

  @override
  State<ViewLogsPage> createState() => _ViewLogsPageState();
}

class _ViewLogsPageState extends State<ViewLogsPage> {
  final _searchController = TextEditingController();
  DateTime? _from;
  DateTime? _to;
  Set<LogType> _selectedLogTypes = {LogType.failed, LogType.logins, LogType.signups};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filters a list of logs based on search text, date range, and selected log types
  List<LogEntry> _filterAndCombineLogs() {
    final loggingService = locator<LoggingService>();
    final q = _searchController.text.trim().toLowerCase();

    List<LogEntry> allLogs = [];

    if (_selectedLogTypes.contains(LogType.failed)) {
      allLogs.addAll(loggingService.failedAttempts.map((e) => LogEntry.fromFailedAttempt(e, LogType.failed)));
    }
    if (_selectedLogTypes.contains(LogType.logins)) {
      allLogs.addAll(loggingService.successfulLogins.map((e) => LogEntry.fromFailedAttempt(e, LogType.logins)));
    }
    if (_selectedLogTypes.contains(LogType.signups)) {
      allLogs.addAll(loggingService.signUps.map((e) => LogEntry.fromFailedAttempt(e, LogType.signups)));
    }
    if (_selectedLogTypes.contains(LogType.summaries)) {
      allLogs.addAll(loggingService.summariesSent.map((e) => LogEntry.fromFailedAttempt(e, LogType.summaries)));
    }
    if (_selectedLogTypes.contains(LogType.mfaOtp)) {
      allLogs.addAll(loggingService.mfaOtp.map((e) => LogEntry.fromFailedAttempt(e, LogType.mfaOtp)));
    }
    if (_selectedLogTypes.contains(LogType.mfaTotp)) {
      allLogs.addAll(loggingService.mfaTotp.map((e) => LogEntry.fromFailedAttempt(e, LogType.mfaTotp)));
    }
    if (_selectedLogTypes.contains(LogType.mfaBio)) {
      allLogs.addAll(loggingService.mfaBiometric.map((e) => LogEntry.fromFailedAttempt(e, LogType.mfaBio)));
    }

    final filtered = allLogs.where((e) {
      final inText = q.isEmpty ||
          e.username.toLowerCase().contains(q) ||
          (e.device ?? '').toLowerCase().contains(q) ||
          (e.ip ?? '').toLowerCase().contains(q);
      final afterFrom = _from == null || !e.timestamp.isBefore(_from!);
      final beforeTo = _to == null || !e.timestamp.isAfter(_to!);
      return inText && afterFrom && beforeTo;
    }).toList();

    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered;
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialFirst = _from ?? now.subtract(const Duration(days: 7));
    final initialLast = _to ?? now;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDateRange: DateTimeRange(start: initialFirst, end: initialLast),
    );
    if (picked != null) {
      setState(() {
        _from = DateTime(picked.start.year, picked.start.month, picked.start.day);
        _to = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
    }
  }

  Future<void> _exportCsv(List<LogEntry> logs) async {
    try {
      final fmt = DateFormat('yyyy-MM-ddTHH:mm:ss');
      final csv = StringBuffer('type,username,timestamp,device,ip\n');
      for (final e in logs) {
        csv.writeln('"${e.type.name}","${e.username}","${fmt.format(e.timestamp)}","${(e.device ?? '').replaceAll('"', "''")}","${e.ip ?? ''}"');
      }
      final dir = await getTemporaryDirectory();
      final fileName = 'security_logs_${DateTime.now().millisecondsSinceEpoch}.csv';
      final f = File('${dir.path}/$fileName');
      await f.writeAsString(csv.toString());

      final params = SaveFileDialogParams(sourceFilePath: f.path, fileName: fileName);
      await FlutterFileDialog.saveFile(params: params);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV exported')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _filterAndCombineLogs();

    return Scaffold(
      appBar: AppBar(
        title: Consumer<LanguageService>(
          builder: (context, languageService, child) {
            final l10n = AppLocalizations.of(context)!;
            return Text(l10n.viewLogs);
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Pick date range',
            icon: const Icon(Icons.date_range),
            onPressed: _pickDateRange,
          ),
          IconButton(
            tooltip: 'Clear filters',
            icon: const Icon(Icons.filter_alt_off),
            onPressed: () => setState(() { _from = null; _to = null; _searchController.clear(); _selectedLogTypes.clear(); }),
          ),
          IconButton(
            tooltip: 'Export CSV',
            icon: const Icon(Icons.download),
            onPressed: () => _exportCsv(filteredLogs),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Filter by user, device, or IP'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            _FilterChips(selectedLogTypes: _selectedLogTypes, onSelectionChanged: (selected) => setState(() => _selectedLogTypes = selected)),
            _SummaryStats(logs: filteredLogs),
            Expanded(
              child: filteredLogs.isEmpty
                  ? const Center(child: Text('No logs match the current filters.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        return LogEntryCard(log: filteredLogs[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final Set<LogType> selectedLogTypes;
  final ValueChanged<Set<LogType>> onSelectionChanged;

  const _FilterChips({required this.selectedLogTypes, required this.onSelectionChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: LogType.values.map((type) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: FilterChip(
                label: Text(type.name.replaceAll('_', ' ').toUpperCase()),
                selected: selectedLogTypes.contains(type),
                onSelected: (selected) {
                  final newSelection = Set<LogType>.from(selectedLogTypes);
                  if (selected) {
                    newSelection.add(type);
                  } else {
                    newSelection.remove(type);
                  }
                  onSelectionChanged(newSelection);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SummaryStats extends StatelessWidget {
  final List<LogEntry> logs;
  const _SummaryStats({required this.logs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counts = { for (var type in LogType.values) type: 0 };
    for (var log in logs) {
      counts[log.type] = (counts[log.type] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text('Total: ${logs.length}', style: theme.textTheme.titleMedium),
          Text('Failed: ${counts[LogType.failed]}', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red)),
          Text('Logins: ${counts[LogType.logins]}', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.green)),
          Text('Signups: ${counts[LogType.signups]}', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.blue)),
        ],
      ),
    );
  }
}

class LogEntryCard extends StatefulWidget {
  final LogEntry log;
  const LogEntryCard({super.key, required this.log});

  @override
  State<LogEntryCard> createState() => _LogEntryCardState();
}

class _LogEntryCardState extends State<LogEntryCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = locator<AuthService>();
    final blocked = auth.isUserBlocked(widget.log.username);
    final mfaOn = auth.isUserMfaEnabled(widget.log.username);

    final logMeta = _getLogMeta(widget.log.type, theme);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(logMeta.icon, color: logMeta.color, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(logMeta.titlePrefix + widget.log.username, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(DateFormat.yMd().add_jms().format(widget.log.timestamp), style: theme.textTheme.bodySmall),
                  const SizedBox(height: 2),
                  Text('Device: ${widget.log.device ?? '-'}  ·  IP: ${widget.log.ip ?? '-'}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (blocked) const Chip(label: Text('Blocked'), backgroundColor: Color(0xFFFFEBEE)),
                      if (!mfaOn) const Chip(label: Text('MFA off'), backgroundColor: Color(0xFFE0E0E0)),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                final logging = locator<LoggingService>();
                switch (value) {
                  case 'block':
                    await auth.blockUser(widget.log.username);
                    await logging.logAdminAction('block_user', widget.log.username);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Blocked ${widget.log.username}')));
                      setState(() {});
                    }
                    break;
                  case 'unblock':
                    await auth.unblockUser(widget.log.username);
                    await logging.logAdminAction('unblock_user', widget.log.username);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unblocked ${widget.log.username}')));
                      setState(() {});
                    }
                    break;
                  case 'disable_mfa':
                    await auth.setUserMfaEnabled(widget.log.username, false);
                    await logging.logAdminAction('disable_mfa', widget.log.username);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('MFA disabled for ${widget.log.username}')));
                      setState(() {});
                    }
                    break;
                  case 'enable_mfa':
                    await auth.setUserMfaEnabled(widget.log.username, true);
                    await logging.logAdminAction('enable_mfa', widget.log.username);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('MFA enabled for ${widget.log.username}')));
                      setState(() {});
                    }
                    break;
                  case 'copy_email':
                    await Clipboard.setData(ClipboardData(text: widget.log.username));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email copied')));
                    }
                    break;
                  case 'copy_ip':
                    if ((widget.log.ip ?? '').isNotEmpty) {
                      await Clipboard.setData(ClipboardData(text: widget.log.ip!));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('IP copied')));
                      }
                    }
                    break;
                }
              },
              itemBuilder: (ctx) => [
                if (!blocked) const PopupMenuItem(value: 'block', child: ListTile(leading: Icon(Icons.block), title: Text('Block user'))),
                if (blocked) const PopupMenuItem(value: 'unblock', child: ListTile(leading: Icon(Icons.lock_open), title: Text('Unblock user'))),
                if (mfaOn) const PopupMenuItem(value: 'disable_mfa', child: ListTile(leading: Icon(Icons.shield_outlined), title: Text('Disable MFA'))),
                if (!mfaOn) const PopupMenuItem(value: 'enable_mfa', child: ListTile(leading: Icon(Icons.shield), title: Text('Enable MFA'))),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'copy_email', child: ListTile(leading: Icon(Icons.copy), title: Text('Copy email'))),
                if ((widget.log.ip ?? '').isNotEmpty) const PopupMenuItem(value: 'copy_ip', child: ListTile(leading: Icon(Icons.copy_all), title: Text('Copy IP'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _LogMeta _getLogMeta(LogType type, ThemeData theme) {
    switch (type) {
      case LogType.failed: return _LogMeta(icon: Icons.warning_amber_rounded, color: theme.colorScheme.error, titlePrefix: 'Failed: ');
      case LogType.logins: return _LogMeta(icon: Icons.login, color: theme.colorScheme.primary, titlePrefix: 'Login: ');
      case LogType.signups: return _LogMeta(icon: Icons.person_add_alt, color: theme.colorScheme.secondary, titlePrefix: 'Signup: ');
      case LogType.summaries: return _LogMeta(icon: Icons.email_outlined, color: Colors.orange, titlePrefix: 'Summary to: ');
      case LogType.mfaOtp: return _LogMeta(icon: Icons.mark_email_read_outlined, color: Colors.blue, titlePrefix: 'MFA OTP: ');
      case LogType.mfaTotp: return _LogMeta(icon: Icons.key_outlined, color: Colors.purple, titlePrefix: 'MFA TOTP: ');
      case LogType.mfaBio: return _LogMeta(icon: Icons.fingerprint, color: Colors.teal, titlePrefix: 'MFA Biometric: ');
    }
  }
}

// A unified class to hold log data from different sources
class LogEntry {
  final String username;
  final DateTime timestamp;
  final String? device;
  final String? ip;
  final LogType type;

  LogEntry({required this.username, required this.timestamp, this.device, this.ip, required this.type});

  factory LogEntry.fromFailedAttempt(FailedAttempt attempt, LogType type) {
    return LogEntry(
      username: attempt.username,
      timestamp: attempt.timestamp,
      device: attempt.device,
      ip: attempt.ip,
      type: type,
    );
  }
}

class _LogMeta {
  final IconData icon;
  final Color color;
  final String titlePrefix;
  _LogMeta({required this.icon, required this.color, required this.titlePrefix});
}
