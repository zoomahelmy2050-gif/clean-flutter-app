import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/services/security_analytics_service.dart';
import '../../locator.dart';
import '../../generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:clean_flutter/core/services/language_service.dart';

class SecurityDashboardPage extends StatefulWidget {
  const SecurityDashboardPage({super.key});

  @override
  State<SecurityDashboardPage> createState() => _SecurityDashboardPageState();
}

class _SecurityDashboardPageState extends State<SecurityDashboardPage>
    with SingleTickerProviderStateMixin {
  late SecurityAnalyticsService _securityService;
  late TabController _tabController;
  String _selectedPeriod = '7d';

  @override
  void initState() {
    super.initState();
    _securityService = locator<SecurityAnalyticsService>();
    _tabController = TabController(length: 4, vsync: this);
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
        title: Consumer<LanguageService>(
          builder: (context, languageService, child) {
            final l10n = AppLocalizations.of(context)!;
            return Text(l10n.securityDashboard);
          },
        ),
        actions: [
          IconButton(
            onPressed: _showSettingsDialog,
            icon: const Icon(Icons.settings),
          ),
          IconButton(
            onPressed: _showExportDialog,
            icon: const Icon(Icons.download),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.security)),
            Tab(text: 'Events', icon: Icon(Icons.event_note)),
            Tab(text: 'Threats', icon: Icon(Icons.warning)),
            Tab(text: 'Trends', icon: Icon(Icons.trending_up)),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: _securityService,
        builder: (context, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildEventsTab(),
              _buildThreatsTab(),
              _buildTrendsTab(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab() {
    final metrics = _securityService.currentMetrics;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSecurityScoreCard(metrics),
        const SizedBox(height: 16),
        _buildStatusCard(metrics),
        const SizedBox(height: 16),
        _buildMetricsGrid(metrics),
        const SizedBox(height: 16),
        _buildRecommendationsCard(),
      ],
    );
  }

  Widget _buildSecurityScoreCard(SecurityMetrics? metrics) {
    final score = metrics?.securityScore ?? 0.0;
    final status = metrics?.status ?? SecurityStatus.unknown;
    
    Color scoreColor;
    if (score >= 80) {
      scoreColor = Colors.green;
    } else if (score >= 60) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Security Score',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${score.toInt()}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      status.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _getScoreDescription(score),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(SecurityMetrics? metrics) {
    final status = metrics?.status ?? SecurityStatus.unknown;
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security Status: ${status.name.toUpperCase()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusDescription(status),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Switch(
              value: _securityService.realTimeMonitoring,
              onChanged: (_) => _securityService.toggleRealTimeMonitoring(),
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(SecurityMetrics? metrics) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildMetricCard(
          'Total Events',
          '${metrics?.totalEvents ?? 0}',
          Icons.event,
          Colors.blue,
        ),
        _buildMetricCard(
          'Critical Events',
          '${metrics?.criticalEvents ?? 0}',
          Icons.error,
          Colors.red,
        ),
        _buildMetricCard(
          'Unresolved',
          '${metrics?.unresolvedEvents ?? 0}',
          Icons.pending,
          Colors.orange,
        ),
        _buildMetricCard(
          'Last Update',
          _formatLastUpdate(metrics?.lastUpdate),
          Icons.update,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final recommendations = _securityService.getSecurityRecommendations();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Security Recommendations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recommendations.isEmpty)
              const Text(
                'No recommendations at this time. Your security looks good!',
                style: TextStyle(color: Colors.green),
              )
            else
              ...recommendations.map((rec) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.arrow_right, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text(rec)),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsTab() {
    final events = _securityService.events;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text('${events.length} security events'),
              const Spacer(),
              FilterChip(
                label: const Text('Unresolved Only'),
                selected: false,
                onSelected: (selected) {
                  // Filter implementation
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: events.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.security, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text('No security events recorded'),
                      Text('Your app is secure!', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return _buildEventCard(event);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEventCard(SecurityEvent event) {
    final color = _getThreatLevelColor(event.threatLevel);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getEventTypeIcon(event.type),
            color: color,
            size: 20,
          ),
        ),
        title: Text(event.description),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${event.type.name} • ${event.threatLevel.name.toUpperCase()}',
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
            Text(_formatEventTime(event.timestamp)),
          ],
        ),
        trailing: event.resolved
            ? const Icon(Icons.check_circle, color: Colors.green)
            : IconButton(
                onPressed: () => _securityService.resolveEvent(event.id),
                icon: const Icon(Icons.check),
              ),
        onTap: () => _showEventDetails(event),
      ),
    );
  }

  Widget _buildThreatsTab() {
    final metrics = _securityService.currentMetrics;
    final threatBreakdown = metrics?.threatBreakdown ?? {};
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildThreatLevelChart(threatBreakdown),
        const SizedBox(height: 16),
        _buildThreatLevelList(threatBreakdown),
      ],
    );
  }

  Widget _buildThreatLevelChart(Map<String, int> threatBreakdown) {
    if (threatBreakdown.isEmpty || threatBreakdown.values.every((v) => v == 0)) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('No threat data available'),
          ),
        ),
      );
    }

    final sections = threatBreakdown.entries.where((e) => e.value > 0).map((entry) {
      final color = _getThreatLevelColor(
        ThreatLevel.values.firstWhere((l) => l.name == entry.key),
      );
      
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${entry.value}',
        color: color,
        radius: 60,
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Threat Level Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreatLevelList(Map<String, int> threatBreakdown) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Threat Levels',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...ThreatLevel.values.map((level) {
              final count = threatBreakdown[level.name] ?? 0;
              final color = _getThreatLevelColor(level);
              
              return ListTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(level.name.toUpperCase()),
                trailing: Text(
                  count.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                onTap: count > 0 ? () => _showThreatLevelEvents(level) : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsTab() {
    final trends = _securityService.getSecurityTrends(days: 30);
    final dailyThreats = trends['dailyThreats'] as List<Map<String, dynamic>>?;

    if (dailyThreats == null || dailyThreats.isEmpty) {
      return const Center(
        child: Text('No trend data available'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Security Trends (30 Days)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < dailyThreats.length) {
                                final date = DateTime.parse(dailyThreats[index]['date']);
                                return Text('${date.day}/${date.month}');
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        // Critical threats line
                        LineChartBarData(
                          spots: dailyThreats.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              (entry.value['critical'] ?? 0).toDouble(),
                            );
                          }).toList(),
                          isCurved: true,
                          color: Colors.red,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                        ),
                        // High threats line
                        LineChartBarData(
                          spots: dailyThreats.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              (entry.value['high'] ?? 0).toDouble(),
                            );
                          }).toList(),
                          isCurved: true,
                          color: Colors.orange,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.circle, color: Colors.red, size: 12),
                    SizedBox(width: 4),
                    Text('Critical'),
                    SizedBox(width: 16),
                    Icon(Icons.circle, color: Colors.orange, size: 12),
                    SizedBox(width: 4),
                    Text('High'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showEventDetails(SecurityEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.type.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${event.description}'),
            const SizedBox(height: 8),
            Text('Threat Level: ${event.threatLevel.name.toUpperCase()}'),
            const SizedBox(height: 8),
            Text('Time: ${_formatEventTime(event.timestamp)}'),
            if (event.ipAddress != null) ...[
              const SizedBox(height: 8),
              Text('IP Address: ${event.ipAddress}'),
            ],
            if (event.metadata.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Metadata:'),
              ...event.metadata.entries.map(
                (e) => Text('  ${e.key}: ${e.value}'),
              ),
            ],
          ],
        ),
        actions: [
          if (!event.resolved)
            TextButton(
              onPressed: () {
                _securityService.resolveEvent(event.id);
                Navigator.pop(context);
              },
              child: const Text('Resolve'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showThreatLevelEvents(ThreatLevel level) {
    final events = _securityService.events
        .where((e) => e.threatLevel == level)
        .toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${level.name.toUpperCase()} Threat Events'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return ListTile(
                title: Text(event.description),
                subtitle: Text(_formatEventTime(event.timestamp)),
                trailing: event.resolved
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
              );
            },
          ),
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

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Settings'),
        content: const Text('Security settings configuration coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Security Data'),
        content: const Text('Export security analytics data as JSON file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final data = _securityService.exportSecurityData();
              // Here you would implement file export functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Security data exported')),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(SecurityStatus status) {
    switch (status) {
      case SecurityStatus.secure:
        return Colors.green;
      case SecurityStatus.warning:
        return Colors.orange;
      case SecurityStatus.compromised:
        return Colors.red;
      case SecurityStatus.unknown:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(SecurityStatus status) {
    switch (status) {
      case SecurityStatus.secure:
        return Icons.security;
      case SecurityStatus.warning:
        return Icons.warning;
      case SecurityStatus.compromised:
        return Icons.error;
      case SecurityStatus.unknown:
        return Icons.help;
    }
  }

  Color _getThreatLevelColor(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.low:
        return Colors.green;
      case ThreatLevel.medium:
        return Colors.orange;
      case ThreatLevel.high:
        return Colors.red;
      case ThreatLevel.critical:
        return Colors.purple;
    }
  }

  IconData _getEventTypeIcon(SecurityEventType type) {
    switch (type) {
      case SecurityEventType.loginAttempt:
      case SecurityEventType.loginSuccess:
      case SecurityEventType.loginFailure:
        return Icons.login;
      case SecurityEventType.passwordChange:
        return Icons.lock;
      case SecurityEventType.backupCodeUsed:
        return Icons.backup;
      case SecurityEventType.suspiciousActivity:
      case SecurityEventType.unauthorizedAccess:
        return Icons.warning;
      case SecurityEventType.dataExport:
        return Icons.download;
      case SecurityEventType.settingsChange:
        return Icons.settings;
      case SecurityEventType.deviceChange:
        return Icons.devices;
      case SecurityEventType.syncActivity:
        return Icons.sync;
      case SecurityEventType.totpAccess:
        return Icons.security;
    }
  }

  String _getScoreDescription(double score) {
    if (score >= 90) return 'Excellent security posture';
    if (score >= 80) return 'Good security with minor issues';
    if (score >= 60) return 'Moderate security, needs attention';
    if (score >= 40) return 'Poor security, immediate action required';
    return 'Critical security issues detected';
  }

  String _getStatusDescription(SecurityStatus status) {
    switch (status) {
      case SecurityStatus.secure:
        return 'Your account is secure and protected';
      case SecurityStatus.warning:
        return 'Some security issues need attention';
      case SecurityStatus.compromised:
        return 'Critical security issues detected';
      case SecurityStatus.unknown:
        return 'Security status is being analyzed';
    }
  }

  String _formatLastUpdate(DateTime? lastUpdate) {
    if (lastUpdate == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    
    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  String _formatEventTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
