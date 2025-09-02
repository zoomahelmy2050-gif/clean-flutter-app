import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ComplianceFramework {
  soc2,
  gdpr,
  hipaa,
  pciDss,
  iso27001,
  nist,
  ccpa,
  sox,
}

enum ComplianceStatus {
  compliant,
  nonCompliant,
  partiallyCompliant,
  notAssessed,
}

enum DataProcessingPurpose {
  authentication,
  analytics,
  marketing,
  support,
  legal,
  security,
}

class ComplianceRequirement {
  final String id;
  final ComplianceFramework framework;
  final String category;
  final String title;
  final String description;
  final ComplianceStatus status;
  final List<String> evidenceFiles;
  final DateTime lastAssessed;
  final DateTime? nextAssessment;
  final String? assessor;
  final Map<String, dynamic> metadata;

  ComplianceRequirement({
    required this.id,
    required this.framework,
    required this.category,
    required this.title,
    required this.description,
    required this.status,
    this.evidenceFiles = const [],
    required this.lastAssessed,
    this.nextAssessment,
    this.assessor,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'framework': framework.name,
    'category': category,
    'title': title,
    'description': description,
    'status': status.name,
    'evidenceFiles': evidenceFiles,
    'lastAssessed': lastAssessed.toIso8601String(),
    'nextAssessment': nextAssessment?.toIso8601String(),
    'assessor': assessor,
    'metadata': metadata,
  };

  factory ComplianceRequirement.fromJson(Map<String, dynamic> json) {
    return ComplianceRequirement(
      id: json['id'],
      framework: ComplianceFramework.values.firstWhere((e) => e.name == json['framework']),
      category: json['category'],
      title: json['title'],
      description: json['description'],
      status: ComplianceStatus.values.firstWhere((e) => e.name == json['status']),
      evidenceFiles: List<String>.from(json['evidenceFiles'] ?? []),
      lastAssessed: DateTime.parse(json['lastAssessed']),
      nextAssessment: json['nextAssessment'] != null ? DateTime.parse(json['nextAssessment']) : null,
      assessor: json['assessor'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

class DataProcessingActivity {
  final String id;
  final String name;
  final String description;
  final DataProcessingPurpose purpose;
  final List<String> dataTypes;
  final List<String> dataSubjects;
  final String legalBasis;
  final Duration retentionPeriod;
  final List<String> recipients;
  final bool internationalTransfer;
  final List<String> safeguards;
  final DateTime createdAt;
  final DateTime lastUpdated;

  DataProcessingActivity({
    required this.id,
    required this.name,
    required this.description,
    required this.purpose,
    required this.dataTypes,
    required this.dataSubjects,
    required this.legalBasis,
    required this.retentionPeriod,
    this.recipients = const [],
    this.internationalTransfer = false,
    this.safeguards = const [],
    required this.createdAt,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'purpose': purpose.name,
    'dataTypes': dataTypes,
    'dataSubjects': dataSubjects,
    'legalBasis': legalBasis,
    'retentionPeriod': retentionPeriod.inDays,
    'recipients': recipients,
    'internationalTransfer': internationalTransfer,
    'safeguards': safeguards,
    'createdAt': createdAt.toIso8601String(),
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory DataProcessingActivity.fromJson(Map<String, dynamic> json) {
    return DataProcessingActivity(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      purpose: DataProcessingPurpose.values.firstWhere((e) => e.name == json['purpose']),
      dataTypes: List<String>.from(json['dataTypes']),
      dataSubjects: List<String>.from(json['dataSubjects']),
      legalBasis: json['legalBasis'],
      retentionPeriod: Duration(days: json['retentionPeriod']),
      recipients: List<String>.from(json['recipients'] ?? []),
      internationalTransfer: json['internationalTransfer'] ?? false,
      safeguards: List<String>.from(json['safeguards'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}

class ComplianceReport {
  final String id;
  final ComplianceFramework framework;
  final String title;
  final DateTime generatedAt;
  final DateTime reportingPeriodStart;
  final DateTime reportingPeriodEnd;
  final Map<String, dynamic> summary;
  final List<String> findings;
  final List<String> recommendations;
  final Map<String, dynamic> metrics;

  ComplianceReport({
    required this.id,
    required this.framework,
    required this.title,
    required this.generatedAt,
    required this.reportingPeriodStart,
    required this.reportingPeriodEnd,
    required this.summary,
    this.findings = const [],
    this.recommendations = const [],
    this.metrics = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'framework': framework.name,
    'title': title,
    'generatedAt': generatedAt.toIso8601String(),
    'reportingPeriodStart': reportingPeriodStart.toIso8601String(),
    'reportingPeriodEnd': reportingPeriodEnd.toIso8601String(),
    'summary': summary,
    'findings': findings,
    'recommendations': recommendations,
    'metrics': metrics,
  };

  factory ComplianceReport.fromJson(Map<String, dynamic> json) {
    return ComplianceReport(
      id: json['id'],
      framework: ComplianceFramework.values.firstWhere((e) => e.name == json['framework']),
      title: json['title'],
      generatedAt: DateTime.parse(json['generatedAt']),
      reportingPeriodStart: DateTime.parse(json['reportingPeriodStart']),
      reportingPeriodEnd: DateTime.parse(json['reportingPeriodEnd']),
      summary: Map<String, dynamic>.from(json['summary']),
      findings: List<String>.from(json['findings'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      metrics: Map<String, dynamic>.from(json['metrics'] ?? {}),
    );
  }
}

class ComplianceReportingService extends ChangeNotifier {
  final List<ComplianceRequirement> _requirements = [];
  final List<DataProcessingActivity> _dataActivities = [];
  final List<ComplianceReport> _reports = [];
  Timer? _assessmentTimer;
  
  static const String _requirementsKey = 'compliance_requirements';
  static const String _dataActivitiesKey = 'data_processing_activities';
  static const String _reportsKey = 'compliance_reports';

  // Getters
  List<ComplianceRequirement> get requirements => List.unmodifiable(_requirements);
  List<DataProcessingActivity> get dataActivities => List.unmodifiable(_dataActivities);
  List<ComplianceReport> get reports => List.unmodifiable(_reports);

  /// Initialize compliance reporting service
  Future<void> initialize() async {
    await _loadRequirements();
    await _loadDataActivities();
    await _loadReports();
    await _initializeDefaultRequirements();
    await _startAssessmentTimer();
  }

  /// Load requirements from storage
  Future<void> _loadRequirements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final requirementsJson = prefs.getStringList(_requirementsKey) ?? [];
      
      _requirements.clear();
      for (final reqJson in requirementsJson) {
        final Map<String, dynamic> data = jsonDecode(reqJson);
        _requirements.add(ComplianceRequirement.fromJson(data));
      }
    } catch (e) {
      debugPrint('Error loading compliance requirements: $e');
    }
  }

  /// Save requirements to storage
  Future<void> _saveRequirements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final requirementsJson = _requirements.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList(_requirementsKey, requirementsJson);
    } catch (e) {
      debugPrint('Error saving compliance requirements: $e');
    }
  }

  /// Load data activities from storage
  Future<void> _loadDataActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activitiesJson = prefs.getStringList(_dataActivitiesKey) ?? [];
      
      _dataActivities.clear();
      for (final activityJson in activitiesJson) {
        final Map<String, dynamic> data = jsonDecode(activityJson);
        _dataActivities.add(DataProcessingActivity.fromJson(data));
      }
    } catch (e) {
      debugPrint('Error loading data processing activities: $e');
    }
  }

  /// Save data activities to storage
  Future<void> _saveDataActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activitiesJson = _dataActivities.map((a) => jsonEncode(a.toJson())).toList();
      await prefs.setStringList(_dataActivitiesKey, activitiesJson);
    } catch (e) {
      debugPrint('Error saving data processing activities: $e');
    }
  }

  /// Load reports from storage
  Future<void> _loadReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = prefs.getStringList(_reportsKey) ?? [];
      
      _reports.clear();
      for (final reportJson in reportsJson) {
        final Map<String, dynamic> data = jsonDecode(reportJson);
        _reports.add(ComplianceReport.fromJson(data));
      }
    } catch (e) {
      debugPrint('Error loading compliance reports: $e');
    }
  }

  /// Save reports to storage
  Future<void> _saveReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = _reports.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList(_reportsKey, reportsJson);
    } catch (e) {
      debugPrint('Error saving compliance reports: $e');
    }
  }

  /// Initialize default requirements
  Future<void> _initializeDefaultRequirements() async {
    if (_requirements.isNotEmpty) return;

    final defaultRequirements = [
      // GDPR Requirements
      ComplianceRequirement(
        id: 'gdpr_data_protection_policy',
        framework: ComplianceFramework.gdpr,
        category: 'Data Protection',
        title: 'Data Protection Policy',
        description: 'Implement comprehensive data protection policy',
        status: ComplianceStatus.compliant,
        lastAssessed: DateTime.now(),
        nextAssessment: DateTime.now().add(const Duration(days: 365)),
      ),
      ComplianceRequirement(
        id: 'gdpr_consent_management',
        framework: ComplianceFramework.gdpr,
        category: 'Consent',
        title: 'Consent Management System',
        description: 'Implement system for managing user consent',
        status: ComplianceStatus.compliant,
        lastAssessed: DateTime.now(),
        nextAssessment: DateTime.now().add(const Duration(days: 365)),
      ),
      ComplianceRequirement(
        id: 'gdpr_data_breach_notification',
        framework: ComplianceFramework.gdpr,
        category: 'Incident Response',
        title: 'Data Breach Notification',
        description: 'Process for notifying authorities of data breaches within 72 hours',
        status: ComplianceStatus.partiallyCompliant,
        lastAssessed: DateTime.now(),
        nextAssessment: DateTime.now().add(const Duration(days: 90)),
      ),
      
      // SOC 2 Requirements
      ComplianceRequirement(
        id: 'soc2_access_controls',
        framework: ComplianceFramework.soc2,
        category: 'Security',
        title: 'Access Controls',
        description: 'Implement logical and physical access controls',
        status: ComplianceStatus.compliant,
        lastAssessed: DateTime.now(),
        nextAssessment: DateTime.now().add(const Duration(days: 365)),
      ),
      ComplianceRequirement(
        id: 'soc2_system_monitoring',
        framework: ComplianceFramework.soc2,
        category: 'Monitoring',
        title: 'System Monitoring',
        description: 'Continuous monitoring of system activities',
        status: ComplianceStatus.compliant,
        lastAssessed: DateTime.now(),
        nextAssessment: DateTime.now().add(const Duration(days: 365)),
      ),
      
      // ISO 27001 Requirements
      ComplianceRequirement(
        id: 'iso27001_risk_assessment',
        framework: ComplianceFramework.iso27001,
        category: 'Risk Management',
        title: 'Information Security Risk Assessment',
        description: 'Regular assessment of information security risks',
        status: ComplianceStatus.partiallyCompliant,
        lastAssessed: DateTime.now(),
        nextAssessment: DateTime.now().add(const Duration(days: 180)),
      ),
    ];

    _requirements.addAll(defaultRequirements);
    await _saveRequirements();

    // Initialize default data processing activities
    final defaultActivities = [
      DataProcessingActivity(
        id: 'user_authentication',
        name: 'User Authentication',
        description: 'Processing user credentials for authentication',
        purpose: DataProcessingPurpose.authentication,
        dataTypes: ['Email', 'Password Hash', 'MFA Tokens'],
        dataSubjects: ['App Users'],
        legalBasis: 'Contract Performance',
        retentionPeriod: const Duration(days: 2555), // 7 years
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      ),
      DataProcessingActivity(
        id: 'security_monitoring',
        name: 'Security Monitoring',
        description: 'Monitoring for security threats and incidents',
        purpose: DataProcessingPurpose.security,
        dataTypes: ['IP Addresses', 'Device Information', 'Access Logs'],
        dataSubjects: ['App Users'],
        legalBasis: 'Legitimate Interest',
        retentionPeriod: const Duration(days: 365),
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      ),
    ];

    _dataActivities.addAll(defaultActivities);
    await _saveDataActivities();
  }

  /// Start assessment timer
  Future<void> _startAssessmentTimer() async {
    _assessmentTimer = Timer.periodic(const Duration(days: 1), (_) {
      _checkAssessmentDueDates();
    });
  }

  /// Check assessment due dates
  void _checkAssessmentDueDates() {
    final now = DateTime.now();
    
    for (final requirement in _requirements) {
      if (requirement.nextAssessment != null && 
          requirement.nextAssessment!.isBefore(now)) {
        debugPrint('Assessment due for: ${requirement.title}');
        // In a real implementation, this would trigger notifications
      }
    }
  }

  /// Generate compliance report
  Future<String> generateComplianceReport({
    required ComplianceFramework framework,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    final now = DateTime.now();
    final start = periodStart ?? now.subtract(const Duration(days: 365));
    final end = periodEnd ?? now;
    
    final frameworkRequirements = _requirements.where((r) => r.framework == framework).toList();
    
    // Calculate compliance metrics
    final totalRequirements = frameworkRequirements.length;
    final compliantCount = frameworkRequirements.where((r) => r.status == ComplianceStatus.compliant).length;
    final nonCompliantCount = frameworkRequirements.where((r) => r.status == ComplianceStatus.nonCompliant).length;
    final partiallyCompliantCount = frameworkRequirements.where((r) => r.status == ComplianceStatus.partiallyCompliant).length;
    
    final compliancePercentage = totalRequirements > 0 ? (compliantCount / totalRequirements * 100) : 0.0;
    
    // Generate findings and recommendations
    final findings = <String>[];
    final recommendations = <String>[];
    
    for (final req in frameworkRequirements) {
      if (req.status == ComplianceStatus.nonCompliant) {
        findings.add('Non-compliant: ${req.title} - ${req.description}');
        recommendations.add('Address non-compliance in ${req.category}: ${req.title}');
      } else if (req.status == ComplianceStatus.partiallyCompliant) {
        findings.add('Partially compliant: ${req.title} - ${req.description}');
        recommendations.add('Complete implementation for ${req.category}: ${req.title}');
      }
    }
    
    // Check for overdue assessments
    for (final req in frameworkRequirements) {
      if (req.nextAssessment != null && req.nextAssessment!.isBefore(now)) {
        findings.add('Overdue assessment: ${req.title}');
        recommendations.add('Schedule reassessment for ${req.title}');
      }
    }
    
    final report = ComplianceReport(
      id: 'report_${framework.name}_${now.millisecondsSinceEpoch}',
      framework: framework,
      title: '${_getFrameworkDisplayName(framework)} Compliance Report',
      generatedAt: now,
      reportingPeriodStart: start,
      reportingPeriodEnd: end,
      summary: {
        'total_requirements': totalRequirements,
        'compliant_count': compliantCount,
        'non_compliant_count': nonCompliantCount,
        'partially_compliant_count': partiallyCompliantCount,
        'compliance_percentage': compliancePercentage,
        'assessment_coverage': _calculateAssessmentCoverage(frameworkRequirements),
      },
      findings: findings,
      recommendations: recommendations,
      metrics: {
        'data_processing_activities': _dataActivities.length,
        'security_incidents': 0, // Would integrate with incident service
        'data_breaches': 0, // Would integrate with incident service
        'user_requests': 0, // Would track GDPR requests
      },
    );
    
    _reports.insert(0, report);
    
    // Keep only last 100 reports
    if (_reports.length > 100) {
      _reports.removeRange(100, _reports.length);
    }
    
    await _saveReports();
    notifyListeners();
    
    return report.id;
  }

  /// Calculate assessment coverage
  double _calculateAssessmentCoverage(List<ComplianceRequirement> requirements) {
    if (requirements.isEmpty) return 0.0;
    
    final now = DateTime.now();
    final recentlyAssessed = requirements.where((r) => 
      now.difference(r.lastAssessed).inDays <= 365
    ).length;
    
    return recentlyAssessed / requirements.length * 100;
  }

  /// Get framework display name
  String _getFrameworkDisplayName(ComplianceFramework framework) {
    switch (framework) {
      case ComplianceFramework.soc2:
        return 'SOC 2';
      case ComplianceFramework.gdpr:
        return 'GDPR';
      case ComplianceFramework.hipaa:
        return 'HIPAA';
      case ComplianceFramework.pciDss:
        return 'PCI DSS';
      case ComplianceFramework.iso27001:
        return 'ISO 27001';
      case ComplianceFramework.nist:
        return 'NIST';
      case ComplianceFramework.ccpa:
        return 'CCPA';
      case ComplianceFramework.sox:
        return 'SOX';
    }
  }

  /// Add compliance requirement
  Future<void> addRequirement(ComplianceRequirement requirement) async {
    _requirements.add(requirement);
    await _saveRequirements();
    notifyListeners();
  }

  /// Update compliance requirement
  Future<void> updateRequirement(ComplianceRequirement requirement) async {
    final index = _requirements.indexWhere((r) => r.id == requirement.id);
    if (index != -1) {
      _requirements[index] = requirement;
      await _saveRequirements();
      notifyListeners();
    }
  }

  /// Add data processing activity
  Future<void> addDataActivity(DataProcessingActivity activity) async {
    _dataActivities.add(activity);
    await _saveDataActivities();
    notifyListeners();
  }

  /// Update data processing activity
  Future<void> updateDataActivity(DataProcessingActivity activity) async {
    final index = _dataActivities.indexWhere((a) => a.id == activity.id);
    if (index != -1) {
      _dataActivities[index] = activity;
      await _saveDataActivities();
      notifyListeners();
    }
  }

  /// Get compliance dashboard data
  Map<String, dynamic> getComplianceDashboard() {
    final totalRequirements = _requirements.length;
    final compliantCount = _requirements.where((r) => r.status == ComplianceStatus.compliant).length;
    final nonCompliantCount = _requirements.where((r) => r.status == ComplianceStatus.nonCompliant).length;
    final partiallyCompliantCount = _requirements.where((r) => r.status == ComplianceStatus.partiallyCompliant).length;
    
    final now = DateTime.now();
    final overdueAssessments = _requirements.where((r) => 
      r.nextAssessment != null && r.nextAssessment!.isBefore(now)
    ).length;
    
    final frameworkCoverage = <String, Map<String, dynamic>>{};
    for (final framework in ComplianceFramework.values) {
      final frameworkReqs = _requirements.where((r) => r.framework == framework).toList();
      if (frameworkReqs.isNotEmpty) {
        final compliant = frameworkReqs.where((r) => r.status == ComplianceStatus.compliant).length;
        frameworkCoverage[framework.name] = {
          'total': frameworkReqs.length,
          'compliant': compliant,
          'percentage': (compliant / frameworkReqs.length * 100).round(),
        };
      }
    }
    
    return {
      'total_requirements': totalRequirements,
      'compliant_count': compliantCount,
      'non_compliant_count': nonCompliantCount,
      'partially_compliant_count': partiallyCompliantCount,
      'overall_compliance': totalRequirements > 0 ? (compliantCount / totalRequirements * 100).round() : 0,
      'overdue_assessments': overdueAssessments,
      'framework_coverage': frameworkCoverage,
      'data_activities_count': _dataActivities.length,
      'reports_generated': _reports.length,
      'last_report_date': _reports.isNotEmpty ? _reports.first.generatedAt.toIso8601String() : null,
    };
  }

  /// Export compliance data
  Map<String, dynamic> exportComplianceData() {
    return {
      'requirements': _requirements.map((r) => r.toJson()).toList(),
      'data_activities': _dataActivities.map((a) => a.toJson()).toList(),
      'reports': _reports.map((r) => r.toJson()).toList(),
      'dashboard': getComplianceDashboard(),
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  void dispose() {
    _assessmentTimer?.cancel();
    super.dispose();
  }
}
