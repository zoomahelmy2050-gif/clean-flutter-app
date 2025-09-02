import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/performance_monitoring_service.dart';

class PerformanceMonitoringPage extends StatefulWidget {
  const PerformanceMonitoringPage({super.key});

  @override
  State<PerformanceMonitoringPage> createState() => _PerformanceMonitoringPageState();
}

class _PerformanceMonitoringPageState extends State<PerformanceMonitoringPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance & Monitoring'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.speed), text: 'Metrics'),
            Tab(icon: Icon(Icons.handshake), text: 'SLA'),
            Tab(icon: Icon(Icons.storage), text: 'Capacity'),
            Tab(icon: Icon(Icons.notification_important), text: 'Alerts'),
          ],
        ),
      ),
      body: Consumer<PerformanceMonitoringService>(
        builder: (context, service, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildDashboard(service),
              _buildMetrics(service),
              _buildSLA(service),
              _buildCapacity(service),
              _buildAlerts(service),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDashboard(PerformanceMonitoringService service) {
    final summary = service.getPerformanceSummary();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Health Card
          Card(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: summary['overallHealth'] == 'Healthy'
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : [Colors.orange.shade400, Colors.orange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        summary['overallHealth'] == 'Healthy'
                            ? Icons.check_circle
                            : Icons.warning,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'System ${summary['overallHealth']}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${summary['healthyServices']} of ${summary['totalServices']} services operational',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Quick Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildStatCard(
                'Active Alerts',
                summary['activeAlerts'].toString(),
                Icons.notifications,
                summary['criticalAlerts'] > 0 ? Colors.red : Colors.orange,
                subtitle: '${summary['criticalAlerts']} critical',
              ),
              _buildStatCard(
                'CPU Usage',
                '${summary['avgCpuUsage'].toStringAsFixed(1)}%',
                Icons.memory,
                Colors.blue,
              ),
              _buildStatCard(
                'Memory Usage',
                '${summary['avgMemoryUsage'].toStringAsFixed(1)}%',
                Icons.data_usage,
                Colors.purple,
              ),
              _buildStatCard(
                'Avg Latency',
                '${summary['avgLatency'].toStringAsFixed(0)}ms',
                Icons.timer,
                Colors.teal,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Service Health
          const Text(
            'Service Health',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...service.services.map((s) => _buildServiceHealthCard(s)),
        ],
      ),
    );
  }

  Widget _buildMetrics(PerformanceMonitoringService service) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: service.metrics.length,
      itemBuilder: (context, index) {
        final metric = service.metrics[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(metric.status),
              child: Icon(
                _getMetricIcon(metric.type),
                color: Colors.white,
              ),
            ),
            title: Text(metric.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: metric.value / metric.threshold,
                  backgroundColor: Colors.grey.shade300,
                  color: _getStatusColor(metric.status),
                ),
                const SizedBox(height: 4),
                Text(
                  '${metric.value.toStringAsFixed(1)}${metric.unit} / ${metric.threshold.toStringAsFixed(0)}${metric.unit}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatusChip(metric.status),
                Text(
                  DateFormat('HH:mm:ss').format(metric.timestamp),
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
            onTap: () => _showMetricDetails(context, metric),
          ),
        );
      },
    );
  }

  Widget _buildSLA(PerformanceMonitoringService service) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: service.slas.length,
      itemBuilder: (context, index) {
        final sla = service.slas[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: Icon(
              sla.isCompliant ? Icons.check_circle : Icons.error,
              color: sla.isCompliant ? Colors.green : Colors.red,
            ),
            title: Text(sla.name),
            subtitle: Text(sla.description),
            trailing: Chip(
              label: Text(
                sla.isCompliant ? 'Compliant' : 'Non-Compliant',
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: sla.isCompliant 
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSLAMetric(
                      'Uptime',
                      '${sla.currentUptime}%',
                      'Target: ${sla.targetUptime}%',
                      sla.currentUptime >= sla.targetUptime,
                    ),
                    const Divider(),
                    _buildSLAMetric(
                      'Response Time',
                      '${sla.averageResponseTime.inMilliseconds}ms',
                      'Target: ${sla.targetResponseTime.inMilliseconds}ms',
                      sla.averageResponseTime <= sla.targetResponseTime,
                    ),
                    const Divider(),
                    _buildSLAMetric(
                      'Incidents',
                      '${sla.incidentCount}',
                      'This period',
                      sla.incidentCount < 5,
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Period: ${DateFormat('MMM d').format(sla.periodStart)} - ${DateFormat('MMM d').format(sla.periodEnd)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('View Report'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCapacity(PerformanceMonitoringService service) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: service.capacityPlans.length,
      itemBuilder: (context, index) {
        final plan = service.capacityPlans[index];
        final isWarning = plan.projectedUsage > 80;
        final isCritical = plan.projectedUsage > 90;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan.resource,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      isCritical 
                          ? Icons.error 
                          : isWarning 
                              ? Icons.warning 
                              : Icons.check_circle,
                      color: isCritical 
                          ? Colors.red 
                          : isWarning 
                              ? Colors.orange 
                              : Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Current Usage
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Current Usage'),
                    Text('${plan.currentUsage.toStringAsFixed(1)}%'),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: plan.currentUsage / 100,
                  backgroundColor: Colors.grey.shade300,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                
                // Projected Usage
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Projected (${DateFormat('MMM d').format(plan.projectionDate)})'),
                    Text('${plan.projectedUsage.toStringAsFixed(1)}%'),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: plan.projectedUsage / 100,
                  backgroundColor: Colors.grey.shade300,
                  color: isCritical 
                      ? Colors.red 
                      : isWarning 
                          ? Colors.orange 
                          : Colors.green,
                ),
                const SizedBox(height: 16),
                
                // Recommendation
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          plan.recommendation,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Historical Trend
                const Text(
                  'Historical Trend',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: plan.historicalData.entries.map((entry) {
                    return Column(
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${entry.value.toStringAsFixed(1)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlerts(PerformanceMonitoringService service) {
    final alerts = service.alerts;
    
    if (alerts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'No Active Alerts',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'All systems are operating normally',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getSeverityColor(alert.severity),
              child: Icon(
                _getSeverityIcon(alert.severity),
                color: Colors.white,
              ),
            ),
            title: Text(alert.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.description),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.source, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      alert.source,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('HH:mm').format(alert.timestamp),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => service.acknowledgeAlert(alert.id),
              tooltip: 'Acknowledge',
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServiceHealthCard(ServiceHealth service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(service.status),
          radius: 8,
        ),
        title: Text(service.name),
        subtitle: Text(
          'Uptime: ${service.uptime.toStringAsFixed(2)}% | Latency: ${service.avgLatency.toStringAsFixed(0)}ms | Error: ${service.errorRate.toStringAsFixed(2)}%',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          DateFormat('HH:mm:ss').format(service.lastChecked),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildSLAMetric(String label, String value, String subtitle, bool isGood) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isGood ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isGood ? Icons.check : Icons.close,
                color: isGood ? Colors.green : Colors.red,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ServiceStatus status) {
    return Chip(
      label: Text(
        status.toString().split('.').last.toUpperCase(),
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
      backgroundColor: _getStatusColor(status),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Color _getStatusColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.healthy:
        return Colors.green;
      case ServiceStatus.degraded:
        return Colors.orange;
      case ServiceStatus.critical:
        return Colors.red;
      case ServiceStatus.unknown:
        return Colors.grey;
    }
  }

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return Colors.blue;
      case AlertSeverity.warning:
        return Colors.orange;
      case AlertSeverity.error:
        return Colors.deepOrange;
      case AlertSeverity.critical:
        return Colors.red;
    }
  }

  IconData _getSeverityIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return Icons.info;
      case AlertSeverity.warning:
        return Icons.warning;
      case AlertSeverity.error:
        return Icons.error;
      case AlertSeverity.critical:
        return Icons.report;
    }
  }

  IconData _getMetricIcon(MetricType type) {
    switch (type) {
      case MetricType.cpu:
        return Icons.memory;
      case MetricType.memory:
        return Icons.data_usage;
      case MetricType.network:
        return Icons.wifi;
      case MetricType.storage:
        return Icons.storage;
      case MetricType.latency:
        return Icons.timer;
      case MetricType.throughput:
        return Icons.speed;
    }
  }

  void _showMetricDetails(BuildContext context, SystemMetric metric) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(metric.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Type', metric.type.toString().split('.').last),
            _buildDetailRow('Value', '${metric.value.toStringAsFixed(2)}${metric.unit}'),
            _buildDetailRow('Threshold', '${metric.threshold.toStringAsFixed(0)}${metric.unit}'),
            _buildDetailRow('Status', metric.status.toString().split('.').last),
            const Divider(),
            const Text('Metadata', style: TextStyle(fontWeight: FontWeight.bold)),
            ...metric.metadata.entries.map((e) => 
              _buildDetailRow(e.key, e.value.toString()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
