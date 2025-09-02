import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AccessibilityFeature {
  screenReader,
  largeText,
  highContrast,
  colorBlind,
  reduceMotion,
  hapticFeedback,
  audioFeedback,
  focusIndicator,
}

/// Local enum to represent haptic feedback types across platforms
enum HapticFeedbackType {
  lightImpact,
  mediumImpact,
  heavyImpact,
  selectionClick,
  vibrate,
}

class AccessibilityConfig {
  final bool screenReaderEnabled;
  final double textScaleFactor;
  final bool highContrastEnabled;
  final bool colorBlindFriendly;
  final bool reduceMotionEnabled;
  final bool hapticFeedbackEnabled;
  final bool audioFeedbackEnabled;
  final bool focusIndicatorEnabled;
  final Map<String, bool> customSettings;

  AccessibilityConfig({
    this.screenReaderEnabled = false,
    this.textScaleFactor = 1.0,
    this.highContrastEnabled = false,
    this.colorBlindFriendly = false,
    this.reduceMotionEnabled = false,
    this.hapticFeedbackEnabled = true,
    this.audioFeedbackEnabled = false,
    this.focusIndicatorEnabled = true,
    this.customSettings = const {},
  });

  Map<String, dynamic> toJson() => {
    'screenReaderEnabled': screenReaderEnabled,
    'textScaleFactor': textScaleFactor,
    'highContrastEnabled': highContrastEnabled,
    'colorBlindFriendly': colorBlindFriendly,
    'reduceMotionEnabled': reduceMotionEnabled,
    'hapticFeedbackEnabled': hapticFeedbackEnabled,
    'audioFeedbackEnabled': audioFeedbackEnabled,
    'focusIndicatorEnabled': focusIndicatorEnabled,
    'customSettings': customSettings,
  };

  factory AccessibilityConfig.fromJson(Map<String, dynamic> json) {
    return AccessibilityConfig(
      screenReaderEnabled: json['screenReaderEnabled'] ?? false,
      textScaleFactor: (json['textScaleFactor'] ?? 1.0).toDouble(),
      highContrastEnabled: json['highContrastEnabled'] ?? false,
      colorBlindFriendly: json['colorBlindFriendly'] ?? false,
      reduceMotionEnabled: json['reduceMotionEnabled'] ?? false,
      hapticFeedbackEnabled: json['hapticFeedbackEnabled'] ?? true,
      audioFeedbackEnabled: json['audioFeedbackEnabled'] ?? false,
      focusIndicatorEnabled: json['focusIndicatorEnabled'] ?? true,
      customSettings: Map<String, bool>.from(json['customSettings'] ?? {}),
    );
  }

  AccessibilityConfig copyWith({
    bool? screenReaderEnabled,
    double? textScaleFactor,
    bool? highContrastEnabled,
    bool? colorBlindFriendly,
    bool? reduceMotionEnabled,
    bool? hapticFeedbackEnabled,
    bool? audioFeedbackEnabled,
    bool? focusIndicatorEnabled,
    Map<String, bool>? customSettings,
  }) {
    return AccessibilityConfig(
      screenReaderEnabled: screenReaderEnabled ?? this.screenReaderEnabled,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      highContrastEnabled: highContrastEnabled ?? this.highContrastEnabled,
      colorBlindFriendly: colorBlindFriendly ?? this.colorBlindFriendly,
      reduceMotionEnabled: reduceMotionEnabled ?? this.reduceMotionEnabled,
      hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
      audioFeedbackEnabled: audioFeedbackEnabled ?? this.audioFeedbackEnabled,
      focusIndicatorEnabled: focusIndicatorEnabled ?? this.focusIndicatorEnabled,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}

class AccessibilityService extends ChangeNotifier {
  AccessibilityConfig _config = AccessibilityConfig();
  Timer? _announcementTimer;
  
  static const String _configKey = 'accessibility_config';
  static const MethodChannel _ttsChannel = MethodChannel('text_to_speech');

  // Getters
  AccessibilityConfig get config => _config;
  bool get screenReaderEnabled => _config.screenReaderEnabled;
  double get textScaleFactor => _config.textScaleFactor;
  bool get highContrastEnabled => _config.highContrastEnabled;
  bool get colorBlindFriendly => _config.colorBlindFriendly;
  bool get reduceMotionEnabled => _config.reduceMotionEnabled;
  bool get hapticFeedbackEnabled => _config.hapticFeedbackEnabled;
  bool get audioFeedbackEnabled => _config.audioFeedbackEnabled;
  bool get focusIndicatorEnabled => _config.focusIndicatorEnabled;

  /// Initialize accessibility service
  Future<void> initialize() async {
    await _loadConfig();
    await _detectSystemSettings();
  }

  /// Load configuration from storage
  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_configKey);
      
      if (configJson != null) {
        final Map<String, dynamic> data = jsonDecode(configJson);
        _config = AccessibilityConfig.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error loading accessibility config: $e');
    }
  }

