import 'dart:async';
import 'dart:math';
import 'dart:developer' as developer;
import '../models/privacy_models.dart';

class PrivacyDashboardService {
  static final PrivacyDashboardService _instance = PrivacyDashboardService._internal();
  factory PrivacyDashboardService() => _instance;
  PrivacyDashboardService._internal();

  final Map<String, PrivacySettings> _userSettings = {};
  final Map<String, List<ConsentRecord>> _consentRecords = {};
  final Map<String, List<DataCollectionItem>> _dataItems = {};
  final Map<String, List<DataExportRequest>> _exportRequests = {};
  final Map<String, List<DataDeletionRequest>> _deletionRequests = {};
  final Map<String, List<DataProcessingActivity>> _processingActivities = {};

  final StreamController<PrivacyDashboardData> _dashboardController = StreamController<PrivacyDashboardData>.broadcast();
  final StreamController<List<ConsentRecord>> _consentController = StreamController<List<ConsentRecord>>.broadcast();
  final StreamController<List<DataExportRequest>> _exportController = StreamController<List<DataExportRequest>>.broadcast();
  final StreamController<List<DataDeletionRequest>> _deletionController = StreamController<List<DataDeletionRequest>>.broadcast();

  Stream<PrivacyDashboardData> get dashboardStream => _dashboardController.stream;
  Stream<List<ConsentRecord>> get consentStream => _consentController.stream;
  Stream<List<DataExportRequest>> get exportStream => _exportController.stream;
  Stream<List<DataDeletionRequest>> get deletionStream => _deletionController.stream;

  final Random _random = Random();
  Timer? _dataUpdateTimer;

  Future<void> initialize() async {
    developer.log('Initializing Privacy Dashboard Service', name: 'PrivacyDashboardService');
    
    _generateMockData();
    _startDataUpdates();
    
    developer.log('Privacy Dashboard Service initialized', name: 'PrivacyDashboardService');
  }

