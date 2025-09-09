import 'dart:async';
import 'dart:math';
import 'dart:convert';
import '../../../core/models/compliance_models.dart';
import '../../../locator.dart';
import 'dart:developer' as developer;

class ComplianceCheckResult {
  final String id;
  final String name;
  final bool passed;
  final String severity; // low, medium, high
  final String? details;

  ComplianceCheckResult({
    required this.id,
    required this.name,
    required this.passed,
    required this.severity,
    this.details,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'passed': passed,
    'severity': severity,
    'details': details,
  };
}

// Removed local ComplianceReport class to avoid conflicts; use model from core/models

class ComplianceService {
  final List<ComplianceFramework> _frameworks = [];
  final List<ComplianceReport> _reports = [];
  final List<AuditEvidence> _evidence = [];
  final List<DataRetentionPolicy> _retentionPolicies = [];
  
  ComplianceService() {
    _initializeMockData();
    _connectToCompliancePlatforms();
  }

  void _connectToCompliancePlatforms() {
    // Mock platform connection - replace with actual implementation when available
    developer.log('Mock compliance platform connection initialized', name: 'ComplianceService');
  }

  void _processComplianceUpdate(Map<String, dynamic> update) {
    final frameworkId = update['frameworkId'] as String?;
    final controlId = update['controlId'] as String?;
    final status = update['status'] as String?;
    
    if (frameworkId != null && controlId != null && status != null) {
      final framework = _frameworks.firstWhere(
        (f) => f.id == frameworkId,
        orElse: () => _frameworks.first,
      );
      
      // Update control status based on external platform data
      final controlIndex = framework.controls.indexWhere((c) => c.id == controlId);
      if (controlIndex != -1) {
        final control = framework.controls[controlIndex];
        final updatedControl = ComplianceControl(
          id: control.id,
          title: control.title,
          description: control.description,
          requirement: control.requirement,
          status: _mapComplianceStatus(status),
          lastAssessed: DateTime.now(),
          assessedBy: 'System',
          evidenceIds: control.evidenceIds,
          notes: control.notes,
        );
        framework.controls[controlIndex] = updatedControl;
        developer.log('Updated compliance control $controlId from external platform', name: 'ComplianceService');
      }
    }
  }

  ComplianceStatus _mapComplianceStatus(String status) {
    switch (status.toLowerCase()) {
      case 'compliant':
        return ComplianceStatus.compliant;
      case 'non_compliant':
        return ComplianceStatus.nonCompliant;
      case 'in_progress':
        return ComplianceStatus.inProgress;
      case 'not_assessed':
        return ComplianceStatus.notAssessed;
      default:
        return ComplianceStatus.notAssessed;
    }
  }

