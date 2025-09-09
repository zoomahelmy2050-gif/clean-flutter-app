import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'ai_models.dart';
import 'ai_action_executor.dart';
import 'ai_realtime_analyzer.dart';
import 'ai_context_manager.dart';

class AIAutomationWorkflows {
  late AIActionExecutor _actionExecutor;
  late AIRealtimeAnalyzer _realtimeAnalyzer;
  late AIContextManager _contextManager;
  
  final Map<String, Workflow> _workflows = {};
  final Map<String, WorkflowInstance> _activeInstances = {};
  final List<WorkflowExecution> _executionHistory = [];
  final _random = Random();
  
  // Stream controllers
  final StreamController<WorkflowEvent> _eventController = StreamController<WorkflowEvent>.broadcast();
  final StreamController<WorkflowStatus> _statusController = StreamController<WorkflowStatus>.broadcast();
  
  Stream<WorkflowEvent> get eventStream => _eventController.stream;
  Stream<WorkflowStatus> get statusStream => _statusController.stream;
  
  // Timers for scheduled workflows
  final Map<String, Timer> _scheduledTimers = {};
  
  AIAutomationWorkflows() {
    _initialize();
  }
  
  void _initialize() {
    _actionExecutor = AIActionExecutor();
    _realtimeAnalyzer = AIRealtimeAnalyzer();
    _contextManager = AIContextManager();
    
    // Initialize predefined workflows
    _initializePredefinedWorkflows();
    
    // Start monitoring for triggers
    _startTriggerMonitoring();
  }
  
  void _initializePredefinedWorkflows() {
    // Security Response Workflow
    _workflows['security_response'] = Workflow(
      id: 'WF-SECURITY-001',
      name: 'Automated Security Response',
      description: 'Responds to security threats automatically',
      type: 'reactive',
      triggers: [
        WorkflowTrigger(
          type: 'event',
          condition: {'event_type': 'security_threat', 'severity': ['high', 'critical']},
          description: 'Triggered by high/critical security threats',
        ),
      ],
      steps: _createSecurityResponseSteps(),
      metadata: {
        'category': 'security',
        'priority': 'critical',
        'estimated_duration': '5-10 minutes',
      },
      enabled: true,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );
    
    // Performance Optimization Workflow
    _workflows['performance_optimization'] = Workflow(
      id: 'WF-PERF-001',
      name: 'Auto Performance Optimization',
      description: 'Optimizes system performance when degradation detected',
      type: 'reactive',
      triggers: [
        WorkflowTrigger(
          type: 'metric',
          condition: {'metric': 'response_time', 'operator': '>', 'value': 1000},
          description: 'Triggered when response time exceeds 1000ms',
        ),
      ],
      steps: _createPerformanceOptimizationSteps(),
      metadata: {
        'category': 'performance',
        'priority': 'high',
        'estimated_duration': '2-5 minutes',
      },
      enabled: true,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );
  }
  
  List<WorkflowStep> _createSecurityResponseSteps() {
    return [
      WorkflowStep(
        id: 'isolate',
        name: 'Isolate Threat',
        action: 'security.isolate_threat',
        parameters: {'mode': 'automatic'},
        conditions: [],
        onSuccess: 'analyze',
        onFailure: 'alert',
      ),
      WorkflowStep(
        id: 'analyze',
        name: 'Analyze Threat',
        action: 'security.deep_analysis',
        parameters: {'depth': 'comprehensive'},
        conditions: [],
        onSuccess: 'mitigate',
        onFailure: 'alert',
      ),
      WorkflowStep(
        id: 'mitigate',
        name: 'Apply Mitigation',
        action: 'security.apply_mitigation',
        parameters: {'strategy': 'adaptive'},
        conditions: [],
        onSuccess: 'report',
        onFailure: 'alert',
      ),
      WorkflowStep(
        id: 'report',
        name: 'Generate Report',
        action: 'reporting.incident_report',
        parameters: {'format': 'detailed'},
        conditions: [],
        onSuccess: 'complete',
        onFailure: 'alert',
      ),
      WorkflowStep(
        id: 'alert',
        name: 'Alert Administrators',
        action: 'notification.alert_admins',
        parameters: {'priority': 'high'},
        conditions: [],
        onSuccess: 'complete',
        onFailure: 'complete',
      ),
    ];
  }
  
