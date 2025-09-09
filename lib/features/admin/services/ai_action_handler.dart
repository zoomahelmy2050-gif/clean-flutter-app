import 'dart:async';
import 'package:get_it/get_it.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/services/performance_monitoring_service.dart';
import '../../../core/services/real_time_monitoring_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/models/rbac_models.dart';
import 'ai_action_executor.dart';
import 'ai_feature_registry.dart';
import 'ai_enhanced_auth_service.dart';
import 'ai_monitoring_integration.dart';
import 'ai_workflow_automation.dart';
import 'ai_sync_integration.dart';
import 'ai_models.dart' hide WorkflowStep;

/// Comprehensive action handler for AI assistant
class AIActionHandler {
  final AuthService _authService;
  final PerformanceMonitoringService _performanceService;
  final AIActionExecutor _actionExecutor;
  
  // Enhanced services
  late final AIEnhancedAuthService _enhancedAuthService;
  late final AIMonitoringIntegration _monitoringIntegration;
  late final AIWorkflowAutomation _workflowAutomation;
  late final AISyncIntegration _syncIntegration;
  
  // Execution tracking
  final Map<String, ActionExecution> _executionHistory = {};
  final Map<String, ActionContext> _contextMap = {};
  
  AIActionHandler({
    required AuthService authService,
    required PerformanceMonitoringService performanceService,
    required AIActionExecutor actionExecutor,
  }) : _authService = authService,
       _performanceService = performanceService,
       _actionExecutor = actionExecutor {
    // Initialize enhanced services
    _enhancedAuthService = AIEnhancedAuthService(authService);
    
    final locator = GetIt.instance;
    _monitoringIntegration = AIMonitoringIntegration(
      monitoringService: locator<RealTimeMonitoringService>(),
      syncService: locator<SyncService>(),
    );
    
    _workflowAutomation = AIWorkflowAutomation();
    
    _syncIntegration = AISyncIntegration(
      syncService: locator<SyncService>(),
    );
  }

  /// Execute action based on feature ID and parameters
  Future<ActionResult> executeAction({
    required String featureId,
    required Map<String, dynamic> parameters,
    required UserRole userRole,
    String? userId,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Get feature definition
      final feature = AIFeatureRegistry.getFeature(featureId);
      if (feature == null) {
        return ActionResult(
          success: false,
          error: 'Feature not found: $featureId',
        );
      }

      // Check permissions
      if (!_hasPermission(feature, userRole)) {
        return ActionResult(
          success: false,
          error: 'Insufficient permissions for action: ${feature.name}',
        );
      }

      // Validate parameters
      final validatedParams = AIFeatureRegistry.validateParameters(
        featureId,
        parameters,
      );

      // Create execution record
      final execution = ActionExecution(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        featureId: featureId,
        parameters: validatedParams,
        userId: userId,
        timestamp: DateTime.now(),
        status: ExecutionStatus.pending,
      );
      
      // Store execution in history (if needed)

      // Execute based on category
      ActionResult result;
      switch (feature.category) {
        case FeatureCategory.authentication:
          result = await _handleAuthAction(feature, validatedParams);
          break;
        case FeatureCategory.userManagement:
          result = await _handleUserManagementAction(feature, validatedParams);
          break;
        case FeatureCategory.security:
          result = await _handleSecurityAction(feature, validatedParams);
          break;
        case FeatureCategory.monitoring:
          result = await _handleMonitoringAction(feature, validatedParams);
          break;
        case FeatureCategory.compliance:
          result = await _handleComplianceAction(feature, validatedParams);
          break;
        case FeatureCategory.workflow:
          result = await _handleWorkflowAction(feature, validatedParams);
          break;
        case FeatureCategory.system:
          result = await _handleSystemAction(feature, validatedParams);
          break;
        case FeatureCategory.forensics:
          result = await _handleForensicsAction(feature, validatedParams);
          break;
        case FeatureCategory.data:
          result = await _handleDataAction(feature, validatedParams);
          break;
        default:
          result = ActionResult(
            success: false,
            error: 'Unsupported category: ${feature.category}',
          );
      }

      // Update execution status
      execution.status = result.success 
          ? ExecutionStatus.completed 
          : ExecutionStatus.failed;
      execution.result = result;

      return result;
    } catch (e) {
      return ActionResult(
        success: false,
        error: 'Action execution failed: $e',
      );
    }
  }