  void _initializeMockData() {
    // Mock compliance frameworks
    _frameworks.addAll([
      ComplianceFramework(
        id: '1',
        name: 'GDPR - General Data Protection Regulation',
        description: 'EU regulation on data protection and privacy',
        type: 'GDPR',
        status: ComplianceStatus.inProgress,
        totalControls: 25,
        completedControls: 18,
        lastUpdated: DateTime.now().subtract(const Duration(days: 5)),
        controls: _generateGDPRControls(),
      ),
      ComplianceFramework(
        id: '2',
        name: 'SOC 2 Type II',
        description: 'Service Organization Control 2 audit framework',
        type: 'SOC2',
        status: ComplianceStatus.compliant,
        totalControls: 35,
        completedControls: 35,
        lastUpdated: DateTime.now().subtract(const Duration(days: 2)),
        controls: _generateSOC2Controls(),
      ),
      ComplianceFramework(
        id: '3',
        name: 'ISO 27001:2013',
        description: 'Information security management systems standard',
        type: 'ISO27001',
        status: ComplianceStatus.inProgress,
        totalControls: 114,
        completedControls: 89,
        lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
        controls: _generateISO27001Controls(),
      ),
      ComplianceFramework(
        id: '4',
        name: 'HIPAA Security Rule',
        description: 'Health Insurance Portability and Accountability Act',
        type: 'HIPAA',
        status: ComplianceStatus.nonCompliant,
        totalControls: 18,
        completedControls: 12,
        lastUpdated: DateTime.now().subtract(const Duration(days: 10)),
        controls: _generateHIPAAControls(),
      ),
    ]);

    // Mock compliance reports
    _reports.addAll([
      ComplianceReport(
        id: 'report_${Random().nextInt(1000)}',
        title: 'GDPR Compliance Report',
        description: 'Comprehensive GDPR compliance assessment',
        type: 'Assessment',
        generatedAt: DateTime.now(),
        generatedBy: 'System',
        frameworkIds: ['1'],
        findings: {
          'overallScore': 82.5,
          'criticalFindings': 3,
          'recommendations': 12,
        },
      ),
      ComplianceReport(
        id: 'report_${Random().nextInt(1000)}',
        title: 'SOC 2 Readiness Assessment',
        description: 'Pre-audit assessment for SOC 2 Type II certification',
        type: 'Readiness',
        generatedAt: DateTime.now().subtract(const Duration(days: 21)),
        generatedBy: 'Auditor',
        frameworkIds: ['2'],
        findings: {
          'readinessScore': 95.0,
          'minorFindings': 2,
          'recommendedActions': 5,
        },
      ),
      ComplianceReport(
        id: 'report_${Random().nextInt(1000)}',
        title: 'ISO 27001 Gap Analysis Report',
        description: 'Detailed analysis of ISO 27001 compliance gaps',
        type: 'Gap Analysis',
        generatedAt: DateTime.now().subtract(const Duration(days: 14)),
        generatedBy: 'Compliance Team',
        frameworkIds: ['3'],
        findings: {
          'identifiedGaps': 7,
          'highPriorityGaps': 2,
          'estimatedRemediationTime': '6 weeks',
        },
      ),
      ComplianceReport(
        id: 'report_${Random().nextInt(1000)}',
        title: 'HIPAA Security Rule Assessment',
        description: 'Comprehensive assessment of HIPAA Security Rule compliance',
        type: 'Security Assessment',
        generatedAt: DateTime.now().subtract(const Duration(days: 10)),
        generatedBy: 'Security Team',
        frameworkIds: ['4'],
        findings: {
          'overallScore': 75.0,
          'criticalFindings': 5,
          'recommendations': 15,
        },
      ),
    ]);

    // Mock audit evidence
    _evidence.addAll([
      AuditEvidence(
        id: '1',
        title: 'Data Processing Agreement Template',
        description: 'Standard DPA template used with third-party processors',
        type: EvidenceType.document,
        controlId: 'GDPR-001',
        collectedAt: DateTime.now().subtract(const Duration(days: 3)),
        collectedBy: 'Legal Team',
        isVerified: true,
        filePath: '/evidence/dpa_template.pdf',
        metadata: {'version': '2.1', 'approvedBy': 'Legal Counsel'},
      ),
      AuditEvidence(
        id: '2',
        title: 'Access Control Matrix Screenshot',
        description: 'Screenshot showing role-based access controls in production',
        type: EvidenceType.screenshot,
        controlId: 'SOC2-CC6.1',
        collectedAt: DateTime.now().subtract(const Duration(days: 1)),
        collectedBy: 'IT Security',
        isVerified: true,
        filePath: '/evidence/access_control_matrix.png',
        metadata: {'system': 'production', 'timestamp': '2024-01-15T10:30:00Z'},
      ),
      AuditEvidence(
        id: '3',
        title: 'Security Incident Response Logs',
        description: 'Logs showing incident response procedures execution',
        type: EvidenceType.log,
        controlId: 'ISO-A.16.1.5',
        collectedAt: DateTime.now().subtract(const Duration(hours: 6)),
        collectedBy: 'Security Operations',
        isVerified: false,
        filePath: '/evidence/incident_response_logs.txt',
        metadata: {'incidentId': 'INC-2024-001', 'severity': 'medium'},
      ),
      AuditEvidence(
        id: '4',
        title: 'SSL Certificate',
        description: 'Current SSL certificate for main application domain',
        type: EvidenceType.certificate,
        controlId: 'SOC2-CC6.7',
        collectedAt: DateTime.now().subtract(const Duration(days: 2)),
        collectedBy: 'DevOps Team',
        isVerified: true,
        filePath: '/evidence/ssl_certificate.pem',
        metadata: {'domain': 'app.company.com', 'expiryDate': '2024-12-31'},
      ),
    ]);

    // Mock data retention policies
    _retentionPolicies.addAll([
      DataRetentionPolicy(
        id: '1',
        name: 'Customer Personal Data',
        description: 'Retention policy for customer personal information',
        dataCategory: 'Personal Data',
        retentionPeriodDays: 2555, // 7 years
        retentionReason: 'Legal and business requirements',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        lastReviewed: DateTime.now().subtract(const Duration(days: 30)),
        applicableFrameworks: ['GDPR', 'SOC2'],
      ),
      DataRetentionPolicy(
        id: '2',
        name: 'Application Logs',
        description: 'Retention policy for application and security logs',
        dataCategory: 'Log Data',
        retentionPeriodDays: 365, // 1 year
        retentionReason: 'Security monitoring and incident investigation',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        lastReviewed: DateTime.now().subtract(const Duration(days: 15)),
        applicableFrameworks: ['SOC2', 'ISO27001'],
      ),
    ]);
  }

