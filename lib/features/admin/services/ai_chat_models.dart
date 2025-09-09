import 'package:flutter/material.dart';

// Intent Types
enum IntentType {
  query,
  command,
  conversation,
  learning,
  action,
  unknown
}

// Entity Types
enum EntityType {
  user,
  dateTime,
  number,
  workflow,
  setting,
  location,
  organization,
  custom
}

// Sentiment Types
enum SentimentType {
  positive,
  negative,
  neutral,
  mixed
}

// Action Types
enum ActionType {
  createWorkflow,
  updateSettings,
  manageUsers,
  sendNotification,
  runAnalysis,
  configSecurity,
  syncData,
  generateReport,
  backupData,
  restoreData,
  monitorSystem,
  optimizePerformance,
  custom
}

// Node Types for Neural Network
enum NodeType {
  input,
  hidden,
  output,
  memory,
  attention
}

// Pattern Types
enum PatternType {
  linguistic,
  semantic,
  behavioral,
  contextual
}

// Intent Class
class Intent {
  final IntentType type;
  final double confidence;
  final List<Intent> subIntents;
  final bool requiresAction;
  final Map<String, dynamic> parameters;

  Intent({
    required this.type,
    required this.confidence,
    required this.subIntents,
    required this.requiresAction,
    required this.parameters,
  });

  Map<String, dynamic> toJson() => {
    'type': type.toString(),
    'confidence': confidence,
    'subIntents': subIntents.map((i) => i.toJson()).toList(),
    'requiresAction': requiresAction,
    'parameters': parameters,
  };
}

// Entity Class
class Entity {
  final EntityType type;
  final String value;
  final int position;
  final double confidence;
  final Map<String, dynamic>? metadata;

  Entity({
    required this.type,
    required this.value,
    required this.position,
    required this.confidence,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'type': type.toString(),
    'value': value,
    'position': position,
    'confidence': confidence,
    'metadata': metadata,
  };
}

// Sentiment Class
class Sentiment {
  final SentimentType type;
  final double positiveScore;
  final double negativeScore;
  final double neutralScore;
  final double confidence;

  Sentiment({
    required this.type,
    required this.positiveScore,
    required this.negativeScore,
    required this.neutralScore,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
    'type': type.toString(),
    'positiveScore': positiveScore,
    'negativeScore': negativeScore,
    'neutralScore': neutralScore,
    'confidence': confidence,
  };
}

// AI Response Class
class AIResponse {
  final String text;
  final List<String> suggestions;
  final Map<String, dynamic> metadata;
  final bool requiresConfirmation;
  final List<AppAction> actions;
  final List<Widget>? widgets;
  final EmotionalTone? emotionalTone;
  final ResponsePriority? priority;

  AIResponse({
    required this.text,
    required this.suggestions,
    required this.metadata,
    required this.requiresConfirmation,
    required this.actions,
    this.widgets,
    this.emotionalTone,
    this.priority,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'suggestions': suggestions,
    'metadata': metadata,
    'requiresConfirmation': requiresConfirmation,
    'actions': actions.map((a) => a.toJson()).toList(),
    'emotionalTone': emotionalTone?.toString(),
    'priority': priority?.toString(),
  };
}

// App Action Class
class AppAction {
  final ActionType type;
  final String name;
  final String description;
  final Map<String, dynamic> parameters;
  final List<String> requiredPermissions;
  final bool isReversible;
  final String? confirmationMessage;
  final ActionImpact impact;

  AppAction({
    required this.type,
    required this.name,
    required this.description,
    required this.parameters,
    required this.requiredPermissions,
    required this.isReversible,
    this.confirmationMessage,
    required this.impact,
  });

  Map<String, dynamic> toJson() => {
    'type': type.toString(),
    'name': name,
    'description': description,
    'parameters': parameters,
    'requiredPermissions': requiredPermissions,
    'isReversible': isReversible,
    'confirmationMessage': confirmationMessage,
    'impact': impact.toJson(),
  };
}

// Action Impact Class
class ActionImpact {
  final String level; // low, medium, high, critical
  final List<String> affectedAreas;
  final List<String> potentialRisks;
  final Map<String, dynamic> estimatedChanges;

  ActionImpact({
    required this.level,
    required this.affectedAreas,
    required this.potentialRisks,
    required this.estimatedChanges,
  });

  Map<String, dynamic> toJson() => {
    'level': level,
    'affectedAreas': affectedAreas,
    'potentialRisks': potentialRisks,
    'estimatedChanges': estimatedChanges,
  };
}

// Conversation Memory Class
class ConversationMemory {
  final String userMessage;
  final String aiResponse;
  final DateTime timestamp;
  final Map<String, dynamic> context;
  final String? intent;
  final double confidence;
  final bool success;
  final double feedback;

  ConversationMemory({
    required this.userMessage,
    required this.aiResponse,
    required this.timestamp,
    required this.context,
    this.intent,
    required this.confidence,
    required this.success,
    required this.feedback,
  });

