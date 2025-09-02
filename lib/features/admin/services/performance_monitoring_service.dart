import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

// Enums
enum ServiceStatus { healthy, degraded, critical, unknown }
enum MetricType { cpu, memory, network, storage, latency, throughput }
enum AlertSeverity { info, warning, error, critical }

// Models
class SystemMetric {
  final String id;
  final String name;
  final MetricType type;
  final double value;
  final double threshold;
  final String unit;
  final ServiceStatus status;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  SystemMetric({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.threshold,
    required this.unit,
    required this.status,
    required this.timestamp,
    required this.metadata,
  });
}

class ServiceLevelAgreement {
  final String id;
  final String name;
  final String description;
  final double targetUptime;
  final double currentUptime;
  final int incidentCount;
  final Duration averageResponseTime;
  final Duration targetResponseTime;
  final DateTime periodStart;
  final DateTime periodEnd;
  final bool isCompliant;

  ServiceLevelAgreement({
    required this.id,
    required this.name,
    required this.description,
    required this.targetUptime,
    required this.currentUptime,
    required this.incidentCount,
    required this.averageResponseTime,
    required this.targetResponseTime,
    required this.periodStart,
    required this.periodEnd,
    required this.isCompliant,
  });
}

class CapacityPlan {
  final String id;
  final String resource;
  final double currentUsage;
  final double projectedUsage;
  final double capacity;
  final DateTime projectionDate;
  final String recommendation;
  final Map<String, double> historicalData;

  CapacityPlan({
    required this.id,
    required this.resource,
    required this.currentUsage,
    required this.projectedUsage,
    required this.capacity,
    required this.projectionDate,
    required this.recommendation,
    required this.historicalData,
  });
}

class PerformanceAlert {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final DateTime timestamp;
  final String source;
  final Map<String, dynamic> context;
  final bool acknowledged;

  PerformanceAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.timestamp,
    required this.source,
    required this.context,
    required this.acknowledged,
  });
}

class ServiceHealth {
  final String name;
  final ServiceStatus status;
  final double uptime;
  final int requestCount;
  final double avgLatency;
  final double errorRate;
  final DateTime lastChecked;

  ServiceHealth({
    required this.name,
    required this.status,
    required this.uptime,
    required this.requestCount,
    required this.avgLatency,
    required this.errorRate,
    required this.lastChecked,
  });
}

// Service
class PerformanceMonitoringService extends ChangeNotifier {
  final List<SystemMetric> _metrics = [];
  final List<ServiceLevelAgreement> _slas = [];
  final List<CapacityPlan> _capacityPlans = [];
  final List<PerformanceAlert> _alerts = [];
  final List<ServiceHealth> _services = [];
  Timer? _metricsTimer;
  final Random _random = Random();

  List<SystemMetric> get metrics => _metrics;
  List<ServiceLevelAgreement> get slas => _slas;
  List<CapacityPlan> get capacityPlans => _capacityPlans;
  List<PerformanceAlert> get alerts => _alerts.where((a) => !a.acknowledged).toList();
  List<ServiceHealth> get services => _services;

  PerformanceMonitoringService() {
    _initializeMockData();
    _startMetricsCollection();
  }

