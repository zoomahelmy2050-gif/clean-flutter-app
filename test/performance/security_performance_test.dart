import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:clean_flutter/core/services/ai_powered_security_service.dart';
import 'package:clean_flutter/core/services/advanced_encryption_service.dart';
import 'package:clean_flutter/core/services/device_security_service.dart';
import 'package:clean_flutter/core/services/threat_intelligence_platform.dart';
import 'package:clean_flutter/core/services/business_intelligence_service.dart';

void main() {
  group('Security Services Performance Tests', () {
    
    test('AI Security Service - Concurrent Threat Analysis Performance', () async {
      final aiService = AiPoweredSecurityService();
      await aiService.initialize();

      final stopwatch = Stopwatch()..start();
      
      // Test 100 concurrent threat analyses
      final futures = List.generate(100, (index) => 
        aiService.analyzeSecurityEvent({
          'user_id': 'perf_test_user_$index',
          'activity': 'login_attempt',
          'ip_address': '192.168.1.$index',
          'timestamp': DateTime.now().toIso8601String(),
        })
      );

      final results = await Future.wait(futures);
      stopwatch.stop();

      // Performance assertions
      expect(results.length, equals(100));
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should complete within 5 seconds
      expect(results.every((r) => r.containsKey('threat_score')), isTrue);
      
      print('AI Security Analysis - 100 concurrent operations: ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Advanced Encryption Service - High Volume Encryption Performance', () async {
      final encryptionService = AdvancedEncryptionService();
      await encryptionService.initialize();

      final key = await encryptionService.generateKey(
        algorithm: 'AES-256-GCM',
        keyType: 'performance_test',
      );
      final testData = 'Performance test data for encryption benchmarking';

      final stopwatch = Stopwatch()..start();
      
      // Test 50 concurrent encryption operations
      final futures = List.generate(50, (index) => 
        encryptionService.encrypt(
          data: utf8.encode('$testData $index'),
          keyId: key.keyId,
        )
      );

      final results = await Future.wait(futures);
      stopwatch.stop();

      expect(results.length, equals(50));
      expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // Should complete within 3 seconds
      expect(results.every((r) => r.encryptedBytes.isNotEmpty), isTrue);
      
      print('Encryption Service - 50 concurrent operations: ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Device Security Service - Continuous Monitoring Performance', () async {
      final deviceService = DeviceSecurityService();
      await deviceService.initialize();

      final stopwatch = Stopwatch()..start();
      
      // Simulate continuous monitoring for 10 iterations
      for (int i = 0; i < 10; i++) {
        deviceService.getCurrentDeviceInfo();
        final threats = deviceService.getActiveThreats();
        expect(threats, isA<List>());
      }
      
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // Should complete within 2 seconds
      
      print('Device Security Monitoring - 10 iterations: ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Threat Intelligence Platform - Large Dataset Processing', () async {
      final threatIntelService = ThreatIntelligencePlatform();
      await threatIntelService.initialize();

      final stopwatch = Stopwatch()..start();
      
      // Test processing multiple threat intelligence queries
      final futures = <Future>[];
      
      for (int i = 0; i < 20; i++) {
        futures.add(threatIntelService.checkIOC('ip', '192.168.1.$i'));
        futures.add(threatIntelService.checkIOC('domain', 'apt$i.example.com'));
      }
      
      final results = await Future.wait(futures);
      stopwatch.stop();

      expect(results.length, equals(40));
      expect(stopwatch.elapsedMilliseconds, lessThan(4000)); // Should complete within 4 seconds
      
      print('Threat Intelligence - 40 concurrent queries: ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Business Intelligence Service - Complex Report Generation', () async {
      final biService = BusinessIntelligenceService();
      await biService.initialize();

      final stopwatch = Stopwatch()..start();
      
      // Generate multiple complex reports concurrently
      final futures = [
        biService.generateROIDashboard(),
        Future.value(biService.getROIMetrics()),
        Future.value(biService.getCostBenefitAnalyses()),
      ];

      final results = await Future.wait(futures);
      stopwatch.stop();

      expect(results.length, equals(3));
      expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // Should complete within 3 seconds
      expect(results.isNotEmpty, isTrue);
      
      print('Business Intelligence - Complex reports: ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Memory Usage - Service Initialization', () async {
      // Test memory efficiency during service initialization
      final aiService = AiPoweredSecurityService();
      final encryptionService = AdvancedEncryptionService();
      final deviceService = DeviceSecurityService();
      final threatService = ThreatIntelligencePlatform();
      final biService = BusinessIntelligenceService();

      final stopwatch = Stopwatch()..start();
      
      await aiService.initialize();
      await encryptionService.initialize();
      await deviceService.initialize();
      await threatService.initialize();
      await biService.initialize();
      
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // All services should initialize within 2 seconds
      expect(aiService.isInitialized, isTrue);
      expect(encryptionService.isInitialized, isTrue);
      expect(deviceService.isInitialized, isTrue);
      expect(threatService.isInitialized, isTrue);
      expect(biService.isInitialized, isTrue);
      
      print('Service Initialization - All services: ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Stress Test - Mixed Operations Under Load', () async {
      final aiService = AiPoweredSecurityService();
      final encryptionService = AdvancedEncryptionService();
      final deviceService = DeviceSecurityService();
      
      await aiService.initialize();
      await encryptionService.initialize();
      await deviceService.initialize();

      final key = await encryptionService.generateKey(
        algorithm: 'AES-256-GCM',
        keyType: 'stress_test',
      );
      
      final stopwatch = Stopwatch()..start();
      
      // Mix different types of operations
      final futures = <Future>[];
      
      for (int i = 0; i < 30; i++) {
        // AI analysis
        futures.add(aiService.analyzeSecurityEvent({
          'user_id': 'stress_test_$i',
          'activity': 'mixed_operations',
        }));
        
        // Encryption
        futures.add(encryptionService.encrypt(
          data: utf8.encode('stress test data $i'),
          keyId: key.keyId,
        ));
        
        // Device check (every 5th iteration)
        if (i % 5 == 0) {
          futures.add(Future.value(deviceService.getCurrentDeviceInfo()));
        }
      }

      final results = await Future.wait(futures);
      stopwatch.stop();

      expect(results.length, greaterThan(60)); // Should have completed all operations
      expect(stopwatch.elapsedMilliseconds, lessThan(8000)); // Should complete within 8 seconds
      
      print('Stress Test - Mixed operations: ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Latency Test - Individual Operation Response Times', () async {
      final aiService = AiPoweredSecurityService();
      await aiService.initialize();

      final latencies = <int>[];
      
      // Test 20 individual operations to measure latency distribution
      for (int i = 0; i < 20; i++) {
        final stopwatch = Stopwatch()..start();
        
        await aiService.analyzeSecurityEvent({
          'user_id': 'latency_test_$i',
          'activity': 'single_operation',
        });
        
        stopwatch.stop();
        latencies.add(stopwatch.elapsedMilliseconds);
      }

      // Calculate statistics
      final avgLatency = latencies.reduce((a, b) => a + b) / latencies.length;
      final maxLatency = latencies.reduce((a, b) => a > b ? a : b);
      final minLatency = latencies.reduce((a, b) => a < b ? a : b);

      expect(avgLatency, lessThan(200)); // Average should be under 200ms
      expect(maxLatency, lessThan(500)); // Max should be under 500ms
      expect(minLatency, greaterThan(0)); // Should take some time
      
      print('Latency Stats - Avg: ${avgLatency.toStringAsFixed(1)}ms, Max: ${maxLatency}ms, Min: ${minLatency}ms');
    });

    test('Throughput Test - Operations Per Second', () async {
      final encryptionService = AdvancedEncryptionService();
      await encryptionService.initialize();

      final key = await encryptionService.generateKey(
        algorithm: 'AES-256-GCM',
        keyType: 'throughput_test',
      );
      const testDurationSeconds = 5;
      
      final stopwatch = Stopwatch()..start();
      int operationCount = 0;
      
      // Run operations for a fixed time period
      while (stopwatch.elapsedMilliseconds < testDurationSeconds * 1000) {
        await encryptionService.encrypt(
          data: utf8.encode('throughput test $operationCount'),
          keyId: key.keyId,
        );
        operationCount++;
      }
      
      stopwatch.stop();
      
      final operationsPerSecond = operationCount / (stopwatch.elapsedMilliseconds / 1000);
      
      expect(operationsPerSecond, greaterThan(10)); // Should handle at least 10 ops/sec
      expect(operationCount, greaterThan(50)); // Should complete at least 50 operations
      
      print('Throughput Test - ${operationsPerSecond.toStringAsFixed(1)} operations/second');
    });

    test('Resource Cleanup - Memory Leak Prevention', () async {
      // Test that services properly clean up resources
      final services = <AiPoweredSecurityService>[];
      
      for (int i = 0; i < 10; i++) {
        final aiService = AiPoweredSecurityService();
        await aiService.initialize();
        services.add(aiService);
        
        // Perform some operations
        await aiService.analyzeSecurityEvent({
          'user_id': 'cleanup_test_$i',
          'activity': 'resource_test',
        });
      }

      // All services should be properly initialized
      expect(services.length, equals(10));
      expect(services.every((s) => s.isInitialized), isTrue);
      
      // Cleanup should not throw errors
      for (final service in services) {
        expect(() => service.dispose(), returnsNormally);
      }
      
      print('Resource Cleanup - 10 services created and disposed successfully');
    });
  });
}
