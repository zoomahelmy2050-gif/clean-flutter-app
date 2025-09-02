import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum IncidentSeverity {
  low,
  medium,
  high,
  critical,
}

enum IncidentStatus {
  open,
  investigating,
  contained,
  resolved,
  closed,
}

enum IncidentType {
  securityBreach,
  dataLeak,
  unauthorizedAccess,
  malwareDetection,
  ddosAttack,
  phishingAttempt,
  systemCompromise,
  accountTakeover,
  privilegeEscalation,
  suspiciousActivity,
}

class IncidentPlaybook {
  final String id;
  final String name;
  final IncidentType type;
  final List<String> steps;
  final Map<String, dynamic> automatedActions;
  final Duration estimatedTime;
  final List<String> requiredRoles;

  IncidentPlaybook({
    required this.id,
    required this.name,
    required this.type,
    required this.steps,
    this.automatedActions = const {},
    required this.estimatedTime,
    this.requiredRoles = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'steps': steps,
    'automatedActions': automatedActions,
    'estimatedTime': estimatedTime.inMilliseconds,
    'requiredRoles': requiredRoles,
  };

  factory IncidentPlaybook.fromJson(Map<String, dynamic> json) {
    return IncidentPlaybook(
      id: json['id'],
      name: json['name'],
      type: IncidentType.values.firstWhere((e) => e.name == json['type']),
      steps: List<String>.from(json['steps']),
      automatedActions: Map<String, dynamic>.from(json['automatedActions'] ?? {}),
      estimatedTime: Duration(milliseconds: json['estimatedTime']),
      requiredRoles: List<String>.from(json['requiredRoles'] ?? []),
    );
  }
}

class IncidentStep {
  final String id;
  final String description;
  final bool completed;
  final DateTime? completedAt;
  final String? completedBy;
  final String? notes;
  final Duration? timeSpent;

  IncidentStep({
    required this.id,
    required this.description,
    this.completed = false,
    this.completedAt,
    this.completedBy,
    this.notes,
    this.timeSpent,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'completed': completed,
    'completedAt': completedAt?.toIso8601String(),
    'completedBy': completedBy,
    'notes': notes,
    'timeSpent': timeSpent?.inMilliseconds,
  };

  factory IncidentStep.fromJson(Map<String, dynamic> json) {
    return IncidentStep(
      id: json['id'],
      description: json['description'],
      completed: json['completed'] ?? false,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      completedBy: json['completedBy'],
      notes: json['notes'],
      timeSpent: json['timeSpent'] != null ? Duration(milliseconds: json['timeSpent']) : null,
    );
  }

  IncidentStep copyWith({
    bool? completed,
    DateTime? completedAt,
    String? completedBy,
    String? notes,
    Duration? timeSpent,
  }) {
    return IncidentStep(
      id: id,
      description: description,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      notes: notes ?? this.notes,
      timeSpent: timeSpent ?? this.timeSpent,
    );
  }
}

class SecurityIncident {
  final String id;
  final String title;
  final String description;
  final IncidentType type;
  final IncidentSeverity severity;
  final IncidentStatus status;
  final DateTime createdAt;
  final DateTime? detectedAt;
  final DateTime? resolvedAt;
  final String? assignedTo;
  final List<String> affectedSystems;
  final List<String> affectedUsers;
  final Map<String, dynamic> evidence;
  final List<IncidentStep> steps;
  final List<String> tags;
  final String? rootCause;
  final List<String> lessonsLearned;
  final Map<String, dynamic> metrics;

