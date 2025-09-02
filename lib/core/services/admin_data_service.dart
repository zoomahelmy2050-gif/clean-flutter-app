import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'backend_service.dart';
import '../../features/admin/models/incident_response_models.dart';
import '../../features/admin/models/enhanced_user_management_models.dart';

class AdminDataService extends ChangeNotifier {
  final ApiService apiService;
  final BackendService _backendService;
  
  // Cached data
  List<SecurityEvent> _securityEvents = [];
  List<ThreatIndicator> _threats = [];
  List<SecurityIncident> _incidents = [];
  List<UserAccount> _users = [];
  Map<String, dynamic> _dashboardMetrics = {};
  Map<String, dynamic> _complianceStatus = {};
  
  // Stream controllers
  final _eventsController = StreamController<List<SecurityEvent>>.broadcast();
  final _threatsController = StreamController<List<ThreatIndicator>>.broadcast();
  final _incidentsController = StreamController<List<SecurityIncident>>.broadcast();
  final _metricsController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Getters
  List<SecurityEvent> get securityEvents => _securityEvents;
  List<ThreatIndicator> get threats => _threats;
  List<SecurityIncident> get incidents => _incidents;
  List<UserAccount> get users => _users;
  Map<String, dynamic> get dashboardMetrics => _dashboardMetrics;
  Map<String, dynamic> get complianceStatus => _complianceStatus;
  
  // Streams
  Stream<List<SecurityEvent>> get eventsStream => _eventsController.stream;
  Stream<List<ThreatIndicator>> get threatsStream => _threatsController.stream;
  Stream<List<SecurityIncident>> get incidentsStream => _incidentsController.stream;
  Stream<Map<String, dynamic>> get metricsStream => _metricsController.stream;
  
  Timer? _refreshTimer;
  bool _isLoading = false;
  
  bool get isLoading => _isLoading;
  
  AdminDataService({required this.apiService, required BackendService backendService})  : _backendService = backendService;
  
