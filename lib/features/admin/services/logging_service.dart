import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/production_database_service.dart';
import '../../../locator.dart';
import 'dart:developer' as developer;

class FailedAttempt {
  final String username;
  final DateTime timestamp;
  final String? device; // e.g., android 14; ios 17; windows 11
  final String? ip;     // local IP best-effort

  FailedAttempt({required this.username, required this.timestamp, this.device, this.ip});

  Map<String, dynamic> toJson() => {
        'u': username,
        't': timestamp.toIso8601String(),
        'd': device,
        'i': ip,
      };

  factory FailedAttempt.fromJson(Map<String, dynamic> json) => FailedAttempt(
        username: json['u'] as String,
        timestamp: DateTime.parse(json['t'] as String),
        device: json['d'] as String?,
        ip: json['i'] as String?,
      );
}

class LoggingService {
  final List<FailedAttempt> _failedAttempts = [];
  // Successful login and signup audit trails
  final List<FailedAttempt> _successfulLogins = [];
  final List<FailedAttempt> _signUps = [];
  final List<FailedAttempt> _summariesSent = [];
  // MFA usage (e.g., OTP verified)
  final List<FailedAttempt> _mfaUsed = [];
  // MFA by method for finer analytics
  final List<FailedAttempt> _mfaOtp = [];
  final List<FailedAttempt> _mfaTotp = [];
  final List<FailedAttempt> _mfaBiometric = [];
  // Admin actions (e.g., block/unblock/toggle MFA)
  final List<FailedAttempt> _adminActions = [];

  static const _kFailedKey = 'logs_failed_v1';
  static const _kLoginsKey = 'logs_logins_v1';
  static const _kSignupsKey = 'logs_signups_v1';
  static const _kSummariesKey = 'logs_summaries_v1';
  static const _kMfaUsedKey = 'logs_mfa_used_v1';
  static const _kMfaOtpKey = 'logs_mfa_otp_v1';
  static const _kMfaTotpKey = 'logs_mfa_totp_v1';
  static const _kMfaBiometricKey = 'logs_mfa_biometric_v1';
  static const _kAdminActionsKey = 'logs_admin_actions_v1';

  // Optional cap to keep storage small
  static const int _maxEntries = 500;

