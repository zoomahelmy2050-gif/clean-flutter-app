import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

// Enums
enum ThreatCategory { iot, container, api, supplyChain, cloud, aiml, quantum }
enum ThreatSeverity { low, medium, high, critical }
enum MitigationStatus { notStarted, inProgress, implemented, verified }
enum VulnerabilityType { 
  zeroDay, knownExploit, misconfiguration, 
  weakCredentials, outdatedSoftware, insecureAPI 
}

// Models
class EmergingThreat {
  final String id;
  final String name;
  final String description;
  final ThreatCategory category;
  final ThreatSeverity severity;
  final DateTime discoveredAt;
  final List<String> affectedSystems;
  final List<String> indicators;
  final double riskScore;
  final bool isActive;
  final Map<String, dynamic> metadata;

  EmergingThreat({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.severity,
    required this.discoveredAt,
    required this.affectedSystems,
    required this.indicators,
    required this.riskScore,
    required this.isActive,
    required this.metadata,
  });
}

class IoTDevice {
  final String id;
  final String name;
  final String type;
  final String manufacturer;
  final String firmware;
  final bool isSecure;
  final DateTime lastSeen;
  final List<String> vulnerabilities;
  final Map<String, dynamic> securityStatus;

  IoTDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.manufacturer,
    required this.firmware,
    required this.isSecure,
    required this.lastSeen,
    required this.vulnerabilities,
    required this.securityStatus,
  });
}

class ContainerSecurity {
  final String id;
  final String containerName;
  final String image;
  final String registry;
  final DateTime scannedAt;
  final int vulnerabilityCount;
  final Map<String, int> severityBreakdown;
  final List<String> misconfigurations;
  final bool isCompliant;

  ContainerSecurity({
    required this.id,
    required this.containerName,
    required this.image,
    required this.registry,
    required this.scannedAt,
    required this.vulnerabilityCount,
    required this.severityBreakdown,
    required this.misconfigurations,
    required this.isCompliant,
  });
}

class APIEndpoint {
  final String id;
  final String path;
  final String method;
  final int requestCount;
  final double avgResponseTime;
  final double errorRate;
  final List<String> securityIssues;
  final bool hasAuthentication;
  final bool hasRateLimiting;
  final DateTime lastAssessed;

  APIEndpoint({
    required this.id,
    required this.path,
    required this.method,
    required this.requestCount,
    required this.avgResponseTime,
    required this.errorRate,
    required this.securityIssues,
    required this.hasAuthentication,
    required this.hasRateLimiting,
    required this.lastAssessed,
  });
}

class SupplyChainRisk {
  final String id;
  final String vendor;
  final String component;
  final String version;
  final ThreatSeverity riskLevel;
  final List<String> vulnerabilities;
  final DateTime assessedAt;
  final String recommendation;
  final Map<String, dynamic> dependencies;

  SupplyChainRisk({
    required this.id,
    required this.vendor,
    required this.component,
    required this.version,
    required this.riskLevel,
    required this.vulnerabilities,
    required this.assessedAt,
    required this.recommendation,
    required this.dependencies,
  });
}

class ThreatMitigation {
  final String threatId;
  final String title;
  final String description;
  final MitigationStatus status;
  final List<String> steps;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String assignee;

  ThreatMitigation({
    required this.threatId,
    required this.title,
    required this.description,
    required this.status,
    required this.steps,
    required this.startedAt,
    this.completedAt,
    required this.assignee,
  });
}

// Service
class EmergingThreatsService extends ChangeNotifier {
  final List<EmergingThreat> _threats = [];
  final List<IoTDevice> _iotDevices = [];
  final List<ContainerSecurity> _containers = [];
  final List<APIEndpoint> _apiEndpoints = [];
  final List<SupplyChainRisk> _supplyChainRisks = [];
  final List<ThreatMitigation> _mitigations = [];
  Timer? _updateTimer;
  final Random _random = Random();

  List<EmergingThreat> get threats => _threats;
  List<IoTDevice> get iotDevices => _iotDevices;
  List<ContainerSecurity> get containers => _containers;
  List<APIEndpoint> get apiEndpoints => _apiEndpoints;
  List<SupplyChainRisk> get supplyChainRisks => _supplyChainRisks;
  List<ThreatMitigation> get mitigations => _mitigations;

  EmergingThreatsService() {
    _initializeMockData();
    _startRealTimeUpdates();
  }