  List<WorkflowStep> _createPerformanceOptimizationSteps() {
    return [
      WorkflowStep(
        id: 'diagnose',
        name: 'Diagnose Performance',
        action: 'performance.diagnose',
        parameters: {'scope': 'full'},
        conditions: [],
        onSuccess: 'optimize_cache',
        onFailure: 'monitor',
      ),
      WorkflowStep(
        id: 'optimize_cache',
        name: 'Optimize Cache',
        action: 'performance.optimize_cache',
        parameters: {'strategy': 'intelligent'},
        conditions: [
          {'field': 'diagnosis.bottleneck', 'operator': 'contains', 'value': 'cache'}
        ],
        onSuccess: 'verify',
        onFailure: 'verify',
      ),
      WorkflowStep(
        id: 'verify',
        name: 'Verify Improvements',
        action: 'performance.verify_metrics',
        parameters: {'duration': 60},
        conditions: [],
        onSuccess: 'complete',
        onFailure: 'escalate',
      ),
      WorkflowStep(
        id: 'escalate',
        name: 'Escalate to Admin',
        action: 'notification.escalate',
        parameters: {'target': 'admin', 'priority': 'high'},
        conditions: [],
        onSuccess: 'complete',
        onFailure: 'complete',
      ),
      WorkflowStep(
        id: 'monitor',
        name: 'Continue Monitoring',
        action: 'monitoring.enhanced',
        parameters: {'duration': 300},
        conditions: [],
        onSuccess: 'complete',
        onFailure: 'complete',
      ),
    ];
  }
  
  void _startTriggerMonitoring() {
    // Monitor real-time events
    _realtimeAnalyzer.insightStream.listen((insight) {
      _checkEventTriggers({
        'event_type': insight.type,
        'severity': insight.severity,
        'data': insight.data,
      });
    });
    
    // Set up scheduled workflows
    for (final workflow in _workflows.values) {
      if (workflow.type == 'scheduled' && workflow.enabled) {
        _scheduleWorkflow(workflow);
      }
    }
    
    // Simulate periodic metric checks
    Timer.periodic(const Duration(seconds: 30), (_) {
      _checkMetricTriggers();
    });
  }
  
  void _checkEventTriggers(Map<String, dynamic> event) {
    for (final workflow in _workflows.values) {
      if (!workflow.enabled || workflow.type != 'reactive') continue;
      
      for (final trigger in workflow.triggers) {
        if (trigger.type == 'event' && _matchesCondition(event, trigger.condition)) {
          _executeWorkflow(workflow.id, event);
          break;
        }
      }
    }
  }
  
  void _checkMetricTriggers() {
    final context = _contextManager.getCurrentContext();
    final metrics = {
      'cpu_usage': (context.performanceData['metrics']?['cpu_usage'] ?? 0).toDouble(),
      'memory_usage': (context.performanceData['metrics']?['memory_usage'] ?? 0).toDouble(),
      'response_time': (context.performanceData['metrics']?['response_time']?['avg_ms'] ?? 0).toDouble(),
      'error_rate': (context.performanceData['metrics']?['errors']?['rate_percent'] ?? 0).toDouble(),
    };
    
    for (final workflow in _workflows.values) {
      if (!workflow.enabled || workflow.type != 'reactive') continue;
      
      for (final trigger in workflow.triggers) {
        if (trigger.type == 'metric') {
          final metricName = trigger.condition['metric'];
          final operator = trigger.condition['operator'];
          final threshold = (trigger.condition['value'] as num).toDouble();
          final currentValue = metrics[metricName] ?? 0.0;
          
          if (_compareValues(currentValue, operator, threshold)) {
            _executeWorkflow(workflow.id, metrics);
            break;
          }
        }
      }
    }
  }
  
