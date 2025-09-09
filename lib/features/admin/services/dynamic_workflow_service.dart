import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class DynamicWorkflowStep {
  final String id;
  final String name;
  final String action;
  final Map<String, dynamic> parameters;
  final List<Map<String, dynamic>> conditions; // simple key/op/value
  final String? onSuccess;
  final String? onFailure;

  DynamicWorkflowStep({
    required this.id,
    required this.name,
    required this.action,
    Map<String, dynamic>? parameters,
    List<Map<String, dynamic>>? conditions,
    this.onSuccess,
    this.onFailure,
  })  : parameters = parameters ?? {},
        conditions = conditions ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'action': action,
    'parameters': parameters,
    'conditions': conditions,
    'onSuccess': onSuccess,
    'onFailure': onFailure,
  };

  factory DynamicWorkflowStep.fromJson(Map<String, dynamic> json) => DynamicWorkflowStep(
    id: json['id'],
    name: json['name'],
    action: json['action'],
    parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
    conditions: List<Map<String, dynamic>>.from(json['conditions'] ?? []),
    onSuccess: json['onSuccess'],
    onFailure: json['onFailure'],
  );
}

class DynamicWorkflow {
  final String id;
  final String name;
  final String description;
  final List<DynamicWorkflowStep> steps;
  final Map<String, dynamic> triggers; // e.g., anomaly, manual, schedule
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  DynamicWorkflow({
    required this.id,
    required this.name,
    required this.description,
    required this.steps,
    Map<String, dynamic>? triggers,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : triggers = triggers ?? {},
        metadata = metadata ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'steps': steps.map((s) => s.toJson()).toList(),
    'triggers': triggers,
    'metadata': metadata,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory DynamicWorkflow.fromJson(Map<String, dynamic> json) => DynamicWorkflow(
    id: json['id'],
    name: json['name'],
    description: json['description'] ?? '',
    steps: (json['steps'] as List<dynamic>? ?? []).map((e) => DynamicWorkflowStep.fromJson(e)).toList(),
    triggers: Map<String, dynamic>.from(json['triggers'] ?? {}),
    metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
  );
}

class DynamicWorkflowService with ChangeNotifier {
  static const String _storageKey = 'dynamic_workflows_v1';

  final SharedPreferences _prefs;
  final Map<String, DynamicWorkflow> _workflows = {};

  DynamicWorkflowService(this._prefs) {
    _load();
  }

  List<DynamicWorkflow> list({int limit = 100}) => _workflows.values.take(limit).toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  DynamicWorkflow? getById(String id) => _workflows[id];

  Future<bool> create(DynamicWorkflow workflow) async {
    if (_workflows.containsKey(workflow.id)) return false;
    if (!_validate(workflow)) return false;
    _workflows[workflow.id] = workflow;
    final ok = await _save();
    if (ok) notifyListeners();
    return ok;
  }

  Future<bool> update(DynamicWorkflow workflow) async {
    if (!_workflows.containsKey(workflow.id)) return false;
    if (!_validate(workflow)) return false;
    _workflows[workflow.id] = workflow;
    final ok = await _save();
    if (ok) notifyListeners();
    return ok;
  }

  Future<bool> remove(String id) async {
    if (!_workflows.containsKey(id)) return false;
    _workflows.remove(id);
    final ok = await _save();
    if (ok) notifyListeners();
    return ok;
  }

  bool _validate(DynamicWorkflow wf) {
    if (wf.name.trim().isEmpty) return false;
    if (wf.steps.isEmpty) return false;
    final ids = <String>{};
    for (final s in wf.steps) {
      if (s.id.trim().isEmpty || s.name.trim().isEmpty || s.action.trim().isEmpty) return false;
      if (!ids.add(s.id)) return false; // duplicate step id
    }
    return true;
  }

  Future<Map<String, dynamic>> execute(String id, {Map<String, dynamic>? context}) async {
    final wf = _workflows[id];
    if (wf == null) {
      return {'success': false, 'error': 'Workflow not found'};
    }
    final ctx = Map<String, dynamic>.from(context ?? {});
    final visited = <String>{};
    String? currentId = wf.steps.first.id;
    final log = <Map<String, dynamic>>[];
    final bool isDryRun = ctx['dryRun'] == true;
    final bool isCanary = ctx['canary'] == true;
    final int canaryPercent = (ctx['canaryPercent'] is int) ? ctx['canaryPercent'] as int : 0;

    while (currentId != null) {
      if (!visited.add(currentId)) {
        return {'success': false, 'error': 'Cycle detected at $currentId', 'log': log};
      }
      final step = wf.steps.firstWhere((s) => s.id == currentId, orElse: () => wf.steps.first);
      final conditionsPass = _evaluateConditions(step.conditions, ctx);
      if (!conditionsPass) {
        log.add({'step': step.id, 'skipped': true});
        currentId = step.onFailure; // treat unmet conditions as failure path
        continue;
      }
      // Simulate execution
      final exec = _simulateAction(step.action, step.parameters, ctx);
      log.add({'step': step.id, 'action': step.action, 'result': exec});
      // Merge any outputs
      if (exec['output'] is Map<String, dynamic>) {
        ctx.addAll(exec['output']);
      }
      currentId = exec['success'] == true ? step.onSuccess : step.onFailure;
    }

    return {
      'success': true,
      'log': log,
      'context': ctx,
      if (isDryRun) 'mode': 'dryRun',
      if (isCanary) 'canary': {'percent': canaryPercent},
    };
  }

  Map<String, dynamic> preflight(String id) {
    final wf = _workflows[id];
    if (wf == null) return {'ok': false, 'error': 'Workflow not found'};

    final warnings = <String>[];
    final stepIds = wf.steps.map((s) => s.id).toSet();

    // Check transitions point to valid steps
    for (final s in wf.steps) {
      if (s.onSuccess != null && !stepIds.contains(s.onSuccess)) {
        warnings.add('Step ${s.id} onSuccess → ${s.onSuccess} not found');
      }
      if (s.onFailure != null && !stepIds.contains(s.onFailure)) {
        warnings.add('Step ${s.id} onFailure → ${s.onFailure} not found');
      }
    }

    // Detect cycles using DFS
    bool hasCycle = false;
    final visiting = <String>{};
    final visited = <String>{};
    bool dfs(String? nodeId) {
      if (nodeId == null) return false;
      if (visiting.contains(nodeId)) return true;
      if (visited.contains(nodeId)) return false;
      visiting.add(nodeId);
      final node = wf.steps.firstWhere((e) => e.id == nodeId, orElse: () => wf.steps.first);
      final c1 = dfs(node.onSuccess);
      final c2 = dfs(node.onFailure);
      visiting.remove(nodeId);
      visited.add(nodeId);
      return c1 || c2;
    }
    hasCycle = dfs(wf.steps.isNotEmpty ? wf.steps.first.id : null);
    if (hasCycle) warnings.add('Potential cycle detected in workflow transitions');

    // Find unreachable steps
    final reachable = <String>{};
    void mark(String? nodeId) {
      if (nodeId == null) return;
      if (!reachable.add(nodeId)) return;
      final node = wf.steps.firstWhere((e) => e.id == nodeId, orElse: () => wf.steps.first);
      mark(node.onSuccess);
      mark(node.onFailure);
    }
    if (wf.steps.isNotEmpty) mark(wf.steps.first.id);
    for (final id in stepIds) {
      if (!reachable.contains(id)) warnings.add('Unreachable step: $id');
    }

    // Steps with no outgoing transitions
    for (final s in wf.steps) {
      if (s.onSuccess == null && s.onFailure == null) {
        warnings.add('Terminal step: ${s.id}');
      }
    }

    return {'ok': warnings.isEmpty, 'warnings': warnings};
  }

  bool _evaluateConditions(List<Map<String, dynamic>> conditions, Map<String, dynamic> ctx) {
    for (final c in conditions) {
      final key = c['key'];
      final op = (c['op'] ?? 'exists').toString();
      final value = c['value'];
      final current = ctx[key];
      switch (op) {
        case 'exists':
          if (!ctx.containsKey(key)) return false;
          break;
        case 'equals':
          if (current != value) return false;
          break;
        case 'contains':
          if (current is! String || value is! String || !current.contains(value)) return false;
          break;
        case 'gt':
          if (current is num && value is num) {
            if (!(current > value)) return false;
          } else {
            return false;
          }
          break;
        case 'gte':
          if (current is num && value is num) {
            if (!(current >= value)) return false;
          } else {
            return false;
          }
          break;
        case 'lt':
          if (current is num && value is num) {
            if (!(current < value)) return false;
          } else {
            return false;
          }
          break;
        case 'lte':
          if (current is num && value is num) {
            if (!(current <= value)) return false;
          } else {
            return false;
          }
          break;
        default:
          return false;
      }
    }
    return true;
  }

  Map<String, dynamic> _simulateAction(String action, Map<String, dynamic> params, Map<String, dynamic> ctx) {
    // Simple action simulation; integrate real backends later
    switch (action) {
      case 'security.isolate_threat':
        return {'success': true, 'output': {'isolated': true}};
      case 'security.deep_analysis':
        return {'success': true, 'output': {'analysisScore': 92}};
      case 'security.apply_mitigation':
        return {'success': true, 'output': {'mitigationApplied': true}};
      case 'reporting.incident_report':
        return {'success': true, 'output': {'reportId': DateTime.now().millisecondsSinceEpoch}};
      case 'notification.alert_admins':
        developer.log('Alerting admins: ${params['priority'] ?? 'normal'}', name: 'DynamicWorkflow');
        return {'success': true};
      // Self-healing actions
      case 'system.restart_notifications':
        developer.log('Restarted notification subsystem', name: 'SelfHealing');
        return {'success': true, 'output': {'notificationsRestarted': true}};
      case 'cache.clear_auth':
        developer.log('Cleared auth cache', name: 'SelfHealing');
        return {'success': true, 'output': {'authCacheCleared': true}};
      case 'network.reconnect_realtime':
        developer.log('Reconnected realtime channel', name: 'SelfHealing');
        return {'success': true, 'output': {'realtimeReconnected': true}};
      default:
        return {'success': true};
    }
  }

  void _load() {
    try {
      final raw = _prefs.getString(_storageKey);
      if (raw == null) return;
      final Map<String, dynamic> map = jsonDecode(raw);
      _workflows.clear();
      map.forEach((k, v) => _workflows[k] = DynamicWorkflow.fromJson(v));
    } catch (e) {
      developer.log('Failed to load workflows: $e', name: 'DynamicWorkflow');
    }
  }

  Future<bool> _save() async {
    try {
      final map = _workflows.map((k, v) => MapEntry(k, v.toJson()));
      await _prefs.setString(_storageKey, jsonEncode(map));
      return true;
    } catch (e) {
      developer.log('Failed to save workflows: $e', name: 'DynamicWorkflow');
      return false;
    }
  }
}