  SecurityIncident({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.severity,
    required this.status,
    required this.createdAt,
    this.detectedAt,
    this.resolvedAt,
    this.assignedTo,
    this.affectedSystems = const [],
    this.affectedUsers = const [],
    this.evidence = const {},
    this.steps = const [],
    this.tags = const [],
    this.rootCause,
    this.lessonsLearned = const [],
    this.metrics = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type.name,
    'severity': severity.name,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'detectedAt': detectedAt?.toIso8601String(),
    'resolvedAt': resolvedAt?.toIso8601String(),
    'assignedTo': assignedTo,
    'affectedSystems': affectedSystems,
    'affectedUsers': affectedUsers,
    'evidence': evidence,
    'steps': steps.map((s) => s.toJson()).toList(),
    'tags': tags,
    'rootCause': rootCause,
    'lessonsLearned': lessonsLearned,
    'metrics': metrics,
  };

  factory SecurityIncident.fromJson(Map<String, dynamic> json) {
    return SecurityIncident(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: IncidentType.values.firstWhere((e) => e.name == json['type']),
      severity: IncidentSeverity.values.firstWhere((e) => e.name == json['severity']),
      status: IncidentStatus.values.firstWhere((e) => e.name == json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      detectedAt: json['detectedAt'] != null ? DateTime.parse(json['detectedAt']) : null,
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
      assignedTo: json['assignedTo'],
      affectedSystems: List<String>.from(json['affectedSystems'] ?? []),
      affectedUsers: List<String>.from(json['affectedUsers'] ?? []),
      evidence: Map<String, dynamic>.from(json['evidence'] ?? {}),
      steps: (json['steps'] as List? ?? []).map((s) => IncidentStep.fromJson(s)).toList(),
      tags: List<String>.from(json['tags'] ?? []),
      rootCause: json['rootCause'],
      lessonsLearned: List<String>.from(json['lessonsLearned'] ?? []),
      metrics: Map<String, dynamic>.from(json['metrics'] ?? {}),
    );
  }

  SecurityIncident copyWith({
    String? title,
    String? description,
    IncidentSeverity? severity,
    IncidentStatus? status,
    DateTime? detectedAt,
    DateTime? resolvedAt,
    String? assignedTo,
    List<String>? affectedSystems,
    List<String>? affectedUsers,
    Map<String, dynamic>? evidence,
    List<IncidentStep>? steps,
    List<String>? tags,
    String? rootCause,
    List<String>? lessonsLearned,
    Map<String, dynamic>? metrics,
  }) {
    return SecurityIncident(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      createdAt: createdAt,
      detectedAt: detectedAt ?? this.detectedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      assignedTo: assignedTo ?? this.assignedTo,
      affectedSystems: affectedSystems ?? this.affectedSystems,
      affectedUsers: affectedUsers ?? this.affectedUsers,
      evidence: evidence ?? this.evidence,
      steps: steps ?? this.steps,
      tags: tags ?? this.tags,
      rootCause: rootCause ?? this.rootCause,
      lessonsLearned: lessonsLearned ?? this.lessonsLearned,
      metrics: metrics ?? this.metrics,
    );
  }
}

class IncidentResponseService extends ChangeNotifier {
  final List<SecurityIncident> _incidents = [];
  final List<IncidentPlaybook> _playbooks = [];
  Timer? _escalationTimer;
  
  static const String _incidentsKey = 'security_incidents';
  static const String _playbooksKey = 'incident_playbooks';

  // Getters
  List<SecurityIncident> get incidents => List.unmodifiable(_incidents);
  List<IncidentPlaybook> get playbooks => List.unmodifiable(_playbooks);
  
  List<SecurityIncident> get openIncidents => 
    _incidents.where((i) => i.status != IncidentStatus.closed).toList();
  
  List<SecurityIncident> get criticalIncidents => 
    _incidents.where((i) => i.severity == IncidentSeverity.critical && i.status != IncidentStatus.closed).toList();

  /// Initialize incident response service
  Future<void> initialize() async {
    await _loadIncidents();
    await _loadPlaybooks();
    await _initializeDefaultPlaybooks();
    await _startEscalationTimer();
  }

  /// Load incidents from storage
  Future<void> _loadIncidents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final incidentsJson = prefs.getStringList(_incidentsKey) ?? [];
      
      _incidents.clear();
      for (final incidentJson in incidentsJson) {
        final Map<String, dynamic> data = jsonDecode(incidentJson);
        _incidents.add(SecurityIncident.fromJson(data));
      }
    } catch (e) {
      debugPrint('Error loading incidents: $e');
    }
  }

  /// Save incidents to storage
  Future<void> _saveIncidents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final incidentsJson = _incidents.map((i) => jsonEncode(i.toJson())).toList();
      await prefs.setStringList(_incidentsKey, incidentsJson);
    } catch (e) {
      debugPrint('Error saving incidents: $e');
    }
  }

