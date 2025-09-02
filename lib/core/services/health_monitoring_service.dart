import 'dart:async';
import 'dart:developer' as developer;

class HealthCheck {
  final String checkId;
  final String name;
  final String category;
  final String status;
  final String message;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final int responseTimeMs;

  HealthCheck({
    required this.checkId,
    required this.name,
    required this.category,
    required this.status,
    required this.message,
    required this.metadata,
    required this.timestamp,
    required this.responseTimeMs,
  });

  Map<String, dynamic> toJson() => {
    'check_id': checkId,
    'name': name,
    'category': category,
    'status': status,
    'message': message,
    'metadata': metadata,
    'timestamp': timestamp.toIso8601String(),
    'response_time_ms': responseTimeMs,
  };
}

class SystemMetrics {
  final double cpuUsage;
  final double memoryUsage;
  final double diskUsage;
  final double networkLatency;
  final int activeConnections;
  final DateTime timestamp;

  SystemMetrics({
    required this.cpuUsage,
    required this.memoryUsage,
    required this.diskUsage,
    required this.networkLatency,
    required this.activeConnections,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'cpu_usage': cpuUsage,
    'memory_usage': memoryUsage,
    'disk_usage': diskUsage,
    'network_latency': networkLatency,
    'active_connections': activeConnections,
    'timestamp': timestamp.toIso8601String(),
  };
}

class ServiceStatus {
  final String serviceId;
  final String name;
  final String status;
  final String version;
  final DateTime lastHealthCheck;
  final Map<String, dynamic> dependencies;
  final List<String> endpoints;

  ServiceStatus({
    required this.serviceId,
    required this.name,
    required this.status,
    required this.version,
    required this.lastHealthCheck,
    required this.dependencies,
    required this.endpoints,
  });

  Map<String, dynamic> toJson() => {
    'service_id': serviceId,
    'name': name,
    'status': status,
    'version': version,
    'last_health_check': lastHealthCheck.toIso8601String(),
    'dependencies': dependencies,
    'endpoints': endpoints,
  };
}

class HealthMonitoringService {
  static final HealthMonitoringService _instance = HealthMonitoringService._internal();
  factory HealthMonitoringService() => _instance;
  HealthMonitoringService._internal();

  final List<HealthCheck> _healthChecks = [];
  final List<SystemMetrics> _systemMetrics = [];
  final Map<String, ServiceStatus> _serviceStatuses = {};
  final Map<String, List<double>> _performanceHistory = {};
  
  final StreamController<HealthCheck> _healthCheckController = StreamController.broadcast();
  final StreamController<SystemMetrics> _metricsController = StreamController.broadcast();
  final StreamController<ServiceStatus> _serviceController = StreamController.broadcast();

  Stream<HealthCheck> get healthCheckStream => _healthCheckController.stream;
  Stream<SystemMetrics> get metricsStream => _metricsController.stream;
  Stream<ServiceStatus> get serviceStream => _serviceController.stream;

  Timer? _monitoringTimer;
  Timer? _metricsTimer;

  Future<void> initialize() async {
    await _setupServiceStatuses();
    _startHealthMonitoring();
    _startMetricsCollection();
    
    developer.log('Health Monitoring Service initialized', name: 'HealthMonitoringService');
  }

