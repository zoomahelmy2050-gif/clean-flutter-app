import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Models for Third-Party Integrations
class MISPEvent {
  final String id;
  final String info;
  final String threatLevel;
  final String analysis;
  final DateTime date;
  final List<String> tags;
  final int attributeCount;
  final bool published;
  final String orgc;
  final String distribution;

  MISPEvent({
    required this.id,
    required this.info,
    required this.threatLevel,
    required this.analysis,
    required this.date,
    required this.tags,
    required this.attributeCount,
    required this.published,
    required this.orgc,
    required this.distribution,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'info': info,
    'threatLevel': threatLevel,
    'analysis': analysis,
    'date': date.toIso8601String(),
    'tags': tags,
    'attributeCount': attributeCount,
    'published': published,
    'orgc': orgc,
    'distribution': distribution,
  };

  factory MISPEvent.fromJson(Map<String, dynamic> json) => MISPEvent(
    id: json['id'],
    info: json['info'],
    threatLevel: json['threatLevel'],
    analysis: json['analysis'],
    date: DateTime.parse(json['date']),
    tags: List<String>.from(json['tags']),
    attributeCount: json['attributeCount'],
    published: json['published'],
    orgc: json['orgc'],
    distribution: json['distribution'],
  );
}

class ServiceNowIncident {
  final String number;
  final String shortDescription;
  final String priority;
  final String state;
  final String assignedTo;
  final String category;
  final DateTime createdOn;
  final DateTime updatedOn;
  final String impact;
  final String urgency;
  final String resolvedBy;
  final String closeNotes;

  ServiceNowIncident({
    required this.number,
    required this.shortDescription,
    required this.priority,
    required this.state,
    required this.assignedTo,
    required this.category,
    required this.createdOn,
    required this.updatedOn,
    required this.impact,
    required this.urgency,
    required this.resolvedBy,
    required this.closeNotes,
  });

  Map<String, dynamic> toJson() => {
    'number': number,
    'shortDescription': shortDescription,
    'priority': priority,
    'state': state,
    'assignedTo': assignedTo,
    'category': category,
    'createdOn': createdOn.toIso8601String(),
    'updatedOn': updatedOn.toIso8601String(),
    'impact': impact,
    'urgency': urgency,
    'resolvedBy': resolvedBy,
    'closeNotes': closeNotes,
  };

  factory ServiceNowIncident.fromJson(Map<String, dynamic> json) => ServiceNowIncident(
    number: json['number'],
    shortDescription: json['shortDescription'],
    priority: json['priority'],
    state: json['state'],
    assignedTo: json['assignedTo'],
    category: json['category'],
    createdOn: DateTime.parse(json['createdOn']),
    updatedOn: DateTime.parse(json['updatedOn']),
    impact: json['impact'],
    urgency: json['urgency'],
    resolvedBy: json['resolvedBy'],
    closeNotes: json['closeNotes'],
  );
}

class CSPMFinding {
  final String id;
  final String cloudProvider;
  final String service;
  final String resource;
  final String region;
  final String severity;
  final String complianceFramework;
  final String control;
  final String description;
  final String remediation;
  final DateTime discoveredAt;
  final String status;
  final double riskScore;

