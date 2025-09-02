import 'dart:async';
import 'dart:developer' as developer;

class PerformanceMetrics {
  final String id;
  final String name;
  final double value;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  PerformanceMetrics({
    required this.id,
    required this.name,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'value': value,
    'unit': unit,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) => PerformanceMetrics(
    id: json['id'],
    name: json['name'],
    value: json['value'].toDouble(),
    unit: json['unit'],
    timestamp: DateTime.parse(json['timestamp']),
    metadata: json['metadata'] ?? {},
  );
}

class APIPerformanceData {
  final String endpoint;
  final int responseTime;
  final int statusCode;
  final DateTime timestamp;
  final String method;
  final int requestSize;
  final int responseSize;

  APIPerformanceData({
    required this.endpoint,
    required this.responseTime,
    required this.statusCode,
    required this.timestamp,
    required this.method,
    this.requestSize = 0,
    this.responseSize = 0,
  });

  Map<String, dynamic> toJson() => {
    'endpoint': endpoint,
    'response_time': responseTime,
    'status_code': statusCode,
    'timestamp': timestamp.toIso8601String(),
    'method': method,
    'request_size': requestSize,
    'response_size': responseSize,
  };
}

class MemoryUsageData {
  final int totalMemory;
  final int usedMemory;
  final int freeMemory;
  final double usagePercentage;
  final DateTime timestamp;

  MemoryUsageData({
    required this.totalMemory,
    required this.usedMemory,
    required this.freeMemory,
    required this.usagePercentage,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'total_memory': totalMemory,
    'used_memory': usedMemory,
    'free_memory': freeMemory,
    'usage_percentage': usagePercentage,
    'timestamp': timestamp.toIso8601String(),
  };
}

class UserInteractionData {
  final String action;
  final String screen;
  final Duration duration;
  final DateTime timestamp;
  final Map<String, dynamic> context;

  UserInteractionData({
    required this.action,
    required this.screen,
    required this.duration,
    required this.timestamp,
    this.context = const {},
  });

  Map<String, dynamic> toJson() => {
    'action': action,
    'screen': screen,
    'duration': duration.inMilliseconds,
    'timestamp': timestamp.toIso8601String(),
    'context': context,
  };
}

class PerformanceMonitoringService {
  static final PerformanceMonitoringService _instance = PerformanceMonitoringService._internal();
  factory PerformanceMonitoringService() => _instance;
  PerformanceMonitoringService._internal();

  final List<PerformanceMetrics> _metrics = [];
  final List<APIPerformanceData> _apiMetrics = [];
  final List<MemoryUsageData> _memoryMetrics = [];
  final List<UserInteractionData> _interactionMetrics = [];
  
  Timer? _memoryMonitorTimer;
  Timer? _metricsCleanupTimer;
  
  final StreamController<PerformanceMetrics> _metricsController = StreamController.broadcast();
  final StreamController<MemoryUsageData> _memoryController = StreamController.broadcast();
  
  bool _isMonitoring = false;
  final int _maxMetricsHistory = 1000;
  final Duration _memoryCheckInterval = const Duration(seconds: 30);
  final Duration _metricsRetentionPeriod = const Duration(hours: 24);

  Stream<PerformanceMetrics> get metricsStream => _metricsController.stream;
  Stream<MemoryUsageData> get memoryStream => _memoryController.stream;

  Future<void> initialize() async {
    await startMonitoring();
    developer.log('Performance Monitoring Service initialized', name: 'PerformanceMonitoringService');
  }

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    
    // Start memory monitoring
    _memoryMonitorTimer = Timer.periodic(_memoryCheckInterval, (_) => _collectMemoryMetrics());
    
    // Start metrics cleanup
    _metricsCleanupTimer = Timer.periodic(const Duration(hours: 1), (_) => _cleanupOldMetrics());
    
    developer.log('Performance monitoring started', name: 'PerformanceMonitoringService');
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _memoryMonitorTimer?.cancel();
    _metricsCleanupTimer?.cancel();
    
    developer.log('Performance monitoring stopped', name: 'PerformanceMonitoringService');
  }

