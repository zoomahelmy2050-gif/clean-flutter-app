import 'dart:async';
import '../../../core/models/threat_models.dart';
import '../security_incident_response_center.dart';
import '../../../core/services/production_database_service.dart';
import '../../../core/services/real_time_communication_service.dart';
import '../../../locator.dart';
import 'dart:developer' as developer;

class IncidentResponseService {
  final List<SecurityIncident> _activeIncidents = [];
  final List<SecurityIncident> _resolvedIncidents = [];
  final List<SecurityPlaybook> _playbooks = [];
  
  IncidentResponseService() {
    _initializeMockData();
    _connectToProductionServices();
  }

  void _connectToProductionServices() {
    try {
      final realTimeService = locator<RealTimeCommunicationService>();
      
      // Mock threat alert stream - replace when threatAlertStream is available
      // realTimeService.threatAlertStream.listen((alert) {
      //   _createIncidentFromAlert(alert);
      // });
      
      developer.log('Connected to production services', name: 'IncidentResponseService');
    } catch (e) {
      developer.log('Failed to connect to production services: $e', name: 'IncidentResponseService');
    }
  }

  void _createIncidentFromAlert(Map<String, dynamic> alert) {
    if (alert['severity'] == 'critical' || alert['severity'] == 'high') {
      final incident = SecurityIncident(
        id: 'auto_${DateTime.now().millisecondsSinceEpoch}',
        title: alert['title'] ?? 'Security Alert',
        description: alert['description'] ?? 'Automated incident from security alert',
        severity: _mapAlertSeverity(alert['severity'] ?? 'medium'),
        status: IncidentStatus.open,
        createdAt: DateTime.now(),
        assignedTo: 'Auto-Assignment',
        affectedUsers: [],
        actions: [],
        metadata: Map<String, dynamic>.from(alert),
      );
      
      _activeIncidents.insert(0, incident);
      developer.log('Auto-created incident from alert: ${incident.title}', name: 'IncidentResponseService');
    }
  }