  /// Handle authentication actions
  Future<ActionResult> _handleAuthAction(
    FeatureDefinition feature,
    Map<String, dynamic> params,
  ) async {
    switch (feature.id) {
      case 'auth.login':
        return await _handleLogin(params);
        
      case 'auth.logout':
        await _authService.logout();
        return ActionResult(
          success: true,
          message: 'Logout successful',
        );
        
      case 'auth.register':
        return await _handleRegister(params);
        
      case 'auth.reset_password':
        return await _handlePasswordReset(params);
        
      case 'auth.enable_mfa':
        return await _handleEnableMFA(params);
        
      default:
        return ActionResult(
          success: false,
          error: 'Unknown auth action: ${feature.id}',
        );
    }
  }

  Future<ActionResult> _handleLogin(Map<String, dynamic> params) async {
    try {
      final email = params['email'] as String?;
      final password = params['password'] as String?;
      
      if (email == null || password == null) {
        return ActionResult(
          success: false,
          message: 'Email and password are required',
        );
      }
      
      final user = await _authService.login(email, password);
      
      return ActionResult(
        success: true,
        message: 'Login successful',
        data: {'user': user},
      );
    } catch (e) {
      return ActionResult(
        success: false,
        message: 'Login error: $e',
      );
    }
  }

  Future<ActionResult> _handleRegister(Map<String, dynamic> params) async {
    try {
      final email = params['email'] as String?;
      final password = params['password'] as String?;
      
      if (email == null || password == null) {
        return ActionResult(
          success: false,
          message: 'Email and password are required',
        );
      }
      
      final user = await _authService.register(email, password);
      
      return ActionResult(
        success: true,
        message: 'Registration successful',
        data: {'user': user},
      );
    } catch (e) {
      return ActionResult(
        success: false,
        message: 'Registration error: $e',
      );
    }
  }

  Future<ActionResult> _handlePasswordReset(Map<String, dynamic> params) async {
    try {
      final email = params['email'] as String?;
      if (email == null) {
        return ActionResult(
          success: false,
          message: 'Email is required for password reset',
        );
      }
      
      final success = await _enhancedAuthService.resetPassword(
        email: email,
        newPassword: params['newPassword'] as String?,
        token: params['token'] as String?,
      );
      
      return ActionResult(
        success: success,
        message: success 
          ? 'Password reset email sent' 
          : 'Password reset failed',
      );
    } catch (e) {
      return ActionResult(
        success: false,
        message: 'Password reset error: $e',
      );
    }
  }

  Future<ActionResult> _handleEnableMFA(Map<String, dynamic> params) async {
    try {
      final userId = params['userId'] as String? ?? 'current_user';
      final type = params['type'] as String? ?? 'totp';
      
      final mfaType = MFAType.values.firstWhere(
        (t) => t.toString().split('.').last == type,
        orElse: () => MFAType.totp,
      );
      
      final result = await _enhancedAuthService.enableMFA(
        userId: userId,
        type: mfaType,
      );
      
      return ActionResult(
        success: true,
        message: 'MFA setup initiated',
        data: {
          'qrCode': result.qrCode,
          'backupCodes': result.backupCodes,
        },
      );
    } catch (e) {
      return ActionResult(
        success: false,
        message: 'MFA setup error: $e',
      );
    }
  }

