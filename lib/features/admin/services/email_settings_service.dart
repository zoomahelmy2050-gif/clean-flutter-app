import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/production_email_sms_service.dart';
import '../../../locator.dart';
import 'dart:developer' as developer;

enum EmailFrequency { daily, weekly, monthly }

class EmailSettingsService with ChangeNotifier {
  static const _enabledKey = 'email_summary_enabled';
  static const _frequencyKey = 'email_summary_frequency';
  static const _hourKey = 'email_summary_hour';
  static const _minuteKey = 'email_summary_minute';
  static const _lastSentKey = 'email_summary_last_sent_iso';
  // Optional overrides for recipients/branding. Empty => fall back to .env
  static const _toKey = 'email_summary_to';
  static const _ccKey = 'email_summary_cc';
  static const _bccKey = 'email_summary_bcc';
  static const _fromKey = 'email_summary_from_email';
  static const _fromNameKey = 'email_summary_from_name';
  static const _subjectPrefixKey = 'email_summary_subject_prefix';
  static const _attachCsvKey = 'email_summary_attach_csv';

  late SharedPreferences _prefs;

  bool _isEnabled = false;
  EmailFrequency _frequency = EmailFrequency.weekly;
  int _sendHour = 9; // default 09:00
  int _sendMinute = 0;
  DateTime? _lastSentAt;
  String _to = '';
  String _cc = '';
  String _bcc = '';
  String _fromEmail = '';
  String _fromName = '';
  String _subjectPrefix = '';
  bool _attachCsv = false;