  Map<String, dynamic> toJson() => {
    'userMessage': userMessage,
    'aiResponse': aiResponse,
    'timestamp': timestamp.toIso8601String(),
    'context': context,
    'intent': intent,
    'confidence': confidence,
    'success': success,
    'feedback': feedback,
  };

  factory ConversationMemory.fromJson(Map<String, dynamic> json) {
    return ConversationMemory(
      userMessage: json['userMessage'],
      aiResponse: json['aiResponse'],
      timestamp: DateTime.parse(json['timestamp']),
      context: json['context'],
      intent: json['intent'],
      confidence: json['confidence'],
      success: json['success'],
      feedback: json['feedback'],
    );
  }
}

// Conversation Context Class
class ConversationContext {
  final String message;
  final DateTime timestamp;
  final String userId;
  final String sessionId;
  final List<String> contextHistory;
  String? intent;
  double? confidence;

  ConversationContext({
    required this.message,
    required this.timestamp,
    required this.userId,
    required this.sessionId,
    required this.contextHistory,
    this.intent,
    this.confidence,
  });

  Map<String, dynamic> toJson() => {
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'userId': userId,
    'sessionId': sessionId,
    'contextHistory': contextHistory,
    'intent': intent,
    'confidence': confidence,
  };
}

// Neural Node Class
class NeuralNode {
  final String id;
  final NodeType type;
  final String label;
  double activation;
  final Map<String, double> connections;

  NeuralNode({
    required this.id,
    required this.type,
    required this.label,
    required this.activation,
    Map<String, double>? connections,
  }) : connections = connections ?? {};

  void updateActivation(double value) {
    activation = value;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'label': label,
    'activation': activation,
    'connections': connections,
  };
}

// Learning Pattern Class
class LearningPattern {
  final String input;
  final Intent intent;
  final List<Entity> entities;
  final DateTime timestamp;
  final bool success;
  double weight;

  LearningPattern({
    required this.input,
    required this.intent,
    required this.entities,
    required this.timestamp,
    required this.success,
    this.weight = 1.0,
  });

  String generateKey() {
    return '${intent.type}_${entities.map((e) => e.type).join('_')}';
  }

  Map<String, dynamic> toJson() => {
    'input': input,
    'intent': intent.toJson(),
    'entities': entities.map((e) => e.toJson()).toList(),
    'timestamp': timestamp.toIso8601String(),
    'success': success,
    'weight': weight,
  };
}

// Pattern Class for Learning
class Pattern {
  final PatternType type;
  final List<dynamic> sequence;
  final Map<String, dynamic> context;
  final double weight;

  Pattern({
    required this.type,
    required this.sequence,
    required this.context,
    required this.weight,
  });

  String generateKey() {
    return '${type}_${sequence.join('_')}';
  }
}

// Action Handler Class
class ActionHandler {
  final ActionType type;
  final Future<ActionResult> Function(dynamic params) execute;
  final Future<bool> Function(dynamic params) validate;
  final Future<void> Function(dynamic params) rollback;

  ActionHandler({
    required this.type,
    required this.execute,
    required this.validate,
    required this.rollback,
  });
}

// Action Result Class
class ActionResult {
  final bool success;
  final String message;
  final String? error;
  final Map<String, dynamic>? data;
  final List<String>? affectedItems;

  ActionResult({
    required this.success,
    required this.message,
    this.error,
    this.data,
    this.affectedItems,
  });

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'error': error,
    'data': data,
    'affectedItems': affectedItems,
  };
}

// Pending Action Class
class PendingAction {
  final String id;
  final AppAction action;
  final DateTime requestedAt;
  final String requestedBy;
  final ActionStatus status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;

  PendingAction({
    required this.id,
    required this.action,
    required this.requestedAt,
    required this.requestedBy,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'action': action.toJson(),
    'requestedAt': requestedAt.toIso8601String(),
    'requestedBy': requestedBy,
    'status': status.toString(),
    'approvedBy': approvedBy,
    'approvedAt': approvedAt?.toIso8601String(),
    'rejectionReason': rejectionReason,
  };
}

// Action Status Enum
enum ActionStatus {
  pending,
  approved,
  rejected,
  executing,
  completed,
  failed,
  rolledBack
}

// Emotional Tone Enum
enum EmotionalTone {
  professional,
  friendly,
  empathetic,
  urgent,
  cautious,
  enthusiastic,
  neutral
}

// Response Priority Enum
enum ResponsePriority {
  low,
  normal,
  high,
  critical
}

// Knowledge Entry Class
class KnowledgeEntry {
  final String id;
  final String category;
  final String topic;
  final Map<String, dynamic> content;
  final double relevanceScore;
  final DateTime lastUpdated;
  final int accessCount;

  KnowledgeEntry({
    required this.id,
    required this.category,
    required this.topic,
    required this.content,
    required this.relevanceScore,
    required this.lastUpdated,
    required this.accessCount,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'topic': topic,
    'content': content,
    'relevanceScore': relevanceScore,
    'lastUpdated': lastUpdated.toIso8601String(),
    'accessCount': accessCount,
  };
}