  /// Handle user management actions
  Future<ActionResult> _handleUserManagementAction(
    FeatureDefinition feature,
    Map<String, dynamic> params,
  ) async {
    switch (feature.id) {
      case 'users.create':
        return await _handleCreateUser(params);
        
      case 'users.update':
        // User update not implemented in base auth service
        return ActionResult(
          success: false,
          message: 'User update not yet implemented',
        );
        
      case 'users.delete':
        // User deletion not implemented in base auth service
        return ActionResult(
          success: false,
          message: 'User deletion not yet implemented',
        );
        
      case 'users.suspend':
        // User suspension not implemented in base auth service
        return ActionResult(
          success: false,
          message: 'User suspension not yet implemented',
        );
        
      case 'users.list':
        return await _handleListUsers(params);
        
      default:
        return ActionResult(
          success: false,
          error: 'Unknown user management action: ${feature.id}',
        );
    }
  }

  Future<ActionResult> _handleCreateUser(Map<String, dynamic> params) async {
    try {
      final email = params['email'] as String?;
      final password = params['password'] as String?;
      final role = params['role'] as String?;
      
      if (email == null || password == null || role == null) {
        return ActionResult(
          success: false,
          message: 'Email, password, and role are required',
        );
      }
      
      final user = await _enhancedAuthService.createUser(
        email: email,
        password: password,
        role: role,
        metadata: params['metadata'] as Map<String, dynamic>?,
      );
      
      return ActionResult(
        success: user != null,
        message: user != null 
          ? 'User created successfully' 
          : 'Failed to create user',
        data: user != null ? {'user': user} : null,
      );
    } catch (e) {
      return ActionResult(
        success: false,
        message: 'Create user error: $e',
      );
    }
  }

  Future<ActionResult> _handleListUsers(Map<String, dynamic> params) async {
    try {
      final users = await _enhancedAuthService.listUsers(
        role: params['role'] as String?,
        active: params['active'] as bool?,
        limit: params['limit'] as int?,
        offset: params['offset'] as int?,
      );
      
      return ActionResult(
        success: true,
        message: 'Found ${users.length} users',
        data: {'users': users},
      );
    } catch (e) {
      return ActionResult(
        success: false,
        message: 'List users error: $e',
      );
    }
  }

  /// Handle security actions
  Future<ActionResult> _handleSecurityAction(
    FeatureDefinition feature,
    Map<String, dynamic> params,
  ) async {
    switch (feature.id) {
      case 'security.scan':
        // Security scan not implemented yet
        return ActionResult(
          success: false,
          message: 'Security scan not yet implemented',
        );
        
      case 'security.block_threat':
        // Threat blocking not implemented yet
        return ActionResult(
          success: false,
          message: 'Threat blocking not yet implemented',
        );
        
      case 'security.update_firewall':
        // Firewall update not implemented yet
        return ActionResult(
          success: false,
          message: 'Firewall update not yet implemented',
        );
        
      case 'security.incident_response':
        // Incident response not implemented yet
        return ActionResult(
          success: false,
          message: 'Incident response not yet implemented',
        );
        
      default:
        return ActionResult(
          success: false,
          error: 'Unknown security action: ${feature.id}',
        );
    }
  }

  /// Handle monitoring actions
  Future<ActionResult> _handleMonitoringAction(
    FeatureDefinition feature,
    Map<String, dynamic> params,
  ) async {
    switch (feature.id) {
      case 'monitoring.performance_metrics':
        final metrics = await _performanceService.getMetrics();
        return ActionResult(
          success: true,
          data: {'metrics': metrics},
          message: 'Performance metrics retrieved',
        );
        
      case 'monitoring.set_alert':
        return await _handleSetAlert(params);
        
      case 'monitoring.device_status':
        return await _handleGetDeviceStatus(params);
        
      case 'monitoring.system_health':
        return await _handleGetSystemHealth(params);
        
      case 'monitoring.api_response_times':
        return await _handleMonitorAPIResponseTimes(params);
        
      case 'monitoring.generate_report':
        // Report generation not implemented yet
        return ActionResult(
          success: false,
          message: 'Report generation not yet implemented',
        );
        
      default:
        return ActionResult(
          success: false,
          error: 'Unknown monitoring action: ${feature.id}',
        );
    }
  }

