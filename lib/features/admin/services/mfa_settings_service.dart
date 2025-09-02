import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MfaSettingsService with ChangeNotifier {
  static const _emailOtpKey = 'mfa_email_otp_enabled';
  static const _backupCodesKey = 'mfa_backup_codes_enabled';

  late SharedPreferences _prefs;

  bool _isEmailOtpEnabled = true;
  bool _isBackupCodesEnabled = true;

  bool get isEmailOtpEnabled => _isEmailOtpEnabled;
  bool get isBackupCodesEnabled => _isBackupCodesEnabled;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isEmailOtpEnabled = _prefs.getBool(_emailOtpKey) ?? true;
    _isBackupCodesEnabled = _prefs.getBool(_backupCodesKey) ?? true;
    notifyListeners();
  }

  Future<void> setEmailOtpEnabled(bool isEnabled) async {
    _isEmailOtpEnabled = isEnabled;
    await _prefs.setBool(_emailOtpKey, isEnabled);
    notifyListeners();
  }

  Future<void> setBackupCodesEnabled(bool isEnabled) async {
    _isBackupCodesEnabled = isEnabled;
    await _prefs.setBool(_backupCodesKey, isEnabled);
    notifyListeners();
  }
}
