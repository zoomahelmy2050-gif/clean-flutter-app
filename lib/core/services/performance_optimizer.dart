import 'dart:async';
import 'package:flutter/foundation.dart';

/// Performance optimization service for security features
class PerformanceOptimizer {
  static final PerformanceOptimizer _instance = PerformanceOptimizer._internal();
  factory PerformanceOptimizer() => _instance;
  PerformanceOptimizer._internal();

  // Debounce timers for reducing unnecessary updates
  final Map<String, Timer?> _debounceTimers = {};
  
  // Throttle timestamps for rate limiting
  final Map<String, DateTime> _throttleTimestamps = {};
  
  // Memory cache with size limits
  final Map<String, dynamic> _optimizedCache = {};
  static const int _maxCacheSize = 100;
  
  // Performance metrics
  int _apiCallsSaved = 0;
  int _cacheHits = 0;
  int _cacheMisses = 0;
  
  /// Debounce function calls to reduce frequency
  void debounce(
    String key,
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 500),
  }) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(delay, callback);
  }
  
  /// Throttle function calls to limit rate
  bool throttle(
    String key, {
    Duration minInterval = const Duration(seconds: 1),
  }) {
    final lastCall = _throttleTimestamps[key];
    final now = DateTime.now();
    
    if (lastCall == null || now.difference(lastCall) >= minInterval) {
      _throttleTimestamps[key] = now;
      return true;
    }
    
    return false;
  }
  
  /// Cache with automatic size management
  void cache(String key, dynamic value) {
    if (_optimizedCache.length >= _maxCacheSize) {
      // Remove oldest entry (simple FIFO)
      _optimizedCache.remove(_optimizedCache.keys.first);
    }
    _optimizedCache[key] = value;
  }
  
  /// Get cached value with performance tracking
  T? getCached<T>(String key) {
    if (_optimizedCache.containsKey(key)) {
      _cacheHits++;
      return _optimizedCache[key] as T?;
    }
    _cacheMisses++;
    return null;
  }
  
  /// Batch API calls to reduce network overhead
  Future<List<T>> batchApiCalls<T>(
    List<Future<T> Function()> apiCalls, {
    int batchSize = 5,
  }) async {
    final results = <T>[];
    
    for (int i = 0; i < apiCalls.length; i += batchSize) {
      final batch = apiCalls.skip(i).take(batchSize);
      final batchResults = await Future.wait(
        batch.map((call) => call()),
      );
      results.addAll(batchResults);
    }
    
    _apiCallsSaved += apiCalls.length - (apiCalls.length / batchSize).ceil();
    return results;
  }
  
  /// Lazy load data only when needed
  Future<T> lazyLoad<T>(
    String key,
    Future<T> Function() loader,
  ) async {
    final cached = getCached<T>(key);
    if (cached != null) {
      return cached;
    }
    
    final data = await loader();
    cache(key, data);
    return data;
  }
  
  /// Memory-efficient list pagination
  List<T> paginate<T>(
    List<T> items,
    int page,
    int pageSize,
  ) {
    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, items.length);
    
    if (start >= items.length) {
      return [];
    }
    
    return items.sublist(start, end);
  }
  
  /// Optimize image/data loading with progressive loading
  Stream<List<T>> progressiveLoad<T>(
    List<T> items, {
    int chunkSize = 20,
    Duration delay = const Duration(milliseconds: 100),
  }) async* {
    for (int i = 0; i < items.length; i += chunkSize) {
      final chunk = items.skip(i).take(chunkSize).toList();
      yield items.sublist(0, i + chunk.length);
      
      if (i + chunkSize < items.length) {
        await Future.delayed(delay);
      }
    }
  }
  
  /// Create a virtual scroll controller for large lists
  VirtualScrollController<T> createVirtualScroller<T>(List<T> items) {
    return VirtualScrollController<T>(
      items: items,
    );
  }
  
  /// Compute-intensive operations in isolate
  Future<R> computeInBackground<T, R>(
    ComputeCallback<T, R> callback,
    T message,
  ) async {
    return await compute(callback, message);
  }
  
  /// Memory cleanup
  void clearCache() {
    _optimizedCache.clear();
    _debounceTimers.forEach((key, timer) => timer?.cancel());
    _debounceTimers.clear();
    _throttleTimestamps.clear();
  }
  
  /// Performance metrics
  Map<String, dynamic> getMetrics() {
    final total = _cacheHits + _cacheMisses;
    return {
      'cache_hits': _cacheHits,
      'cache_misses': _cacheMisses,
      'cache_hit_rate': total > 0 ? (_cacheHits / total) : 0.0,
      'api_calls_saved': _apiCallsSaved,
      'cache_size': _optimizedCache.length,
      'max_cache_size': _maxCacheSize,
    };
  }
  
  /// Dispose resources
  void dispose() {
    clearCache();
  }
}

/// Memoization decorator for expensive computations
class Memoizer<T> {
  final Map<String, T> _cache = {};
  final Future<T> Function(String) _computation;
  
  Memoizer(this._computation);
  
  Future<T> call(String key) async {
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }
    
    final result = await _computation(key);
    _cache[key] = result;
    return result;
  }
  
  void clear() {
    _cache.clear();
  }
}

/// Virtual scrolling helper for large lists
class VirtualScrollController<T> {
  final List<T> items;
  final int viewportSize;
  final int bufferSize;
  
  int _currentIndex = 0;
  
  VirtualScrollController({
    required this.items,
    this.viewportSize = 20,
    this.bufferSize = 5,
  });
  
  List<T> get visibleItems {
    final start = (_currentIndex - bufferSize).clamp(0, items.length);
    final end = (_currentIndex + viewportSize + bufferSize).clamp(0, items.length);
    return items.sublist(start, end);
  }
  
  void scrollTo(int index) {
    _currentIndex = index.clamp(0, items.length - viewportSize);
  }
  
  void scrollBy(int delta) {
    scrollTo(_currentIndex + delta);
  }
}

/// Stream optimization utilities
class StreamOptimizer {
  /// Debounce stream events
  static Stream<T> debounceStream<T>(
    Stream<T> source,
    Duration duration,
  ) {
    Timer? timer;
    late T lastValue;
    
    return source.transform(
      StreamTransformer<T, T>.fromHandlers(
        handleData: (data, sink) {
          lastValue = data;
          timer?.cancel();
          timer = Timer(duration, () {
            sink.add(lastValue);
          });
        },
        handleDone: (sink) {
          timer?.cancel();
          sink.close();
        },
      ),
    );
  }
  
  /// Throttle stream events
  static Stream<T> throttleStream<T>(
    Stream<T> source,
    Duration duration,
  ) {
    DateTime? lastEmit;
    
    return source.where((event) {
      final now = DateTime.now();
      if (lastEmit == null || now.difference(lastEmit!) >= duration) {
        lastEmit = now;
        return true;
      }
      return false;
    });
  }
  
  /// Buffer stream events
  static Stream<List<T>> bufferStream<T>(
    Stream<T> source,
    Duration duration,
  ) {
    final buffer = <T>[];
    Timer? timer;
    
    return source.transform(
      StreamTransformer<T, List<T>>.fromHandlers(
        handleData: (data, sink) {
          buffer.add(data);
          timer?.cancel();
          timer = Timer(duration, () {
            if (buffer.isNotEmpty) {
              sink.add(List.from(buffer));
              buffer.clear();
            }
          });
        },
        handleDone: (sink) {
          timer?.cancel();
          if (buffer.isNotEmpty) {
            sink.add(List.from(buffer));
          }
          sink.close();
        },
      ),
    );
  }
}