  AlertSeverity _mapAlertSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return AlertSeverity.critical;
      case 'high':
        return AlertSeverity.high;
      case 'medium':
        return AlertSeverity.medium;
      case 'low':
        return AlertSeverity.low;
      default:
        return AlertSeverity.medium;
    }
  }

  void _initializeMockData() {
    // Mock active incidents
    _activeIncidents.addAll([
      SecurityIncident(
        id: '1',
        title: 'Suspected Data Breach - Customer Database',
        description: 'Unusual database access patterns detected. Multiple customer records accessed outside normal business hours.',
        severity: AlertSeverity.critical,
        status: IncidentStatus.investigating,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        assignedTo: 'Security Team Lead',
        affectedUsers: ['customer1@email.com', 'customer2@email.com', 'customer3@email.com'],
        actions: [
          IncidentAction(
            id: '1',
            action: 'Initial assessment completed',
            performedBy: 'Security Analyst',
            timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
            notes: 'Confirmed unauthorized access to customer database',
          ),
          IncidentAction(
            id: '2',
            action: 'Database access restricted',
            performedBy: 'Database Admin',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            notes: 'Temporarily restricted access to affected database tables',
          ),
        ],
        metadata: {
          'affectedTables': ['customers', 'orders', 'payments'],
          'accessMethod': 'SQL injection',
          'sourceIP': '192.168.1.100',
        },
      ),
      SecurityIncident(
        id: '2',
        title: 'Phishing Campaign Targeting Employees',
        description: 'Multiple employees reported suspicious emails claiming to be from IT department requesting password changes.',
        severity: AlertSeverity.high,
        status: IncidentStatus.open,
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        assignedTo: 'Incident Response Team',
        affectedUsers: ['employee1@company.com', 'employee2@company.com'],
        actions: [
          IncidentAction(
            id: '3',
            action: 'Phishing emails identified and quarantined',
            performedBy: 'Email Security System',
            timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
            notes: 'Automated quarantine of 15 suspicious emails',
          ),
        ],
        metadata: {
          'emailCount': 15,
          'senderDomain': 'fake-company-it.com',
          'clickRate': '12%',
        },
      ),
      SecurityIncident(
        id: '3',
        title: 'Malware Detection on Workstation',
        description: 'Endpoint protection detected trojan malware on employee workstation in accounting department.',
        severity: AlertSeverity.medium,
        status: IncidentStatus.investigating,
        createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
        assignedTo: 'IT Security',
        affectedUsers: ['accounting.user@company.com'],
        actions: [],
        metadata: {
          'malwareType': 'Trojan.Win32.Generic',
          'workstationID': 'WS-ACC-001',
          'quarantined': true,
        },
      ),
    ]);

    // Mock resolved incidents
    _resolvedIncidents.addAll([
      SecurityIncident(
        id: '4',
        title: 'Failed Login Brute Force Attack',
        description: 'Automated brute force attack against admin accounts detected and blocked.',
        severity: AlertSeverity.high,
        status: IncidentStatus.resolved,
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        resolvedAt: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
        assignedTo: 'Security Operations',
        affectedUsers: ['admin@company.com'],
        actions: [
          IncidentAction(
            id: '4',
            action: 'IP address blocked',
            performedBy: 'Firewall System',
            timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2, minutes: 45)),
            notes: 'Automatically blocked source IP after 10 failed attempts',
          ),
          IncidentAction(
            id: '5',
            action: 'Admin account secured',
            performedBy: 'Security Admin',
            timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
            notes: 'Forced password reset and enabled additional MFA',
          ),
        ],
        metadata: {
          'sourceIP': '203.0.113.45',
          'attemptCount': 127,
          'duration': '2 hours',
        },
      ),
      SecurityIncident(
        id: '5',
        title: 'Suspicious File Upload Detected',
        description: 'Web application firewall detected attempt to upload potentially malicious file.',
        severity: AlertSeverity.medium,
        status: IncidentStatus.resolved,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        resolvedAt: DateTime.now().subtract(const Duration(days: 2, hours: -1)),
        assignedTo: 'Web Security Team',
        affectedUsers: [],
        actions: [
          IncidentAction(
            id: '6',
            action: 'File upload blocked',
            performedBy: 'WAF System',
            timestamp: DateTime.now().subtract(const Duration(days: 2, minutes: -5)),
            notes: 'Automatically blocked file upload based on signature match',
          ),
        ],
        metadata: {
          'fileName': 'invoice.exe',
          'fileSize': '2.3MB',
          'uploadIP': '10.0.0.50',
        },
      ),
    ]);

    // Mock security playbooks
    _playbooks.addAll([
      SecurityPlaybook(
        id: '1',
        title: 'Data Breach Response',
        description: 'Comprehensive response procedure for suspected or confirmed data breaches',
        type: 'breach',
        estimatedDuration: 120,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        steps: [
          PlaybookStep(
            id: '1',
            title: 'Initial Assessment',
            description: 'Assess the scope and severity of the potential breach',
            action: 'ASSESS_BREACH_SCOPE',
            isAutomated: false,
            estimatedMinutes: 15,
          ),
          PlaybookStep(
            id: '2',
            title: 'Contain the Breach',
            description: 'Immediately isolate affected systems to prevent further damage',
            action: 'ISOLATE_SYSTEMS',
            isAutomated: true,
            estimatedMinutes: 5,
          ),
          PlaybookStep(
            id: '3',
            title: 'Notify Stakeholders',
            description: 'Inform management, legal team, and relevant authorities',
            action: 'SEND_NOTIFICATIONS',
            isAutomated: true,
            estimatedMinutes: 10,
          ),
          PlaybookStep(
            id: '4',
            title: 'Evidence Collection',
            description: 'Preserve forensic evidence for investigation',
            action: 'COLLECT_EVIDENCE',
            isAutomated: false,
            estimatedMinutes: 30,
          ),
          PlaybookStep(
            id: '5',
            title: 'System Recovery',
            description: 'Restore systems from clean backups',
            action: 'RESTORE_SYSTEMS',
            isAutomated: false,
            estimatedMinutes: 60,
          ),
        ],
      ),
      SecurityPlaybook(
        id: '2',
        title: 'Phishing Attack Response',
        description: 'Response procedure for phishing campaigns targeting employees',
        type: 'phishing',
        estimatedDuration: 45,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        steps: [
          PlaybookStep(
            id: '6',
            title: 'Identify Phishing Emails',
            description: 'Scan email systems for similar phishing messages',
            action: 'SCAN_EMAIL_SYSTEMS',
            isAutomated: true,
            estimatedMinutes: 5,
          ),
          PlaybookStep(
            id: '7',
            title: 'Quarantine Messages',
            description: 'Remove phishing emails from all mailboxes',
            action: 'QUARANTINE_EMAILS',
            isAutomated: true,
            estimatedMinutes: 10,
          ),
          PlaybookStep(
            id: '8',
            title: 'Update Email Filters',
            description: 'Add sender and content filters to prevent similar attacks',
            action: 'UPDATE_EMAIL_FILTERS',
            isAutomated: true,
            estimatedMinutes: 5,
          ),
          PlaybookStep(
            id: '9',
            title: 'User Notification',
            description: 'Notify users about the phishing attempt and provide guidance',
            action: 'NOTIFY_USERS',
            isAutomated: true,
            estimatedMinutes: 15,
          ),
          PlaybookStep(
            id: '10',
            title: 'Security Awareness Training',
            description: 'Schedule additional phishing awareness training',
            action: 'SCHEDULE_TRAINING',
            isAutomated: false,
            estimatedMinutes: 10,
          ),
        ],
      ),
      SecurityPlaybook(
        id: '3',
        title: 'Malware Incident Response',
        description: 'Response procedure for malware detection and containment',
        type: 'malware',
        estimatedDuration: 60,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        steps: [
          PlaybookStep(
            id: '11',
            title: 'Isolate Infected System',
            description: 'Disconnect infected system from network',
            action: 'ISOLATE_SYSTEM',
            isAutomated: true,
            estimatedMinutes: 2,
          ),
          PlaybookStep(
            id: '12',
            title: 'Malware Analysis',
            description: 'Analyze malware sample to understand capabilities',
            action: 'ANALYZE_MALWARE',
            isAutomated: false,
            estimatedMinutes: 20,
          ),
          PlaybookStep(
            id: '13',
            title: 'System Cleanup',
            description: 'Remove malware and restore system integrity',
            action: 'CLEAN_SYSTEM',
            isAutomated: false,
            estimatedMinutes: 30,
          ),
          PlaybookStep(
            id: '14',
            title: 'Update Signatures',
            description: 'Update antivirus signatures across all systems',
            action: 'UPDATE_AV_SIGNATURES',
            isAutomated: true,
            estimatedMinutes: 5,
          ),
          PlaybookStep(
            id: '15',
            title: 'System Monitoring',
            description: 'Enhanced monitoring for similar threats',
            action: 'ENABLE_MONITORING',
            isAutomated: true,
            estimatedMinutes: 3,
          ),
        ],
      ),
      SecurityPlaybook(
        id: '4',
        title: 'DDoS Attack Mitigation',
        description: 'Response procedure for distributed denial of service attacks',
        type: 'ddos',
        estimatedDuration: 30,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        steps: [
          PlaybookStep(
            id: '16',
            title: 'Traffic Analysis',
            description: 'Analyze incoming traffic patterns to confirm DDoS',
            action: 'ANALYZE_TRAFFIC',
            isAutomated: true,
            estimatedMinutes: 5,
          ),
          PlaybookStep(
            id: '17',
            title: 'Enable DDoS Protection',
            description: 'Activate cloud-based DDoS protection services',
            action: 'ENABLE_DDOS_PROTECTION',
            isAutomated: true,
            estimatedMinutes: 2,
          ),
          PlaybookStep(
            id: '18',
            title: 'Rate Limiting',
            description: 'Implement aggressive rate limiting rules',
            action: 'APPLY_RATE_LIMITS',
            isAutomated: true,
            estimatedMinutes: 3,
          ),
          PlaybookStep(
            id: '19',
            title: 'Block Attack Sources',
            description: 'Block IP ranges identified as attack sources',
            action: 'BLOCK_ATTACK_IPS',
            isAutomated: true,
            estimatedMinutes: 5,
          ),
          PlaybookStep(
            id: '20',
            title: 'Monitor Recovery',
            description: 'Monitor service availability and performance',
            action: 'MONITOR_RECOVERY',
            isAutomated: false,
            estimatedMinutes: 15,
          ),
        ],
      ),
    ]);
  }

  // Public API methods
  Future<List<SecurityIncident>> getActiveIncidents() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _activeIncidents.where((incident) => 
      incident.status != IncidentStatus.resolved && 
      incident.status != IncidentStatus.closed
    ).toList();
  }

  Future<List<SecurityIncident>> getResolvedIncidents() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _resolvedIncidents;
  }

  Future<List<SecurityPlaybook>> getSecurityPlaybooks() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _playbooks;
  }

  Future<SecurityIncident> createIncident(
    String title,
    String description,
    AlertSeverity severity,
  ) async {
    final incident = SecurityIncident(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      severity: severity,
      status: IncidentStatus.open,
      createdAt: DateTime.now(),
      assignedTo: 'Incident Response Team',
      affectedUsers: [],
      actions: [],
      metadata: {'createdBy': 'manual', 'source': 'admin_console'},
    );

    _activeIncidents.insert(0, incident);
    
    developer.log('New security incident created: $title', name: 'IncidentResponse');
    
    // Auto-assign based on severity
    if (severity == AlertSeverity.critical) {
      await _autoEscalateIncident(incident);
    }
    
    return incident;
  }

  Future<void> updateIncidentStatus(String incidentId, IncidentStatus newStatus) async {
    try {
      // Update in production database
      final dbService = locator<ProductionDatabaseService>();
      await dbService.logSecurityEvent(
        'incident_status_update',
        'info',
        'Incident $incidentId status updated to $newStatus',
        userId: 'system',
        metadata: {
          'incident_id': incidentId,
          'new_status': newStatus.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      developer.log('Failed to log incident update to database: $e', name: 'IncidentResponseService');
    }
    
    // Find incident in active list
    final activeIndex = _activeIncidents.indexWhere((i) => i.id == incidentId);
    if (activeIndex != -1) {
      final incident = _activeIncidents[activeIndex];
      final updatedIncident = SecurityIncident(
        id: incident.id,
        title: incident.title,
        description: incident.description,
        severity: incident.severity,
        status: newStatus,
        createdAt: incident.createdAt,
        assignedTo: incident.assignedTo,
        affectedUsers: incident.affectedUsers,
        actions: incident.actions,
        metadata: incident.metadata,
      );
      
      if (newStatus == IncidentStatus.resolved || newStatus == IncidentStatus.closed) {
        _activeIncidents.removeAt(activeIndex);
        _resolvedIncidents.add(updatedIncident);
      } else {
        _activeIncidents[activeIndex] = updatedIncident;
      }
      
      developer.log('Updated incident $incidentId status to $newStatus', name: 'IncidentResponseService');
    }
  }

  Future<void> addIncidentAction(
    String incidentId,
    String action,
    String performedBy,
    String notes,
  ) async {
    final incidentIndex = _activeIncidents.indexWhere((i) => i.id == incidentId);
    if (incidentIndex != -1) {
      final incident = _activeIncidents[incidentIndex];
      final newAction = IncidentAction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        action: action,
        performedBy: performedBy,
        timestamp: DateTime.now(),
        notes: notes,
      );

      final updatedActions = [...incident.actions, newAction];
      final updatedIncident = SecurityIncident(
        id: incident.id,
        title: incident.title,
        description: incident.description,
        severity: incident.severity,
        status: incident.status,
        createdAt: incident.createdAt,
        resolvedAt: incident.resolvedAt,
        assignedTo: incident.assignedTo,
        affectedUsers: incident.affectedUsers,
        actions: updatedActions,
        metadata: incident.metadata,
      );

      _activeIncidents[incidentIndex] = updatedIncident;
    }
  }

  Future<void> escalateIncident(String incidentId) async {
    final incidentIndex = _activeIncidents.indexWhere((i) => i.id == incidentId);
    if (incidentIndex != -1) {
      final incident = _activeIncidents[incidentIndex];
      
      // Increase severity if not already critical
      AlertSeverity newSeverity = incident.severity;
      if (incident.severity == AlertSeverity.low) {
        newSeverity = AlertSeverity.medium;
      } else if (incident.severity == AlertSeverity.medium) {
        newSeverity = AlertSeverity.high;
      } else if (incident.severity == AlertSeverity.high) {
        newSeverity = AlertSeverity.critical;
      }

      final updatedIncident = SecurityIncident(
        id: incident.id,
        title: incident.title,
        description: incident.description,
        severity: newSeverity,
        status: IncidentStatus.investigating,
        createdAt: incident.createdAt,
        resolvedAt: incident.resolvedAt,
        assignedTo: newSeverity == AlertSeverity.critical ? 'Security Team Lead' : incident.assignedTo,
        affectedUsers: incident.affectedUsers,
        actions: [
          ...incident.actions,
          IncidentAction(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            action: 'Incident escalated',
            performedBy: 'System',
            timestamp: DateTime.now(),
            notes: 'Severity increased to ${newSeverity.name}',
          ),
        ],
        metadata: incident.metadata,
      );

      _activeIncidents[incidentIndex] = updatedIncident;
      
      developer.log('Incident $incidentId escalated to ${newSeverity.name}', name: 'IncidentResponse');
    }
  }

  Future<void> _autoEscalateIncident(SecurityIncident incident) async {
    // Auto-escalate critical incidents
    await addIncidentAction(
      incident.id,
      'Critical incident auto-escalated',
      'System',
      'Automatically escalated due to critical severity level',
    );
    
    // TODO: Send notifications to security team
    developer.log('Critical incident auto-escalated: ${incident.title}', name: 'IncidentResponse');
  }

  Future<void> executePlaybook(String playbookId, String incidentId) async {
    final playbook = _playbooks.where((p) => p.id == playbookId).firstOrNull;
    if (playbook == null) return;

    developer.log('Executing playbook: ${playbook.title} for incident: $incidentId', name: 'IncidentResponse');

    // Execute each step
    for (final step in playbook.steps) {
      await _executePlaybookStep(step, incidentId);
      
      // Add action to incident
      await addIncidentAction(
        incidentId,
        'Playbook step executed: ${step.title}',
        step.isAutomated ? 'Automated System' : 'Security Team',
        step.description,
      );
      
      // Simulate step execution time
      await Future.delayed(Duration(seconds: step.isAutomated ? 1 : 3));
    }

    developer.log('Playbook execution completed for incident: $incidentId', name: 'IncidentResponse');
  }

  Future<void> _executePlaybookStep(PlaybookStep step, String incidentId) async {
    developer.log('Executing step: ${step.title} (${step.action})', name: 'IncidentResponse');
    
    switch (step.action) {
      case 'ISOLATE_SYSTEMS':
      case 'ISOLATE_SYSTEM':
        // Simulate system isolation
        await Future.delayed(const Duration(seconds: 2));
        break;
      case 'SEND_NOTIFICATIONS':
        // Simulate sending notifications
        await Future.delayed(const Duration(seconds: 1));
        break;
      case 'QUARANTINE_EMAILS':
        // Simulate email quarantine
        await Future.delayed(const Duration(seconds: 3));
        break;
      case 'UPDATE_EMAIL_FILTERS':
        // Simulate filter updates
        await Future.delayed(const Duration(seconds: 2));
        break;
      case 'BLOCK_ATTACK_IPS':
        // Simulate IP blocking
        await Future.delayed(const Duration(seconds: 1));
        break;
      case 'ENABLE_DDOS_PROTECTION':
        // Simulate DDoS protection activation
        await Future.delayed(const Duration(seconds: 1));
        break;
      default:
        // Generic step execution
        await Future.delayed(Duration(seconds: step.isAutomated ? 1 : 2));
    }
  }

  Future<Map<String, dynamic>> getIncidentMetrics() async {
    final totalIncidents = _activeIncidents.length + _resolvedIncidents.length;
    final criticalCount = _activeIncidents.where((i) => i.severity == AlertSeverity.critical).length;
    final avgResolutionTime = _calculateAverageResolutionTime();
    
    return {
      'totalIncidents': totalIncidents,
      'activeIncidents': _activeIncidents.length,
      'criticalIncidents': criticalCount,
      'averageResolutionTimeMinutes': avgResolutionTime,
      'resolutionRate': _resolvedIncidents.length / totalIncidents * 100,
    };
  }

  int _calculateAverageResolutionTime() {
    if (_resolvedIncidents.isEmpty) return 0;
    
    int totalMinutes = 0;
    int resolvedCount = 0;
    
    for (final incident in _resolvedIncidents) {
      if (incident.resolvedAt != null) {
        final resolutionTime = incident.resolvedAt!.difference(incident.createdAt).inMinutes;
        totalMinutes += resolutionTime;
        resolvedCount++;
      }
    }
    
    return resolvedCount > 0 ? totalMinutes ~/ resolvedCount : 0;
  }

  Future<SecurityPlaybook> createPlaybook(
    String title,
    String description,
    String type,
    List<PlaybookStep> steps,
  ) async {
    final playbook = SecurityPlaybook(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      type: type,
      steps: steps,
      estimatedDuration: steps.fold(0, (sum, step) => sum + step.estimatedMinutes),
      createdAt: DateTime.now(),
    );

    _playbooks.insert(0, playbook);
    
    developer.log('New security playbook created: $title', name: 'IncidentResponse');
    
    return playbook;
  }

  Future<List<SecurityIncident>> searchIncidents(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final allIncidents = [..._activeIncidents, ..._resolvedIncidents];
    return allIncidents.where((incident) =>
      incident.title.toLowerCase().contains(query.toLowerCase()) ||
      incident.description.toLowerCase().contains(query.toLowerCase()) ||
      incident.assignedTo.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}
