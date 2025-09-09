import 'package:flutter/foundation.dart';
import 'package:clean_flutter/features/admin/services/dynamic_workflow_service.dart';
import 'package:clean_flutter/locator.dart';

class PreflightResult {
  final String workflowId;
  final bool wouldSucceed;
  final List<String> warnings;
  final Map<String, dynamic> metrics; // e.g., estimated_duration_ms, steps, external_calls
  PreflightResult({
    required this.workflowId,
    required this.wouldSucceed,
    required this.warnings,
    required this.metrics,
  });
}

class BlastRadiusSimulation {
  final String workflowId;
  final int estimatedAffectedUsers;
  final int estimatedAffectedSessions;
  final int estimatedExternalCalls;
  final String riskLevel; // low/medium/high
  final Map<String, dynamic> details;
  BlastRadiusSimulation({
    required this.workflowId,
    required this.estimatedAffectedUsers,
    required this.estimatedAffectedSessions,
    required this.estimatedExternalCalls,
    required this.riskLevel,
    required this.details,
  });
}

class SafetyValidationService with ChangeNotifier {
  PreflightResult preflight(String workflowId, {Map<String, dynamic>? context}) {
    final dynamicWorkflowService = locator<DynamicWorkflowService>();
    final wf = dynamicWorkflowService.getById(workflowId);
    if (wf == null) {
      return PreflightResult(workflowId: workflowId, wouldSucceed: false, warnings: ['Workflow not found'], metrics: {});
    }

    final steps = wf.steps;
    final externalCalls = steps.where((s) => s.action.startsWith('network.') || s.action.startsWith('api.')).length;
    final riskySteps = steps.where((s) => s.action.contains('delete') || s.action.contains('block') || s.action.contains('revoke')).length;
    final estDurationMs = steps.length * 150; // rough estimate

    final warnings = <String>[];
    if (riskySteps > 0) warnings.add('Contains $riskySteps potentially destructive step(s).');
    if (externalCalls > 3) warnings.add('High number of external calls: $externalCalls');

    final wouldSucceed = true; // simulated environment OK
    return PreflightResult(
      workflowId: workflowId,
      wouldSucceed: wouldSucceed,
      warnings: warnings,
      metrics: {
        'steps': steps.length,
        'risky_steps': riskySteps,
        'external_calls': externalCalls,
        'estimated_duration_ms': estDurationMs,
      },
    );
  }

  BlastRadiusSimulation simulateBlastRadius(String workflowId, {Map<String, dynamic>? scope}) {
    final dynamicWorkflowService = locator<DynamicWorkflowService>();
    final wf = dynamicWorkflowService.getById(workflowId);
    if (wf == null) {
      return BlastRadiusSimulation(
        workflowId: workflowId,
        estimatedAffectedUsers: 0,
        estimatedAffectedSessions: 0,
        estimatedExternalCalls: 0,
        riskLevel: 'low',
        details: {'error': 'Workflow not found'},
      );
    }

    final steps = wf.steps;
    final scale = (scope?['canary_percent'] as num?)?.toDouble() ?? 100.0;
    final externalCalls = steps.where((s) => s.action.startsWith('network.') || s.action.startsWith('api.')).length;
    final affectsUsers = steps.where((s) => s.action.contains('user') || s.action.contains('auth')).length;

    final baseUsers = 50 + steps.length * 5;
    final baseSessions = 120 + steps.length * 10;
    final estUsers = (baseUsers * (scale / 100.0)).round();
    final estSessions = (baseSessions * (scale / 100.0)).round();

    String risk = 'low';
    final riskScore = (affectsUsers * 2) + (externalCalls) + (steps.length >= 6 ? 2 : 0);
    if (riskScore >= 6) risk = 'high'; else if (riskScore >= 3) risk = 'medium';

    return BlastRadiusSimulation(
      workflowId: workflowId,
      estimatedAffectedUsers: estUsers,
      estimatedAffectedSessions: estSessions,
      estimatedExternalCalls: (externalCalls * (scale / 100.0)).round(),
      riskLevel: risk,
      details: {
        'scale_percent': scale,
        'steps': steps.length,
        'affecting_steps': affectsUsers,
        'external_calls': externalCalls,
      },
    );
  }
}


