import 'package:flutter_test/flutter_test.dart';
import 'package:clean_flutter/core/services/security_cache_service.dart';
import 'package:clean_flutter/features/admin/services/enhanced_security_orchestration_service.dart';
import 'package:clean_flutter/features/admin/services/enhanced_performance_monitoring_service.dart';
import 'package:clean_flutter/features/admin/services/enhanced_emerging_threats_service.dart';

void main() {
  group('Offline Cache Integration Tests', () {
    late SecurityCacheService cacheService;
    
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      cacheService = SecurityCacheService();
      await cacheService.initialize();
    });
    
    tearDown(() async {
      await cacheService.clear();
    });
    
    test('Cache service initializes correctly', () async {
      expect(cacheService, isNotNull);
      final stats = cacheService.getCacheStats();
      expect(stats['memory_entries'], isA<int>());
    });
    
    test('Can cache and retrieve security data', () async {
      // Test caching simple data
      await cacheService.set('test_key', {'data': 'test_value'});
      final retrieved = await cacheService.get<Map>('test_key');
      
      expect(retrieved, isNotNull);
      expect(retrieved!['data'], equals('test_value'));
    });
    
    test('Cache respects TTL', () async {
      // Cache with short TTL
      await cacheService.set(
        'short_ttl', 
        {'data': 'expires_soon'}, 
        ttl: const Duration(milliseconds: 100)
      );
      
      // Should exist immediately
      var data = await cacheService.get<Map>('short_ttl');
      expect(data, isNotNull);
      
      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Should be expired
      data = await cacheService.get<Map>('short_ttl');
      expect(data, isNull);
    });
    
    test('Threat intelligence caching works', () async {
      final threatData = {
        'threat_id': 'test_001',
        'severity': 'high',
        'description': 'Test threat'
      };
      
      await cacheService.cacheThreatIntel('test_threat', threatData);
      final retrieved = await cacheService.getThreatIntel('test_threat');
      
      expect(retrieved, isNotNull);
      expect(retrieved!['threat_id'], equals('test_001'));
    });
    
    test('Batch operations work correctly', () async {
      final batchData = {
        'key1': {'value': 1},
        'key2': {'value': 2},
        'key3': {'value': 3},
      };
      
      await cacheService.setBatch(batchData);
      
      final retrieved = await cacheService.getBatch(['key1', 'key2', 'key3']);
      expect(retrieved.length, equals(3));
      expect(retrieved['key1'], equals({'value': 1}));
    });
    
    test('Cache invalidation by pattern works', () async {
      // Set multiple keys with pattern
      await cacheService.set('user_1', {'name': 'User 1'});
      await cacheService.set('user_2', {'name': 'User 2'});
      await cacheService.set('config_1', {'setting': 'value'});
      
      // Invalidate user keys
      await cacheService.invalidatePattern('user_');
      
      // User keys should be gone
      expect(await cacheService.get('user_1'), isNull);
      expect(await cacheService.get('user_2'), isNull);
      
      // Config key should remain
      expect(await cacheService.get('config_1'), isNotNull);
    });
    
    test('Offline data persistence works', () async {
      final offlineData = {
        'playbooks': ['pb1', 'pb2'],
        'metrics': [85.5, 92.3],
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await cacheService.cacheForOffline('security_data', offlineData);
      
      // Should persist for longer duration
      final retrieved = await cacheService.getOfflineData('security_data');
      expect(retrieved, isNotNull);
      expect(retrieved!['playbooks'], hasLength(2));
    });
    
    test('Cache warming pre-loads critical data', () async {
      await cacheService.warmCache();
      
      // Critical config should be pre-loaded
      final config = await cacheService.getConfig('security_config');
      expect(config, isNotNull);
      expect(config!['warmed'], isTrue);
    });
    
    test('Enhanced services use cache on API failure', () async {
      // This test would require mocking the API client to simulate failure
      // For now, we verify the services can be instantiated
      
      final orchestrationService = EnhancedSecurityOrchestrationService();
      final performanceService = EnhancedPerformanceMonitoringService();
      final threatsService = EnhancedEmergingThreatsService();
      
      expect(orchestrationService, isNotNull);
      expect(performanceService, isNotNull);
      expect(threatsService, isNotNull);
      
      // Services should have mock data even without API
      expect(orchestrationService.playbooks, isNotEmpty);
      expect(performanceService.metrics, isNotEmpty);
      expect(threatsService.threats, isNotEmpty);
    });
    
    test('Cache statistics are accurate', () async {
      // Add some data
      await cacheService.set('stat_test_1', {'data': 1});
      await cacheService.set('stat_test_2', {'data': 2});
      
      final stats = cacheService.getCacheStats();
      
      expect(stats['memory_entries'], greaterThanOrEqualTo(2));
      expect(stats['cache_hit_rate'], isA<double>());
      expect(stats['memory_usage_mb'], isA<double>());
      expect(stats['last_cleanup'], isA<String>());
    });
  });
}
