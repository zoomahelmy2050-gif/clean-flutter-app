import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

// Enums
enum PlaybookStatus { draft, active, testing, archived }
enum ActionType { 
  investigation, containment, eradication, recovery, 
  notification, escalation, automation, manual 
}
enum CaseStatus { open, investigating, resolved, closed, escalated }
enum CasePriority { critical, high, medium, low }
enum CaseType { incident, breach, vulnerability, compliance, general }

// Models
class PlaybookAction {
  final String id;
  final String name;
  final String description;
  final ActionType type;
  final int order;
  final Map<String, dynamic> parameters;
  final List<String> conditions;
  final String? nextActionId;
  final int estimatedMinutes;

  PlaybookAction({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.order,
    required this.parameters,
    required this.conditions,
    this.nextActionId,
    required this.estimatedMinutes,
  });
}

class SecurityPlaybook {
  final String id;
  final String name;
  final String description;
  final String category;
  final PlaybookStatus status;
  final List<PlaybookAction> actions;
  final Map<String, dynamic> triggers;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String author;
  final int useCount;
  final double successRate;

  SecurityPlaybook({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.status,
    required this.actions,
    required this.triggers,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
    required this.useCount,
    required this.successRate,
  });
}

class SecurityCase {
  final String id;
  final String title;
  final String description;
  final CaseType type;
  final CaseStatus status;
  final CasePriority priority;
  final String? assignee;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? playbookId;
  final List<CaseActivity> activities;
  final Map<String, dynamic> evidence;
  final List<String> affectedAssets;

  SecurityCase({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.priority,
    this.assignee,
    required this.tags,
    required this.createdAt,
    this.resolvedAt,
    this.playbookId,
    required this.activities,
    required this.evidence,
    required this.affectedAssets,
  });
}

class CaseActivity {
  final String id;
  final String caseId;
  final String action;
  final String details;
  final String performedBy;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  CaseActivity({
    required this.id,
    required this.caseId,
    required this.action,
    required this.details,
    required this.performedBy,
    required this.timestamp,
    this.metadata,
  });
}

class OrchestrationMetrics {
  final int totalPlaybooks;
  final int activePlaybooks;
  final int totalCases;
  final int openCases;
  final double avgResolutionHours;
  final Map<CasePriority, int> casesByPriority;
  final Map<CaseType, int> casesByType;
  final List<Map<String, dynamic>> recentExecutions;

  OrchestrationMetrics({
    required this.totalPlaybooks,
    required this.activePlaybooks,
    required this.totalCases,
    required this.openCases,
    required this.avgResolutionHours,
    required this.casesByPriority,
    required this.casesByType,
    required this.recentExecutions,
  });
}

// Service
class SecurityOrchestrationService extends ChangeNotifier {
  List<SecurityPlaybook> _playbooks = [];
  List<SecurityCase> _cases = [];
  Timer? _simulationTimer;
  final Random _random = Random();

  List<SecurityPlaybook> get playbooks => _playbooks;
  List<SecurityCase> get cases => _cases;
  
  SecurityOrchestrationService() {
    _initializeMockData();
    _startSimulation();
  }

