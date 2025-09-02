import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Models
class ComplianceFramework {
  final String id;
  final String name;
  final String version;
  final String description;
  final List<ComplianceControl> controls;
  final double overallScore;
  final String status;
  final DateTime lastAssessment;
  final DateTime nextAssessment;

  ComplianceFramework({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.controls,
    required this.overallScore,
    required this.status,
    required this.lastAssessment,
    required this.nextAssessment,
  });
}

class ComplianceControl {
  final String id;
  final String name;
  final String category;
  final String description;
  final String requirement;
  final String status;
  final double score;
  final String evidence;
  final String responsible;
  final DateTime lastChecked;
  final List<String> gaps;
  final List<String> remediations;

  ComplianceControl({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.requirement,
    required this.status,
    required this.score,
    required this.evidence,
    required this.responsible,
    required this.lastChecked,
    required this.gaps,
    required this.remediations,
  });
}

class AuditReport {
  final String id;
  final String title;
  final String type;
  final String framework;
  final DateTime createdDate;
  final String createdBy;
  final String status;
  final Map<String, dynamic> findings;
  final List<String> recommendations;
  final String executiveSummary;
  final String format;

  AuditReport({
    required this.id,
    required this.title,
    required this.type,
    required this.framework,
    required this.createdDate,
    required this.createdBy,
    required this.status,
    required this.findings,
    required this.recommendations,
    required this.executiveSummary,
    required this.format,
  });
}

class ComplianceTask {
  final String id;
  final String title;
  final String description;
  final String framework;
  final String assignee;
  final String priority;
  final String status;
  final DateTime dueDate;
  final double progress;
  final List<String> notes;

  ComplianceTask({
    required this.id,
    required this.title,
    required this.description,
    required this.framework,
    required this.assignee,
    required this.priority,
    required this.status,
    required this.dueDate,
    required this.progress,
    required this.notes,
  });
}

class ComplianceReportingService extends ChangeNotifier {
  final List<ComplianceFramework> _frameworks = [];
  final List<AuditReport> _reports = [];
  final List<ComplianceTask> _tasks = [];
  
  bool _isAssessing = false;
  bool _isGeneratingReport = false;
  DateTime _lastAssessmentDate = DateTime.now();
  final Map<String, double> _trendData = {};
  
  Timer? _autoAssessmentTimer;
  
  // Getters
  List<ComplianceFramework> get frameworks => List.unmodifiable(_frameworks);
  List<AuditReport> get reports => List.unmodifiable(_reports);
  List<ComplianceTask> get tasks => List.unmodifiable(_tasks);
  bool get isAssessing => _isAssessing;
  bool get isGeneratingReport => _isGeneratingReport;
  DateTime get lastAssessmentDate => _lastAssessmentDate;
  Map<String, double> get trendData => Map.unmodifiable(_trendData);

  ComplianceReportingService() {
    _initializeFrameworks();
    _startAutoAssessment();
  }

  void _initializeFrameworks() {
    _frameworks.addAll([
      ComplianceFramework(
        id: 'pci-dss',
        name: 'PCI DSS',
        version: '4.0',
        description: 'Payment Card Industry Data Security Standard',
        controls: _generateControls('PCI'),
        overallScore: 87.5,
        status: 'Compliant',
        lastAssessment: DateTime.now().subtract(const Duration(days: 7)),
        nextAssessment: DateTime.now().add(const Duration(days: 23)),
      ),
      ComplianceFramework(
        id: 'iso-27001',
        name: 'ISO 27001',
        version: '2022',
        description: 'Information Security Management System',
        controls: _generateControls('ISO'),
        overallScore: 92.3,
        status: 'Compliant',
        lastAssessment: DateTime.now().subtract(const Duration(days: 14)),
        nextAssessment: DateTime.now().add(const Duration(days: 76)),
      ),
      ComplianceFramework(
        id: 'gdpr',
        name: 'GDPR',
        version: '2016/679',
        description: 'General Data Protection Regulation',
        controls: _generateControls('GDPR'),
        overallScore: 94.7,
        status: 'Compliant',
        lastAssessment: DateTime.now().subtract(const Duration(days: 3)),
        nextAssessment: DateTime.now().add(const Duration(days: 27)),
      ),
      ComplianceFramework(
        id: 'hipaa',
        name: 'HIPAA',
        version: '2013',
        description: 'Health Insurance Portability and Accountability Act',
        controls: _generateControls('HIPAA'),
        overallScore: 89.2,
        status: 'Compliant with Observations',
        lastAssessment: DateTime.now().subtract(const Duration(days: 21)),
        nextAssessment: DateTime.now().add(const Duration(days: 9)),
      ),
    ]);

    _generateMockReports();
    _generateMockTasks();
  }

