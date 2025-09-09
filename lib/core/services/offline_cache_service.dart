import 'dart:async';

class OfflineCacheService {
  static final OfflineCacheService _instance = OfflineCacheService._internal();
  factory OfflineCacheService() => _instance;
  OfflineCacheService._internal();

  final Map<String, dynamic> _cache = {};

  Future<void> cacheData(String key, dynamic data) async {
    _cache[key] = data;
  }

  Future<dynamic> getCachedData(String key) async {
    return _cache[key];
  }

  Future<void> clearCache() async {
    _cache.clear();
  }

  Future<Map<String, dynamic>> getCacheStatus() async {
    return {
      'entries': _cache.length,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }
}