  CSPMFinding({
    required this.id,
    required this.cloudProvider,
    required this.service,
    required this.resource,
    required this.region,
    required this.severity,
    required this.complianceFramework,
    required this.control,
    required this.description,
    required this.remediation,
    required this.discoveredAt,
    required this.status,
    required this.riskScore,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'cloudProvider': cloudProvider,
    'service': service,
    'resource': resource,
    'region': region,
    'severity': severity,
    'complianceFramework': complianceFramework,
    'control': control,
    'description': description,
    'remediation': remediation,
    'discoveredAt': discoveredAt.toIso8601String(),
    'status': status,
    'riskScore': riskScore,
  };

  factory CSPMFinding.fromJson(Map<String, dynamic> json) => CSPMFinding(
    id: json['id'],
    cloudProvider: json['cloudProvider'],
    service: json['service'],
    resource: json['resource'],
    region: json['region'],
    severity: json['severity'],
    complianceFramework: json['complianceFramework'],
    control: json['control'],
    description: json['description'],
    remediation: json['remediation'],
    discoveredAt: DateTime.parse(json['discoveredAt']),
    status: json['status'],
    riskScore: json['riskScore'].toDouble(),
  );
}

class NVDVulnerability {
  final String cveId;
  final String description;
  final double cvssScore;
  final String severity;
  final String vector;
  final DateTime publishedDate;
  final DateTime modifiedDate;
  final List<String> affectedProducts;
  final List<String> references;
  final bool exploitAvailable;
  final String cweId;

  NVDVulnerability({
    required this.cveId,
    required this.description,
    required this.cvssScore,
    required this.severity,
    required this.vector,
    required this.publishedDate,
    required this.modifiedDate,
    required this.affectedProducts,
    required this.references,
    required this.exploitAvailable,
    required this.cweId,
  });

  Map<String, dynamic> toJson() => {
    'cveId': cveId,
    'description': description,
    'cvssScore': cvssScore,
    'severity': severity,
    'vector': vector,
    'publishedDate': publishedDate.toIso8601String(),
    'modifiedDate': modifiedDate.toIso8601String(),
    'affectedProducts': affectedProducts,
    'references': references,
    'exploitAvailable': exploitAvailable,
    'cweId': cweId,
  };

  factory NVDVulnerability.fromJson(Map<String, dynamic> json) => NVDVulnerability(
    cveId: json['cveId'],
    description: json['description'],
    cvssScore: json['cvssScore'].toDouble(),
    severity: json['severity'],
    vector: json['vector'],
    publishedDate: DateTime.parse(json['publishedDate']),
    modifiedDate: DateTime.parse(json['modifiedDate']),
    affectedProducts: List<String>.from(json['affectedProducts']),
    references: List<String>.from(json['references']),
    exploitAvailable: json['exploitAvailable'],
    cweId: json['cweId'],
  );
}

class IntegrationConfig {
  final String name;
  final String type;
  final String endpoint;
  final String apiKey;
  final bool enabled;
  final DateTime lastSync;
  final String status;
  final Map<String, dynamic> settings;

  IntegrationConfig({
    required this.name,
    required this.type,
    required this.endpoint,
    required this.apiKey,
    required this.enabled,
    required this.lastSync,
    required this.status,
    required this.settings,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'endpoint': endpoint,
    'apiKey': apiKey,
    'enabled': enabled,
    'lastSync': lastSync.toIso8601String(),
    'status': status,
    'settings': settings,
  };

  factory IntegrationConfig.fromJson(Map<String, dynamic> json) => IntegrationConfig(
    name: json['name'],
    type: json['type'],
    endpoint: json['endpoint'],
    apiKey: json['apiKey'],
    enabled: json['enabled'],
    lastSync: DateTime.parse(json['lastSync']),
    status: json['status'],
    settings: Map<String, dynamic>.from(json['settings']),
  );
}

class ThirdPartyIntegrationsService extends ChangeNotifier {
  final List<MISPEvent> _mispEvents = [];
  final List<ServiceNowIncident> _serviceNowIncidents = [];
  final List<CSPMFinding> _cspmFindings = [];
  final List<NVDVulnerability> _nvdVulnerabilities = [];
  final List<IntegrationConfig> _integrations = [];
  
  bool _isSyncing = false;
  DateTime _lastSyncTime = DateTime.now();
  final Map<String, int> _syncStats = {};
  final Map<String, List<String>> _syncErrors = {};
  
  Timer? _autoSyncTimer;
  