  List<ComplianceControl> _generateGDPRControls() {
    return [
      ComplianceControl(
        id: 'GDPR-001',
        title: 'Data Processing Agreements',
        description: 'Ensure all third-party processors have signed DPAs',
        requirement: 'Article 28 - Processor obligations',
        status: ComplianceStatus.compliant,
        lastAssessed: DateTime.now().subtract(const Duration(days: 5)),
        assessedBy: 'Legal Team',
        evidenceIds: ['1'],
        notes: 'All current processors have valid DPAs in place',
      ),
      ComplianceControl(
        id: 'GDPR-002',
        title: 'Data Subject Rights',
        description: 'Implement procedures for handling data subject requests',
        requirement: 'Articles 15-22 - Data subject rights',
        status: ComplianceStatus.inProgress,
        lastAssessed: DateTime.now().subtract(const Duration(days: 10)),
        assessedBy: 'Privacy Officer',
        evidenceIds: [],
        notes: 'Automated system 80% complete',
      ),
      ComplianceControl(
        id: 'GDPR-003',
        title: 'Privacy by Design',
        description: 'Implement privacy considerations in system design',
        requirement: 'Article 25 - Data protection by design',
        status: ComplianceStatus.compliant,
        lastAssessed: DateTime.now().subtract(const Duration(days: 3)),
        assessedBy: 'Engineering Team',
        evidenceIds: [],
        notes: 'Privacy impact assessments completed for all new features',
      ),
    ];
  }

  List<ComplianceControl> _generateSOC2Controls() {
    return [
      ComplianceControl(
        id: 'SOC2-CC6.1',
        title: 'Logical Access Controls',
        description: 'Implement role-based access controls',
        requirement: 'Common Criteria 6.1 - Logical and physical access controls',
        status: ComplianceStatus.compliant,
        lastAssessed: DateTime.now().subtract(const Duration(days: 1)),
        assessedBy: 'IT Security',
        evidenceIds: ['2'],
        notes: 'RBAC implemented across all systems',
      ),
      ComplianceControl(
        id: 'SOC2-CC6.7',
        title: 'Data Transmission Controls',
        description: 'Encrypt data in transit using strong encryption',
        requirement: 'Common Criteria 6.7 - Data transmission',
        status: ComplianceStatus.compliant,
        lastAssessed: DateTime.now().subtract(const Duration(days: 2)),
        assessedBy: 'DevOps Team',
        evidenceIds: ['4'],
        notes: 'TLS 1.3 implemented for all external communications',
      ),
    ];
  }

  List<ComplianceControl> _generateISO27001Controls() {
    return [
      ComplianceControl(
        id: 'ISO-A.16.1.5',
        title: 'Response to Information Security Incidents',
        description: 'Establish incident response procedures',
        requirement: 'A.16.1.5 - Response to information security incidents',
        status: ComplianceStatus.compliant,
        lastAssessed: DateTime.now().subtract(const Duration(hours: 6)),
        assessedBy: 'Security Operations',
        evidenceIds: ['3'],
        notes: 'Incident response playbooks tested quarterly',
      ),
    ];
  }

  List<ComplianceControl> _generateHIPAAControls() {
    return [
      ComplianceControl(
        id: 'HIPAA-164.312',
        title: 'Access Control',
        description: 'Implement access controls for PHI',
        requirement: '164.312(a)(1) - Access control',
        status: ComplianceStatus.nonCompliant,
        lastAssessed: DateTime.now().subtract(const Duration(days: 10)),
        assessedBy: 'Compliance Officer',
        evidenceIds: [],
        notes: 'Need to implement unique user identification for PHI access',
      ),
    ];
  }

  // Public API methods
  Future<List<ComplianceFramework>> getComplianceFrameworks() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _frameworks;
  }

