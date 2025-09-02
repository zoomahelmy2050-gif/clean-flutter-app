import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math';
import '../../core/models/monitoring_models.dart';
import 'services/real_time_monitoring_service.dart';
import '../../locator.dart';

class RealTimeMonitoringPage extends StatefulWidget {
  const RealTimeMonitoringPage({super.key});

  @override
  State<RealTimeMonitoringPage> createState() => _RealTimeMonitoringPageState();
}

class _RealTimeMonitoringPageState extends State<RealTimeMonitoringPage> {
  Timer? _refreshTimer;
  List<SystemMetric> _systemMetrics = [];
  List<AnomalyDetection> _recentAnomalies = [];
  List<RealTimeAlert> _recentAlerts = [];
  List<AIInsight> _aiInsights = [];
  List<_SecurityEvent> _recentEvents = [];
  SystemHealthMetrics? _systemHealth;
  bool _isMonitoring = true;
  late RealTimeMonitoringService _monitoringService;
  StreamSubscription<SystemMetric>? _metricsSubscription;
  StreamSubscription<AnomalyDetection>? _anomalySubscription;
  StreamSubscription<RealTimeAlert>? _alertSubscription;
  StreamSubscription<AIInsight>? _insightsSubscription;

  @override
  void initState() {
    super.initState();
    _monitoringService = locator<RealTimeMonitoringService>();
    _initializeMonitoring();
    _setupStreamSubscriptions();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _metricsSubscription?.cancel();
    _anomalySubscription?.cancel();
    _alertSubscription?.cancel();
    _insightsSubscription?.cancel();
    super.dispose();
  }

  void _initializeMonitoring() async {
    await _loadInitialData();
  }

