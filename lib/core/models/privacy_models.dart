enum DataCategory { 
  personal_info, 
  contact_info, 
  authentication, 
  usage_analytics, 
  device_info, 
  location_data, 
  biometric_data, 
  financial_data,
  health_data,
  behavioral_data
}

enum ConsentStatus { granted, denied, pending, expired, withdrawn }
enum DataProcessingPurpose { 
  authentication, 
  security, 
  analytics, 
  marketing, 
  personalization, 
  legal_compliance, 
  fraud_prevention,
  service_improvement,
  communication
}

enum RetentionPeriod { 
  session_only, 
  days_30, 
  days_90, 
  months_6, 
  year_1, 
  years_3, 
  years_7, 
  indefinite 
}

class DataCollectionItem {
  final String id;
  final String name;
  final String description;
  final DataCategory category;
  final List<DataProcessingPurpose> purposes;
  final bool isRequired;
  final bool isCollected;
  final DateTime? collectionDate;
  final RetentionPeriod retentionPeriod;
  final List<String> thirdPartySharing;
  final Map<String, dynamic> metadata;

  DataCollectionItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.purposes = const [],
    this.isRequired = false,
    this.isCollected = false,
    this.collectionDate,
    this.retentionPeriod = RetentionPeriod.year_1,
    this.thirdPartySharing = const [],
    this.metadata = const {},
  });

  factory DataCollectionItem.fromJson(Map<String, dynamic> json) {
    return DataCollectionItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: DataCategory.values.byName(json['category']),
      purposes: (json['purposes'] as List?)?.map((e) => DataProcessingPurpose.values.byName(e)).toList() ?? [],
      isRequired: json['isRequired'] ?? false,
      isCollected: json['isCollected'] ?? false,
      collectionDate: json['collectionDate'] != null ? DateTime.parse(json['collectionDate']) : null,
      retentionPeriod: RetentionPeriod.values.byName(json['retentionPeriod'] ?? 'year_1'),
      thirdPartySharing: List<String>.from(json['thirdPartySharing'] ?? []),
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'purposes': purposes.map((e) => e.name).toList(),
      'isRequired': isRequired,
      'isCollected': isCollected,
      'collectionDate': collectionDate?.toIso8601String(),
      'retentionPeriod': retentionPeriod.name,
      'thirdPartySharing': thirdPartySharing,
      'metadata': metadata,
    };
  }
}

class ConsentRecord {
  final String id;
  final String userId;
  final String dataItemId;
  final ConsentStatus status;
  final DateTime grantedAt;
  final DateTime? expiresAt;
  final DateTime? withdrawnAt;
  final String consentMethod;
  final String ipAddress;
  final String userAgent;
  final Map<String, dynamic> context;

  ConsentRecord({
    required this.id,
    required this.userId,
    required this.dataItemId,
    required this.status,
    required this.grantedAt,
    this.expiresAt,
    this.withdrawnAt,
    required this.consentMethod,
    required this.ipAddress,
    required this.userAgent,
    this.context = const {},
  });

  factory ConsentRecord.fromJson(Map<String, dynamic> json) {
    return ConsentRecord(
      id: json['id'],
      userId: json['userId'],
      dataItemId: json['dataItemId'],
      status: ConsentStatus.values.byName(json['status']),
      grantedAt: DateTime.parse(json['grantedAt']),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      withdrawnAt: json['withdrawnAt'] != null ? DateTime.parse(json['withdrawnAt']) : null,
      consentMethod: json['consentMethod'],
      ipAddress: json['ipAddress'],
      userAgent: json['userAgent'],
      context: json['context'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'dataItemId': dataItemId,
      'status': status.name,
      'grantedAt': grantedAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'withdrawnAt': withdrawnAt?.toIso8601String(),
      'consentMethod': consentMethod,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'context': context,
    };
  }

  bool get isActive => status == ConsentStatus.granted && 
                      (expiresAt == null || DateTime.now().isBefore(expiresAt!));
}

class DataExportRequest {
  final String id;
  final String userId;
  final DateTime requestedAt;
  final String status;
  final List<DataCategory> categories;
  final String format;
  final DateTime? completedAt;
  final String? downloadUrl;
  final DateTime? expiresAt;
  final Map<String, dynamic> metadata;

  DataExportRequest({
    required this.id,
    required this.userId,
    required this.requestedAt,
    required this.status,
    this.categories = const [],
    this.format = 'json',
    this.completedAt,
    this.downloadUrl,
    this.expiresAt,
    this.metadata = const {},
  });

