import 'dart:async';
import 'dart:developer' as developer;
import 'api_client.dart';
import 'backend_config.dart';
import '../models/siem_integration_models.dart';

class BackendSIEMService {
  static final BackendSIEMService _instance = BackendSIEMService._internal();
  factory BackendSIEMService() => _instance;
  BackendSIEMService._internal();

  final ApiClient _apiClient = ApiClient();

  Future<void> initialize() async {
    developer.log('Backend SIEM Service initialized', name: 'BackendSIEMService');
  }

  Future<ApiResponse<List<SIEMConnection>>> getSIEMConnections() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        BackendConfig.siemConnectionsEndpoint,
      );

      if (response.success && response.data != null) {
        final connections = response.data!.map((c) => SIEMConnection.fromJson(c)).toList();
        return ApiResponse.success(connections);
      }

      return ApiResponse.error(response.error ?? 'Failed to get SIEM connections');
    } catch (e) {
      developer.log('Get SIEM connections failed: $e', name: 'BackendSIEMService');
      return ApiResponse.error('Get SIEM connections failed: $e');
    }
  }

  Future<ApiResponse<SIEMConnection>> createSIEMConnection(SIEMConnection connection) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        BackendConfig.siemConnectionsEndpoint,
        body: connection.toJson(),
      );

      if (response.success && response.data != null) {
        final createdConnection = SIEMConnection.fromJson(response.data!);
        return ApiResponse.success(createdConnection);
      }

      return ApiResponse.error(response.error ?? 'Failed to create SIEM connection');
    } catch (e) {
      developer.log('Create SIEM connection failed: $e', name: 'BackendSIEMService');
      return ApiResponse.error('Create SIEM connection failed: $e');
    }
  }

  Future<ApiResponse<SIEMConnection>> updateSIEMConnection(String connectionId, Map<String, dynamic> updates) async {
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '${BackendConfig.siemConnectionsEndpoint}/$connectionId',
        body: updates,
      );

      if (response.success && response.data != null) {
        final updatedConnection = SIEMConnection.fromJson(response.data!);
        return ApiResponse.success(updatedConnection);
      }

      return ApiResponse.error(response.error ?? 'Failed to update SIEM connection');
    } catch (e) {
      developer.log('Update SIEM connection failed: $e', name: 'BackendSIEMService');
      return ApiResponse.error('Update SIEM connection failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> testSIEMConnection(String connectionId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.siemConnectionsEndpoint}/$connectionId/test',
        body: {'timestamp': DateTime.now().toIso8601String()},
      );

      return response;
    } catch (e) {
      developer.log('Test SIEM connection failed: $e', name: 'BackendSIEMService');
      return ApiResponse.error('Test SIEM connection failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> deleteSIEMConnection(String connectionId) async {
    try {
      final response = await _apiClient.delete<Map<String, dynamic>>(
        '${BackendConfig.siemConnectionsEndpoint}/$connectionId',
      );

      return response;
    } catch (e) {
      developer.log('Delete SIEM connection failed: $e', name: 'BackendSIEMService');
      return ApiResponse.error('Delete SIEM connection failed: $e');
    }
  }

  Future<ApiResponse<List<AutomatedPlaybook>>> getPlaybooks({
    String? status,
    String? trigger,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (trigger != null) queryParams['trigger'] = trigger;
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiClient.get<List<dynamic>>(
        '${BackendConfig.siemEndpoint}/playbooks',
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        final playbooks = response.data!.map((p) => AutomatedPlaybook.fromJson(p)).toList();
        return ApiResponse.success(playbooks);
      }

      return ApiResponse.error(response.error ?? 'Failed to get playbooks');
    } catch (e) {
      developer.log('Get playbooks failed: $e', name: 'BackendSIEMService');
      return ApiResponse.error('Get playbooks failed: $e');
    }
  }

  Future<ApiResponse<AutomatedPlaybook>> createPlaybook(AutomatedPlaybook playbook) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.siemEndpoint}/playbooks',
        body: playbook.toJson(),
      );

      if (response.success && response.data != null) {
        final createdPlaybook = AutomatedPlaybook.fromJson(response.data!);
        return ApiResponse.success(createdPlaybook);
      }

      return ApiResponse.error(response.error ?? 'Failed to create playbook');
    } catch (e) {
      developer.log('Create playbook failed: $e', name: 'BackendSIEMService');
      return ApiResponse.error('Create playbook failed: $e');
    }
  }

  Future<ApiResponse<AutomatedPlaybook>> updatePlaybook(String playbookId, Map<String, dynamic> updates) async {
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '${BackendConfig.siemEndpoint}/playbooks/$playbookId',
        body: updates,
      );

      if (response.success && response.data != null) {
        final updatedPlaybook = AutomatedPlaybook.fromJson(response.data!);
        return ApiResponse.success(updatedPlaybook);
      }

      return ApiResponse.error(response.error ?? 'Failed to update playbook');
    } catch (e) {
      developer.log('Update playbook failed: $e', name: 'BackendSIEMService');
      return ApiResponse.error('Update playbook failed: $e');
    }
  }

  Future<ApiResponse<PlaybookExecution>> executePlaybook(String playbookId, {
    Map<String, dynamic>? parameters,
    String? triggeredBy,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.siemEndpoint}/playbooks/$playbookId/execute',
        body: {
          'parameters': parameters ?? {},
          'triggered_by': triggeredBy,
          'timestamp': DateTime.now().toIso8601String(),
        },
        timeout: BackendConfig.longOperationTimeout,
      );

      if (response.success && response.data != null) {
        final execution = PlaybookExecution.fromJson(response.data!);
        return ApiResponse.success(execution);
      }

      return ApiResponse.error(response.error ?? 'Failed to execute playbook');
    } catch (e) {
      developer.log('Execute playbook failed: $e', name: 'BackendSIEMService');
      return ApiResponse.error('Execute playbook failed: $e');
    }
  }

  Future<ApiResponse<List<PlaybookExecution>>> getPlaybookExecutions({
    String? playbookId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (playbookId != null) queryParams['playbook_id'] = playbookId;
      if (status != null) queryParams['status'] = status;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final response = await _apiClient.get<List<dynamic>>(
        '${BackendConfig.siemEndpoint}/playbook-executions',
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        final executions = response.data!.map((e) => PlaybookExecution.fromJson(e)).toList();
        return ApiResponse.success(executions);
      }

      return ApiResponse.error(response.error ?? 'Failed to get playbook executions');
    } catch (e) {
      developer.log('Get playbook executions failed: $e', name: 'BackendSIEMService');
      return ApiResponse.error('Get playbook executions failed: $e');
    }
  }

  Future<ApiResponse<PlaybookExecution>> getPlaybookExecution(String executionId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${BackendConfig.siemEndpoint}/playbook-executions/$executionId',
      );

      if (response.success && response.data != null) {
        final execution = PlaybookExecution.fromJson(response.data!);
        return ApiResponse.success(execution);
      }

      return ApiResponse.error(response.error ?? 'Failed to get playbook execution');
    } catch (e) {
      developer.log('Get playbook execution failed: $e', name: 'BackendSIEMService');
      return ApiResponse.error('Get playbook execution failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> stopPlaybookExecution(String executionId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.siemEndpoint}/playbook-executions/$executionId/stop',
        body: {'timestamp': DateTime.now().toIso8601String()},
      );

      return response;
    } catch (e) {
      developer.log('Stop playbook execution failed: $e', name: 'BackendSIEMService');
      return ApiResponse.error('Stop playbook execution failed: $e');
    }
  }

  Future<ApiResponse<List<SIEMDataSync>>> getSyncOperations({
    String? connectionId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (connectionId != null) queryParams['connection_id'] = connectionId;
      if (status != null) queryParams['status'] = status;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiClient.get<List<dynamic>>(
        BackendConfig.siemSyncEndpoint,
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        final syncOps = response.data!.map((s) => SIEMDataSync.fromJson(s)).toList();
        return ApiResponse.success(syncOps);
      }

      return ApiResponse.error(response.error ?? 'Failed to get sync operations');
    } catch (e) {
      developer.log('Get sync operations failed: $e', name: 'BackendSIEMService');
      return ApiResponse.error('Get sync operations failed: $e');
    }
  }

  Future<ApiResponse<SIEMDataSync>> startDataSync(String connectionId, {
    String? syncType,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        BackendConfig.siemSyncEndpoint,
        body: {
          'connection_id': connectionId,
          'sync_type': syncType ?? 'full',
          'parameters': parameters ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.success && response.data != null) {
        final syncOp = SIEMDataSync.fromJson(response.data!);
        return ApiResponse.success(syncOp);
      }

      return ApiResponse.error(response.error ?? 'Failed to start data sync');
    } catch (e) {
      developer.log('Start data sync failed: $e', name: 'BackendSIEMService');
      return ApiResponse.error('Start data sync failed: $e');
    }
  }

  Future<ApiResponse<List<SIEMAlert>>> getSIEMAlerts({
    String? connectionId,
    String? severity,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (connectionId != null) queryParams['connection_id'] = connectionId;
      if (severity != null) queryParams['severity'] = severity;
      if (status != null) queryParams['status'] = status;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final response = await _apiClient.get<List<dynamic>>(
        BackendConfig.siemAlertsEndpoint,
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        final alerts = response.data!.map((a) => SIEMAlert.fromJson(a)).toList();
        return ApiResponse.success(alerts);
      }

      return ApiResponse.error(response.error ?? 'Failed to get SIEM alerts');
    } catch (e) {
      developer.log('Get SIEM alerts failed: $e', name: 'BackendSIEMService');
      return ApiResponse.error('Get SIEM alerts failed: $e');
    }
  }

  Future<ApiResponse<List<SIEMQuery>>> getSIEMQueries({
    String? connectionId,
    String? status,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (connectionId != null) queryParams['connection_id'] = connectionId;
      if (status != null) queryParams['status'] = status;
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiClient.get<List<dynamic>>(
        BackendConfig.siemQueriesEndpoint,
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        final queries = response.data!.map((q) => SIEMQuery.fromJson(q)).toList();
        return ApiResponse.success(queries);
      }

      return ApiResponse.error(response.error ?? 'Failed to get SIEM queries');
    } catch (e) {
      developer.log('Get SIEM queries failed: $e', name: 'BackendSIEMService');
      return ApiResponse.error('Get SIEM queries failed: $e');
    }
  }

  Future<ApiResponse<SIEMQuery>> executeSIEMQuery(String connectionId, String query, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.siemQueriesEndpoint}/execute',
        body: {
          'connection_id': connectionId,
          'query': query,
          'parameters': parameters ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
        timeout: BackendConfig.longOperationTimeout,
      );

      if (response.success && response.data != null) {
        final siemQuery = SIEMQuery.fromJson(response.data!);
        return ApiResponse.success(siemQuery);
      }

      return ApiResponse.error(response.error ?? 'Failed to execute SIEM query');
    } catch (e) {
      developer.log('Execute SIEM query failed: $e', name: 'BackendSIEMService');
      return ApiResponse.error('Execute SIEM query failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getSIEMStats({
    String? connectionId,
    String? timeRange,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (connectionId != null) queryParams['connection_id'] = connectionId;
      if (timeRange != null) queryParams['time_range'] = timeRange;

      final response = await _apiClient.get<Map<String, dynamic>>(
        '${BackendConfig.siemEndpoint}/stats',
        queryParams: queryParams,
      );

      return response;
    } catch (e) {
      developer.log('Get SIEM stats failed: $e', name: 'BackendSIEMService');
      return ApiResponse.error('Get SIEM stats failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> exportSIEMData({
    required String connectionId,
    required String format,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? dataTypes,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.siemEndpoint}/export',
        body: {
          'connection_id': connectionId,
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
      developer.log('Export SIEM data failed: $e', name: 'BackendSIEMService');
      return ApiResponse.error('Export SIEM data failed: $e');
    }
  }

  void dispose() {
    // Cleanup if needed
  }
}
