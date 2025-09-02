import 'dart:async';
import 'dart:developer' as developer;
import 'api_client.dart';
import 'backend_config.dart';
import '../models/privacy_models.dart';

class BackendPrivacyService {
  static final BackendPrivacyService _instance = BackendPrivacyService._internal();
  factory BackendPrivacyService() => _instance;
  BackendPrivacyService._internal();

  final ApiClient _apiClient = ApiClient();

  Future<void> initialize() async {
    developer.log('Backend Privacy Service initialized', name: 'BackendPrivacyService');
  }

  Future<ApiResponse<PrivacyDashboardData>> getPrivacyDashboard(String userId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${BackendConfig.privacyDashboardEndpoint}/$userId',
      );

      if (response.success && response.data != null) {
        final dashboard = PrivacyDashboardData.fromJson(response.data!);
        return ApiResponse.success(dashboard);
      }

      return ApiResponse.error(response.error ?? 'Failed to get privacy dashboard');
    } catch (e) {
      developer.log('Get privacy dashboard failed: $e', name: 'BackendPrivacyService');
      return ApiResponse.error('Get privacy dashboard failed: $e');
    }
  }

  Future<ApiResponse<List<ConsentRecord>>> getConsentRecords(String userId) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${BackendConfig.consentEndpoint}/$userId',
      );

      if (response.success && response.data != null) {
        final records = response.data!.map((r) => ConsentRecord.fromJson(r)).toList();
        return ApiResponse.success(records);
      }

      return ApiResponse.error(response.error ?? 'Failed to get consent records');
    } catch (e) {
      developer.log('Get consent records failed: $e', name: 'BackendPrivacyService');
      return ApiResponse.error('Get consent records failed: $e');
    }
  }

  Future<ApiResponse<ConsentRecord>> updateConsent(String userId, String categoryId, ConsentStatus status, {
    String? reason,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.consentEndpoint}/$userId/$categoryId',
        body: {
          'status': status.toString().split('.').last,
          'reason': reason,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.success && response.data != null) {
        final record = ConsentRecord.fromJson(response.data!);
        return ApiResponse.success(record);
      }

      return ApiResponse.error(response.error ?? 'Failed to update consent');
    } catch (e) {
      developer.log('Update consent failed: $e', name: 'BackendPrivacyService');
      return ApiResponse.error('Update consent failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> bulkUpdateConsent(String userId, Map<String, ConsentStatus> consents) async {
    try {
      final consentData = consents.map((key, value) => MapEntry(key, value.toString().split('.').last));
      
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.consentEndpoint}/$userId/bulk',
        body: {
          'consents': consentData,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return response;
    } catch (e) {
      developer.log('Bulk update consent failed: $e', name: 'BackendPrivacyService');
      return ApiResponse.error('Bulk update consent failed: $e');
    }
  }

  Future<ApiResponse<DataExportRequest>> requestDataExport(String userId, {
    List<String>? categories,
    String? format,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        BackendConfig.dataExportEndpoint,
        body: {
          'user_id': userId,
          'categories': categories ?? [],
          'format': format ?? 'json',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.success && response.data != null) {
        final request = DataExportRequest.fromJson(response.data!);
        return ApiResponse.success(request);
      }

      return ApiResponse.error(response.error ?? 'Failed to request data export');
    } catch (e) {
      developer.log('Request data export failed: $e', name: 'BackendPrivacyService');
      return ApiResponse.error('Request data export failed: $e');
    }
  }

  Future<ApiResponse<List<DataExportRequest>>> getDataExportRequests(String userId) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${BackendConfig.dataExportEndpoint}/$userId',
      );

      if (response.success && response.data != null) {
        final requests = response.data!.map((r) => DataExportRequest.fromJson(r)).toList();
        return ApiResponse.success(requests);
      }

      return ApiResponse.error(response.error ?? 'Failed to get data export requests');
    } catch (e) {
      developer.log('Get data export requests failed: $e', name: 'BackendPrivacyService');
      return ApiResponse.error('Get data export requests failed: $e');
    }
  }

  Future<ApiResponse<String>> downloadDataExport(String requestId) async {
    try {
      final response = await _apiClient.get<String>(
        '${BackendConfig.dataExportEndpoint}/download/$requestId',
      );

      return response;
    } catch (e) {
      developer.log('Download data export failed: $e', name: 'BackendPrivacyService');
      return ApiResponse.error('Download data export failed: $e');
    }
  }

  Future<ApiResponse<DataDeletionRequest>> requestDataDeletion(String userId, {
    List<String>? categories,
    String? reason,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        BackendConfig.dataDeletionEndpoint,
        body: {
          'user_id': userId,
          'categories': categories ?? [],
          'reason': reason,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.success && response.data != null) {
        final request = DataDeletionRequest.fromJson(response.data!);
        return ApiResponse.success(request);
      }

      return ApiResponse.error(response.error ?? 'Failed to request data deletion');
    } catch (e) {
      developer.log('Request data deletion failed: $e', name: 'BackendPrivacyService');
      return ApiResponse.error('Request data deletion failed: $e');
    }
  }

  Future<ApiResponse<List<DataDeletionRequest>>> getDataDeletionRequests(String userId) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${BackendConfig.dataDeletionEndpoint}/$userId',
      );

      if (response.success && response.data != null) {
        final requests = response.data!.map((r) => DataDeletionRequest.fromJson(r)).toList();
        return ApiResponse.success(requests);
      }

      return ApiResponse.error(response.error ?? 'Failed to get data deletion requests');
    } catch (e) {
      developer.log('Get data deletion requests failed: $e', name: 'BackendPrivacyService');
      return ApiResponse.error('Get data deletion requests failed: $e');
    }
  }

  Future<ApiResponse<List<DataProcessingActivity>>> getProcessingActivities(String userId) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${BackendConfig.privacyEndpoint}/$userId/processing-activities',
      );

      if (response.success && response.data != null) {
        final activities = response.data!.map((a) => DataProcessingActivity.fromJson(a)).toList();
        return ApiResponse.success(activities);
      }

      return ApiResponse.error(response.error ?? 'Failed to get processing activities');
    } catch (e) {
      developer.log('Get processing activities failed: $e', name: 'BackendPrivacyService');
      return ApiResponse.error('Get processing activities failed: $e');
    }
  }

  Future<ApiResponse<PrivacySettings>> getPrivacySettings(String userId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${BackendConfig.privacyEndpoint}/$userId/settings',
      );

      if (response.success && response.data != null) {
        final settings = PrivacySettings.fromJson(response.data!);
        return ApiResponse.success(settings);
      }

      return ApiResponse.error(response.error ?? 'Failed to get privacy settings');
    } catch (e) {
      developer.log('Get privacy settings failed: $e', name: 'BackendPrivacyService');
      return ApiResponse.error('Get privacy settings failed: $e');
    }
  }

  Future<ApiResponse<PrivacySettings>> updatePrivacySettings(String userId, PrivacySettings settings) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '${BackendConfig.privacyEndpoint}/$userId/settings',
        body: settings.toJson(),
      );

      if (response.success && response.data != null) {
        final updatedSettings = PrivacySettings.fromJson(response.data!);
        return ApiResponse.success(updatedSettings);
      }

      return ApiResponse.error(response.error ?? 'Failed to update privacy settings');
    } catch (e) {
      developer.log('Update privacy settings failed: $e', name: 'BackendPrivacyService');
      return ApiResponse.error('Update privacy settings failed: $e');
    }
  }

  Future<ApiResponse<List<ComplianceReport>>> getComplianceReports({
    String? framework,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (framework != null) queryParams['framework'] = framework;
      if (status != null) queryParams['status'] = status;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiClient.get<List<dynamic>>(
        BackendConfig.complianceReportsEndpoint,
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        final reports = response.data!.map((r) => ComplianceReport.fromJson(r)).toList();
        return ApiResponse.success(reports);
      }

      return ApiResponse.error(response.error ?? 'Failed to get compliance reports');
    } catch (e) {
      developer.log('Get compliance reports failed: $e', name: 'BackendPrivacyService');
      return ApiResponse.error('Get compliance reports failed: $e');
    }
  }

  Future<ApiResponse<ComplianceReport>> generateComplianceReport({
    required String framework,
    required DateTime startDate,
    required DateTime endDate,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.complianceReportsEndpoint}/generate',
        body: {
          'framework': framework,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'parameters': parameters ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
        timeout: BackendConfig.longOperationTimeout,
      );

      if (response.success && response.data != null) {
        final report = ComplianceReport.fromJson(response.data!);
        return ApiResponse.success(report);
      }

      return ApiResponse.error(response.error ?? 'Failed to generate compliance report');
    } catch (e) {
      developer.log('Generate compliance report failed: $e', name: 'BackendPrivacyService');
      return ApiResponse.error('Generate compliance report failed: $e');
    }
  }

  Future<ApiResponse<List<DataCategory>>> getDataCategories() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${BackendConfig.privacyEndpoint}/data-categories',
      );

      if (response.success && response.data != null) {
                final categories = response.data!.map((c) => DataCategory.values.byName(c as String)).toList();
        return ApiResponse.success(categories);
      }

      return ApiResponse.error(response.error ?? 'Failed to get data categories');
    } catch (e) {
      developer.log('Get data categories failed: $e', name: 'BackendPrivacyService');
      return ApiResponse.error('Get data categories failed: $e');
    }
  }

  Future<ApiResponse<List<DataProcessingPurpose>>> getProcessingPurposes() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${BackendConfig.privacyEndpoint}/processing-purposes',
      );

      if (response.success && response.data != null) {
                final purposes = response.data!.map((p) => DataProcessingPurpose.values.byName(p as String)).toList();
        return ApiResponse.success(purposes);
      }

      return ApiResponse.error(response.error ?? 'Failed to get processing purposes');
    } catch (e) {
      developer.log('Get processing purposes failed: $e', name: 'BackendPrivacyService');
      return ApiResponse.error('Get processing purposes failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getPrivacyMetrics({
    String? timeRange,
    List<String>? metrics,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (timeRange != null) queryParams['time_range'] = timeRange;
      if (metrics != null) queryParams['metrics'] = metrics.join(',');

      final response = await _apiClient.get<Map<String, dynamic>>(
        '${BackendConfig.privacyEndpoint}/metrics',
        queryParams: queryParams,
      );

      return response;
    } catch (e) {
      developer.log('Get privacy metrics failed: $e', name: 'BackendPrivacyService');
      return ApiResponse.error('Get privacy metrics failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> auditPrivacyAction({
    required String userId,
    required String action,
    required String category,
    Map<String, dynamic>? details,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.privacyEndpoint}/audit',
        body: {
          'user_id': userId,
          'action': action,
          'category': category,
          'details': details ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return response;
    } catch (e) {
      developer.log('Audit privacy action failed: $e', name: 'BackendPrivacyService');
      return ApiResponse.error('Audit privacy action failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> validateCompliance({
    required String framework,
    String? userId,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.privacyEndpoint}/validate-compliance',
        body: {
          'framework': framework,
          'user_id': userId,
          'parameters': parameters ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return response;
    } catch (e) {
      developer.log('Validate compliance failed: $e', name: 'BackendPrivacyService');
      return ApiResponse.error('Validate compliance failed: $e');
    }
  }

  void dispose() {
    // Cleanup if needed
  }
}