  void _initializeMockData() {
    // Create sample playbooks
    _playbooks = [
      SecurityPlaybook(
        id: 'pb_001',
        name: 'Ransomware Response',
        description: 'Automated response playbook for ransomware incidents',
        category: 'Malware',
        status: PlaybookStatus.active,
        actions: [
          PlaybookAction(
            id: 'act_001',
            name: 'Isolate Affected Systems',
            description: 'Disconnect infected systems from network',
            type: ActionType.containment,
            order: 1,
            parameters: {'auto_isolate': true, 'notify_team': true},
            conditions: ['ransomware_detected'],
            nextActionId: 'act_002',
            estimatedMinutes: 5,
          ),
          PlaybookAction(
            id: 'act_002',
            name: 'Capture Forensic Data',
            description: 'Collect memory dumps and system logs',
            type: ActionType.investigation,
            order: 2,
            parameters: {'collect_memory': true, 'collect_logs': true},
            conditions: [],
            nextActionId: 'act_003',
            estimatedMinutes: 30,
          ),
          PlaybookAction(
            id: 'act_003',
            name: 'Notify Stakeholders',
            description: 'Alert management and affected users',
            type: ActionType.notification,
            order: 3,
            parameters: {'notify_ciso': true, 'notify_users': true},
            conditions: [],
            estimatedMinutes: 10,
          ),
        ],
        triggers: {
          'auto_trigger': true,
          'conditions': ['ransomware_signature', 'encryption_activity'],
        },
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        author: 'Security Team',
        useCount: 12,
        successRate: 0.92,
      ),
      SecurityPlaybook(
        id: 'pb_002',
        name: 'Data Breach Investigation',
        description: 'Step-by-step investigation for potential data breaches',
        category: 'Data Protection',
        status: PlaybookStatus.active,
        actions: [
          PlaybookAction(
            id: 'act_004',
            name: 'Verify Breach Indicators',
            description: 'Confirm suspicious activity and breach scope',
            type: ActionType.investigation,
            order: 1,
            parameters: {'check_logs': true, 'verify_alerts': true},
            conditions: [],
            nextActionId: 'act_005',
            estimatedMinutes: 45,
          ),
          PlaybookAction(
            id: 'act_005',
            name: 'Contain Data Exfiltration',
            description: 'Block suspicious connections and accounts',
            type: ActionType.containment,
            order: 2,
            parameters: {'block_ips': true, 'disable_accounts': true},
            conditions: ['breach_confirmed'],
            nextActionId: 'act_006',
            estimatedMinutes: 15,
          ),
        ],
        triggers: {
          'auto_trigger': false,
          'manual_only': true,
        },
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        author: 'Incident Response Team',
        useCount: 8,
        successRate: 0.88,
      ),
      SecurityPlaybook(
        id: 'pb_003',
        name: 'Phishing Response',
        description: 'Automated phishing email response and remediation',
        category: 'Email Security',
        status: PlaybookStatus.testing,
        actions: [
          PlaybookAction(
            id: 'act_007',
            name: 'Quarantine Emails',
            description: 'Remove phishing emails from all mailboxes',
            type: ActionType.automation,
            order: 1,
            parameters: {'auto_quarantine': true},
            conditions: ['phishing_confirmed'],
            estimatedMinutes: 5,
          ),
        ],
        triggers: {
          'auto_trigger': true,
          'conditions': ['phishing_reported', 'suspicious_url'],
        },
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
        author: 'Email Security Team',
        useCount: 45,
        successRate: 0.96,
      ),
    ];

    // Create sample cases
    _cases = [
      SecurityCase(
        id: 'case_001',
        title: 'Suspicious Login Activity from Unknown Location',
        description: 'Multiple failed login attempts followed by successful access from Russia',
        type: CaseType.incident,
        status: CaseStatus.investigating,
        priority: CasePriority.high,
        assignee: 'John Smith',
        tags: ['authentication', 'geo-anomaly', 'account-takeover'],
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        playbookId: 'pb_002',
        activities: [
          CaseActivity(
            id: 'act_log_001',
            caseId: 'case_001',
            action: 'Case Created',
            details: 'Automated case creation from SIEM alert',
            performedBy: 'System',
            timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          ),
          CaseActivity(
            id: 'act_log_002',
            caseId: 'case_001',
            action: 'Investigation Started',
            details: 'Analyzing authentication logs and user behavior',
            performedBy: 'John Smith',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          ),
        ],
        evidence: {
          'ip_addresses': ['192.168.1.100', '185.220.101.45'],
          'user_account': 'user@example.com',
          'login_attempts': 15,
        },
        affectedAssets: ['USER-LAPTOP-01', 'MAIL-SERVER-02'],
      ),
      SecurityCase(
        id: 'case_002',
        title: 'Ransomware Detection on File Server',
        description: 'Encryption activity detected on shared drive FS-001',
        type: CaseType.incident,
        status: CaseStatus.open,
        priority: CasePriority.critical,
        assignee: 'Sarah Johnson',
        tags: ['ransomware', 'malware', 'file-server'],
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        playbookId: 'pb_001',
        activities: [
          CaseActivity(
            id: 'act_log_003',
            caseId: 'case_002',
            action: 'Playbook Executed',
            details: 'Ransomware Response playbook auto-triggered',
            performedBy: 'System',
            timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
          ),
        ],
        evidence: {
          'encrypted_files': 1247,
          'ransom_note': 'PAY_TO_DECRYPT.txt',
          'process_name': 'suspicious.exe',
        },
        affectedAssets: ['FS-001', 'BACKUP-SERVER-01'],
      ),
      SecurityCase(
        id: 'case_003',
        title: 'Compliance Violation: Unencrypted PII Transfer',
        description: 'Personal data transmitted without encryption to external service',
        type: CaseType.compliance,
        status: CaseStatus.resolved,
        priority: CasePriority.medium,
        assignee: 'Mike Chen',
        tags: ['gdpr', 'data-protection', 'encryption'],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        resolvedAt: DateTime.now().subtract(const Duration(hours: 6)),
        activities: [
          CaseActivity(
            id: 'act_log_004',
            caseId: 'case_003',
            action: 'Resolution Applied',
            details: 'Encryption enabled for all external transfers',
            performedBy: 'Mike Chen',
            timestamp: DateTime.now().subtract(const Duration(hours: 6)),
          ),
        ],
        evidence: {
          'data_type': 'customer_records',
          'transfer_protocol': 'HTTP',
          'records_affected': 500,
        },
        affectedAssets: ['API-GATEWAY-01', 'WEB-APP-03'],
      ),
    ];
  }

