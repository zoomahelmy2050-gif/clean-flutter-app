import 'dart:async';
import 'dart:developer' as developer;
import 'api_client.dart';
import 'backend_config.dart';
import '../../features/admin/models/threat_intelligence_models.dart';

class BackendThreatIntelligenceService {
  static final BackendThreatIntelligenceService _instance = BackendThreatIntelligenceService._internal();
  factory BackendThreatIntelligenceService() => _instance;
  BackendThreatIntelligenceService._internal();

  final ApiClient _apiClient = ApiClient();
  StreamSubscription? _threatFeedSubscription;

  Future<void> initialize() async {
    developer.log('Backend Threat Intelligence Service initialized', name: 'BackendThreatIntelligenceService');
  }

  Future<ApiResponse<List<ThreatFeed>>> getThreatFeeds() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        BackendConfig.threatFeedsEndpoint,
      );

      if (response.success && response.data != null) {
        final feeds = response.data!.map((f) => ThreatFeed.fromJson(f)).toList();
        return ApiResponse.success(feeds);
      }

      return ApiResponse.error(response.error ?? 'Failed to get threat feeds');
    } catch (e) {
      developer.log('Get threat feeds failed: $e', name: 'BackendThreatIntelligenceService');
      return ApiResponse.error('Get threat feeds failed: $e');
    }
  }

  Future<ApiResponse<IPReputation>> checkIPReputation(String ipAddress) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        BackendConfig.ipReputationEndpoint,
        queryParams: {'ip': ipAddress},
      );

      if (response.success && response.data != null) {
        final reputation = IPReputation.fromJson(response.data!);
        return ApiResponse.success(reputation);
      }

      return ApiResponse.error(response.error ?? 'Failed to check IP reputation');
    } catch (e) {
      developer.log('IP reputation check failed: $e', name: 'BackendThreatIntelligenceService');
      return ApiResponse.error('IP reputation check failed: $e');
    }
  }

  Future<ApiResponse<List<IOC>>> getIOCs({
    String? type,
    String? severity,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (type != null) queryParams['type'] = type;
      if (severity != null) queryParams['severity'] = severity;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final response = await _apiClient.get<List<dynamic>>(
        BackendConfig.iocEndpoint,
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        final iocs = response.data!.map((i) => IOC.fromJson(i)).toList();
        return ApiResponse.success(iocs);
      }

      return ApiResponse.error(response.error ?? 'Failed to get IOCs');
    } catch (e) {
      developer.log('Get IOCs failed: $e', name: 'BackendThreatIntelligenceService');
      return ApiResponse.error('Get IOCs failed: $e');
    }
  }

  Future<ApiResponse<IOC>> createIOC(IOC ioc) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        BackendConfig.iocEndpoint,
        body: ioc.toJson(),
      );

      if (response.success && response.data != null) {
        final createdIOC = IOC.fromJson(response.data!);
        return ApiResponse.success(createdIOC);
      }

      return ApiResponse.error(response.error ?? 'Failed to create IOC');
    } catch (e) {
      developer.log('Create IOC failed: $e', name: 'BackendThreatIntelligenceService');
      return ApiResponse.error('Create IOC failed: $e');
    }
  }

  Future<ApiResponse<List<ThreatHuntResult>>> executeThreatHunt(ThreatHuntQuery query) async {
    try {
      final response = await _apiClient.post<List<dynamic>>(
        '${BackendConfig.threatHuntingEndpoint}/execute',
        body: query.toJson(),
        timeout: BackendConfig.longOperationTimeout,
      );

      if (response.success && response.data != null) {
        final results = response.data!.map((r) => ThreatHuntResult.fromJson(r)).toList();
        return ApiResponse.success(results);
      }

      return ApiResponse.error(response.error ?? 'Failed to execute threat hunt');
    } catch (e) {
      developer.log('Threat hunt execution failed: $e', name: 'BackendThreatIntelligenceService');
      return ApiResponse.error('Threat hunt execution failed: $e');
    }
  }

  Future<ApiResponse<List<ThreatHuntQuery>>> getSavedQueries(String userId) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${BackendConfig.threatHuntingEndpoint}/queries',
        queryParams: {'userId': userId},
      );

      if (response.success && response.data != null) {
        final queries = response.data!.map((q) => ThreatHuntQuery.fromJson(q)).toList();
        return ApiResponse.success(queries);
      }

      return ApiResponse.error(response.error ?? 'Failed to get saved queries');
    } catch (e) {
      developer.log('Get saved queries failed: $e', name: 'BackendThreatIntelligenceService');
      return ApiResponse.error('Get saved queries failed: $e');
    }
  }

  Future<ApiResponse<ThreatHuntQuery>> saveQuery(ThreatHuntQuery query) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.threatHuntingEndpoint}/queries',
        body: query.toJson(),
      );

      if (response.success && response.data != null) {
        final savedQuery = ThreatHuntQuery.fromJson(response.data!);
        return ApiResponse.success(savedQuery);
      }

      return ApiResponse.error(response.error ?? 'Failed to save query');
    } catch (e) {
      developer.log('Save query failed: $e', name: 'BackendThreatIntelligenceService');
      return ApiResponse.error('Save query failed: $e');
    }
  }

  Future<ApiResponse<List<ThreatActor>>> getThreatActors({
    String? region,
    String? motivation,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (region != null) queryParams['region'] = region;
      if (motivation != null) queryParams['motivation'] = motivation;
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiClient.get<List<dynamic>>(
        '${BackendConfig.threatIntelEndpoint}/actors',
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        final actors = response.data!.map((a) => ThreatActor.fromJson(a)).toList();
        return ApiResponse.success(actors);
      }

      return ApiResponse.error(response.error ?? 'Failed to get threat actors');
    } catch (e) {
      developer.log('Get threat actors failed: $e', name: 'BackendThreatIntelligenceService');
      return ApiResponse.error('Get threat actors failed: $e');
    }
  }

  Future<ApiResponse<List<AttackPattern>>> getAttackPatterns({
    String? tactic,
    String? technique,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (tactic != null) queryParams['tactic'] = tactic;
      if (technique != null) queryParams['technique'] = technique;
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiClient.get<List<dynamic>>(
        '${BackendConfig.threatIntelEndpoint}/attack-patterns',
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        final patterns = response.data!.map((p) => AttackPattern.fromJson(p)).toList();
        return ApiResponse.success(patterns);
      }

      return ApiResponse.error(response.error ?? 'Failed to get attack patterns');
    } catch (e) {
      developer.log('Get attack patterns failed: $e', name: 'BackendThreatIntelligenceService');
      return ApiResponse.error('Get attack patterns failed: $e');
    }
  }

  Stream<ThreatFeed> subscribeThreatFeed() {
    return _apiClient.connectWebSocket<ThreatFeed>(
      BackendConfig.wsThreatFeed,
      parser: (data) => ThreatFeed.fromJson(data),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> enrichIOC(String iocValue, String iocType) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.iocEndpoint}/enrich',
        body: {
          'value': iocValue,
          'type': iocType,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return response;
    } catch (e) {
      developer.log('IOC enrichment failed: $e', name: 'BackendThreatIntelligenceService');
      return ApiResponse.error('IOC enrichment failed: $e');
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> bulkIOCLookup(List<String> iocs) async {
    try {
      final response = await _apiClient.post<List<dynamic>>(
        '${BackendConfig.iocEndpoint}/bulk-lookup',
        body: {
          'iocs': iocs,
          'timestamp': DateTime.now().toIso8601String(),
        },
        timeout: BackendConfig.longOperationTimeout,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data!.cast<Map<String, dynamic>>());
      }

      return ApiResponse.error(response.error ?? 'Failed to perform bulk IOC lookup');
    } catch (e) {
      developer.log('Bulk IOC lookup failed: $e', name: 'BackendThreatIntelligenceService');
      return ApiResponse.error('Bulk IOC lookup failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getThreatIntelligenceStats() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${BackendConfig.threatIntelEndpoint}/stats',
      );

      return response;
    } catch (e) {
      developer.log('Get threat intelligence stats failed: $e', name: 'BackendThreatIntelligenceService');
      return ApiResponse.error('Get threat intelligence stats failed: $e');
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> searchThreatIntelligence({
    required String query,
    List<String>? types,
    String? severity,
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
      if (severity != null) queryParams['severity'] = severity;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final response = await _apiClient.get<List<dynamic>>(
        '${BackendConfig.threatIntelEndpoint}/search',
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data!.cast<Map<String, dynamic>>());
      }

      return ApiResponse.error(response.error ?? 'Failed to search threat intelligence');
    } catch (e) {
      developer.log('Threat intelligence search failed: $e', name: 'BackendThreatIntelligenceService');
      return ApiResponse.error('Threat intelligence search failed: $e');
    }
  }

  void dispose() {
    _threatFeedSubscription?.cancel();
  }
}
