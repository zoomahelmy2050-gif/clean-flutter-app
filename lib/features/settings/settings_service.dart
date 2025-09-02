import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MfaType {
  email,
  totp,
  biometric,
}

class SettingsService {
  late final ValueNotifier<ThemeMode> themeModeNotifier;

  SettingsService() {
    themeModeNotifier = ValueNotifier(ThemeMode.system);
  }

  Future<void> init() async {
    themeModeNotifier.value = await getThemeMode();
  }
  static const _mfaKey = 'mfa_preference';
  static const _themeKey = 'theme_preference';
  static const _mfaEnabledKey = 'mfa_enabled';

  Future<MfaType> getMfaType() async {
    final prefs = await SharedPreferences.getInstance();
    final mfaString = prefs.getString(_mfaKey) ?? MfaType.email.name;
    return MfaType.values.byName(mfaString);
  }

  Future<void> setMfaType(MfaType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mfaKey, type.name);
  }

  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey) ?? ThemeMode.system.name;
    return ThemeMode.values.byName(themeString);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
    themeModeNotifier.value = mode;
  }

  Future<bool> isMfaEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_mfaEnabledKey) ?? false;
  }

  Future<void> setMfaEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mfaEnabledKey, isEnabled);
  }
}
