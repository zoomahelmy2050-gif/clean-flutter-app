import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum DrillType {
  ransomware,
  phishing,
  dataExfiltration,
  ddos,
  insiderThreat,
  supplyChain,
  zeroDay,
  apt,
}

enum DrillStatus {
  notStarted,
  inProgress,
  completed,
  failed,
}

class SecurityDrill {
  final String id;
  final DrillType type;
  final String name;
  final String description;
  final DateTime scheduledTime;
  final int durationMinutes;
  DrillStatus status;
  final List<String> playbooks;
  final Map<String, dynamic> metrics;
  DateTime? startTime;
  DateTime? endTime;
  double? performanceScore;
  final List<DrillEvent> events;

  SecurityDrill({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.scheduledTime,
    required this.durationMinutes,
    this.status = DrillStatus.notStarted,
    required this.playbooks,
    Map<String, dynamic>? metrics,
    this.startTime,
    this.endTime,
    this.performanceScore,
    List<DrillEvent>? events,
  }) : metrics = metrics ?? {},
        events = events ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'name': name,
    'description': description,
    'scheduledTime': scheduledTime.toIso8601String(),
    'durationMinutes': durationMinutes,
    'status': status.toString(),
    'playbooks': playbooks,
    'metrics': metrics,
    'startTime': startTime?.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'performanceScore': performanceScore,
    'events': events.map((e) => e.toJson()).toList(),
  };
}

class DrillEvent {
  final DateTime timestamp;
  final String type;
  final String description;
  final String severity;
  final Map<String, dynamic> data;

  DrillEvent({
    required this.timestamp,
    required this.type,
    required this.description,
    required this.severity,
    Map<String, dynamic>? data,
  }) : data = data ?? {};

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'type': type,
    'description': description,
    'severity': severity,
    'data': data,
  };
}

class ThreatPattern {
  final String id;
  final String name;
  final String description;
  final String attackVector;
  final List<String> indicators;
  final Map<String, dynamic> tactics;
  final double severity;

  ThreatPattern({
    required this.id,
    required this.name,
    required this.description,
    required this.attackVector,
    required this.indicators,
    required this.tactics,
    required this.severity,
  });
}

class SecurityDrillsService extends ChangeNotifier {
  final List<SecurityDrill> _drills = [];
  final List<ThreatPattern> _threatPatterns = [];
  SecurityDrill? _activeDrill;
  Timer? _drillTimer;
  Timer? _eventTimer;
  final Random _random = Random();
  
  // DDoS Simulation
  int _currentRequestRate = 100;
  int _peakRequestRate = 100;
  bool _ddosActive = false;
  Timer? _ddosTimer;
  
  List<SecurityDrill> get drills => _drills;
  List<SecurityDrill> get completedDrills => _drills.where((d) => d.status == DrillStatus.completed).toList();
  SecurityDrill? get activeDrill => _activeDrill;
  bool get isDrillActive => _activeDrill != null;
  int get currentRequestRate => _currentRequestRate;
  int get peakRequestRate => _peakRequestRate;
  bool get ddosActive => _ddosActive;

  SecurityDrillsService() {
    _initializeThreatPatterns();
    _loadDrills();
  }

  void _initializeThreatPatterns() {
    _threatPatterns.addAll([
      ThreatPattern(
        id: 'apt-29',
        name: 'Cozy Bear Activity',
        description: 'Advanced persistent threat with focus on espionage',
        attackVector: 'Spear phishing and supply chain compromise',
        indicators: ['Unusual PowerShell activity', 'Suspicious DNS queries', 'Lateral movement patterns'],
        tactics: {'initial_access': 'phishing', 'persistence': 'scheduled_tasks', 'exfiltration': 'c2_channel'},
        severity: 0.95,
      ),
      ThreatPattern(
        id: 'ransomware-lockbit',
        name: 'LockBit 3.0 Simulation',
        description: 'Ransomware attack simulation with encryption behaviors',
        attackVector: 'RDP brute force and vulnerable services',
        indicators: ['Mass file encryption', 'Shadow copy deletion', 'Ransom note creation'],
        tactics: {'impact': 'data_encryption', 'defense_evasion': 'indicator_removal', 'collection': 'data_staging'},
        severity: 0.9,
      ),
      ThreatPattern(
        id: 'insider-exfil',
        name: 'Insider Data Exfiltration',
        description: 'Malicious insider stealing sensitive data',
        attackVector: 'Legitimate credentials abuse',
        indicators: ['Large data transfers', 'After-hours access', 'Unusual file access patterns'],
        tactics: {'collection': 'data_from_local', 'exfiltration': 'web_service', 'impact': 'data_theft'},
        severity: 0.8,
      ),
    ]);
  }

  Future<void> _loadDrills() async {
    final prefs = await SharedPreferences.getInstance();
    final drillsJson = prefs.getString('security_drills');
    if (drillsJson != null) {
      json.decode(drillsJson) as List;
      _drills.clear();
      // Note: Simplified loading - in production, properly deserialize
      notifyListeners();
    }
  }

