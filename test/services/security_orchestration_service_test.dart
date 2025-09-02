import 'package:flutter_test/flutter_test.dart';
import 'package:clean_flutter/features/admin/services/security_orchestration_service.dart';

void main() {
  group('SecurityOrchestrationService Tests', () {
    late SecurityOrchestrationService service;

    setUp(() {
      service = SecurityOrchestrationService();
    });

    tearDown(() {
      service.dispose();
    });

    test('should initialize with mock data', () {
      expect(service.playbooks.isNotEmpty, true);
      expect(service.cases.isNotEmpty, true);
    });

    test('should have playbooks with correct structure', () {
      for (final playbook in service.playbooks) {
        expect(playbook.id, isNotEmpty);
        expect(playbook.name, isNotEmpty);
        expect(playbook.status, isA<PlaybookStatus>());
        expect(playbook.actions, isNotEmpty);
        expect(playbook.triggers, isA<Map<String, dynamic>>());
        expect(playbook.useCount, greaterThanOrEqualTo(0));
        expect(playbook.successRate, greaterThanOrEqualTo(0));
      }
    });

    test('should have cases with activities and evidence', () {
      for (final testCase in service.cases) {
        expect(testCase.id, isNotEmpty);
        expect(testCase.title, isNotEmpty);
        expect(testCase.status, isA<CaseStatus>());
        expect(testCase.priority, isA<CasePriority>());
        expect(testCase.activities, isNotEmpty);
        expect(testCase.evidence, isA<Map<String, dynamic>>());
        expect(testCase.affectedAssets, isA<List<String>>());
      }
    });

    test('should have different case priorities', () {
      final criticalCases = service.cases.where((c) => c.priority == CasePriority.critical).toList();
      final highCases = service.cases.where((c) => c.priority == CasePriority.high).toList();
      
      // Should have cases with different priorities
      expect(criticalCases.isNotEmpty || highCases.isNotEmpty, true);
    });

    test('should have cases with assignees', () {
      final assignedCases = service.cases.where((c) => c.assignee != null).toList();
      
      expect(assignedCases.isNotEmpty, true);
      for (final testCase in assignedCases) {
        expect(testCase.assignee, isNotEmpty);
      }
    });

    test('should filter cases by status', () {
      final openCases = service.cases.where((c) => c.status == CaseStatus.open).toList();
      final investigatingCases = service.cases.where((c) => c.status == CaseStatus.investigating).toList();
      
      expect(openCases.isNotEmpty, true);
      expect(investigatingCases.isNotEmpty, true);
    });

    test('should track playbook success rates', () {
      for (final playbook in service.playbooks) {
        expect(playbook.successRate, greaterThanOrEqualTo(0));
        expect(playbook.successRate, lessThanOrEqualTo(1));
      }
    });

    test('should handle playbook triggers', () {
      final playbook = service.playbooks.first;
      
      expect(playbook.triggers, isA<Map<String, dynamic>>());
      expect(playbook.triggers.isNotEmpty, true);
    });

    test('should manage playbook actions', () {
      final playbook = service.playbooks.first;
      
      expect(playbook.actions.isNotEmpty, true);
      
      for (final action in playbook.actions) {
        expect(action.id, isNotEmpty);
        expect(action.name, isNotEmpty);
        expect(action.type, isA<ActionType>());
      }
    });

    test('should track case activities', () {
      for (final testCase in service.cases) {
        expect(testCase.activities, isNotEmpty);
        
        for (final activity in testCase.activities) {
          expect(activity.id, isNotEmpty);
          expect(activity.caseId, equals(testCase.id));
          expect(activity.action, isNotEmpty);
          expect(activity.performedBy, isNotEmpty);
          expect(activity.timestamp, isA<DateTime>());
        }
      }
    });
  });
}