  void _startDataUpdates() {
    _dataUpdateTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _updateProcessingActivities();
    });
  }

  void _generateMockData() {
    final userId = 'user_123';
    
    // Generate privacy settings
    _userSettings[userId] = PrivacySettings(
      userId: userId,
      allowAnalytics: true,
      allowMarketing: false,
      allowPersonalization: true,
      allowThirdPartySharing: false,
      allowLocationTracking: false,
      allowBiometricData: true,
      categoryPreferences: {
        DataCategory.personal_info: true,
        DataCategory.contact_info: true,
        DataCategory.authentication: true,
        DataCategory.usage_analytics: true,
        DataCategory.device_info: false,
        DataCategory.location_data: false,
        DataCategory.biometric_data: true,
        DataCategory.financial_data: false,
      },
      purposePreferences: {
        DataProcessingPurpose.authentication: true,
        DataProcessingPurpose.security: true,
        DataProcessingPurpose.analytics: true,
        DataProcessingPurpose.marketing: false,
        DataProcessingPurpose.personalization: true,
        DataProcessingPurpose.legal_compliance: true,
        DataProcessingPurpose.fraud_prevention: true,
      },
    );

    // Generate data collection items
    _dataItems[userId] = [
      DataCollectionItem(
        id: 'item_1',
        name: 'Email Address',
        description: 'Your email address for account identification and communication',
        category: DataCategory.contact_info,
        purposes: [DataProcessingPurpose.authentication, DataProcessingPurpose.communication],
        isRequired: true,
        isCollected: true,
        collectionDate: DateTime.now().subtract(const Duration(days: 30)),
        retentionPeriod: RetentionPeriod.years_7,
      ),
      DataCollectionItem(
        id: 'item_2',
        name: 'Password Hash',
        description: 'Encrypted version of your password for authentication',
        category: DataCategory.authentication,
        purposes: [DataProcessingPurpose.authentication, DataProcessingPurpose.security],
        isRequired: true,
        isCollected: true,
        collectionDate: DateTime.now().subtract(const Duration(days: 30)),
        retentionPeriod: RetentionPeriod.years_7,
      ),
      DataCollectionItem(
        id: 'item_3',
        name: 'Usage Analytics',
        description: 'Information about how you use our application',
        category: DataCategory.usage_analytics,
        purposes: [DataProcessingPurpose.analytics, DataProcessingPurpose.service_improvement],
        isRequired: false,
        isCollected: true,
        collectionDate: DateTime.now().subtract(const Duration(days: 25)),
        retentionPeriod: RetentionPeriod.year_1,
      ),
      DataCollectionItem(
        id: 'item_4',
        name: 'Device Information',
        description: 'Information about your device and browser',
        category: DataCategory.device_info,
        purposes: [DataProcessingPurpose.security, DataProcessingPurpose.fraud_prevention],
        isRequired: false,
        isCollected: false,
        retentionPeriod: RetentionPeriod.months_6,
      ),
      DataCollectionItem(
        id: 'item_5',
        name: 'Biometric Data',
        description: 'Fingerprint and face recognition data for secure authentication',
        category: DataCategory.biometric_data,
        purposes: [DataProcessingPurpose.authentication, DataProcessingPurpose.security],
        isRequired: false,
        isCollected: true,
        collectionDate: DateTime.now().subtract(const Duration(days: 20)),
        retentionPeriod: RetentionPeriod.years_3,
      ),
      DataCollectionItem(
        id: 'item_6',
        name: 'Location Data',
        description: 'Your approximate location for security and fraud prevention',
        category: DataCategory.location_data,
        purposes: [DataProcessingPurpose.security, DataProcessingPurpose.fraud_prevention],
        isRequired: false,
        isCollected: false,
        retentionPeriod: RetentionPeriod.days_90,
      ),
    ];

    // Generate consent records
    _consentRecords[userId] = [];
    for (final item in _dataItems[userId]!) {
      if (item.isCollected) {
        _consentRecords[userId]!.add(ConsentRecord(
          id: 'consent_${item.id}',
          userId: userId,
          dataItemId: item.id,
          status: ConsentStatus.granted,
          grantedAt: item.collectionDate ?? DateTime.now(),
          expiresAt: _getExpirationDate(item.retentionPeriod),
          consentMethod: item.isRequired ? 'registration' : 'explicit_consent',
          ipAddress: '192.168.1.${_random.nextInt(255)}',
          userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          context: {
            'page': item.isRequired ? '/register' : '/privacy-settings',
            'version': '1.0.0',
          },
        ));
      }
    }

    // Generate export requests
    _exportRequests[userId] = [
      DataExportRequest(
        id: 'export_1',
        userId: userId,
        requestedAt: DateTime.now().subtract(const Duration(days: 5)),
        status: 'completed',
        categories: [DataCategory.personal_info, DataCategory.contact_info],
        format: 'json',
        completedAt: DateTime.now().subtract(const Duration(days: 4)),
        downloadUrl: 'https://example.com/exports/user_data_export_1.json',
        expiresAt: DateTime.now().add(const Duration(days: 26)),
      ),
      DataExportRequest(
        id: 'export_2',
        userId: userId,
        requestedAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'processing',
        categories: [DataCategory.usage_analytics, DataCategory.device_info],
        format: 'csv',
      ),
    ];

    // Generate deletion requests
    _deletionRequests[userId] = [
      DataDeletionRequest(
        id: 'deletion_1',
        userId: userId,
        requestedAt: DateTime.now().subtract(const Duration(days: 10)),
        status: 'completed',
        categories: [DataCategory.location_data],
        reason: 'No longer needed',
        scheduledFor: DateTime.now().subtract(const Duration(days: 8)),
        completedAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
    ];

    // Generate processing activities
    _processingActivities[userId] = [];
    _generateProcessingActivities(userId);

    // Emit initial data
    _emitDashboardData(userId);
  }

  void _generateProcessingActivities(String userId) {
    final activities = <DataProcessingActivity>[];
    final items = _dataItems[userId] ?? [];
    
    for (int i = 0; i < 20; i++) {
      final item = items[_random.nextInt(items.length)];
      final purpose = item.purposes[_random.nextInt(item.purposes.length)];
      
      activities.add(DataProcessingActivity(
        id: 'activity_${i + 1}',
        userId: userId,
        dataItemId: item.id,
        purpose: purpose,
        processedAt: DateTime.now().subtract(Duration(hours: _random.nextInt(168))), // Last week
        processingMethod: _getProcessingMethod(purpose),
        details: {
          'dataSize': '${_random.nextInt(1000)} bytes',
          'processingTime': '${_random.nextInt(100)} ms',
        },
        wasConsentRequired: !item.isRequired,
        hadValidConsent: item.isCollected,
      ));
    }
    
    _processingActivities[userId] = activities;
  }

  String _getProcessingMethod(DataProcessingPurpose purpose) {
    switch (purpose) {
      case DataProcessingPurpose.authentication:
        return 'Authentication Service';
      case DataProcessingPurpose.security:
        return 'Security Monitor';
      case DataProcessingPurpose.analytics:
        return 'Analytics Engine';
      case DataProcessingPurpose.marketing:
        return 'Marketing Platform';
      case DataProcessingPurpose.personalization:
        return 'Personalization Service';
      case DataProcessingPurpose.legal_compliance:
        return 'Compliance System';
      case DataProcessingPurpose.fraud_prevention:
        return 'Fraud Detection';
      case DataProcessingPurpose.service_improvement:
        return 'ML Analysis';
      case DataProcessingPurpose.communication:
        return 'Email Service';
    }
  }

  DateTime? _getExpirationDate(RetentionPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case RetentionPeriod.session_only:
        return now.add(const Duration(hours: 1));
      case RetentionPeriod.days_30:
        return now.add(const Duration(days: 30));
      case RetentionPeriod.days_90:
        return now.add(const Duration(days: 90));
      case RetentionPeriod.months_6:
        return now.add(const Duration(days: 180));
      case RetentionPeriod.year_1:
        return now.add(const Duration(days: 365));
      case RetentionPeriod.years_3:
        return now.add(const Duration(days: 1095));
      case RetentionPeriod.years_7:
        return now.add(const Duration(days: 2555));
      case RetentionPeriod.indefinite:
        return null;
    }
  }

  void _updateProcessingActivities() {
    _userSettings.keys.forEach((userId) {
      // Add new processing activity
      final items = _dataItems[userId] ?? [];
      if (items.isNotEmpty && _random.nextDouble() < 0.3) {
        final item = items[_random.nextInt(items.length)];
        if (item.purposes.isNotEmpty) {
          final purpose = item.purposes[_random.nextInt(item.purposes.length)];
          
          final activity = DataProcessingActivity(
            id: 'activity_${DateTime.now().millisecondsSinceEpoch}',
            userId: userId,
            dataItemId: item.id,
            purpose: purpose,
            processedAt: DateTime.now(),
            processingMethod: _getProcessingMethod(purpose),
            details: {
              'dataSize': '${_random.nextInt(1000)} bytes',
              'processingTime': '${_random.nextInt(100)} ms',
            },
            wasConsentRequired: !item.isRequired,
            hadValidConsent: item.isCollected,
          );
          
          _processingActivities[userId]!.insert(0, activity);
          
          // Keep only last 50 activities
          if (_processingActivities[userId]!.length > 50) {
            _processingActivities[userId]!.removeLast();
          }
        }
      }
      
      _emitDashboardData(userId);
    });
  }

  void _emitDashboardData(String userId) {
    final consents = _consentRecords[userId] ?? [];
    final items = _dataItems[userId] ?? [];
    final exports = _exportRequests[userId] ?? [];
    final deletions = _deletionRequests[userId] ?? [];
    final activities = _processingActivities[userId] ?? [];

    final activeConsents = consents.where((c) => c.isActive).length;
    final expiredConsents = consents.where((c) => c.status == ConsentStatus.expired).length;
    final withdrawnConsents = consents.where((c) => c.status == ConsentStatus.withdrawn).length;

    final dataByCategory = <DataCategory, int>{};
    for (final item in items) {
      dataByCategory[item.category] = (dataByCategory[item.category] ?? 0) + 1;
    }

    final processingByPurpose = <DataProcessingPurpose, int>{};
    for (final activity in activities.take(100)) {
      processingByPurpose[activity.purpose] = (processingByPurpose[activity.purpose] ?? 0) + 1;
    }

    final dashboardData = PrivacyDashboardData(
      userId: userId,
      totalDataItems: items.length,
      activeConsents: activeConsents,
      expiredConsents: expiredConsents,
      withdrawnConsents: withdrawnConsents,
      dataByCategory: dataByCategory,
      processingByPurpose: processingByPurpose,
      recentExports: exports.take(5).toList(),
      recentDeletions: deletions.take(5).toList(),
      recentActivity: activities.take(10).toList(),
    );

    _dashboardController.add(dashboardData);
  }

  // API Methods
  Future<PrivacyDashboardData> getDashboardData(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!_userSettings.containsKey(userId)) {
      _generateMockData();
    }
    
    final consents = _consentRecords[userId] ?? [];
    final items = _dataItems[userId] ?? [];
    final exports = _exportRequests[userId] ?? [];
    final deletions = _deletionRequests[userId] ?? [];
    final activities = _processingActivities[userId] ?? [];

    final activeConsents = consents.where((c) => c.isActive).length;
    final expiredConsents = consents.where((c) => c.status == ConsentStatus.expired).length;
    final withdrawnConsents = consents.where((c) => c.status == ConsentStatus.withdrawn).length;

    final dataByCategory = <DataCategory, int>{};
    for (final item in items) {
      dataByCategory[item.category] = (dataByCategory[item.category] ?? 0) + 1;
    }

    final processingByPurpose = <DataProcessingPurpose, int>{};
    for (final activity in activities.take(100)) {
      processingByPurpose[activity.purpose] = (processingByPurpose[activity.purpose] ?? 0) + 1;
    }

    return PrivacyDashboardData(
      userId: userId,
      totalDataItems: items.length,
      activeConsents: activeConsents,
      expiredConsents: expiredConsents,
      withdrawnConsents: withdrawnConsents,
      dataByCategory: dataByCategory,
      processingByPurpose: processingByPurpose,
      recentExports: exports.take(5).toList(),
      recentDeletions: deletions.take(5).toList(),
      recentActivity: activities.take(10).toList(),
    );
  }

  Future<PrivacySettings> getPrivacySettings(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    return _userSettings[userId] ?? PrivacySettings(userId: userId);
  }

  Future<void> updatePrivacySettings(PrivacySettings settings) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    _userSettings[settings.userId] = settings;
    _emitDashboardData(settings.userId);
  }

  Future<List<DataCollectionItem>> getDataItems(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    return _dataItems[userId] ?? [];
  }

  Future<List<ConsentRecord>> getConsentHistory(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    return _consentRecords[userId] ?? [];
  }

  Future<ConsentRecord> grantConsent(String userId, String dataItemId, String method) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final consent = ConsentRecord(
      id: 'consent_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      dataItemId: dataItemId,
      status: ConsentStatus.granted,
      grantedAt: DateTime.now(),
      consentMethod: method,
      ipAddress: '192.168.1.${_random.nextInt(255)}',
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    );
    
    _consentRecords.putIfAbsent(userId, () => []).add(consent);
    _consentController.add(_consentRecords[userId]!);
    _emitDashboardData(userId);
    
    return consent;
  }

  Future<void> withdrawConsent(String userId, String consentId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final consents = _consentRecords[userId] ?? [];
    final index = consents.indexWhere((c) => c.id == consentId);
    
    if (index != -1) {
      final consent = consents[index];
      consents[index] = ConsentRecord(
        id: consent.id,
        userId: consent.userId,
        dataItemId: consent.dataItemId,
        status: ConsentStatus.withdrawn,
        grantedAt: consent.grantedAt,
        expiresAt: consent.expiresAt,
        withdrawnAt: DateTime.now(),
        consentMethod: consent.consentMethod,
        ipAddress: consent.ipAddress,
        userAgent: consent.userAgent,
        context: consent.context,
      );
      
      _consentController.add(consents);
      _emitDashboardData(userId);
    }
  }

  Future<DataExportRequest> requestDataExport(String userId, List<DataCategory> categories, String format) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final request = DataExportRequest(
      id: 'export_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      requestedAt: DateTime.now(),
      status: 'processing',
      categories: categories,
      format: format,
    );
    
    _exportRequests.putIfAbsent(userId, () => []).add(request);
    _exportController.add(_exportRequests[userId]!);
    _emitDashboardData(userId);
    
    // Simulate processing completion
    Timer(const Duration(seconds: 5), () {
      final requests = _exportRequests[userId]!;
      final index = requests.indexWhere((r) => r.id == request.id);
      if (index != -1) {
        requests[index] = DataExportRequest(
          id: request.id,
          userId: request.userId,
          requestedAt: request.requestedAt,
          status: 'completed',
          categories: request.categories,
          format: request.format,
          completedAt: DateTime.now(),
          downloadUrl: 'https://example.com/exports/${request.id}.${request.format}',
          expiresAt: DateTime.now().add(const Duration(days: 30)),
        );
        
        _exportController.add(requests);
        _emitDashboardData(userId);
      }
    });
    
    return request;
  }

  Future<DataDeletionRequest> requestDataDeletion(String userId, List<DataCategory> categories, String reason) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final request = DataDeletionRequest(
      id: 'deletion_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      requestedAt: DateTime.now(),
      status: 'pending',
      categories: categories,
      reason: reason,
      scheduledFor: DateTime.now().add(const Duration(days: 7)), // 7-day grace period
    );
    
    _deletionRequests.putIfAbsent(userId, () => []).add(request);
    _deletionController.add(_deletionRequests[userId]!);
    _emitDashboardData(userId);
    
    return request;
  }

  Future<List<DataProcessingActivity>> getProcessingActivity(String userId, {int limit = 50}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final activities = _processingActivities[userId] ?? [];
    return activities.take(limit).toList();
  }

  Future<ComplianceReport> generateComplianceReport(String organizationId, String reportType) async {
    await Future.delayed(const Duration(seconds: 2));
    
    final now = DateTime.now();
    final periodStart = now.subtract(const Duration(days: 30));
    
    return ComplianceReport(
      id: 'report_${DateTime.now().millisecondsSinceEpoch}',
      organizationId: organizationId,
      reportType: reportType,
      generatedAt: now,
      periodStart: periodStart,
      periodEnd: now,
      metrics: {
        'totalUsers': 1000 + _random.nextInt(9000),
        'activeConsents': 800 + _random.nextInt(200),
        'dataExportRequests': _random.nextInt(50),
        'dataDeletionRequests': _random.nextInt(20),
        'complianceScore': 85 + _random.nextInt(15),
      },
      complianceIssues: [
        'Some users have expired consents that need renewal',
        '3 data export requests are overdue',
      ],
      recommendations: [
        'Implement automated consent renewal reminders',
        'Improve data export processing time',
        'Add more granular consent options',
      ],
      status: 'completed',
    );
  }

  void dispose() {
    _dataUpdateTimer?.cancel();
    _dashboardController.close();
    _consentController.close();
    _exportController.close();
    _deletionController.close();
  }
}
