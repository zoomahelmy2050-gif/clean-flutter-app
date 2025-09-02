import 'dart:async';
import 'dart:math';
import '../../../core/models/monitoring_models.dart';
import '../../../core/services/real_time_communication_service.dart';
import '../../../locator.dart';
import 'dart:developer' as developer;

class RealTimeMonitoringService {
  final List<SystemMetric> _metrics = [];
  final List<AnomalyDetection> _anomalies = [];
  final List<MonitoringRule> _rules = [];
  final List<RealTimeAlert> _alerts = [];
  final List<UserBehaviorPattern> _behaviorPatterns = [];
  final List<AIInsight> _insights = [];
  
  Timer? _metricsTimer;
  Timer? _anomalyTimer;
  Timer? _insightsTimer;
  
  final StreamController<SystemMetric> _metricsController = StreamController.broadcast();
  final StreamController<AnomalyDetection> _anomalyController = StreamController.broadcast();
  final StreamController<RealTimeAlert> _alertController = StreamController.broadcast();
  final StreamController<AIInsight> _insightsController = StreamController.broadcast();
  
  Stream<SystemMetric> get metricsStream => _metricsController.stream;
  Stream<AnomalyDetection> get anomalyStream => _anomalyController.stream;
  Stream<RealTimeAlert> get alertStream => _alertController.stream;
  Stream<AIInsight> get insightsStream => _insightsController.stream;
  
  MonitoringStatus _status = MonitoringStatus.active;
  
  RealTimeMonitoringService() {
    _initializeMockData();
    startMonitoring();
    _connectToRealTimeService();
  }

  void _connectToRealTimeService() {
    try {
      final realTimeService = locator<RealTimeCommunicationService>();
      
      // Mock system and device event streams - replace when available
      // realTimeService.systemEventStream.listen((event) {
      //   _processSystemEvent(event);
      // });
      // 
      // realTimeService.deviceEventStream.listen((event) {
      //   _processDeviceEvent(event);
      // });
      
      developer.log('Connected to real-time communication service', name: 'RealTimeMonitoringService');
    } catch (e) {
      developer.log('Failed to connect to real-time service: $e', name: 'RealTimeMonitoringService');
    }
  }