  List<ComplianceControl> _generateControls(String prefix) {
    return [
      ComplianceControl(
        id: '$prefix-1',
        name: 'Access Control',
        category: 'Security',
        description: 'User access management and authentication',
        requirement: 'Implement strong access controls',
        status: 'Compliant',
        score: 95.0,
        evidence: 'Access logs reviewed',
        responsible: 'Security Team',
        lastChecked: DateTime.now().subtract(const Duration(days: 2)),
        gaps: [],
        remediations: [],
      ),
      ComplianceControl(
        id: '$prefix-2',
        name: 'Data Protection',
        category: 'Privacy',
        description: 'Data encryption and protection measures',
        requirement: 'Encrypt sensitive data at rest and in transit',
        status: 'Partially Compliant',
        score: 75.0,
        evidence: 'Encryption implemented',
        responsible: 'Data Team',
        lastChecked: DateTime.now().subtract(const Duration(days: 5)),
        gaps: ['Some legacy systems unencrypted'],
        remediations: ['Upgrade legacy systems'],
      ),
      ComplianceControl(
        id: '$prefix-3',
        name: 'Incident Response',
        category: 'Operations',
        description: 'Incident detection and response procedures',
        requirement: 'Establish incident response plan',
        status: 'Compliant',
        score: 90.0,
        evidence: 'IR plan documented and tested',
        responsible: 'SOC Team',
        lastChecked: DateTime.now().subtract(const Duration(days: 1)),
        gaps: [],
        remediations: [],
      ),
    ];
  }

  void _generateMockReports() {
    _reports.addAll([
      AuditReport(
        id: 'RPT-2024-001',
        title: 'Q4 2024 PCI DSS Compliance Report',
        type: 'Compliance Audit',
        framework: 'PCI DSS',
        createdDate: DateTime.now().subtract(const Duration(days: 5)),
        createdBy: 'John Smith',
        status: 'Final',
        findings: {
          'compliant': 45,
          'non_compliant': 2,
          'not_applicable': 8,
        },
        recommendations: [
          'Update network segmentation documentation',
          'Implement quarterly vulnerability scanning',
          'Enhance logging and monitoring',
        ],
        executiveSummary: 'Overall compliance level meets requirements with minor gaps.',
        format: 'PDF',
      ),
      AuditReport(
        id: 'RPT-2024-002',
        title: 'Annual ISO 27001 Assessment',
        type: 'Internal Audit',
        framework: 'ISO 27001',
        createdDate: DateTime.now().subtract(const Duration(days: 14)),
        createdBy: 'Jane Doe',
        status: 'Draft',
        findings: {
          'conformity': 112,
          'minor_nc': 5,
          'major_nc': 0,
        },
        recommendations: [
          'Update risk assessment methodology',
          'Improve incident response procedures',
        ],
        executiveSummary: 'ISO 27001 certification maintained with improvements needed.',
        format: 'DOCX',
      ),
    ]);
  }

  void _generateMockTasks() {
    _tasks.addAll([
      ComplianceTask(
        id: 'TASK-001',
        title: 'Update Data Retention Policy',
        description: 'Review and update data retention policy for GDPR compliance',
        framework: 'GDPR',
        assignee: 'Data Protection Officer',
        priority: 'High',
        status: 'In Progress',
        dueDate: DateTime.now().add(const Duration(days: 7)),
        progress: 65.0,
        notes: ['Legal review completed'],
      ),
      ComplianceTask(
        id: 'TASK-002',
        title: 'Quarterly Vulnerability Scan',
        description: 'Perform quarterly vulnerability scanning for PCI DSS',
        framework: 'PCI DSS',
        assignee: 'Security Team',
        priority: 'Critical',
        status: 'Scheduled',
        dueDate: DateTime.now().add(const Duration(days: 3)),
        progress: 0.0,
        notes: ['Scanner configured'],
      ),
      ComplianceTask(
        id: 'TASK-003',
        title: 'Access Control Review',
        description: 'Annual review of user access controls',
        framework: 'SOX',
        assignee: 'IT Audit',
        priority: 'Medium',
        status: 'Not Started',
        dueDate: DateTime.now().add(const Duration(days: 30)),
        progress: 0.0,
        notes: [],
      ),
    ]);
  }