  /// Save configuration to storage
  Future<void> _saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_configKey, jsonEncode(_config.toJson()));
    } catch (e) {
      debugPrint('Error saving accessibility config: $e');
    }
  }

  /// Detect system accessibility settings
  Future<void> _detectSystemSettings() async {
    try {
      // Check if system screen reader is enabled
      final mediaQuery = MediaQueryData.fromWindow(WidgetsBinding.instance.window);
      final systemScreenReader = mediaQuery.accessibleNavigation;
      
      if (systemScreenReader && !_config.screenReaderEnabled) {
        await updateConfig(_config.copyWith(screenReaderEnabled: true));
      }
      
      // Check system text scale
      final systemTextScale = mediaQuery.textScaleFactor;
      if (systemTextScale > 1.0 && _config.textScaleFactor == 1.0) {
        await updateConfig(_config.copyWith(textScaleFactor: systemTextScale));
      }
      
      // Check reduce motion
      final systemReduceMotion = mediaQuery.disableAnimations;
      if (systemReduceMotion && !_config.reduceMotionEnabled) {
        await updateConfig(_config.copyWith(reduceMotionEnabled: true));
      }
    } catch (e) {
      debugPrint('Error detecting system accessibility settings: $e');
    }
  }

  /// Update accessibility configuration
  Future<void> updateConfig(AccessibilityConfig newConfig) async {
    _config = newConfig;
    await _saveConfig();
    notifyListeners();
  }

  /// Toggle screen reader
  Future<void> toggleScreenReader() async {
    await updateConfig(_config.copyWith(
      screenReaderEnabled: !_config.screenReaderEnabled,
    ));
  }

  /// Set text scale factor
  Future<void> setTextScaleFactor(double factor) async {
    final clampedFactor = factor.clamp(0.8, 3.0);
    await updateConfig(_config.copyWith(textScaleFactor: clampedFactor));
  }

  /// Toggle high contrast
  Future<void> toggleHighContrast() async {
    await updateConfig(_config.copyWith(
      highContrastEnabled: !_config.highContrastEnabled,
    ));
  }

  /// Toggle color blind friendly mode
  Future<void> toggleColorBlindFriendly() async {
    await updateConfig(_config.copyWith(
      colorBlindFriendly: !_config.colorBlindFriendly,
    ));
  }

  /// Toggle reduce motion
  Future<void> toggleReduceMotion() async {
    await updateConfig(_config.copyWith(
      reduceMotionEnabled: !_config.reduceMotionEnabled,
    ));
  }

  /// Toggle haptic feedback
  Future<void> toggleHapticFeedback() async {
    await updateConfig(_config.copyWith(
      hapticFeedbackEnabled: !_config.hapticFeedbackEnabled,
    ));
  }

  /// Toggle audio feedback
  Future<void> toggleAudioFeedback() async {
    await updateConfig(_config.copyWith(
      audioFeedbackEnabled: !_config.audioFeedbackEnabled,
    ));
  }

  /// Toggle focus indicator
  Future<void> toggleFocusIndicator() async {
    await updateConfig(_config.copyWith(
      focusIndicatorEnabled: !_config.focusIndicatorEnabled,
    ));
  }

  /// Announce text for screen readers
  Future<void> announceText(String text, {bool interrupt = false}) async {
    if (!_config.screenReaderEnabled && !_config.audioFeedbackEnabled) return;
    
    try {
      if (interrupt) {
        _announcementTimer?.cancel();
      }
      
      // Use system screen reader if available
      await SemanticsService.announce(text, TextDirection.ltr);
      
      // Fallback to TTS if available
      if (_config.audioFeedbackEnabled) {
        await _speakText(text);
      }
    } catch (e) {
      debugPrint('Error announcing text: $e');
    }
  }

  /// Speak text using TTS
  Future<void> _speakText(String text) async {
    try {
      await _ttsChannel.invokeMethod('speak', {'text': text});
    } catch (e) {
      debugPrint('TTS not available: $e');
    }
  }

  /// Provide haptic feedback
  Future<void> provideHapticFeedback(HapticFeedbackType type) async {
    if (!_config.hapticFeedbackEnabled) return;
    
    try {
      switch (type) {
        case HapticFeedbackType.lightImpact:
          await HapticFeedback.lightImpact();
          break;
        case HapticFeedbackType.mediumImpact:
          await HapticFeedback.mediumImpact();
          break;
        case HapticFeedbackType.heavyImpact:
          await HapticFeedback.heavyImpact();
          break;
        case HapticFeedbackType.selectionClick:
          await HapticFeedback.selectionClick();
          break;
        case HapticFeedbackType.vibrate:
          await HapticFeedback.vibrate();
          break;
      }
    } catch (e) {
      debugPrint('Error providing haptic feedback: $e');
    }
  }

  /// Get accessible colors based on settings
  ColorScheme getAccessibleColors(ColorScheme baseScheme) {
    if (!_config.highContrastEnabled && !_config.colorBlindFriendly) {
      return baseScheme;
    }
    
    if (_config.highContrastEnabled) {
      return _getHighContrastColors(baseScheme);
    }
    
    if (_config.colorBlindFriendly) {
      return _getColorBlindFriendlyColors(baseScheme);
    }
    
    return baseScheme;
  }

  /// Get high contrast color scheme
  ColorScheme _getHighContrastColors(ColorScheme baseScheme) {
    return baseScheme.copyWith(
      primary: Colors.black,
      onPrimary: Colors.white,
      secondary: Colors.black,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
      background: Colors.white,
      onBackground: Colors.black,
      error: Colors.red[900]!,
      onError: Colors.white,
    );
  }

  /// Get color blind friendly color scheme
  ColorScheme _getColorBlindFriendlyColors(ColorScheme baseScheme) {
    return baseScheme.copyWith(
      primary: Colors.blue[800]!,
      secondary: Colors.orange[800]!,
      error: Colors.red[800]!,
      tertiary: Colors.purple[800]!,
    );
  }

  /// Get accessible text theme
  TextTheme getAccessibleTextTheme(TextTheme baseTheme) {
    return baseTheme.apply(
      fontSizeFactor: _config.textScaleFactor,
    );
  }

  /// Create accessible button
  Widget createAccessibleButton({
    required Widget child,
    required VoidCallback? onPressed,
    String? semanticLabel,
    String? tooltip,
    bool excludeSemantics = false,
  }) {
    Widget button = ElevatedButton(
      onPressed: onPressed,
      child: child,
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip,
        child: button,
      );
    }

    if (semanticLabel != null && !excludeSemantics) {
      button = Semantics(
        label: semanticLabel,
        button: true,
        enabled: onPressed != null,
        child: ExcludeSemantics(child: button),
      );
    }

    if (_config.focusIndicatorEnabled) {
      button = Focus(
        child: Builder(
          builder: (context) {
            final hasFocus = Focus.of(context).hasFocus;
            return Container(
              decoration: hasFocus ? BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ) : null,
              child: button,
            );
          },
        ),
      );
    }

    return GestureDetector(
      onTap: onPressed != null ? () {
        provideHapticFeedback(HapticFeedbackType.selectionClick);
        onPressed();
      } : null,
      child: button,
    );
  }

  /// Create accessible text field
  Widget createAccessibleTextField({
    required TextEditingController controller,
    String? labelText,
    String? hintText,
    String? semanticLabel,
    bool obscureText = false,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    Widget textField = TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: const OutlineInputBorder(),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 16 * _config.textScaleFactor,
      ),
    );

    if (semanticLabel != null) {
      textField = Semantics(
        label: semanticLabel,
        textField: true,
        child: ExcludeSemantics(child: textField),
      );
    }

    if (_config.focusIndicatorEnabled) {
      textField = Focus(
        child: Builder(
          builder: (context) {
            final hasFocus = Focus.of(context).hasFocus;
            return Container(
              decoration: hasFocus ? BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ) : null,
              child: textField,
            );
          },
        ),
      );
    }

    return textField;
  }

  /// Create accessible list tile
  Widget createAccessibleListTile({
    required Widget title,
    Widget? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    String? semanticLabel,
  }) {
    Widget listTile = ListTile(
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: trailing,
      onTap: onTap != null ? () {
        provideHapticFeedback(HapticFeedbackType.selectionClick);
        onTap();
      } : null,
    );

    if (semanticLabel != null) {
      listTile = Semantics(
        label: semanticLabel,
        button: onTap != null,
        child: ExcludeSemantics(child: listTile),
      );
    }

    return listTile;
  }

  /// Get accessibility summary
  Map<String, dynamic> getAccessibilitySummary() {
    return {
      'screenReader': _config.screenReaderEnabled,
      'textScale': _config.textScaleFactor,
      'highContrast': _config.highContrastEnabled,
      'colorBlindFriendly': _config.colorBlindFriendly,
      'reduceMotion': _config.reduceMotionEnabled,
      'hapticFeedback': _config.hapticFeedbackEnabled,
      'audioFeedback': _config.audioFeedbackEnabled,
      'focusIndicator': _config.focusIndicatorEnabled,
      'featuresEnabled': _getEnabledFeaturesCount(),
    };
  }

  /// Get count of enabled accessibility features
  int _getEnabledFeaturesCount() {
    int count = 0;
    if (_config.screenReaderEnabled) count++;
    if (_config.textScaleFactor > 1.0) count++;
    if (_config.highContrastEnabled) count++;
    if (_config.colorBlindFriendly) count++;
    if (_config.reduceMotionEnabled) count++;
    if (_config.hapticFeedbackEnabled) count++;
    if (_config.audioFeedbackEnabled) count++;
    if (_config.focusIndicatorEnabled) count++;
    return count;
  }

  /// Export accessibility settings
  Map<String, dynamic> exportSettings() {
    return _config.toJson();
  }

  /// Import accessibility settings
  Future<void> importSettings(Map<String, dynamic> settings) async {
    try {
      final newConfig = AccessibilityConfig.fromJson(settings);
      await updateConfig(newConfig);
    } catch (e) {
      throw Exception('Failed to import accessibility settings: $e');
    }
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    await updateConfig(AccessibilityConfig());
  }

  @override
  void dispose() {
    _announcementTimer?.cancel();
    super.dispose();
  }
}