  // Getters
  List<MISPEvent> get mispEvents => List.unmodifiable(_mispEvents);
  List<ServiceNowIncident> get serviceNowIncidents => List.unmodifiable(_serviceNowIncidents);
  List<CSPMFinding> get cspmFindings => List.unmodifiable(_cspmFindings);
  List<NVDVulnerability> get nvdVulnerabilities => List.unmodifiable(_nvdVulnerabilities);
  List<IntegrationConfig> get integrations => List.unmodifiable(_integrations);
  bool get isSyncing => _isSyncing;
  DateTime get lastSyncTime => _lastSyncTime;
  Map<String, int> get syncStats => Map.unmodifiable(_syncStats);
  Map<String, List<String>> get syncErrors => Map.unmodifiable(_syncErrors);

  ThirdPartyIntegrationsService() {
    _initializeIntegrations();
    _loadData();
    _startAutoSync();
  }

  void _initializeIntegrations() {
    _integrations.addAll([
      IntegrationConfig(
        name: 'MISP - Threat Intelligence',
        type: 'MISP',
        endpoint: 'https://misp.example.com/api',
        apiKey: 'demo-api-key-misp',
        enabled: true,
        lastSync: DateTime.now().subtract(const Duration(hours: 1)),
        status: 'Connected',
        settings: {
          'autoPublish': true,
          'syncInterval': 3600,
          'threatLevelFilter': 'all',
        },
      ),
      IntegrationConfig(
        name: 'ServiceNow ITSM',
        type: 'ServiceNow',
        endpoint: 'https://instance.service-now.com/api/now',
        apiKey: 'demo-api-key-snow',
        enabled: true,
        lastSync: DateTime.now().subtract(const Duration(minutes: 30)),
        status: 'Connected',
        settings: {
          'autoCreateTickets': true,
          'assignmentGroup': 'Security Team',
          'priority': 'P2',
        },
      ),
      IntegrationConfig(
        name: 'AWS Security Hub',
        type: 'CSPM',
        endpoint: 'https://securityhub.amazonaws.com',
        apiKey: 'demo-api-key-aws',
        enabled: true,
        lastSync: DateTime.now().subtract(const Duration(minutes: 15)),
        status: 'Connected',
        settings: {
          'regions': ['us-east-1', 'eu-west-1'],
          'complianceStandards': ['PCI-DSS', 'CIS'],
          'severityFilter': 'HIGH,CRITICAL',
        },
      ),
      IntegrationConfig(
        name: 'NVD - Vulnerability Database',
        type: 'NVD',
        endpoint: 'https://services.nvd.nist.gov/rest/json/cves/2.0',
        apiKey: 'demo-api-key-nvd',
        enabled: true,
        lastSync: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'Connected',
        settings: {
          'cvssMinScore': 7.0,
          'includeReferences': true,
          'checkExploits': true,
        },
      ),
    ]);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load saved integration data
    final mispData = prefs.getString('misp_events');
    if (mispData != null) {
      final List<dynamic> decoded = json.decode(mispData);
      _mispEvents.clear();
      _mispEvents.addAll(decoded.map((e) => MISPEvent.fromJson(e)));
    } else {
      _generateMockMISPEvents();
    }
    
    _generateMockServiceNowIncidents();
    _generateMockCSPMFindings();
    _generateMockNVDVulnerabilities();
    
    notifyListeners();
  }

