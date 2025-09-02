import 'dart:async';
import 'dart:developer' as developer;
import 'api_client.dart';
import 'backend_config.dart';
import '../models/analytics_models.dart';

class BackendSecurityAnalyticsService {
  static final BackendSecurityAnalyticsService _instance = BackendSecurityAnalyticsService._internal();
  factory BackendSecurityAnalyticsService() => _instance;
  BackendSecurityAnalyticsService._internal();

  final ApiClient _apiClient = ApiClient();
  StreamSubscription? _analyticsSubscription;

  Future<void> initialize() async {
    developer.log('Backend Security Analytics Service initialized', name: 'BackendSecurityAnalyticsService');
  }

  Future<ApiResponse<List<SecurityMetric>>> getSecurityMetrics({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (category != null) queryParams['category'] = category;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiClient.get<List<dynamic>>(
        BackendConfig.metricsEndpoint,
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        final metrics = response.data!.map((m) => SecurityMetric.fromJson(m)).toList();
        return ApiResponse.success(metrics);
      }

      return ApiResponse.error(response.error ?? 'Failed to get security metrics');
    } catch (e) {
      developer.log('Get security metrics failed: $e', name: 'BackendSecurityAnalyticsService');
      return ApiResponse.error('Get security metrics failed: $e');
    }
  }

  Future<ApiResponse<List<SecurityTrend>>> getSecurityTrends({
    String? metricType,
    String? period,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (metricType != null) queryParams['metric_type'] = metricType;
      if (period != null) queryParams['period'] = period;
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiClient.get<List<dynamic>>(
        BackendConfig.trendsEndpoint,
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        final trends = response.data!.map((t) => SecurityTrend.fromJson(t)).toList();
        return ApiResponse.success(trends);
      }

      return ApiResponse.error(response.error ?? 'Failed to get security trends');
    } catch (e) {
      developer.log('Get security trends failed: $e', name: 'BackendSecurityAnalyticsService');
      return ApiResponse.error('Get security trends failed: $e');
    }
  }

  Future<ApiResponse<List<SecurityAlert>>> getSecurityAlerts({
    String? severity,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (severity != null) queryParams['severity'] = severity;
      if (status != null) queryParams['status'] = status;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final response = await _apiClient.get<List<dynamic>>(
        BackendConfig.alertsEndpoint,
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        final alerts = response.data!.map((a) => SecurityAlert.fromJson(a)).toList();
        return ApiResponse.success(alerts);
      }

      return ApiResponse.error(response.error ?? 'Failed to get security alerts');
    } catch (e) {
      developer.log('Get security alerts failed: $e', name: 'BackendSecurityAnalyticsService');
      return ApiResponse.error('Get security alerts failed: $e');
    }
  }

