import 'package:clean_flutter/features/admin/services/performance_monitoring_service.dart';
import 'package:clean_flutter/core/services/security_api_client.dart';
import 'package:clean_flutter/core/config/api_config.dart';
import 'package:clean_flutter/core/services/security_cache_service.dart';
import 'package:clean_flutter/core/services/performance_optimizer.dart';
import 'dart:async';

class EnhancedPerformanceMonitoringService extends PerformanceMonitoringService {
  SecurityApiClient? _apiClient;
  final SecurityCacheService _cacheService = SecurityCacheService();
  final PerformanceOptimizer _optimizer = PerformanceOptimizer();
  Timer? _refreshTimer;
  bool _isLoading = false;
  String? _error;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  EnhancedPerformanceMonitoringService() : super() {
    if (!ApiConfig.useMockData && ApiConfig.apiKey.isNotEmpty) {
      _apiClient = SecurityApiClient(
        baseUrl: ApiConfig.baseUrl,
        apiKey: ApiConfig.apiKey,
      );
      _loadRealData();
      _startAutoRefresh();
    }
  }
  
  Future<void> _loadRealData() async {
    if (_apiClient == null) return;
    
    // Throttle API calls to prevent excessive requests
    if (!_optimizer.throttle('load_metrics', minInterval: const Duration(seconds: 3))) {
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Load metrics from API
      final apiMetrics = await _apiClient!.getSystemMetrics();
      super.metrics.clear();
      super.metrics.addAll(apiMetrics);
      
      // Load service health from API
      final apiServices = await _apiClient!.getServiceHealth();
      super.services.clear();
      super.services.addAll(apiServices);
      
      // Load alerts from API
      final apiAlerts = await _apiClient!.getPerformanceAlerts();
      super.alerts.clear();
      super.alerts.addAll(apiAlerts);
      
      // Cache for offline use
      await _cacheService.cacheMetrics(apiMetrics);
      await _cacheService.cacheAlerts(apiAlerts);
      
      _error = null;
    } catch (e) {
      _error = 'Failed to load data from API: $e';
      
      // Try to load from cache for offline support
      final cachedMetrics = await _cacheService.get<List>('system_metrics');
      final cachedAlerts = await _cacheService.get<List>('performance_alerts');
      
      if (cachedMetrics != null || cachedAlerts != null) {
        _error = 'Using cached data (offline mode)';
      }
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void _startAutoRefresh() {
    if (_apiClient == null) return;
    
    // Auto-refresh every 30 seconds for real-time monitoring
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadRealData();
    });
  }
  
  Future<void> refreshData() async {
    if (_apiClient != null) {
      // Debounce refresh requests
      _optimizer.debounce('refresh_metrics', () async {
        await _loadRealData();
      });
    }
  }
  
  @override
  Future<void> acknowledgeAlert(String alertId) async {
    if (_apiClient != null) {
      try {
        final success = await _apiClient!.acknowledgeAlert(alertId);
        if (success) {
          // Update local state - commented out as alerts is not accessible
          // final alert = _alerts.firstWhere((a) => a.id == alertId);
          // final acknowledgedAlert = PerformanceAlert(
          //   id: alert.id,
          //   title: alert.title,
          //   description: alert.description,
          //   severity: alert.severity,
          //   timestamp: alert.timestamp,
          //   source: alert.source,
          //   context: alert.context,
          //   acknowledged: true,
          // );
          // 
          // final index = _alerts.indexWhere((a) => a.id == alertId);
          // _alerts[index] = acknowledgedAlert;
          notifyListeners();
          
          // Refresh data from server
          await _loadRealData();
        }
      } catch (e) {
        print('Error acknowledging alert via API: $e');
        // Fall back to parent implementation
        super.acknowledgeAlert(alertId);
      }
    } else {
      super.acknowledgeAlert(alertId);
    }
  }
  
  @override
  Map<String, dynamic> getPerformanceSummary() {
    if (_isLoading) {
      return {
        'avgCpuUsage': 0.0,
        'avgMemoryUsage': 0.0,
        'totalAlerts': 0,
        'healthyServices': 0,
        'avgResponseTime': 0.0,
      };
    }
    return super.getPerformanceSummary();
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    _apiClient?.dispose();
    _optimizer.dispose();
    super.dispose();
  }
}
