import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import '../services/backup_code_service.dart';

class BackupCodesPage extends StatefulWidget {
  const BackupCodesPage({super.key});
  static const routeName = '/backup-codes';

  @override
  State<BackupCodesPage> createState() => _BackupCodesPageState();
}

class _BackupCodesPageState extends State<BackupCodesPage> {
  final _backupCodeService = BackupCodeService();
  List<String> _codes = [];
  bool _isLoading = true;
  bool _hidden = false;
  int _remaining = 0;

  @override
  void initState() {
    super.initState();
    _generateCodes();
  }

  Future<void> _generateCodes() async {
    setState(() => _isLoading = true);
    final newCodes = await _backupCodeService.generateNewCodes();
    final remaining = await _backupCodeService.getUnusedCount();
    setState(() {
      _codes = newCodes;
      _remaining = remaining;
      _isLoading = false;
    });
  }

  Future<void> _downloadCodes() async {
    final pdfBytes = await _createPdf(_codes);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/backup-codes.pdf');
    await file.writeAsBytes(pdfBytes);

    if (!mounted) return;
    try {
      await FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(sourceFilePath: file.path),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Codes downloaded successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }

  Future<void> _printCodes() async {
    final pdfBytes = await _createPdf(_codes);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
  }

  Future<void> _exportTxt() async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/backup-codes.txt');
    await file.writeAsString(_codes.join('\n'));
    if (!mounted) return;
    try {
      await FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(sourceFilePath: file.path),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Codes exported as TXT.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _copyAll() async {
    await Clipboard.setData(ClipboardData(text: _codes.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All codes copied to clipboard')),
    );
  }

  Future<Uint8List> _createPdf(List<String> codes) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Backup Codes', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('These are single-use recovery codes. Save them in a secure place.'),
              pw.SizedBox(height: 20),
              pw.GridView(
                crossAxisCount: 2,
                childAspectRatio: 4,
                children: codes.map((code) => pw.Text(code, style: const pw.TextStyle(fontSize: 16))).toList(),
              ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Codes'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Text(
                    'Your Recovery Codes',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'These are single-use recovery codes. Save them in a secure place.',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: theme.colorScheme.tertiaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Store these codes in a safe place. You will need them to access your account if you lose your device.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onTertiaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _codes.length,
                    itemBuilder: (context, index) {
                      final code = _codes[index];
                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: theme.dividerColor),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  _hidden ? '••••-••••' : code,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyLarge?.copyWith(fontFamily: 'monospace'),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                splashRadius: 18,
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: code));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Code copied to clipboard')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Remaining: $_remaining / ${_codes.length}', style: theme.textTheme.bodyMedium),
                      TextButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Regenerate'),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Regenerate codes?'),
                              content: const Text('This will invalidate all existing backup codes and create new ones.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Regenerate')),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await _generateCodes();
                          }
                        },
                        style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.print_outlined),
                          label: const Text('Print PDF'),
                          onPressed: _printCodes,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('Download PDF'),
                          onPressed: _downloadCodes,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.content_copy),
                          label: const Text('Copy all'),
                          onPressed: _copyAll,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.description_outlined),
                          label: const Text('Export .txt'),
                          onPressed: _exportTxt,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: Icon(_hidden ? Icons.visibility_off : Icons.visibility),
                      label: Text(_hidden ? 'Show codes' : 'Hide codes'),
                      onPressed: () => setState(() => _hidden = !_hidden),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
