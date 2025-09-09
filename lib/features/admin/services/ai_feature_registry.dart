import '../../../core/models/rbac_models.dart';

/// Comprehensive registry of all app features and their AI command mappings
class AIFeatureRegistry {
  static final Map<String, FeatureDefinition> features = {
    // Authentication & User Management
    'auth.login': FeatureDefinition(
      id: 'auth.login',
      name: 'User Login',
      category: FeatureCategory.authentication,
      description: 'Authenticate user with credentials',
      commands: ['login', 'sign in', 'authenticate'],
      parameters: {
        'email': ParameterDefinition(type: String, required: true),
        'password': ParameterDefinition(type: String, required: true, sensitive: true),
        'mfa_code': ParameterDefinition(type: String, required: false),
      },
      permissions: [UserRole.user],
      impact: ImpactLevel.low,
      requiresConfirmation: false,
    ),
    'auth.logout': FeatureDefinition(
      id: 'auth.logout',
      name: 'User Logout',
      category: FeatureCategory.authentication,
      description: 'Sign out current user',
      commands: ['logout', 'sign out', 'disconnect'],
      parameters: {},
      permissions: [UserRole.user],
      impact: ImpactLevel.low,
      requiresConfirmation: false,
    ),
    'auth.register': FeatureDefinition(
      id: 'auth.register',
      name: 'User Registration',
      category: FeatureCategory.authentication,
      description: 'Register new user account',
      commands: ['register', 'sign up', 'create account'],
      parameters: {
        'email': ParameterDefinition(type: String, required: true),
        'password': ParameterDefinition(type: String, required: true, sensitive: true),
        'name': ParameterDefinition(type: String, required: true),
        'role': ParameterDefinition(type: String, required: false, defaultValue: 'user'),
      },
      permissions: [UserRole.admin],
      impact: ImpactLevel.medium,
      requiresConfirmation: true,
    ),
    'auth.reset_password': FeatureDefinition(
      id: 'auth.reset_password',
      name: 'Password Reset',
      category: FeatureCategory.authentication,
      description: 'Reset user password',
      commands: ['reset password', 'forgot password', 'change password'],
      parameters: {
        'email': ParameterDefinition(type: String, required: true),
        'new_password': ParameterDefinition(type: String, required: false, sensitive: true),
      },
      permissions: [UserRole.user],
      impact: ImpactLevel.medium,
      requiresConfirmation: true,
    ),
    'auth.enable_mfa': FeatureDefinition(
      id: 'auth.enable_mfa',
      name: 'Enable MFA',
      category: FeatureCategory.authentication,
      description: 'Enable multi-factor authentication',
      commands: ['enable mfa', 'enable two factor', 'activate 2fa'],
      parameters: {
        'method': ParameterDefinition(type: String, required: true, values: ['sms', 'totp', 'email']),
      },
      permissions: [UserRole.user],
      impact: ImpactLevel.high,
      requiresConfirmation: true,
    ),

    // User Management
    'users.list': FeatureDefinition(
      id: 'users.list',
      name: 'List Users',
      category: FeatureCategory.userManagement,
      description: 'Display all users in the system',
      commands: ['show users', 'list users', 'get all users'],
      parameters: {
        'filter': ParameterDefinition(type: String, required: false),
        'role': ParameterDefinition(type: String, required: false),
        'status': ParameterDefinition(type: String, required: false),
      },
      permissions: [UserRole.admin],
      impact: ImpactLevel.low,
      requiresConfirmation: false,
    ),
    'users.create': FeatureDefinition(
      id: 'users.create',
      name: 'Create User',
      category: FeatureCategory.userManagement,
      description: 'Create new user account',
      commands: ['create user', 'add user', 'new user'],
      parameters: {
        'email': ParameterDefinition(type: String, required: true),
        'name': ParameterDefinition(type: String, required: true),
        'role': ParameterDefinition(type: String, required: true, values: ['user', 'admin', 'superadmin']),
        'department': ParameterDefinition(type: String, required: false),
      },
      permissions: [UserRole.admin],
      impact: ImpactLevel.high,
      requiresConfirmation: true,
    ),
    'users.update': FeatureDefinition(
      id: 'users.update',
      name: 'Update User',
      category: FeatureCategory.userManagement,
      description: 'Update user information',
      commands: ['update user', 'modify user', 'edit user'],
      parameters: {
        'user_id': ParameterDefinition(type: String, required: true),
        'name': ParameterDefinition(type: String, required: false),
        'role': ParameterDefinition(type: String, required: false),
        'status': ParameterDefinition(type: String, required: false),
      },
      permissions: [UserRole.admin],
      impact: ImpactLevel.medium,
      requiresConfirmation: true,
    ),
    'users.delete': FeatureDefinition(
      id: 'users.delete',
      name: 'Delete User',
      category: FeatureCategory.userManagement,
      description: 'Remove user from system',
      commands: ['delete user', 'remove user', 'deactivate user'],
      parameters: {
        'user_id': ParameterDefinition(type: String, required: true),
        'reason': ParameterDefinition(type: String, required: false),
      },
      permissions: [UserRole.superuser],
      impact: ImpactLevel.critical,
      requiresConfirmation: true,
    ),
    'users.suspend': FeatureDefinition(
      id: 'users.suspend',
      name: 'Suspend User',
      category: FeatureCategory.userManagement,
      description: 'Temporarily suspend user access',
      commands: ['suspend user', 'block user', 'disable user'],
      parameters: {
        'user_id': ParameterDefinition(type: String, required: true),
        'duration': ParameterDefinition(type: int, required: false),
        'reason': ParameterDefinition(type: String, required: true),
      },
      permissions: [UserRole.admin],
      impact: ImpactLevel.high,
      requiresConfirmation: true,
    ),

    // Security Features
    'security.scan': FeatureDefinition(
      id: 'security.scan',
      name: 'Security Scan',
      category: FeatureCategory.security,
      description: 'Run comprehensive security scan',
      commands: ['run security scan', 'check security', 'scan for threats'],
      parameters: {
        'scan_type': ParameterDefinition(type: String, required: false, values: ['full', 'quick', 'custom']),
        'target': ParameterDefinition(type: String, required: false),
      },
      permissions: [UserRole.admin],
      impact: ImpactLevel.low,
      requiresConfirmation: false,
    ),
    'security.block_threat': FeatureDefinition(
      id: 'security.block_threat',
      name: 'Block Threat',
      category: FeatureCategory.security,
      description: 'Block identified security threat',
      commands: ['block threat', 'quarantine threat', 'isolate threat'],
      parameters: {
        'threat_id': ParameterDefinition(type: String, required: true),
        'action': ParameterDefinition(type: String, required: true, values: ['block', 'quarantine', 'delete']),
      },
      permissions: [UserRole.admin],
      impact: ImpactLevel.critical,
      requiresConfirmation: true,
    ),
    'security.update_firewall': FeatureDefinition(
      id: 'security.update_firewall',
      name: 'Update Firewall',
      category: FeatureCategory.security,
      description: 'Modify firewall rules',
      commands: ['update firewall', 'change firewall rules', 'configure firewall'],
      parameters: {
        'rule_type': ParameterDefinition(type: String, required: true, values: ['allow', 'deny']),
        'target': ParameterDefinition(type: String, required: true),
        'port': ParameterDefinition(type: int, required: false),
        'protocol': ParameterDefinition(type: String, required: false),
      },
      permissions: [UserRole.superuser],
      impact: ImpactLevel.critical,
      requiresConfirmation: true,
    ),
    'security.incident_response': FeatureDefinition(
      id: 'security.incident_response',
      name: 'Incident Response',
      category: FeatureCategory.security,
      description: 'Initiate incident response protocol',
      commands: ['respond to incident', 'handle security incident', 'activate incident response'],
      parameters: {
        'incident_id': ParameterDefinition(type: String, required: true),
        'severity': ParameterDefinition(type: String, required: true, values: ['critical', 'high', 'medium', 'low']),
        'response_type': ParameterDefinition(type: String, required: true),
      },
      permissions: [UserRole.admin],
      impact: ImpactLevel.high,
      requiresConfirmation: true,
    ),

    // Monitoring & Analytics
    'monitoring.view_metrics': FeatureDefinition(
      id: 'monitoring.view_metrics',
      name: 'View Metrics',
      category: FeatureCategory.monitoring,
      description: 'Display system metrics and performance data',
      commands: ['show metrics', 'view performance', 'display statistics'],
      parameters: {
        'metric_type': ParameterDefinition(type: String, required: false),
        'time_range': ParameterDefinition(type: String, required: false),
      },
      permissions: [UserRole.user],
      impact: ImpactLevel.low,
      requiresConfirmation: false,
    ),
    'monitoring.set_alert': FeatureDefinition(
      id: 'monitoring.set_alert',
      name: 'Set Alert',
      category: FeatureCategory.monitoring,
      description: 'Configure monitoring alert',
      commands: ['set alert', 'create alert', 'configure notification'],
      parameters: {
        'metric': ParameterDefinition(type: String, required: true),
        'threshold': ParameterDefinition(type: double, required: true),
        'condition': ParameterDefinition(type: String, required: true, values: ['above', 'below', 'equals']),
        'notification_channel': ParameterDefinition(type: String, required: true),
      },
      permissions: [UserRole.admin],
      impact: ImpactLevel.medium,
      requiresConfirmation: true,
    ),
    'monitoring.generate_report': FeatureDefinition(
      id: 'monitoring.generate_report',
      name: 'Generate Report',
      category: FeatureCategory.monitoring,
      description: 'Create monitoring or analytics report',
      commands: ['generate report', 'create report', 'export data'],
      parameters: {
        'report_type': ParameterDefinition(type: String, required: true),
        'start_date': ParameterDefinition(type: DateTime, required: false),
        'end_date': ParameterDefinition(type: DateTime, required: false),
        'format': ParameterDefinition(type: String, required: false, values: ['pdf', 'csv', 'json']),
      },
      permissions: [UserRole.admin],
      impact: ImpactLevel.low,
      requiresConfirmation: false,
    ),

    // Compliance & Policy
    'compliance.check': FeatureDefinition(
      id: 'compliance.check',
      name: 'Compliance Check',
      category: FeatureCategory.compliance,
      description: 'Run compliance verification',
      commands: ['check compliance', 'verify compliance', 'audit compliance'],
      parameters: {
        'standard': ParameterDefinition(type: String, required: true, values: ['gdpr', 'hipaa', 'pci-dss', 'sox']),
        'scope': ParameterDefinition(type: String, required: false),
      },
      permissions: [UserRole.admin],
      impact: ImpactLevel.low,
      requiresConfirmation: false,
    ),
    'compliance.update_policy': FeatureDefinition(
      id: 'compliance.update_policy',
      name: 'Update Policy',
      category: FeatureCategory.compliance,
      description: 'Modify compliance policy',
      commands: ['update policy', 'change policy', 'modify rules'],
      parameters: {
        'policy_id': ParameterDefinition(type: String, required: true),
        'changes': ParameterDefinition(type: Map, required: true),
        'effective_date': ParameterDefinition(type: DateTime, required: false),
      },
      permissions: [UserRole.superuser],
      impact: ImpactLevel.critical,
      requiresConfirmation: true,
    ),

    // Workflow Management
    'workflow.create': FeatureDefinition(
      id: 'workflow.create',
      name: 'Create Workflow',
      category: FeatureCategory.workflow,
      description: 'Create new automated workflow',
      commands: ['create workflow', 'new automation', 'build workflow'],
      parameters: {
        'name': ParameterDefinition(type: String, required: true),
        'trigger': ParameterDefinition(type: String, required: true),
        'actions': ParameterDefinition(type: List, required: true),
        'schedule': ParameterDefinition(type: String, required: false),
      },
      permissions: [UserRole.admin],
      impact: ImpactLevel.medium,
      requiresConfirmation: true,
    ),
    'workflow.execute': FeatureDefinition(
      id: 'workflow.execute',
      name: 'Execute Workflow',
      category: FeatureCategory.workflow,
      description: 'Run existing workflow',
      commands: ['run workflow', 'execute automation', 'trigger workflow'],
      parameters: {
        'workflow_id': ParameterDefinition(type: String, required: true),
        'parameters': ParameterDefinition(type: Map, required: false),
      },
      permissions: [UserRole.user],
      impact: ImpactLevel.medium,
      requiresConfirmation: false,
    ),
    'workflow.schedule': FeatureDefinition(
      id: 'workflow.schedule',
      name: 'Schedule Workflow',
      category: FeatureCategory.workflow,
      description: 'Schedule workflow execution',
      commands: ['schedule workflow', 'set automation timer', 'configure schedule'],
      parameters: {
        'workflow_id': ParameterDefinition(type: String, required: true),
        'cron_expression': ParameterDefinition(type: String, required: true),
        'enabled': ParameterDefinition(type: bool, required: false, defaultValue: true),
      },
      permissions: [UserRole.admin],
      impact: ImpactLevel.medium,
      requiresConfirmation: true,
    ),

    // System Administration
    'system.backup': FeatureDefinition(
      id: 'system.backup',
      name: 'System Backup',
      category: FeatureCategory.system,
      description: 'Create system backup',
      commands: ['backup system', 'create backup', 'save configuration'],
      parameters: {
        'backup_type': ParameterDefinition(type: String, required: false, values: ['full', 'incremental', 'differential']),
        'destination': ParameterDefinition(type: String, required: false),
      },
      permissions: [UserRole.superuser],
      impact: ImpactLevel.high,
      requiresConfirmation: true,
    ),
    'system.restore': FeatureDefinition(
      id: 'system.restore',
      name: 'System Restore',
      category: FeatureCategory.system,
      description: 'Restore from backup',
      commands: ['restore system', 'restore backup', 'recover data'],
      parameters: {
        'backup_id': ParameterDefinition(type: String, required: true),
        'restore_point': ParameterDefinition(type: DateTime, required: false),
      },
      permissions: [UserRole.superuser],
      impact: ImpactLevel.critical,
      requiresConfirmation: true,
    ),
    'system.optimize': FeatureDefinition(
      id: 'system.optimize',
      name: 'System Optimization',
      category: FeatureCategory.system,
      description: 'Optimize system performance',
      commands: ['optimize system', 'improve performance', 'clean system'],
      parameters: {
        'optimization_type': ParameterDefinition(type: String, required: false, values: ['memory', 'storage', 'cpu', 'all']),
        'aggressive': ParameterDefinition(type: bool, required: false, defaultValue: false),
      },
      permissions: [UserRole.admin],
      impact: ImpactLevel.medium,
      requiresConfirmation: true,
    ),
    'system.settings': FeatureDefinition(
      id: 'system.settings',
      name: 'System Settings',
      category: FeatureCategory.system,
      description: 'Modify system configuration',
      commands: ['change settings', 'update configuration', 'modify system'],
      parameters: {
        'setting': ParameterDefinition(type: String, required: true),
        'value': ParameterDefinition(type: dynamic, required: true),
      },
      permissions: [UserRole.admin],
      impact: ImpactLevel.high,
      requiresConfirmation: true,
    ),

    // Forensics & Investigation
    'forensics.investigate': FeatureDefinition(
      id: 'forensics.investigate',
      name: 'Forensic Investigation',
      category: FeatureCategory.forensics,
      description: 'Start forensic investigation',
      commands: ['investigate', 'analyze incident', 'forensic analysis'],
      parameters: {
        'target': ParameterDefinition(type: String, required: true),
        'time_range': ParameterDefinition(type: String, required: false),
        'depth': ParameterDefinition(type: String, required: false, values: ['basic', 'detailed', 'comprehensive']),
      },
      permissions: [UserRole.admin],
      impact: ImpactLevel.low,
      requiresConfirmation: false,
    ),
    'forensics.collect_evidence': FeatureDefinition(
      id: 'forensics.collect_evidence',
      name: 'Collect Evidence',
      category: FeatureCategory.forensics,
      description: 'Gather forensic evidence',
      commands: ['collect evidence', 'gather logs', 'preserve data'],
      parameters: {
        'source': ParameterDefinition(type: String, required: true),
        'evidence_type': ParameterDefinition(type: String, required: true),
        'chain_of_custody': ParameterDefinition(type: bool, required: false, defaultValue: true),
      },
      permissions: [UserRole.admin],
      impact: ImpactLevel.medium,
      requiresConfirmation: true,
    ),

    // Data Management
    'data.export': FeatureDefinition(
      id: 'data.export',
      name: 'Export Data',
      category: FeatureCategory.data,
      description: 'Export system data',
      commands: ['export data', 'download data', 'extract information'],
      parameters: {
        'data_type': ParameterDefinition(type: String, required: true),
        'format': ParameterDefinition(type: String, required: true, values: ['json', 'csv', 'xml', 'excel']),
        'filters': ParameterDefinition(type: Map, required: false),
      },
      permissions: [UserRole.admin],
      impact: ImpactLevel.low,
      requiresConfirmation: false,
    ),
    'data.import': FeatureDefinition(
      id: 'data.import',
      name: 'Import Data',
      category: FeatureCategory.data,
      description: 'Import data into system',
      commands: ['import data', 'upload data', 'load information'],
      parameters: {
        'file_path': ParameterDefinition(type: String, required: true),
        'data_type': ParameterDefinition(type: String, required: true),
        'validation': ParameterDefinition(type: bool, required: false, defaultValue: true),
      },
      permissions: [UserRole.admin],
      impact: ImpactLevel.high,
      requiresConfirmation: true,
    ),
    'data.purge': FeatureDefinition(
      id: 'data.purge',
      name: 'Purge Data',
      category: FeatureCategory.data,
      description: 'Permanently delete data',
      commands: ['purge data', 'delete permanently', 'clean data'],
      parameters: {
        'data_type': ParameterDefinition(type: String, required: true),
        'older_than': ParameterDefinition(type: DateTime, required: false),
        'confirm_deletion': ParameterDefinition(type: bool, required: true),
      },
      permissions: [UserRole.superuser],
      impact: ImpactLevel.critical,
      requiresConfirmation: true,
    ),
  };

