import 'package:clean_flutter/features/admin/services/dynamic_workflow_service.dart';

class WorkflowNlpService {
  DynamicWorkflow generateFromPrompt({
    required String id,
    required String name,
    required String prompt,
  }) {
    final lower = prompt.toLowerCase();
    final steps = <DynamicWorkflowStep>[];

    bool addedAny = false;
    if (lower.contains('isolate') || lower.contains('quarantine')) {
      steps.add(DynamicWorkflowStep(
        id: 'isolate',
        name: 'Isolate Threat',
        action: 'security.isolate_threat',
        onSuccess: 'analyze',
        onFailure: 'alert',
      ));
      addedAny = true;
    }
    if (lower.contains('analy') || lower.contains('investigate')) {
      steps.add(DynamicWorkflowStep(
        id: 'analyze',
        name: 'Analyze Threat',
        action: 'security.deep_analysis',
        onSuccess: 'mitigate',
        onFailure: 'alert',
      ));
      addedAny = true;
    }
    if (lower.contains('mitigat') || lower.contains('contain')) {
      steps.add(DynamicWorkflowStep(
        id: 'mitigate',
        name: 'Apply Mitigation',
        action: 'security.apply_mitigation',
        onSuccess: 'report',
        onFailure: 'alert',
      ));
      addedAny = true;
    }
    if (lower.contains('report') || lower.contains('summary')) {
      steps.add(DynamicWorkflowStep(
        id: 'report',
        name: 'Generate Report',
        action: 'reporting.incident_report',
        onSuccess: null,
        onFailure: 'alert',
      ));
      addedAny = true;
    }

    if (lower.contains('alert') || lower.contains('notify')) {
      steps.add(DynamicWorkflowStep(
        id: 'alert',
        name: 'Alert Administrators',
        action: 'notification.alert_admins',
        parameters: {'priority': 'high'},
        onSuccess: null,
        onFailure: null,
      ));
      addedAny = true;
    }

    if (!addedAny) {
      steps.add(DynamicWorkflowStep(
        id: 'analyze',
        name: 'Analyze Threat',
        action: 'security.deep_analysis',
        onSuccess: 'report',
        onFailure: 'alert',
      ));
      steps.add(DynamicWorkflowStep(
        id: 'report',
        name: 'Generate Report',
        action: 'reporting.incident_report',
        onSuccess: null,
        onFailure: 'alert',
      ));
      steps.add(DynamicWorkflowStep(
        id: 'alert',
        name: 'Alert Administrators',
        action: 'notification.alert_admins',
        parameters: {'priority': 'normal'},
        onSuccess: null,
        onFailure: null,
      ));
    }

    // Chain missing onSuccess where possible
    for (int i = 0; i < steps.length - 1; i++) {
      if (steps[i].onSuccess == null) {
        steps[i] = DynamicWorkflowStep(
          id: steps[i].id,
          name: steps[i].name,
          action: steps[i].action,
          parameters: steps[i].parameters,
          conditions: steps[i].conditions,
          onSuccess: steps[i + 1].id,
          onFailure: steps[i].onFailure,
        );
      }
    }

    return DynamicWorkflow(
      id: id,
      name: name,
      description: 'Generated from prompt',
      steps: steps,
      triggers: {'type': 'manual'},
      metadata: {'source': 'nlp', 'prompt': prompt},
    );
  }
}