  factory DataExportRequest.fromJson(Map<String, dynamic> json) {
    return DataExportRequest(
      id: json['id'],
      userId: json['userId'],
      requestedAt: DateTime.parse(json['requestedAt']),
      status: json['status'],
      categories: (json['categories'] as List?)?.map((e) => DataCategory.values.byName(e)).toList() ?? [],
      format: json['format'] ?? 'json',
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      downloadUrl: json['downloadUrl'],
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'requestedAt': requestedAt.toIso8601String(),
      'status': status,
      'categories': categories.map((e) => e.name).toList(),
      'format': format,
      'completedAt': completedAt?.toIso8601String(),
      'downloadUrl': downloadUrl,
      'expiresAt': expiresAt?.toIso8601String(),
      'metadata': metadata,
    };
  }
}

class DataDeletionRequest {
  final String id;
  final String userId;
  final DateTime requestedAt;
  final String status;
  final List<DataCategory> categories;
  final String reason;
  final DateTime? scheduledFor;
  final DateTime? completedAt;
  final Map<String, dynamic> metadata;

  DataDeletionRequest({
    required this.id,
    required this.userId,
    required this.requestedAt,
    required this.status,
    this.categories = const [],
    required this.reason,
    this.scheduledFor,
    this.completedAt,
    this.metadata = const {},
  });

