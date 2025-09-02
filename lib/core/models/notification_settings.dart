import '../models/notification_models.dart';

class NotificationSettings {
  final bool enablePushNotifications;
  final bool enableEmailNotifications;
  final bool enableSMSNotifications;
  final bool enableInAppNotifications;
  final NotificationSeverity minSeverity;
  final Map<NotificationCategory, bool> categorySettings;
  final Duration? quietHoursStart;
  final Duration? quietHoursEnd;
  final bool enableGrouping;
  final AlertGroupingStrategy groupingStrategy;
  final bool enableSound;
  final bool enableVibration;
  final bool enableBadge;
  final DateTime lastModified;

  NotificationSettings({
    this.enablePushNotifications = true,
    this.enableEmailNotifications = false,
    this.enableSMSNotifications = false,
    this.enableInAppNotifications = true,
    this.minSeverity = NotificationSeverity.info,
    this.categorySettings = const {},
    this.quietHoursStart,
    this.quietHoursEnd,
    this.enableGrouping = true,
    this.groupingStrategy = AlertGroupingStrategy.by_type,
    this.enableSound = true,
    this.enableVibration = true,
    this.enableBadge = true,
    required this.lastModified,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enablePushNotifications: json['enablePushNotifications'] ?? true,
      enableEmailNotifications: json['enableEmailNotifications'] ?? false,
      enableSMSNotifications: json['enableSMSNotifications'] ?? false,
      enableInAppNotifications: json['enableInAppNotifications'] ?? true,
      minSeverity: NotificationSeverity.values.firstWhere(
        (e) => e.name == json['minSeverity'],
        orElse: () => NotificationSeverity.info,
      ),
      categorySettings: Map<NotificationCategory, bool>.from(
        (json['categorySettings'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(
            NotificationCategory.values.firstWhere(
              (e) => e.name == key,
              orElse: () => NotificationCategory.system,
            ),
            value as bool,
          ),
        ) ?? {},
      ),
      quietHoursStart: json['quietHoursStart'] != null 
        ? Duration(seconds: json['quietHoursStart']) 
        : null,
      quietHoursEnd: json['quietHoursEnd'] != null 
        ? Duration(seconds: json['quietHoursEnd']) 
        : null,
      enableGrouping: json['enableGrouping'] ?? true,
      groupingStrategy: AlertGroupingStrategy.values.firstWhere(
        (e) => e.name == json['groupingStrategy'],
        orElse: () => AlertGroupingStrategy.by_type,
      ),
      enableSound: json['enableSound'] ?? true,
      enableVibration: json['enableVibration'] ?? true,
      enableBadge: json['enableBadge'] ?? true,
      lastModified: DateTime.tryParse(json['lastModified'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enablePushNotifications': enablePushNotifications,
      'enableEmailNotifications': enableEmailNotifications,
      'enableSMSNotifications': enableSMSNotifications,
      'enableInAppNotifications': enableInAppNotifications,
      'minSeverity': minSeverity.name,
      'categorySettings': categorySettings.map((key, value) => MapEntry(key.name, value)),
      'quietHoursStart': quietHoursStart?.inSeconds,
      'quietHoursEnd': quietHoursEnd?.inSeconds,
      'enableGrouping': enableGrouping,
      'groupingStrategy': groupingStrategy.name,
      'enableSound': enableSound,
      'enableVibration': enableVibration,
      'enableBadge': enableBadge,
      'lastModified': lastModified.toIso8601String(),
    };
  }

  NotificationSettings copyWith({
    bool? enablePushNotifications,
    bool? enableEmailNotifications,
    bool? enableSMSNotifications,
    bool? enableInAppNotifications,
    NotificationSeverity? minSeverity,
    Map<NotificationCategory, bool>? categorySettings,
    Duration? quietHoursStart,
    Duration? quietHoursEnd,
    bool? enableGrouping,
    AlertGroupingStrategy? groupingStrategy,
    bool? enableSound,
    bool? enableVibration,
    bool? enableBadge,
    DateTime? lastModified,
  }) {
    return NotificationSettings(
      enablePushNotifications: enablePushNotifications ?? this.enablePushNotifications,
      enableEmailNotifications: enableEmailNotifications ?? this.enableEmailNotifications,
      enableSMSNotifications: enableSMSNotifications ?? this.enableSMSNotifications,
      enableInAppNotifications: enableInAppNotifications ?? this.enableInAppNotifications,
      minSeverity: minSeverity ?? this.minSeverity,
      categorySettings: categorySettings ?? this.categorySettings,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      enableGrouping: enableGrouping ?? this.enableGrouping,
      groupingStrategy: groupingStrategy ?? this.groupingStrategy,
      enableSound: enableSound ?? this.enableSound,
      enableVibration: enableVibration ?? this.enableVibration,
      enableBadge: enableBadge ?? this.enableBadge,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