  void _initializeMockData() {
    // Initialize Emerging Threats
    _threats.addAll([
      EmergingThreat(
        id: 'threat_001',
        name: 'IoT Botnet Vulnerability',
        description: 'Critical vulnerability in IoT device firmware allowing remote code execution',
        category: ThreatCategory.iot,
        severity: ThreatSeverity.critical,
        discoveredAt: DateTime.now().subtract(const Duration(hours: 2)),
        affectedSystems: ['Smart Cameras', 'Home Routers', 'Smart TVs'],
        indicators: ['Unusual network traffic', 'Unauthorized access attempts', 'Device reboots'],
        riskScore: 9.2,
        isActive: true,
        metadata: {'cve': 'CVE-2024-1234', 'exploitAvailable': true},
      ),
      EmergingThreat(
        id: 'threat_002',
        name: 'Container Escape Technique',
        description: 'New container escape method exploiting kernel vulnerabilities',
        category: ThreatCategory.container,
        severity: ThreatSeverity.high,
        discoveredAt: DateTime.now().subtract(const Duration(days: 1)),
        affectedSystems: ['Docker', 'Kubernetes', 'containerd'],
        indicators: ['Privilege escalation', 'Kernel module loading', 'Process injection'],
        riskScore: 8.5,
        isActive: true,
        metadata: {'affectedVersions': ['Docker < 20.10.9', 'K8s < 1.22']},
      ),
      EmergingThreat(
        id: 'threat_003',
        name: 'API Authentication Bypass',
        description: 'Authentication bypass in REST API implementations',
        category: ThreatCategory.api,
        severity: ThreatSeverity.high,
        discoveredAt: DateTime.now().subtract(const Duration(hours: 12)),
        affectedSystems: ['Payment Gateway', 'User Management API', 'Data Export API'],
        indicators: ['Unauthorized API calls', 'Token manipulation', 'Session hijacking'],
        riskScore: 8.8,
        isActive: true,
        metadata: {'owasp': 'A07:2021', 'impactedEndpoints': 15},
      ),
      EmergingThreat(
        id: 'threat_004',
        name: 'Supply Chain Malware',
        description: 'Malicious code injection in third-party dependencies',
        category: ThreatCategory.supplyChain,
        severity: ThreatSeverity.critical,
        discoveredAt: DateTime.now().subtract(const Duration(hours: 6)),
        affectedSystems: ['NPM packages', 'Python libraries', 'Maven dependencies'],
        indicators: ['Unexpected network connections', 'Data exfiltration', 'Code obfuscation'],
        riskScore: 9.5,
        isActive: true,
        metadata: {'packages': ['lib-utils v2.3.4', 'crypto-helper v1.0.2']},
      ),
    ]);

    // Initialize IoT Devices
    _iotDevices.addAll([
      IoTDevice(
        id: 'iot_001',
        name: 'Conference Room Camera',
        type: 'Security Camera',
        manufacturer: 'SecureCam Inc',
        firmware: 'v3.2.1',
        isSecure: false,
        lastSeen: DateTime.now(),
        vulnerabilities: ['CVE-2024-1234', 'Weak default password'],
        securityStatus: {'encryption': false, 'updates': 'outdated', 'authentication': 'weak'},
      ),
      IoTDevice(
        id: 'iot_002',
        name: 'Smart Thermostat',
        type: 'HVAC Controller',
        manufacturer: 'ClimateControl',
        firmware: 'v2.8.5',
        isSecure: true,
        lastSeen: DateTime.now(),
        vulnerabilities: [],
        securityStatus: {'encryption': true, 'updates': 'current', 'authentication': 'strong'},
      ),
      IoTDevice(
        id: 'iot_003',
        name: 'Office Router',
        type: 'Network Device',
        manufacturer: 'NetGear',
        firmware: 'v1.9.2',
        isSecure: false,
        lastSeen: DateTime.now(),
        vulnerabilities: ['Open telnet port', 'Outdated firmware'],
        securityStatus: {'encryption': true, 'updates': 'outdated', 'authentication': 'medium'},
      ),
    ]);

    // Initialize Container Security
    _containers.addAll([
      ContainerSecurity(
        id: 'cont_001',
        containerName: 'web-frontend',
        image: 'nginx:1.21.0',
        registry: 'docker.io',
        scannedAt: DateTime.now().subtract(const Duration(hours: 1)),
        vulnerabilityCount: 23,
        severityBreakdown: {'critical': 2, 'high': 5, 'medium': 10, 'low': 6},
        misconfigurations: ['Running as root', 'No resource limits'],
        isCompliant: false,
      ),
      ContainerSecurity(
        id: 'cont_002',
        containerName: 'api-backend',
        image: 'node:16-alpine',
        registry: 'docker.io',
        scannedAt: DateTime.now().subtract(const Duration(hours: 2)),
        vulnerabilityCount: 8,
        severityBreakdown: {'critical': 0, 'high': 1, 'medium': 3, 'low': 4},
        misconfigurations: ['Missing health check'],
        isCompliant: true,
      ),
      ContainerSecurity(
        id: 'cont_003',
        containerName: 'database',
        image: 'postgres:14',
        registry: 'docker.io',
        scannedAt: DateTime.now(),
        vulnerabilityCount: 12,
        severityBreakdown: {'critical': 1, 'high': 2, 'medium': 5, 'low': 4},
        misconfigurations: ['Weak password policy', 'No encryption at rest'],
        isCompliant: false,
      ),
    ]);

    // Initialize API Endpoints
    _apiEndpoints.addAll([
      APIEndpoint(
        id: 'api_001',
        path: '/api/v1/users',
        method: 'GET',
        requestCount: 45678,
        avgResponseTime: 145.2,
        errorRate: 0.12,
        securityIssues: ['No rate limiting', 'Missing authentication'],
        hasAuthentication: false,
        hasRateLimiting: false,
        lastAssessed: DateTime.now(),
      ),
      APIEndpoint(
        id: 'api_002',
        path: '/api/v1/payments',
        method: 'POST',
        requestCount: 12345,
        avgResponseTime: 234.5,
        errorRate: 0.05,
        securityIssues: [],
        hasAuthentication: true,
        hasRateLimiting: true,
        lastAssessed: DateTime.now(),
      ),
      APIEndpoint(
        id: 'api_003',
        path: '/api/v1/reports',
        method: 'GET',
        requestCount: 8901,
        avgResponseTime: 567.8,
        errorRate: 0.23,
        securityIssues: ['SQL injection risk', 'Excessive data exposure'],
        hasAuthentication: true,
        hasRateLimiting: false,
        lastAssessed: DateTime.now(),
      ),
    ]);

    // Initialize Supply Chain Risks
    _supplyChainRisks.addAll([
      SupplyChainRisk(
        id: 'supply_001',
        vendor: 'LogLib Inc',
        component: 'log4j',
        version: '2.14.1',
        riskLevel: ThreatSeverity.critical,
        vulnerabilities: ['Log4Shell (CVE-2021-44228)'],
        assessedAt: DateTime.now(),
        recommendation: 'Upgrade to version 2.17.1 immediately',
        dependencies: {'direct': 3, 'transitive': 12},
      ),
      SupplyChainRisk(
        id: 'supply_002',
        vendor: 'UtilCorp',
        component: 'commons-text',
        version: '1.9',
        riskLevel: ThreatSeverity.high,
        vulnerabilities: ['CVE-2022-42889'],
        assessedAt: DateTime.now(),
        recommendation: 'Update to version 1.10.0',
        dependencies: {'direct': 1, 'transitive': 5},
      ),
      SupplyChainRisk(
        id: 'supply_003',
        vendor: 'CryptoLib',
        component: 'openssl',
        version: '1.1.1k',
        riskLevel: ThreatSeverity.medium,
        vulnerabilities: ['CVE-2023-0286'],
        assessedAt: DateTime.now(),
        recommendation: 'Consider updating to latest stable version',
        dependencies: {'direct': 2, 'transitive': 8},
      ),
    ]);

    // Initialize Mitigations
    _mitigations.addAll([
      ThreatMitigation(
        threatId: 'threat_001',
        title: 'IoT Device Firmware Update',
        description: 'Update all affected IoT devices to latest firmware',
        status: MitigationStatus.inProgress,
        steps: [
          'Identify all affected devices',
          'Download latest firmware',
          'Schedule maintenance window',
          'Apply updates',
          'Verify functionality'
        ],
        startedAt: DateTime.now().subtract(const Duration(hours: 1)),
        assignee: 'Security Team',
      ),
      ThreatMitigation(
        threatId: 'threat_003',
        title: 'API Security Enhancement',
        description: 'Implement authentication and rate limiting on vulnerable endpoints',
        status: MitigationStatus.notStarted,
        steps: [
          'Audit all API endpoints',
          'Implement OAuth 2.0',
          'Add rate limiting',
          'Deploy WAF rules',
          'Monitor for anomalies'
        ],
        startedAt: DateTime.now(),
        assignee: 'Development Team',
      ),
    ]);
  }