  /// Get feature by ID
  static FeatureDefinition? getFeature(String featureId) {
    return features[featureId];
  }

  /// Find features by command
  static List<FeatureDefinition> findByCommand(String command) {
    final normalizedCommand = command.toLowerCase();
    return features.values.where((feature) {
      return feature.commands.any((cmd) => 
        normalizedCommand.contains(cmd.toLowerCase()) ||
        cmd.toLowerCase().contains(normalizedCommand)
      );
    }).toList();
  }

  /// Get features by category
  static List<FeatureDefinition> getByCategory(FeatureCategory category) {
    return features.values
        .where((feature) => feature.category == category)
        .toList();
  }

  /// Get features by permission level
  static List<FeatureDefinition> getByPermission(UserRole role) {
    return features.values
        .where((feature) => feature.permissions.contains(role))
        .toList();
  }

  /// Validate parameters for a feature
  static Map<String, dynamic> validateParameters(
    String featureId,
    Map<String, dynamic> providedParams,
  ) {
    final feature = features[featureId];
    if (feature == null) {
      throw Exception('Feature not found: $featureId');
    }

    final validatedParams = <String, dynamic>{};
    final errors = <String, String>{};

    // Check required parameters
    feature.parameters.forEach((key, definition) {
      final value = providedParams[key];
      
      if (definition.required && value == null) {
        errors[key] = 'Required parameter missing';
      } else if (value != null) {
        // Type validation
        if (definition.type != dynamic && value.runtimeType != definition.type) {
          errors[key] = 'Invalid type. Expected ${definition.type}';
        }
        // Value validation
        else if (definition.values != null && !definition.values!.contains(value)) {
          errors[key] = 'Invalid value. Must be one of: ${definition.values!.join(', ')}';
        } else {
          validatedParams[key] = value;
        }
      } else if (definition.defaultValue != null) {
        validatedParams[key] = definition.defaultValue;
      }
    });

    if (errors.isNotEmpty) {
      throw ValidationException(errors);
    }

    return validatedParams;
  }