  void _generateMockMISPEvents() {
    _mispEvents.addAll([
      MISPEvent(
        id: 'MISP-2024-001',
        info: 'APT29 - New Spear Phishing Campaign',
        threatLevel: 'High',
        analysis: 'Completed',
        date: DateTime.now().subtract(const Duration(days: 1)),
        tags: ['APT29', 'Phishing', 'Email', 'Russia'],
        attributeCount: 42,
        published: true,
        orgc: 'CERT-EU',
        distribution: 'All Communities',
      ),
      MISPEvent(
        id: 'MISP-2024-002',
        info: 'Ransomware - LockBit 3.0 IOCs',
        threatLevel: 'Critical',
        analysis: 'Ongoing',
        date: DateTime.now().subtract(const Duration(hours: 3)),
        tags: ['Ransomware', 'LockBit', 'IOC', 'File-Hash'],
        attributeCount: 128,
        published: true,
        orgc: 'FBI',
        distribution: 'Community',
      ),
      MISPEvent(
        id: 'MISP-2024-003',
        info: 'Supply Chain Attack - NPM Package',
        threatLevel: 'Medium',
        analysis: 'Initial',
        date: DateTime.now().subtract(const Duration(hours: 12)),
        tags: ['Supply-Chain', 'NPM', 'Malware', 'JavaScript'],
        attributeCount: 23,
        published: false,
        orgc: 'Internal',
        distribution: 'Organization',
      ),
    ]);
  }

  void _generateMockServiceNowIncidents() {
    _serviceNowIncidents.addAll([
      ServiceNowIncident(
        number: 'INC0010234',
        shortDescription: 'Multiple failed login attempts detected',
        priority: 'P2',
        state: 'In Progress',
        assignedTo: 'John Smith',
        category: 'Security',
        createdOn: DateTime.now().subtract(const Duration(hours: 2)),
        updatedOn: DateTime.now().subtract(const Duration(minutes: 30)),
        impact: 'Medium',
        urgency: 'High',
        resolvedBy: '',
        closeNotes: '',
      ),
      ServiceNowIncident(
        number: 'INC0010235',
        shortDescription: 'Suspicious network traffic from internal host',
        priority: 'P1',
        state: 'New',
        assignedTo: 'Security Team',
        category: 'Network Security',
        createdOn: DateTime.now().subtract(const Duration(minutes: 15)),
        updatedOn: DateTime.now().subtract(const Duration(minutes: 5)),
        impact: 'High',
        urgency: 'Critical',
        resolvedBy: '',
        closeNotes: '',
      ),
      ServiceNowIncident(
        number: 'INC0010233',
        shortDescription: 'Unauthorized access attempt blocked',
        priority: 'P3',
        state: 'Resolved',
        assignedTo: 'Jane Doe',
        category: 'Access Control',
        createdOn: DateTime.now().subtract(const Duration(days: 1)),
        updatedOn: DateTime.now().subtract(const Duration(hours: 6)),
        impact: 'Low',
        urgency: 'Medium',
        resolvedBy: 'Jane Doe',
        closeNotes: 'False positive - legitimate user with expired credentials',
      ),
    ]);
  }

  void _generateMockCSPMFindings() {
    _cspmFindings.addAll([
      CSPMFinding(
        id: 'AWS-001',
        cloudProvider: 'AWS',
        service: 'S3',
        resource: 'my-public-bucket',
        region: 'us-east-1',
        severity: 'Critical',
        complianceFramework: 'PCI-DSS',
        control: '2.2.1',
        description: 'S3 bucket allows public read access',
        remediation: 'Update bucket policy to restrict public access',
        discoveredAt: DateTime.now().subtract(const Duration(days: 2)),
        status: 'Open',
        riskScore: 9.5,
      ),
      CSPMFinding(
        id: 'AWS-002',
        cloudProvider: 'AWS',
        service: 'EC2',
        resource: 'i-0123456789',
        region: 'eu-west-1',
        severity: 'High',
        complianceFramework: 'CIS',
        control: '4.1',
        description: 'Security group allows unrestricted inbound SSH',
        remediation: 'Restrict SSH access to specific IP ranges',
        discoveredAt: DateTime.now().subtract(const Duration(hours: 8)),
        status: 'In Progress',
        riskScore: 7.8,
      ),
      CSPMFinding(
        id: 'AZURE-001',
        cloudProvider: 'Azure',
        service: 'Storage',
        resource: 'storageaccount01',
        region: 'East US',
        severity: 'Medium',
        complianceFramework: 'ISO 27001',
        control: 'A.13.1.1',
        description: 'Storage account not using encryption at rest',
        remediation: 'Enable encryption for storage account',
        discoveredAt: DateTime.now().subtract(const Duration(days: 1)),
        status: 'Open',
        riskScore: 6.2,
      ),
    ]);
  }

