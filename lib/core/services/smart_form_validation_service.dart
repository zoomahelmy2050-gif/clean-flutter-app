import 'dart:async';
import 'dart:math';
import 'dart:developer' as developer;
import '../models/form_validation_models.dart';

class SmartFormValidationService {
  static final SmartFormValidationService _instance = SmartFormValidationService._internal();
  factory SmartFormValidationService() => _instance;
  SmartFormValidationService._internal();

  final Map<String, FormValidationConfig> _configs = {};
  final Map<String, ValidationAnalytics> _analytics = {};
  final Map<String, Timer> _debounceTimers = {};
  final Map<String, BreachCheckResult> _breachCache = {};
  
  final StreamController<ValidationResult> _validationController = StreamController<ValidationResult>.broadcast();
  final StreamController<BreachCheckResult> _breachController = StreamController<BreachCheckResult>.broadcast();
  final StreamController<PasswordStrengthResult> _passwordController = StreamController<PasswordStrengthResult>.broadcast();

  Stream<ValidationResult> get validationStream => _validationController.stream;
  Stream<BreachCheckResult> get breachStream => _breachController.stream;
  Stream<PasswordStrengthResult> get passwordStrengthStream => _passwordController.stream;

  final Random _random = Random();
  final List<DataBreach> _knownBreaches = [];

  Future<void> initialize() async {
    developer.log('Initializing Smart Form Validation Service', name: 'SmartFormValidationService');
    
    _generateMockBreaches();
    _setupDefaultConfigs();
    
    developer.log('Smart Form Validation Service initialized', name: 'SmartFormValidationService');
  }

  void _generateMockBreaches() {
    _knownBreaches.addAll([
      DataBreach(
        id: 'breach_1',
        name: 'LinkedIn Data Breach',
        domain: 'linkedin.com',
        breachDate: DateTime(2012, 6, 5),
        affectedAccounts: 164000000,
        compromisedData: ['Email addresses', 'Passwords'],
        severity: 'high',
        description: 'In June 2012, LinkedIn suffered a data breach which exposed the passwords of 164 million users.',
        isVerified: true,
      ),
      DataBreach(
        id: 'breach_2',
        name: 'Yahoo Data Breach',
        domain: 'yahoo.com',
        breachDate: DateTime(2013, 8, 1),
        affectedAccounts: 3000000000,
        compromisedData: ['Email addresses', 'Passwords', 'Names', 'Phone numbers'],
        severity: 'critical',
        description: 'Yahoo disclosed a breach affecting all 3 billion user accounts.',
        isVerified: true,
      ),
      DataBreach(
        id: 'breach_3',
        name: 'Adobe Creative Cloud',
        domain: 'adobe.com',
        breachDate: DateTime(2013, 10, 3),
        affectedAccounts: 153000000,
        compromisedData: ['Email addresses', 'Passwords', 'Names', 'Credit cards'],
        severity: 'high',
        description: 'Adobe suffered a breach exposing 153 million user records.',
        isVerified: true,
      ),
      DataBreach(
        id: 'breach_4',
        name: 'Dropbox',
        domain: 'dropbox.com',
        breachDate: DateTime(2012, 7, 1),
        affectedAccounts: 68000000,
        compromisedData: ['Email addresses', 'Passwords'],
        severity: 'medium',
        description: 'Dropbox disclosed a breach affecting 68 million user accounts.',
        isVerified: true,
      ),
    ]);
  }