  void _startRealTimeUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _simulateNewThreats();
      _updateDeviceStatus();
      _updateMetrics();
      notifyListeners();
    });
  }

  void _simulateNewThreats() {
    if (_random.nextDouble() > 0.85) {
      final categories = ThreatCategory.values;
      final category = categories[_random.nextInt(categories.length)];
      
      _threats.add(EmergingThreat(
        id: 'threat_${DateTime.now().millisecondsSinceEpoch}',
        name: 'New ${category.toString().split('.').last} Threat',
        description: 'Recently discovered vulnerability',
        category: category,
        severity: ThreatSeverity.values[_random.nextInt(4)],
        discoveredAt: DateTime.now(),
        affectedSystems: ['System ${_random.nextInt(10)}'],
        indicators: ['Indicator ${_random.nextInt(5)}'],
        riskScore: 5 + _random.nextDouble() * 5,
        isActive: true,
        metadata: {},
      ));
    }
  }

  void _updateDeviceStatus() {
    for (int i = 0; i < _iotDevices.length; i++) {
      final device = _iotDevices[i];
      _iotDevices[i] = IoTDevice(
        id: device.id,
        name: device.name,
        type: device.type,
        manufacturer: device.manufacturer,
        firmware: device.firmware,
        isSecure: _random.nextDouble() > 0.3,
        lastSeen: DateTime.now(),
        vulnerabilities: device.vulnerabilities,
        securityStatus: device.securityStatus,
      );
    }
  }

  void _updateMetrics() {
    for (int i = 0; i < _apiEndpoints.length; i++) {
      final endpoint = _apiEndpoints[i];
      _apiEndpoints[i] = APIEndpoint(
        id: endpoint.id,
        path: endpoint.path,
        method: endpoint.method,
        requestCount: endpoint.requestCount + _random.nextInt(100),
        avgResponseTime: endpoint.avgResponseTime + (_random.nextDouble() - 0.5) * 20,
        errorRate: max(0, endpoint.errorRate + (_random.nextDouble() - 0.5) * 0.02),
        securityIssues: endpoint.securityIssues,
        hasAuthentication: endpoint.hasAuthentication,
        hasRateLimiting: endpoint.hasRateLimiting,
        lastAssessed: DateTime.now(),
      );
    }
  }

  void startMitigation(String threatId) {
    final threat = _threats.firstWhere((t) => t.id == threatId);
    _mitigations.add(ThreatMitigation(
      threatId: threatId,
      title: 'Mitigate ${threat.name}',
      description: 'Automated mitigation for ${threat.name}',
      status: MitigationStatus.inProgress,
      steps: ['Analyze', 'Plan', 'Implement', 'Test', 'Deploy'],
      startedAt: DateTime.now(),
      assignee: 'Auto-Response System',
    ));
    notifyListeners();
  }

  void updateMitigationStatus(String threatId, MitigationStatus status) {
    final index = _mitigations.indexWhere((m) => m.threatId == threatId);
    if (index != -1) {
      final mitigation = _mitigations[index];
      _mitigations[index] = ThreatMitigation(
        threatId: mitigation.threatId,
        title: mitigation.title,
        description: mitigation.description,
        status: status,
        steps: mitigation.steps,
        startedAt: mitigation.startedAt,
        completedAt: status == MitigationStatus.verified ? DateTime.now() : null,
        assignee: mitigation.assignee,
      );
      notifyListeners();
    }
  }

  Map<String, dynamic> getThreatSummary() {
    final activeThreatCount = _threats.where((t) => t.isActive).length;
    final criticalThreats = _threats.where((t) => 
      t.isActive && t.severity == ThreatSeverity.critical).length;
    final vulnerableDevices = _iotDevices.where((d) => !d.isSecure).length;
    final nonCompliantContainers = _containers.where((c) => !c.isCompliant).length;
    final vulnerableAPIs = _apiEndpoints.where((a) => a.securityIssues.isNotEmpty).length;
    final highRiskSuppliers = _supplyChainRisks.where((r) => 
      r.riskLevel == ThreatSeverity.critical || r.riskLevel == ThreatSeverity.high).length;
    
    return {
      'activeThreats': activeThreatCount,
      'criticalThreats': criticalThreats,
      'vulnerableDevices': vulnerableDevices,
      'totalDevices': _iotDevices.length,
      'nonCompliantContainers': nonCompliantContainers,
      'totalContainers': _containers.length,
      'vulnerableAPIs': vulnerableAPIs,
      'totalAPIs': _apiEndpoints.length,
      'highRiskSuppliers': highRiskSuppliers,
      'totalSuppliers': _supplyChainRisks.length,
      'activeMitigations': _mitigations.where((m) => 
        m.status == MitigationStatus.inProgress).length,
    };
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}