  void recordMetric({
    required String name,
    required double value,
    required String unit,
    Map<String, dynamic>? metadata,
  }) {
    final metric = PerformanceMetrics(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      value: value,
      unit: unit,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );
    
    _metrics.add(metric);
    _metricsController.add(metric);
    
    _limitMetricsHistory(_metrics);
    
    developer.log('Recorded metric: $name = $value $unit', name: 'PerformanceMonitoringService');
  }

  void recordAPICall({
    required String endpoint,
    required int responseTime,
    required int statusCode,
    required String method,
    int requestSize = 0,
    int responseSize = 0,
  }) {
    final apiData = APIPerformanceData(
      endpoint: endpoint,
      responseTime: responseTime,
      statusCode: statusCode,
      timestamp: DateTime.now(),
      method: method,
      requestSize: requestSize,
      responseSize: responseSize,
    );
    
    _apiMetrics.add(apiData);
    _limitMetricsHistory(_apiMetrics);
    
    // Record as general metric
    recordMetric(
      name: 'api_response_time',
      value: responseTime.toDouble(),
      unit: 'ms',
      metadata: {
        'endpoint': endpoint,
        'method': method,
        'status_code': statusCode,
      },
    );
    
    developer.log('Recorded API call: $method $endpoint - ${responseTime}ms', name: 'PerformanceMonitoringService');
  }

  void recordUserInteraction({
    required String action,
    required String screen,
    required Duration duration,
    Map<String, dynamic>? context,
  }) {
    final interaction = UserInteractionData(
      action: action,
      screen: screen,
      duration: duration,
      timestamp: DateTime.now(),
      context: context ?? {},
    );
    
    _interactionMetrics.add(interaction);
    _limitMetricsHistory(_interactionMetrics);
    
    // Record as general metric
    recordMetric(
      name: 'user_interaction_time',
      value: duration.inMilliseconds.toDouble(),
      unit: 'ms',
      metadata: {
        'action': action,
        'screen': screen,
        'context': context ?? {},
      },
    );
    
    developer.log('Recorded user interaction: $action on $screen - ${duration.inMilliseconds}ms', name: 'PerformanceMonitoringService');
  }

  Future<void> _collectMemoryMetrics() async {
    try {
      // Get memory info (platform-specific implementation needed)
      final memoryInfo = await _getMemoryInfo();
      
      final memoryData = MemoryUsageData(
        totalMemory: memoryInfo['total'] ?? 0,
        usedMemory: memoryInfo['used'] ?? 0,
        freeMemory: memoryInfo['free'] ?? 0,
        usagePercentage: memoryInfo['percentage'] ?? 0.0,
        timestamp: DateTime.now(),
      );
      
      _memoryMetrics.add(memoryData);
      _memoryController.add(memoryData);
      _limitMetricsHistory(_memoryMetrics);
      
      // Record as general metric
      recordMetric(
        name: 'memory_usage',
        value: memoryData.usagePercentage,
        unit: '%',
        metadata: {
          'total_memory': memoryData.totalMemory,
          'used_memory': memoryData.usedMemory,
          'free_memory': memoryData.freeMemory,
        },
      );
      
    } catch (e) {
      developer.log('Failed to collect memory metrics: $e', name: 'PerformanceMonitoringService');
    }
  }

  Future<Map<String, dynamic>> _getMemoryInfo() async {
    // Mock implementation - in real app, use platform channels
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    final totalMemory = 8 * 1024 * 1024 * 1024; // 8GB
    final usedMemory = (totalMemory * (50 + random) / 100).round();
    final freeMemory = totalMemory - usedMemory;
    
    return {
      'total': totalMemory,
      'used': usedMemory,
      'free': freeMemory,
      'percentage': (usedMemory / totalMemory * 100),
    };
  }

  void _limitMetricsHistory<T>(List<T> metrics) {
    if (metrics.length > _maxMetricsHistory) {
      metrics.removeRange(0, metrics.length - _maxMetricsHistory);
    }
  }

  void _cleanupOldMetrics() {
    final cutoffTime = DateTime.now().subtract(_metricsRetentionPeriod);
    
    _metrics.removeWhere((metric) => metric.timestamp.isBefore(cutoffTime));
    _apiMetrics.removeWhere((metric) => metric.timestamp.isBefore(cutoffTime));
    _memoryMetrics.removeWhere((metric) => metric.timestamp.isBefore(cutoffTime));
    _interactionMetrics.removeWhere((metric) => metric.timestamp.isBefore(cutoffTime));
    
    developer.log('Cleaned up old performance metrics', name: 'PerformanceMonitoringService');
  }