  void _setupDefaultConfigs() {
    // Login form config
    _configs['login_form'] = FormValidationConfig(
      formId: 'login_form',
      name: 'Login Form',
      fieldRules: {
        'email': [
          ValidationRule(
            id: 'email_required',
            type: ValidationRuleType.required,
            name: 'Email Required',
            description: 'Email address is required',
            isRequired: true,
          ),
          ValidationRule(
            id: 'email_format',
            type: ValidationRuleType.email,
            name: 'Valid Email',
            description: 'Must be a valid email address',
          ),
          ValidationRule(
            id: 'email_breach_check',
            type: ValidationRuleType.breach_check,
            name: 'Breach Check',
            description: 'Check if email was involved in known breaches',
          ),
        ],
        'password': [
          ValidationRule(
            id: 'password_required',
            type: ValidationRuleType.required,
            name: 'Password Required',
            description: 'Password is required',
            isRequired: true,
          ),
          ValidationRule(
            id: 'password_strength',
            type: ValidationRuleType.password_strength,
            name: 'Password Strength',
            description: 'Password must meet strength requirements',
            parameters: {'minScore': 3},
          ),
        ],
      },
    );

    // Registration form config
    _configs['register_form'] = FormValidationConfig(
      formId: 'register_form',
      name: 'Registration Form',
      fieldRules: {
        'email': [
          ValidationRule(
            id: 'email_required',
            type: ValidationRuleType.required,
            name: 'Email Required',
            description: 'Email address is required',
            isRequired: true,
          ),
          ValidationRule(
            id: 'email_format',
            type: ValidationRuleType.email,
            name: 'Valid Email',
            description: 'Must be a valid email address',
          ),
          ValidationRule(
            id: 'email_breach_check',
            type: ValidationRuleType.breach_check,
            name: 'Breach Check',
            description: 'Check if email was involved in known breaches',
          ),
        ],
        'password': [
          ValidationRule(
            id: 'password_required',
            type: ValidationRuleType.required,
            name: 'Password Required',
            description: 'Password is required',
            isRequired: true,
          ),
          ValidationRule(
            id: 'password_strength',
            type: ValidationRuleType.password_strength,
            name: 'Password Strength',
            description: 'Password must be strong',
            parameters: {'minScore': 4},
          ),
          ValidationRule(
            id: 'password_length',
            type: ValidationRuleType.length,
            name: 'Password Length',
            description: 'Password must be at least 8 characters',
            parameters: {'minLength': 8},
          ),
        ],
        'confirmPassword': [
          ValidationRule(
            id: 'confirm_password_required',
            type: ValidationRuleType.required,
            name: 'Confirm Password Required',
            description: 'Password confirmation is required',
            isRequired: true,
          ),
          ValidationRule(
            id: 'passwords_match',
            type: ValidationRuleType.custom,
            name: 'Passwords Match',
            description: 'Passwords must match',
            parameters: {'matchField': 'password'},
          ),
        ],
      },
    );
  }

  Future<ValidationResult> validateField(String formId, String fieldName, String value, {Map<String, String>? formData}) async {
    final config = _configs[formId];
    if (config == null) {
      return ValidationResult.error('Form configuration not found');
    }

    final rules = config.fieldRules[fieldName] ?? [];
    if (rules.isEmpty) {
      return ValidationResult.success();
    }

    // Track analytics
    _updateAnalytics(formId, fieldName, true);

    for (final rule in rules.where((r) => r.isEnabled)) {
      final result = await _validateRule(rule, value, formData);
      if (!result.isValid && rule.isRequired) {
        _updateAnalytics(formId, fieldName, false, rule.type);
        _validationController.add(result);
        return result;
      } else if (result.severity == ValidationSeverity.warning || result.severity == ValidationSeverity.error) {
        _validationController.add(result);
        if (!result.isValid) {
          _updateAnalytics(formId, fieldName, false, rule.type);
          return result;
        }
      }
    }

    return ValidationResult.success(message: 'Field is valid');
  }

