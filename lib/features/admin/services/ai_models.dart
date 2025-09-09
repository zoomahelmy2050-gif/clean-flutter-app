// Advanced AI Models and Data Structures
import 'dart:convert';

class AIContext {
  final String id;
  final DateTime timestamp;
  final Map<String, dynamic> systemState;
  final Map<String, dynamic> userContext;
  final Map<String, dynamic> securityMetrics;
  final Map<String, dynamic> performanceData;
  final List<String> activeThreats;
  final List<String> recommendations;
  final double confidenceScore;

  AIContext({
    required this.id,
    required this.timestamp,
    required this.systemState,
    required this.userContext,
    required this.securityMetrics,
    required this.performanceData,
    required this.activeThreats,
    required this.recommendations,
    required this.confidenceScore,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'systemState': systemState,
    'userContext': userContext,
    'securityMetrics': securityMetrics,
    'performanceData': performanceData,
    'activeThreats': activeThreats,
    'recommendations': recommendations,
    'confidenceScore': confidenceScore,
  };
}

class AIAction {
  final String id;
  final String type;
  final String description;
  final Map<String, dynamic> parameters;
  String status;
  final DateTime? executedAt;
  Map<String, dynamic>? result;
  String? error;
  final String priority;
  final bool requiresConfirmation;
  final String impact;
  final double confidence;

  AIAction({
    required this.id,
    required this.type,
    required this.description,
    required this.parameters,
    required this.status,
    this.executedAt,
    this.result,
    this.error,
    this.priority = 'medium',
    this.requiresConfirmation = false,
    this.impact = 'low',
    this.confidence = 0.8,
  });

  AIAction copyWith({
    String? id,
    String? type,
    String? description,
    Map<String, dynamic>? parameters,
    String? status,
    DateTime? executedAt,
    Map<String, dynamic>? result,
    String? error,
    String? priority,
    bool? requiresConfirmation,
    String? impact,
    double? confidence,
  }) {
    return AIAction(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      parameters: parameters ?? this.parameters,
      status: status ?? this.status,
      executedAt: executedAt ?? this.executedAt,
      result: result ?? this.result,
      error: error ?? this.error,
      priority: priority ?? this.priority,
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
      impact: impact ?? this.impact,
      confidence: confidence ?? this.confidence,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'description': description,
    'parameters': parameters,
    'status': status,
    'executedAt': executedAt?.toIso8601String(),
    'result': result,
    'error': error,
    'priority': priority,
    'requiresConfirmation': requiresConfirmation,
    'impact': impact,
    'confidence': confidence,
  };
}

class AIInsight {
  final String id;
  final String category;
  final String title;
  final String description;
  final String severity;
  final Map<String, dynamic> data;
  final List<String> affectedComponents;
  final List<String> suggestedActions;
  final DateTime discoveredAt;
  final bool isActionable;
  final double importance;

  AIInsight({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.severity,
    required this.data,
    required this.affectedComponents,
    required this.suggestedActions,
    required this.discoveredAt,
    required this.isActionable,
    required this.importance,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'title': title,
    'description': description,
    'severity': severity,
    'data': data,
    'affectedComponents': affectedComponents,
    'suggestedActions': suggestedActions,
    'timestamp': discoveredAt.toIso8601String(),
    'detectedAt': discoveredAt.toIso8601String(),
  };

  // Add getter for type to maintain compatibility
  String get type => category;
  
  // Add getter for timestamp alias
  DateTime get timestamp => discoveredAt;
  DateTime get detectedAt => discoveredAt;
}

class AIConversation {
  final String id;
  final List<AIMessage> messages;
  final AIContext context;
  final Map<String, dynamic> sessionData;
  final DateTime startedAt;
  DateTime lastActivity;
  String status;

  AIConversation({
    required this.id,
    required this.messages,
    required this.context,
    required this.sessionData,
    required this.startedAt,
    required this.lastActivity,
    required this.status,
  });
}

class AIMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? category;
  final Map<String, dynamic>? metadata;
  final List<AIAction>? actions;
  final List<AIInsight>? insights;
  final String? intent;
  final double? confidenceScore;
  final List<String>? sources;
  final Map<String, dynamic>? visualData;

  AIMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.category,
    this.metadata,
    this.actions,
    this.insights,
    this.intent,
    this.confidenceScore,
    this.sources,
    this.visualData,
  });
}

class AIPrediction {
  final String id;
  final String type;
  final String description;
  final double probability;
  final String timeframe;
  final Map<String, dynamic> indicators;
  final List<AIAction> preventiveActions;
  final DateTime predictedAt;

  AIPrediction({
    required this.id,
    required this.type,
    required this.probability,
    required this.timeframe,
    required this.indicators,
    required this.preventiveActions,
    required this.predictedAt,
    String? description,
  }) : description = description ?? type;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'description': description,
    'probability': probability,
    'timeframe': timeframe,
    'indicators': indicators,
    'preventiveActions': preventiveActions,
    'predictedAt': predictedAt.toIso8601String(),
  };
}