  // Monitoring action handlers  
  Future<ActionResult> _handleGetDeviceStatus(Map<String, dynamic> params) async {
    try {
      final deviceId = params['deviceId'] as String?;
      
      if (deviceId != null) {
        final status = await _monitoringIntegration.getDeviceStatus(deviceId);
        return ActionResult(
          success: true,
          message: 'Device status retrieved',
          data: {'status': status},
        );
      } else {
        final statuses = await _monitoringIntegration.getAllDeviceStatuses();
        return ActionResult(
          success: true,
          message: 'All devices status retrieved',
          data: {'statuses': statuses},
        );
      }
    } catch (e) {
      return ActionResult(
        success: false,
        message: 'Failed to get device status: $e',
      );
    }
  }
  
  Future<ActionResult> _handleGetSystemHealth(Map<String, dynamic> params) async {
    try {
      final dashboard = await _monitoringIntegration.getSystemHealthDashboard();
      return ActionResult(
        success: true,
        message: 'System health dashboard retrieved',
        data: {'dashboard': dashboard},
      );
    } catch (e) {
      return ActionResult(
        success: false,
        message: 'Failed to get system health: $e',
      );
    }
  }
  
  Future<ActionResult> _handleSetAlert(Map<String, dynamic> params) async {
    try {
      final metric = params['metric'] as String?;
      final threshold = (params['threshold'] as num?)?.toDouble();
      final deviceId = params['deviceId'] as String? ?? 'system';
      
      if (metric == null || threshold == null) {
        return ActionResult(
          success: false,
          message: 'Metric and threshold are required',
        );
      }
      
      final monitorId = await _monitoringIntegration.startDeviceMonitoring(
        deviceId: deviceId,
        thresholds: {metric: threshold},
      );
      
      return ActionResult(
        success: true,
        message: 'Alert configured',
        data: {'monitorId': monitorId},
      );
    } catch (e) {
      return ActionResult(
        success: false,
        message: 'Failed to set alert: $e',
      );
    }
  }
  
  Future<ActionResult> _handleMonitorAPIResponseTimes(Map<String, dynamic> params) async {
    try {
      final endpoint = params['endpoint'] as String? ?? '/api';
      final duration = params['duration'] != null 
        ? Duration(seconds: params['duration'] as int)
        : null;
      
      final result = await _monitoringIntegration.monitorAPIResponseTimes(
        endpoint: endpoint,
        duration: duration,
      );
      
      return ActionResult(
        success: true,
        message: 'API monitoring complete',
        data: {'result': result},
      );
    } catch (e) {
      return ActionResult(
        success: false,
        message: 'Failed to monitor API: $e',
      );
    }
  }

  /// Handle analytics actions
  Future<ActionResult> _handleComplianceAction(
    FeatureDefinition feature,
    Map<String, dynamic> params,
  ) async {
    switch (feature.id) {
      case 'compliance.check':
        final action = AIAction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'run_compliance_check',
          description: 'Running compliance check',
          parameters: params,
          status: 'pending',
        );
        final executedAction = await _actionExecutor.executeAction(action);
        final result = executedAction.result ?? {};
        return ActionResult(
          success: result['success'] ?? false,
          message: result['message'] ?? 'Compliance check completed',
          data: result,
        );
        
      case 'compliance.update_policy':
        final action = AIAction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'update_policy',
          description: 'Updating policy',
          parameters: params,
          status: 'pending',
        );
        final executedAction = await _actionExecutor.executeAction(action);
        final result = executedAction.result ?? {};
        return ActionResult(
          success: result['success'] ?? false,
          message: result['message'] ?? 'Policy updated',
          data: result,
        );
        
