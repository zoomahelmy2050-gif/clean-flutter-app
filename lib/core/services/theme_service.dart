import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _useSystemThemeKey = 'use_system_theme';
  
  ThemeMode _themeMode = ThemeMode.system;
  bool _useSystemTheme = true;

  ThemeMode get themeMode => _themeMode;
  bool get useSystemTheme => _useSystemTheme;
  
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeIndex];
    _useSystemTheme = prefs.getBool(_useSystemThemeKey) ?? true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    _useSystemTheme = mode == ThemeMode.system;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, _themeMode.index);
    await prefs.setBool(_useSystemThemeKey, _useSystemTheme);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    if (_useSystemTheme) {
      // If using system theme, switch to light
      await setThemeMode(ThemeMode.light);
    } else if (_themeMode == ThemeMode.light) {
      // If light, switch to dark
      await setThemeMode(ThemeMode.dark);
    } else {
      // If dark, switch back to system
      await setThemeMode(ThemeMode.system);
    }
  }

  Future<void> setLightTheme() async {
    await setThemeMode(ThemeMode.light);
  }

  Future<void> setDarkTheme() async {
    await setThemeMode(ThemeMode.dark);
  }

  Future<void> setSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }

  String get currentThemeName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}