  void _generateMockNVDVulnerabilities() {
    _nvdVulnerabilities.addAll([
      NVDVulnerability(
        cveId: 'CVE-2024-12345',
        description: 'Remote code execution vulnerability in popular web framework',
        cvssScore: 9.8,
        severity: 'Critical',
        vector: 'CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H',
        publishedDate: DateTime.now().subtract(const Duration(days: 1)),
        modifiedDate: DateTime.now().subtract(const Duration(hours: 2)),
        affectedProducts: ['Framework v1.0-v2.5', 'Library v3.0'],
        references: ['https://cve.mitre.org/cve-2024-12345', 'https://github.com/vendor/advisory'],
        exploitAvailable: true,
        cweId: 'CWE-78',
      ),
      NVDVulnerability(
        cveId: 'CVE-2024-12346',
        description: 'SQL injection vulnerability in database connector',
        cvssScore: 8.2,
        severity: 'High',
        vector: 'CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:N',
        publishedDate: DateTime.now().subtract(const Duration(days: 3)),
        modifiedDate: DateTime.now().subtract(const Duration(days: 2)),
        affectedProducts: ['DB-Connector v4.0-v4.3'],
        references: ['https://nvd.nist.gov/vuln/detail/CVE-2024-12346'],
        exploitAvailable: false,
        cweId: 'CWE-89',
      ),
      NVDVulnerability(
        cveId: 'CVE-2024-12347',
        description: 'Cross-site scripting (XSS) in admin panel',
        cvssScore: 7.1,
        severity: 'High',
        vector: 'CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:C/C:L/I:L/A:N',
        publishedDate: DateTime.now().subtract(const Duration(hours: 12)),
        modifiedDate: DateTime.now().subtract(const Duration(hours: 6)),
        affectedProducts: ['AdminPanel v2.0', 'Dashboard v1.5'],
        references: ['https://security.vendor.com/advisory/2024-001'],
        exploitAvailable: true,
        cweId: 'CWE-79',
      ),
    ]);
  }

  void _startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      for (final integration in _integrations) {
        if (integration.enabled) {
          syncIntegration(integration.type);
        }
      }
    });
  }

  Future<void> syncIntegration(String type) async {
    _isSyncing = true;
    notifyListeners();
    
    await Future.delayed(const Duration(seconds: 2));
    
    switch (type) {
      case 'MISP':
        await _syncMISP();
        break;
      case 'ServiceNow':
        await _syncServiceNow();
        break;
      case 'CSPM':
        await _syncCSPM();
        break;
      case 'NVD':
        await _syncNVD();
        break;
    }
    
    _lastSyncTime = DateTime.now();
    _isSyncing = false;
    
    // Update integration status
    final index = _integrations.indexWhere((i) => i.type == type);
    if (index != -1) {
      final integration = _integrations[index];
      _integrations[index] = IntegrationConfig(
        name: integration.name,
        type: integration.type,
        endpoint: integration.endpoint,
        apiKey: integration.apiKey,
        enabled: integration.enabled,
        lastSync: DateTime.now(),
        status: 'Connected',
        settings: integration.settings,
      );
    }
    
    await _saveData();
    notifyListeners();
  }

  Future<void> _syncMISP() async {
    // Simulate MISP sync
    _syncStats['MISP'] = _mispEvents.length;
    
    // Add a new event
    _mispEvents.insert(0, MISPEvent(
      id: 'MISP-2024-${DateTime.now().millisecondsSinceEpoch}',
      info: 'New Threat Intelligence Update',
      threatLevel: ['Low', 'Medium', 'High', 'Critical'][DateTime.now().second % 4],
      analysis: 'Initial',
      date: DateTime.now(),
      tags: ['New', 'Unverified', 'IOC'],
      attributeCount: 15,
      published: false,
      orgc: 'Auto-Import',
      distribution: 'Organization',
    ));
  }

