import 'package:flutter_test/flutter_test.dart';
import 'package:clean_flutter/features/admin/services/performance_monitoring_service.dart';

void main() {
  group('PerformanceMonitoringService Tests', () {
    late PerformanceMonitoringService service;

    setUp(() {
      service = PerformanceMonitoringService();
    });

    tearDown(() {
      service.dispose();
    });

    test('should initialize with mock data', () {
      expect(service.metrics.isNotEmpty, true);
      expect(service.slas.isNotEmpty, true);
      expect(service.capacityPlans.isNotEmpty, true);
      expect(service.alerts.isNotEmpty, true);
      expect(service.services.isNotEmpty, true);
    });

    test('should have services with health status', () {
      for (final svc in service.services) {
        expect(svc.name, isNotEmpty);
        expect(svc.status, isA<ServiceStatus>());
      }
    });

    test('should return performance summary', () {
      final summary = service.getPerformanceSummary();
      
      expect(summary['avgCpuUsage'], isA<double>());
      expect(summary['avgMemoryUsage'], isA<double>());
      expect(summary['totalAlerts'], isA<int>());
      expect(summary['criticalAlerts'], isA<int>());
      expect(summary['slaCompliance'], isA<double>());
      expect(summary['healthyServices'], isA<int>());
      
      // Validate ranges
      expect(summary['avgCpuUsage'], greaterThanOrEqualTo(0));
      expect(summary['avgCpuUsage'], lessThanOrEqualTo(100));
      expect(summary['slaCompliance'], greaterThanOrEqualTo(0));
      expect(summary['slaCompliance'], lessThanOrEqualTo(100));
    });

    test('should have unacknowledged alerts', () {
      // alerts getter only returns unacknowledged alerts
      expect(service.alerts, isA<List<PerformanceAlert>>());
      
      for (final alert in service.alerts) {
        expect(alert.acknowledged, false);
        expect(alert.id, isNotEmpty);
        expect(alert.severity, isA<AlertSeverity>());
      }
    });

    test('should track system metrics', () {
      for (final metric in service.metrics) {
        expect(metric.id, isNotEmpty);
        expect(metric.name, isNotEmpty);
        expect(metric.value, greaterThanOrEqualTo(0));
        expect(metric.unit, isNotEmpty);
        expect(metric.type, isA<MetricType>());
        expect(metric.status, isA<ServiceStatus>());
      }
    });

    test('should monitor SLA compliance', () {
      for (final sla in service.slas) {
        expect(sla.id, isNotEmpty);
        expect(sla.name, isNotEmpty);
        expect(sla.targetUptime, greaterThan(0));
        expect(sla.currentUptime, greaterThanOrEqualTo(0));
        expect(sla.isCompliant, isA<bool>());
      }
    });

    test('should track capacity planning', () {
      for (final plan in service.capacityPlans) {
        expect(plan.id, isNotEmpty);
        expect(plan.resource, isNotEmpty);
        expect(plan.currentUsage, greaterThanOrEqualTo(0));
        expect(plan.projectedUsage, greaterThanOrEqualTo(0));
        expect(plan.recommendation, isNotEmpty);
      }
    });

    test('should categorize alerts by severity', () {
      final criticalAlerts = service.alerts.where(
        (a) => a.severity == AlertSeverity.critical,
      ).toList();
      
      final errorAlerts = service.alerts.where(
        (a) => a.severity == AlertSeverity.error,
      ).toList();
      
      final warningAlerts = service.alerts.where(
        (a) => a.severity == AlertSeverity.warning,
      ).toList();
      
      // At least some alerts should exist
      expect(
        criticalAlerts.length + errorAlerts.length + warningAlerts.length,
        greaterThan(0),
      );
    });

    test('should track service health status', () {
      for (final health in service.services) {
        expect(health.name, isNotEmpty);
        expect(health.status, isA<ServiceStatus>());
        expect(health.uptime, greaterThanOrEqualTo(0));
        expect(health.uptime, lessThanOrEqualTo(100));
        expect(health.avgLatency, greaterThan(0));
        expect(health.errorRate, greaterThanOrEqualTo(0));
      }
    });

    test('should handle metric thresholds', () {
      final cpuMetric = service.metrics.firstWhere(
        (m) => m.type == MetricType.cpu,
      );
      
      // CPU threshold should affect status
      if (cpuMetric.value > 80) {
        expect(cpuMetric.status, equals(ServiceStatus.critical));
      } else if (cpuMetric.value > 60) {
        expect(cpuMetric.status, equals(ServiceStatus.degraded));
      } else {
        expect(cpuMetric.status, equals(ServiceStatus.healthy));
      }
    });
  });
}