  Future<void> _setupServiceStatuses() async {
    // Authentication Service
    _serviceStatuses['auth_service'] = ServiceStatus(
      serviceId: 'auth_service',
      name: 'Authentication Service',
      status: 'healthy',
      version: '1.2.3',
      lastHealthCheck: DateTime.now(),
      dependencies: {
        'database': 'healthy',
        'redis': 'healthy',
        'ldap': 'healthy',
      },
      endpoints: ['/api/auth/login', '/api/auth/logout', '/api/auth/verify'],
    );

    // Security Analytics Service
    _serviceStatuses['analytics_service'] = ServiceStatus(
      serviceId: 'analytics_service',
      name: 'Security Analytics Service',
      status: 'healthy',
      version: '2.1.0',
      lastHealthCheck: DateTime.now(),
      dependencies: {
        'elasticsearch': 'healthy',
        'kafka': 'healthy',
        'ml_engine': 'degraded',
      },
      endpoints: ['/api/analytics/metrics', '/api/analytics/reports'],
    );

    // Threat Intelligence Service
    _serviceStatuses['threat_intel_service'] = ServiceStatus(
      serviceId: 'threat_intel_service',
      name: 'Threat Intelligence Service',
      status: 'healthy',
      version: '1.5.2',
      lastHealthCheck: DateTime.now(),
      dependencies: {
        'threat_feeds': 'healthy',
        'ioc_database': 'healthy',
        'external_apis': 'healthy',
      },
      endpoints: ['/api/threat-intel/feeds', '/api/threat-intel/iocs'],
    );

    // Notification Service
    _serviceStatuses['notification_service'] = ServiceStatus(
      serviceId: 'notification_service',
      name: 'Notification Service',
      status: 'healthy',
      version: '1.0.8',
      lastHealthCheck: DateTime.now(),
      dependencies: {
        'smtp_server': 'healthy',
        'slack_api': 'healthy',
        'push_service': 'healthy',
      },
      endpoints: ['/api/notifications/send', '/api/notifications/templates'],
    );

    // API Gateway
    _serviceStatuses['api_gateway'] = ServiceStatus(
      serviceId: 'api_gateway',
      name: 'API Gateway',
      status: 'healthy',
      version: '3.0.1',
      lastHealthCheck: DateTime.now(),
      dependencies: {
        'rate_limiter': 'healthy',
        'auth_provider': 'healthy',
        'load_balancer': 'healthy',
      },
      endpoints: ['/health', '/metrics', '/api/*'],
    );

    // Database Service
    _serviceStatuses['database_service'] = ServiceStatus(
      serviceId: 'database_service',
      name: 'Database Service',
      status: 'healthy',
      version: '14.2',
      lastHealthCheck: DateTime.now(),
      dependencies: {
        'primary_db': 'healthy',
        'replica_db': 'healthy',
        'backup_system': 'healthy',
      },
      endpoints: [],
    );
  }