  void _initializeMockData() {
    // Initialize metrics
    _updateMetrics();

    // Initialize SLAs
    _slas.addAll([
      ServiceLevelAgreement(
        id: 'sla_001',
        name: 'API Availability',
        description: 'Main API endpoint availability',
        targetUptime: 99.9,
        currentUptime: 99.92,
        incidentCount: 2,
        averageResponseTime: const Duration(milliseconds: 245),
        targetResponseTime: const Duration(milliseconds: 300),
        periodStart: DateTime.now().subtract(const Duration(days: 30)),
        periodEnd: DateTime.now(),
        isCompliant: true,
      ),
      ServiceLevelAgreement(
        id: 'sla_002',
        name: 'Database Performance',
        description: 'Database query response time',
        targetUptime: 99.95,
        currentUptime: 99.87,
        incidentCount: 5,
        averageResponseTime: const Duration(milliseconds: 120),
        targetResponseTime: const Duration(milliseconds: 100),
        periodStart: DateTime.now().subtract(const Duration(days: 30)),
        periodEnd: DateTime.now(),
        isCompliant: false,
      ),
      ServiceLevelAgreement(
        id: 'sla_003',
        name: 'Authentication Service',
        description: 'Auth service availability and performance',
        targetUptime: 99.99,
        currentUptime: 99.98,
        incidentCount: 1,
        averageResponseTime: const Duration(milliseconds: 150),
        targetResponseTime: const Duration(milliseconds: 200),
        periodStart: DateTime.now().subtract(const Duration(days: 30)),
        periodEnd: DateTime.now(),
        isCompliant: true,
      ),
    ]);

    // Initialize capacity plans
    _capacityPlans.addAll([
      CapacityPlan(
        id: 'cap_001',
        resource: 'Storage',
        currentUsage: 75.2,
        projectedUsage: 92.5,
        capacity: 100.0,
        projectionDate: DateTime.now().add(const Duration(days: 30)),
        recommendation: 'Consider increasing storage capacity by 50GB',
        historicalData: {
          '7d': 72.1,
          '14d': 70.5,
          '21d': 68.3,
          '30d': 65.0,
        },
      ),
      CapacityPlan(
        id: 'cap_002',
        resource: 'CPU Cores',
        currentUsage: 45.8,
        projectedUsage: 58.2,
        capacity: 100.0,
        projectionDate: DateTime.now().add(const Duration(days: 30)),
        recommendation: 'Current capacity sufficient for next 3 months',
        historicalData: {
          '7d': 44.2,
          '14d': 42.8,
          '21d': 41.5,
          '30d': 40.0,
        },
      ),
      CapacityPlan(
        id: 'cap_003',
        resource: 'Network Bandwidth',
        currentUsage: 62.3,
        projectedUsage: 78.9,
        capacity: 100.0,
        projectionDate: DateTime.now().add(const Duration(days: 30)),
        recommendation: 'Monitor closely, may need upgrade in 2 months',
        historicalData: {
          '7d': 60.5,
          '14d': 58.2,
          '21d': 55.7,
          '30d': 52.0,
        },
      ),
    ]);

    // Initialize services
    _services.addAll([
      ServiceHealth(
        name: 'Web Application',
        status: ServiceStatus.healthy,
        uptime: 99.95,
        requestCount: 1245678,
        avgLatency: 145.2,
        errorRate: 0.12,
        lastChecked: DateTime.now(),
      ),
      ServiceHealth(
        name: 'API Gateway',
        status: ServiceStatus.healthy,
        uptime: 99.98,
        requestCount: 3456789,
        avgLatency: 89.5,
        errorRate: 0.08,
        lastChecked: DateTime.now(),
      ),
      ServiceHealth(
        name: 'Database Cluster',
        status: ServiceStatus.degraded,
        uptime: 99.87,
        requestCount: 5678901,
        avgLatency: 234.7,
        errorRate: 0.45,
        lastChecked: DateTime.now(),
      ),
      ServiceHealth(
        name: 'Cache Service',
        status: ServiceStatus.healthy,
        uptime: 99.99,
        requestCount: 8901234,
        avgLatency: 12.3,
        errorRate: 0.02,
        lastChecked: DateTime.now(),
      ),
      ServiceHealth(
        name: 'Message Queue',
        status: ServiceStatus.healthy,
        uptime: 99.91,
        requestCount: 234567,
        avgLatency: 56.8,
        errorRate: 0.15,
        lastChecked: DateTime.now(),
      ),
    ]);

    // Initialize alerts
    _alerts.addAll([
      PerformanceAlert(
        id: 'alert_001',
        title: 'High Memory Usage',
        description: 'Memory usage exceeded 85% threshold',
        severity: AlertSeverity.warning,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        source: 'Server-01',
        context: {'usage': 87.3, 'threshold': 85.0},
        acknowledged: false,
      ),
      PerformanceAlert(
        id: 'alert_002',
        title: 'Slow Database Queries',
        description: 'Multiple queries exceeding 1s response time',
        severity: AlertSeverity.error,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        source: 'Database Cluster',
        context: {'avgTime': 1.45, 'queryCount': 23},
        acknowledged: false,
      ),
    ]);
  }