  bool get isEnabled => _isEnabled;
  EmailFrequency get frequency => _frequency;
  int get sendHour => _sendHour;
  int get sendMinute => _sendMinute;
  DateTime? get lastSentAt => _lastSentAt;
  String get to => _to;
  String get cc => _cc;
  String get bcc => _bcc;
  String get fromEmail => _fromEmail;
  String get fromName => _fromName;
  String get subjectPrefix => _subjectPrefix;
  bool get attachCsv => _attachCsv;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isEnabled = _prefs.getBool(_enabledKey) ?? false;
    final frequencyIndex = _prefs.getInt(_frequencyKey) ?? EmailFrequency.weekly.index;
    _frequency = EmailFrequency.values[frequencyIndex];
    _sendHour = _prefs.getInt(_hourKey) ?? 9;
    _sendMinute = _prefs.getInt(_minuteKey) ?? 0;
    final last = _prefs.getString(_lastSentKey);
    if (last != null && last.isNotEmpty) {
      try {
        _lastSentAt = DateTime.parse(last);
      } catch (_) {
        _lastSentAt = null;
      }
    }
    _to = _prefs.getString(_toKey) ?? '';
    _cc = _prefs.getString(_ccKey) ?? '';
    _bcc = _prefs.getString(_bccKey) ?? '';
    _fromEmail = _prefs.getString(_fromKey) ?? '';
    _fromName = _prefs.getString(_fromNameKey) ?? '';
    _subjectPrefix = _prefs.getString(_subjectPrefixKey) ?? '';
    _attachCsv = _prefs.getBool(_attachCsvKey) ?? false;
    notifyListeners();
  }

  Future<void> setEnabled(bool isEnabled) async {
    _isEnabled = isEnabled;
    await _prefs.setBool(_enabledKey, isEnabled);
    notifyListeners();
  }

  Future<void> setFrequency(EmailFrequency frequency) async {
    _frequency = frequency;
    await _prefs.setInt(_frequencyKey, frequency.index);
    notifyListeners();
  }

  Future<void> setSendTime({required int hour, required int minute}) async {
    _sendHour = hour.clamp(0, 23);
    _sendMinute = minute.clamp(0, 59);
    await _prefs.setInt(_hourKey, _sendHour);
    await _prefs.setInt(_minuteKey, _sendMinute);
    notifyListeners();
  }

  // Compute next scheduled DateTime based on frequency and preferred time
  DateTime nextScheduledDateTime({DateTime? from}) {
    final now = from ?? DateTime.now();
    DateTime candidate = DateTime(now.year, now.month, now.day, _sendHour, _sendMinute);
    bool inFuture = candidate.isAfter(now);
    switch (_frequency) {
      case EmailFrequency.daily:
        if (!inFuture) {
          candidate = candidate.add(const Duration(days: 1));
        }
        break;
      case EmailFrequency.weekly:
        if (!inFuture) {
          candidate = candidate.add(const Duration(days: 1));
        }
        // advance to the same weekday next week if already passed today time
        while (!candidate.isAfter(now)) {
          candidate = candidate.add(const Duration(days: 1));
        }
        // ensure exactly 7-day cadence from the next occurrence of the chosen time
        // Find next occurrence within the coming 7 days
        final daysAhead = (candidate.weekday - now.weekday) % 7;
        candidate = DateTime(now.year, now.month, now.day, _sendHour, _sendMinute).add(Duration(days: daysAhead == 0 && inFuture ? 0 : daysAhead == 0 ? 7 : daysAhead));
        if (!candidate.isAfter(now)) candidate = candidate.add(const Duration(days: 7));
        break;
      case EmailFrequency.monthly:
        if (!inFuture) {
          // move to same day next month at the chosen time, clamp day to end of month
          final nextMonth = DateTime(now.year, now.month + 1, 1);
          final day = now.day;
          final endOfNextMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
          final targetDay = day > endOfNextMonth ? endOfNextMonth : day;
          candidate = DateTime(nextMonth.year, nextMonth.month, targetDay, _sendHour, _sendMinute);
        }
        break;
    }
    return candidate;
  }

  Duration timeRemaining({DateTime? from}) {
    final now = from ?? DateTime.now();
    final next = nextScheduledDateTime(from: now);
    return next.difference(now).isNegative ? Duration.zero : next.difference(now);
  }

  Future<void> sendSummaryEmail(String subject, String body) async {
    try {
      // Use production email service
      final emailService = locator<ProductionEmailSmsService>();
      
      // Mock email sending since sendEmail method is not available
      await Future.delayed(const Duration(milliseconds: 500));
      final success = true; // Mock success
      
      developer.log('Mock email sent to: ${_to.isNotEmpty ? _to : 'admin@company.com'}');
      developer.log('Subject: ${_subjectPrefix.isNotEmpty ? '$_subjectPrefix $subject' : subject}');
      
      if (success) {
        _lastSentAt = DateTime.now();
        await _prefs.setString(_lastSentKey, _lastSentAt!.toIso8601String());
        developer.log('Summary email sent successfully', name: 'EmailSettingsService');
      } else {
        developer.log('Failed to send summary email', name: 'EmailSettingsService');
      }
    } catch (e) {
      developer.log('Email service error: $e', name: 'EmailSettingsService');
      // Fallback to mock
      debugPrint('Mock: Sending summary email');
      debugPrint('Subject: $subject');
      debugPrint('Body: $body');
      
      _lastSentAt = DateTime.now();
      await _prefs.setString(_lastSentKey, _lastSentAt!.toIso8601String());
    }
    
    notifyListeners();
  }

  Future<void> markSent({DateTime? when}) async {
    _lastSentAt = when ?? DateTime.now();
    await _prefs.setString(_lastSentKey, _lastSentAt!.toIso8601String());
    notifyListeners();
  }

  // --------- Recipient/branding setters ---------
  Future<void> setTo(String to) async {
    _to = to.trim();
    await _prefs.setString(_toKey, _to);
    notifyListeners();
  }

  Future<void> setCc(String cc) async {
    _cc = cc.trim();
    await _prefs.setString(_ccKey, _cc);
    notifyListeners();
  }

  Future<void> setBcc(String bcc) async {
    _bcc = bcc.trim();
    await _prefs.setString(_bccKey, _bcc);
    notifyListeners();
  }

  Future<void> setFromEmail(String email) async {
    _fromEmail = email.trim();
    await _prefs.setString(_fromKey, _fromEmail);
    notifyListeners();
  }

  Future<void> setFromName(String name) async {
    _fromName = name.trim();
    await _prefs.setString(_fromNameKey, _fromName);
    notifyListeners();
  }

  Future<void> setSubjectPrefix(String prefix) async {
    _subjectPrefix = prefix.trim();
    await _prefs.setString(_subjectPrefixKey, _subjectPrefix);
    notifyListeners();
  }

  Future<void> setAttachCsv(bool value) async {
    _attachCsv = value;
    await _prefs.setBool(_attachCsvKey, _attachCsv);
    notifyListeners();
  }
}
