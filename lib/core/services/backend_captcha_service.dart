import 'dart:async';
import 'dart:developer' as developer;
import 'api_client.dart';
import 'backend_config.dart';
import '../models/captcha_models.dart';

class BackendCaptchaService {
  static final BackendCaptchaService _instance = BackendCaptchaService._internal();
  factory BackendCaptchaService() => _instance;
  BackendCaptchaService._internal();

  final ApiClient _apiClient = ApiClient();

  Future<void> initialize() async {
    developer.log('Backend Captcha Service initialized', name: 'BackendCaptchaService');
  }

  Future<ApiResponse<CaptchaChallenge>> generateCaptcha({
    required String type,
    String? difficulty,
    Map<String, dynamic>? options,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        BackendConfig.captchaGenerateEndpoint,
        body: {
          'type': type,
          'difficulty': difficulty ?? 'medium',
          'options': options ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.success && response.data != null) {
        final challenge = CaptchaChallenge.fromJson(response.data!);
        return ApiResponse.success(challenge);
      }

      return ApiResponse.error(response.error ?? 'Failed to generate captcha');
    } catch (e) {
      developer.log('Generate captcha failed: $e', name: 'BackendCaptchaService');
      return ApiResponse.error('Generate captcha failed: $e');
    }
  }

  Future<ApiResponse<CaptchaVerificationResult>> verifyCaptcha({
    required String challengeId,
    required String response,
    Map<String, dynamic>? behavioralData,
  }) async {
    try {
      final apiResponse = await _apiClient.post<Map<String, dynamic>>(
        BackendConfig.captchaVerifyEndpoint,
        body: {
          'challenge_id': challengeId,
          'response': response,
          'behavioral_data': behavioralData ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (apiResponse.success && apiResponse.data != null) {
        final result = CaptchaVerificationResult.fromJson(apiResponse.data!);
        return ApiResponse.success(result);
      }

      return ApiResponse.error(apiResponse.error ?? 'Failed to verify captcha');
    } catch (e) {
      developer.log('Verify captcha failed: $e', name: 'BackendCaptchaService');
      return ApiResponse.error('Verify captcha failed: $e');
    }
  }

  Future<ApiResponse<BotDetectionResult>> analyzeBotBehavior({
    required Map<String, dynamic> behavioralData,
    String? sessionId,
    String? userAgent,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.captchaEndpoint}/bot-detection',
        body: {
          'behavioral_data': behavioralData,
          'session_id': sessionId,
          'user_agent': userAgent,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.success && response.data != null) {
        final result = BotDetectionResult.fromJson(response.data!);
        return ApiResponse.success(result);
      }

      return ApiResponse.error(response.error ?? 'Failed to analyze bot behavior');
    } catch (e) {
      developer.log('Analyze bot behavior failed: $e', name: 'BackendCaptchaService');
      return ApiResponse.error('Analyze bot behavior failed: $e');
    }
  }

  Future<ApiResponse<CaptchaConfig>> getCaptchaConfig(String type) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${BackendConfig.captchaEndpoint}/config/$type',
      );

      if (response.success && response.data != null) {
        final config = CaptchaConfig.fromJson(response.data!);
        return ApiResponse.success(config);
      }

