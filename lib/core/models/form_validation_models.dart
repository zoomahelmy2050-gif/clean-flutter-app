enum ValidationSeverity { info, warning, error, critical }
enum BreachStatus { safe, compromised, unknown, checking }
enum ValidationRuleType { 
  required, 
  email, 
  password_strength, 
  breach_check, 
  pattern, 
  length, 
  custom,
  phone_number,
  url,
  credit_card,
  ssn
}

class ValidationResult {
  final bool isValid;
  final ValidationSeverity severity;
  final String? message;
  final String? suggestion;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  ValidationResult({
    required this.isValid,
    this.severity = ValidationSeverity.error,
    this.message,
    this.suggestion,
    this.metadata = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ValidationResult.success({String? message}) {
    return ValidationResult(
      isValid: true,
      severity: ValidationSeverity.info,
      message: message,
    );
  }

  factory ValidationResult.error(String message, {String? suggestion}) {
    return ValidationResult(
      isValid: false,
      severity: ValidationSeverity.error,
      message: message,
      suggestion: suggestion,
    );
  }

  factory ValidationResult.warning(String message, {String? suggestion}) {
    return ValidationResult(
      isValid: true,
      severity: ValidationSeverity.warning,
      message: message,
      suggestion: suggestion,
    );
  }

  factory ValidationResult.fromJson(Map<String, dynamic> json) {
    return ValidationResult(
      isValid: json['isValid'],
      severity: ValidationSeverity.values.byName(json['severity']),
      message: json['message'],
      suggestion: json['suggestion'],
      metadata: json['metadata'] ?? {},
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'severity': severity.name,
      'message': message,
      'suggestion': suggestion,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class ValidationRule {
  final String id;
  final ValidationRuleType type;
  final String name;
  final String description;
  final bool isRequired;
  final Map<String, dynamic> parameters;
  final bool isEnabled;
  final int priority;

  ValidationRule({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    this.isRequired = false,
    this.parameters = const {},
    this.isEnabled = true,
    this.priority = 0,
  });

  factory ValidationRule.fromJson(Map<String, dynamic> json) {
    return ValidationRule(
      id: json['id'],
      type: ValidationRuleType.values.byName(json['type']),
      name: json['name'],
      description: json['description'],
      isRequired: json['isRequired'] ?? false,
      parameters: json['parameters'] ?? {},
      isEnabled: json['isEnabled'] ?? true,
      priority: json['priority'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'description': description,
      'isRequired': isRequired,
      'parameters': parameters,
      'isEnabled': isEnabled,
      'priority': priority,
    };
  }
}

class BreachCheckResult {
  final String value;
  final BreachStatus status;
  final List<DataBreach> breaches;
  final DateTime checkedAt;
  final String? riskScore;
  final Map<String, dynamic> metadata;

  BreachCheckResult({
    required this.value,
    required this.status,
    this.breaches = const [],
    DateTime? checkedAt,
    this.riskScore,
    this.metadata = const {},
  }) : checkedAt = checkedAt ?? DateTime.now();

  factory BreachCheckResult.fromJson(Map<String, dynamic> json) {
    return BreachCheckResult(
      value: json['value'],
      status: BreachStatus.values.byName(json['status']),
      breaches: (json['breaches'] as List?)?.map((e) => DataBreach.fromJson(e)).toList() ?? [],
      checkedAt: DateTime.parse(json['checkedAt']),
      riskScore: json['riskScore'],
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'status': status.name,
      'breaches': breaches.map((e) => e.toJson()).toList(),
      'checkedAt': checkedAt.toIso8601String(),
      'riskScore': riskScore,
      'metadata': metadata,
    };
  }
}

class DataBreach {
  final String id;
  final String name;
  final String domain;
  final DateTime breachDate;
  final int affectedAccounts;
  final List<String> compromisedData;
  final String severity;
  final String description;
  final bool isVerified;
  final bool isSensitive;

  DataBreach({
    required this.id,
    required this.name,
    required this.domain,
    required this.breachDate,
    required this.affectedAccounts,
    this.compromisedData = const [],
    required this.severity,
    required this.description,
    this.isVerified = true,
    this.isSensitive = false,
  });

  factory DataBreach.fromJson(Map<String, dynamic> json) {
    return DataBreach(
      id: json['id'],
      name: json['name'],
      domain: json['domain'],
      breachDate: DateTime.parse(json['breachDate']),
      affectedAccounts: json['affectedAccounts'],
      compromisedData: List<String>.from(json['compromisedData'] ?? []),
      severity: json['severity'],
      description: json['description'],
      isVerified: json['isVerified'] ?? true,
      isSensitive: json['isSensitive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'domain': domain,
      'breachDate': breachDate.toIso8601String(),
      'affectedAccounts': affectedAccounts,
      'compromisedData': compromisedData,
      'severity': severity,
      'description': description,
      'isVerified': isVerified,
      'isSensitive': isSensitive,
    };
  }
}

class FormValidationConfig {
  final String formId;
  final String name;
  final Map<String, List<ValidationRule>> fieldRules;
  final bool enableBreachChecking;
  final bool enableRealTimeValidation;
  final bool enablePasswordStrengthMeter;
  final Duration debounceDelay;
  final Map<String, dynamic> customSettings;

  FormValidationConfig({
    required this.formId,
    required this.name,
    this.fieldRules = const {},
    this.enableBreachChecking = true,
    this.enableRealTimeValidation = true,
    this.enablePasswordStrengthMeter = true,
    this.debounceDelay = const Duration(milliseconds: 500),
    this.customSettings = const {},
  });

  factory FormValidationConfig.fromJson(Map<String, dynamic> json) {
    final fieldRulesMap = <String, List<ValidationRule>>{};
    if (json['fieldRules'] != null) {
      (json['fieldRules'] as Map<String, dynamic>).forEach((key, value) {
        fieldRulesMap[key] = (value as List).map((e) => ValidationRule.fromJson(e)).toList();
      });
    }

    return FormValidationConfig(
      formId: json['formId'],
      name: json['name'],
      fieldRules: fieldRulesMap,
      enableBreachChecking: json['enableBreachChecking'] ?? true,
      enableRealTimeValidation: json['enableRealTimeValidation'] ?? true,
      enablePasswordStrengthMeter: json['enablePasswordStrengthMeter'] ?? true,
      debounceDelay: Duration(milliseconds: json['debounceDelay'] ?? 500),
      customSettings: json['customSettings'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    final fieldRulesMap = <String, dynamic>{};
    fieldRules.forEach((key, value) {
      fieldRulesMap[key] = value.map((e) => e.toJson()).toList();
    });

    return {
      'formId': formId,
      'name': name,
      'fieldRules': fieldRulesMap,
      'enableBreachChecking': enableBreachChecking,
      'enableRealTimeValidation': enableRealTimeValidation,
      'enablePasswordStrengthMeter': enablePasswordStrengthMeter,
      'debounceDelay': debounceDelay.inMilliseconds,
      'customSettings': customSettings,
    };
  }
}

class PasswordStrengthResult {
  final int score;
  final String level;
  final List<String> suggestions;
  final Map<String, bool> criteria;
  final Duration estimatedCrackTime;
  final String feedback;

  PasswordStrengthResult({
    required this.score,
    required this.level,
    this.suggestions = const [],
    this.criteria = const {},
    required this.estimatedCrackTime,
    required this.feedback,
  });

  factory PasswordStrengthResult.fromJson(Map<String, dynamic> json) {
    return PasswordStrengthResult(
      score: json['score'],
      level: json['level'],
      suggestions: List<String>.from(json['suggestions'] ?? []),
      criteria: Map<String, bool>.from(json['criteria'] ?? {}),
      estimatedCrackTime: Duration(seconds: json['estimatedCrackTime']),
      feedback: json['feedback'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'level': level,
      'suggestions': suggestions,
      'criteria': criteria,
      'estimatedCrackTime': estimatedCrackTime.inSeconds,
      'feedback': feedback,
    };
  }
}

class ValidationAnalytics {
  final String formId;
  final int totalValidations;
  final int successfulValidations;
  final int failedValidations;
  final Map<String, int> errorsByField;
  final Map<String, int> errorsByRule;
  final double averageValidationTime;
  final DateTime lastUpdated;
  final Map<String, dynamic> trends;

  ValidationAnalytics({
    required this.formId,
    this.totalValidations = 0,
    this.successfulValidations = 0,
    this.failedValidations = 0,
    this.errorsByField = const {},
    this.errorsByRule = const {},
    this.averageValidationTime = 0.0,
    DateTime? lastUpdated,
    this.trends = const {},
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory ValidationAnalytics.fromJson(Map<String, dynamic> json) {
    return ValidationAnalytics(
      formId: json['formId'],
      totalValidations: json['totalValidations'] ?? 0,
      successfulValidations: json['successfulValidations'] ?? 0,
      failedValidations: json['failedValidations'] ?? 0,
      errorsByField: Map<String, int>.from(json['errorsByField'] ?? {}),
      errorsByRule: Map<String, int>.from(json['errorsByRule'] ?? {}),
      averageValidationTime: json['averageValidationTime']?.toDouble() ?? 0.0,
      lastUpdated: DateTime.parse(json['lastUpdated']),
      trends: json['trends'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'formId': formId,
      'totalValidations': totalValidations,
      'successfulValidations': successfulValidations,
      'failedValidations': failedValidations,
      'errorsByField': errorsByField,
      'errorsByRule': errorsByRule,
      'averageValidationTime': averageValidationTime,
      'lastUpdated': lastUpdated.toIso8601String(),
      'trends': trends,
    };
  }
}

class SmartValidationSuggestion {
  final String fieldName;
  final String currentValue;
  final String suggestedValue;
  final String reason;
  final double confidence;
  final ValidationRuleType triggerRule;
  final bool isAutoCorrect;

  SmartValidationSuggestion({
    required this.fieldName,
    required this.currentValue,
    required this.suggestedValue,
    required this.reason,
    required this.confidence,
    required this.triggerRule,
    this.isAutoCorrect = false,
  });

  factory SmartValidationSuggestion.fromJson(Map<String, dynamic> json) {
    return SmartValidationSuggestion(
      fieldName: json['fieldName'],
      currentValue: json['currentValue'],
      suggestedValue: json['suggestedValue'],
      reason: json['reason'],
      confidence: json['confidence'].toDouble(),
      triggerRule: ValidationRuleType.values.byName(json['triggerRule']),
      isAutoCorrect: json['isAutoCorrect'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fieldName': fieldName,
      'currentValue': currentValue,
      'suggestedValue': suggestedValue,
      'reason': reason,
      'confidence': confidence,
      'triggerRule': triggerRule.name,
      'isAutoCorrect': isAutoCorrect,
    };
  }
}
