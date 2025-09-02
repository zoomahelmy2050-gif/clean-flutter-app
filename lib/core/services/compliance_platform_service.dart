import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CompliancePlatformService extends ChangeNotifier {
  static CompliancePlatformService? _instance;
  static CompliancePlatformService get instance => _instance ??= CompliancePlatformService._();
  CompliancePlatformService._();

  final Dio _dio = Dio();
  bool _isInitialized = false;
  bool _useRealConnections = false;

  // Platform configurations loaded from environment
  final Map<String, String> _platformConfigs = {};
  final Map<String, String> _apiKeys = {};
  final Map<String, String> _usernames = {};
  final Map<String, String> _passwords = {};

  final StreamController<ComplianceEvent> _eventController = StreamController.broadcast();
  Stream<ComplianceEvent> get eventStream => _eventController.stream;

  Timer? _syncTimer;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load configuration from environment variables
      _loadEnvironmentConfig();
      
      _dio.options.connectTimeout = const Duration(minutes: 2);
      _dio.options.receiveTimeout = const Duration(minutes: 5);

      _useRealConnections = _hasValidCredentials();
      
      if (_useRealConnections) {
        // Start periodic sync only if we have real connections
        _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) => _syncAllPlatforms());
        developer.log('Compliance platform service initialized with real connections');
      } else {
        developer.log('Compliance platform service initialized in mock mode - no credentials configured');
        _startMockDataGeneration();
      }
      
      _isInitialized = true;
    } catch (e) {
      developer.log('Failed to initialize compliance platform service: $e');
      _isInitialized = true;
      _startMockDataGeneration();
    }
  }
  
  void _loadEnvironmentConfig() {
    // ServiceNow
    _platformConfigs['servicenow'] = dotenv.env['SERVICENOW_URL'] ?? '';
    _apiKeys['servicenow'] = dotenv.env['SERVICENOW_API_KEY'] ?? '';
    _usernames['servicenow'] = dotenv.env['SERVICENOW_USERNAME'] ?? '';
    _passwords['servicenow'] = dotenv.env['SERVICENOW_PASSWORD'] ?? '';
    
    // RSA Archer
    _platformConfigs['archer'] = dotenv.env['ARCHER_URL'] ?? '';
    _apiKeys['archer'] = dotenv.env['ARCHER_API_KEY'] ?? '';
    _usernames['archer'] = dotenv.env['ARCHER_USERNAME'] ?? '';
    _passwords['archer'] = dotenv.env['ARCHER_PASSWORD'] ?? '';
    
    // MetricStream
    _platformConfigs['metricstream'] = dotenv.env['METRICSTREAM_URL'] ?? '';
    _apiKeys['metricstream'] = dotenv.env['METRICSTREAM_API_KEY'] ?? '';
    
    // Resolver
    _platformConfigs['resolver'] = dotenv.env['RESOLVER_URL'] ?? '';
    _apiKeys['resolver'] = dotenv.env['RESOLVER_API_KEY'] ?? '';
    
    // LogicGate
    _platformConfigs['logicgate'] = dotenv.env['LOGICGATE_URL'] ?? '';
    _apiKeys['logicgate'] = dotenv.env['LOGICGATE_API_KEY'] ?? '';
    
    // AuditBoard
    _platformConfigs['auditboard'] = dotenv.env['AUDITBOARD_URL'] ?? '';
    _apiKeys['auditboard'] = dotenv.env['AUDITBOARD_API_KEY'] ?? '';
  }
  
  bool _hasValidCredentials() {
    return _platformConfigs.values.any((url) => url.isNotEmpty) &&
           _apiKeys.values.any((key) => key.isNotEmpty);
  }
  
  void _startMockDataGeneration() {
    // Generate mock compliance events for development/testing
    Timer.periodic(const Duration(minutes: 5), (timer) {
      if (!_isInitialized) {
        timer.cancel();
        return;
      }
      
      _generateMockComplianceEvent();
    });
  }
  
  void _generateMockComplianceEvent() {
    final platforms = ['ServiceNow', 'Archer', 'MetricStream', 'Resolver', 'LogicGate', 'AuditBoard'];
    final eventTypes = [ComplianceEventType.incidentCreated, ComplianceEventType.recordCreated, ComplianceEventType.riskSubmitted];
    
    final randomPlatform = platforms[DateTime.now().millisecondsSinceEpoch % platforms.length];
    final randomEventType = eventTypes[DateTime.now().millisecondsSinceEpoch % eventTypes.length];
    
    _eventController.add(ComplianceEvent(
      type: randomEventType,
      platform: randomPlatform,
      data: {
        'id': 'mock_${DateTime.now().millisecondsSinceEpoch}',
        'title': 'Mock Compliance Event',
        'description': 'Generated for development testing',
        'severity': 'medium',
        'timestamp': DateTime.now().toIso8601String(),
        'isMock': true,
      },
      timestamp: DateTime.now(),
    ));
  }

  // ServiceNow GRC Integration
  Future<ComplianceResult> createServiceNowIncident({
    required String title,
    required String description,
    required String category,
    required String priority,
    Map<String, dynamic>? customFields,
  }) async {
    try {
      final response = await _dio.post(
        '${_platformConfigs['servicenow']}incident',
        data: {
          'short_description': title,
          'description': description,
          'category': category,
          'priority': priority,
          'caller_id': 'security_system',
          'assignment_group': 'Security Team',
          'state': '1', // New
          ...?customFields,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${_apiKeys['servicenow']}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201) {
        final incident = ComplianceIncident.fromJson(response.data['result']);
        _eventController.add(ComplianceEvent(
          type: ComplianceEventType.incidentCreated,
          platform: 'ServiceNow',
          data: incident.toJson(),
          timestamp: DateTime.now(),
        ));

        return ComplianceResult(
          success: true,
          data: incident,
          platform: 'ServiceNow',
        );
      } else {
        return ComplianceResult(
          success: false,
          error: 'ServiceNow incident creation failed: ${response.statusCode}',
          platform: 'ServiceNow',
        );
      }
    } catch (e) {
      developer.log('ServiceNow incident creation error: $e');
      return ComplianceResult(
        success: false,
        error: e.toString(),
        platform: 'ServiceNow',
      );
    }
  }

  Future<List<ComplianceAssessment>> getServiceNowAssessments() async {
    try {
      final response = await _dio.get(
        '${_platformConfigs['servicenow']}u_compliance_assessment',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${_apiKeys['servicenow']}',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = response.data['result'];
        return results.map((data) => ComplianceAssessment.fromJson(data)).toList();
      }
      return [];
    } catch (e) {
      developer.log('ServiceNow assessments retrieval error: $e');
      return [];
    }
  }

  // RSA Archer Integration
  Future<ComplianceResult> createArcherRecord({
    required String applicationId,
    required Map<String, dynamic> fieldValues,
  }) async {
    try {
      final response = await _dio.post(
        '${_platformConfigs['archer']}content',
        data: {
          'RequestedObject': {
            'ApplicationId': applicationId,
            'FieldContents': fieldValues,
          }
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${_apiKeys['archer']}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final recordId = response.data['RequestedObject']['Id'];
        _eventController.add(ComplianceEvent(
          type: ComplianceEventType.recordCreated,
          platform: 'Archer',
          data: {'recordId': recordId, 'applicationId': applicationId},
          timestamp: DateTime.now(),
        ));

        return ComplianceResult(
          success: true,
          data: {'recordId': recordId},
          platform: 'Archer',
        );
      } else {
        return ComplianceResult(
          success: false,
          error: 'Archer record creation failed: ${response.statusCode}',
          platform: 'Archer',
        );
      }
    } catch (e) {
      developer.log('Archer record creation error: $e');
      return ComplianceResult(
        success: false,
        error: e.toString(),
        platform: 'Archer',
      );
    }
  }

  // MetricStream Integration
  Future<ComplianceResult> submitMetricStreamRisk({
    required String riskTitle,
    required String riskDescription,
    required String riskCategory,
    required int riskScore,
    required String owner,
  }) async {
    try {
      final response = await _dio.post(
        '${_platformConfigs['metricstream']}risks',
        data: {
          'title': riskTitle,
          'description': riskDescription,
          'category': riskCategory,
          'inherent_risk_score': riskScore,
          'risk_owner': owner,
          'status': 'Open',
          'created_date': DateTime.now().toIso8601String(),
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${_apiKeys['metricstream']}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201) {
        final riskId = response.data['id'];
        _eventController.add(ComplianceEvent(
          type: ComplianceEventType.riskSubmitted,
          platform: 'MetricStream',
          data: {'riskId': riskId, 'riskScore': riskScore},
          timestamp: DateTime.now(),
        ));

        return ComplianceResult(
          success: true,
          data: {'riskId': riskId},
          platform: 'MetricStream',
        );
      } else {
        return ComplianceResult(
          success: false,
          error: 'MetricStream risk submission failed: ${response.statusCode}',
          platform: 'MetricStream',
        );
      }
    } catch (e) {
      developer.log('MetricStream risk submission error: $e');
      return ComplianceResult(
        success: false,
        error: e.toString(),
        platform: 'MetricStream',
      );
    }
  }

  // Resolver Integration
  Future<ComplianceResult> createResolverIncident({
    required String title,
    required String description,
    required String severity,
    required List<String> tags,
  }) async {
    try {
      final response = await _dio.post(
        '${_platformConfigs['resolver']}incidents',
        data: {
          'title': title,
          'description': description,
          'severity': severity,
          'tags': tags,
          'status': 'open',
          'reporter': 'security_system',
          'created_at': DateTime.now().toIso8601String(),
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${_apiKeys['resolver']}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201) {
        final incidentId = response.data['id'];
        return ComplianceResult(
          success: true,
          data: {'incidentId': incidentId},
          platform: 'Resolver',
        );
      } else {
        return ComplianceResult(
          success: false,
          error: 'Resolver incident creation failed: ${response.statusCode}',
          platform: 'Resolver',
        );
      }
    } catch (e) {
      developer.log('Resolver incident creation error: $e');
      return ComplianceResult(
        success: false,
        error: e.toString(),
        platform: 'Resolver',
      );
    }
  }

  // LogicGate Integration
  Future<ComplianceResult> createLogicGateWorkflow({
    required String workflowId,
    required Map<String, dynamic> stepData,
  }) async {
    try {
      final response = await _dio.post(
        '${_platformConfigs['logicgate']}workflows/$workflowId/records',
        data: {
          'fields': stepData,
          'status': 'active',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${_apiKeys['logicgate']}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201) {
        final recordId = response.data['id'];
        return ComplianceResult(
          success: true,
          data: {'recordId': recordId, 'workflowId': workflowId},
          platform: 'LogicGate',
        );
      } else {
        return ComplianceResult(
          success: false,
          error: 'LogicGate workflow creation failed: ${response.statusCode}',
          platform: 'LogicGate',
        );
      }
    } catch (e) {
      developer.log('LogicGate workflow creation error: $e');
      return ComplianceResult(
        success: false,
        error: e.toString(),
        platform: 'LogicGate',
      );
    }
  }

  // AuditBoard Integration
  Future<ComplianceResult> createAuditBoardFinding({
    required String title,
    required String description,
    required String riskRating,
    required String controlId,
  }) async {
    try {
      final response = await _dio.post(
        '${_platformConfigs['auditboard']}findings',
        data: {
          'title': title,
          'description': description,
          'risk_rating': riskRating,
          'control_id': controlId,
          'status': 'open',
          'created_date': DateTime.now().toIso8601String(),
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${_apiKeys['auditboard']}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201) {
        final findingId = response.data['id'];
        return ComplianceResult(
          success: true,
          data: {'findingId': findingId},
          platform: 'AuditBoard',
        );
      } else {
        return ComplianceResult(
          success: false,
          error: 'AuditBoard finding creation failed: ${response.statusCode}',
          platform: 'AuditBoard',
        );
      }
    } catch (e) {
      developer.log('AuditBoard finding creation error: $e');
      return ComplianceResult(
        success: false,
        error: e.toString(),
        platform: 'AuditBoard',
      );
    }
  }

  // Unified compliance reporting
  Future<ComplianceReport> generateUnifiedReport({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? platforms,
  }) async {
    final targetPlatforms = platforms ?? _platformConfigs.keys.toList();
    final reportData = <String, dynamic>{};

    for (final platform in targetPlatforms) {
      try {
        switch (platform) {
          case 'servicenow':
            reportData[platform] = await _getServiceNowReportData(startDate, endDate);
            break;
          case 'archer':
            reportData[platform] = await _getArcherReportData(startDate, endDate);
            break;
          case 'metricstream':
            reportData[platform] = await _getMetricStreamReportData(startDate, endDate);
            break;
          case 'resolver':
            reportData[platform] = await _getResolverReportData(startDate, endDate);
            break;
          case 'logicgate':
            reportData[platform] = await _getLogicGateReportData(startDate, endDate);
            break;
          case 'auditboard':
            reportData[platform] = await _getAuditBoardReportData(startDate, endDate);
            break;
        }
      } catch (e) {
        developer.log('Error getting report data from $platform: $e');
        reportData[platform] = {'error': e.toString()};
      }
    }

    return ComplianceReport(
      startDate: startDate,
      endDate: endDate,
      platforms: targetPlatforms,
      data: reportData,
      generatedAt: DateTime.now(),
    );
  }

  // Platform-specific report data methods
  Future<Map<String, dynamic>> _getServiceNowReportData(DateTime start, DateTime end) async {
    final incidents = await _getServiceNowIncidents(start, end);
    final assessments = await getServiceNowAssessments();
    
    return {
      'incidents': incidents.length,
      'assessments': assessments.length,
      'open_incidents': incidents.where((i) => i.status == 'Open').length,
      'high_priority_incidents': incidents.where((i) => i.priority == 'High').length,
    };
  }

  Future<Map<String, dynamic>> _getArcherReportData(DateTime start, DateTime end) async {
    // Implementation for Archer report data
    return {
      'records_created': 0,
      'applications_updated': 0,
    };
  }

  Future<Map<String, dynamic>> _getMetricStreamReportData(DateTime start, DateTime end) async {
    // Implementation for MetricStream report data
    return {
      'risks_submitted': 0,
      'high_risk_items': 0,
    };
  }

  Future<Map<String, dynamic>> _getResolverReportData(DateTime start, DateTime end) async {
    // Implementation for Resolver report data
    return {
      'incidents_created': 0,
      'resolved_incidents': 0,
    };
  }

  Future<Map<String, dynamic>> _getLogicGateReportData(DateTime start, DateTime end) async {
    // Implementation for LogicGate report data
    return {
      'workflows_initiated': 0,
      'completed_workflows': 0,
    };
  }

  Future<Map<String, dynamic>> _getAuditBoardReportData(DateTime start, DateTime end) async {
    // Implementation for AuditBoard report data
    return {
      'findings_created': 0,
      'remediated_findings': 0,
    };
  }

  Future<List<ComplianceIncident>> _getServiceNowIncidents(DateTime start, DateTime end) async {
    try {
      final response = await _dio.get(
        '${_platformConfigs['servicenow']}incident',
        queryParameters: {
          'sysparm_query': 'created_on>=${start.toIso8601String()}^created_on<=${end.toIso8601String()}',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${_apiKeys['servicenow']}',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = response.data['result'];
        return results.map((data) => ComplianceIncident.fromJson(data)).toList();
      }
      return [];
    } catch (e) {
      developer.log('ServiceNow incidents retrieval error: $e');
      return [];
    }
  }

  // Sync all platforms
  Future<void> _syncAllPlatforms() async {
    developer.log('Starting compliance platform sync');
    
    for (final platform in _platformConfigs.keys) {
      try {
        await _syncPlatform(platform);
      } catch (e) {
        developer.log('Error syncing $platform: $e');
      }
    }

    _eventController.add(ComplianceEvent(
      type: ComplianceEventType.syncCompleted,
      platform: 'All',
      data: {'timestamp': DateTime.now().toIso8601String()},
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _syncPlatform(String platform) async {
    // Platform-specific sync logic
    developer.log('Syncing $platform');
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _eventController.close();
    super.dispose();
  }
}

// Data models
enum ComplianceEventType {
  incidentCreated,
  recordCreated,
  riskSubmitted,
  findingCreated,
  syncCompleted,
}

class ComplianceEvent {
  final ComplianceEventType type;
  final String platform;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  ComplianceEvent({
    required this.type,
    required this.platform,
    required this.data,
    required this.timestamp,
  });
}

class ComplianceResult {
  final bool success;
  final dynamic data;
  final String? error;
  final String platform;

  ComplianceResult({
    required this.success,
    this.data,
    this.error,
    required this.platform,
  });
}

class ComplianceIncident {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final DateTime createdAt;

  ComplianceIncident({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
  });

  factory ComplianceIncident.fromJson(Map<String, dynamic> json) {
    return ComplianceIncident(
      id: json['sys_id'] ?? '',
      title: json['short_description'] ?? '',
      description: json['description'] ?? '',
      status: json['state'] ?? '',
      priority: json['priority'] ?? '',
      createdAt: DateTime.tryParse(json['sys_created_on'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ComplianceAssessment {
  final String id;
  final String name;
  final String framework;
  final String status;
  final double completionPercentage;

  ComplianceAssessment({
    required this.id,
    required this.name,
    required this.framework,
    required this.status,
    required this.completionPercentage,
  });

  factory ComplianceAssessment.fromJson(Map<String, dynamic> json) {
    return ComplianceAssessment(
      id: json['sys_id'] ?? '',
      name: json['name'] ?? '',
      framework: json['framework'] ?? '',
      status: json['status'] ?? '',
      completionPercentage: double.tryParse(json['completion_percentage']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class ComplianceReport {
  final DateTime startDate;
  final DateTime endDate;
  final List<String> platforms;
  final Map<String, dynamic> data;
  final DateTime generatedAt;

  ComplianceReport({
    required this.startDate,
    required this.endDate,
    required this.platforms,
    required this.data,
    required this.generatedAt,
  });
}
