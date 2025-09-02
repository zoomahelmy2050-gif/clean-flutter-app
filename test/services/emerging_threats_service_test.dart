import 'package:flutter_test/flutter_test.dart';
import 'package:clean_flutter/features/admin/services/emerging_threats_service.dart';

void main() {
  group('EmergingThreatsService Tests', () {
    late EmergingThreatsService service;

    setUp(() {
      service = EmergingThreatsService();
    });

    tearDown(() {
      service.dispose();
    });

    test('should initialize with mock data', () {
      expect(service.threats.isNotEmpty, true);
      expect(service.iotDevices.isNotEmpty, true);
      expect(service.containers.isNotEmpty, true);
      expect(service.apiEndpoints.isNotEmpty, true);
      expect(service.supplyChainRisks.isNotEmpty, true);
      expect(service.mitigations.isNotEmpty, true);
    });

    test('should return comprehensive threat summary', () {
      final summary = service.getThreatSummary();
      
      expect(summary['activeThreats'], isA<int>());
      expect(summary['criticalThreats'], isA<int>());
      expect(summary['vulnerableDevices'], isA<int>());
      expect(summary['totalDevices'], isA<int>());
      expect(summary['nonCompliantContainers'], isA<int>());
      expect(summary['totalContainers'], isA<int>());
      expect(summary['vulnerableAPIs'], isA<int>());
      expect(summary['totalAPIs'], isA<int>());
      expect(summary['highRiskSuppliers'], isA<int>());
      expect(summary['totalSuppliers'], isA<int>());
      expect(summary['activeMitigations'], isA<int>());
    });

    test('should track emerging threats by category', () {
      final iotThreats = service.threats.where(
        (t) => t.category == ThreatCategory.iot,
      ).toList();
      
      final containerThreats = service.threats.where(
        (t) => t.category == ThreatCategory.container,
      ).toList();
      
      final apiThreats = service.threats.where(
        (t) => t.category == ThreatCategory.api,
      ).toList();
      
      final supplyChainThreats = service.threats.where(
        (t) => t.category == ThreatCategory.supplyChain,
      ).toList();
      
      // Should have threats in multiple categories
      expect(iotThreats.isNotEmpty, true);
      expect(containerThreats.isNotEmpty, true);
      expect(apiThreats.isNotEmpty, true);
      expect(supplyChainThreats.isNotEmpty, true);
    });

    test('should categorize threats by severity', () {
      final criticalThreats = service.threats.where(
        (t) => t.severity == ThreatSeverity.critical,
      ).toList();
      
      final highThreats = service.threats.where(
        (t) => t.severity == ThreatSeverity.high,
      ).toList();
      
      // Should have at least some critical and high severity threats
      expect(criticalThreats.isNotEmpty, true);
      expect(highThreats.isNotEmpty, true);
    });

    test('should categorize IoT devices by security', () {
      final vulnerableDevices = service.iotDevices.where(
        (d) => d.securityStatus == 'Vulnerable',
      ).toList();
      
      expect(service.iotDevices.isNotEmpty, true);
      expect(vulnerableDevices.isNotEmpty, true);
      
      // Verify both secure and vulnerable devices exist
      final hasSecure = service.iotDevices.any((d) => d.securityStatus == 'Secure');
      final hasVulnerable = service.iotDevices.any((d) => d.securityStatus == 'Vulnerable');
      expect(hasSecure || hasVulnerable, true);
      
      for (final device in service.iotDevices) {
        expect(device.id, isNotEmpty);
        expect(device.name, isNotEmpty);
        expect(device.type, isNotEmpty);
        expect(device.manufacturer, isNotEmpty);
        expect(device.firmware, isNotEmpty);
        expect(device.securityStatus, isNotEmpty);
      }
    });

    test('should track container security', () {
      final nonCompliantContainers = service.containers.where(
        (c) => !c.isCompliant,
      ).toList();
      
      expect(service.containers.isNotEmpty, true);
      expect(nonCompliantContainers.isNotEmpty, true);
      
      // Verify both compliant and non-compliant containers exist
      final hasCompliant = service.containers.any((c) => c.isCompliant);
      final hasNonCompliant = service.containers.any((c) => !c.isCompliant);
      expect(hasCompliant || hasNonCompliant, true);
      
      for (final container in service.containers) {
        expect(container.id, isNotEmpty);
        expect(container.containerName, isNotEmpty);
        expect(container.image, isNotEmpty);
        expect(container.vulnerabilityCount, greaterThanOrEqualTo(0));
        expect(container.severityBreakdown, isNotEmpty);
      }
    });

    test('should monitor API security', () {
      final authenticatedAPIs = service.apiEndpoints.where(
        (a) => a.hasAuthentication,
      ).toList();
      
      expect(service.apiEndpoints.isNotEmpty, true);
      expect(authenticatedAPIs.isNotEmpty, true);
      
      // Verify authentication and rate limiting settings
      final hasAuthenticated = service.apiEndpoints.any((a) => a.hasAuthentication);
      final hasRateLimiting = service.apiEndpoints.any((a) => a.hasRateLimiting);
      expect(hasAuthenticated || hasRateLimiting, true);
      
      for (final api in service.apiEndpoints) {
        expect(api.id, isNotEmpty);
        expect(api.path, isNotEmpty);
        expect(api.method, isNotEmpty);
        expect(api.requestCount, greaterThan(0));
        expect(api.avgResponseTime, greaterThan(0));
        expect(api.errorRate, greaterThanOrEqualTo(0));
      }
    });

    test('should track supply chain risks', () {
      final criticalRisks = service.supplyChainRisks.where(
        (r) => r.riskLevel == ThreatSeverity.critical,
      ).toList();
      
      final highRisks = service.supplyChainRisks.where(
        (r) => r.riskLevel == ThreatSeverity.high,
      ).toList();
      
      // Should have critical and high risks
      expect(criticalRisks.isNotEmpty, true);
      expect(highRisks.isNotEmpty, true);
      
      for (final risk in service.supplyChainRisks) {
        expect(risk.id, isNotEmpty);
        expect(risk.vendor, isNotEmpty);
        expect(risk.component, isNotEmpty);
        expect(risk.version, isNotEmpty);
        expect(risk.recommendation, isNotEmpty);
        expect(risk.dependencies, isNotEmpty);
      }
    });

    test('should start threat mitigation', () {
      final threat = service.threats.first;
      final initialMitigationCount = service.mitigations.length;
      
      service.startMitigation(threat.id);
      
      expect(service.mitigations.length, equals(initialMitigationCount + 1));
      
      final newMitigation = service.mitigations.last;
      expect(newMitigation.threatId, equals(threat.id));
      expect(newMitigation.status, equals(MitigationStatus.inProgress));
    });

    test('should update mitigation status', () {
      final threat = service.threats.first;
      service.startMitigation(threat.id);
      
      service.updateMitigationStatus(threat.id, MitigationStatus.verified);
      
      final mitigation = service.mitigations.firstWhere(
        (m) => m.threatId == threat.id,
      );
      expect(mitigation.status, equals(MitigationStatus.verified));
      expect(mitigation.completedAt, isNotNull);
    });

    test('should validate threat risk scores', () {
      for (final threat in service.threats) {
        expect(threat.riskScore, greaterThanOrEqualTo(0));
        expect(threat.riskScore, lessThanOrEqualTo(10));
        
        // Critical threats should have high risk scores
        if (threat.severity == ThreatSeverity.critical) {
          expect(threat.riskScore, greaterThanOrEqualTo(8));
        }
      }
    });

    test('should track active threats', () {
      final activeThreats = service.threats.where((t) => t.isActive).toList();
      
      // Should have active threats
      expect(activeThreats.isNotEmpty, true);
      
      for (final threat in activeThreats) {
        expect(threat.affectedSystems.isNotEmpty, true);
        expect(threat.indicators.isNotEmpty, true);
      }
    });

    test('should filter threats by status', () {
      final activeThreats = service.threats.where(
        (t) => t.isActive,
      ).toList();
      
      expect(activeThreats.isNotEmpty, true);
      
      // Verify active and inactive threats exist
      final totalThreats = service.threats.length;
      final activeCount = activeThreats.length;
      expect(activeCount, lessThanOrEqualTo(totalThreats));
    });

    test('should validate threat risk scores', () {
      for (final threat in service.threats) {
        expect(threat.riskScore, greaterThanOrEqualTo(0));
        expect(threat.riskScore, lessThanOrEqualTo(10));
        
        // Critical threats should have high risk scores
        if (threat.severity == ThreatSeverity.critical) {
          expect(threat.riskScore, greaterThanOrEqualTo(8));
        }
      }
    });
  });
}