  void _processSystemEvent(Map<String, dynamic> event) {
    final metric = SystemMetric(
      id: event['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: event['name'] ?? 'System Event',
      category: event['category'] ?? 'System',
      value: (event['value'] ?? 0).toDouble(),
      unit: event['unit'] ?? '',
      timestamp: DateTime.now(),
      threshold: (event['threshold'] ?? 100).toDouble(),
      isAnomalous: event['isAnomalous'] ?? false,
      metadata: Map<String, dynamic>.from(event['metadata'] ?? {}),
    );
    
    _metrics.add(metric);
    if (_metrics.length > 1000) {
      _metrics.removeRange(0, 500);
    }
    _metricsController.add(metric);
    
    // Check for anomalies
    if (metric.isAnomalous || (metric.threshold != null && metric.value > metric.threshold!)) {
      _createAnomalyFromMetric(metric);
    }
  }

  void _processDeviceEvent(Map<String, dynamic> event) {
    final alert = RealTimeAlert(
      id: event['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: event['title'] ?? 'Device Alert',
      message: event['message'] ?? 'Device event detected',
      severity: _mapSeverity(event['severity'] ?? 'medium'),
      timestamp: DateTime.now(),
      source: event['source'] ?? 'Device Monitor',
      isRead: false,
    );
    
    _alerts.add(alert);
    if (_alerts.length > 500) {
      _alerts.removeRange(0, 250);
    }
    _alertController.add(alert);
  }

  void _createAnomalyFromMetric(SystemMetric metric) {
    final anomaly = AnomalyDetection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: AnomalyType.systemResource,
      severity: AnomalySeverity.high,
      title: 'Anomaly Detected: ${metric.name}',
      description: 'Metric ${metric.name} exceeded threshold',
      detectedAt: DateTime.now(),
      userId: 'system',
      context: {
        'metric_value': metric.value,
        'threshold': metric.threshold,
        'metric_unit': metric.unit,
      },
      confidenceScore: 0.85,
      affectedSystems: [metric.name],
      status: AlertStatus.new_,
    );
    
    _anomalies.add(anomaly);
    if (_anomalies.length > 200) {
      _anomalies.removeRange(0, 100);
    }
    _anomalyController.add(anomaly);
  }

  AnomalySeverity _mapSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return AnomalySeverity.critical;
      case 'high':
        return AnomalySeverity.high;
      case 'medium':
        return AnomalySeverity.medium;
      case 'low':
        return AnomalySeverity.low;
      default:
        return AnomalySeverity.medium;
    }
  }

  void _initializeMockData() {
    // Initialize monitoring rules
    _rules.addAll([
      MonitoringRule(
        id: '1',
        name: 'High CPU Usage Alert',
        description: 'Triggers when CPU usage exceeds 85%',
        category: 'System Performance',
        isEnabled: true,
        conditions: {'metric': 'cpu_usage', 'operator': '>', 'value': 85.0},
        actions: ['send_alert', 'log_event', 'auto_scale'],
        severity: AnomalySeverity.high,
        threshold: 85.0,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        triggerCount: 12,
      ),
      MonitoringRule(
        id: '2',
        name: 'Unusual Login Pattern',
        description: 'Detects login attempts from new locations or devices',
        category: 'User Behavior',
        isEnabled: true,
        conditions: {'type': 'login', 'new_location': true, 'time_window': '1h'},
        actions: ['send_alert', 'require_mfa', 'log_security_event'],
        severity: AnomalySeverity.medium,
        threshold: 0.7,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        triggerCount: 8,
      ),
      MonitoringRule(
        id: '3',
        name: 'API Rate Limit Exceeded',
        description: 'Monitors API usage patterns for abuse',
        category: 'API Security',
        isEnabled: true,
        conditions: {'requests_per_minute': '>', 'value': 1000},
        actions: ['throttle_requests', 'send_alert', 'temporary_block'],
        severity: AnomalySeverity.high,
        threshold: 1000.0,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        triggerCount: 3,
      ),
      MonitoringRule(
        id: '4',
        name: 'Data Access Anomaly',
        description: 'Detects unusual data access patterns',
        category: 'Data Security',
        isEnabled: true,
        conditions: {'data_volume': '>', 'baseline': 'x5'},
        actions: ['send_alert', 'audit_log', 'require_approval'],
        severity: AnomalySeverity.critical,
        threshold: 5.0,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        triggerCount: 2,
      ),
    ]);

    // Generate initial metrics
    _generateInitialMetrics();
    
    // Generate initial anomalies
    _generateInitialAnomalies();
    
    // Generate initial behavior patterns
    _generateInitialBehaviorPatterns();
    
    // Generate initial AI insights
    _generateInitialInsights();
  }

  void _generateInitialMetrics() {
    final now = DateTime.now();
    final random = Random();
    
    // Generate metrics for the last hour
    for (int i = 60; i >= 0; i--) {
      final timestamp = now.subtract(Duration(minutes: i));
      
      _metrics.addAll([
        SystemMetric(
          id: 'cpu_${timestamp.millisecondsSinceEpoch}',
          name: 'CPU Usage',
          category: 'System Performance',
          value: 20 + random.nextDouble() * 60,
          unit: '%',
          timestamp: timestamp,
          threshold: 85.0,
          isAnomalous: false,
          metadata: {'core_count': 8, 'architecture': 'x64'},
        ),
        SystemMetric(
          id: 'memory_${timestamp.millisecondsSinceEpoch}',
          name: 'Memory Usage',
          category: 'System Performance',
          value: 30 + random.nextDouble() * 50,
          unit: '%',
          timestamp: timestamp,
          threshold: 90.0,
          isAnomalous: false,
          metadata: {'total_memory': '16GB', 'available': '8GB'},
        ),
        SystemMetric(
          id: 'requests_${timestamp.millisecondsSinceEpoch}',
          name: 'Requests per Second',
          category: 'API Performance',
          value: 50 + random.nextDouble() * 200,
          unit: 'req/s',
          timestamp: timestamp,
          threshold: 500.0,
          isAnomalous: false,
          metadata: {'endpoint_count': 45, 'avg_response_time': '120ms'},
        ),
        SystemMetric(
          id: 'errors_${timestamp.millisecondsSinceEpoch}',
          name: 'Error Rate',
          category: 'API Performance',
          value: random.nextDouble() * 5,
          unit: '%',
          timestamp: timestamp,
          threshold: 10.0,
          isAnomalous: false,
          metadata: {'total_requests': 1200, 'error_count': 15},
        ),
      ]);
    }
  }

  void _generateInitialAnomalies() {
    final now = DateTime.now();
    
    _anomalies.addAll([
      AnomalyDetection(
        id: '1',
        type: AnomalyType.loginPattern,
        severity: AnomalySeverity.high,
        title: 'Suspicious Login from New Location',
        description: 'User logged in from an unusual geographic location',
        detectedAt: now.subtract(const Duration(minutes: 15)),
        userId: 'user_12345',
        sessionId: 'sess_abc123',
        context: {
          'previous_location': 'New York, US',
          'current_location': 'Moscow, RU',
          'time_difference': '2 hours',
          'device_fingerprint': 'different'
        },
        confidenceScore: 0.89,
        affectedSystems: ['Authentication', 'User Management'],
        status: AlertStatus.new_,
      ),
      AnomalyDetection(
        id: '2',
        type: AnomalyType.dataAccess,
        severity: AnomalySeverity.critical,
        title: 'Unusual Data Export Volume',
        description: 'User exported 10x more data than typical baseline',
        detectedAt: now.subtract(const Duration(minutes: 45)),
        userId: 'user_67890',
        context: {
          'baseline_volume': '100MB',
          'current_volume': '1.2GB',
          'export_type': 'customer_data',
          'time_of_day': 'after_hours'
        },
        confidenceScore: 0.95,
        affectedSystems: ['Data Export', 'Customer Database'],
        status: AlertStatus.investigating,
        assignedTo: 'security_team',
      ),
      AnomalyDetection(
        id: '3',
        type: AnomalyType.apiUsage,
        severity: AnomalySeverity.medium,
        title: 'API Rate Limit Approach',
        description: 'API key approaching rate limit threshold',
        detectedAt: now.subtract(const Duration(minutes: 5)),
        userId: 'api_client_xyz',
        context: {
          'current_rate': '850 req/min',
          'limit': '1000 req/min',
          'utilization': '85%',
          'endpoint': '/api/v1/users'
        },
        confidenceScore: 0.75,
        affectedSystems: ['API Gateway'],
        status: AlertStatus.acknowledged,
      ),
    ]);
  }

  void _generateInitialBehaviorPatterns() {
    final now = DateTime.now();
    final random = Random();
    
    for (int i = 0; i < 10; i++) {
      _behaviorPatterns.add(
        UserBehaviorPattern(
          userId: 'user_${1000 + i}',
          sessionId: 'sess_${random.nextInt(100000)}',
          startTime: now.subtract(Duration(hours: random.nextInt(24))),
          endTime: now.subtract(Duration(minutes: random.nextInt(60))),
          actionsPerformed: [
            'login',
            'view_dashboard',
            'export_data',
            'update_profile',
            'logout'
          ],
          featureUsage: {
            'dashboard': random.nextInt(20),
            'reports': random.nextInt(10),
            'settings': random.nextInt(5),
          },
          deviceInfo: 'Chrome 120.0 on Windows 11',
          ipAddress: '192.168.1.${random.nextInt(255)}',
          location: 'New York, US',
          riskScore: random.nextDouble() * 100,
          isAnomalous: random.nextBool(),
          anomalyReasons: random.nextBool() 
              ? ['unusual_time', 'new_device'] 
              : [],
        ),
      );
    }
  }

  void _generateInitialInsights() {
    final now = DateTime.now();
    
    _insights.addAll([
      AIInsight(
        id: '1',
        title: 'Peak Usage Pattern Identified',
        description: 'System usage peaks detected between 2-4 PM daily',
        category: 'Performance Optimization',
        confidence: 0.92,
        generatedAt: now.subtract(const Duration(hours: 2)),
        data: {
          'peak_hours': ['14:00', '16:00'],
          'usage_increase': '340%',
          'affected_services': ['API', 'Database', 'Cache']
        },
        recommendations: [
          'Consider auto-scaling during peak hours',
          'Implement request queuing',
          'Add caching layers for frequently accessed data'
        ],
        impact: 'High - Could improve response times by 45%',
        isActionable: true,
      ),
      AIInsight(
        id: '2',
        title: 'Security Pattern Analysis',
        description: 'Correlation found between failed logins and geographic locations',
        category: 'Security Intelligence',
        confidence: 0.87,
        generatedAt: now.subtract(const Duration(hours: 6)),
        data: {
          'correlation_strength': 0.78,
          'suspicious_regions': ['Eastern Europe', 'Southeast Asia'],
          'attack_pattern': 'credential_stuffing'
        },
        recommendations: [
          'Implement geo-blocking for high-risk regions',
          'Add CAPTCHA for suspicious login patterns',
          'Enable mandatory MFA for new device logins'
        ],
        impact: 'Medium - Could reduce security incidents by 60%',
        isActionable: true,
      ),
      AIInsight(
        id: '3',
        title: 'Resource Optimization Opportunity',
        description: 'Database queries can be optimized based on usage patterns',
        category: 'Performance Optimization',
        confidence: 0.81,
        generatedAt: now.subtract(const Duration(hours: 12)),
        data: {
          'slow_queries': 15,
          'optimization_potential': '65%',
          'affected_tables': ['users', 'sessions', 'audit_logs']
        },
        recommendations: [
          'Add composite indexes on frequently queried columns',
          'Implement query result caching',
          'Archive old audit logs to separate storage'
        ],
        impact: 'High - Could reduce database load by 65%',
        isActionable: true,
      ),
    ]);
  }

  void startMonitoring() {
    if (_status == MonitoringStatus.active) return;
    
    _status = MonitoringStatus.active;
    
    // Start real-time metrics collection
    _metricsTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _generateRealTimeMetrics();
    });
    
    // Start anomaly detection
    _anomalyTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _runAnomalyDetection();
    });
    
    // Start AI insights generation
    _insightsTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _generateAIInsights();
    });
    
    developer.log('Real-time monitoring started', name: 'Monitoring');
  }

  void stopMonitoring() {
    _status = MonitoringStatus.paused;
    _metricsTimer?.cancel();
    _anomalyTimer?.cancel();
    _insightsTimer?.cancel();
    
    developer.log('Real-time monitoring stopped', name: 'Monitoring');
  }

  void _generateRealTimeMetrics() {
    final now = DateTime.now();
    final random = Random();
    
    final newMetrics = [
      SystemMetric(
        id: 'cpu_${now.millisecondsSinceEpoch}',
        name: 'CPU Usage',
        category: 'System Performance',
        value: 20 + random.nextDouble() * 60,
        unit: '%',
        timestamp: now,
        threshold: 85.0,
        isAnomalous: false,
        metadata: {'core_count': 8},
      ),
      SystemMetric(
        id: 'memory_${now.millisecondsSinceEpoch}',
        name: 'Memory Usage',
        category: 'System Performance',
        value: 30 + random.nextDouble() * 50,
        unit: '%',
        timestamp: now,
        threshold: 90.0,
        isAnomalous: false,
        metadata: {'total_memory': '16GB'},
      ),
      SystemMetric(
        id: 'requests_${now.millisecondsSinceEpoch}',
        name: 'Requests per Second',
        category: 'API Performance',
        value: 50 + random.nextDouble() * 200,
        unit: 'req/s',
        timestamp: now,
        threshold: 500.0,
        isAnomalous: false,
        metadata: {'endpoint_count': 45},
      ),
    ];

    // Add metrics to storage
    _metrics.addAll(newMetrics);
    
    // Keep only last 1000 metrics
    if (_metrics.length > 1000) {
      _metrics.removeRange(0, _metrics.length - 1000);
    }
    
    // Emit metrics to stream
    for (final metric in newMetrics) {
      _metricsController.add(metric);
    }
  }

  void _runAnomalyDetection() {
    final random = Random();
    
    // Simulate AI-based anomaly detection
    if (random.nextDouble() < 0.3) { // 30% chance of detecting anomaly
      final anomaly = _generateRandomAnomaly();
      _anomalies.insert(0, anomaly);
      _anomalyController.add(anomaly);
      
      // Generate corresponding alert
      final alert = RealTimeAlert(
        id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
        title: anomaly.title,
        message: anomaly.description,
        severity: anomaly.severity,
        timestamp: anomaly.detectedAt,
        source: 'AI Anomaly Detection',
        data: anomaly.context,
        isRead: false,
        actionUrl: '/admin/anomalies/${anomaly.id}',
        tags: [anomaly.type.name, anomaly.severity.name],
      );
      
      _alerts.insert(0, alert);
      _alertController.add(alert);
      
      developer.log('Anomaly detected: ${anomaly.title}', name: 'Monitoring');
    }
  }

  AnomalyDetection _generateRandomAnomaly() {
    final random = Random();
    final now = DateTime.now();
    final types = AnomalyType.values;
    final severities = AnomalySeverity.values;
    
    final type = types[random.nextInt(types.length)];
    final severity = severities[random.nextInt(severities.length)];
    
    final anomalyTemplates = {
      AnomalyType.loginPattern: {
        'title': 'Unusual Login Pattern Detected',
        'description': 'User login from unexpected location or time',
      },
      AnomalyType.dataAccess: {
        'title': 'Abnormal Data Access Volume',
        'description': 'User accessed unusually large amount of data',
      },
      AnomalyType.networkTraffic: {
        'title': 'Network Traffic Spike',
        'description': 'Unexpected increase in network traffic detected',
      },
      AnomalyType.systemResource: {
        'title': 'System Resource Anomaly',
        'description': 'Unusual system resource consumption pattern',
      },
      AnomalyType.userBehavior: {
        'title': 'User Behavior Anomaly',
        'description': 'User behavior deviates from established baseline',
      },
    };
    
    final template = anomalyTemplates[type]!;
    
    return AnomalyDetection(
      id: 'anomaly_${now.millisecondsSinceEpoch}',
      type: type,
      severity: severity,
      title: template['title']!,
      description: template['description']!,
      detectedAt: now,
      userId: 'user_${random.nextInt(10000)}',
      sessionId: 'sess_${random.nextInt(100000)}',
      context: _generateAnomalyContext(type),
      confidenceScore: 0.6 + random.nextDouble() * 0.4,
      affectedSystems: _getAffectedSystems(type),
      status: AlertStatus.new_,
    );
  }

  Map<String, dynamic> _generateAnomalyContext(AnomalyType type) {
    final random = Random();
    
    switch (type) {
      case AnomalyType.loginPattern:
        return {
          'previous_location': 'New York, US',
          'current_location': 'London, UK',
          'time_difference': '${random.nextInt(12)} hours',
          'device_change': random.nextBool(),
        };
      case AnomalyType.dataAccess:
        return {
          'baseline_volume': '${random.nextInt(500)}MB',
          'current_volume': '${random.nextInt(5000)}MB',
          'data_type': 'customer_records',
        };
      case AnomalyType.networkTraffic:
        return {
          'baseline_traffic': '${random.nextInt(100)}Mbps',
          'current_traffic': '${random.nextInt(1000)}Mbps',
          'protocol': 'HTTPS',
        };
      default:
        return {
          'metric': 'cpu_usage',
          'baseline': '${random.nextInt(50)}%',
          'current': '${random.nextInt(100)}%',
        };
    }
  }

  List<String> _getAffectedSystems(AnomalyType type) {
    switch (type) {
      case AnomalyType.loginPattern:
        return ['Authentication', 'User Management'];
      case AnomalyType.dataAccess:
        return ['Database', 'Data Export'];
      case AnomalyType.networkTraffic:
        return ['Network', 'Load Balancer'];
      case AnomalyType.systemResource:
        return ['System', 'Infrastructure'];
      case AnomalyType.userBehavior:
        return ['User Interface', 'Session Management'];
      default:
        return ['System'];
    }
  }

  void _generateAIInsights() {
    final random = Random();
    
    if (random.nextDouble() < 0.4) { // 40% chance of generating insight
      final insight = _generateRandomInsight();
      _insights.insert(0, insight);
      _insightsController.add(insight);
      
      developer.log('AI insight generated: ${insight.title}', name: 'Monitoring');
    }
  }

  AIInsight _generateRandomInsight() {
    final random = Random();
    final now = DateTime.now();
    
    final insightTemplates = [
      {
        'title': 'Performance Optimization Opportunity',
        'description': 'Database query optimization could improve response times',
        'category': 'Performance',
        'recommendations': [
          'Add database indexes',
          'Implement query caching',
          'Optimize slow queries'
        ],
      },
      {
        'title': 'Security Pattern Detected',
        'description': 'Correlation found in failed authentication attempts',
        'category': 'Security',
        'recommendations': [
          'Implement rate limiting',
          'Add geo-blocking',
          'Enable MFA for suspicious patterns'
        ],
      },
      {
        'title': 'Resource Usage Trend',
        'description': 'Memory usage trending upward over past week',
        'category': 'Infrastructure',
        'recommendations': [
          'Monitor for memory leaks',
          'Consider scaling up resources',
          'Implement memory optimization'
        ],
      },
    ];
    
    final template = insightTemplates[random.nextInt(insightTemplates.length)];
    
    return AIInsight(
      id: 'insight_${now.millisecondsSinceEpoch}',
      title: template['title'] as String,
      description: template['description'] as String,
      category: template['category'] as String,
      confidence: 0.7 + random.nextDouble() * 0.3,
      generatedAt: now,
      data: {
        'analysis_period': '7 days',
        'data_points': random.nextInt(1000) + 500,
        'correlation_strength': random.nextDouble(),
      },
      recommendations: template['recommendations'] as List<String>,
      impact: 'Could improve system performance by ${random.nextInt(50) + 20}%',
      isActionable: true,
    );
  }

  // Public API methods
  Future<List<SystemMetric>> getRecentMetrics({int limit = 100}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _metrics.take(limit).toList();
  }

  Future<List<AnomalyDetection>> getRecentAnomalies({int limit = 50}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _anomalies.take(limit).toList();
  }

  Future<List<RealTimeAlert>> getRecentAlerts({int limit = 50}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _alerts.take(limit).toList();
  }

  Future<List<AIInsight>> getRecentInsights({int limit = 20}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _insights.take(limit).toList();
  }

  Future<SystemHealthMetrics> getCurrentSystemHealth() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final random = Random();
    
    return SystemHealthMetrics(
      cpuUsage: 20 + random.nextDouble() * 60,
      memoryUsage: 30 + random.nextDouble() * 50,
      diskUsage: 40 + random.nextDouble() * 40,
      networkLatency: 10 + random.nextDouble() * 50,
      activeConnections: 100 + random.nextInt(500),
      requestsPerSecond: 50 + random.nextInt(200),
      errorRate: random.nextDouble() * 5,
      timestamp: DateTime.now(),
      customMetrics: {
        'cache_hit_rate': 80 + random.nextDouble() * 20,
        'queue_depth': random.nextDouble() * 100,
        'thread_pool_usage': 20 + random.nextDouble() * 60,
      },
    );
  }

  Future<List<MonitoringRule>> getMonitoringRules() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _rules;
  }

  Future<MonitoringRule> createMonitoringRule(
    String name,
    String description,
    String category,
    Map<String, dynamic> conditions,
    List<String> actions,
    AnomalySeverity severity,
    double threshold,
  ) async {
    final rule = MonitoringRule(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      category: category,
      isEnabled: true,
      conditions: conditions,
      actions: actions,
      severity: severity,
      threshold: threshold,
      createdAt: DateTime.now(),
      triggerCount: 0,
    );

    _rules.insert(0, rule);
    
    developer.log('New monitoring rule created: $name', name: 'Monitoring');
    
    return rule;
  }

  Future<void> updateRuleStatus(String ruleId, bool isEnabled) async {
    final ruleIndex = _rules.indexWhere((r) => r.id == ruleId);
    if (ruleIndex == -1) return;

    final rule = _rules[ruleIndex];
    final updatedRule = MonitoringRule(
      id: rule.id,
      name: rule.name,
      description: rule.description,
      category: rule.category,
      isEnabled: isEnabled,
      conditions: rule.conditions,
      actions: rule.actions,
      severity: rule.severity,
      threshold: rule.threshold,
      createdAt: rule.createdAt,
      lastTriggered: rule.lastTriggered,
      triggerCount: rule.triggerCount,
    );

    _rules[ruleIndex] = updatedRule;
    
    developer.log('Rule ${rule.name} ${isEnabled ? 'enabled' : 'disabled'}', name: 'Monitoring');
  }

  Future<void> acknowledgeAnomaly(String anomalyId, String acknowledgedBy) async {
    final anomalyIndex = _anomalies.indexWhere((a) => a.id == anomalyId);
    if (anomalyIndex == -1) return;

    final anomaly = _anomalies[anomalyIndex];
    final updatedAnomaly = AnomalyDetection(
      id: anomaly.id,
      type: anomaly.type,
      severity: anomaly.severity,
      title: anomaly.title,
      description: anomaly.description,
      detectedAt: anomaly.detectedAt,
      userId: anomaly.userId,
      sessionId: anomaly.sessionId,
      context: anomaly.context,
      confidenceScore: anomaly.confidenceScore,
      affectedSystems: anomaly.affectedSystems,
      status: AlertStatus.acknowledged,
      assignedTo: acknowledgedBy,
      resolvedAt: anomaly.resolvedAt,
      resolution: anomaly.resolution,
    );

    _anomalies[anomalyIndex] = updatedAnomaly;
    
    developer.log('Anomaly $anomalyId acknowledged by $acknowledgedBy', name: 'Monitoring');
  }

  Future<void> resolveAnomaly(String anomalyId, String resolvedBy, String resolution) async {
    final anomalyIndex = _anomalies.indexWhere((a) => a.id == anomalyId);
    if (anomalyIndex == -1) return;

    final anomaly = _anomalies[anomalyIndex];
    final updatedAnomaly = AnomalyDetection(
      id: anomaly.id,
      type: anomaly.type,
      severity: anomaly.severity,
      title: anomaly.title,
      description: anomaly.description,
      detectedAt: anomaly.detectedAt,
      userId: anomaly.userId,
      sessionId: anomaly.sessionId,
      context: anomaly.context,
      confidenceScore: anomaly.confidenceScore,
      affectedSystems: anomaly.affectedSystems,
      status: AlertStatus.resolved,
      assignedTo: anomaly.assignedTo,
      resolvedAt: DateTime.now(),
      resolution: resolution,
    );

    _anomalies[anomalyIndex] = updatedAnomaly;
    
    developer.log('Anomaly $anomalyId resolved by $resolvedBy', name: 'Monitoring');
  }

  Future<Map<String, dynamic>> getMonitoringStatistics() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));
    
    final recentAnomalies = _anomalies.where((a) => a.detectedAt.isAfter(last24h)).toList();
    final recentAlerts = _alerts.where((a) => a.timestamp.isAfter(last24h)).toList();
    
    return {
      'total_metrics_collected': _metrics.length,
      'anomalies_detected_24h': recentAnomalies.length,
      'alerts_generated_24h': recentAlerts.length,
      'active_monitoring_rules': _rules.where((r) => r.isEnabled).length,
      'system_health_score': 85 + Random().nextDouble() * 15,
      'ai_insights_generated': _insights.length,
      'monitoring_uptime': '99.8%',
      'last_updated': now.toIso8601String(),
    };
  }

  void dispose() {
    stopMonitoring();
    _metricsController.close();
    _anomalyController.close();
    _alertController.close();
    _insightsController.close();
  }
}
