import 'package:flutter/foundation.dart';
import 'api_service.dart';

class SecurityDataService extends ChangeNotifier {
  final ApiService _apiService;
  SecurityData? _securityData;
  bool _isLoading = false;
  String? _error;

  SecurityDataService(this._apiService);

  SecurityData? get securityData => _securityData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get securityScore => _securityData?.securityScore ?? 0;
  int get activeSessions => _securityData?.activeSessions ?? 0;
  int get recentAlerts => _securityData?.recentAlerts ?? 0;
  List<SecurityAlert> get alerts => _securityData?.alerts ?? [];

  Future<bool> loadSecurityData(String userId) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.get<Map<String, dynamic>>('/api/users/$userId/security');
      
      if (response.isSuccess && response.data != null) {
        _securityData = SecurityData.fromJson(response.data!);
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Failed to load security data';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> acknowledgeAlert(String alertId) async {
    try {
      final response = await _apiService.put('/api/security/alerts/$alertId/acknowledge');
      
      if (response.isSuccess) {
        if (_securityData != null) {
          final updatedAlerts = _securityData!.alerts.map((alert) {
            if (alert.id == alertId) {
              return SecurityAlert(
                id: alert.id,
                type: alert.type,
                message: alert.message,
                severity: alert.severity,
                timestamp: alert.timestamp,
                acknowledged: true,
              );
            }
            return alert;
          }).toList();
          
          _securityData = SecurityData(
            securityScore: _securityData!.securityScore,
            lastSecurityCheck: _securityData!.lastSecurityCheck,
            activeSessions: _securityData!.activeSessions,
            recentAlerts: _securityData!.recentAlerts,
            backupCodesGenerated: _securityData!.backupCodesGenerated,
            passwordLastChanged: _securityData!.passwordLastChanged,
            alerts: updatedAlerts,
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> runSecurityScan(String userId) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.post('/api/users/$userId/security/scan');
      
      if (response.isSuccess) {
        // Reload security data after scan
        await loadSecurityData(userId);
        return true;
      } else {
        _error = response.error ?? 'Security scan failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> getSecurityMetrics(String userId, int days) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/api/users/$userId/security/metrics',
        queryParams: {'days': days},
      );
      
      if (response.isSuccess) {
        return response.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
