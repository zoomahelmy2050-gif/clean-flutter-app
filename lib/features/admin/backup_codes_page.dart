import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/services/backup_codes_service.dart';
import '../../features/auth/services/auth_service.dart';
import '../../locator.dart';
import '../../generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:clean_flutter/core/services/language_service.dart';

class BackupCodesPage extends StatefulWidget {
  const BackupCodesPage({super.key});

  @override
  State<BackupCodesPage> createState() => _BackupCodesPageState();
}

class _BackupCodesPageState extends State<BackupCodesPage> {
  late final BackupCodesService _backupCodesService;
  List<String> _backupCodes = [];
  Map<String, dynamic> _status = {};
  bool _isLoading = false;
  bool _showCodes = false;

  @override
  void initState() {
    super.initState();
    _backupCodesService = BackupCodesService(locator<AuthService>());
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoading = true);
    try {
      final status = await _backupCodesService.getBackupCodesStatus();
      setState(() => _status = status);
    } catch (e) {
      _showError('Failed to load backup codes status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateBackupCodes() async {
    final confirmed = await _showConfirmDialog(
      'Generate Backup Codes',
      'This will generate new backup codes and invalidate any existing ones. Continue?',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);
    try {
      final codes = await _backupCodesService.generateBackupCodes();
      setState(() {
        _backupCodes = codes;
        _showCodes = true;
      });
      await _loadStatus();
      _showSuccess('Backup codes generated successfully!');
    } catch (e) {
      _showError('Failed to generate backup codes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _regenerateBackupCodes() async {
    final confirmed = await _showConfirmDialog(
      'Regenerate Backup Codes',
      'This will create new backup codes and invalidate all existing ones. Any unused codes will no longer work. Continue?',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);
    try {
      final codes = await _backupCodesService.regenerateBackupCodes();
      setState(() {
        _backupCodes = codes;
        _showCodes = true;
      });
      await _loadStatus();
      _showSuccess('Backup codes regenerated successfully!');
    } catch (e) {
      _showError('Failed to regenerate backup codes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBackupCodes() async {
    final confirmed = await _showConfirmDialog(
      'Delete Backup Codes',
      'This will permanently delete all backup codes. You will not be able to recover your account using backup codes. Continue?',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);
    try {
      await _backupCodesService.deleteBackupCodes();
      setState(() {
        _backupCodes = [];
        _showCodes = false;
      });
      await _loadStatus();
      _showSuccess('Backup codes deleted successfully!');
    } catch (e) {
      _showError('Failed to delete backup codes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyAllCodes() {
    final codesText = _backupCodes.join('\n');
    Clipboard.setData(ClipboardData(text: codesText));
    _showSuccess('All backup codes copied to clipboard!');
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    _showSuccess('Code copied to clipboard!');
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _printCodes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Print Backup Codes'),
        content: SingleChildScrollView(
          child: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BACKUP CODES',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Generated: ${DateTime.now().toString().split(' ')[0]}',
                  style: const TextStyle(color: Colors.black, fontSize: 12),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Keep these codes safe. Each can only be used once.',
                  style: TextStyle(color: Colors.black, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ..._backupCodes.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          '${entry.key + 1}.',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          entry.value,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadCodes() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/backup_codes_${DateTime.now().millisecondsSinceEpoch}.txt',
      );

      final content = StringBuffer();
      content.writeln('BACKUP CODES');
      content.writeln('Generated: ${DateTime.now()}');
      content.writeln('');
      content.writeln('Keep these codes safe. Each can only be used once.');
      content.writeln('');

      for (int i = 0; i < _backupCodes.length; i++) {
        content.writeln('${i + 1}. ${_backupCodes[i]}');
      }

      await file.writeAsString(content.toString());

      if (mounted) {
        _showSuccess('Backup codes saved to: ${file.path}');
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to download backup codes: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<LanguageService>(
          builder: (context, languageService, child) {
            final l10n = AppLocalizations.of(context)!;
            return Text(l10n.backupCodes);
          },
        ),
        actions: [
          if (_backupCodes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _downloadCodes,
              tooltip: 'Download Codes',
            ),
        ],
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
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildActionsCard(),
                  if (_showCodes && _backupCodes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildCodesCard(),
                  ],
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
                  'About Backup Codes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Backup codes are one-time use recovery codes that allow you to access your account if you lose access to your authenticator app. Each code can only be used once.',
            ),
            const SizedBox(height: 8),
            const Text(
              '• Store these codes in a safe place\n'
              '• Each code can only be used once\n'
              '• Generate new codes if you run out\n'
              '• Keep them separate from your device',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final hasBackupCodes = _status['hasBackupCodes'] ?? false;
    final remaining = _status['remaining'] ?? 0;
    final total = _status['total'] ?? 0;
    final used = _status['used'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasBackupCodes ? Icons.check_circle : Icons.warning,
                  color: hasBackupCodes ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Backup Codes Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasBackupCodes) ...[
              Text('Total codes: $total'),
              Text('Used codes: $used'),
              Text('Remaining codes: $remaining'),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: total > 0 ? (total - remaining) / total : 0,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  remaining > 3 ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                remaining <= 3 ? 'Consider generating new codes' : 'Good',
                style: TextStyle(
                  color: remaining <= 3 ? Colors.orange : Colors.green,
                  fontSize: 12,
                ),
              ),
            ] else ...[
              const Text('No backup codes generated'),
              const SizedBox(height: 4),
              const Text(
                'Generate backup codes to secure your account',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    final hasBackupCodes = _status['hasBackupCodes'] ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (!hasBackupCodes) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generateBackupCodes,
                  icon: const Icon(Icons.add),
                  label: const Text('Generate Backup Codes'),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _regenerateBackupCodes,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Regenerate Codes'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _deleteBackupCodes,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    'Delete All Codes',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCodesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Backup Codes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _copyAllCodes,
                      icon: const Icon(Icons.copy_all, size: 16),
                      label: const Text('Copy All'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _printCodes,
                      icon: const Icon(Icons.print, size: 16),
                      label: const Text('Print'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _downloadCodes,
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Download'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                ),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Save these codes in a secure location. Each can only be used once.',
                          style: TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_backupCodes.length, (index) {
                    final code = _backupCodes[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                code,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _copyCode(code),
                            icon: const Icon(Icons.copy, size: 16),
                            tooltip: 'Copy code',
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