  bool _matchesCondition(Map<String, dynamic> data, Map<String, dynamic> condition) {
    for (final entry in condition.entries) {
      final dataValue = data[entry.key];
      final conditionValue = entry.value;
      
      if (conditionValue is List) {
        if (!conditionValue.contains(dataValue)) return false;
      } else {
        if (dataValue != conditionValue) return false;
      }
    }
    return true;
  }
  
  bool _compareValues(double value1, String operator, double value2) {
    switch (operator) {
      case '>':
        return value1 > value2;
      case '>=':
        return value1 >= value2;
      case '<':
        return value1 < value2;
      case '<=':
        return value1 <= value2;
      case '==':
        return value1 == value2;
      case '!=':
        return value1 != value2;
      default:
        return false;
    }
  }
  
  void _scheduleWorkflow(Workflow workflow) {
    // Simplified scheduling - in production would use proper cron parser
    for (final trigger in workflow.triggers) {
      if (trigger.type == 'schedule') {
        final cron = trigger.condition['cron'] as String;
        Duration interval;
        
        if (cron.contains('*/15')) {
          interval = const Duration(minutes: 15);
        } else if (cron.contains('0 * * * *')) {
          interval = const Duration(hours: 1);
        } else {
          interval = const Duration(hours: 24);
        }
        
        final timer = Timer.periodic(interval, (_) {
          _executeWorkflow(workflow.id, {'scheduled': true});
        });
        
        _scheduledTimers[workflow.id] = timer;
      }
    }
  }
  
  Future<void> _executeWorkflow(String workflowId, Map<String, dynamic> context) async {
    final workflow = _workflows[workflowId];
    if (workflow == null || !workflow.enabled) return;
    
    // Check if already running
    if (_activeInstances.containsKey(workflowId)) {
      debugPrint('Workflow $workflowId is already running');
      return;
    }
    
    final instance = WorkflowInstance(
      id: 'INST-${DateTime.now().millisecondsSinceEpoch}',
      workflowId: workflowId,
      status: 'running',
      currentStep: workflow.steps.first.id,
      context: context,
      startTime: DateTime.now(),
      steps: {},
    );
    
    _activeInstances[workflowId] = instance;
    
    _eventController.add(WorkflowEvent(
      type: 'started',
      workflowId: workflowId,
      instanceId: instance.id,
      data: {'workflow': workflow.name},
      timestamp: DateTime.now(),
    ));
    
    // Execute steps
    try {
      await _executeSteps(workflow, instance);
      
      instance.status = 'completed';
      instance.endTime = DateTime.now();
      
      _eventController.add(WorkflowEvent(
        type: 'completed',
        workflowId: workflowId,
        instanceId: instance.id,
        data: {'duration': instance.endTime!.difference(instance.startTime).inSeconds},
        timestamp: DateTime.now(),
      ));
      
    } catch (e) {
      instance.status = 'failed';
      instance.error = e.toString();
      instance.endTime = DateTime.now();
      
      _eventController.add(WorkflowEvent(
        type: 'failed',
        workflowId: workflowId,
        instanceId: instance.id,
        data: {'error': e.toString()},
        timestamp: DateTime.now(),
      ));
    } finally {
      _activeInstances.remove(workflowId);
      _addToHistory(instance);
    }
  }
  
  Future<void> _executeSteps(Workflow workflow, WorkflowInstance instance) async {
    Map<String, WorkflowStep> stepMap = {};
    for (final step in workflow.steps) {
      stepMap[step.id] = step;
    }
    
    String? currentStepId = workflow.steps.first.id;
    
    while (currentStepId != null && currentStepId != 'complete') {
      final step = stepMap[currentStepId];
      if (step == null) break;
      
      instance.currentStep = currentStepId;
      
      _eventController.add(WorkflowEvent(
        type: 'step_started',
        workflowId: workflow.id,
        instanceId: instance.id,
        data: {'step': step.name},
        timestamp: DateTime.now(),
      ));
      
      final stepResult = await _executeStep(step, instance);
      instance.steps[currentStepId] = stepResult;
      
      if (stepResult.success) {
        currentStepId = step.onSuccess;
      } else {
        currentStepId = step.onFailure;
      }
      
      _eventController.add(WorkflowEvent(
        type: 'step_completed',
        workflowId: workflow.id,
        instanceId: instance.id,
        data: {
          'step': step.name,
          'success': stepResult.success,
          'next': currentStepId,
        },
        timestamp: DateTime.now(),
      ));
    }
  }
  
