enum ComplianceStatus { compliant, nonCompliant, inProgress, notAssessed }
enum EvidenceType { document, screenshot, log, certificate }

class ComplianceFramework {
  final String id;
  final String name;
  final String description;
  final String type;
  final ComplianceStatus status;
  final int totalControls;
  final int completedControls;
  final DateTime lastUpdated;
  final List<ComplianceControl> controls;

  ComplianceFramework({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.status,
    required this.totalControls,
    required this.completedControls,
    required this.lastUpdated,
    this.controls = const [],
  });

  factory ComplianceFramework.fromJson(Map<String, dynamic> json) {
    return ComplianceFramework(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: json['type'],
      status: ComplianceStatus.values.byName(json['status']),
      totalControls: json['totalControls'],
      completedControls: json['completedControls'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
      controls: (json['controls'] as List?)
          ?.map((e) => ComplianceControl.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'status': status.name,
      'totalControls': totalControls,
      'completedControls': completedControls,
      'lastUpdated': lastUpdated.toIso8601String(),
      'controls': controls.map((e) => e.toJson()).toList(),
    };
  }
}

class ComplianceControl {
  final String id;
  final String title;
  final String description;
  final String requirement;
  final ComplianceStatus status;
  final DateTime? lastAssessed;
  final String? assessedBy;
  final List<String> evidenceIds;
  final String? notes;

  ComplianceControl({
    required this.id,
    required this.title,
    required this.description,
    required this.requirement,
    required this.status,
    this.lastAssessed,
    this.assessedBy,
    this.evidenceIds = const [],
    this.notes,
  });

  factory ComplianceControl.fromJson(Map<String, dynamic> json) {
    return ComplianceControl(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      requirement: json['requirement'],
      status: ComplianceStatus.values.byName(json['status']),
      lastAssessed: json['lastAssessed'] != null ? DateTime.parse(json['lastAssessed']) : null,
      assessedBy: json['assessedBy'],
      evidenceIds: List<String>.from(json['evidenceIds'] ?? []),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'requirement': requirement,
      'status': status.name,
      'lastAssessed': lastAssessed?.toIso8601String(),
      'assessedBy': assessedBy,
      'evidenceIds': evidenceIds,
      'notes': notes,
    };
  }
}

class ComplianceReport {
  final String id;
  final String title;
  final String description;
  final String type;
  final DateTime generatedAt;
  final String generatedBy;
  final List<String> frameworkIds;
  final Map<String, dynamic> findings;
  final String? filePath;

  ComplianceReport({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.generatedAt,
    required this.generatedBy,
    this.frameworkIds = const [],
    this.findings = const {},
    this.filePath,
  });

  factory ComplianceReport.fromJson(Map<String, dynamic> json) {
    return ComplianceReport(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      generatedAt: DateTime.parse(json['generatedAt']),
      generatedBy: json['generatedBy'],
      frameworkIds: List<String>.from(json['frameworkIds'] ?? []),
      findings: json['findings'] ?? {},
      filePath: json['filePath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'generatedAt': generatedAt.toIso8601String(),
      'generatedBy': generatedBy,
      'frameworkIds': frameworkIds,
      'findings': findings,
      'filePath': filePath,
    };
  }
}

class AuditEvidence {
  final String id;
  final String title;
  final String description;
  final EvidenceType type;
  final String controlId;
  final DateTime collectedAt;
  final String collectedBy;
  final bool isVerified;
  final String? filePath;
  final Map<String, dynamic> metadata;

  AuditEvidence({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.controlId,
    required this.collectedAt,
    required this.collectedBy,
    required this.isVerified,
    this.filePath,
    this.metadata = const {},
  });

  factory AuditEvidence.fromJson(Map<String, dynamic> json) {
    return AuditEvidence(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: EvidenceType.values.byName(json['type']),
      controlId: json['controlId'],
      collectedAt: DateTime.parse(json['collectedAt']),
      collectedBy: json['collectedBy'],
      isVerified: json['isVerified'],
      filePath: json['filePath'],
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'controlId': controlId,
      'collectedAt': collectedAt.toIso8601String(),
      'collectedBy': collectedBy,
      'isVerified': isVerified,
      'filePath': filePath,
      'metadata': metadata,
    };
  }
}

class ComplianceOverview {
  final double overallScore;
  final int compliantControls;
  final int nonCompliantControls;
  final int inProgressControls;
  final int notAssessedControls;
  final DateTime lastUpdated;
  final List<ComplianceGap> gaps;
  final List<ComplianceRecommendation> recommendations;

  ComplianceOverview({
    required this.overallScore,
    required this.compliantControls,
    required this.nonCompliantControls,
    required this.inProgressControls,
    required this.notAssessedControls,
    required this.lastUpdated,
    this.gaps = const [],
    this.recommendations = const [],
  });

  factory ComplianceOverview.fromJson(Map<String, dynamic> json) {
    return ComplianceOverview(
      overallScore: json['overallScore'].toDouble(),
      compliantControls: json['compliantControls'],
      nonCompliantControls: json['nonCompliantControls'],
      inProgressControls: json['inProgressControls'],
      notAssessedControls: json['notAssessedControls'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
      gaps: (json['gaps'] as List?)
          ?.map((e) => ComplianceGap.fromJson(e))
          .toList() ?? [],
      recommendations: (json['recommendations'] as List?)
          ?.map((e) => ComplianceRecommendation.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallScore': overallScore,
      'compliantControls': compliantControls,
      'nonCompliantControls': nonCompliantControls,
      'inProgressControls': inProgressControls,
      'notAssessedControls': notAssessedControls,
      'lastUpdated': lastUpdated.toIso8601String(),
      'gaps': gaps.map((e) => e.toJson()).toList(),
      'recommendations': recommendations.map((e) => e.toJson()).toList(),
    };
  }
}

class ComplianceGap {
  final String id;
  final String title;
  final String description;
  final String frameworkId;
  final String controlId;
  final String severity;
  final DateTime identifiedAt;
  final String? remediationPlan;
  final DateTime? targetDate;

  ComplianceGap({
    required this.id,
    required this.title,
    required this.description,
    required this.frameworkId,
    required this.controlId,
    required this.severity,
    required this.identifiedAt,
    this.remediationPlan,
    this.targetDate,
  });

  factory ComplianceGap.fromJson(Map<String, dynamic> json) {
    return ComplianceGap(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      frameworkId: json['frameworkId'],
      controlId: json['controlId'],
      severity: json['severity'],
      identifiedAt: DateTime.parse(json['identifiedAt']),
      remediationPlan: json['remediationPlan'],
      targetDate: json['targetDate'] != null ? DateTime.parse(json['targetDate']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'frameworkId': frameworkId,
      'controlId': controlId,
      'severity': severity,
      'identifiedAt': identifiedAt.toIso8601String(),
      'remediationPlan': remediationPlan,
      'targetDate': targetDate?.toIso8601String(),
    };
  }
}

class ComplianceRecommendation {
  final String id;
  final String title;
  final String description;
  final String priority;
  final String category;
  final DateTime createdAt;
  final String? assignedTo;
  final bool isImplemented;

  ComplianceRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
    required this.createdAt,
    this.assignedTo,
    required this.isImplemented,
  });

  factory ComplianceRecommendation.fromJson(Map<String, dynamic> json) {
    return ComplianceRecommendation(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      priority: json['priority'],
      category: json['category'],
      createdAt: DateTime.parse(json['createdAt']),
      assignedTo: json['assignedTo'],
      isImplemented: json['isImplemented'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'assignedTo': assignedTo,
      'isImplemented': isImplemented,
    };
  }
}

class DataRetentionPolicy {
  final String id;
  final String name;
  final String description;
  final String dataCategory;
  final int retentionPeriodDays;
  final String retentionReason;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastReviewed;
  final List<String> applicableFrameworks;

  DataRetentionPolicy({
    required this.id,
    required this.name,
    required this.description,
    required this.dataCategory,
    required this.retentionPeriodDays,
    required this.retentionReason,
    required this.isActive,
    required this.createdAt,
    this.lastReviewed,
    this.applicableFrameworks = const [],
  });

  factory DataRetentionPolicy.fromJson(Map<String, dynamic> json) {
    return DataRetentionPolicy(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      dataCategory: json['dataCategory'],
      retentionPeriodDays: json['retentionPeriodDays'],
      retentionReason: json['retentionReason'],
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
      lastReviewed: json['lastReviewed'] != null ? DateTime.parse(json['lastReviewed']) : null,
      applicableFrameworks: List<String>.from(json['applicableFrameworks'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'dataCategory': dataCategory,
      'retentionPeriodDays': retentionPeriodDays,
      'retentionReason': retentionReason,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastReviewed': lastReviewed?.toIso8601String(),
      'applicableFrameworks': applicableFrameworks,
    };
  }
}

enum AlertSeverity { low, medium, high, critical }

enum AlertStatus { open, inProgress, resolved, closed }

class ComplianceAlert {
  final String alertId;
  final String deviceId;
  final String policyId;
  final List<String> violations;
  final DateTime timestamp;
  final AlertSeverity severity;
  AlertStatus status;

  ComplianceAlert({
    required this.alertId,
    required this.deviceId,
    required this.policyId,
    required this.violations,
    required this.timestamp,
    this.severity = AlertSeverity.medium,
    this.status = AlertStatus.open,
  });
}
