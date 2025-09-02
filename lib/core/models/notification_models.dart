enum NotificationSeverity { info, warning, error, critical }
enum NotificationCategory { 
  security, 
  system, 
  user_activity, 
  compliance, 
  threat_detection,
  authentication,
  data_protection,
  network_security,
  incident_response
}
enum NotificationChannel { 
  email, sms, push, in_app, webhook, slack;
  
  static NotificationChannel fromJson(String value) {
    return NotificationChannel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationChannel.in_app,
    );
  }
  
  String toJson() => name;
}
enum NotificationStatus { pending, sent, delivered, failed, acknowledged }
enum AlertGroupingStrategy { none, by_type, by_severity, by_source, by_time }

class SmartNotification {
  final String id;
  final String title;
  final String message;
  final NotificationSeverity severity;
  final NotificationCategory category;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;
  final NotificationStatus status;
  final Map<String, dynamic> metadata;
  final List<String> recipients;
  final List<NotificationChannel> channels;
  final String? sourceId;
  final String? sourceType;
  final Map<String, dynamic> actions;
  final bool isGrouped;
  final String? groupId;
  final int retryCount;
  final DateTime? expiresAt;

  SmartNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.category,
    required this.createdAt,
    this.scheduledAt,
    this.sentAt,
    this.acknowledgedAt,
    this.acknowledgedBy,
    this.status = NotificationStatus.pending,
    this.metadata = const {},
    this.recipients = const [],
    this.channels = const [],
    this.sourceId,
    this.sourceType,
    this.actions = const {},
    this.isGrouped = false,
    this.groupId,
    this.retryCount = 0,
    this.expiresAt,
  });

  factory SmartNotification.fromJson(Map<String, dynamic> json) {
    return SmartNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      severity: NotificationSeverity.values.byName(json['severity']),
      category: NotificationCategory.values.byName(json['category']),
      createdAt: DateTime.parse(json['createdAt']),
      scheduledAt: json['scheduledAt'] != null ? DateTime.parse(json['scheduledAt']) : null,
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : null,
      acknowledgedAt: json['acknowledgedAt'] != null ? DateTime.parse(json['acknowledgedAt']) : null,
      acknowledgedBy: json['acknowledgedBy'],
      status: NotificationStatus.values.byName(json['status']),
      metadata: json['metadata'] ?? {},
      recipients: List<String>.from(json['recipients'] ?? []),
      channels: (json['channels'] as List?)?.map((e) => NotificationChannel.values.byName(e)).toList() ?? [],
      sourceId: json['sourceId'],
      sourceType: json['sourceType'],
      actions: json['actions'] ?? {},
      isGrouped: json['isGrouped'] ?? false,
      groupId: json['groupId'],
      retryCount: json['retryCount'] ?? 0,
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'severity': severity.name,
      'category': category.name,
      'createdAt': createdAt.toIso8601String(),
      'scheduledAt': scheduledAt?.toIso8601String(),
      'sentAt': sentAt?.toIso8601String(),
      'acknowledgedAt': acknowledgedAt?.toIso8601String(),
      'acknowledgedBy': acknowledgedBy,
      'status': status.name,
      'metadata': metadata,
      'recipients': recipients,
      'channels': channels.map((e) => e.name).toList(),
      'sourceId': sourceId,
      'sourceType': sourceType,
      'actions': actions,
      'isGrouped': isGrouped,
      'groupId': groupId,
      'retryCount': retryCount,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
}

class NotificationGroup {
  final String id;
  final String title;
  final String description;
  final NotificationSeverity maxSeverity;
  final NotificationCategory category;
  final AlertGroupingStrategy strategy;
  final List<String> notificationIds;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final int totalCount;
  final Map<NotificationSeverity, int> severityBreakdown;
  final bool isAcknowledged;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;

  NotificationGroup({
    required this.id,
    required this.title,
    required this.description,
    required this.maxSeverity,
    required this.category,
    required this.strategy,
    this.notificationIds = const [],
    required this.createdAt,
    required this.lastUpdated,
    required this.totalCount,
    this.severityBreakdown = const {},
    this.isAcknowledged = false,
    this.acknowledgedBy,
    this.acknowledgedAt,
  });