  Future<StepResult> _executeStep(WorkflowStep step, WorkflowInstance instance) async {
    // Check conditions
    for (final condition in step.conditions) {
      if (!_evaluateCondition(condition, instance)) {
        return StepResult(
          stepId: step.id,
          success: false,
          skipped: true,
          output: {'reason': 'Condition not met'},
          timestamp: DateTime.now(),
        );
      }
    }
    
    // Simulate step execution
    await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(1500)));
    
    // Create and execute action
    final action = AIAction(
      id: 'ACT-${DateTime.now().millisecondsSinceEpoch}',
      type: step.action,
      description: step.name,
      parameters: step.parameters,
      priority: 'high',
      status: 'pending',
      requiresConfirmation: false,
      impact: 'medium',
      confidence: 0.9,
    );
    
    final executedAction = await _actionExecutor.executeAction(action);
    
    return StepResult(
      stepId: step.id,
      success: executedAction.status == 'completed',
      skipped: false,
      output: executedAction.result ?? {},
      timestamp: DateTime.now(),
    );
  }
  
  bool _evaluateCondition(Map<String, dynamic> condition, WorkflowInstance instance) {
    final field = condition['field'] as String;
    final operator = condition['operator'] as String;
    final expectedValue = condition['value'];
    
    // Extract value from instance context or previous step results
    dynamic actualValue;
    if (field.startsWith('context.')) {
      actualValue = _getNestedValue(instance.context, field.substring(8));
    } else {
      // Check previous step results
      for (final stepResult in instance.steps.values) {
        actualValue = _getNestedValue(stepResult.output, field);
        if (actualValue != null) break;
      }
    }
    
    if (actualValue == null) return false;
    
    switch (operator) {
      case '==':
        return actualValue == expectedValue;
      case '!=':
        return actualValue != expectedValue;
      case '>':
        return actualValue > expectedValue;
      case '<':
        return actualValue < expectedValue;
      case 'contains':
        return actualValue.toString().contains(expectedValue.toString());
      default:
        return false;
    }
  }
  
  dynamic _getNestedValue(Map<String, dynamic> data, String path) {
    final parts = path.split('.');
    dynamic current = data;
    
    for (final part in parts) {
      if (current is Map) {
        current = current[part];
      } else {
        return null;
      }
    }
    
    return current;
  }
  
  void _addToHistory(WorkflowInstance instance) {
    _executionHistory.add(WorkflowExecution(
      instanceId: instance.id,
      workflowId: instance.workflowId,
      status: instance.status,
      startTime: instance.startTime,
      endTime: instance.endTime!,
      duration: instance.endTime!.difference(instance.startTime),
      stepsExecuted: instance.steps.length,
      error: instance.error,
    ));
    
    // Limit history size
    while (_executionHistory.length > 100) {
      _executionHistory.removeAt(0);
    }
  }
  
  // Public API
  List<Workflow> getWorkflows() {
    return _workflows.values.toList();
  }
  
  List<WorkflowExecution> getExecutionHistory({int limit = 50}) {
    final history = _executionHistory.reversed.take(limit).toList();
    return history;
  }
  
  void dispose() {
    for (final timer in _scheduledTimers.values) {
      timer.cancel();
    }
    _scheduledTimers.clear();
    _eventController.close();
    _statusController.close();
    _actionExecutor.dispose();
    _realtimeAnalyzer.dispose();
    _contextManager.dispose();
  }
}