  Future<ValidationResult> _validateRule(ValidationRule rule, String value, Map<String, String>? formData) async {
    switch (rule.type) {
      case ValidationRuleType.required:
        return _validateRequired(value);
      
      case ValidationRuleType.email:
        return _validateEmail(value);
      
      case ValidationRuleType.password_strength:
        return await _validatePasswordStrength(value, rule.parameters);
      
      case ValidationRuleType.breach_check:
        return await _validateBreachCheck(value);
      
      case ValidationRuleType.pattern:
        return _validatePattern(value, rule.parameters);
      
      case ValidationRuleType.length:
        return _validateLength(value, rule.parameters);
      
      case ValidationRuleType.custom:
        return _validateCustom(value, rule.parameters, formData);
      
      case ValidationRuleType.phone_number:
        return _validatePhoneNumber(value);
      
      case ValidationRuleType.url:
        return _validateUrl(value);
      
      case ValidationRuleType.credit_card:
        return _validateCreditCard(value);
      
      case ValidationRuleType.ssn:
        return _validateSSN(value);
    }
  }

  ValidationResult _validateRequired(String value) {
    if (value.trim().isEmpty) {
      return ValidationResult.error('This field is required');
    }
    return ValidationResult.success();
  }

  ValidationResult _validateEmail(String value) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return ValidationResult.error(
        'Please enter a valid email address',
        suggestion: 'Example: user@example.com',
      );
    }
    return ValidationResult.success();
  }

  Future<ValidationResult> _validatePasswordStrength(String value, Map<String, dynamic> parameters) async {
    final strengthResult = await checkPasswordStrength(value);
    final minScore = parameters['minScore'] ?? 3;
    
    if (strengthResult.score < minScore) {
      return ValidationResult.error(
        'Password is too weak (${strengthResult.level})',
        suggestion: strengthResult.suggestions.isNotEmpty ? strengthResult.suggestions.first : 'Use a stronger password',
      );
    } else if (strengthResult.score == minScore) {
      return ValidationResult.warning(
        'Password strength is acceptable but could be stronger',
        suggestion: strengthResult.suggestions.isNotEmpty ? strengthResult.suggestions.first : null,
      );
    }
    
    return ValidationResult.success(message: 'Password is strong');
  }

  Future<ValidationResult> _validateBreachCheck(String value) async {
    final breachResult = await checkDataBreach(value);
    
    if (breachResult.status == BreachStatus.compromised && breachResult.breaches.isNotEmpty) {
      final breachCount = breachResult.breaches.length;
      final latestBreach = breachResult.breaches.reduce((a, b) => a.breachDate.isAfter(b.breachDate) ? a : b);
      
      return ValidationResult.warning(
        'This email was found in $breachCount data breach${breachCount > 1 ? 'es' : ''}',
        suggestion: 'Consider using a different email or ensure your password is unique and strong',
      );
    }
    
    return ValidationResult.success(message: 'No known breaches found');
  }

  ValidationResult _validatePattern(String value, Map<String, dynamic> parameters) {
    final pattern = parameters['pattern'] as String?;
    if (pattern == null) return ValidationResult.success();
    
    final regex = RegExp(pattern);
    if (!regex.hasMatch(value)) {
      return ValidationResult.error(
        parameters['message'] ?? 'Value does not match required pattern',
        suggestion: parameters['suggestion'],
      );
    }
    return ValidationResult.success();
  }

  ValidationResult _validateLength(String value, Map<String, dynamic> parameters) {
    final minLength = parameters['minLength'] as int?;
    final maxLength = parameters['maxLength'] as int?;
    
    if (minLength != null && value.length < minLength) {
      return ValidationResult.error(
        'Must be at least $minLength characters long',
        suggestion: 'Add ${minLength - value.length} more character${minLength - value.length > 1 ? 's' : ''}',
      );
    }
    
    if (maxLength != null && value.length > maxLength) {
      return ValidationResult.error(
        'Must be no more than $maxLength characters long',
        suggestion: 'Remove ${value.length - maxLength} character${value.length - maxLength > 1 ? 's' : ''}',
      );
    }
    
    return ValidationResult.success();
  }

  ValidationResult _validateCustom(String value, Map<String, dynamic> parameters, Map<String, String>? formData) {
    final matchField = parameters['matchField'] as String?;
    if (matchField != null && formData != null) {
      final matchValue = formData[matchField];
      if (value != matchValue) {
        return ValidationResult.error(
          'Values do not match',
          suggestion: 'Ensure both fields contain the same value',
        );
      }
    }
    return ValidationResult.success();
  }

  ValidationResult _validatePhoneNumber(String value) {
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    if (!phoneRegex.hasMatch(value)) {
      return ValidationResult.error(
        'Please enter a valid phone number',
        suggestion: 'Example: +1 (555) 123-4567',
      );
    }
    return ValidationResult.success();
  }

  ValidationResult _validateUrl(String value) {
    final urlRegex = RegExp(r'^https?:\/\/[^\s]+$');
    if (!urlRegex.hasMatch(value)) {
      return ValidationResult.error(
        'Please enter a valid URL',
        suggestion: 'Example: https://www.example.com',
      );
    }
    return ValidationResult.success();
  }

  ValidationResult _validateCreditCard(String value) {
    final cleanValue = value.replaceAll(RegExp(r'\s|-'), '');
    if (cleanValue.length < 13 || cleanValue.length > 19) {
      return ValidationResult.error('Invalid credit card number length');
    }
    
    // Luhn algorithm check
    if (!_luhnCheck(cleanValue)) {
      return ValidationResult.error('Invalid credit card number');
    }
    
    return ValidationResult.success();
  }

  bool _luhnCheck(String cardNumber) {
    int sum = 0;
    bool alternate = false;
    
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    return sum % 10 == 0;
  }

  ValidationResult _validateSSN(String value) {
    final ssnRegex = RegExp(r'^\d{3}-?\d{2}-?\d{4}$');
    if (!ssnRegex.hasMatch(value)) {
      return ValidationResult.error(
        'Please enter a valid SSN',
        suggestion: 'Format: XXX-XX-XXXX',
      );
    }
    return ValidationResult.success();
  }

  Future<BreachCheckResult> checkDataBreach(String email) async {
    // Check cache first
    if (_breachCache.containsKey(email)) {
      final cached = _breachCache[email]!;
      if (DateTime.now().difference(cached.checkedAt).inHours < 24) {
        return cached;
      }
    }

    // Simulate API call delay
    await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(1000)));

    final matchingBreaches = <DataBreach>[];
    
    // Simulate breach checking logic
    if (_random.nextDouble() < 0.3) { // 30% chance of being in a breach
      final breachCount = 1 + _random.nextInt(3);
      for (int i = 0; i < breachCount; i++) {
        matchingBreaches.add(_knownBreaches[_random.nextInt(_knownBreaches.length)]);
      }
    }

    final result = BreachCheckResult(
      value: email,
      status: matchingBreaches.isNotEmpty ? BreachStatus.compromised : BreachStatus.safe,
      breaches: matchingBreaches,
      riskScore: matchingBreaches.isNotEmpty ? '${60 + _random.nextInt(40)}' : '${_random.nextInt(20)}',
      metadata: {
        'sources': ['HaveIBeenPwned', 'Internal DB'],
        'lastChecked': DateTime.now().toIso8601String(),
      },
    );

    _breachCache[email] = result;
    _breachController.add(result);
    
    return result;
  }

  Future<PasswordStrengthResult> checkPasswordStrength(String password) async {
    await Future.delayed(const Duration(milliseconds: 100));

    int score = 0;
    final suggestions = <String>[];
    final criteria = <String, bool>{};

    // Length check
    criteria['length'] = password.length >= 8;
    if (password.length >= 8) score++;
    else suggestions.add('Use at least 8 characters');

    // Uppercase check
    criteria['uppercase'] = password.contains(RegExp(r'[A-Z]'));
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    else suggestions.add('Add uppercase letters');

    // Lowercase check
    criteria['lowercase'] = password.contains(RegExp(r'[a-z]'));
    if (password.contains(RegExp(r'[a-z]'))) score++;
    else suggestions.add('Add lowercase letters');

    // Number check
    criteria['numbers'] = password.contains(RegExp(r'[0-9]'));
    if (password.contains(RegExp(r'[0-9]'))) score++;
    else suggestions.add('Add numbers');

    // Special character check
    criteria['special'] = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    else suggestions.add('Add special characters');

    // Common password check
    final commonPasswords = ['password', '123456', 'qwerty', 'abc123', 'password123'];
    criteria['not_common'] = !commonPasswords.contains(password.toLowerCase());
    if (!commonPasswords.contains(password.toLowerCase())) score++;
    else suggestions.add('Avoid common passwords');

    String level;
    Duration crackTime;
    String feedback;

    switch (score) {
      case 0:
      case 1:
        level = 'Very Weak';
        crackTime = const Duration(seconds: 1);
        feedback = 'This password is extremely vulnerable';
        break;
      case 2:
        level = 'Weak';
        crackTime = const Duration(minutes: 1);
        feedback = 'This password could be cracked quickly';
        break;
      case 3:
        level = 'Fair';
        crackTime = const Duration(hours: 1);
        feedback = 'This password provides basic protection';
        break;
      case 4:
        level = 'Good';
        crackTime = const Duration(days: 30);
        feedback = 'This password is reasonably secure';
        break;
      case 5:
        level = 'Strong';
        crackTime = const Duration(days: 365);
        feedback = 'This password is very secure';
        break;
      default:
        level = 'Very Strong';
        crackTime = const Duration(days: 3650);
        feedback = 'This password is excellent';
    }

    final result = PasswordStrengthResult(
      score: score,
      level: level,
      suggestions: suggestions,
      criteria: criteria,
      estimatedCrackTime: crackTime,
      feedback: feedback,
    );

    _passwordController.add(result);
    return result;
  }

  void _updateAnalytics(String formId, String fieldName, bool success, [ValidationRuleType? failedRule]) {
    final analytics = _analytics[formId] ?? ValidationAnalytics(formId: formId);
    
    final updatedAnalytics = ValidationAnalytics(
      formId: formId,
      totalValidations: analytics.totalValidations + 1,
      successfulValidations: analytics.successfulValidations + (success ? 1 : 0),
      failedValidations: analytics.failedValidations + (success ? 0 : 1),
      errorsByField: Map.from(analytics.errorsByField)
        ..update(fieldName, (value) => value + (success ? 0 : 1), ifAbsent: () => success ? 0 : 1),
      errorsByRule: failedRule != null 
        ? (Map.from(analytics.errorsByRule)..update(failedRule.name, (value) => value + 1, ifAbsent: () => 1))
        : analytics.errorsByRule,
      averageValidationTime: analytics.averageValidationTime, // Would be calculated from actual timing
      trends: analytics.trends,
    );
    
    _analytics[formId] = updatedAnalytics;
  }

  FormValidationConfig? getFormConfig(String formId) => _configs[formId];
  ValidationAnalytics? getFormAnalytics(String formId) => _analytics[formId];
  
  void setFormConfig(FormValidationConfig config) {
    _configs[config.formId] = config;
  }

  List<SmartValidationSuggestion> getSmartSuggestions(String formId, Map<String, String> formData) {
    final suggestions = <SmartValidationSuggestion>[];
    
    // Example smart suggestions based on form data
    formData.forEach((fieldName, value) {
      if (fieldName == 'email' && value.isNotEmpty) {
        if (value.contains('gmail.com') && !value.contains('+')) {
          suggestions.add(SmartValidationSuggestion(
            fieldName: fieldName,
            currentValue: value,
            suggestedValue: value.replaceFirst('@', '+tag@'),
            reason: 'Consider using email aliases for better organization',
            confidence: 0.7,
            triggerRule: ValidationRuleType.email,
          ));
        }
      }
    });
    
    return suggestions;
  }

  void dispose() {
    _debounceTimers.values.forEach((timer) => timer.cancel());
    _validationController.close();
    _breachController.close();
    _passwordController.close();
  }
}