      default:
        return ActionResult(
          success: false,
          error: 'Unknown compliance action: ${feature.id}',
        );
    }
  }

  /// Handle workflow actions
  Future<ActionResult> _handleWorkflowAction(
    FeatureDefinition feature,
    Map<String, dynamic> params,
  ) async {
    switch (feature.id) {
      case 'workflow.create':
        try {
          final name = params['name'] as String? ?? 'Workflow';
          final description = params['description'] as String? ?? '';
          final steps = (params['steps'] as List? ?? []).map((step) {
            final stepData = step as Map<String, dynamic>;
            return WorkflowStep(
              name: stepData['name'] ?? '',
              action: stepData['action'] ?? '',
              parameters: stepData['parameters'] ?? {},
            );
          }).toList();
          
          final workflowId = await _workflowAutomation.createWorkflow(
            name: name,
            description: description,
            steps: steps,
          );
          
          return ActionResult(
            success: true,
            message: 'Workflow created',
            data: {'workflowId': workflowId},
          );
        } catch (e) {
          return ActionResult(
            success: false,
            message: 'Failed to create workflow: $e',
          );
        }
        
      case 'workflow.execute':
        try {
          final workflowId = params['workflowId'] as String?;
          if (workflowId == null) {
            return ActionResult(
              success: false,
              message: 'Workflow ID is required',
            );
          }
          
          final result = await _workflowAutomation.executeWorkflow(workflowId);
          return ActionResult(
            success: true,
            message: 'Workflow execution complete',
            data: {'result': result},
          );
        } catch (e) {
          return ActionResult(
            success: false,
            message: 'Failed to execute workflow: $e',
          );
        }
        
      case 'workflow.schedule':
        try {
          final workflowId = params['workflowId'] as String?;
          final scheduledTime = params['scheduledTime'] != null
            ? DateTime.parse(params['scheduledTime'] as String)
            : DateTime.now().add(Duration(hours: 1));
          
          if (workflowId == null) {
            return ActionResult(
              success: false,
              message: 'Workflow ID is required',
            );
          }
          
          await _workflowAutomation.scheduleWorkflow(
            workflowId: workflowId,
            scheduledTime: scheduledTime,
          );
          
          return ActionResult(
            success: true,
            message: 'Workflow scheduled',
          );
        } catch (e) {
          return ActionResult(
            success: false,
            message: 'Failed to schedule workflow: $e',
          );
        }
        
      case 'workflow.cancel':
        try {
          final workflowId = params['workflowId'] as String?;
          if (workflowId == null) {
            return ActionResult(
              success: false,
              message: 'Workflow ID is required',
            );
          }
          
          // Cancel workflow implementation
          return ActionResult(
            success: true,
            message: 'Workflow cancellation not yet implemented',
          );
        } catch (e) {
          return ActionResult(
            success: false,
            message: 'Failed to cancel workflow: $e',
          );
        }
        
      default:
        return ActionResult(
          success: false,
          error: 'Unknown workflow action: ${feature.id}',
        );
    }
  }

  /// Handle system actions
  Future<ActionResult> _handleSystemAction(
    FeatureDefinition feature,
    Map<String, dynamic> params,
  ) async {
    switch (feature.id) {
      case 'system.backup':
        try {
          final deviceId = params['deviceId'] as String? ?? 'default';
          final backupName = params['backupName'] as String?;
          
          // Create backup using sync integration
          final backupId = await _syncIntegration.backupDeviceConfiguration(
            deviceId: deviceId,
            backupName: backupName,
            compress: true,
          );
          
          return ActionResult(
            success: true,
            message: 'Backup created successfully',
            data: {
              'deviceId': deviceId,
              'backupId': backupId,
              'backupName': backupName ?? 'Auto backup',
            },
          );
        } catch (e) {
          return ActionResult(
            success: false,
            message: 'Failed to create backup: $e',
          );
        }
        
      case 'system.restore':
        try {
          final deviceId = params['deviceId'] as String? ?? 'default';
          final backupId = params['backupId'] as String?;
          
          if (backupId == null) {
            return ActionResult(
              success: false,
              message: 'Backup ID is required for system restore',
            );
          }
          
          // Restore device configuration
          final success = await _syncIntegration.restoreDeviceConfiguration(
            deviceId: deviceId,
            backupId: backupId,
            validateFirst: true,
          );
          
          return ActionResult(
            success: success,
            message: success 
                ? 'System restored successfully'
                : 'Failed to restore system',
            data: {
              'deviceId': deviceId,
              'backupId': backupId,
            },
          );
        } catch (e) {
          return ActionResult(
            success: false,
            message: 'Failed to restore system: $e',
          );
        }
        
      case 'system.optimize':
        final action = AIAction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'optimize_system',
          description: 'Optimizing system',
          parameters: params,
          status: 'pending',
        );
        final executedAction = await _actionExecutor.executeAction(action);
        final result = executedAction.result ?? {};
        return ActionResult(
          success: result['success'] ?? false,
          data: result,
          message: 'System optimization completed',
        );
        
      case 'system.settings':
        final action = AIAction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'update_settings',
          description: 'Updating settings',
          parameters: params,
          status: 'pending',
        );
        final executedAction = await _actionExecutor.executeAction(action);
        final result = executedAction.result ?? {};
        return ActionResult(
          success: result['success'] ?? false,
          message: 'Settings updated successfully',
        );
        
      default:
        return ActionResult(
          success: false,
          error: 'Unknown system action: ${feature.id}',
        );
    }
  }

  /// Handle forensics actions
  Future<ActionResult> _handleForensicsAction(
    FeatureDefinition feature,
    Map<String, dynamic> params,
  ) async {
    switch (feature.id) {
      case 'forensics.investigate':
        // Forensics not implemented yet
        return ActionResult(
          success: false,
          message: 'Forensics investigation not yet implemented',
        );
        
      case 'forensics.collect_evidence':
        // Evidence collection not implemented yet
        return ActionResult(
          success: false,
          message: 'Evidence collection not yet implemented',
        );
        
      default:
        return ActionResult(
          success: false,
          error: 'Unknown forensics action: ${feature.id}',
        );
    }
  }

  /// Handle data actions
  Future<ActionResult> _handleDataAction(
    FeatureDefinition feature,
    Map<String, dynamic> params,
  ) async {
    switch (feature.id) {
      case 'data.export':
        final action = AIAction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'export_data',
          description: 'Exporting data',
          parameters: params,
          status: 'pending',
        );
        final executedAction = await _actionExecutor.executeAction(action);
        final exportPath = executedAction.result?['path'] ?? '';
        return ActionResult(
          success: exportPath != null,
          data: {'export_path': exportPath},
          message: 'Data exported successfully',
        );
        
      case 'data.import':
        final action = AIAction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'import_data',
          description: 'Importing data',
          parameters: params,
          status: 'pending',
        );
        final executedAction = await _actionExecutor.executeAction(action);
        final success = executedAction.result?['success'] ?? false;
        return ActionResult(
          success: success,
          message: 'Data imported successfully',
        );
        
      case 'data.purge':
        final action = AIAction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'purge_data',
          description: 'Purging data',
          parameters: params,
          status: 'pending',
        );
        final executedAction = await _actionExecutor.executeAction(action);
        final success = executedAction.result?['success'] ?? false;
        return ActionResult(
          success: success,
          message: 'Data purged successfully',
        );
        
      default:
        return ActionResult(
          success: false,
          error: 'Unknown data action: ${feature.id}',
        );
    }
  }

  /// Check if user has permission for action
  bool _hasPermission(FeatureDefinition feature, UserRole userRole) {
    // Check if user role is in allowed permissions
    if (feature.permissions.contains(userRole)) {
      return true;
    }
    
    // Check role hierarchy
    switch (userRole) {
      case UserRole.superuser:
        return true; // Superuser can do everything
      case UserRole.admin:
        return !feature.permissions.contains(UserRole.superuser);
      case UserRole.staff:
        return feature.permissions.contains(UserRole.staff) || 
               feature.permissions.contains(UserRole.user);
      case UserRole.user:
        return feature.permissions.contains(UserRole.user);
    }
  }

  /// Get action suggestions based on context
  Future<List<ActionSuggestion>> getSuggestions({
    required String context,
    required UserRole userRole,
    int limit = 5,
  }) async {
    final suggestions = <ActionSuggestion>[];
    
    // Find relevant features based on context
    final features = AIFeatureRegistry.findByCommand(context);
    
    for (final feature in features.take(limit)) {
      if (_hasPermission(feature, userRole)) {
        suggestions.add(ActionSuggestion(
          featureId: feature.id,
          title: feature.name,
          description: feature.description,
          category: feature.category,
          confidence: _calculateConfidence(context, feature),
        ));
      }
    }
    
    // Sort by confidence
    suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    return suggestions;
  }

  /// Calculate confidence score for suggestion
  double _calculateConfidence(String context, FeatureDefinition feature) {
    final normalizedContext = context.toLowerCase();
    double score = 0.0;
    
    // Check command matches
    for (final command in feature.commands) {
      if (normalizedContext.contains(command.toLowerCase())) {
        score += 0.5;
      }
    }
    
    // Check category relevance
    if (normalizedContext.contains(feature.category.name)) {
      score += 0.3;
    }
    
    // Check description relevance
    final descWords = feature.description.toLowerCase().split(' ');
    for (final word in descWords) {
      if (normalizedContext.contains(word) && word.length > 3) {
        score += 0.1;
      }
    }
    
    return score.clamp(0.0, 1.0);
  }

  /// Get execution history
  List<ActionExecution> getHistory({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) {
    var history = _executionHistory.values.toList();
    
    // Filter by user
    if (userId != null) {
      history = history.where((e) => e.userId == userId).toList();
    }
    
    // Filter by date range
    if (startDate != null) {
      history = history.where((e) => e.timestamp.isAfter(startDate)).toList();
    }
    if (endDate != null) {
      history = history.where((e) => e.timestamp.isBefore(endDate)).toList();
    }
    
    // Sort by timestamp (newest first)
    history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // Apply limit
    if (limit != null && history.length > limit) {
      history = history.take(limit).toList();
    }
    
    return history;
  }

  /// Get action context
  ActionContext? getContext(String actionId) {
    return _contextMap[actionId];
  }

  /// Save action context
  void saveContext(String actionId, ActionContext context) {
    _contextMap[actionId] = context;
  }
}