  Future<void> _saveDrills() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('security_drills', json.encode(_drills.map((d) => d.toJson()).toList()));
  }

  void scheduleDrill({
    required DrillType type,
    required String name,
    required String description,
    required DateTime scheduledTime,
    required int durationMinutes,
    required List<String> playbooks,
  }) {
    final drill = SecurityDrill(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      name: name,
      description: description,
      scheduledTime: scheduledTime,
      durationMinutes: durationMinutes,
      playbooks: playbooks,
    );
    
    _drills.add(drill);
    _saveDrills();
    notifyListeners();
    
    // Schedule automatic start
    final delay = scheduledTime.difference(DateTime.now());
    if (delay.isNegative) {
      startDrill(drill.id);
    } else {
      Timer(delay, () => startDrill(drill.id));
    }
  }

  List<SecurityDrill> filterDrills(Map<String, dynamic> filter) {
    return _drills
        .where((d) => 
          (filter['type'] == null || d.type == filter['type']) &&
          (filter['status'] == null || d.status == filter['status']) &&
          (filter['startDate'] == null || d.scheduledTime.isAfter(filter['startDate'])) &&
          (filter['endDate'] == null || d.scheduledTime.isBefore(filter['endDate']))
        )
        .toList();
  }

  void startDrill(String drillId) {
    final drill = _drills.firstWhere((d) => d.id == drillId);
    if (_activeDrill != null) return;
    
    drill.status = DrillStatus.inProgress;
    drill.startTime = DateTime.now();
    _activeDrill = drill;
    
    // Generate initial events
    _generateDrillEvents(drill);
    
    // Set timer for drill completion
    _drillTimer = Timer(Duration(minutes: drill.durationMinutes), () {
      completeDrill(drillId);
    });
    
    // Start event generation
    _eventTimer = Timer.periodic(Duration(seconds: 10), (_) {
      if (_activeDrill?.id == drillId) {
        _generateRandomEvent(drill);
      }
    });
    
    _saveDrills();
    notifyListeners();
  }

  void _generateDrillEvents(SecurityDrill drill) {
    final pattern = _threatPatterns.firstWhere(
      (p) => p.name.toLowerCase().contains(drill.type.toString().split('.').last),
      orElse: () => _threatPatterns.first,
    );
    
    // Initial detection
    drill.events.add(DrillEvent(
      timestamp: DateTime.now(),
      type: 'detection',
      description: 'Threat activity detected: ${pattern.attackVector}',
      severity: 'high',
      data: {'pattern_id': pattern.id, 'indicators': pattern.indicators},
    ));
    
    // Playbook activation
    for (final playbook in drill.playbooks) {
      drill.events.add(DrillEvent(
        timestamp: DateTime.now().add(Duration(seconds: _random.nextInt(30))),
        type: 'playbook_activated',
        description: 'Automated response initiated: $playbook',
        severity: 'info',
        data: {'playbook': playbook, 'auto_execute': true},
      ));
    }
  }

  void _generateRandomEvent(SecurityDrill drill) {
    final eventTypes = ['alert', 'action_taken', 'escalation', 'containment', 'investigation'];
    final severities = ['low', 'medium', 'high', 'critical'];
    
    drill.events.add(DrillEvent(
      timestamp: DateTime.now(),
      type: eventTypes[_random.nextInt(eventTypes.length)],
      description: _generateEventDescription(drill.type),
      severity: severities[_random.nextInt(severities.length)],
      data: {
        'response_time': '${_random.nextInt(60)} seconds',
        'affected_systems': _random.nextInt(10) + 1,
      },
    ));
    
    notifyListeners();
  }

  String _generateEventDescription(DrillType type) {
    final descriptions = {
      DrillType.ransomware: [
        'File encryption detected on endpoint',
        'Ransomware kill switch activated',
        'Backup systems isolated',
        'Decryption keys secured',
      ],
      DrillType.phishing: [
        'Phishing email quarantined',
        'User credentials reset',
        'Email gateway rules updated',
        'User awareness notification sent',
      ],
      DrillType.ddos: [
        'Traffic spike detected',
        'Rate limiting applied',
        'CDN failover initiated',
        'Attack pattern identified',
      ],
      DrillType.dataExfiltration: [
        'Unusual data transfer blocked',
        'DLP policy triggered',
        'User session terminated',
        'Data classification scan initiated',
      ],
    };
    
    final list = descriptions[type] ?? ['Security event processed'];
    return list[_random.nextInt(list.length)];
  }

  void completeDrill(String drillId) {
    final drill = _drills.firstWhere((d) => d.id == drillId);
    
    drill.status = DrillStatus.completed;
    drill.endTime = DateTime.now();
    drill.performanceScore = _calculatePerformanceScore(drill);
    
    // Update metrics
    drill.metrics['total_events'] = drill.events.length;
    drill.metrics['response_time'] = '${_random.nextInt(300) + 60} seconds';
    drill.metrics['systems_affected'] = _random.nextInt(50) + 10;
    drill.metrics['data_protected'] = '${_random.nextInt(900) + 100} GB';
    
    _activeDrill = null;
    _drillTimer?.cancel();
    _eventTimer?.cancel();
    
    _saveDrills();
    notifyListeners();
  }

  double _calculatePerformanceScore(SecurityDrill drill) {
    // Simulated scoring based on response times and actions taken
    double score = 0.5;
    
    // Factor in response time
    if (drill.events.any((e) => e.type == 'playbook_activated')) {
      score += 0.2;
    }
    
    // Factor in containment
    if (drill.events.any((e) => e.type == 'containment')) {
      score += 0.15;
    }
    
    // Factor in investigation
    if (drill.events.any((e) => e.type == 'investigation')) {
      score += 0.15;
    }
    
    // Add some randomness
    score += _random.nextDouble() * 0.1;
    
    return score.clamp(0.0, 1.0);
  }

  void cancelDrill(String drillId) {
    _drills.removeWhere((d) => d.id == drillId);
    _saveDrills();
    notifyListeners();
  }

  // Threat Hunter Console Testing
  void testThreatHunterQuery(String query) {
    // Simulate threat hunting query results
    final results = <Map<String, dynamic>>[];
    
    if (query.toLowerCase().contains('suspicious')) {
      results.add({
        'timestamp': DateTime.now().subtract(Duration(hours: 2)),
        'type': 'process_creation',
        'description': 'Suspicious PowerShell execution detected',
        'host': 'WORKSTATION-042',
        'user': 'john.doe',
        'severity': 'high',
      });
    }
    
    if (query.toLowerCase().contains('russia') || query.toLowerCase().contains('login')) {
      results.add({
        'timestamp': DateTime.now().subtract(Duration(days: 1)),
        'type': 'authentication',
        'description': 'Multiple failed login attempts from Russian IP',
        'source_ip': '185.220.101.45',
        'target_user': 'admin',
        'severity': 'medium',
      });
    }
    
    notifyListeners();
  }

  // DDoS Simulation
  void startDDoSSimulation() {
    if (_ddosActive) return;
    
    _ddosActive = true;
    _currentRequestRate = 100;
    _peakRequestRate = 100;
    
    _ddosTimer = Timer.periodic(Duration(seconds: 1), (_) {
      // Simulate increasing attack
      if (_currentRequestRate < 10000) {
        _currentRequestRate = (_currentRequestRate * 1.2).round();
        if (_currentRequestRate > _peakRequestRate) {
          _peakRequestRate = _currentRequestRate;
        }
      } else {
        // Simulate mitigation
        _currentRequestRate = (_currentRequestRate * 0.95).round();
      }
      
      notifyListeners();
    });
    
    // Auto-stop after 2 minutes
    Timer(Duration(minutes: 2), stopDDoSSimulation);
  }

  void stopDDoSSimulation() {
    _ddosActive = false;
    _ddosTimer?.cancel();
    _currentRequestRate = 100;
    notifyListeners();
  }

  // Rate Limiting Test
  Map<String, dynamic> testRateLimiting() {
    return {
      'endpoint': '/api/login',
      'current_rate': '${_random.nextInt(900) + 100} req/min',
      'limit': '1000 req/min',
      'blocked_ips': _random.nextInt(50),
      'throttled_requests': _random.nextInt(200),
      'status': 'active',
    };
  }

  // Incident Response Workflow Validation
  Map<String, dynamic> validateIncidentWorkflow(String incidentType) {
    final steps = <String, bool>{};
    final workflowSteps = [
      'Detection',
      'Triage',
      'Containment',
      'Eradication',
      'Recovery',
      'Lessons Learned',
    ];
    
    for (final step in workflowSteps) {
      steps[step] = _random.nextBool() || _random.nextBool(); // 75% chance of completion
    }
    
    return {
      'incident_type': incidentType,
      'workflow_steps': steps,
      'completion_rate': steps.values.where((v) => v).length / steps.length,
      'estimated_time': '${_random.nextInt(120) + 30} minutes',
      'recommendations': _getWorkflowRecommendations(steps),
    };
  }

  List<String> _getWorkflowRecommendations(Map<String, bool> steps) {
    final recommendations = <String>[];
    
    if (!steps['Detection']!) {
      recommendations.add('Improve detection capabilities with enhanced monitoring');
    }
    if (!steps['Containment']!) {
      recommendations.add('Implement automated containment procedures');
    }
    if (!steps['Recovery']!) {
      recommendations.add('Develop comprehensive recovery playbooks');
    }
    
    return recommendations;
  }

  @override
  void dispose() {
    _drillTimer?.cancel();
    _eventTimer?.cancel();
    _ddosTimer?.cancel();
    super.dispose();
  }
}
