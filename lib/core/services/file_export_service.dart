import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:cross_file/cross_file.dart';

class FileExportService {
  static const String _exportFolder = 'exports';

  Future<String> get _exportPath async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${directory.path}/$_exportFolder');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir.path;
  }

  Future<bool> exportVulnerabilityData(Map<String, dynamic> vulnerabilityData) async {
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'vulnerability_report_$timestamp';
      
      // Export as JSON
      await _exportAsJson(vulnerabilityData, '${fileName}.json');
      
      // Export as CSV
      await _exportVulnerabilitiesAsCsv(vulnerabilityData, '${fileName}.csv');
      
      // Export as PDF report
      await _exportAsPdfReport(vulnerabilityData, '${fileName}.pdf');
      
      return true;
    } catch (e) {
      debugPrint('Export failed: $e');
      return false;
    }
  }

  Future<void> _exportAsJson(Map<String, dynamic> data, String fileName) async {
    final path = await _exportPath;
    final file = File('$path/$fileName');
    
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    await file.writeAsString(jsonString);
  }

  Future<void> _exportVulnerabilitiesAsCsv(Map<String, dynamic> data, String fileName) async {
    final path = await _exportPath;
    final file = File('$path/$fileName');
    
    final vulnerabilities = data['vulnerabilities'] as List<dynamic>? ?? [];
    
    final csvData = [
      ['ID', 'Title', 'Severity', 'CVSS Score', 'Status', 'Found Date', 'Description'],
      ...vulnerabilities.map((vuln) => [
        vuln['id'] ?? '',
        vuln['title'] ?? '',
        vuln['severity'] ?? '',
        vuln['cvssScore']?.toString() ?? '',
        vuln['status'] ?? '',
        vuln['foundDate'] ?? '',
        vuln['description'] ?? '',
      ]),
    ];
    
    final csvString = ListToCsvConverter().convert(csvData);
    await file.writeAsString(csvString);
  }

  Future<void> _exportAsPdfReport(Map<String, dynamic> data, String fileName) async {
    final path = await _exportPath;
    final file = File('$path/$fileName');
    
    // For now, create a simple text-based report
    // In a real implementation, you'd use pdf package
    final report = _generateTextReport(data);
    await file.writeAsString(report);
  }

  String _generateTextReport(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    buffer.writeln('VULNERABILITY ASSESSMENT REPORT');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('=' * 50);
    buffer.writeln();
    
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    buffer.writeln('EXECUTIVE SUMMARY');
    buffer.writeln('-' * 20);
    buffer.writeln('Total Vulnerabilities: ${summary['total'] ?? 0}');
    buffer.writeln('Critical: ${summary['critical'] ?? 0}');
    buffer.writeln('High: ${summary['high'] ?? 0}');
    buffer.writeln('Medium: ${summary['medium'] ?? 0}');
    buffer.writeln('Low: ${summary['low'] ?? 0}');
    buffer.writeln();
    
    final vulnerabilities = data['vulnerabilities'] as List<dynamic>? ?? [];
    buffer.writeln('DETAILED FINDINGS');
    buffer.writeln('-' * 20);
    
    for (final vuln in vulnerabilities) {
      buffer.writeln('ID: ${vuln['id']}');
      buffer.writeln('Title: ${vuln['title']}');
      buffer.writeln('Severity: ${vuln['severity']}');
      buffer.writeln('CVSS Score: ${vuln['cvssScore']}');
      buffer.writeln('Description: ${vuln['description']}');
      buffer.writeln('Recommendation: ${vuln['recommendation']}');
      buffer.writeln('-' * 30);
    }
    
    return buffer.toString();
  }

  Future<bool> exportSecurityLogs(List<Map<String, dynamic>> logs) async {
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'security_logs_$timestamp';
      
      // Export as JSON
      await _exportAsJson({'logs': logs}, '${fileName}.json');
      
      // Export as CSV
      await _exportLogsAsCsv(logs, '${fileName}.csv');
      
      return true;
    } catch (e) {
      debugPrint('Log export failed: $e');
      return false;
    }
  }

  Future<void> _exportLogsAsCsv(List<Map<String, dynamic>> logs, String fileName) async {
    final path = await _exportPath;
    final file = File('$path/$fileName');
    
    final csvData = [
      ['Timestamp', 'Level', 'Event', 'User', 'IP Address', 'Details'],
      ...logs.map((log) => [
        log['timestamp']?.toString() ?? '',
        log['level'] ?? '',
        log['event'] ?? '',
        log['user'] ?? '',
        log['ipAddress'] ?? '',
        log['details'] ?? '',
      ]),
    ];
    
    final csvString = ListToCsvConverter().convert(csvData);
    await file.writeAsString(csvString);
  }

  Future<bool> exportUserData(Map<String, dynamic> userData) async {
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'user_data_export_$timestamp.json';
      
      await _exportAsJson(userData, fileName);
      return true;
    } catch (e) {
      debugPrint('User data export failed: $e');
      return false;
    }
  }

  Future<List<String>> getExportedFiles() async {
    try {
      final path = await _exportPath;
      final directory = Directory(path);
      
      if (!await directory.exists()) {
        return [];
      }
      
      final files = await directory.list().toList();
      return files
          .where((entity) => entity is File)
          .map((file) => file.path.split('/').last)
          .toList();
    } catch (e) {
      debugPrint('Failed to get exported files: $e');
      return [];
    }
  }

  Future<bool> shareExportedFile(String fileName) async {
    try {
      final path = await _exportPath;
      final file = File('$path/$fileName');
      
      if (await file.exists()) {
        await Share.shareXFiles([XFile(file.path)], text: 'Exported file: $fileName');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to share file: $e');
      return false;
    }
  }

  Future<bool> deleteExportedFile(String fileName) async {
    try {
      final path = await _exportPath;
      final file = File('$path/$fileName');
      
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to delete file: $e');
      return false;
    }
  }
}
