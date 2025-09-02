import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clean_flutter/features/admin/services/security_orchestration_service.dart';
import 'package:clean_flutter/features/admin/services/performance_monitoring_service.dart';
import 'package:clean_flutter/features/admin/services/emerging_threats_service.dart';

class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;
  final String key;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.ttl,
    required this.key,
  });

  bool get isExpired => DateTime.now().isAfter(timestamp.add(ttl));

  Map<String, dynamic> toJson() => {
    'data': data is Map ? data : data.toString(),
    'timestamp': timestamp.toIso8601String(),
    'ttl': ttl.inMilliseconds,
    'key': key,
  };
}

class SecurityCacheService {
  static final SecurityCacheService _instance = SecurityCacheService._internal();
  factory SecurityCacheService() => _instance;
  SecurityCacheService._internal();

  final Map<String, CacheEntry> _memoryCache = {};
  SharedPreferences? _prefs;
  Timer? _cleanupTimer;
  
  final Duration _defaultTTL = const Duration(hours: 1);
  final Duration _threatIntelTTL = const Duration(minutes: 30);
  final Duration _userDataTTL = const Duration(minutes: 15);
  final Duration _configTTL = const Duration(hours: 24);
  final Duration _playbookTTL = const Duration(hours: 6);
  final Duration _metricsTTL = const Duration(minutes: 5);
  final Duration _alertsTTL = const Duration(minutes: 1);
  
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    _startCleanupTimer();
    _isInitialized = true;
    