class AIWorkflow {
  final String id;
  final String name;
  final String description;
  final List<String> steps;
  final Map<String, dynamic> conditions;
  final List<AIAction> actions;
  final String status;
  final DateTime? lastExecuted;
  final Map<String, dynamic>? results;

  AIWorkflow({
    required this.id,
    required this.name,
    required this.description,
    required this.steps,
    required this.conditions,
    required this.actions,
    required this.status,
    this.lastExecuted,
    this.results,
  });
}

class AIAnalyticsData {
  final String id;
  final String type;
  final Map<String, dynamic> metrics;
  final List<Map<String, dynamic>> timeSeries;
  final Map<String, dynamic> aggregations;
  final List<String> anomalies;
  final DateTime generatedAt;

  AIAnalyticsData({
    required this.id,
    required this.type,
    required this.metrics,
    required this.timeSeries,
    required this.aggregations,
    required this.anomalies,
    required this.generatedAt,
  });
}

class AICommand {
  final String id;
  final String command;
  final String description;
  final Map<String, dynamic> parameters;
  final String category;
  final List<String> requiredPermissions;
  final bool requiresConfirmation;
  
  AICommand({
    required this.id,
    required this.command,
    required this.description,
    required this.parameters,
    required this.category,
    required this.requiredPermissions,
    required this.requiresConfirmation,
  });
}

enum AICapability {
  securityAnalysis,
  threatDetection,
  performanceMonitoring,
  userManagement,
  systemAutomation,
  predictiveAnalytics,
  incidentResponse,
  forensicsAnalysis,
  complianceChecking,
  resourceOptimization,
  behaviorAnalysis,
  anomalyDetection,
  reportGeneration,
  workflowOrchestration,
  intelligenceGathering,
}

class AISystemStatus {
  final bool isOperational;
  final double systemLoad;
  final int activeProcesses;
  final int queuedTasks;
  final Map<String, dynamic> resourceUsage;
  final List<String> activeModules;
  final DateTime lastHealthCheck;
  final Map<AICapability, bool> capabilityStatus;

  AISystemStatus({
    required this.isOperational,
    required this.systemLoad,
    required this.activeProcesses,
    required this.queuedTasks,
    required this.resourceUsage,
    required this.activeModules,
    required this.lastHealthCheck,
    required this.capabilityStatus,
  });
}

// Workflow-specific models
class Workflow {
  final String id;
  final String name;
  final String description;
  final String type; // 'reactive', 'scheduled', 'manual'
  final List<WorkflowTrigger> triggers;
  final List<WorkflowStep> steps;
  final Map<String, dynamic> metadata;
  final bool enabled;
  final DateTime createdAt;
  final DateTime lastModified;

  Workflow({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.triggers,
    required this.steps,
    required this.metadata,
    required this.enabled,
    required this.createdAt,
    required this.lastModified,
  });
}

class WorkflowTrigger {
  final String type; // 'event', 'metric', 'schedule', 'manual'
  final Map<String, dynamic> condition;
  final String description;

  WorkflowTrigger({
    required this.type,
    required this.condition,
    required this.description,
  });
}

class WorkflowStep {
  final String id;
  final String name;
  final String action;
  final Map<String, dynamic> parameters;
  final List<Map<String, dynamic>> conditions;
  final String onSuccess;
  final String onFailure;

  WorkflowStep({
    required this.id,
    required this.name,
    required this.action,
    required this.parameters,
    required this.conditions,
    required this.onSuccess,
    required this.onFailure,
  });
}

class WorkflowInstance {
  final String id;
  final String workflowId;
  String status;
  String currentStep;
  final Map<String, dynamic> context;
  final DateTime startTime;
  DateTime? endTime;
  final Map<String, StepResult> steps;
  String? error;

  WorkflowInstance({
    required this.id,
    required this.workflowId,
    required this.status,
    required this.currentStep,
    required this.context,
    required this.startTime,
    this.endTime,
    required this.steps,
    this.error,
  });
}

class StepResult {
  final String stepId;
  final bool success;
  final bool skipped;
  final Map<String, dynamic> output;
  final DateTime timestamp;

  StepResult({
    required this.stepId,
    required this.success,
    required this.skipped,
    required this.output,
    required this.timestamp,
  });
}

class WorkflowExecution {
  final String instanceId;
  final String workflowId;
  final String status;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final int stepsExecuted;
  final String? error;

  WorkflowExecution({
    required this.instanceId,
    required this.workflowId,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.stepsExecuted,
    this.error,
  });
}

class WorkflowEvent {
  final String type;
  final String workflowId;
  final String instanceId;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  WorkflowEvent({
    required this.type,
    required this.workflowId,
    required this.instanceId,
    required this.data,
    required this.timestamp,
  });
}

class WorkflowStatus {
  final String workflowId;
  final String instanceId;
  final String status;
  final String currentStep;
  final double progress;
  final DateTime timestamp;

  WorkflowStatus({
    required this.workflowId,
    required this.instanceId,
    required this.status,
    required this.currentStep,
    required this.progress,
    required this.timestamp,
  });
}
