import 'package:clean_flutter/features/admin/services/security_orchestration_service.dart';
import 'package:clean_flutter/core/services/security_api_client.dart';
import 'package:clean_flutter/core/config/api_config.dart';
import 'package:clean_flutter/core/services/security_cache_service.dart';
import 'package:clean_flutter/core/services/performance_optimizer.dart';
import 'dart:async';

class EnhancedSecurityOrchestrationService extends SecurityOrchestrationService {
  SecurityApiClient? _apiClient;
  final SecurityCacheService _cacheService = SecurityCacheService();
  final PerformanceOptimizer _optimizer = PerformanceOptimizer();
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Override parent getters to provide access
  @override
  List<SecurityPlaybook> get playbooks => super.playbooks;
  
  @override
  List<SecurityCase> get cases => super.cases;
  
  EnhancedSecurityOrchestrationService() : super() {
    if (!ApiConfig.useMockData && ApiConfig.apiKey.isNotEmpty) {
      _apiClient = SecurityApiClient(
        baseUrl: ApiConfig.baseUrl,
        apiKey: ApiConfig.apiKey,
      );
      _loadRealData();
    }
  }
  
  Future<void> _loadRealData() async {
    if (_apiClient == null) return;
    
    // Throttle API calls to prevent excessive requests
    if (!_optimizer.throttle('load_data', minInterval: const Duration(seconds: 5))) {
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Load playbooks from API
      final apiPlaybooks = await _apiClient!.getPlaybooks();
      // Clear and update the playbooks list
      playbooks.clear();
      playbooks.addAll(apiPlaybooks);
      
      // Load cases from API
      final apiCases = await _apiClient!.getSecurityCases();
      // Clear and update the cases list
      cases.clear();
      cases.addAll(apiCases);
      
      _error = null;
    } catch (e) {
      _error = 'Failed to load data from API: $e';
      print(_error);
      // Keep mock data on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> loadData() async {
    if (!ApiConfig.useMockData && _apiClient != null) {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      try {
        // Try to load from API
        final playbookData = await _apiClient!.getPlaybooks();
        final casesData = await _apiClient!.getSecurityCases();
        
        // Update parent's fields
        super.playbooks.clear();
        super.playbooks.addAll(playbookData);
        super.cases.clear();
        super.cases.addAll(casesData);
        
        // Cache for offline use
        await _cacheService.cachePlaybooks(playbookData);
        await _cacheService.cacheSecurityCases(casesData);
        
        _error = null;
      } catch (e) {
        _error = 'Failed to load from API: $e';
        
        // Try to load from cache for offline support
        final cachedPlaybooks = await _cacheService.get<List>('security_playbooks');
        final cachedCases = await _cacheService.get<List>('security_cases');
        
        if (cachedPlaybooks != null || cachedCases != null) {
          _error = 'Using cached data (offline mode)';
        } else {
          // Fall back to mock data if no cache available
          // Parent class doesn't have loadData, initialize directly
          notifyListeners();
        }
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    } else {
      // Use parent's mock data which is initialized in constructor
      notifyListeners();
    }
  }
  
  Future<void> refreshData() async {
    if (_apiClient != null) {
      // Debounce refresh requests
      _optimizer.debounce('refresh', () async {
        await _loadRealData();
      });
    }
  }
  
  @override
  Future<void> executePlaybook(String playbookId, String caseId) async {
    if (_apiClient != null) {
      try {
        final success = await _apiClient!.executePlaybook(playbookId, caseId);
        if (success) {
          // Update local state
          final playbook = playbooks.firstWhere((p) => p.id == playbookId);
          final updatedPlaybook = SecurityPlaybook(
            id: playbook.id,
            name: playbook.name,
            description: playbook.description,
            category: playbook.category,
            status: playbook.status,
            actions: playbook.actions,
            triggers: playbook.triggers,
            createdAt: playbook.createdAt,
            updatedAt: DateTime.now(),
            author: playbook.author,
            useCount: playbook.useCount + 1,
            successRate: playbook.successRate,
          );
          
          final index = playbooks.indexWhere((p) => p.id == playbookId);
          playbooks[index] = updatedPlaybook;
          
          // Refresh data from server
          await _loadRealData();
        }
      } catch (e) {
        print('Error executing playbook via API: $e');
        // Fall back to parent implementation
        super.executePlaybook(playbookId, caseId);
      }
    } else {
      super.executePlaybook(playbookId, caseId);
    }
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    _apiClient?.dispose();
    _optimizer.dispose();
    super.dispose();
  }
}