  void _setupStreamSubscriptions() {
    _metricsSubscription = _monitoringService.metricsStream.listen((metric) {
      if (mounted) {
        setState(() {
          _systemMetrics.insert(0, metric);
          if (_systemMetrics.length > 100) {
            _systemMetrics = _systemMetrics.take(100).toList();
          }
        });
      }
    });

    _anomalySubscription = _monitoringService.anomalyStream.listen((anomaly) {
      if (mounted) {
        setState(() {
          _recentAnomalies.insert(0, anomaly);
          if (_recentAnomalies.length > 50) {
            _recentAnomalies = _recentAnomalies.take(50).toList();
          }
        });
      }
    });

    _alertSubscription = _monitoringService.alertStream.listen((alert) {
      if (mounted) {
        setState(() {
          _recentAlerts.insert(0, alert);
          if (_recentAlerts.length > 50) {
            _recentAlerts = _recentAlerts.take(50).toList();
          }
        });
      }
    });

    _insightsSubscription = _monitoringService.insightsStream.listen((insight) {
      if (mounted) {
        setState(() {
          _aiInsights.insert(0, insight);
          if (_aiInsights.length > 20) {
            _aiInsights = _aiInsights.take(20).toList();
          }
        });
      }
    });
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        _monitoringService.getRecentMetrics(limit: 50),
        _monitoringService.getRecentAnomalies(limit: 20),
        _monitoringService.getRecentAlerts(limit: 20),
        _monitoringService.getRecentInsights(limit: 10),
        _monitoringService.getCurrentSystemHealth(),
      ]);

      if (mounted) {
        setState(() {
          _systemMetrics = results[0] as List<SystemMetric>;
          _recentAnomalies = results[1] as List<AnomalyDetection>;
          _recentAlerts = results[2] as List<RealTimeAlert>;
          _aiInsights = results[3] as List<AIInsight>;
          _systemHealth = results[4] as SystemHealthMetrics;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading monitoring data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-Time Monitoring'),
        actions: [
          IconButton(
            icon: Icon(_isMonitoring ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              setState(() {
                _isMonitoring = !_isMonitoring;
                if (_isMonitoring) {
                  _monitoringService.startMonitoring();
                } else {
                  _monitoringService.stopMonitoring();
                }
              });
            },
            tooltip: _isMonitoring ? 'Pause Monitoring' : 'Resume Monitoring',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _initializeMonitoring();
              });
            },
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSystemStatusOverview(),
            const SizedBox(height: 20),
            _buildAIInsightsPanel(),
            const SizedBox(height: 20),
            _buildLiveAnomaliesPanel(),
            const SizedBox(height: 20),
            _buildSystemMetricsCharts(),
            const SizedBox(height: 20),
            _buildActiveAlertsPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatusOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'System Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'OPERATIONAL',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildStatusCard(
                  'CPU', 
                  _systemHealth != null ? '${_systemHealth!.cpuUsage.toStringAsFixed(1)}%' : 'N/A', 
                  Icons.memory, 
                  Colors.blue
                ),
                _buildStatusCard(
                  'Memory', 
                  _systemHealth != null ? '${_systemHealth!.memoryUsage.toStringAsFixed(1)}%' : 'N/A', 
                  Icons.storage, 
                  Colors.orange
                ),
                _buildStatusCard(
                  'Network', 
                  _systemHealth != null ? '${_systemHealth!.networkLatency.toStringAsFixed(0)}ms' : 'N/A', 
                  Icons.network_check, 
                  Colors.green
                ),
                _buildStatusCard(
                  'Requests/s', 
                  _systemHealth != null ? '${_systemHealth!.requestsPerSecond}' : 'N/A', 
                  Icons.speed, 
                  Colors.purple
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightsPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'AI Security Insights',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_aiInsights.length} Insights',
                    style: const TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _aiInsights.isEmpty
                  ? const Center(
                      child: Text(
                        'No AI insights available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _aiInsights.length,
                      itemBuilder: (context, index) {
                        final insight = _aiInsights[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              insight.isActionable ? Icons.lightbulb : Icons.info,
                              color: insight.isActionable ? Colors.amber : Colors.blue,
                            ),
                            title: Text(
                              insight.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(insight.description),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text(
                                        insight.category,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      backgroundColor: Colors.blue.withOpacity(0.1),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Confidence: ${(insight.confidence * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: insight.isActionable
                                ? IconButton(
                                    icon: const Icon(Icons.arrow_forward),
                                    onPressed: () => _showInsightDetails(insight),
                                  )
                                : null,
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveAnomaliesPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Live Anomaly Detection',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isMonitoring)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (_isMonitoring) const SizedBox(width: 4),
                      Text(
                        _isMonitoring ? 'LIVE' : 'PAUSED',
                        style: TextStyle(
                          color: _isMonitoring ? Colors.red : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _recentAnomalies.isEmpty
                  ? const Center(
                      child: Text(
                        'No anomalies detected',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _recentAnomalies.length,
                      itemBuilder: (context, index) {
                        final anomaly = _recentAnomalies[index];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            _getAnomalyIcon(anomaly.type),
                            color: _getSeverityColor(anomaly.severity),
                            size: 20,
                          ),
                          title: Text(
                            anomaly.title,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            '${anomaly.userId} • ${DateFormat('HH:mm:ss').format(anomaly.detectedAt)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: Text(
                                  anomaly.severity.name.toUpperCase(),
                                  style: const TextStyle(fontSize: 10),
                                ),
                                backgroundColor: _getSeverityColor(anomaly.severity).withOpacity(0.1),
                              ),
                              Text(
                                '${(anomaly.confidenceScore * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                          onTap: () => _showAnomalyDetails(anomaly),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemMetricsCharts() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Performance Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final time = DateTime.now().subtract(Duration(minutes: (30 - value).toInt()));
                          return Text(DateFormat('HH:mm').format(time));
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateCPUData(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: _generateMemoryData(),
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: _generateNetworkData(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('CPU', Colors.blue),
                const SizedBox(width: 20),
                _buildLegendItem('Memory', Colors.orange),
                const SizedBox(width: 20),
                _buildLegendItem('Network', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveAlertsPanel() {
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Active Security Alerts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_recentAlerts.length} Active',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentAlerts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No active alerts',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentAlerts.length,
                itemBuilder: (context, index) {
                  final alert = _recentAlerts[index];
                  return Card(
                    color: _getSeverityColor(alert.severity).withOpacity(0.1),
                    child: ListTile(
                      leading: Icon(
                        Icons.notification_important,
                        color: _getSeverityColor(alert.severity),
                      ),
                      title: Text(alert.title),
                      subtitle: Text(
                        '${alert.message}\n${DateFormat.yMMMd().add_jm().format(alert.timestamp)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!alert.isRead)
                            IconButton(
                              icon: const Icon(Icons.mark_email_read),
                              onPressed: () => _markAlertAsRead(alert),
                              tooltip: 'Mark as Read',
                            ),
                          IconButton(
                            icon: const Icon(Icons.info),
                            onPressed: () => _showAlertDetails(alert),
                            tooltip: 'Details',
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // Helper methods
  void _generateSystemMetrics() {
    _systemMetrics = [
      SystemMetric(
        id: 'cpu',
        name: 'CPU',
        category: 'performance',
        value: Random().nextInt(100).toDouble(),
        unit: '%',
        timestamp: DateTime.now(),
        threshold: 80.0,
        isAnomalous: false,
      ),
      SystemMetric(
        id: 'memory',
        name: 'Memory',
        category: 'performance',
        value: Random().nextInt(100).toDouble(),
        unit: '%',
        timestamp: DateTime.now(),
        threshold: 85.0,
        isAnomalous: false,
      ),
      SystemMetric(
        id: 'network',
        name: 'Network',
        category: 'network',
        value: Random().nextInt(100).toDouble(),
        unit: 'Mbps',
        timestamp: DateTime.now(),
        threshold: 90.0,
        isAnomalous: false,
      ),
      SystemMetric(
        id: 'disk',
        name: 'Disk I/O',
        category: 'storage',
        value: Random().nextInt(100).toDouble(),
        unit: 'MB/s',
        timestamp: DateTime.now(),
        threshold: 75.0,
        isAnomalous: false,
      ),
    ];
  }

  void _generateSecurityEvents() {
    final events = [
      _SecurityEvent(
        'Failed Login Attempt',
        'user@example.com',
        'High',
        Icons.warning,
        DateTime.now(),
      ),
      _SecurityEvent(
        'Successful Login',
        'admin@example.com',
        'Low',
        Icons.login,
        DateTime.now().subtract(const Duration(minutes: 2)),
      ),
      _SecurityEvent(
        'Password Reset',
        'manager@example.com',
        'Medium',
        Icons.lock_reset,
        DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];
    
    // Add new events to the beginning and keep only recent ones
    _recentEvents.insertAll(0, events);
    if (_recentEvents.length > 20) {
      _recentEvents = _recentEvents.take(20).toList();
    }
  }

  List<FlSpot> _generateCPUData() {
    return List.generate(30, (index) {
      return FlSpot(index.toDouble(), (Random().nextInt(40) + 30).toDouble());
    });
  }

  List<FlSpot> _generateMemoryData() {
    return List.generate(30, (index) {
      return FlSpot(index.toDouble(), (Random().nextInt(30) + 50).toDouble());
    });
  }

  List<FlSpot> _generateNetworkData() {
    return List.generate(30, (index) {
      return FlSpot(index.toDouble(), (Random().nextInt(50) + 10).toDouble());
    });
  }

  IconData _getAnomalyIcon(AnomalyType type) {
    switch (type) {
      case AnomalyType.loginPattern:
        return Icons.login;
      case AnomalyType.dataAccess:
        return Icons.storage;
      case AnomalyType.networkTraffic:
        return Icons.network_check;
      case AnomalyType.systemResource:
        return Icons.memory;
      case AnomalyType.userBehavior:
        return Icons.person;
      case AnomalyType.apiUsage:
        return Icons.api;
      case AnomalyType.geolocation:
        return Icons.location_on;
      case AnomalyType.deviceFingerprint:
        return Icons.fingerprint;
    }
  }

  Color _getSeverityColor(AnomalySeverity severity) {
    switch (severity) {
      case AnomalySeverity.critical:
        return Colors.red;
      case AnomalySeverity.high:
        return Colors.orange;
      case AnomalySeverity.medium:
        return Colors.yellow[700]!;
      case AnomalySeverity.low:
        return Colors.blue;
    }
  }

  void _showInsightDetails(AIInsight insight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(insight.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Category: ${insight.category}'),
              Text('Confidence: ${(insight.confidence * 100).toStringAsFixed(1)}%'),
              Text('Generated: ${DateFormat.yMMMd().add_jm().format(insight.generatedAt)}'),
              const SizedBox(height: 12),
              Text(insight.description),
              if (insight.impact != null) ...[
                const SizedBox(height: 12),
                const Text('Impact:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(insight.impact!),
              ],
              if (insight.recommendations.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Recommendations:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...insight.recommendations.map((rec) => Text('• $rec')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (insight.isActionable)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Handle insight action
              },
              child: const Text('Take Action'),
            ),
        ],
      ),
    );
  }

  void _showAnomalyDetails(AnomalyDetection anomaly) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(anomaly.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type: ${anomaly.type.name}'),
              Text('Severity: ${anomaly.severity.name.toUpperCase()}'),
              Text('User: ${anomaly.userId}'),
              Text('Confidence: ${(anomaly.confidenceScore * 100).toStringAsFixed(1)}%'),
              Text('Detected: ${DateFormat.yMMMd().add_jm().format(anomaly.detectedAt)}'),
              const SizedBox(height: 12),
              Text(anomaly.description),
              if (anomaly.context.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Context:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...anomaly.context.entries.map((entry) => 
                  Text('• ${entry.key}: ${entry.value}')),
              ],
              if (anomaly.affectedSystems.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Affected Systems:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...anomaly.affectedSystems.map((system) => Text('• $system')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (anomaly.status == AlertStatus.new_)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _acknowledgeAnomaly(anomaly);
              },
              child: const Text('Acknowledge'),
            ),
        ],
      ),
    );
  }

  void _showAlertDetails(RealTimeAlert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alert.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Message: ${alert.message}'),
              Text('Severity: ${alert.severity.name.toUpperCase()}'),
              Text('Source: ${alert.source}'),
              Text('Time: ${DateFormat.yMMMd().add_jm().format(alert.timestamp)}'),
              if (alert.data.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Additional Data:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...alert.data.entries.map((entry) => 
                  Text('• ${entry.key}: ${entry.value}')),
              ],
              if (alert.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Tags:', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 4,
                  children: alert.tags.map((tag) => Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 10)),
                    backgroundColor: Colors.grey.withOpacity(0.1),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!alert.isRead)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _markAlertAsRead(alert);
              },
              child: const Text('Mark as Read'),
            ),
        ],
      ),
    );
  }

  void _markAlertAsRead(RealTimeAlert alert) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Alert "${alert.title}" marked as read')),
    );
    setState(() {
      final index = _recentAlerts.indexWhere((a) => a.id == alert.id);
      if (index != -1) {
        final updatedAlert = RealTimeAlert(
          id: alert.id,
          title: alert.title,
          message: alert.message,
          severity: alert.severity,
          timestamp: alert.timestamp,
          source: alert.source,
          data: alert.data,
          isRead: true,
          actionUrl: alert.actionUrl,
          tags: alert.tags,
        );
        _recentAlerts[index] = updatedAlert;
      }
    });
  }

  void _acknowledgeAnomaly(AnomalyDetection anomaly) async {
    try {
      await _monitoringService.acknowledgeAnomaly(anomaly.id, 'Admin User');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anomaly "${anomaly.title}" acknowledged')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error acknowledging anomaly: $e')),
      );
    }
  }
}


class _SecurityEvent {
  final String title;
  final String source;
  final String severity;
  final IconData icon;
  final DateTime timestamp;

  _SecurityEvent(this.title, this.source, this.severity, this.icon, this.timestamp);
}