      return ApiResponse.error(response.error ?? 'Failed to get captcha config');
    } catch (e) {
      developer.log('Get captcha config failed: $e', name: 'BackendCaptchaService');
      return ApiResponse.error('Get captcha config failed: $e');
    }
  }

  Future<ApiResponse<CaptchaConfig>> updateCaptchaConfig(String type, CaptchaConfig config) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '${BackendConfig.captchaEndpoint}/config/$type',
        body: config.toJson(),
      );

      if (response.success && response.data != null) {
        final updatedConfig = CaptchaConfig.fromJson(response.data!);
        return ApiResponse.success(updatedConfig);
      }

      return ApiResponse.error(response.error ?? 'Failed to update captcha config');
    } catch (e) {
      developer.log('Update captcha config failed: $e', name: 'BackendCaptchaService');
      return ApiResponse.error('Update captcha config failed: $e');
    }
  }

  Future<ApiResponse<CaptchaAnalytics>> getCaptchaAnalytics({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (type != null) queryParams['type'] = type;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiClient.get<Map<String, dynamic>>(
        '${BackendConfig.captchaEndpoint}/analytics',
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        final analytics = CaptchaAnalytics.fromJson(response.data!);
        return ApiResponse.success(analytics);
      }

      return ApiResponse.error(response.error ?? 'Failed to get captcha analytics');
    } catch (e) {
      developer.log('Get captcha analytics failed: $e', name: 'BackendCaptchaService');
      return ApiResponse.error('Get captcha analytics failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> recordCaptchaEvent({
    required String eventType,
    required String challengeId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.captchaEndpoint}/events',
        body: {
          'event_type': eventType,
          'challenge_id': challengeId,
          'metadata': metadata ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return response;
    } catch (e) {
      developer.log('Record captcha event failed: $e', name: 'BackendCaptchaService');
      return ApiResponse.error('Record captcha event failed: $e');
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getCaptchaHistory({
    String? sessionId,
    String? ipAddress,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (sessionId != null) queryParams['session_id'] = sessionId;
      if (ipAddress != null) queryParams['ip_address'] = ipAddress;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiClient.get<List<dynamic>>(
        '${BackendConfig.captchaEndpoint}/history',
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data!.cast<Map<String, dynamic>>());
      }

      return ApiResponse.error(response.error ?? 'Failed to get captcha history');
    } catch (e) {
      developer.log('Get captcha history failed: $e', name: 'BackendCaptchaService');
      return ApiResponse.error('Get captcha history failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> validateCaptchaSession({
    required String sessionId,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.captchaEndpoint}/validate-session',
        body: {
          'session_id': sessionId,
          'ip_address': ipAddress,
          'user_agent': userAgent,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return response;
    } catch (e) {
      developer.log('Validate captcha session failed: $e', name: 'BackendCaptchaService');
      return ApiResponse.error('Validate captcha session failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> refreshCaptcha(String challengeId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.captchaEndpoint}/refresh',
        body: {
          'challenge_id': challengeId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return response;
    } catch (e) {
      developer.log('Refresh captcha failed: $e', name: 'BackendCaptchaService');
      return ApiResponse.error('Refresh captcha failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> reportCaptchaAbuse({
    required String challengeId,
    required String reason,
    Map<String, dynamic>? evidence,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.captchaEndpoint}/report-abuse',
        body: {
          'challenge_id': challengeId,
          'reason': reason,
          'evidence': evidence ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return response;
    } catch (e) {
      developer.log('Report captcha abuse failed: $e', name: 'BackendCaptchaService');
      return ApiResponse.error('Report captcha abuse failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getBotDetectionStats({
    String? timeRange,
    List<String>? metrics,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (timeRange != null) queryParams['time_range'] = timeRange;
      if (metrics != null) queryParams['metrics'] = metrics.join(',');

      final response = await _apiClient.get<Map<String, dynamic>>(
        '${BackendConfig.captchaEndpoint}/bot-detection/stats',
        queryParams: queryParams,
      );

      return response;
    } catch (e) {
      developer.log('Get bot detection stats failed: $e', name: 'BackendCaptchaService');
      return ApiResponse.error('Get bot detection stats failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> trainBotModel({
    required List<Map<String, dynamic>> trainingData,
    String? modelType,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.captchaEndpoint}/bot-detection/train',
        body: {
          'training_data': trainingData,
          'model_type': modelType ?? 'behavioral',
          'parameters': parameters ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
        timeout: BackendConfig.longOperationTimeout,
      );

      return response;
    } catch (e) {
      developer.log('Train bot model failed: $e', name: 'BackendCaptchaService');
      return ApiResponse.error('Train bot model failed: $e');
    }
  }

  void dispose() {
    // Cleanup if needed
  }
}
