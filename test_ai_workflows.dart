import 'dart:async';
import 'package:clean_flutter/features/admin/services/ai_automation_workflows.dart';
import 'package:clean_flutter/features/admin/services/ai_models.dart';

void main() async {
  print('Testing AI Automation Workflows...\n');
  
  // Initialize the workflow service
  final workflowService = AIAutomationWorkflows();
  await workflowService.initialize();
  
  print('✓ Workflow service initialized');
  print('✓ Found ${workflowService.getWorkflows().length} predefined workflows\n');
  
  // List available workflows
  print('Available Workflows:');
  for (final workflow in workflowService.getWorkflows()) {
    print('  - ${workflow.name} (${workflow.type})');
    print('    ${workflow.description}');
    print('    Steps: ${workflow.steps.length}');
    print('    Enabled: ${workflow.enabled}');
    print('');
  }
  
  // Test workflow event stream
  print('Setting up event listeners...');
  
  final eventSubscription = workflowService.eventStream.listen((event) {
    print('[EVENT] ${event.type}: ${event.message}');
    if (event.data != null) {
      print('  Data: ${event.data}');
    }
  });
  
  final statusSubscription = workflowService.statusStream.listen((status) {
    print('[STATUS] Workflow ${status.workflowId}: ${status.status}');
    if (status.currentStep != null) {
      print('  Current Step: ${status.currentStep}');
    }
    if (status.progress > 0) {
      print('  Progress: ${(status.progress * 100).toStringAsFixed(0)}%');
    }
  });
  
  // Simulate a security threat to trigger reactive workflow
  print('\nSimulating high security threat to trigger workflow...');
  
  // Create a mock trigger condition
  final securityWorkflow = workflowService.getWorkflows().firstWhere(
    (w) => w.name.contains('Security'),
  );
  
  if (securityWorkflow.enabled) {
    print('Security Response Workflow is enabled. Triggering manually...');
    
    // Manually trigger the workflow for testing
    await workflowService.executeWorkflow(securityWorkflow.id, {
      'threatLevel': 'critical',
      'source': 'test_script',
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Wait for execution to complete
    await Future.delayed(Duration(seconds: 5));
  } else {
    print('Security Response Workflow is disabled. Enable it first to test execution.');
  }
  
  // Get execution history
  final history = workflowService.getExecutionHistory();
  if (history.isNotEmpty) {
    print('\nExecution History:');
    for (final execution in history.take(5)) {
      print('  - Workflow: ${execution.workflowId}');
      print('    Status: ${execution.status}');
      print('    Started: ${execution.startTime}');
      if (execution.endTime != null) {
        final duration = execution.endTime!.difference(execution.startTime);
        print('    Duration: ${duration.inSeconds}s');
      }
      if (execution.error != null) {
        print('    Error: ${execution.error}');
      }
      print('');
    }
  }
  
  // Test workflow statistics
  final stats = workflowService.getWorkflowStats();
  print('Workflow Statistics:');
  print('  Total Executions: ${stats['totalExecutions']}');
  print('  Successful: ${stats['successfulExecutions']}');
  print('  Failed: ${stats['failedExecutions']}');
  print('  Average Duration: ${stats['averageDuration']}ms');
  print('  Workflows by Type:');
  final byType = stats['executionsByType'] as Map<String, dynamic>;
  byType.forEach((type, count) {
    print('    $type: $count');
  });
  
  // Cleanup
  await eventSubscription.cancel();
  await statusSubscription.cancel();
  workflowService.dispose();
  
  print('\n✓ AI Workflow test completed successfully!');
}