  List<PerformanceMetrics> getMetrics({
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
  }) {
    var filteredMetrics = _metrics.where((metric) {
      if (name != null && metric.name != name) return false;
      if (startTime != null && metric.timestamp.isBefore(startTime)) return false;
      if (endTime != null && metric.timestamp.isAfter(endTime)) return false;
      return true;
    }).toList();
    
    filteredMetrics.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    if (limit != null && filteredMetrics.length > limit) {
      filteredMetrics = filteredMetrics.take(limit).toList();
    }
    
    return filteredMetrics;
  }

  List<APIPerformanceData> getAPIMetrics({
    String? endpoint,
    String? method,
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
  }) {
    var filteredMetrics = _apiMetrics.where((metric) {
      if (endpoint != null && !metric.endpoint.contains(endpoint)) return false;
      if (method != null && metric.method != method) return false;
      if (startTime != null && metric.timestamp.isBefore(startTime)) return false;
      if (endTime != null && metric.timestamp.isAfter(endTime)) return false;
      return true;
    }).toList();
    
    filteredMetrics.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    if (limit != null && filteredMetrics.length > limit) {
      filteredMetrics = filteredMetrics.take(limit).toList();
    }
    
    return filteredMetrics;
  }

  Map<String, dynamic> getPerformanceSummary() {
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    
    final recentMetrics = getMetrics(startTime: oneHourAgo);
    final recentAPIMetrics = getAPIMetrics(startTime: oneHourAgo);
    final recentMemoryMetrics = _memoryMetrics.where((m) => m.timestamp.isAfter(oneHourAgo)).toList();
    
    // Calculate averages
    double avgResponseTime = 0;
    if (recentAPIMetrics.isNotEmpty) {
      avgResponseTime = recentAPIMetrics.map((m) => m.responseTime).reduce((a, b) => a + b) / recentAPIMetrics.length;
    }
    
    double avgMemoryUsage = 0;
    if (recentMemoryMetrics.isNotEmpty) {
      avgMemoryUsage = recentMemoryMetrics.map((m) => m.usagePercentage).reduce((a, b) => a + b) / recentMemoryMetrics.length;
    }
    
    return {
      'summary_period': '1 hour',
      'total_metrics': recentMetrics.length,
      'api_calls': recentAPIMetrics.length,
      'avg_response_time': avgResponseTime,
      'avg_memory_usage': avgMemoryUsage,
      'error_rate': _calculateErrorRate(recentAPIMetrics),
      'top_slow_endpoints': _getTopSlowEndpoints(recentAPIMetrics),
      'memory_trend': _getMemoryTrend(recentMemoryMetrics),
      'generated_at': now.toIso8601String(),
    };
  }

  double _calculateErrorRate(List<APIPerformanceData> apiMetrics) {
    if (apiMetrics.isEmpty) return 0.0;
    
    final errorCount = apiMetrics.where((m) => m.statusCode >= 400).length;
    return (errorCount / apiMetrics.length) * 100;
  }

  List<Map<String, dynamic>> _getTopSlowEndpoints(List<APIPerformanceData> apiMetrics) {
    final endpointTimes = <String, List<int>>{};
    
    for (final metric in apiMetrics) {
      endpointTimes.putIfAbsent(metric.endpoint, () => []).add(metric.responseTime);
    }
    
    final avgTimes = endpointTimes.entries.map((entry) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      return {'endpoint': entry.key, 'avg_response_time': avg, 'call_count': entry.value.length};
    }).toList();
    
        avgTimes.sort((a, b) => (b['avg_response_time'] as double? ?? 0.0).compareTo(a['avg_response_time'] as double? ?? 0.0));
    
    return avgTimes.take(5).toList();
  }

  String _getMemoryTrend(List<MemoryUsageData> memoryMetrics) {
    if (memoryMetrics.length < 2) return 'stable';
    
    final first = memoryMetrics.first.usagePercentage;
    final last = memoryMetrics.last.usagePercentage;
    final diff = last - first;
    
    if (diff > 5) return 'increasing';
    if (diff < -5) return 'decreasing';
    return 'stable';
  }

  void dispose() {
    stopMonitoring();
    _metricsController.close();
    _memoryController.close();
  }
}
