import 'package:flutter/foundation.dart';
import 'api_service.dart';

class SessionManagementService extends ChangeNotifier {
  final ApiService _apiService;
  List<UserSession> _sessions = [];
  bool _isLoading = false;
  String? _error;

  SessionManagementService(this._apiService);

  List<UserSession> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> loadUserSessions(String userId) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.get<List<dynamic>>('/api/users/$userId/sessions');
      
      if (response.isSuccess && response.data != null) {
        _sessions = response.data!
            .map((sessionData) => UserSession.fromJson(sessionData))
            .toList();
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Failed to load sessions';
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

  Future<bool> terminateSession(String sessionId) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.delete('/api/sessions/$sessionId');
      
      if (response.isSuccess) {
        _sessions.removeWhere((session) => session.id == sessionId);
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Failed to terminate session';
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

  Future<bool> terminateAllOtherSessions(String currentSessionId) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.post('/api/sessions/terminate-others', 
          body: {'currentSessionId': currentSessionId});
      
      if (response.isSuccess) {
        _sessions.removeWhere((session) => session.id != currentSessionId);
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Failed to terminate sessions';
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

  Future<bool> refreshSessionActivity(String sessionId) async {
    try {
      final response = await _apiService.put('/api/sessions/$sessionId/refresh');
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  UserSession? getCurrentSession() {
    return _sessions.firstWhere(
      (session) => session.isCurrent,
      orElse: () => _sessions.isNotEmpty ? _sessions.first : UserSession(
        id: 'unknown',
        userId: 'unknown',
        deviceName: 'Current Device',
        deviceType: 'Unknown',
        ipAddress: '0.0.0.0',
        location: 'Unknown',
        userAgent: 'Unknown',
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
        isCurrent: true,
      ),
    );
  }

  int get activeSessionCount => _sessions.length;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
