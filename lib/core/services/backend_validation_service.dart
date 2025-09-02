import 'dart:async';
import 'dart:developer' as developer;
import 'api_client.dart';
import 'backend_config.dart';
import '../models/form_validation_models.dart';

class BackendValidationService {
  static final BackendValidationService _instance = BackendValidationService._internal();
  factory BackendValidationService() => _instance;
  BackendValidationService._internal();

  final ApiClient _apiClient = ApiClient();

  Future<void> initialize() async {
    developer.log('Backend Validation Service initialized', name: 'BackendValidationService');
  }

  Future<ApiResponse<BreachCheckResult>> checkDataBreach(String email) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        BackendConfig.breachCheckEndpoint,
        body: {
          'email': email,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.success && response.data != null) {
        final result = BreachCheckResult.fromJson(response.data!);
        return ApiResponse.success(result);
      }

      return ApiResponse.error(response.error ?? 'Failed to check data breach');
    } catch (e) {
      developer.log('Data breach check failed: $e', name: 'BackendValidationService');
      return ApiResponse.error('Data breach check failed: $e');
    }
  }

  Future<ApiResponse<PasswordStrengthResult>> checkPasswordStrength(String password, {
    String? email,
    List<String>? commonPasswords,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        BackendConfig.passwordStrengthEndpoint,
        body: {
          'password': password,
          'email': email,
          'common_passwords': commonPasswords ?? [],
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.success && response.data != null) {
        final result = PasswordStrengthResult.fromJson(response.data!);
        return ApiResponse.success(result);
      }

      return ApiResponse.error(response.error ?? 'Failed to check password strength');
    } catch (e) {
      developer.log('Password strength check failed: $e', name: 'BackendValidationService');
      return ApiResponse.error('Password strength check failed: $e');
    }
  }

  Future<ApiResponse<ValidationResult>> validateField({
    required String fieldName,
    required String value,
    required List<String> rules,
    Map<String, dynamic>? context,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.validationEndpoint}/field',
        body: {
          'field_name': fieldName,
          'value': value,
          'rules': rules,
          'context': context ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.success && response.data != null) {
        final result = ValidationResult.fromJson(response.data!);
        return ApiResponse.success(result);
      }

      return ApiResponse.error(response.error ?? 'Failed to validate field');
    } catch (e) {
      developer.log('Field validation failed: $e', name: 'BackendValidationService');
      return ApiResponse.error('Field validation failed: $e');
    }
  }

  Future<ApiResponse<Map<String, ValidationResult>>> validateForm({
    required Map<String, String> formData,
    required Map<String, List<String>> validationRules,
    Map<String, dynamic>? context,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.validationEndpoint}/form',
        body: {
          'form_data': formData,
          'validation_rules': validationRules,
          'context': context ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.success && response.data != null) {
        final results = <String, ValidationResult>{};
        final data = response.data!;
        
        for (final entry in data.entries) {
          if (entry.value is Map<String, dynamic>) {
            results[entry.key] = ValidationResult.fromJson(entry.value);
          }
        }
        
        return ApiResponse.success(results);
      }

      return ApiResponse.error(response.error ?? 'Failed to validate form');
    } catch (e) {
      developer.log('Form validation failed: $e', name: 'BackendValidationService');
      return ApiResponse.error('Form validation failed: $e');
    }
  }

  Future<ApiResponse<List<SmartValidationSuggestion>>> getValidationSuggestions({
    required String fieldName,
    required String value,
    String? fieldType,
    Map<String, dynamic>? context,
  }) async {
    try {
      final response = await _apiClient.post<List<dynamic>>(
        '${BackendConfig.validationEndpoint}/suggestions',
        body: {
          'field_name': fieldName,
          'value': value,
          'field_type': fieldType,
          'context': context ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.success && response.data != null) {
        final suggestions = response.data!.map((s) => SmartValidationSuggestion.fromJson(s)).toList();
        return ApiResponse.success(suggestions);
      }

      return ApiResponse.error(response.error ?? 'Failed to get validation suggestions');
    } catch (e) {
      developer.log('Get validation suggestions failed: $e', name: 'BackendValidationService');
      return ApiResponse.error('Get validation suggestions failed: $e');
    }
  }

  Future<ApiResponse<FormValidationConfig>> getValidationConfig(String formType) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${BackendConfig.validationEndpoint}/config/$formType',
      );

      if (response.success && response.data != null) {
        final config = FormValidationConfig.fromJson(response.data!);
        return ApiResponse.success(config);
      }

      return ApiResponse.error(response.error ?? 'Failed to get validation config');
    } catch (e) {
      developer.log('Get validation config failed: $e', name: 'BackendValidationService');
      return ApiResponse.error('Get validation config failed: $e');
    }
  }

  Future<ApiResponse<FormValidationConfig>> updateValidationConfig(String formType, FormValidationConfig config) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '${BackendConfig.validationEndpoint}/config/$formType',
        body: config.toJson(),
      );

      if (response.success && response.data != null) {
        final updatedConfig = FormValidationConfig.fromJson(response.data!);
        return ApiResponse.success(updatedConfig);
      }

      return ApiResponse.error(response.error ?? 'Failed to update validation config');
    } catch (e) {
      developer.log('Update validation config failed: $e', name: 'BackendValidationService');
      return ApiResponse.error('Update validation config failed: $e');
    }
  }

  Future<ApiResponse<ValidationAnalytics>> getValidationAnalytics({
    String? formType,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (formType != null) queryParams['form_type'] = formType;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiClient.get<Map<String, dynamic>>(
        '${BackendConfig.validationEndpoint}/analytics',
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        final analytics = ValidationAnalytics.fromJson(response.data!);
        return ApiResponse.success(analytics);
      }

      return ApiResponse.error(response.error ?? 'Failed to get validation analytics');
    } catch (e) {
      developer.log('Get validation analytics failed: $e', name: 'BackendValidationService');
      return ApiResponse.error('Get validation analytics failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> recordValidationEvent({
    required String eventType,
    required String formType,
    required String fieldName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.validationEndpoint}/events',
        body: {
          'event_type': eventType,
          'form_type': formType,
          'field_name': fieldName,
          'metadata': metadata ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return response;
    } catch (e) {
      developer.log('Record validation event failed: $e', name: 'BackendValidationService');
      return ApiResponse.error('Record validation event failed: $e');
    }
  }

  Future<ApiResponse<List<DataBreach>>> getKnownBreaches({
    String? domain,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (domain != null) queryParams['domain'] = domain;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiClient.get<List<dynamic>>(
        '${BackendConfig.validationEndpoint}/breaches',
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        final breaches = response.data!.map((b) => DataBreach.fromJson(b)).toList();
        return ApiResponse.success(breaches);
      }

      return ApiResponse.error(response.error ?? 'Failed to get known breaches');
    } catch (e) {
      developer.log('Get known breaches failed: $e', name: 'BackendValidationService');
      return ApiResponse.error('Get known breaches failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> bulkBreachCheck(List<String> emails) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.breachCheckEndpoint}/bulk',
        body: {
          'emails': emails,
          'timestamp': DateTime.now().toIso8601String(),
        },
        timeout: BackendConfig.longOperationTimeout,
      );

      return response;
    } catch (e) {
      developer.log('Bulk breach check failed: $e', name: 'BackendValidationService');
      return ApiResponse.error('Bulk breach check failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> validateEmail(String email, {
    bool? checkMx,
    bool? checkDisposable,
    bool? checkBreach,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.validationEndpoint}/email',
        body: {
          'email': email,
          'check_mx': checkMx ?? true,
          'check_disposable': checkDisposable ?? true,
          'check_breach': checkBreach ?? true,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return response;
    } catch (e) {
      developer.log('Email validation failed: $e', name: 'BackendValidationService');
      return ApiResponse.error('Email validation failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> validatePhone(String phone, {
    String? countryCode,
    bool? checkCarrier,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.validationEndpoint}/phone',
        body: {
          'phone': phone,
          'country_code': countryCode,
          'check_carrier': checkCarrier ?? false,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return response;
    } catch (e) {
      developer.log('Phone validation failed: $e', name: 'BackendValidationService');
      return ApiResponse.error('Phone validation failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> validateUrl(String url, {
    bool? checkReachable,
    bool? checkSafety,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.validationEndpoint}/url',
        body: {
          'url': url,
          'check_reachable': checkReachable ?? false,
          'check_safety': checkSafety ?? true,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return response;
    } catch (e) {
      developer.log('URL validation failed: $e', name: 'BackendValidationService');
      return ApiResponse.error('URL validation failed: $e');
    }
  }

  void dispose() {
    // Cleanup if needed
  }
}