  void _startHealthMonitoring() {
    _monitoringTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _performHealthChecks();
    });
  }

  void _startMetricsCollection() {
    _metricsTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _collectSystemMetrics();
    });
  }

  Future<void> _performHealthChecks() async {
    // Database connectivity check
    await _checkDatabase();
    
    // API endpoint checks
    await _checkApiEndpoints();
    
    // External service checks
    await _checkExternalServices();
    
    // Security service checks
    await _checkSecurityServices();
    
    // Performance checks
    await _checkPerformance();
    
    // Update service statuses
    await _updateServiceStatuses();
  }

  Future<void> _checkDatabase() async {
    final startTime = DateTime.now();
    
    try {
      // Mock database check
      await Future.delayed(const Duration(milliseconds: 50));
      
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      
      final healthCheck = HealthCheck(
        checkId: 'db_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Database Connectivity',
        category: 'database',
        status: responseTime < 100 ? 'healthy' : 'degraded',
        message: responseTime < 100 ? 'Database responding normally' : 'Database response slow',
        metadata: {
          'response_time_ms': responseTime,
          'connection_pool_size': 20,
          'active_connections': 15,
        },
        timestamp: DateTime.now(),
        responseTimeMs: responseTime,
      );
      
      _addHealthCheck(healthCheck);
      
    } catch (e) {
      final healthCheck = HealthCheck(
        checkId: 'db_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Database Connectivity',
        category: 'database',
        status: 'unhealthy',
        message: 'Database connection failed: $e',
        metadata: {'error': e.toString()},
        timestamp: DateTime.now(),
        responseTimeMs: DateTime.now().difference(startTime).inMilliseconds,
      );
      
      _addHealthCheck(healthCheck);
    }
  }

  Future<void> _checkApiEndpoints() async {
    final endpoints = [
      '/api/auth/health',
      '/api/security/health',
      '/api/analytics/health',
      '/api/notifications/health',
    ];
    
    for (final endpoint in endpoints) {
      final startTime = DateTime.now();
      
      try {
        // Mock API check
        await Future.delayed(Duration(milliseconds: 20 + (DateTime.now().millisecond % 80)));
        
        final responseTime = DateTime.now().difference(startTime).inMilliseconds;
        
        final healthCheck = HealthCheck(
          checkId: 'api_${endpoint.replaceAll('/', '_')}_${DateTime.now().millisecondsSinceEpoch}',
          name: 'API Endpoint $endpoint',
          category: 'api',
          status: responseTime < 200 ? 'healthy' : 'degraded',
          message: responseTime < 200 ? 'Endpoint responding normally' : 'Endpoint response slow',
          metadata: {
            'endpoint': endpoint,
            'response_time_ms': responseTime,
            'status_code': 200,
          },
          timestamp: DateTime.now(),
          responseTimeMs: responseTime,
        );
        
        _addHealthCheck(healthCheck);
        
      } catch (e) {
        final healthCheck = HealthCheck(
          checkId: 'api_${endpoint.replaceAll('/', '_')}_${DateTime.now().millisecondsSinceEpoch}',
          name: 'API Endpoint $endpoint',
          category: 'api',
          status: 'unhealthy',
          message: 'Endpoint check failed: $e',
          metadata: {
            'endpoint': endpoint,
            'error': e.toString(),
          },
          timestamp: DateTime.now(),
          responseTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        );
        
        _addHealthCheck(healthCheck);
      }
    }
  }

  Future<void> _checkExternalServices() async {
    final services = [
      {'name': 'Threat Intelligence Feed', 'url': 'https://feeds.threatintel.com'},
      {'name': 'Email Service', 'url': 'smtp://mail.company.com'},
      {'name': 'Slack Integration', 'url': 'https://hooks.slack.com'},
      {'name': 'SIEM Platform', 'url': 'https://siem.company.com'},
    ];
    
    for (final service in services) {
      final startTime = DateTime.now();
      
      try {
        // Mock external service check
        await Future.delayed(Duration(milliseconds: 100 + (DateTime.now().millisecond % 200)));
        
        final responseTime = DateTime.now().difference(startTime).inMilliseconds;
        final isHealthy = responseTime < 500 && DateTime.now().second % 10 != 0; // 90% success rate
        
        final healthCheck = HealthCheck(
          checkId: 'ext_${service['name']!.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
          name: 'External Service: ${service['name']}',
          category: 'external',
          status: isHealthy ? 'healthy' : 'unhealthy',
          message: isHealthy ? 'Service accessible' : 'Service unreachable',
          metadata: {
            'service_name': service['name'],
            'service_url': service['url'],
            'response_time_ms': responseTime,
          },
          timestamp: DateTime.now(),
          responseTimeMs: responseTime,
        );
        
        _addHealthCheck(healthCheck);
        
      } catch (e) {
        final healthCheck = HealthCheck(
          checkId: 'ext_${service['name']!.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
          name: 'External Service: ${service['name']}',
          category: 'external',
          status: 'unhealthy',
          message: 'Service check failed: $e',
          metadata: {
            'service_name': service['name'],
            'service_url': service['url'],
            'error': e.toString(),
          },
          timestamp: DateTime.now(),
          responseTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        );
        
        _addHealthCheck(healthCheck);
      }
    }
  }

  Future<void> _checkSecurityServices() async {
    final securityChecks = [
      'Threat Detection Engine',
      'Vulnerability Scanner',
      'Intrusion Detection System',
      'Security Event Processor',
      'Compliance Monitor',
    ];
    
    for (final checkName in securityChecks) {
      final startTime = DateTime.now();
      
      try {
        // Mock security service check
        await Future.delayed(Duration(milliseconds: 30 + (DateTime.now().millisecond % 70)));
        
        final responseTime = DateTime.now().difference(startTime).inMilliseconds;
        final isHealthy = DateTime.now().second % 15 != 0; // 93% success rate
        
        final healthCheck = HealthCheck(
          checkId: 'sec_${checkName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
          name: checkName,
          category: 'security',
          status: isHealthy ? 'healthy' : 'degraded',
          message: isHealthy ? 'Security service operational' : 'Security service experiencing issues',
          metadata: {
            'service_name': checkName,
            'response_time_ms': responseTime,
            'last_scan': DateTime.now().subtract(Duration(minutes: DateTime.now().minute % 30)).toIso8601String(),
          },
          timestamp: DateTime.now(),
          responseTimeMs: responseTime,
        );
        
        _addHealthCheck(healthCheck);
        
      } catch (e) {
        final healthCheck = HealthCheck(
          checkId: 'sec_${checkName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
          name: checkName,
          category: 'security',
          status: 'unhealthy',
          message: 'Security service check failed: $e',
          metadata: {
            'service_name': checkName,
            'error': e.toString(),
          },
          timestamp: DateTime.now(),
          responseTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        );
        
        _addHealthCheck(healthCheck);
      }
    }
  }

  Future<void> _checkPerformance() async {
    final performanceChecks = [
      {'name': 'CPU Usage', 'threshold': 80.0},
      {'name': 'Memory Usage', 'threshold': 85.0},
      {'name': 'Disk Usage', 'threshold': 90.0},
      {'name': 'Network Latency', 'threshold': 100.0},
    ];
    
    for (final check in performanceChecks) {
      final startTime = DateTime.now();
      
      // Generate mock performance data
      final value = _generateMockPerformanceValue(check['name'] as String);
      final threshold = check['threshold'] as double;
      
      final status = value < threshold * 0.7 ? 'healthy' : 
                    value < threshold ? 'degraded' : 'unhealthy';
      
      final healthCheck = HealthCheck(
        checkId: 'perf_${(check['name'] as String).replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Performance: ${check['name']}',
        category: 'performance',
        status: status,
        message: '${check['name']}: ${value.toStringAsFixed(1)}%',
        metadata: {
          'metric_name': check['name'],
          'current_value': value,
          'threshold': threshold,
          'unit': check['name'] == 'Network Latency' ? 'ms' : '%',
        },
        timestamp: DateTime.now(),
        responseTimeMs: DateTime.now().difference(startTime).inMilliseconds,
      );
      
      _addHealthCheck(healthCheck);
      
      // Track performance history
      _performanceHistory[check['name'] as String] ??= [];
      _performanceHistory[check['name'] as String]!.add(value);
      
      // Keep only last 100 values
      if (_performanceHistory[check['name'] as String]!.length > 100) {
        _performanceHistory[check['name'] as String]!.removeAt(0);
      }
    }
  }

  double _generateMockPerformanceValue(String metricName) {
    final now = DateTime.now();
    final baseValue = switch (metricName) {
      'CPU Usage' => 45.0 + (now.second % 30),
      'Memory Usage' => 60.0 + (now.minute % 25),
      'Disk Usage' => 35.0 + (now.hour % 20),
      'Network Latency' => 25.0 + (now.millisecond % 50),
      _ => 50.0,
    };
    
    // Add some randomness
    final randomFactor = (now.millisecond % 20) - 10;
    return (baseValue + randomFactor).clamp(0.0, 100.0);
  }

  Future<void> _updateServiceStatuses() async {
    for (final serviceId in _serviceStatuses.keys) {
      final service = _serviceStatuses[serviceId]!;
      
      // Check recent health checks for this service
      final recentChecks = _healthChecks.where((check) => 
          check.timestamp.isAfter(DateTime.now().subtract(const Duration(minutes: 5))) &&
          (check.category == 'api' || check.category == 'database' || check.category == 'security')
      ).toList();
      
      final unhealthyChecks = recentChecks.where((check) => check.status == 'unhealthy').length;
      final degradedChecks = recentChecks.where((check) => check.status == 'degraded').length;
      
      String newStatus;
      if (unhealthyChecks > 0) {
        newStatus = 'unhealthy';
      } else if (degradedChecks > 2) {
        newStatus = 'degraded';
      } else {
        newStatus = 'healthy';
      }
      
      final updatedService = ServiceStatus(
        serviceId: service.serviceId,
        name: service.name,
        status: newStatus,
        version: service.version,
        lastHealthCheck: DateTime.now(),
        dependencies: service.dependencies,
        endpoints: service.endpoints,
      );
      
      _serviceStatuses[serviceId] = updatedService;
      _serviceController.add(updatedService);
    }
  }

  Future<void> _collectSystemMetrics() async {
    final metrics = SystemMetrics(
      cpuUsage: _generateMockPerformanceValue('CPU Usage'),
      memoryUsage: _generateMockPerformanceValue('Memory Usage'),
      diskUsage: _generateMockPerformanceValue('Disk Usage'),
      networkLatency: _generateMockPerformanceValue('Network Latency'),
      activeConnections: 150 + (DateTime.now().second % 50),
      timestamp: DateTime.now(),
    );
    
    _systemMetrics.add(metrics);
    _metricsController.add(metrics);
    
    // Keep only last 1000 metrics (about 8 hours at 30-second intervals)
    if (_systemMetrics.length > 1000) {
      _systemMetrics.removeAt(0);
    }
  }

  void _addHealthCheck(HealthCheck healthCheck) {
    _healthChecks.add(healthCheck);
    _healthCheckController.add(healthCheck);
    
    // Keep only last 1000 health checks
    if (_healthChecks.length > 1000) {
      _healthChecks.removeAt(0);
    }
  }

  Future<List<HealthCheck>> getHealthChecks({
    String? category,
    String? status,
    int? limit,
  }) async {
    var checks = List<HealthCheck>.from(_healthChecks);
    
    if (category != null) {
      checks = checks.where((check) => check.category == category).toList();
    }
    
    if (status != null) {
      checks = checks.where((check) => check.status == status).toList();
    }
    
    checks.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    if (limit != null && limit > 0) {
      checks = checks.take(limit).toList();
    }
    
    return checks;
  }

  Future<List<SystemMetrics>> getSystemMetrics({int? limit}) async {
    var metrics = List<SystemMetrics>.from(_systemMetrics);
    
    metrics.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    if (limit != null && limit > 0) {
      metrics = metrics.take(limit).toList();
    }
    
    return metrics;
  }

  Future<List<ServiceStatus>> getServiceStatuses() async {
    return _serviceStatuses.values.toList();
  }

  Future<ServiceStatus?> getServiceStatus(String serviceId) async {
    return _serviceStatuses[serviceId];
  }

  Map<String, dynamic> getHealthMetrics() {
    return getHealthSummary();
  }

  Map<String, dynamic> getHealthSummary() {
    final recentChecks = _healthChecks.where((check) => 
        check.timestamp.isAfter(DateTime.now().subtract(const Duration(minutes: 5)))
    ).toList();
    
    final healthyCount = recentChecks.where((check) => check.status == 'healthy').length;
    final degradedCount = recentChecks.where((check) => check.status == 'degraded').length;
    final unhealthyCount = recentChecks.where((check) => check.status == 'unhealthy').length;
    
    final healthyServices = _serviceStatuses.values.where((service) => service.status == 'healthy').length;
    final degradedServices = _serviceStatuses.values.where((service) => service.status == 'degraded').length;
    final unhealthyServices = _serviceStatuses.values.where((service) => service.status == 'unhealthy').length;
    
    final latestMetrics = _systemMetrics.isNotEmpty ? _systemMetrics.last : null;
    
    return {
      'overall_status': unhealthyServices > 0 ? 'unhealthy' : 
                       degradedServices > 0 ? 'degraded' : 'healthy',
      'health_checks': {
        'total': recentChecks.length,
        'healthy': healthyCount,
        'degraded': degradedCount,
        'unhealthy': unhealthyCount,
      },
      'services': {
        'total': _serviceStatuses.length,
        'healthy': healthyServices,
        'degraded': degradedServices,
        'unhealthy': unhealthyServices,
      },
      'system_metrics': latestMetrics?.toJson(),
      'performance_trends': _getPerformanceTrends(),
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  Map<String, double> _getPerformanceTrends() {
    final trends = <String, double>{};
    
    for (final entry in _performanceHistory.entries) {
      final values = entry.value;
      if (values.length >= 2) {
        final recent = values.sublist(values.length - 10).reduce((a, b) => a + b) / 10;
        final older = values.sublist(0, (values.length / 2).floor()).reduce((a, b) => a + b) / (values.length / 2).floor();
        trends[entry.key] = ((recent - older) / older) * 100; // Percentage change
      }
    }
    
    return trends;
  }

  void dispose() {
    _monitoringTimer?.cancel();
    _metricsTimer?.cancel();
    _healthCheckController.close();
    _metricsController.close();
    _serviceController.close();
  }
}