  void _startAutoAssessment() {
    _autoAssessmentTimer?.cancel();
    _autoAssessmentTimer = Timer.periodic(const Duration(hours: 6), (_) {
      runAutomatedAssessment();
    });
  }

  Future<void> runAutomatedAssessment() async {
    _isAssessing = true;
    notifyListeners();
    
    await Future.delayed(const Duration(seconds: 3));
    
    // Update compliance scores
    for (var framework in _frameworks) {
      double totalScore = 0;
      int controlCount = 0;
      
      for (var control in framework.controls) {
        totalScore += control.score;
        controlCount++;
      }
      
      if (controlCount > 0) {
        final avgScore = totalScore / controlCount;
        _trendData[framework.id] = avgScore;
      }
    }
    
    _lastAssessmentDate = DateTime.now();
    _isAssessing = false;
    notifyListeners();
  }

  Future<void> generateReport(String frameworkId, String reportType) async {
    _isGeneratingReport = true;
    notifyListeners();
    
    await Future.delayed(const Duration(seconds: 2));
    
    final framework = _frameworks.firstWhere((f) => f.id == frameworkId);
    
    _reports.insert(0, AuditReport(
      id: 'RPT-${DateTime.now().millisecondsSinceEpoch}',
      title: '${framework.name} $reportType Report',
      type: reportType,
      framework: framework.name,
      createdDate: DateTime.now(),
      createdBy: 'System Generated',
      status: 'Draft',
      findings: {
        'total_controls': framework.controls.length,
        'compliant': framework.controls.where((c) => c.status == 'Compliant').length,
        'non_compliant': framework.controls.where((c) => c.status == 'Non-Compliant').length,
      },
      recommendations: framework.controls
          .where((c) => c.gaps.isNotEmpty)
          .expand((c) => c.remediations)
          .toList(),
      executiveSummary: 'Automated assessment completed for ${framework.name}',
      format: 'PDF',
    ));
    
    _isGeneratingReport = false;
    notifyListeners();
  }

  void updateControlStatus(String frameworkId, String controlId, String newStatus, double newScore) {
    final frameworkIndex = _frameworks.indexWhere((f) => f.id == frameworkId);
    if (frameworkIndex != -1) {
      final framework = _frameworks[frameworkIndex];
      final controlIndex = framework.controls.indexWhere((c) => c.id == controlId);
      
      if (controlIndex != -1) {
        final control = framework.controls[controlIndex];
        framework.controls[controlIndex] = ComplianceControl(
          id: control.id,
          name: control.name,
          category: control.category,
          description: control.description,
          requirement: control.requirement,
          status: newStatus,
          score: newScore,
          evidence: control.evidence,
          responsible: control.responsible,
          lastChecked: DateTime.now(),
          gaps: control.gaps,
          remediations: control.remediations,
        );
        notifyListeners();
      }
    }
  }

  void createTask(String title, String description, String framework, String assignee, String priority, DateTime dueDate) {
    _tasks.insert(0, ComplianceTask(
      id: 'TASK-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      framework: framework,
      assignee: assignee,
      priority: priority,
      status: 'Not Started',
      dueDate: dueDate,
      progress: 0.0,
      notes: [],
    ));
    notifyListeners();
  }

  void updateTaskProgress(String taskId, double progress, String status) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      _tasks[index] = ComplianceTask(
        id: task.id,
        title: task.title,
        description: task.description,
        framework: task.framework,
        assignee: task.assignee,
        priority: task.priority,
        status: status,
        dueDate: task.dueDate,
        progress: progress,
        notes: task.notes,
      );
      notifyListeners();
    }
  }

  Map<String, int> getComplianceMetrics() {
    int totalControls = 0;
    int compliantControls = 0;
    int nonCompliantControls = 0;
    int partiallyCompliantControls = 0;
    
    for (var framework in _frameworks) {
      for (var control in framework.controls) {
        totalControls++;
        switch (control.status) {
          case 'Compliant':
            compliantControls++;
            break;
          case 'Non-Compliant':
            nonCompliantControls++;
            break;
          case 'Partially Compliant':
            partiallyCompliantControls++;
            break;
        }
      }
    }
    
    return {
      'total': totalControls,
      'compliant': compliantControls,
      'non_compliant': nonCompliantControls,
      'partially_compliant': partiallyCompliantControls,
    };
  }

  @override
  void dispose() {
    _autoAssessmentTimer?.cancel();
    super.dispose();
  }
}