  Future<List<ComplianceReport>> getReports() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _reports;
  }

  Future<List<AuditEvidence>> getAuditEvidence() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _evidence;
  }

  Future<ComplianceOverview> getComplianceOverview() async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    // Calculate overall metrics
    int totalControls = 0;
    int compliantControls = 0;
    int nonCompliantControls = 0;
    int inProgressControls = 0;
    int notAssessedControls = 0;

    for (final framework in _frameworks) {
      for (final control in framework.controls) {
        totalControls++;
        switch (control.status) {
          case ComplianceStatus.compliant:
            compliantControls++;
            break;
          case ComplianceStatus.nonCompliant:
            nonCompliantControls++;
            break;
          case ComplianceStatus.inProgress:
            inProgressControls++;
            break;
          case ComplianceStatus.notAssessed:
            notAssessedControls++;
            break;
        }
      }
    }

    final overallScore = totalControls > 0 
        ? (compliantControls / totalControls) * 100 
        : 0.0;

    return ComplianceOverview(
      overallScore: overallScore,
      compliantControls: compliantControls,
      nonCompliantControls: nonCompliantControls,
      inProgressControls: inProgressControls,
      notAssessedControls: notAssessedControls,
      lastUpdated: DateTime.now(),
      gaps: _generateComplianceGaps(),
      recommendations: _generateComplianceRecommendations(),
    );
  }

  List<ComplianceGap> _generateComplianceGaps() {
    return [
      ComplianceGap(
        id: '1',
        title: 'Missing HIPAA Access Controls',
        description: 'Unique user identification not implemented for PHI access',
        frameworkId: '4',
        controlId: 'HIPAA-164.312',
        severity: 'High',
        identifiedAt: DateTime.now().subtract(const Duration(days: 10)),
        remediationPlan: 'Implement multi-factor authentication for PHI systems',
        targetDate: DateTime.now().add(const Duration(days: 30)),
      ),
      ComplianceGap(
        id: '2',
        title: 'Incomplete GDPR Data Subject Rights',
        description: 'Automated data subject request system not fully implemented',
        frameworkId: '1',
        controlId: 'GDPR-002',
        severity: 'Medium',
        identifiedAt: DateTime.now().subtract(const Duration(days: 15)),
        remediationPlan: 'Complete development of automated DSR portal',
        targetDate: DateTime.now().add(const Duration(days: 45)),
      ),
    ];
  }

  List<ComplianceRecommendation> _generateComplianceRecommendations() {
    return [
      ComplianceRecommendation(
        id: '1',
        title: 'Implement Continuous Compliance Monitoring',
        description: 'Deploy automated tools to continuously monitor compliance status',
        priority: 'High',
        category: 'Automation',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        assignedTo: 'IT Security Team',
        isImplemented: false,
      ),
      ComplianceRecommendation(
        id: '2',
        title: 'Enhance Evidence Collection Process',
        description: 'Implement automated evidence collection for audit purposes',
        priority: 'Medium',
        category: 'Process Improvement',
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        assignedTo: 'Compliance Team',
        isImplemented: false,
      ),
    ];
  }

  Future<ComplianceReport> generateReport(String frameworkId) async {
    developer.log('Generating compliance report for framework $frameworkId', name: 'Compliance');
    
    // Simulate report generation
    await Future.delayed(const Duration(seconds: 3));
    
    final framework = _frameworks.firstWhere((f) => f.id == frameworkId);
    final reportStatus = framework.status;
    final findings = _generateReportFindings([frameworkId]);
    
    final report = ComplianceReport(
      id: 'report_${Random().nextInt(1000)}',
      title: 'Compliance Report - ${framework.name}',
      description: 'Generated compliance report',
      type: 'Generated Report',
      generatedAt: DateTime.now(),
      generatedBy: 'System',
      frameworkIds: [frameworkId],
      findings: findings,
    );

    _reports.insert(0, report);
    
    return report;
  }

  Map<String, dynamic> _generateReportFindings(List<String> frameworkIds) {
    final random = Random();
    return {
      'overallScore': 75.0 + random.nextDouble() * 20,
      'frameworksAssessed': frameworkIds.length,
      'totalControls': frameworkIds.length * 25,
      'compliantControls': frameworkIds.length * 20,
      'criticalFindings': random.nextInt(5),
      'recommendations': random.nextInt(15) + 5,
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<void> updateControlStatus(
    String frameworkId,
    String controlId,
    ComplianceStatus newStatus,
    String assessedBy,
    String? notes,
  ) async {
    final frameworkIndex = _frameworks.indexWhere((f) => f.id == frameworkId);
    if (frameworkIndex == -1) return;

    final framework = _frameworks[frameworkIndex];
    final controlIndex = framework.controls.indexWhere((c) => c.id == controlId);
    if (controlIndex == -1) return;

    final control = framework.controls[controlIndex];
    final updatedControl = ComplianceControl(
      id: control.id,
      title: control.title,
      description: control.description,
      requirement: control.requirement,
      status: newStatus,
      lastAssessed: DateTime.now(),
      assessedBy: assessedBy,
      evidenceIds: control.evidenceIds,
      notes: notes ?? control.notes,
    );

    final updatedControls = [...framework.controls];
    updatedControls[controlIndex] = updatedControl;

    // Recalculate completed controls
    final completedCount = updatedControls
        .where((c) => c.status == ComplianceStatus.compliant)
        .length;

    final updatedFramework = ComplianceFramework(
      id: framework.id,
      name: framework.name,
      description: framework.description,
      type: framework.type,
      status: _calculateFrameworkStatus(updatedControls),
      totalControls: framework.totalControls,
      completedControls: completedCount,
      lastUpdated: DateTime.now(),
      controls: updatedControls,
    );

    _frameworks[frameworkIndex] = updatedFramework;
    
    developer.log('Control $controlId status updated to ${newStatus.name}', name: 'Compliance');
  }

  ComplianceStatus _calculateFrameworkStatus(List<ComplianceControl> controls) {
    if (controls.isEmpty) return ComplianceStatus.notAssessed;
    
    final compliantCount = controls.where((c) => c.status == ComplianceStatus.compliant).length;
    final nonCompliantCount = controls.where((c) => c.status == ComplianceStatus.nonCompliant).length;
    
    if (nonCompliantCount > 0) return ComplianceStatus.nonCompliant;
    if (compliantCount == controls.length) return ComplianceStatus.compliant;
    return ComplianceStatus.inProgress;
  }

  Future<AuditEvidence> addAuditEvidence(
    String title,
    String description,
    EvidenceType type,
    String controlId,
    String collectedBy,
    String? filePath,
  ) async {
    final evidence = AuditEvidence(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      type: type,
      controlId: controlId,
      collectedAt: DateTime.now(),
      collectedBy: collectedBy,
      isVerified: false,
      filePath: filePath,
      metadata: {'uploadedVia': 'admin_console'},
    );

    _evidence.insert(0, evidence);
    
    developer.log('New audit evidence added: $title', name: 'Compliance');
    
    return evidence;
  }

  Future<void> verifyEvidence(String evidenceId, String verifiedBy) async {
    final evidenceIndex = _evidence.indexWhere((e) => e.id == evidenceId);
    if (evidenceIndex == -1) return;

    final evidence = _evidence[evidenceIndex];
    final updatedEvidence = AuditEvidence(
      id: evidence.id,
      title: evidence.title,
      description: evidence.description,
      type: evidence.type,
      controlId: evidence.controlId,
      collectedAt: evidence.collectedAt,
      collectedBy: evidence.collectedBy,
      isVerified: true,
      filePath: evidence.filePath,
      metadata: {
        ...evidence.metadata,
        'verifiedBy': verifiedBy,
        'verifiedAt': DateTime.now().toIso8601String(),
      },
    );

    _evidence[evidenceIndex] = updatedEvidence;
    
    developer.log('Evidence $evidenceId verified by $verifiedBy', name: 'Compliance');
  }

  Future<List<DataRetentionPolicy>> getDataRetentionPolicies() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _retentionPolicies;
  }

  Future<DataRetentionPolicy> createDataRetentionPolicy(
    String name,
    String description,
    String dataCategory,
    int retentionPeriodDays,
    String retentionReason,
    List<String> applicableFrameworks,
  ) async {
    final policy = DataRetentionPolicy(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      dataCategory: dataCategory,
      retentionPeriodDays: retentionPeriodDays,
      retentionReason: retentionReason,
      isActive: true,
      createdAt: DateTime.now(),
      applicableFrameworks: applicableFrameworks,
    );

    _retentionPolicies.insert(0, policy);
    
    developer.log('New data retention policy created: $name', name: 'Compliance');
    
    return policy;
  }

  Future<Map<String, dynamic>> getComplianceMetrics() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final overview = await getComplianceOverview();
    
    return {
      'overallScore': overview.overallScore,
      'totalFrameworks': _frameworks.length,
      'compliantFrameworks': _frameworks.where((f) => f.status == ComplianceStatus.compliant).length,
      'totalControls': overview.compliantControls + overview.nonCompliantControls + 
                      overview.inProgressControls + overview.notAssessedControls,
      'compliantControls': overview.compliantControls,
      'totalEvidence': _evidence.length,
      'verifiedEvidence': _evidence.where((e) => e.isVerified).length,
      'totalReports': _reports.length,
      'recentReports': _reports.where((r) => 
        DateTime.now().difference(r.generatedAt).inDays <= 30).length,
    };
  }

  Future<List<ComplianceFramework>> searchFrameworks(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    return _frameworks.where((framework) =>
      framework.name.toLowerCase().contains(query.toLowerCase()) ||
      framework.description.toLowerCase().contains(query.toLowerCase()) ||
      framework.type.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  Future<List<AuditEvidence>> searchEvidence(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    return _evidence.where((evidence) =>
      evidence.title.toLowerCase().contains(query.toLowerCase()) ||
      evidence.description.toLowerCase().contains(query.toLowerCase()) ||
      evidence.controlId.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  Future<List<ComplianceReport>> getComplianceReports() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_reports);
  }

  Future<ComplianceReport> runChecks({Map<String, dynamic>? context}) async {
    final checks = <ComplianceCheckResult>[];

    // Example checks
    checks.add(_passwordPolicy(context));
    checks.add(_mfaEnforcement(context));
    checks.add(_dataEncryption(context));
    checks.add(_ipBlockingPolicy(context));

    final score = _computeScore(checks);
    final findings = {
      'score': score,
      'totalChecks': checks.length,
      'passed': checks.where((c) => c.passed).length,
      'failed': checks.where((c) => !c.passed).length,
      'results': checks.map((c) => c.toJson()).toList(),
    };

    return ComplianceReport(
      id: 'auto_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Automated Compliance Checks',
      description: 'Automated compliance assessment snapshot',
      type: 'Automated',
      generatedAt: DateTime.now(),
      generatedBy: 'System',
      frameworkIds: const [],
      findings: findings,
    );
  }

  ComplianceCheckResult _passwordPolicy(Map<String, dynamic>? ctx) {
    final enabled = (ctx?['passwordPolicyEnabled'] ?? true) == true;
    return ComplianceCheckResult(
      id: 'password_policy',
      name: 'Password Policy Enforcement',
      passed: enabled,
      severity: enabled ? 'low' : 'high',
      details: enabled ? null : 'Password policy is disabled',
    );
  }

  ComplianceCheckResult _mfaEnforcement(Map<String, dynamic>? ctx) {
    final required = (ctx?['mfaRequired'] ?? true) == true;
    return ComplianceCheckResult(
      id: 'mfa_required',
      name: 'MFA Required for High-Risk',
      passed: required,
      severity: required ? 'low' : 'high',
      details: required ? null : 'MFA is not enforced for high-risk scenarios',
    );
  }

  ComplianceCheckResult _dataEncryption(Map<String, dynamic>? ctx) {
    final atRest = (ctx?['encryptionAtRest'] ?? true) == true;
    final inTransit = (ctx?['encryptionInTransit'] ?? true) == true;
    final passed = atRest && inTransit;
    return ComplianceCheckResult(
      id: 'data_encryption',
      name: 'Data Encryption',
      passed: passed,
      severity: passed ? 'low' : 'high',
      details: passed ? null : 'Encryption at rest or in transit is disabled',
    );
  }

  ComplianceCheckResult _ipBlockingPolicy(Map<String, dynamic>? ctx) {
    final enabled = (ctx?['ipBlockingEnabled'] ?? true) == true;
    return ComplianceCheckResult(
      id: 'ip_blocking',
      name: 'IP Blocking Policy',
      passed: enabled,
      severity: enabled ? 'low' : 'medium',
      details: enabled ? null : 'IP Blocking is disabled',
    );
  }

  double _computeScore(List<ComplianceCheckResult> results) {
    if (results.isEmpty) return 0.0;
    final passed = results.where((r) => r.passed).length;
    return (passed / results.length) * 100.0;
  }
}