  /// Get feature suggestions based on context
  static List<FeatureDefinition> getSuggestions({
    String? context,
    UserRole? userRole,
    FeatureCategory? category,
    int limit = 5,
  }) {
    var suggestions = features.values.toList();

    // Filter by user role
    if (userRole != null) {
      suggestions = suggestions
          .where((f) => f.permissions.contains(userRole))
          .toList();
    }

    // Filter by category
    if (category != null) {
      suggestions = suggestions
          .where((f) => f.category == category)
          .toList();
    }

    // Sort by relevance/frequency (simplified)
    suggestions.sort((a, b) => a.impact.index.compareTo(b.impact.index));

    return suggestions.take(limit).toList();
  }
}

/// Feature definition model
class FeatureDefinition {
  final String id;
  final String name;
  final FeatureCategory category;
  final String description;
  final List<String> commands;
  final Map<String, ParameterDefinition> parameters;
  final List<UserRole> permissions;
  final ImpactLevel impact;
  final bool requiresConfirmation;
  final Map<String, dynamic>? metadata;

  const FeatureDefinition({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.commands,
    required this.parameters,
    required this.permissions,
    required this.impact,
    required this.requiresConfirmation,
    this.metadata,
  });
}

/// Parameter definition for features
class ParameterDefinition {
  final String name;
  final String description;
  final Type type;
  final bool required;
  final dynamic defaultValue;
  final List<dynamic>? values;
  final bool sensitive;

  const ParameterDefinition({
    this.name = '',
    this.description = '',
    required this.type,
    required this.required,
    this.defaultValue,
    this.values,
    this.sensitive = false,
  });
}

/// Feature categories
enum FeatureCategory {
  authentication,
  userManagement,
  security,
  monitoring,
  compliance,
  workflow,
  system,
  forensics,
  data,
  analytics,
  reporting,
}

/// Impact levels for actions
enum ImpactLevel {
  low,
  medium,
  high,
  critical,
}

/// Validation exception
class ValidationException implements Exception {
  final Map<String, String> errors;

  ValidationException(this.errors);

  @override
  String toString() => 'Validation errors: ${errors.entries.map((e) => '${e.key}: ${e.value}').join(', ')}';
}