/// Action result model
class ActionResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? message;
  final String? error;
  final List<String>? warnings;

  ActionResult({
    required this.success,
    this.data,
    this.message,
    this.error,
    this.warnings,
  });
}

/// Action execution record
class ActionExecution {
  final String id;
  final String featureId;
  final Map<String, dynamic> parameters;
  final String? userId;
  final DateTime timestamp;
  ExecutionStatus status;
  ActionResult? result;

  ActionExecution({
    required this.id,
    required this.featureId,
    required this.parameters,
    this.userId,
    required this.timestamp,
    required this.status,
    this.result,
  });
}

/// Execution status
enum ExecutionStatus {
  pending,
  running,
  completed,
  failed,
  cancelled,
}

/// Action suggestion
class ActionSuggestion {
  final String featureId;
  final String title;
  final String description;
  final FeatureCategory category;
  final double confidence;

  ActionSuggestion({
    required this.featureId,
    required this.title,
    required this.description,
    required this.category,
    required this.confidence,
  });
}

/// Action context for maintaining state
class ActionContext {
  final String actionId;
  final Map<String, dynamic> state;
  final List<String> history;
  final DateTime created;
  DateTime? lastModified;

  ActionContext({
    required this.actionId,
    required this.state,
    List<String>? history,
    DateTime? created,
  })  : history = history ?? [],
        created = created ?? DateTime.now();

  void updateState(String key, dynamic value) {
    state[key] = value;
    lastModified = DateTime.now();
  }

  void addHistory(String entry) {
    history.add(entry);
    lastModified = DateTime.now();
  }
}