    developer.log('Security Cache Service initialized', name: 'SecurityCacheService');
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _cleanupExpiredEntries();
    });
  }

  Future<void> set<T>(String key, T data, {Duration? ttl}) async {
    await _ensureInitialized();
    
    final entry = CacheEntry<T>(
      data: data,
      timestamp: DateTime.now(),
      ttl: ttl ?? _defaultTTL,
      key: key,
    );
    
    _memoryCache[key] = entry;
    
    // Persist to disk for offline support
    try {
      await _prefs!.setString(key, jsonEncode(entry.toJson()));
    } catch (e) {
      developer.log('Failed to persist cache entry: $e', name: 'SecurityCacheService');
    }
    
    developer.log('Cached data for key: $key', name: 'SecurityCacheService');
  }

  Future<T?> get<T>(String key) async {
    await _ensureInitialized();
    
    // Check memory cache first
    final memoryEntry = _memoryCache[key];
    if (memoryEntry != null && !memoryEntry.isExpired) {
      developer.log('Cache hit (memory): $key', name: 'SecurityCacheService');
      return memoryEntry.data as T?;
    }
    
    // Check persistent cache
    try {
      final persistedData = _prefs!.getString(key);
      if (persistedData != null) {
        final entryJson = jsonDecode(persistedData);
        final timestamp = DateTime.parse(entryJson['timestamp']);
        final ttl = Duration(milliseconds: entryJson['ttl']);
        
        if (!DateTime.now().isAfter(timestamp.add(ttl))) {
          final data = entryJson['data'];
          developer.log('Cache hit (disk): $key', name: 'SecurityCacheService');
          return data as T?;
        } else {
          // Remove expired entry
          await _prefs!.remove(key);
        }
      }
    } catch (e) {
      developer.log('Failed to read cache entry: $e', name: 'SecurityCacheService');
    }
    
    // Remove expired memory entry
    if (memoryEntry != null && memoryEntry.isExpired) {
      _memoryCache.remove(key);
    }
    
    developer.log('Cache miss: $key', name: 'SecurityCacheService');
    return null;
  }

  Future<void> remove(String key) async {
    await _ensureInitialized();
    
    _memoryCache.remove(key);
    await _prefs!.remove(key);
    
    developer.log('Removed cache entry: $key', name: 'SecurityCacheService');
  }

  Future<void> clear() async {
    await _ensureInitialized();
    
    _memoryCache.clear();
    
    // Clear only our cache keys from SharedPreferences
    final keys = _prefs!.getKeys().where((key) => key.startsWith('security_cache_')).toList();
    for (final key in keys) {
      await _prefs!.remove(key);
    }
    
    developer.log('Cleared all cache entries', name: 'SecurityCacheService');
  }

  // Threat Intelligence Caching
  Future<void> cacheThreatIntel(String key, Map<String, dynamic> data) async {
    await set('threat_intel_$key', data, ttl: _threatIntelTTL);
  }

  Future<Map<String, dynamic>?> getThreatIntel(String key) async {
    return await get<Map<String, dynamic>>('threat_intel_$key');
  }

  // User Data Caching
  Future<void> cacheUserData(String userId, Map<String, dynamic> data) async {
    await set('user_data_$userId', data, ttl: _userDataTTL);
  }

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    return await get<Map<String, dynamic>>('user_data_$userId');
  }

  // Security Alerts Caching
  Future<void> cacheSecurityAlerts(List<Map<String, dynamic>> alerts) async {
    await set('security_alerts', alerts, ttl: const Duration(minutes: 5));
  }

  Future<List<Map<String, dynamic>>?> getSecurityAlerts() async {
    final cached = await get<List>('security_alerts');
    return cached?.cast<Map<String, dynamic>>();
  }

  // Configuration Caching
  Future<void> cacheConfig(String configKey, Map<String, dynamic> config) async {
    await set('config_$configKey', config, ttl: _configTTL);
  }

  Future<Map<String, dynamic>?> getConfig(String configKey) async {
    return await get<Map<String, dynamic>>('config_$configKey');
  }

  // Analytics Data Caching
  Future<void> cacheAnalytics(String key, Map<String, dynamic> data) async {
    await set('analytics_$key', data, ttl: const Duration(minutes: 10));
  }

  Future<Map<String, dynamic>?> getAnalytics(String key) async {
    return await get<Map<String, dynamic>>('analytics_$key');
  }

  // SIEM Data Caching
  Future<void> cacheSIEMData(String connectionId, Map<String, dynamic> data) async {
    await set('siem_$connectionId', data, ttl: const Duration(minutes: 20));
  }

  Future<Map<String, dynamic>?> getSIEMData(String connectionId) async {
    return await get<Map<String, dynamic>>('siem_$connectionId');
  }

  // Offline Support Methods
  Future<void> cacheForOffline(String key, Map<String, dynamic> data) async {
    await set('offline_$key', data, ttl: const Duration(days: 7));
  }

  Future<Map<String, dynamic>?> getOfflineData(String key) async {
    return await get<Map<String, dynamic>>('offline_$key');
  }

  Future<List<String>> getOfflineKeys() async {
    await _ensureInitialized();
    return _prefs!.getKeys().where((key) => key.startsWith('offline_')).toList();
  }

  // Cache Statistics
  Map<String, dynamic> getCacheStats() {
    final memoryEntries = _memoryCache.length;
    final expiredMemoryEntries = _memoryCache.values.where((entry) => entry.isExpired).length;
    
    return {
      'memory_entries': memoryEntries,
      'expired_memory_entries': expiredMemoryEntries,
      'cache_hit_rate': _calculateHitRate(),
      'memory_usage_mb': _estimateMemoryUsage(),
      'last_cleanup': DateTime.now().toIso8601String(),
    };
  }

  double _calculateHitRate() {
    // This would need to be tracked over time in a real implementation
    return 0.85; // Mock 85% hit rate
  }

  double _estimateMemoryUsage() {
    // Rough estimation of memory usage
    final totalEntries = _memoryCache.length;
    return totalEntries * 0.5; // Estimate 0.5MB per entry
  }

  void _cleanupExpiredEntries() {
    final expiredKeys = _memoryCache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();
    
    for (final key in expiredKeys) {
      _memoryCache.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      developer.log('Cleaned up ${expiredKeys.length} expired cache entries', name: 'SecurityCacheService');
    }
  }

  // Batch Operations
  Future<void> setBatch(Map<String, dynamic> entries, {Duration? ttl}) async {
    for (final entry in entries.entries) {
      await set(entry.key, entry.value, ttl: ttl);
    }
  }

  Future<Map<String, dynamic>> getBatch(List<String> keys) async {
    final results = <String, dynamic>{};
    
    for (final key in keys) {
      final value = await get(key);
      if (value != null) {
        results[key] = value;
      }
    }
    
    return results;
  }

  // Cache Warming
  Future<void> warmCache() async {
    developer.log('Starting cache warming...', name: 'SecurityCacheService');
    
    // Pre-load critical security data
    final criticalKeys = [
      'security_config',
      'threat_feeds',
      'user_permissions',
      'security_policies',
    ];
    
    for (final key in criticalKeys) {
      // In a real implementation, this would fetch from backend
      await cacheConfig(key, {'warmed': true, 'timestamp': DateTime.now().toIso8601String()});
    }
    
    developer.log('Cache warming completed', name: 'SecurityCacheService');
  }

  // Cache Invalidation
  Future<void> invalidatePattern(String pattern) async {
    await _ensureInitialized();
    
    final keysToRemove = _memoryCache.keys.where((key) => key.contains(pattern)).toList();
    
    for (final key in keysToRemove) {
      await remove(key);
    }
    
    developer.log('Invalidated ${keysToRemove.length} cache entries matching pattern: $pattern', name: 'SecurityCacheService');
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
  
  // Security Orchestration Caching
  Future<void> cachePlaybooks(List<SecurityPlaybook> playbooks) async {
    final data = playbooks.map((p) => {
      'id': p.id,
      'name': p.name,
      'description': p.description,
      'category': p.category,
      'status': p.status.name,
      'useCount': p.useCount,
      'successRate': p.successRate,
    }).toList();
    await set('security_playbooks', data, ttl: _playbookTTL);
  }
  
  Future<List<SecurityPlaybook>?> getCachedPlaybooks() async {
    final cached = await get<List>('security_playbooks');
    if (cached == null) return null;
    
    // Note: This returns simplified playbooks without full action details
    // For full offline support, would need to serialize complete objects
    return null; // Simplified for now
  }
  
  Future<void> cacheSecurityCases(List<SecurityCase> cases) async {
    final data = cases.map((c) => {
      'id': c.id,
      'title': c.title,
      'description': c.description,
      'type': c.type.name,
      'status': c.status.name,
      'priority': c.priority.name,
      'createdAt': c.createdAt.toIso8601String(),
    }).toList();
    await set('security_cases', data, ttl: _defaultTTL);
  }
  
  // Performance Monitoring Caching
  Future<void> cacheMetrics(List<SystemMetric> metrics) async {
    final data = metrics.map((m) => {
      'id': m.id,
      'name': m.name,
      'value': m.value,
      'unit': m.unit,
      'type': m.type.name,
      'status': m.status.name,
      'threshold': m.threshold,
      'timestamp': m.timestamp.toIso8601String(),
    }).toList();
    await set('system_metrics', data, ttl: _metricsTTL);
  }
  
  Future<void> cacheAlerts(List<PerformanceAlert> alerts) async {
    final data = alerts.map((a) => {
      'id': a.id,
      'title': a.title,
      'description': a.description,
      'severity': a.severity.name,
      'source': a.source,
      'acknowledged': a.acknowledged,
      'timestamp': a.timestamp.toIso8601String(),
    }).toList();
    await set('performance_alerts', data, ttl: _alertsTTL);
  }
  
  // Emerging Threats Caching  
  Future<void> cacheThreats(List<EmergingThreat> threats) async {
    final data = threats.map((t) => {
      'id': t.id,
      'name': t.name,
      'description': t.description,
      'severity': t.severity.name,
      'category': t.category,
      'riskScore': t.riskScore,
      'isActive': t.isActive,
      'discoveredAt': t.discoveredAt.toIso8601String(),
    }).toList();
    await set('emerging_threats', data, ttl: _threatIntelTTL);
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _memoryCache.clear();
  }
}