  Future<ApiResponse<SecurityAlert>> createAlert(SecurityAlert alert) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        BackendConfig.alertsEndpoint,
        body: alert.toJson(),
      );

      if (response.success && response.data != null) {
        final createdAlert = SecurityAlert.fromJson(response.data!);
        return ApiResponse.success(createdAlert);
      }

      return ApiResponse.error(response.error ?? 'Failed to create alert');
    } catch (e) {
      developer.log('Create alert failed: $e', name: 'BackendSecurityAnalyticsService');
      return ApiResponse.error('Create alert failed: $e');
    }
  }

  Future<ApiResponse<SecurityAlert>> updateAlert(String alertId, Map<String, dynamic> updates) async {
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '${BackendConfig.alertsEndpoint}/$alertId',
        body: updates,
      );

      if (response.success && response.data != null) {
        final updatedAlert = SecurityAlert.fromJson(response.data!);
        return ApiResponse.success(updatedAlert);
      }

      return ApiResponse.error(response.error ?? 'Failed to update alert');
    } catch (e) {
      developer.log('Update alert failed: $e', name: 'BackendSecurityAnalyticsService');
      return ApiResponse.error('Update alert failed: $e');
    }
  }

  Future<ApiResponse<List<AnalyticsReport>>> getReports({
    String? type,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (type != null) queryParams['type'] = type;
      if (status != null) queryParams['status'] = status;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiClient.get<List<dynamic>>(
        BackendConfig.reportsEndpoint,
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        final reports = response.data!.map((r) => AnalyticsReport.fromJson(r)).toList();
        return ApiResponse.success(reports);
      }

      return ApiResponse.error(response.error ?? 'Failed to get reports');
    } catch (e) {
      developer.log('Get reports failed: $e', name: 'BackendSecurityAnalyticsService');
      return ApiResponse.error('Get reports failed: $e');
    }
  }

  Future<ApiResponse<AnalyticsReport>> generateReport({
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.reportsEndpoint}/generate',
        body: {
          'type': type,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'parameters': parameters ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
        timeout: BackendConfig.longOperationTimeout,
      );

      if (response.success && response.data != null) {
        final report = AnalyticsReport.fromJson(response.data!);
        return ApiResponse.success(report);
      }

      return ApiResponse.error(response.error ?? 'Failed to generate report');
    } catch (e) {
      developer.log('Generate report failed: $e', name: 'BackendSecurityAnalyticsService');
      return ApiResponse.error('Generate report failed: $e');
    }
  }

  Future<ApiResponse<List<PredictiveModel>>> getPredictiveModels({
    String? type,
    String? status,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (type != null) queryParams['type'] = type;
      if (status != null) queryParams['status'] = status;
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiClient.get<List<dynamic>>(
        '${BackendConfig.analyticsEndpoint}/models',
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        final models = response.data!.map((m) => PredictiveModel.fromJson(m)).toList();
        return ApiResponse.success(models);
      }

      return ApiResponse.error(response.error ?? 'Failed to get predictive models');
    } catch (e) {
      developer.log('Get predictive models failed: $e', name: 'BackendSecurityAnalyticsService');
      return ApiResponse.error('Get predictive models failed: $e');
    }
  }

  Future<ApiResponse<List<SecurityPrediction>>> getPredictions({
    String? modelId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (modelId != null) queryParams['model_id'] = modelId;
      if (type != null) queryParams['type'] = type;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiClient.get<List<dynamic>>(
        BackendConfig.predictionsEndpoint,
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        final predictions = response.data!.map((p) => SecurityPrediction.fromJson(p)).toList();
        return ApiResponse.success(predictions);
      }

      return ApiResponse.error(response.error ?? 'Failed to get predictions');
    } catch (e) {
      developer.log('Get predictions failed: $e', name: 'BackendSecurityAnalyticsService');
      return ApiResponse.error('Get predictions failed: $e');
    }
  }

  Future<ApiResponse<SecurityPrediction>> runPrediction(String modelId, Map<String, dynamic> inputData) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.predictionsEndpoint}/run',
        body: {
          'model_id': modelId,
          'input_data': inputData,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.success && response.data != null) {
        final prediction = SecurityPrediction.fromJson(response.data!);
        return ApiResponse.success(prediction);
      }

      return ApiResponse.error(response.error ?? 'Failed to run prediction');
    } catch (e) {
      developer.log('Run prediction failed: $e', name: 'BackendSecurityAnalyticsService');
      return ApiResponse.error('Run prediction failed: $e');
    }
  }

  Future<ApiResponse<List<CorrelationRule>>> getCorrelationRules({
    String? status,
    String? severity,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (severity != null) queryParams['severity'] = severity;
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiClient.get<List<dynamic>>(
        BackendConfig.correlationEndpoint,
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        final rules = response.data!.map((r) => CorrelationRule.fromJson(r)).toList();
        return ApiResponse.success(rules);
      }

      return ApiResponse.error(response.error ?? 'Failed to get correlation rules');
    } catch (e) {
      developer.log('Get correlation rules failed: $e', name: 'BackendSecurityAnalyticsService');
      return ApiResponse.error('Get correlation rules failed: $e');
    }
  }

  Future<ApiResponse<CorrelationRule>> createCorrelationRule(CorrelationRule rule) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        BackendConfig.correlationEndpoint,
        body: rule.toJson(),
      );

      if (response.success && response.data != null) {
        final createdRule = CorrelationRule.fromJson(response.data!);
        return ApiResponse.success(createdRule);
      }

      return ApiResponse.error(response.error ?? 'Failed to create correlation rule');
    } catch (e) {
      developer.log('Create correlation rule failed: $e', name: 'BackendSecurityAnalyticsService');
      return ApiResponse.error('Create correlation rule failed: $e');
    }
  }

  Future<ApiResponse<CorrelationRule>> updateCorrelationRule(String ruleId, Map<String, dynamic> updates) async {
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '${BackendConfig.correlationEndpoint}/$ruleId',
        body: updates,
      );

      if (response.success && response.data != null) {
        final updatedRule = CorrelationRule.fromJson(response.data!);
        return ApiResponse.success(updatedRule);
      }

      return ApiResponse.error(response.error ?? 'Failed to update correlation rule');
    } catch (e) {
      developer.log('Update correlation rule failed: $e', name: 'BackendSecurityAnalyticsService');
      return ApiResponse.error('Update correlation rule failed: $e');
    }
  }

  Stream<SecurityAlert> subscribeToAlerts() {
    return _apiClient.connectWebSocket<SecurityAlert>(
      BackendConfig.wsAnalytics,
      parser: (data) => SecurityAlert.fromJson(data),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getAnalyticsDashboard({
    String? timeRange,
    List<String>? widgets,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (timeRange != null) queryParams['time_range'] = timeRange;
      if (widgets != null) queryParams['widgets'] = widgets.join(',');

      final response = await _apiClient.get<Map<String, dynamic>>(
        '${BackendConfig.analyticsEndpoint}/dashboard',
        queryParams: queryParams,
      );

      return response;
    } catch (e) {
      developer.log('Get analytics dashboard failed: $e', name: 'BackendSecurityAnalyticsService');
      return ApiResponse.error('Get analytics dashboard failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> exportAnalyticsData({
    required String format,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? dataTypes,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.analyticsEndpoint}/export',
        body: {
          'format': format,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'data_types': dataTypes ?? [],
          'timestamp': DateTime.now().toIso8601String(),
        },
        timeout: BackendConfig.longOperationTimeout,
      );

      return response;
    } catch (e) {
      developer.log('Export analytics data failed: $e', name: 'BackendSecurityAnalyticsService');
      return ApiResponse.error('Export analytics data failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> searchAnalytics({
    required String query,
    List<String>? types,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{
        'q': query,
      };
      
      if (types != null) queryParams['types'] = types.join(',');
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final response = await _apiClient.get<Map<String, dynamic>>(
        '${BackendConfig.analyticsEndpoint}/search',
        queryParams: queryParams,
      );

      return response;
    } catch (e) {
      developer.log('Search analytics failed: $e', name: 'BackendSecurityAnalyticsService');
      return ApiResponse.error('Search analytics failed: $e');
    }
  }

  void dispose() {
    _analyticsSubscription?.cancel();
  }
}
