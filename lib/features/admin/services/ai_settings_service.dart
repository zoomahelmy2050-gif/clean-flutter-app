import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AISettings {
  bool autoActionsEnabled;
  bool requestedActionsEnabled;
  bool deepReasoningEnabled;
  bool selfLearningEnabled;
  bool suspiciousActivityDetectionEnabled;
  bool policyRecommendationsEnabled;
  int autoActionDelaySeconds;
  double autoActionThreshold;
  Map<String, bool> actionTypeSettings;

  AISettings({
    this.autoActionsEnabled = false,
    this.requestedActionsEnabled = true,
    this.deepReasoningEnabled = true,
    this.selfLearningEnabled = true,
    this.suspiciousActivityDetectionEnabled = true,
    this.policyRecommendationsEnabled = true,
    this.autoActionDelaySeconds = 30,
    this.autoActionThreshold = 0.85,
    Map<String, bool>? actionTypeSettings,
  }) : actionTypeSettings = actionTypeSettings ?? {
    'block_ip': false,
    'disable_account': false,
    'force_mfa': true,
    'isolate_system': false,
    'reset_password': true,
    'enable_monitoring': true,
    'update_firewall': true,
    'quarantine_file': false,
  };

  Map<String, dynamic> toJson() => {
    'autoActionsEnabled': autoActionsEnabled,
    'requestedActionsEnabled': requestedActionsEnabled,
    'deepReasoningEnabled': deepReasoningEnabled,
    'selfLearningEnabled': selfLearningEnabled,
    'suspiciousActivityDetectionEnabled': suspiciousActivityDetectionEnabled,
    'policyRecommendationsEnabled': policyRecommendationsEnabled,
    'autoActionDelaySeconds': autoActionDelaySeconds,
    'autoActionThreshold': autoActionThreshold,
    'actionTypeSettings': actionTypeSettings,
  };

  factory AISettings.fromJson(Map<String, dynamic> json) {
    return AISettings(
      autoActionsEnabled: json['autoActionsEnabled'] ?? false,
      requestedActionsEnabled: json['requestedActionsEnabled'] ?? true,
      deepReasoningEnabled: json['deepReasoningEnabled'] ?? true,
      selfLearningEnabled: json['selfLearningEnabled'] ?? true,
      suspiciousActivityDetectionEnabled: json['suspiciousActivityDetectionEnabled'] ?? true,
      policyRecommendationsEnabled: json['policyRecommendationsEnabled'] ?? true,
      autoActionDelaySeconds: json['autoActionDelaySeconds'] ?? 30,
      autoActionThreshold: (json['autoActionThreshold'] ?? 0.85).toDouble(),
      actionTypeSettings: Map<String, bool>.from(json['actionTypeSettings'] ?? {}),
    );
  }
  
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_settings', json.encode(toJson()));
  }
  
  static Future<AISettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('ai_settings');
    if (settingsJson != null) {
      return AISettings.fromJson(json.decode(settingsJson));
    }
    return AISettings();
  }
}