  Future<void> _syncServiceNow() async {
    // Simulate ServiceNow sync
    _syncStats['ServiceNow'] = _serviceNowIncidents.length;
  }

  Future<void> _syncCSPM() async {
    // Simulate CSPM sync
    _syncStats['CSPM'] = _cspmFindings.length;
  }

  Future<void> _syncNVD() async {
    // Simulate NVD sync
    _syncStats['NVD'] = _nvdVulnerabilities.length;
  }

  void toggleIntegration(String type) {
    final index = _integrations.indexWhere((i) => i.type == type);
    if (index != -1) {
      final integration = _integrations[index];
      _integrations[index] = IntegrationConfig(
        name: integration.name,
        type: integration.type,
        endpoint: integration.endpoint,
        apiKey: integration.apiKey,
        enabled: !integration.enabled,
        lastSync: integration.lastSync,
        status: !integration.enabled ? 'Connected' : 'Disabled',
        settings: integration.settings,
      );
      notifyListeners();
    }
  }

  void updateIntegrationSettings(String type, Map<String, dynamic> settings) {
    final index = _integrations.indexWhere((i) => i.type == type);
    if (index != -1) {
      final integration = _integrations[index];
      _integrations[index] = IntegrationConfig(
        name: integration.name,
        type: integration.type,
        endpoint: integration.endpoint,
        apiKey: integration.apiKey,
        enabled: integration.enabled,
        lastSync: integration.lastSync,
        status: integration.status,
        settings: settings,
      );
      notifyListeners();
    }
  }

  Future<void> testConnection(String type) async {
    // Simulate connection test
    await Future.delayed(const Duration(seconds: 1));
    
    final index = _integrations.indexWhere((i) => i.type == type);
    if (index != -1) {
      final integration = _integrations[index];
      _integrations[index] = IntegrationConfig(
        name: integration.name,
        type: integration.type,
        endpoint: integration.endpoint,
        apiKey: integration.apiKey,
        enabled: integration.enabled,
        lastSync: integration.lastSync,
        status: 'Connection Successful',
        settings: integration.settings,
      );
      notifyListeners();
    }
  }

  void createServiceNowIncident(String description, String priority) {
    _serviceNowIncidents.insert(0, ServiceNowIncident(
      number: 'INC00${10236 + _serviceNowIncidents.length}',
      shortDescription: description,
      priority: priority,
      state: 'New',
      assignedTo: 'Security Team',
      category: 'Security',
      createdOn: DateTime.now(),
      updatedOn: DateTime.now(),
      impact: priority == 'P1' ? 'High' : 'Medium',
      urgency: priority == 'P1' ? 'Critical' : 'High',
      resolvedBy: '',
      closeNotes: '',
    ));
    notifyListeners();
  }

  void acknowledgeFinding(String findingId) {
    final index = _cspmFindings.indexWhere((f) => f.id == findingId);
    if (index != -1) {
      final finding = _cspmFindings[index];
      _cspmFindings[index] = CSPMFinding(
        id: finding.id,
        cloudProvider: finding.cloudProvider,
        service: finding.service,
        resource: finding.resource,
        region: finding.region,
        severity: finding.severity,
        complianceFramework: finding.complianceFramework,
        control: finding.control,
        description: finding.description,
        remediation: finding.remediation,
        discoveredAt: finding.discoveredAt,
        status: 'Acknowledged',
        riskScore: finding.riskScore,
      );
      notifyListeners();
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save MISP events
    final mispData = json.encode(_mispEvents.map((e) => e.toJson()).toList());
    await prefs.setString('misp_events', mispData);
    
    // Save other integration data as needed
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }
}
