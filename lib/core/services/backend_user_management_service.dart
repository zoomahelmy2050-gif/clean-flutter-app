import 'dart:async';
import 'dart:developer' as developer;
import 'api_client.dart';
import 'backend_config.dart';
import '../models/user_management_models.dart';
import '../models/risk_based_auth_models.dart';
import '../models/admin_models.dart';

class BackendUserManagementService {
  static final BackendUserManagementService _instance = BackendUserManagementService._internal();
  factory BackendUserManagementService() => _instance;
  BackendUserManagementService._internal();

  final ApiClient _apiClient = ApiClient();

  Future<void> initialize() async {
    developer.log('Backend User Management Service initialized', name: 'BackendUserManagementService');
  }

  Future<ApiResponse<UserProfile>> getUserProfile(String userId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${BackendConfig.userProfileEndpoint}/$userId',
      );

      if (response.success && response.data != null) {
        final profile = UserProfile.fromJson(response.data!);
        return ApiResponse.success(profile);
      }

      return ApiResponse.error(response.error ?? 'Failed to get user profile');
    } catch (e) {
      developer.log('Get user profile failed: $e', name: 'BackendUserManagementService');
      return ApiResponse.error('Get user profile failed: $e');
    }
  }

  Future<ApiResponse<UserProfile>> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '${BackendConfig.userProfileEndpoint}/$userId',
        body: updates,
      );

      if (response.success && response.data != null) {
        final profile = UserProfile.fromJson(response.data!);
        return ApiResponse.success(profile);
      }

      return ApiResponse.error(response.error ?? 'Failed to update user profile');
    } catch (e) {
      developer.log('Update user profile failed: $e', name: 'BackendUserManagementService');
      return ApiResponse.error('Update user profile failed: $e');
    }
  }

  Future<ApiResponse<List<UserProfile>>> getUsers({
    String? role,
    String? status,
    String? search,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (role != null) queryParams['role'] = role;
      if (status != null) queryParams['status'] = status;
      if (search != null) queryParams['search'] = search;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final response = await _apiClient.get<List<dynamic>>(
        BackendConfig.usersEndpoint,
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        final users = response.data!.map((u) => UserProfile.fromJson(u)).toList();
        return ApiResponse.success(users);
      }

      return ApiResponse.error(response.error ?? 'Failed to get users');
    } catch (e) {
      developer.log('Get users failed: $e', name: 'BackendUserManagementService');
      return ApiResponse.error('Get users failed: $e');
    }
  }

  Future<ApiResponse<UserRiskScore>> getUserRiskScore(String userId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${BackendConfig.userRiskScoreEndpoint}/$userId',
      );

      if (response.success && response.data != null) {
        final riskScore = UserRiskScore.fromJson(response.data!);
        return ApiResponse.success(riskScore);
      }

      return ApiResponse.error(response.error ?? 'Failed to get user risk score');
    } catch (e) {
      developer.log('Get user risk score failed: $e', name: 'BackendUserManagementService');
      return ApiResponse.error('Get user risk score failed: $e');
    }
  }

  Future<ApiResponse<UserRiskScore>> updateUserRiskScore(String userId, {
    required double score,
    required String reason,
    Map<String, dynamic>? factors,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.userRiskScoreEndpoint}/$userId',
        body: {
          'score': score,
          'reason': reason,
          'factors': factors ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.success && response.data != null) {
        final riskScore = UserRiskScore.fromJson(response.data!);
        return ApiResponse.success(riskScore);
      }

      return ApiResponse.error(response.error ?? 'Failed to update user risk score');
    } catch (e) {
      developer.log('Update user risk score failed: $e', name: 'BackendUserManagementService');
      return ApiResponse.error('Update user risk score failed: $e');
    }
  }

  Future<ApiResponse<List<UserSession>>> getUserSessions(String userId) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${BackendConfig.userSessionsEndpoint}/$userId',
      );

      if (response.success && response.data != null) {
        final sessions = response.data!.map((s) => UserSession.fromJson(s)).toList();
        return ApiResponse.success(sessions);
      }

      return ApiResponse.error(response.error ?? 'Failed to get user sessions');
    } catch (e) {
      developer.log('Get user sessions failed: $e', name: 'BackendUserManagementService');
      return ApiResponse.error('Get user sessions failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> terminateUserSession(String userId, String sessionId) async {
    try {
      final response = await _apiClient.delete<Map<String, dynamic>>(
        '${BackendConfig.userSessionsEndpoint}/$userId/$sessionId',
      );

      return response;
    } catch (e) {
      developer.log('Terminate user session failed: $e', name: 'BackendUserManagementService');
      return ApiResponse.error('Terminate user session failed: $e');
    }
  }

  Future<ApiResponse<List<UserActivity>>> getUserActivity(String userId, {
    DateTime? startDate,
    DateTime? endDate,
    String? activityType,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (activityType != null) queryParams['activity_type'] = activityType;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final response = await _apiClient.get<List<dynamic>>(
        '${BackendConfig.usersEndpoint}/$userId/activity',
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        final activities = response.data!.map((a) => UserActivity.fromJson(a)).toList();
        return ApiResponse.success(activities);
      }

      return ApiResponse.error(response.error ?? 'Failed to get user activity');
    } catch (e) {
      developer.log('Get user activity failed: $e', name: 'BackendUserManagementService');
      return ApiResponse.error('Get user activity failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> createUser({
    required String email,
    required String name,
    String? role,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        BackendConfig.usersEndpoint,
        body: {
          'email': email,
          'name': name,
          'role': role ?? 'user',
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
          ...?additionalData,
        },
      );

      return response;
    } catch (e) {
      developer.log('Create user failed: $e', name: 'BackendUserManagementService');
      return ApiResponse.error('Create user failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updateUserStatus(String userId, String status, {
    String? reason,
  }) async {
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '${BackendConfig.usersEndpoint}/$userId/status',
        body: {
          'status': status,
          'reason': reason,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      return response;
    } catch (e) {
      developer.log('Update user status failed: $e', name: 'BackendUserManagementService');
      return ApiResponse.error('Update user status failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updateUserRole(String userId, String role, {
    String? reason,
  }) async {
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '${BackendConfig.usersEndpoint}/$userId/role',
        body: {
          'role': role,
          'reason': reason,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      return response;
    } catch (e) {
      developer.log('Update user role failed: $e', name: 'BackendUserManagementService');
      return ApiResponse.error('Update user role failed: $e');
    }
  }

  Future<ApiResponse<List<UserPermission>>> getUserPermissions(String userId) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${BackendConfig.usersEndpoint}/$userId/permissions',
      );

      if (response.success && response.data != null) {
        final permissions = response.data!.map((p) => UserPermission.fromJson(p)).toList();
        return ApiResponse.success(permissions);
      }

      return ApiResponse.error(response.error ?? 'Failed to get user permissions');
    } catch (e) {
      developer.log('Get user permissions failed: $e', name: 'BackendUserManagementService');
      return ApiResponse.error('Get user permissions failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updateUserPermissions(String userId, List<String> permissions) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '${BackendConfig.usersEndpoint}/$userId/permissions',
        body: {
          'permissions': permissions,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      return response;
    } catch (e) {
      developer.log('Update user permissions failed: $e', name: 'BackendUserManagementService');
      return ApiResponse.error('Update user permissions failed: $e');
    }
  }

  Future<ApiResponse<List<TrustedDevice>>> getUserDevices(String userId) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${BackendConfig.userDevicesEndpoint}/$userId',
      );

      if (response.success && response.data != null) {
        final devices = response.data!.map((d) => TrustedDevice.fromJson(d)).toList();
        return ApiResponse.success(devices);
      }

      return ApiResponse.error(response.error ?? 'Failed to get user devices');
    } catch (e) {
      developer.log('Get user devices failed: $e', name: 'BackendUserManagementService');
      return ApiResponse.error('Get user devices failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> revokeUserDevice(String userId, String deviceId) async {
    try {
      final response = await _apiClient.delete<Map<String, dynamic>>(
        '${BackendConfig.userDevicesEndpoint}/$userId/$deviceId',
      );

      return response;
    } catch (e) {
      developer.log('Revoke user device failed: $e', name: 'BackendUserManagementService');
      return ApiResponse.error('Revoke user device failed: $e');
    }
  }

  Future<ApiResponse<BehavioralBiometrics>> getUserBehavioralProfile(String userId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${BackendConfig.userBehaviorEndpoint}/$userId/profile',
      );

      if (response.success && response.data != null) {
        final profile = BehavioralBiometrics.fromJson(response.data!);
        return ApiResponse.success(profile);
      }

      return ApiResponse.error(response.error ?? 'Failed to get user behavioral profile');
    } catch (e) {
      developer.log('Get user behavioral profile failed: $e', name: 'BackendUserManagementService');
      return ApiResponse.error('Get user behavioral profile failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updateUserBehavioralProfile(String userId, BehavioralBiometrics profile) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '${BackendConfig.userBehaviorEndpoint}/$userId/profile',
        body: profile.toJson(),
      );

      return response;
    } catch (e) {
      developer.log('Update user behavioral profile failed: $e', name: 'BackendUserManagementService');
      return ApiResponse.error('Update user behavioral profile failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> searchUsers({
    required String query,
    List<String>? fields,
    String? role,
    String? status,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{
        'q': query,
      };
      
      if (fields != null) queryParams['fields'] = fields.join(',');
      if (role != null) queryParams['role'] = role;
      if (status != null) queryParams['status'] = status;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final response = await _apiClient.get<Map<String, dynamic>>(
        '${BackendConfig.usersEndpoint}/search',
        queryParams: queryParams,
      );

      return response;
    } catch (e) {
      developer.log('Search users failed: $e', name: 'BackendUserManagementService');
      return ApiResponse.error('Search users failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getUserStats({
    String? timeRange,
    List<String>? metrics,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (timeRange != null) queryParams['time_range'] = timeRange;
      if (metrics != null) queryParams['metrics'] = metrics.join(',');

      final response = await _apiClient.get<Map<String, dynamic>>(
        '${BackendConfig.usersEndpoint}/stats',
        queryParams: queryParams,
      );

      return response;
    } catch (e) {
      developer.log('Get user stats failed: $e', name: 'BackendUserManagementService');
      return ApiResponse.error('Get user stats failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> bulkUserOperation({
    required String operation,
    required List<String> userIds,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.usersEndpoint}/bulk',
        body: {
          'operation': operation,
          'user_ids': userIds,
          'parameters': parameters ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
        timeout: BackendConfig.longOperationTimeout,
      );

      return response;
    } catch (e) {
      developer.log('Bulk user operation failed: $e', name: 'BackendUserManagementService');
      return ApiResponse.error('Bulk user operation failed: $e');
    }
  }

  void dispose() {
    // Cleanup if needed
  }
}