  List<FailedAttempt> get failedAttempts => _failedAttempts;
  List<FailedAttempt> get successfulLogins => _successfulLogins;
  List<FailedAttempt> get signUps => _signUps;
  List<FailedAttempt> get summariesSent => _summariesSent;
  List<FailedAttempt> get mfaUsed => _mfaUsed;
  List<FailedAttempt> get mfaOtp => _mfaOtp;
  List<FailedAttempt> get mfaTotp => _mfaTotp;
  List<FailedAttempt> get mfaBiometric => _mfaBiometric;
  List<FailedAttempt> get adminActions => _adminActions;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _loadInto(_failedAttempts, prefs.getStringList(_kFailedKey));
      _loadInto(_successfulLogins, prefs.getStringList(_kLoginsKey));
      _loadInto(_signUps, prefs.getStringList(_kSignupsKey));
      _loadInto(_summariesSent, prefs.getStringList(_kSummariesKey));
      _loadInto(_mfaUsed, prefs.getStringList(_kMfaUsedKey));
      _loadInto(_mfaOtp, prefs.getStringList(_kMfaOtpKey));
      _loadInto(_mfaTotp, prefs.getStringList(_kMfaTotpKey));
      _loadInto(_mfaBiometric, prefs.getStringList(_kMfaBiometricKey));
      _loadInto(_adminActions, prefs.getStringList(_kAdminActionsKey));
      debugPrint('LoggingService initialized with persisted logs.');
    } catch (e) {
      debugPrint('LoggingService init failed: $e');
    }
  }

  void _loadInto(List<FailedAttempt> target, List<String>? raw) {
    target.clear();
    if (raw == null) return;
    for (final s in raw) {
      try {
        final m = json.decode(s) as Map<String, dynamic>;
        target.add(FailedAttempt.fromJson(m));
      } catch (_) {}
    }
    target.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (target.length > _maxEntries) {
      target.removeRange(0, target.length - _maxEntries);
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kFailedKey, _failedAttempts.map((e) => json.encode(e.toJson())).toList());
      await prefs.setStringList(_kLoginsKey, _successfulLogins.map((e) => json.encode(e.toJson())).toList());
      await prefs.setStringList(_kSignupsKey, _signUps.map((e) => json.encode(e.toJson())).toList());
      await prefs.setStringList(_kSummariesKey, _summariesSent.map((e) => json.encode(e.toJson())).toList());
      await prefs.setStringList(_kMfaUsedKey, _mfaUsed.map((e) => json.encode(e.toJson())).toList());
      await prefs.setStringList(_kMfaOtpKey, _mfaOtp.map((e) => json.encode(e.toJson())).toList());
      await prefs.setStringList(_kMfaTotpKey, _mfaTotp.map((e) => json.encode(e.toJson())).toList());
      await prefs.setStringList(_kMfaBiometricKey, _mfaBiometric.map((e) => json.encode(e.toJson())).toList());
      await prefs.setStringList(_kAdminActionsKey, _adminActions.map((e) => json.encode(e.toJson())).toList());
    } catch (e) {
      debugPrint('Persist logs failed: $e');
    }
  }

  Future<void> logFailedAttempt(String username) async {
    final ctx = await _context();
    final log = FailedAttempt(username: username, timestamp: DateTime.now(), device: ctx.$1, ip: ctx.$2);
    _failedAttempts.add(log);
    
    // Log to production database
    try {
      final dbService = locator<ProductionDatabaseService>();
      await dbService.logSecurityEvent(
        'failed_login',
        'medium',
        'Failed login attempt',
        userId: username,
        metadata: {
          'device': ctx.$1,
          'ipAddress': ctx.$2,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      developer.log('Failed attempt logged to production DB for: $username', name: 'LoggingService');
    } catch (e) {
      developer.log('Failed to log to production DB: $e', name: 'LoggingService');
    }
    
    debugPrint('Logged failed attempt for user: $username');
    _trimAndPersist();
  }

  Future<void> logSuccessfulLogin(String username) async {
    final ctx = await _context();
    final log = FailedAttempt(username: username, timestamp: DateTime.now(), device: ctx.$1, ip: ctx.$2);
    _successfulLogins.add(log);
    
    // Log to production database
    try {
      final dbService = locator<ProductionDatabaseService>();
      await dbService.logSecurityEvent(
        'successful_login',
        'info',
        'Successful login',
        userId: username,
        metadata: {
          'device': ctx.$1,
          'ipAddress': ctx.$2,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      developer.log('Successful login logged to production DB for: $username', name: 'LoggingService');
    } catch (e) {
      developer.log('Failed to log to production DB: $e', name: 'LoggingService');
    }
    
    debugPrint('Logged successful login for user: $username');
    _trimAndPersist();
  }

  Future<void> logSignUp(String username) async {
    final ctx = await _context();
    final log = FailedAttempt(username: username, timestamp: DateTime.now(), device: ctx.$1, ip: ctx.$2);
    _signUps.add(log);
    debugPrint('Logged signup for user: $username');
    _trimAndPersist();
  }

  Future<void> logSummarySent(String target) async {
    final ctx = await _context();
    final log = FailedAttempt(username: target, timestamp: DateTime.now(), device: ctx.$1, ip: ctx.$2);
    _summariesSent.add(log);
    debugPrint('Logged summary email sent: $target');
    _trimAndPersist();
  }

  Future<void> logMfaUsed(String username) async {
    final ctx = await _context();
    final log = FailedAttempt(username: username, timestamp: DateTime.now(), device: ctx.$1, ip: ctx.$2);
    _mfaUsed.add(log);
    debugPrint('Logged MFA used for user: $username');
    _trimAndPersist();
  }

  Future<void> logMfaOtp(String username) async {
    final ctx = await _context();
    final log = FailedAttempt(username: username, timestamp: DateTime.now(), device: 'mfa:otp · ${ctx.$1}', ip: ctx.$2);
    _mfaOtp.add(log);
    _mfaUsed.add(log);
    debugPrint('Logged MFA(OTP) for user: $username');
    _trimAndPersist();
  }

  Future<void> logMfaTotp(String username) async {
    final ctx = await _context();
    final log = FailedAttempt(username: username, timestamp: DateTime.now(), device: 'mfa:totp · ${ctx.$1}', ip: ctx.$2);
    _mfaTotp.add(log);
    _mfaUsed.add(log);
    debugPrint('Logged MFA(TOTP) for user: $username');
    _trimAndPersist();
  }

  Future<void> logMfaBiometric(String username) async {
    final ctx = await _context();
    final log = FailedAttempt(username: username, timestamp: DateTime.now(), device: 'mfa:biometric · ${ctx.$1}', ip: ctx.$2);
    _mfaBiometric.add(log);
    _mfaUsed.add(log);
    debugPrint('Logged MFA(Biometric) for user: $username');
    _trimAndPersist();
  }

  Future<void> logAdminAction(String action, String targetUser) async {
    // Encode action in device field for compactness, keep username as target
    final ctx = await _context();
    final deviceTag = (ctx.$1?.isNotEmpty ?? false) ? '${ctx.$1} · action:$action' : 'action:$action';
    final log = FailedAttempt(username: targetUser, timestamp: DateTime.now(), device: deviceTag, ip: ctx.$2);
    _adminActions.add(log);
    debugPrint('Logged admin action "$action" for user: $targetUser');
    _trimAndPersist();
  }

  int getFailedAttemptsCount({Duration duration = const Duration(hours: 24)}) {
    final now = DateTime.now();
    return _failedAttempts.where((log) {
      return now.difference(log.timestamp) <= duration;
    }).length;
  }

  int getMfaUsedCount({Duration duration = const Duration(hours: 24)}) {
    final now = DateTime.now();
    return _mfaUsed.where((log) => now.difference(log.timestamp) <= duration).length;
  }

  int getMfaOtpCount({Duration duration = const Duration(hours: 24)}) {
    final now = DateTime.now();
    return _mfaOtp.where((log) => now.difference(log.timestamp) <= duration).length;
  }

  int getMfaTotpCount({Duration duration = const Duration(hours: 24)}) {
    final now = DateTime.now();
    return _mfaTotp.where((log) => now.difference(log.timestamp) <= duration).length;
  }

  int getMfaBiometricCount({Duration duration = const Duration(hours: 24)}) {
    final now = DateTime.now();
    return _mfaBiometric.where((log) => now.difference(log.timestamp) <= duration).length;
  }

  int getActiveAlertsCount({Duration duration = const Duration(hours: 24)}) {
    // Mock implementation - return a simulated count of active security alerts
    return 3;
  }

  double getSecurityScore() {
    // Mock implementation - return a simulated security score out of 100
    return 87.5;
  }

  int getCriticalEventsCount({Duration duration = const Duration(hours: 24)}) {
    // Mock implementation - return a simulated count of critical security events
    return 1;
  }

  void _trimAndPersist() {
    if (_failedAttempts.length > _maxEntries) {
      _failedAttempts.removeRange(0, _failedAttempts.length - _maxEntries);
    }
    if (_successfulLogins.length > _maxEntries) {
      _successfulLogins.removeRange(0, _successfulLogins.length - _maxEntries);
    }
    if (_signUps.length > _maxEntries) {
      _signUps.removeRange(0, _signUps.length - _maxEntries);
    }
    if (_summariesSent.length > _maxEntries) {
      _summariesSent.removeRange(0, _summariesSent.length - _maxEntries);
    }
    if (_mfaUsed.length > _maxEntries) {
      _mfaUsed.removeRange(0, _mfaUsed.length - _maxEntries);
    }
    if (_adminActions.length > _maxEntries) {
      _adminActions.removeRange(0, _adminActions.length - _maxEntries);
    }
    _persist();
  }

  // Helpers to capture device and IP
  Future<(String?, String?)> _context() async {
    String? device;
    String? ip;
    try {
      device = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    } catch (_) {}
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLoopback: false);
      for (final ni in interfaces) {
        for (final a in ni.addresses) {
          if (!a.isLoopback && a.type == InternetAddressType.IPv4) {
            ip = a.address;
            break;
          }
        }
        if (ip != null) break;
      }
    } catch (_) {}
    return (device, ip);
  }

  /// Export all logs into a CSV file and return the saved file path.
  /// Columns: type,username,timestamp,device,ip
  Future<String> exportCsv({DateTime? since}) async {
    final buf = StringBuffer();
    buf.writeln('type,username,timestamp,device,ip');
    void writeRows(String type, List<FailedAttempt> xs) {
      for (final e in xs) {
        if (since != null && e.timestamp.isBefore(since)) continue;
        // Basic CSV escaping: wrap fields that may contain commas/quotes
        String esc(String? v) {
          final s = v ?? '';
          if (s.contains(',') || s.contains('"') || s.contains('\n')) {
            return '"' + s.replaceAll('"', '""') + '"';
          }
          return s;
        }
        buf.writeln([
          type,
          esc(e.username),
          e.timestamp.toIso8601String(),
          esc(e.device),
          esc(e.ip),
        ].join(','));
      }
    }

    writeRows('failed', _failedAttempts);
    writeRows('login', _successfulLogins);
    writeRows('signup', _signUps);
    writeRows('summary', _summariesSent);
    writeRows('mfa', _mfaUsed);
    writeRows('admin', _adminActions);

    final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${Directory.systemTemp.path}/security_logs_$ts.csv');
    await file.writeAsString(buf.toString());
    return file.path;
  }
}