  void _startSimulation() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _simulateActivity();
    });
  }

  void _simulateActivity() {
    // Randomly update case statuses
    if (_cases.isNotEmpty && _random.nextDouble() > 0.5) {
      final caseIndex = _random.nextInt(_cases.length);
      final currentCase = _cases[caseIndex];
      
      if (currentCase.status == CaseStatus.open) {
        _updateCaseStatus(currentCase.id, CaseStatus.investigating);
      } else if (currentCase.status == CaseStatus.investigating && _random.nextDouble() > 0.7) {
        _updateCaseStatus(currentCase.id, CaseStatus.resolved);
      }
    }

    // Randomly add new activity
    if (_cases.isNotEmpty && _random.nextDouble() > 0.6) {
      final caseIndex = _random.nextInt(_cases.length);
      final currentCase = _cases[caseIndex];
      
      final actions = ['Evidence collected', 'System analyzed', 'User interviewed', 'Logs reviewed'];
      final action = actions[_random.nextInt(actions.length)];
      
      _addCaseActivity(
        currentCase.id,
        action,
        'Automated simulation activity',
        'System',
      );
    }

    notifyListeners();
  }

  // Playbook Management
  void createPlaybook(String name, String description, String category) {
    final playbook = SecurityPlaybook(
      id: 'pb_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      category: category,
      status: PlaybookStatus.draft,
      actions: [],
      triggers: {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      author: 'Current User',
      useCount: 0,
      successRate: 0.0,
    );
    
    _playbooks.add(playbook);
    notifyListeners();
  }

  void updatePlaybookStatus(String playbookId, PlaybookStatus status) {
    final index = _playbooks.indexWhere((p) => p.id == playbookId);
    if (index != -1) {
      final playbook = _playbooks[index];
      _playbooks[index] = SecurityPlaybook(
        id: playbook.id,
        name: playbook.name,
        description: playbook.description,
        category: playbook.category,
        status: status,
        actions: playbook.actions,
        triggers: playbook.triggers,
        createdAt: playbook.createdAt,
        updatedAt: DateTime.now(),
        author: playbook.author,
        useCount: playbook.useCount,
        successRate: playbook.successRate,
      );
      notifyListeners();
    }
  }

  void executePlaybook(String playbookId, String caseId) {
    final playbook = _playbooks.firstWhere((p) => p.id == playbookId);
    
    // Simulate playbook execution
    Timer(const Duration(seconds: 2), () {
      _addCaseActivity(
        caseId,
        'Playbook Executed',
        'Executed ${playbook.name} with ${playbook.actions.length} actions',
        'System',
      );
      
      // Update playbook use count
      final index = _playbooks.indexOf(playbook);
      _playbooks[index] = SecurityPlaybook(
        id: playbook.id,
        name: playbook.name,
        description: playbook.description,
        category: playbook.category,
        status: playbook.status,
        actions: playbook.actions,
        triggers: playbook.triggers,
        createdAt: playbook.createdAt,
        updatedAt: playbook.updatedAt,
        author: playbook.author,
        useCount: playbook.useCount + 1,
        successRate: playbook.successRate,
      );
      
      notifyListeners();
    });
  }

  // Case Management
  void createCase({
    required String title,
    required String description,
    required CaseType type,
    required CasePriority priority,
    List<String>? tags,
    String? assignee,
  }) {
    final newCase = SecurityCase(
      id: 'case_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      type: type,
      status: CaseStatus.open,
      priority: priority,
      assignee: assignee,
      tags: tags ?? [],
      createdAt: DateTime.now(),
      activities: [
        CaseActivity(
          id: 'act_${DateTime.now().millisecondsSinceEpoch}',
          caseId: 'case_${DateTime.now().millisecondsSinceEpoch}',
          action: 'Case Created',
          details: 'Manual case creation',
          performedBy: assignee ?? 'Current User',
          timestamp: DateTime.now(),
        ),
      ],
      evidence: {},
      affectedAssets: [],
    );
    
    _cases.insert(0, newCase);
    notifyListeners();
  }

  void _updateCaseStatus(String caseId, CaseStatus status) {
    final index = _cases.indexWhere((c) => c.id == caseId);
    if (index != -1) {
      final currentCase = _cases[index];
      _cases[index] = SecurityCase(
        id: currentCase.id,
        title: currentCase.title,
        description: currentCase.description,
        type: currentCase.type,
        status: status,
        priority: currentCase.priority,
        assignee: currentCase.assignee,
        tags: currentCase.tags,
        createdAt: currentCase.createdAt,
        resolvedAt: status == CaseStatus.resolved ? DateTime.now() : currentCase.resolvedAt,
        playbookId: currentCase.playbookId,
        activities: currentCase.activities,
        evidence: currentCase.evidence,
        affectedAssets: currentCase.affectedAssets,
      );
    }
  }

  void _addCaseActivity(String caseId, String action, String details, String performedBy) {
    final index = _cases.indexWhere((c) => c.id == caseId);
    if (index != -1) {
      final currentCase = _cases[index];
      final newActivity = CaseActivity(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        caseId: caseId,
        action: action,
        details: details,
        performedBy: performedBy,
        timestamp: DateTime.now(),
      );
      
      final updatedActivities = [...currentCase.activities, newActivity];
      
      _cases[index] = SecurityCase(
        id: currentCase.id,
        title: currentCase.title,
        description: currentCase.description,
        type: currentCase.type,
        status: currentCase.status,
        priority: currentCase.priority,
        assignee: currentCase.assignee,
        tags: currentCase.tags,
        createdAt: currentCase.createdAt,
        resolvedAt: currentCase.resolvedAt,
        playbookId: currentCase.playbookId,
        activities: updatedActivities,
        evidence: currentCase.evidence,
        affectedAssets: currentCase.affectedAssets,
      );
    }
  }

  void assignCase(String caseId, String assignee) {
    final index = _cases.indexWhere((c) => c.id == caseId);
    if (index != -1) {
      final currentCase = _cases[index];
      _cases[index] = SecurityCase(
        id: currentCase.id,
        title: currentCase.title,
        description: currentCase.description,
        type: currentCase.type,
        status: currentCase.status,
        priority: currentCase.priority,
        assignee: assignee,
        tags: currentCase.tags,
        createdAt: currentCase.createdAt,
        resolvedAt: currentCase.resolvedAt,
        playbookId: currentCase.playbookId,
        activities: currentCase.activities,
        evidence: currentCase.evidence,
        affectedAssets: currentCase.affectedAssets,
      );
      
      _addCaseActivity(caseId, 'Case Assigned', 'Assigned to $assignee', 'System');
      notifyListeners();
    }
  }

  // Metrics
  OrchestrationMetrics getMetrics() {
    final openCases = _cases.where((c) => 
      c.status != CaseStatus.closed && c.status != CaseStatus.resolved).length;
    
    final casesByPriority = <CasePriority, int>{};
    final casesByType = <CaseType, int>{};
    
    for (final c in _cases) {
      casesByPriority[c.priority] = (casesByPriority[c.priority] ?? 0) + 1;
      casesByType[c.type] = (casesByType[c.type] ?? 0) + 1;
    }
    
    final resolvedCases = _cases.where((c) => c.resolvedAt != null).toList();
    double avgResolution = 0;
    if (resolvedCases.isNotEmpty) {
      final totalHours = resolvedCases.fold<double>(
        0,
        (sum, c) => sum + c.resolvedAt!.difference(c.createdAt).inHours,
      );
      avgResolution = totalHours / resolvedCases.length;
    }
    
    return OrchestrationMetrics(
      totalPlaybooks: _playbooks.length,
      activePlaybooks: _playbooks.where((p) => p.status == PlaybookStatus.active).length,
      totalCases: _cases.length,
      openCases: openCases,
      avgResolutionHours: avgResolution,
      casesByPriority: casesByPriority,
      casesByType: casesByType,
      recentExecutions: _playbooks.take(5).map((p) => {
        'name': p.name,
        'useCount': p.useCount,
        'successRate': p.successRate,
      }).toList(),
    );
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }
}
