import 'package:clean_flutter/features/admin/services/emerging_threats_service.dart';
import 'package:clean_flutter/core/services/security_api_client.dart';
import 'package:clean_flutter/core/config/api_config.dart';
import 'package:clean_flutter/core/services/security_cache_service.dart';
import 'package:clean_flutter/core/services/performance_optimizer.dart';
import 'dart:async';

class EnhancedEmergingThreatsService extends EmergingThreatsService {
  SecurityApiClient? _apiClient;
  final SecurityCacheService _cacheService = SecurityCacheService();
  final PerformanceOptimizer _optimizer = PerformanceOptimizer();
  Timer? _refreshTimer;
  bool _isLoading = false;
  String? _error;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  EnhancedEmergingThreatsService() : super() {
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
    if (!_optimizer.throttle('load_threats', minInterval: const Duration(seconds: 3))) {
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Load threats from API
      final apiThreats = await _apiClient!.getEmergingThreats();
      super.threats.clear();
      super.threats.addAll(apiThreats);
      
      // Load IoT devices from API
      final apiIoTDevices = await _apiClient!.getIoTDevices();
      super.iotDevices.clear();
      super.iotDevices.addAll(apiIoTDevices);
      
      // Load container security from API
      final apiContainers = await _apiClient!.getContainerSecurity();
      super.containers.clear();
      super.containers.addAll(apiContainers);
      
      // Cache for offline use
      await _cacheService.cacheThreats(super.threats);
      
      _error = null;
    } catch (e) {
      _error = 'Failed to load data from API: $e';
      
      // Try to load from cache for offline support
      final cachedThreats = await _cacheService.get<List>('emerging_threats');
      
      if (cachedThreats != null) {
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
    
    // Auto-refresh every 60 seconds for threat monitoring
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (_apiClient != null) {
        _loadRealData();
      }
    });
  }
  
  Future<void> refreshData() async {
    if (_apiClient != null) {
      // Debounce refresh requests
      _optimizer.debounce('refresh_threats', () async {
        await _loadRealData();
      });
    }
  }
  
  Future<bool> mitigateThreat(String threatId, String mitigation) async {
    if (_apiClient != null) {
      try {
        final success = await _apiClient!.mitigateThreat(threatId, mitigation);
        if (success) {
          // Update local state - commented out as threat model doesn't have these properties
          // final threat = super.threats.firstWhere((t) => t.id == threatId);
          // threat.mitigations.add(mitigation);
          // threat.isActive = false;
          notifyListeners();
          
          // Refresh data from server
          await _loadRealData();
        }
        return success;
      } catch (e) {
        print('Error mitigating threat via API: $e');
        return false;
      }
    }
    return false;
  }
  
  @override
  Map<String, dynamic> getThreatSummary() {
    if (_isLoading) {
      return {
        'totalThreats': 0,
        'activeThreats': 0,
        'criticalThreats': 0,
        'vulnerableDevices': 0,
        'nonCompliantContainers': 0,
      };
    }
    return super.getThreatSummary();
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    _apiClient?.dispose();
    _optimizer.dispose();
    super.dispose();
  }
}
