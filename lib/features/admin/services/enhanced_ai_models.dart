import 'dart:convert';

// Enhanced Models for Deep Reasoning
class DeepReasoningAnalysis {
  final String id;
  final DateTime timestamp;
  final String query;
  final String analysis;
  final double confidenceScore;
  final List<String> recommendations;
  final Map<String, dynamic> reasoningChain;
  final Map<String, dynamic> contextualFactors;
  final List<PolicySuggestion> policySuggestions;
  final List<AutomatedAction> suggestedActions;
  final String riskLevel;
  final Map<String, dynamic> learningOutcome;

  DeepReasoningAnalysis({
    required this.id,
    required this.timestamp,
    required this.query,
    required this.analysis,
    required this.confidenceScore,
    required this.recommendations,
    required this.reasoningChain,
    required this.contextualFactors,
    required this.policySuggestions,
    required this.suggestedActions,
    required this.riskLevel,
    required this.learningOutcome,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'query': query,
    'analysis': analysis,
    'confidenceScore': confidenceScore,
    'recommendations': recommendations,
    'reasoningChain': reasoningChain,
    'contextualFactors': contextualFactors,
    'policySuggestions': policySuggestions.map((p) => p.toJson()).toList(),
    'suggestedActions': suggestedActions.map((a) => a.toJson()).toList(),
    'riskLevel': riskLevel,
    'learningOutcome': learningOutcome,
  };
}

class PolicySuggestion {
  final String id;
  final String title;
  final String description;
  final String category;
  final String impact;
  final Map<String, dynamic> implementation;
  final double priority;

  PolicySuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.impact,
    required this.implementation,
    required this.priority,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'impact': impact,
    'implementation': implementation,
    'priority': priority,
  };
}

class AutomatedAction {
  final String id;
  final String type;
  final String description;
  final Map<String, dynamic> parameters;
  final String riskLevel;
  final bool requiresConfirmation;
  final Function? action;
  final String status;

  AutomatedAction({
    required this.id,
    required this.type,
    required this.description,
    required this.parameters,
    required this.riskLevel,
    required this.requiresConfirmation,
    this.action,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'description': description,
    'parameters': parameters,
    'riskLevel': riskLevel,
    'requiresConfirmation': requiresConfirmation,
    'status': status,
  };
}

class SuspiciousActivity {
  final String id;
  final DateTime detectedAt;
  final String type;
  final String description;
  final double anomalyScore;
  final Map<String, dynamic> indicators;
  final List<String> affectedAssets;
  final String severity;
  final Map<String, dynamic> context;
  final List<AutomatedAction> recommendedActions;

  SuspiciousActivity({
    required this.id,
    required this.detectedAt,
    required this.type,
    required this.description,
    required this.anomalyScore,
    required this.indicators,
    required this.affectedAssets,
    required this.severity,
    required this.context,
    required this.recommendedActions,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'detectedAt': detectedAt.toIso8601String(),
    'type': type,
    'description': description,
    'anomalyScore': anomalyScore,
    'indicators': indicators,
    'affectedAssets': affectedAssets,
    'severity': severity,
    'context': context,
    'recommendedActions': recommendedActions.map((a) => a.toJson()).toList(),
  };
}

class LearningPattern {
  final String patternId;
  final String category;
  final Map<String, dynamic> features;
  double confidence;
  int occurrences;
  final DateTime firstSeen;
  DateTime lastSeen;
  final List<String> associatedActions;
  final Map<String, dynamic> outcomes;

  LearningPattern({
    required this.patternId,
    required this.category,
    required this.features,
    required this.confidence,
    required this.occurrences,
    required this.firstSeen,
    required this.lastSeen,
    required this.associatedActions,
    required this.outcomes,
  });

  Map<String, dynamic> toJson() => {
    'patternId': patternId,
    'category': category,
    'features': features,
    'confidence': confidence,
    'occurrences': occurrences,
    'firstSeen': firstSeen.toIso8601String(),
    'lastSeen': lastSeen.toIso8601String(),
    'associatedActions': associatedActions,
    'outcomes': outcomes,
  };

  factory LearningPattern.fromJson(Map<String, dynamic> json) {
    return LearningPattern(
      patternId: json['patternId'],
      category: json['category'],
      features: json['features'],
      confidence: json['confidence'],
      occurrences: json['occurrences'],
      firstSeen: DateTime.parse(json['firstSeen']),
      lastSeen: DateTime.parse(json['lastSeen']),
      associatedActions: List<String>.from(json['associatedActions']),
      outcomes: json['outcomes'],
    );
  }
}