  void _startMetricsCollection() {
    _metricsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _updateMetrics();
      _generateRandomAlert();
      _updateServiceHealth();
      notifyListeners();
    });
  }

  void _updateMetrics() {
    _metrics.clear();
    
    // CPU Metrics
    final cpuValue = 35 + _random.nextDouble() * 30;
    _metrics.add(SystemMetric(
      id: 'metric_cpu',
      name: 'CPU Usage',
      type: MetricType.cpu,
      value: cpuValue,
      threshold: 80.0,
      unit: '%',
      status: _getMetricStatus(cpuValue, 80.0),
      timestamp: DateTime.now(),
      metadata: {'cores': 8, 'model': 'Intel Xeon'},
    ));

    // Memory Metrics
    final memValue = 50 + _random.nextDouble() * 35;
    _metrics.add(SystemMetric(
      id: 'metric_mem',
      name: 'Memory Usage',
      type: MetricType.memory,
      value: memValue,
      threshold: 85.0,
      unit: '%',
      status: _getMetricStatus(memValue, 85.0),
      timestamp: DateTime.now(),
      metadata: {'total': '32GB', 'available': '${(32 * (100 - memValue) / 100).toStringAsFixed(1)}GB'},
    ));

    // Network Metrics
    final netValue = 100 + _random.nextDouble() * 400;
    _metrics.add(SystemMetric(
      id: 'metric_net',
      name: 'Network Throughput',
      type: MetricType.network,
      value: netValue,
      threshold: 800.0,
      unit: 'Mbps',
      status: _getMetricStatus(netValue, 800.0),
      timestamp: DateTime.now(),
      metadata: {'interface': 'eth0', 'packets_dropped': _random.nextInt(10)},
    ));

    // Storage Metrics
    final storageValue = 60 + _random.nextDouble() * 20;
    _metrics.add(SystemMetric(
      id: 'metric_storage',
      name: 'Storage Usage',
      type: MetricType.storage,
      value: storageValue,
      threshold: 90.0,
      unit: '%',
      status: _getMetricStatus(storageValue, 90.0),
      timestamp: DateTime.now(),
      metadata: {'total': '1TB', 'filesystem': 'ext4'},
    ));

    // Latency Metrics
    final latencyValue = 50 + _random.nextDouble() * 200;
    _metrics.add(SystemMetric(
      id: 'metric_latency',
      name: 'API Latency',
      type: MetricType.latency,
      value: latencyValue,
      threshold: 300.0,
      unit: 'ms',
      status: _getMetricStatus(latencyValue, 300.0),
      timestamp: DateTime.now(),
      metadata: {'p95': latencyValue * 1.5, 'p99': latencyValue * 2},
    ));

    // Throughput Metrics
    final throughputValue = 500 + _random.nextDouble() * 1000;
    _metrics.add(SystemMetric(
      id: 'metric_throughput',
      name: 'Request Throughput',
      type: MetricType.throughput,
      value: throughputValue,
      threshold: 2000.0,
      unit: 'req/s',
      status: ServiceStatus.healthy,
      timestamp: DateTime.now(),
      metadata: {'success_rate': 99.8 - _random.nextDouble() * 0.5},
    ));
  }

  ServiceStatus _getMetricStatus(double value, double threshold) {
    if (value < threshold * 0.7) return ServiceStatus.healthy;
    if (value < threshold * 0.9) return ServiceStatus.degraded;
    return ServiceStatus.critical;
  }

  void _generateRandomAlert() {
    if (_random.nextDouble() > 0.92) {
      final alertTypes = [
        {'title': 'High CPU Usage', 'desc': 'CPU usage spike detected', 'severity': AlertSeverity.warning},
        {'title': 'Memory Leak Detected', 'desc': 'Gradual memory increase in service', 'severity': AlertSeverity.error},
        {'title': 'Disk Space Low', 'desc': 'Less than 10% disk space remaining', 'severity': AlertSeverity.critical},
        {'title': 'Network Congestion', 'desc': 'High packet loss detected', 'severity': AlertSeverity.warning},
        {'title': 'Service Degradation', 'desc': 'Response times increasing', 'severity': AlertSeverity.error},
      ];
      
      final alert = alertTypes[_random.nextInt(alertTypes.length)];
      _alerts.add(PerformanceAlert(
        id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
        title: alert['title'] as String,
        description: alert['desc'] as String,
        severity: alert['severity'] as AlertSeverity,
        timestamp: DateTime.now(),
        source: 'System Monitor',
        context: {},
        acknowledged: false,
      ));
    }
  }

  void _updateServiceHealth() {
    for (int i = 0; i < _services.length; i++) {
      final service = _services[i];
      _services[i] = ServiceHealth(
        name: service.name,
        status: _random.nextDouble() > 0.9 ? ServiceStatus.degraded : ServiceStatus.healthy,
        uptime: service.uptime + (_random.nextDouble() - 0.5) * 0.01,
        requestCount: service.requestCount + _random.nextInt(1000),
        avgLatency: service.avgLatency + (_random.nextDouble() - 0.5) * 10,
        errorRate: max(0, service.errorRate + (_random.nextDouble() - 0.5) * 0.05),
        lastChecked: DateTime.now(),
      );
    }
  }

  void acknowledgeAlert(String alertId) {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index] = PerformanceAlert(
        id: _alerts[index].id,
        title: _alerts[index].title,
        description: _alerts[index].description,
        severity: _alerts[index].severity,
        timestamp: _alerts[index].timestamp,
        source: _alerts[index].source,
        context: _alerts[index].context,
        acknowledged: true,
      );
      notifyListeners();
    }
  }

  Map<String, dynamic> getPerformanceSummary() {
    final healthyServices = _services.where((s) => s.status == ServiceStatus.healthy).length;
    final totalAlerts = _alerts.where((a) => !a.acknowledged).length;
    final criticalAlerts = _alerts.where((a) => !a.acknowledged && a.severity == AlertSeverity.critical).length;
    
    return {
      'overallHealth': healthyServices == _services.length ? 'Healthy' : 'Degraded',
      'healthyServices': healthyServices,
      'totalServices': _services.length,
      'activeAlerts': totalAlerts,
      'criticalAlerts': criticalAlerts,
      'avgCpuUsage': _metrics.firstWhere((m) => m.type == MetricType.cpu).value,
      'avgMemoryUsage': _metrics.firstWhere((m) => m.type == MetricType.memory).value,
      'avgLatency': _metrics.firstWhere((m) => m.type == MetricType.latency).value,
    };
  }

  @override
  void dispose() {
    _metricsTimer?.cancel();
    super.dispose();
  }
}