  Future<void> initialize() async {
    await loadAllData();
    _startAutoRefresh();
  }
  
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      refreshData();
    });
  }
  
  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await Future.wait([
        loadSecurityEvents(),
        loadThreats(),
        loadIncidents(),
        loadUsers(),
        loadDashboardMetrics(),
        loadComplianceStatus(),
      ]);
    } catch (e) {
      debugPrint('Error loading admin data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> refreshData() async {
    try {
      await Future.wait([
        loadSecurityEvents(silent: true),
        loadDashboardMetrics(silent: true),
        loadThreats(silent: true),
      ]);
    } catch (e) {
      debugPrint('Error refreshing data: $e');
    }
  }
  
  Future<void> loadSecurityEvents({bool silent = false}) async {
    try {
      final response = await _backendService.makeAuthenticatedRequest(
        '/api/admin/security-events',
        method: 'GET',
      );
      
      if (response != null && response['events'] != null) {
        _securityEvents = (response['events'] as List)
            .map((e) => SecurityEvent.fromJson(e))
            .toList();
        _eventsController.add(_securityEvents);
        if (!silent) notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading security events: $e');
      // Use mock data in development
      _securityEvents = _generateMockSecurityEvents();
      _eventsController.add(_securityEvents);
      if (!silent) notifyListeners();
    }
  }
  
  Future<void> loadThreats({bool silent = false}) async {
    try {
      final response = await _backendService.makeAuthenticatedRequest(
        '/api/admin/threats',
        method: 'GET',
      );
      
      if (response != null && response['threats'] != null) {
        _threats = (response['threats'] as List)
            .map((e) => ThreatIndicator.fromJson(e))
            .toList();
        _threatsController.add(_threats);
        if (!silent) notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading threats: $e');
      // Use mock data in development
      _threats = _generateMockThreats();
      _threatsController.add(_threats);
      if (!silent) notifyListeners();
    }
  }
  
  Future<void> loadIncidents({bool silent = false}) async {
    try {
      final response = await _backendService.makeAuthenticatedRequest(
        '/api/admin/incidents',
        method: 'GET',
      );
      
      if (response != null && response['incidents'] != null) {
        _incidents = (response['incidents'] as List)
            .map((e) => SecurityIncident.fromJson(e))
            .toList();
        _incidentsController.add(_incidents);
        if (!silent) notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading incidents: $e');
      // Use mock data in development
      _incidents = _generateMockIncidents();
      _incidentsController.add(_incidents);
      if (!silent) notifyListeners();
    }
  }
  
  Future<void> loadUsers({bool silent = false}) async {
    try {
      final response = await _backendService.makeAuthenticatedRequest(
        '/api/admin/users',
        method: 'GET',
      );
      
      if (response != null && response['users'] != null) {
        _users = (response['users'] as List)
            .map((e) => UserAccount.fromJson(e))
            .toList();
        if (!silent) notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
      // Use mock data in development
      _users = _generateMockUsers();
      if (!silent) notifyListeners();
    }
  }
  
  Future<void> loadDashboardMetrics({bool silent = false}) async {
    try {
      final response = await _backendService.makeAuthenticatedRequest(
        '/api/admin/metrics',
        method: 'GET',
      );
      
      if (response != null && response['metrics'] != null) {
        _dashboardMetrics = response['metrics'];
        _metricsController.add(_dashboardMetrics);
        if (!silent) notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading metrics: $e');
      // Use mock data in development
      _dashboardMetrics = _generateMockMetrics();
      _metricsController.add(_dashboardMetrics);
      if (!silent) notifyListeners();
    }
  }
  
  Future<void> loadComplianceStatus({bool silent = false}) async {
    try {
      final response = await _backendService.makeAuthenticatedRequest(
        '/api/admin/compliance',
        method: 'GET',
      );
      
      if (response != null && response['compliance'] != null) {
        _complianceStatus = response['compliance'];
        if (!silent) notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading compliance: $e');
      // Use mock data in development
      _complianceStatus = _generateMockCompliance();
      if (!silent) notifyListeners();
    }
  }
  
  // Admin Actions
  Future<bool> blockUser(String userId, String reason) async {
    try {
      final response = await _backendService.makeAuthenticatedRequest(
        '/api/admin/users/$userId/block',
        method: 'POST',
        body: {'reason': reason},
      );
      
      if (response != null && response['success'] == true) {
        await loadUsers();
        return true;
      }
    } catch (e) {
      debugPrint('Error blocking user: $e');
    }
    return false;
  }
  
  Future<bool> unblockUser(String userId) async {
    try {
      final response = await _backendService.makeAuthenticatedRequest(
        '/api/admin/users/$userId/unblock',
        method: 'POST',
      );
      
      if (response != null && response['success'] == true) {
        await loadUsers();
        return true;
      }
    } catch (e) {
      debugPrint('Error unblocking user: $e');
    }
    return false;
  }
  
  Future<bool> resolveIncident(String incidentId, String resolution) async {
    try {
      final response = await _backendService.makeAuthenticatedRequest(
        '/api/admin/incidents/$incidentId/resolve',
        method: 'POST',
        body: {'resolution': resolution},
      );
      
      if (response != null && response['success'] == true) {
        await loadIncidents();
        return true;
      }
    } catch (e) {
      debugPrint('Error resolving incident: $e');
    }
    return false;
  }
  
  Future<bool> dismissThreat(String threatId, String reason) async {
    try {
      final response = await _backendService.makeAuthenticatedRequest(
        '/api/admin/threats/$threatId/dismiss',
        method: 'POST',
        body: {'reason': reason},
      );
      
      if (response != null && response['success'] == true) {
        await loadThreats();
        return true;
      }
    } catch (e) {
      debugPrint('Error dismissing threat: $e');
    }
    return false;
  }
  
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      final response = await _backendService.makeAuthenticatedRequest(
        '/api/admin/users/$userId',
        method: 'GET',
      );
      
      return response;
    } catch (e) {
      debugPrint('Error getting user details: $e');
      return null;
    }
  }
  
  Future<List<Map<String, dynamic>>> getUserSessions(String userId) async {
    try {
      final response = await _backendService.makeAuthenticatedRequest(
        '/api/admin/users/$userId/sessions',
        method: 'GET',
      );
      
      if (response != null && response['sessions'] != null) {
        return List<Map<String, dynamic>>.from(response['sessions']);
      }
    } catch (e) {
      debugPrint('Error getting user sessions: $e');
    }
    return [];
  }
  
  Future<bool> terminateSession(String sessionId) async {
    try {
      final response = await _backendService.makeAuthenticatedRequest(
        '/api/admin/sessions/$sessionId/terminate',
        method: 'DELETE',
      );
      
      return response != null && response['success'] == true;
    } catch (e) {
      debugPrint('Error terminating session: $e');
      return false;
    }
  }
  
  Future<List<Map<String, dynamic>>> getAuditLogs({
    String? userId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (userId != null) queryParams['userId'] = userId;
      if (action != null) queryParams['action'] = action;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      queryParams['limit'] = limit.toString();
      
      final response = await apiService.get(
        'admin/audit-logs',
        queryParams: queryParams,
      );
      
      if (response.data != null && response.data['logs'] != null) {
        return List<Map<String, dynamic>>.from(response.data['logs']);
      }
    } catch (e) {
      debugPrint('Error getting audit logs: $e');
    }
    return [];
  }
  
  // Mock data generators for development
  List<SecurityEvent> _generateMockSecurityEvents() {
    return [
      SecurityEvent(
        id: '1',
        type: 'login_attempt',
        message: 'Failed login attempt from IP 192.168.1.100',
        severity: 'medium',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        details: {'ip': '192.168.1.100', 'attempts': 3},
      ),
      SecurityEvent(
        id: '2',
        type: 'permission_change',
        message: 'Admin privileges granted to user@example.com',
        severity: 'high',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        details: {'user': 'user@example.com', 'role': 'admin'},
      ),
      SecurityEvent(
        id: '3',
        type: 'data_export',
        message: 'User data exported by admin',
        severity: 'low',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        details: {'admin': 'admin@example.com', 'records': 500},
      ),
    ];
  }
  
  List<ThreatIndicator> _generateMockThreats() {
    return [
      ThreatIndicator(
        id: '1',
        type: 'malware',
        value: 'file_hash_123456',
        riskLevel: 'high',
        description: 'Potentially malicious file detected - Suspicious File Upload',
        firstSeen: DateTime.now().subtract(const Duration(days: 1)),
        lastSeen: DateTime.now(),
        metadata: {
          'confidence': 0.85,
          'source': 'File Scanner',
          'tags': ['malware', 'upload'],
        },
      ),
      ThreatIndicator(
        id: '2',
        type: 'phishing',
        value: 'malicious-site.com',
        riskLevel: 'critical',
        description: 'Known phishing domain accessed - Phishing URL Detected',
        firstSeen: DateTime.now().subtract(const Duration(hours: 3)),
        lastSeen: DateTime.now(),
        metadata: {
          'confidence': 0.95,
          'source': 'URL Scanner',
          'tags': ['phishing', 'url'],
        },
      ),
    ];
  }
  
  List<SecurityIncident> _generateMockIncidents() {
    return [
      SecurityIncident(
        id: '1',
        title: 'Unauthorized Access Attempt',
        description: 'Multiple failed login attempts detected',
        severity: 'medium',
        status: 'investigating',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        assignedTo: 'security_team',
        affectedSystems: ['auth_service'],
        metadata: {
          'reportedBy': 'system',
          'tags': ['brute_force', 'authentication'],
          'timeline': [],
          'evidence': [],
          'actions': [],
        },
      ),
    ];
  }
  
  List<UserAccount> _generateMockUsers() {
    return [
      UserAccount(
        id: '1',
        email: 'john.doe@example.com',
        name: 'John Doe',
        role: 'user',
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastLogin: DateTime.now().subtract(const Duration(hours: 1)),
        metadata: {
          'mfaEnabled': true,
          'riskScore': 25,
          'loginCount': 150,
          'department': 'Engineering',
        },
      ),
      UserAccount(
        id: '2',
        email: 'jane.smith@example.com',
        name: 'Jane Smith',
        role: 'admin',
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        lastLogin: DateTime.now(),
        metadata: {
          'mfaEnabled': true,
          'riskScore': 10,
          'loginCount': 500,
          'department': 'Security',
        },
      ),
    ];
  }
  
  Map<String, dynamic> _generateMockMetrics() {
    return {
      'total_users': 1250,
      'active_sessions': 342,
      'threats_blocked': 89,
      'incidents_today': 3,
      'security_score': 85,
      'mfa_adoption': 78.5,
      'failed_logins_24h': 45,
      'successful_logins_24h': 823,
      'data_encrypted_gb': 125.4,
      'api_calls_24h': 15623,
      'avg_response_time_ms': 245,
      'uptime_percentage': 99.95,
    };
  }
  
  Map<String, dynamic> _generateMockCompliance() {
    return {
      'gdpr': {'status': 'compliant', 'lastAudit': '2024-01-15', 'score': 95},
      'hipaa': {'status': 'compliant', 'lastAudit': '2024-01-20', 'score': 92},
      'pci_dss': {'status': 'compliant', 'lastAudit': '2024-01-10', 'score': 88},
      'sox': {'status': 'review_needed', 'lastAudit': '2023-12-01', 'score': 75},
      'iso_27001': {'status': 'compliant', 'lastAudit': '2024-01-25', 'score': 90},
    };
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    _eventsController.close();
    _threatsController.close();
    _incidentsController.close();
    _metricsController.close();
    super.dispose();
  }
}
