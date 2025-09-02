import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

class RealTimeMonitoringService extends ChangeNotifier {
  static final RealTimeMonitoringService _instance = RealTimeMonitoringService._internal();
  factory RealTimeMonitoringService() => _instance;
  RealTimeMonitoringService._internal();

  final Random _random = Random();
  Timer? _monitoringTimer;
  bool _isMonitoring = false;

  // Streams for real-time data
  final StreamController<Map<String, dynamic>> _systemMetricsController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _securityEventsController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _networkTrafficController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get systemMetricsStream => _systemMetricsController.stream;
  Stream<Map<String, dynamic>> get securityEventsStream => _securityEventsController.stream;
  Stream<Map<String, dynamic>> get networkTrafficStream => _networkTrafficController.stream;

  bool get isMonitoring => _isMonitoring;

  void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _monitoringTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _generateSystemMetrics();
      _generateSecurityEvents();
      _generateNetworkTraffic();
    });
    notifyListeners();
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    notifyListeners();
  }

  void _generateSystemMetrics() {
    final metrics = {
      'timestamp': DateTime.now().toIso8601String(),
      'cpuUsage': _random.nextDouble() * 100,
      'memoryUsage': _random.nextDouble() * 100,
      'diskUsage': _random.nextDouble() * 100,
      'networkLatency': _random.nextInt(100) + 10,
      'activeConnections': _random.nextInt(1000) + 100,
      'systemLoad': _random.nextDouble() * 5,
    };
    _systemMetricsController.add(metrics);
  }

  void _generateSecurityEvents() {
    final events = [
      'Failed login attempt',
      'Suspicious file access',
      'Unusual network activity',
      'Malware detection',
      'Policy violation',
      'Privilege escalation attempt',
    ];

    if (_random.nextBool()) {
      final event = {
        'timestamp': DateTime.now().toIso8601String(),
        'type': events[_random.nextInt(events.length)],
        'severity': ['low', 'medium', 'high', 'critical'][_random.nextInt(4)],
        'source': 'System Monitor',
        'details': 'Automated security event detection',
      };
      _securityEventsController.add(event);
    }
  }

  void _generateNetworkTraffic() {
    final traffic = {
      'timestamp': DateTime.now().toIso8601String(),
      'inboundTraffic': _random.nextInt(1000000) + 100000,
      'outboundTraffic': _random.nextInt(1000000) + 100000,
      'packetsPerSecond': _random.nextInt(10000) + 1000,
      'connectionCount': _random.nextInt(500) + 50,
      'blockedRequests': _random.nextInt(100),
    };
    _networkTrafficController.add(traffic);
  }

  Future<Map<String, dynamic>> getCurrentSystemStatus() async {
    return {
      'status': 'operational',
      'uptime': '${_random.nextInt(30) + 1} days',
      'lastCheck': DateTime.now().toIso8601String(),
      'services': {
        'database': _random.nextBool(),
        'api': _random.nextBool(),
        'authentication': true,
        'monitoring': _isMonitoring,
      },
      'alerts': _random.nextInt(5),
      'warnings': _random.nextInt(10),
    };
  }

  Future<List<Map<String, dynamic>>> getRecentAlerts() async {
    final alerts = <Map<String, dynamic>>[];
    final alertTypes = [
      'High CPU usage detected',
      'Memory threshold exceeded',
      'Disk space running low',
      'Unusual login pattern',
      'Network anomaly detected',
    ];

    for (int i = 0; i < _random.nextInt(5) + 1; i++) {
      alerts.add({
        'id': 'alert_${DateTime.now().millisecondsSinceEpoch}_$i',
        'type': alertTypes[_random.nextInt(alertTypes.length)],
        'severity': ['low', 'medium', 'high'][_random.nextInt(3)],
        'timestamp': DateTime.now().subtract(Duration(minutes: _random.nextInt(60))).toIso8601String(),
        'acknowledged': _random.nextBool(),
      });
    }

    return alerts;
  }

  void acknowledgeAlert(String alertId) {
    // Mock acknowledgment
    notifyListeners();
  }

  @override
  void dispose() {
    stopMonitoring();
    _systemMetricsController.close();
    _securityEventsController.close();
    _networkTrafficController.close();
    super.dispose();
  }
}
