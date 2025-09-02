import 'package:flutter_test/flutter_test.dart';
import 'package:clean_flutter/features/admin/services/security_orchestration_service.dart';
import 'package:clean_flutter/features/admin/services/performance_monitoring_service.dart';
import 'package:clean_flutter/features/admin/services/emerging_threats_service.dart';

void main() {
  group('Security Services Verification', () {
    test('SecurityOrchestrationService initializes correctly', () {
      final service = SecurityOrchestrationService();
      
      expect(service.playbooks.isNotEmpty, true);
      expect(service.cases.isNotEmpty, true);
      expect(service.getActivePlaybooks().isNotEmpty, true);
      print('✓ SecurityOrchestrationService: PASSED');
    });
    
    test('PerformanceMonitoringService initializes correctly', () {
      final service = PerformanceMonitoringService();
      
      expect(service.metrics.isNotEmpty, true);
      expect(service.slas.isNotEmpty, true);
      expect(service.services.isNotEmpty, true);
      expect(service.alerts.isNotEmpty, true);
      print('✓ PerformanceMonitoringService: PASSED');
    });
    
    test('EmergingThreatsService initializes correctly', () {
      final service = EmergingThreatsService();
      
      expect(service.threats.isNotEmpty, true);
      expect(service.iotDevices.isNotEmpty, true);
      expect(service.containers.isNotEmpty, true);
      expect(service.apiEndpoints.isNotEmpty, true);
      print('✓ EmergingThreatsService: PASSED');
    });
  });
}
