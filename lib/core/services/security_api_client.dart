import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:clean_flutter/features/admin/services/security_orchestration_service.dart';
import 'package:clean_flutter/features/admin/services/performance_monitoring_service.dart';
import 'package:clean_flutter/features/admin/services/emerging_threats_service.dart';

class SecurityApiClient {
  final String baseUrl;
  final String? apiKey;
  final http.Client _httpClient;
  
  SecurityApiClient({
    required this.baseUrl,
    this.apiKey,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();
  
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (apiKey != null) 'Authorization': 'Bearer $apiKey',
  };
  
  // Security Orchestration API
  Future<List<SecurityPlaybook>> getPlaybooks() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/security/playbooks'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => SecurityPlaybook(
          id: json['id'],
          name: json['name'],
          description: json['description'],
          category: json['category'] ?? 'General',
          status: PlaybookStatus.values.firstWhere(
            (s) => s.name == json['status'],
            orElse: () => PlaybookStatus.active,
          ),
          actions: (json['actions'] as List<dynamic>?)?.map((a) => PlaybookAction(
            id: a['id'],
            name: a['name'],
            description: a['description'],
            type: ActionType.values.firstWhere(
              (t) => t.name == a['type'],
              orElse: () => ActionType.manual,
            ),
            order: a['order'] ?? 0,
            parameters: Map<String, dynamic>.from(a['parameters'] ?? {}),
            conditions: List<String>.from(a['conditions'] ?? []),
            nextActionId: a['nextActionId'],
            estimatedMinutes: a['estimatedMinutes'] ?? 30,
          )).toList() ?? [],
          triggers: Map<String, dynamic>.from(json['triggers'] ?? {}),
          createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
          updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : DateTime.now(),
          author: json['author'] ?? 'System',
          useCount: json['useCount'] ?? 0,
          successRate: (json['successRate'] ?? 0).toDouble(),
        )).toList();
      }
      throw Exception('Failed to load playbooks: ${response.statusCode}');
    } catch (e) {
      print('Error fetching playbooks: $e');
      rethrow;
    }
  }
  
  Future<List<SecurityCase>> getSecurityCases() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/security/cases'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => SecurityCase(
          id: json['id'],
          title: json['title'],
          description: json['description'],
          type: CaseType.values.firstWhere(
            (t) => t.name == json['type'],
            orElse: () => CaseType.general,
          ),
          status: CaseStatus.values.firstWhere(
            (s) => s.name == json['status'],
            orElse: () => CaseStatus.open,
          ),
          priority: CasePriority.values.firstWhere(
            (p) => p.name == json['priority'],
            orElse: () => CasePriority.medium,
          ),
          assignee: json['assignee'],
          tags: List<String>.from(json['tags'] ?? []),
          createdAt: DateTime.parse(json['createdAt']),
          resolvedAt: json['resolvedAt'] != null
            ? DateTime.parse(json['resolvedAt'])
            : null,
          playbookId: json['playbookId'],
          activities: (json['activities'] as List<dynamic>?)?.map((a) => CaseActivity(
            id: a['id'],
            caseId: a['caseId'],
            action: a['action'],
            details: a['details'],
            performedBy: a['performedBy'],
            timestamp: DateTime.parse(a['timestamp']),
            metadata: a['metadata'] != null
              ? Map<String, dynamic>.from(a['metadata'])
              : null,
          )).toList() ?? [],
          evidence: Map<String, dynamic>.from(json['evidence'] ?? {}),
          affectedAssets: List<String>.from(json['affectedAssets'] ?? []),
        )).toList();
      }
      throw Exception('Failed to load cases: ${response.statusCode}');
    } catch (e) {
      print('Error fetching cases: $e');
      rethrow;
    }
  }
  
  Future<bool> executePlaybook(String playbookId, String caseId) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/security/playbooks/$playbookId/execute'),
        headers: _headers,
        body: json.encode({'caseId': caseId}),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error executing playbook: $e');
      return false;
    }
  }
  
  // Performance Monitoring API
  Future<List<SystemMetric>> getSystemMetrics() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/monitoring/metrics'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => SystemMetric(
          id: json['id'],
          name: json['name'],
          value: (json['value'] ?? 0).toDouble(),
          unit: json['unit'] ?? '%',
          type: MetricType.values.firstWhere(
            (t) => t.name == json['type'],
            orElse: () => MetricType.cpu,
          ),
          status: ServiceStatus.values.firstWhere(
            (s) => s.name == json['status'],
            orElse: () => ServiceStatus.healthy,
          ),
          timestamp: DateTime.parse(json['timestamp']),
          threshold: (json['threshold'] ?? 80).toDouble(),
          metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
        )).toList();
      }
      throw Exception('Failed to load metrics: ${response.statusCode}');
    } catch (e) {
      print('Error fetching metrics: $e');
      rethrow;
    }
  }
  
  Future<List<ServiceHealth>> getServiceHealth() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/monitoring/services'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ServiceHealth(
          name: json['name'],
          status: ServiceStatus.values.firstWhere(
            (s) => s.name == json['status'],
            orElse: () => ServiceStatus.healthy,
          ),
          uptime: (json['uptime'] ?? 99.9).toDouble(),
          requestCount: json['requestCount'] ?? 0,
          avgLatency: (json['avgLatency'] ?? 0).toDouble(),
          errorRate: (json['errorRate'] ?? 0).toDouble(),
          lastChecked: DateTime.parse(json['lastChecked']),
        )).toList();
      }
      throw Exception('Failed to load service health: ${response.statusCode}');
    } catch (e) {
      print('Error fetching service health: $e');
      rethrow;
    }
  }
  
  Future<List<PerformanceAlert>> getPerformanceAlerts() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/monitoring/alerts'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PerformanceAlert(
          id: json['id'],
          title: json['title'],
          description: json['description'],
          severity: AlertSeverity.values.firstWhere(
            (s) => s.name == json['severity'],
            orElse: () => AlertSeverity.info,
          ),
          timestamp: DateTime.parse(json['timestamp']),
          source: json['source'] ?? 'System',
          context: Map<String, dynamic>.from(json['context'] ?? {}),
          acknowledged: json['acknowledged'] ?? false,
        )).toList();
      }
      throw Exception('Failed to load alerts: ${response.statusCode}');
    } catch (e) {
      print('Error fetching alerts: $e');
      rethrow;
    }
  }
  
  // Emerging Threats API
  Future<List<EmergingThreat>> getEmergingThreats() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/threats/emerging'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => EmergingThreat(
          id: json['id'],
          name: json['name'],
          description: json['description'],
          severity: ThreatSeverity.values.firstWhere(
            (s) => s.name == json['severity'],
            orElse: () => ThreatSeverity.medium,
          ),
          category: json['category'] ?? 'Unknown',
          discoveredAt: json['discoveredAt'] != null
            ? DateTime.parse(json['discoveredAt'])
            : DateTime.now(),
          affectedSystems: List<String>.from(json['affectedSystems'] ?? []),
          indicators: List<String>.from(json['indicators'] ?? []),
          riskScore: (json['riskScore'] ?? 5).toDouble(),
          isActive: json['isActive'] ?? true,
          metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
        )).toList();
      }
      throw Exception('Failed to load threats: ${response.statusCode}');
    } catch (e) {
      print('Error fetching threats: $e');
      rethrow;
    }
  }
  
  Future<List<IoTDevice>> getIoTDevices() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/threats/iot-devices'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => IoTDevice(
          id: json['id'],
          name: json['name'],
          type: json['type'],
          manufacturer: json['manufacturer'],
          firmware: json['firmware'],
          lastSeen: DateTime.parse(json['lastSeen']),
          vulnerabilities: List<String>.from(json['vulnerabilities'] ?? []),
          securityStatus: json['securityStatus'] ?? 'Unknown',
          isSecure: json['isSecure'] ?? false,
        )).toList();
      }
      throw Exception('Failed to load IoT devices: ${response.statusCode}');
    } catch (e) {
      print('Error fetching IoT devices: $e');
      rethrow;
    }
  }
  
  Future<List<ContainerSecurity>> getContainerSecurity() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/threats/containers'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ContainerSecurity(
          id: json['id'],
          containerName: json['containerName'],
          image: json['image'],
          registry: json['registry'],
          scannedAt: DateTime.parse(json['scannedAt']),
          vulnerabilityCount: json['vulnerabilityCount'] ?? 0,
          severityBreakdown: Map<String, int>.from(json['severityBreakdown'] ?? {}),
          misconfigurations: List<String>.from(json['misconfigurations'] ?? []),
          isCompliant: json['isCompliant'] ?? false,
        )).toList();
      }
      throw Exception('Failed to load container security: ${response.statusCode}');
    } catch (e) {
      print('Error fetching container security: $e');
      rethrow;
    }
  }
  
  Future<bool> acknowledgeAlert(String alertId) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/monitoring/alerts/$alertId/acknowledge'),
        headers: _headers,
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error acknowledging alert: $e');
      return false;
    }
  }
  
  Future<bool> mitigateThreat(String threatId, String mitigation) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/threats/$threatId/mitigate'),
        headers: _headers,
        body: json.encode({'mitigation': mitigation}),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error mitigating threat: $e');
      return false;
    }
  }
  
  void dispose() {
    _httpClient.close();
  }
}