  factory NotificationGroup.fromJson(Map<String, dynamic> json) {
    return NotificationGroup(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      maxSeverity: NotificationSeverity.values.byName(json['maxSeverity']),
      category: NotificationCategory.values.byName(json['category']),
      strategy: AlertGroupingStrategy.values.byName(json['strategy']),
      notificationIds: List<String>.from(json['notificationIds'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      totalCount: json['totalCount'],
      severityBreakdown: Map<NotificationSeverity, int>.from(
        (json['severityBreakdown'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(NotificationSeverity.values.byName(key), value),
        ) ?? {},
      ),
      isAcknowledged: json['isAcknowledged'] ?? false,
      acknowledgedBy: json['acknowledgedBy'],
      acknowledgedAt: json['acknowledgedAt'] != null ? DateTime.parse(json['acknowledgedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'maxSeverity': maxSeverity.name,
      'category': category.name,
      'strategy': strategy.name,
      'notificationIds': notificationIds,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'totalCount': totalCount,
      'severityBreakdown': severityBreakdown.map((key, value) => MapEntry(key.name, value)),
      'isAcknowledged': isAcknowledged,
      'acknowledgedBy': acknowledgedBy,
      'acknowledgedAt': acknowledgedAt?.toIso8601String(),
    };
  }
}

class NotificationRule {
  final String id;
  final String name;
  final String description;
  final List<String> conditions;
  final List<NotificationChannel> channels;
  final List<String> recipients;
  final NotificationSeverity minSeverity;
  final List<NotificationCategory> categories;
  final bool isEnabled;
  final Map<String, dynamic> channelSettings;
  final Duration? cooldownPeriod;
  final int? maxNotificationsPerHour;
  final DateTime createdAt;
  final DateTime lastModified;
  final String createdBy;
  final int triggerCount;
  final DateTime? lastTriggered;

  NotificationRule({
    required this.id,
    required this.name,
    required this.description,
    this.conditions = const [],
    this.channels = const [],
    this.recipients = const [],
    this.minSeverity = NotificationSeverity.info,
    this.categories = const [],
    this.isEnabled = true,
    this.channelSettings = const {},
    this.cooldownPeriod,
    this.maxNotificationsPerHour,
    required this.createdAt,
    required this.lastModified,
    required this.createdBy,
    this.triggerCount = 0,
    this.lastTriggered,
  });

  factory NotificationRule.fromJson(Map<String, dynamic> json) {
    return NotificationRule(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      conditions: List<String>.from(json['conditions'] ?? []),
      channels: (json['channels'] as List?)?.map((e) => NotificationChannel.values.byName(e)).toList() ?? [],
      recipients: List<String>.from(json['recipients'] ?? []),
      minSeverity: NotificationSeverity.values.byName(json['minSeverity'] ?? 'info'),
      categories: (json['categories'] as List?)?.map((e) => NotificationCategory.values.byName(e)).toList() ?? [],
      isEnabled: json['isEnabled'] ?? true,
      channelSettings: json['channelSettings'] ?? {},
      cooldownPeriod: json['cooldownPeriod'] != null ? Duration(seconds: json['cooldownPeriod']) : null,
      maxNotificationsPerHour: json['maxNotificationsPerHour'],
      createdAt: DateTime.parse(json['createdAt']),
      lastModified: DateTime.parse(json['lastModified']),
      createdBy: json['createdBy'],
      triggerCount: json['triggerCount'] ?? 0,
      lastTriggered: json['lastTriggered'] != null ? DateTime.parse(json['lastTriggered']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'conditions': conditions,
      'channels': channels.map((e) => e.name).toList(),
      'recipients': recipients,
      'minSeverity': minSeverity.name,
      'categories': categories.map((e) => e.name).toList(),
      'isEnabled': isEnabled,
      'channelSettings': channelSettings,
      'cooldownPeriod': cooldownPeriod?.inSeconds,
      'maxNotificationsPerHour': maxNotificationsPerHour,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'createdBy': createdBy,
      'triggerCount': triggerCount,
      'lastTriggered': lastTriggered?.toIso8601String(),
    };
  }
}

class NotificationTemplate {
  final String id;
  final String name;
  final String description;
  final NotificationCategory category;
  final String titleTemplate;
  final String messageTemplate;
  final Map<NotificationChannel, String> channelTemplates;
  final List<String> requiredVariables;
  final Map<String, dynamic> defaultVariables;
  final bool isSystem;
  final DateTime createdAt;
  final String createdBy;
  final int usageCount;

  NotificationTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.titleTemplate,
    required this.messageTemplate,
    this.channelTemplates = const {},
    this.requiredVariables = const [],
    this.defaultVariables = const {},
    this.isSystem = false,
    required this.createdAt,
    required this.createdBy,
    this.usageCount = 0,
  });

  factory NotificationTemplate.fromJson(Map<String, dynamic> json) {
    return NotificationTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: NotificationCategory.values.byName(json['category']),
      titleTemplate: json['titleTemplate'],
      messageTemplate: json['messageTemplate'],
      channelTemplates: Map<NotificationChannel, String>.from(
        (json['channelTemplates'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(NotificationChannel.values.byName(key), value),
        ) ?? {},
      ),
      requiredVariables: List<String>.from(json['requiredVariables'] ?? []),
      defaultVariables: json['defaultVariables'] ?? {},
      isSystem: json['isSystem'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: json['createdBy'],
      usageCount: json['usageCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'titleTemplate': titleTemplate,
      'messageTemplate': messageTemplate,
      'channelTemplates': channelTemplates.map((key, value) => MapEntry(key.name, value)),
      'requiredVariables': requiredVariables,
      'defaultVariables': defaultVariables,
      'isSystem': isSystem,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'usageCount': usageCount,
    };
  }
}

class NotificationPreference {
  final String id;
  final String userId;
  final NotificationCategory category;
  final List<NotificationChannel> enabledChannels;
  final NotificationSeverity minSeverity;
  final Map<String, bool> channelSettings;
  final List<String> mutedSources;
  final Duration? quietHoursStart;
  final Duration? quietHoursEnd;
  final bool enableGrouping;
  final AlertGroupingStrategy groupingStrategy;
  final Duration? groupingWindow;
  final DateTime createdAt;
  final DateTime lastModified;

  NotificationPreference({
    required this.id,
    required this.userId,
    required this.category,
    this.enabledChannels = const [],
    this.minSeverity = NotificationSeverity.info,
    this.channelSettings = const {},
    this.mutedSources = const [],
    this.quietHoursStart,
    this.quietHoursEnd,
    this.enableGrouping = true,
    this.groupingStrategy = AlertGroupingStrategy.by_type,
    this.groupingWindow,
    required this.createdAt,
    required this.lastModified,
  });

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      id: json['id'],
      userId: json['userId'],
      category: NotificationCategory.values.byName(json['category']),
      enabledChannels: (json['enabledChannels'] as List?)?.map((e) => NotificationChannel.values.byName(e)).toList() ?? [],
      minSeverity: NotificationSeverity.values.byName(json['minSeverity'] ?? 'info'),
      channelSettings: Map<String, bool>.from(json['channelSettings'] ?? {}),
      mutedSources: List<String>.from(json['mutedSources'] ?? []),
      quietHoursStart: json['quietHoursStart'] != null ? Duration(seconds: json['quietHoursStart']) : null,
      quietHoursEnd: json['quietHoursEnd'] != null ? Duration(seconds: json['quietHoursEnd']) : null,
      enableGrouping: json['enableGrouping'] ?? true,
      groupingStrategy: AlertGroupingStrategy.values.byName(json['groupingStrategy'] ?? 'by_type'),
      groupingWindow: json['groupingWindow'] != null ? Duration(seconds: json['groupingWindow']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      lastModified: DateTime.parse(json['lastModified']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'category': category.name,
      'enabledChannels': enabledChannels.map((e) => e.name).toList(),
      'minSeverity': minSeverity.name,
      'channelSettings': channelSettings,
      'mutedSources': mutedSources,
      'quietHoursStart': quietHoursStart?.inSeconds,
      'quietHoursEnd': quietHoursEnd?.inSeconds,
      'enableGrouping': enableGrouping,
      'groupingStrategy': groupingStrategy.name,
      'groupingWindow': groupingWindow?.inSeconds,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
    };
  }
}

class NotificationDeliveryLog {
  final String id;
  final String notificationId;
  final NotificationChannel channel;
  final String recipient;
  final NotificationStatus status;
  final DateTime attemptedAt;
  final DateTime? deliveredAt;
  final String? errorMessage;
  final Map<String, dynamic> metadata;
  final int retryCount;
  final String? externalId;

  NotificationDeliveryLog({
    required this.id,
    required this.notificationId,
    required this.channel,
    required this.recipient,
    required this.status,
    required this.attemptedAt,
    this.deliveredAt,
    this.errorMessage,
    this.metadata = const {},
    this.retryCount = 0,
    this.externalId,
  });

  factory NotificationDeliveryLog.fromJson(Map<String, dynamic> json) {
    return NotificationDeliveryLog(
      id: json['id'],
      notificationId: json['notificationId'],
      channel: NotificationChannel.values.byName(json['channel']),
      recipient: json['recipient'],
      status: NotificationStatus.values.byName(json['status']),
      attemptedAt: DateTime.parse(json['attemptedAt']),
      deliveredAt: json['deliveredAt'] != null ? DateTime.parse(json['deliveredAt']) : null,
      errorMessage: json['errorMessage'],
      metadata: json['metadata'] ?? {},
      retryCount: json['retryCount'] ?? 0,
      externalId: json['externalId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'notificationId': notificationId,
      'channel': channel.name,
      'recipient': recipient,
      'status': status.name,
      'attemptedAt': attemptedAt.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'errorMessage': errorMessage,
      'metadata': metadata,
      'retryCount': retryCount,
      'externalId': externalId,
    };
  }
}

class NotificationAnalytics {
  final String id;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalNotifications;
  final int deliveredNotifications;
  final int failedNotifications;
  final double deliveryRate;
  final Map<NotificationChannel, int> channelBreakdown;
  final Map<NotificationSeverity, int> severityBreakdown;
  final Map<NotificationCategory, int> categoryBreakdown;
  final Map<String, int> topSources;
  final Map<String, int> topRecipients;
  final double avgDeliveryTime;
  final List<String> commonFailureReasons;
  final DateTime generatedAt;

  NotificationAnalytics({
    required this.id,
    required this.periodStart,
    required this.periodEnd,
    required this.totalNotifications,
    required this.deliveredNotifications,
    required this.failedNotifications,
    required this.deliveryRate,
    this.channelBreakdown = const {},
    this.severityBreakdown = const {},
    this.categoryBreakdown = const {},
    this.topSources = const {},
    this.topRecipients = const {},
    required this.avgDeliveryTime,
    this.commonFailureReasons = const [],
    required this.generatedAt,
  });

  factory NotificationAnalytics.fromJson(Map<String, dynamic> json) {
    return NotificationAnalytics(
      id: json['id'],
      periodStart: DateTime.parse(json['periodStart']),
      periodEnd: DateTime.parse(json['periodEnd']),
      totalNotifications: json['totalNotifications'],
      deliveredNotifications: json['deliveredNotifications'],
      failedNotifications: json['failedNotifications'],
      deliveryRate: json['deliveryRate'].toDouble(),
      channelBreakdown: Map<NotificationChannel, int>.from(
        (json['channelBreakdown'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(NotificationChannel.values.byName(key), value),
        ) ?? {},
      ),
      severityBreakdown: Map<NotificationSeverity, int>.from(
        (json['severityBreakdown'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(NotificationSeverity.values.byName(key), value),
        ) ?? {},
      ),
      categoryBreakdown: Map<NotificationCategory, int>.from(
        (json['categoryBreakdown'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(NotificationCategory.values.byName(key), value),
        ) ?? {},
      ),
      topSources: Map<String, int>.from(json['topSources'] ?? {}),
      topRecipients: Map<String, int>.from(json['topRecipients'] ?? {}),
      avgDeliveryTime: json['avgDeliveryTime'].toDouble(),
      commonFailureReasons: List<String>.from(json['commonFailureReasons'] ?? []),
      generatedAt: DateTime.parse(json['generatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'totalNotifications': totalNotifications,
      'deliveredNotifications': deliveredNotifications,
      'failedNotifications': failedNotifications,
      'deliveryRate': deliveryRate,
      'channelBreakdown': channelBreakdown.map((key, value) => MapEntry(key.name, value)),
      'severityBreakdown': severityBreakdown.map((key, value) => MapEntry(key.name, value)),
      'categoryBreakdown': categoryBreakdown.map((key, value) => MapEntry(key.name, value)),
      'topSources': topSources,
      'topRecipients': topRecipients,
      'avgDeliveryTime': avgDeliveryTime,
      'commonFailureReasons': commonFailureReasons,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}

// Additional models for backend compatibility
class NotificationMessage {
  final String id;
  final String title;
  final String message;
  final NotificationSeverity severity;
  final NotificationCategory category;
  final DateTime createdAt;
  final NotificationStatus status;
  final Map<String, dynamic> metadata;
  final List<String> recipients;
  final List<NotificationChannel> channels;

  NotificationMessage({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.category,
    required this.createdAt,
    this.status = NotificationStatus.pending,
    this.metadata = const {},
    this.recipients = const [],
    this.channels = const [],
  });

  factory NotificationMessage.fromJson(Map<String, dynamic> json) {
    return NotificationMessage(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      severity: NotificationSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => NotificationSeverity.info,
      ),
      category: NotificationCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => NotificationCategory.system,
      ),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      status: NotificationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => NotificationStatus.pending,
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      recipients: List<String>.from(json['recipients'] ?? []),
      channels: (json['channels'] as List?)?.map((e) => 
        NotificationChannel.values.firstWhere(
          (c) => c.name == e,
          orElse: () => NotificationChannel.in_app,
        )
      ).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'severity': severity.name,
      'category': category.name,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'metadata': metadata,
      'recipients': recipients,
      'channels': channels.map((e) => e.name).toList(),
    };
  }
}

class NotificationPreferences {
  final String userId;
  final Map<NotificationCategory, bool> categoryEnabled;
  final Map<NotificationChannel, bool> channelEnabled;
  final NotificationSeverity minSeverity;
  final bool enableGrouping;
  final Duration? quietHoursStart;
  final Duration? quietHoursEnd;
  final List<String> mutedSources;
  final DateTime lastModified;

  NotificationPreferences({
    required this.userId,
    this.categoryEnabled = const {},
    this.channelEnabled = const {},
    this.minSeverity = NotificationSeverity.info,
    this.enableGrouping = true,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.mutedSources = const [],
    required this.lastModified,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      userId: json['userId'] ?? '',
      categoryEnabled: Map<NotificationCategory, bool>.from(
        (json['categoryEnabled'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(
            NotificationCategory.values.firstWhere(
              (e) => e.name == key,
              orElse: () => NotificationCategory.system,
            ),
            value as bool,
          ),
        ) ?? {},
      ),
      channelEnabled: Map<NotificationChannel, bool>.from(
        (json['channelEnabled'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(
            NotificationChannel.values.firstWhere(
              (e) => e.name == key,
              orElse: () => NotificationChannel.in_app,
            ),
            value as bool,
          ),
        ) ?? {},
      ),
      minSeverity: NotificationSeverity.values.firstWhere(
        (e) => e.name == json['minSeverity'],
        orElse: () => NotificationSeverity.info,
      ),
      enableGrouping: json['enableGrouping'] ?? true,
      quietHoursStart: json['quietHoursStart'] != null 
        ? Duration(seconds: json['quietHoursStart']) 
        : null,
      quietHoursEnd: json['quietHoursEnd'] != null 
        ? Duration(seconds: json['quietHoursEnd']) 
        : null,
      mutedSources: List<String>.from(json['mutedSources'] ?? []),
      lastModified: DateTime.tryParse(json['lastModified'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'categoryEnabled': categoryEnabled.map((key, value) => MapEntry(key.name, value)),
      'channelEnabled': channelEnabled.map((key, value) => MapEntry(key.name, value)),
      'minSeverity': minSeverity.name,
      'enableGrouping': enableGrouping,
      'quietHoursStart': quietHoursStart?.inSeconds,
      'quietHoursEnd': quietHoursEnd?.inSeconds,
      'mutedSources': mutedSources,
      'lastModified': lastModified.toIso8601String(),
    };
  }
}