  /// Load playbooks from storage
  Future<void> _loadPlaybooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playbooksJson = prefs.getStringList(_playbooksKey) ?? [];
      
      _playbooks.clear();
      for (final playbookJson in playbooksJson) {
        final Map<String, dynamic> data = jsonDecode(playbookJson);
        _playbooks.add(IncidentPlaybook.fromJson(data));
      }
    } catch (e) {
      debugPrint('Error loading playbooks: $e');
    }
  }

  /// Save playbooks to storage
  Future<void> _savePlaybooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playbooksJson = _playbooks.map((p) => jsonEncode(p.toJson())).toList();
      await prefs.setStringList(_playbooksKey, playbooksJson);
    } catch (e) {
      debugPrint('Error saving playbooks: $e');
    }
  }

  /// Initialize default playbooks
  Future<void> _initializeDefaultPlaybooks() async {
    if (_playbooks.isNotEmpty) return;

    final defaultPlaybooks = [
      IncidentPlaybook(
        id: 'security_breach',
        name: 'Security Breach Response',
        type: IncidentType.securityBreach,
        steps: [
          'Identify and isolate affected systems',
          'Assess scope and impact',
          'Preserve evidence',
          'Notify stakeholders',
          'Implement containment measures',
          'Eradicate threat',
          'Recover systems',
          'Document lessons learned',
        ],
        estimatedTime: const Duration(hours: 4),
        requiredRoles: ['Security Admin', 'IT Admin'],
      ),
      IncidentPlaybook(
        id: 'data_leak',
        name: 'Data Leak Response',
        type: IncidentType.dataLeak,
        steps: [
          'Stop data exfiltration',
          'Identify leaked data',
          'Assess legal requirements',
          'Notify affected users',
          'Notify authorities if required',
          'Implement additional controls',
          'Monitor for misuse',
          'Update policies',
        ],
        estimatedTime: const Duration(hours: 6),
        requiredRoles: ['Security Admin', 'Legal', 'Communications'],
      ),
      IncidentPlaybook(
        id: 'ddos_attack',
        name: 'DDoS Attack Response',
        type: IncidentType.ddosAttack,
        steps: [
          'Activate DDoS protection',
          'Analyze attack patterns',
          'Implement rate limiting',
          'Contact ISP/CDN provider',
          'Monitor service availability',
          'Document attack details',
          'Review protection measures',
        ],
        estimatedTime: const Duration(hours: 2),
        requiredRoles: ['Network Admin', 'Security Admin'],
      ),
    ];

    _playbooks.addAll(defaultPlaybooks);
    await _savePlaybooks();
  }

  /// Start escalation timer
  Future<void> _startEscalationTimer() async {
    _escalationTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _checkForEscalation();
    });
  }

  /// Check for incident escalation
  void _checkForEscalation() {
    final now = DateTime.now();
    
    for (final incident in _incidents) {
      if (incident.status == IncidentStatus.closed) continue;
      
      final age = now.difference(incident.createdAt);
      bool shouldEscalate = false;
      
      // Escalation rules based on severity and age
      switch (incident.severity) {
        case IncidentSeverity.critical:
          shouldEscalate = age.inMinutes > 30;
          break;
        case IncidentSeverity.high:
          shouldEscalate = age.inHours > 2;
          break;
        case IncidentSeverity.medium:
          shouldEscalate = age.inHours > 8;
          break;
        case IncidentSeverity.low:
          shouldEscalate = age.inDays > 1;
          break;
      }
      
      if (shouldEscalate && !incident.tags.contains('escalated')) {
        _escalateIncident(incident.id);
      }
    }
  }

  /// Create new incident
  Future<String> createIncident({
    required String title,
    required String description,
    required IncidentType type,
    required IncidentSeverity severity,
    DateTime? detectedAt,
    List<String> affectedSystems = const [],
    List<String> affectedUsers = const [],
    Map<String, dynamic> evidence = const {},
    List<String> tags = const [],
  }) async {
    final incident = SecurityIncident(
      id: 'incident_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      type: type,
      severity: severity,
      status: IncidentStatus.open,
      createdAt: DateTime.now(),
      detectedAt: detectedAt,
      affectedSystems: affectedSystems,
      affectedUsers: affectedUsers,
      evidence: evidence,
      tags: tags,
      steps: _generateStepsFromPlaybook(type),
    );

    _incidents.insert(0, incident);
    await _saveIncidents();
    
    // Auto-execute immediate actions
    await _executeAutomatedActions(incident);
    
    notifyListeners();
    return incident.id;
  }

  /// Generate steps from playbook
  List<IncidentStep> _generateStepsFromPlaybook(IncidentType type) {
    final playbook = _playbooks.firstWhere(
      (p) => p.type == type,
      orElse: () => _playbooks.first,
    );
    
    return playbook.steps.asMap().entries.map((entry) {
      return IncidentStep(
        id: 'step_${entry.key}',
        description: entry.value,
      );
    }).toList();
  }

  /// Execute automated actions
  Future<void> _executeAutomatedActions(SecurityIncident incident) async {
    final playbook = _playbooks.firstWhere(
      (p) => p.type == incident.type,
      orElse: () => _playbooks.first,
    );
    
    for (final action in playbook.automatedActions.entries) {
      await _executeAction(action.key, action.value, incident);
    }
  }

  /// Execute specific action
  Future<void> _executeAction(String actionType, dynamic actionData, SecurityIncident incident) async {
    switch (actionType) {
      case 'notify_admin':
        debugPrint('Notifying admin about incident: ${incident.title}');
        break;
      case 'block_ip':
        debugPrint('Blocking IP addresses: $actionData');
        break;
      case 'isolate_system':
        debugPrint('Isolating systems: $actionData');
        break;
      case 'enable_monitoring':
        debugPrint('Enabling enhanced monitoring');
        break;
    }
  }

  /// Update incident
  Future<void> updateIncident(String incidentId, {
    String? title,
    String? description,
    IncidentSeverity? severity,
    IncidentStatus? status,
    DateTime? detectedAt,
    DateTime? resolvedAt,
    String? assignedTo,
    List<String>? affectedSystems,
    List<String>? affectedUsers,
    Map<String, dynamic>? evidence,
    List<String>? tags,
    String? rootCause,
    List<String>? lessonsLearned,
  }) async {
    final index = _incidents.indexWhere((i) => i.id == incidentId);
    if (index != -1) {
      _incidents[index] = _incidents[index].copyWith(
        title: title,
        description: description,
        severity: severity,
        status: status,
        detectedAt: detectedAt,
        resolvedAt: resolvedAt,
        assignedTo: assignedTo,
        affectedSystems: affectedSystems,
        affectedUsers: affectedUsers,
        evidence: evidence,
        tags: tags,
        rootCause: rootCause,
        lessonsLearned: lessonsLearned,
      );
      
      await _saveIncidents();
      notifyListeners();
    }
  }

  /// Complete incident step
  Future<void> completeStep(String incidentId, String stepId, {
    String? completedBy,
    String? notes,
    Duration? timeSpent,
  }) async {
    final incidentIndex = _incidents.indexWhere((i) => i.id == incidentId);
    if (incidentIndex != -1) {
      final incident = _incidents[incidentIndex];
      final stepIndex = incident.steps.indexWhere((s) => s.id == stepId);
      
      if (stepIndex != -1) {
        final updatedSteps = List<IncidentStep>.from(incident.steps);
        updatedSteps[stepIndex] = updatedSteps[stepIndex].copyWith(
          completed: true,
          completedAt: DateTime.now(),
          completedBy: completedBy,
          notes: notes,
          timeSpent: timeSpent,
        );
        
        _incidents[incidentIndex] = incident.copyWith(steps: updatedSteps);
        await _saveIncidents();
        notifyListeners();
      }
    }
  }

  /// Escalate incident
  Future<void> _escalateIncident(String incidentId) async {
    final index = _incidents.indexWhere((i) => i.id == incidentId);
    if (index != -1) {
      final incident = _incidents[index];
      final updatedTags = List<String>.from(incident.tags);
      updatedTags.add('escalated');
      
      // Increase severity if not already critical
      IncidentSeverity newSeverity = incident.severity;
      if (incident.severity != IncidentSeverity.critical) {
        final severityIndex = IncidentSeverity.values.indexOf(incident.severity);
        if (severityIndex < IncidentSeverity.values.length - 1) {
          newSeverity = IncidentSeverity.values[severityIndex + 1];
        }
      }
      
      _incidents[index] = incident.copyWith(
        severity: newSeverity,
        tags: updatedTags,
      );
      
      await _saveIncidents();
      notifyListeners();
      
      debugPrint('Incident ${incident.title} escalated to ${newSeverity.name}');
    }
  }

  /// Close incident
  Future<void> closeIncident(String incidentId, {
    required String rootCause,
    List<String> lessonsLearned = const [],
  }) async {
    await updateIncident(
      incidentId,
      status: IncidentStatus.closed,
      resolvedAt: DateTime.now(),
      rootCause: rootCause,
      lessonsLearned: lessonsLearned,
    );
  }

  /// Get incident statistics
  Map<String, dynamic> getIncidentStatistics() {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));
    final last7d = now.subtract(const Duration(days: 7));
    final last30d = now.subtract(const Duration(days: 30));
    
    final incidents24h = _incidents.where((i) => i.createdAt.isAfter(last24h)).length;
    final incidents7d = _incidents.where((i) => i.createdAt.isAfter(last7d)).length;
    final incidents30d = _incidents.where((i) => i.createdAt.isAfter(last30d)).length;
    
    final openIncidents = _incidents.where((i) => i.status != IncidentStatus.closed).length;
    final criticalOpen = _incidents.where((i) => 
      i.severity == IncidentSeverity.critical && i.status != IncidentStatus.closed
    ).length;
    
    return {
      'total_incidents': _incidents.length,
      'open_incidents': openIncidents,
      'critical_open': criticalOpen,
      'incidents_24h': incidents24h,
      'incidents_7d': incidents7d,
      'incidents_30d': incidents30d,
      'by_severity': _getIncidentsBySeverity(),
      'by_type': _getIncidentsByType(),
      'by_status': _getIncidentsByStatus(),
      'average_resolution_time': _getAverageResolutionTime(),
      'escalation_rate': _getEscalationRate(),
    };
  }

  /// Get incidents by severity
  Map<String, int> _getIncidentsBySeverity() {
    final Map<String, int> bySeverity = {};
    for (final severity in IncidentSeverity.values) {
      bySeverity[severity.name] = _incidents.where((i) => i.severity == severity).length;
    }
    return bySeverity;
  }

  /// Get incidents by type
  Map<String, int> _getIncidentsByType() {
    final Map<String, int> byType = {};
    for (final incident in _incidents) {
      byType[incident.type.name] = (byType[incident.type.name] ?? 0) + 1;
    }
    return byType;
  }

  /// Get incidents by status
  Map<String, int> _getIncidentsByStatus() {
    final Map<String, int> byStatus = {};
    for (final status in IncidentStatus.values) {
      byStatus[status.name] = _incidents.where((i) => i.status == status).length;
    }
    return byStatus;
  }

  /// Get average resolution time
  Duration _getAverageResolutionTime() {
    final resolvedIncidents = _incidents.where((i) => 
      i.status == IncidentStatus.closed && i.resolvedAt != null
    ).toList();
    
    if (resolvedIncidents.isEmpty) return Duration.zero;
    
    final totalTime = resolvedIncidents.fold<Duration>(
      Duration.zero,
      (sum, incident) => sum + incident.resolvedAt!.difference(incident.createdAt),
    );
    
    return Duration(milliseconds: totalTime.inMilliseconds ~/ resolvedIncidents.length);
  }

  /// Get escalation rate
  double _getEscalationRate() {
    if (_incidents.isEmpty) return 0.0;
    final escalated = _incidents.where((i) => i.tags.contains('escalated')).length;
    return escalated / _incidents.length;
  }

  /// Export incident data
  Map<String, dynamic> exportIncidentData() {
    return {
      'incidents': _incidents.map((i) => i.toJson()).toList(),
      'playbooks': _playbooks.map((p) => p.toJson()).toList(),
      'statistics': getIncidentStatistics(),
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  void dispose() {
    _escalationTimer?.cancel();
    super.dispose();
  }
}