  factory DataDeletionRequest.fromJson(Map<String, dynamic> json) {
    return DataDeletionRequest(
      id: json['id'],
      userId: json['userId'],
      requestedAt: DateTime.parse(json['requestedAt']),
      status: json['status'],
      categories: (json['categories'] as List?)?.map((e) => DataCategory.values.byName(e)).toList() ?? [],
      reason: json['reason'],
      scheduledFor: json['scheduledFor'] != null ? DateTime.parse(json['scheduledFor']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'requestedAt': requestedAt.toIso8601String(),
      'status': status,
      'categories': categories.map((e) => e.name).toList(),
      'reason': reason,
      'scheduledFor': scheduledFor?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }
}

class PrivacySettings {
  final String userId;
  final bool allowAnalytics;
  final bool allowMarketing;
  final bool allowPersonalization;
  final bool allowThirdPartySharing;
  final bool allowLocationTracking;
  final bool allowBiometricData;
  final Map<DataCategory, bool> categoryPreferences;
  final Map<DataProcessingPurpose, bool> purposePreferences;
  final DateTime lastUpdated;

  PrivacySettings({
    required this.userId,
    this.allowAnalytics = true,
    this.allowMarketing = false,
    this.allowPersonalization = true,
    this.allowThirdPartySharing = false,
    this.allowLocationTracking = false,
    this.allowBiometricData = false,
    this.categoryPreferences = const {},
    this.purposePreferences = const {},
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    final categoryPrefs = <DataCategory, bool>{};
    if (json['categoryPreferences'] != null) {
      (json['categoryPreferences'] as Map<String, dynamic>).forEach((key, value) {
        categoryPrefs[DataCategory.values.byName(key)] = value;
      });
    }

    final purposePrefs = <DataProcessingPurpose, bool>{};
    if (json['purposePreferences'] != null) {
      (json['purposePreferences'] as Map<String, dynamic>).forEach((key, value) {
        purposePrefs[DataProcessingPurpose.values.byName(key)] = value;
      });
    }

    return PrivacySettings(
      userId: json['userId'],
      allowAnalytics: json['allowAnalytics'] ?? true,
      allowMarketing: json['allowMarketing'] ?? false,
      allowPersonalization: json['allowPersonalization'] ?? true,
      allowThirdPartySharing: json['allowThirdPartySharing'] ?? false,
      allowLocationTracking: json['allowLocationTracking'] ?? false,
      allowBiometricData: json['allowBiometricData'] ?? false,
      categoryPreferences: categoryPrefs,
      purposePreferences: purposePrefs,
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    final categoryPrefs = <String, bool>{};
    categoryPreferences.forEach((key, value) {
      categoryPrefs[key.name] = value;
    });

    final purposePrefs = <String, bool>{};
    purposePreferences.forEach((key, value) {
      purposePrefs[key.name] = value;
    });

    return {
      'userId': userId,
      'allowAnalytics': allowAnalytics,
      'allowMarketing': allowMarketing,
      'allowPersonalization': allowPersonalization,
      'allowThirdPartySharing': allowThirdPartySharing,
      'allowLocationTracking': allowLocationTracking,
      'allowBiometricData': allowBiometricData,
      'categoryPreferences': categoryPrefs,
      'purposePreferences': purposePrefs,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

class DataProcessingActivity {
  final String id;
  final String userId;
  final String dataItemId;
  final DataProcessingPurpose purpose;
  final DateTime processedAt;
  final String processingMethod;
  final Map<String, dynamic> details;
  final bool wasConsentRequired;
  final bool hadValidConsent;

  DataProcessingActivity({
    required this.id,
    required this.userId,
    required this.dataItemId,
    required this.purpose,
    required this.processedAt,
    required this.processingMethod,
    this.details = const {},
    this.wasConsentRequired = true,
    this.hadValidConsent = false,
  });

  factory DataProcessingActivity.fromJson(Map<String, dynamic> json) {
    return DataProcessingActivity(
      id: json['id'],
      userId: json['userId'],
      dataItemId: json['dataItemId'],
      purpose: DataProcessingPurpose.values.byName(json['purpose']),
      processedAt: DateTime.parse(json['processedAt']),
      processingMethod: json['processingMethod'],
      details: json['details'] ?? {},
      wasConsentRequired: json['wasConsentRequired'] ?? true,
      hadValidConsent: json['hadValidConsent'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'dataItemId': dataItemId,
      'purpose': purpose.name,
      'processedAt': processedAt.toIso8601String(),
      'processingMethod': processingMethod,
      'details': details,
      'wasConsentRequired': wasConsentRequired,
      'hadValidConsent': hadValidConsent,
    };
  }
}

class PrivacyDashboardData {
  final String userId;
  final int totalDataItems;
  final int activeConsents;
  final int expiredConsents;
  final int withdrawnConsents;
  final Map<DataCategory, int> dataByCategory;
  final Map<DataProcessingPurpose, int> processingByPurpose;
  final List<DataExportRequest> recentExports;
  final List<DataDeletionRequest> recentDeletions;
  final List<DataProcessingActivity> recentActivity;
  final DateTime lastUpdated;

  PrivacyDashboardData({
    required this.userId,
    this.totalDataItems = 0,
    this.activeConsents = 0,
    this.expiredConsents = 0,
    this.withdrawnConsents = 0,
    this.dataByCategory = const {},
    this.processingByPurpose = const {},
    this.recentExports = const [],
    this.recentDeletions = const [],
    this.recentActivity = const [],
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory PrivacyDashboardData.fromJson(Map<String, dynamic> json) {
    final dataByCategory = <DataCategory, int>{};
    if (json['dataByCategory'] != null) {
      (json['dataByCategory'] as Map<String, dynamic>).forEach((key, value) {
        dataByCategory[DataCategory.values.byName(key)] = value;
      });
    }

    final processingByPurpose = <DataProcessingPurpose, int>{};
    if (json['processingByPurpose'] != null) {
      (json['processingByPurpose'] as Map<String, dynamic>).forEach((key, value) {
        processingByPurpose[DataProcessingPurpose.values.byName(key)] = value;
      });
    }

    return PrivacyDashboardData(
      userId: json['userId'],
      totalDataItems: json['totalDataItems'] ?? 0,
      activeConsents: json['activeConsents'] ?? 0,
      expiredConsents: json['expiredConsents'] ?? 0,
      withdrawnConsents: json['withdrawnConsents'] ?? 0,
      dataByCategory: dataByCategory,
      processingByPurpose: processingByPurpose,
      recentExports: (json['recentExports'] as List?)?.map((e) => DataExportRequest.fromJson(e)).toList() ?? [],
      recentDeletions: (json['recentDeletions'] as List?)?.map((e) => DataDeletionRequest.fromJson(e)).toList() ?? [],
      recentActivity: (json['recentActivity'] as List?)?.map((e) => DataProcessingActivity.fromJson(e)).toList() ?? [],
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    final dataByCategoryMap = <String, int>{};
    dataByCategory.forEach((key, value) {
      dataByCategoryMap[key.name] = value;
    });

    final processingByPurposeMap = <String, int>{};
    processingByPurpose.forEach((key, value) {
      processingByPurposeMap[key.name] = value;
    });

    return {
      'userId': userId,
      'totalDataItems': totalDataItems,
      'activeConsents': activeConsents,
      'expiredConsents': expiredConsents,
      'withdrawnConsents': withdrawnConsents,
      'dataByCategory': dataByCategoryMap,
      'processingByPurpose': processingByPurposeMap,
      'recentExports': recentExports.map((e) => e.toJson()).toList(),
      'recentDeletions': recentDeletions.map((e) => e.toJson()).toList(),
      'recentActivity': recentActivity.map((e) => e.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

class ComplianceReport {
  final String id;
  final String organizationId;
  final String reportType;
  final DateTime generatedAt;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Map<String, dynamic> metrics;
  final List<String> complianceIssues;
  final List<String> recommendations;
  final String status;

  ComplianceReport({
    required this.id,
    required this.organizationId,
    required this.reportType,
    required this.generatedAt,
    required this.periodStart,
    required this.periodEnd,
    this.metrics = const {},
    this.complianceIssues = const [],
    this.recommendations = const [],
    required this.status,
  });

  factory ComplianceReport.fromJson(Map<String, dynamic> json) {
    return ComplianceReport(
      id: json['id'],
      organizationId: json['organizationId'],
      reportType: json['reportType'],
      generatedAt: DateTime.parse(json['generatedAt']),
      periodStart: DateTime.parse(json['periodStart']),
      periodEnd: DateTime.parse(json['periodEnd']),
      metrics: json['metrics'] ?? {},
      complianceIssues: List<String>.from(json['complianceIssues'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizationId': organizationId,
      'reportType': reportType,
      'generatedAt': generatedAt.toIso8601String(),
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'metrics': metrics,
      'complianceIssues': complianceIssues,
      'recommendations': recommendations,
      'status': status,
    };
  }
}
