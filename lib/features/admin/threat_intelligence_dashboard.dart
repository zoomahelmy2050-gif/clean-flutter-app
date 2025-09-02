import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../locator.dart';
import 'services/threat_intelligence_service.dart';
import '../../core/models/threat_models.dart';

class ThreatIntelligenceDashboard extends StatefulWidget {
  const ThreatIntelligenceDashboard({super.key});

  @override
  State<ThreatIntelligenceDashboard> createState() => _ThreatIntelligenceDashboardState();
}

class _ThreatIntelligenceDashboardState extends State<ThreatIntelligenceDashboard> 
    with TickerProviderStateMixin {
  final _threatService = locator<ThreatIntelligenceService>();
  late TabController _tabController;
  
  List<ThreatFeed> _threatFeeds = [];
  List<IPReputationResult> _recentIPChecks = [];
  List<GeolocationAnomaly> _geoAnomalies = [];
  List<ThreatAlert> _activeAlerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadThreatData();
  }

  Future<void> _loadThreatData() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _threatService.getLatestThreatFeeds(),
        _threatService.getRecentIPChecks(),
        _threatService.getGeolocationAnomalies(),
        _threatService.getActiveAlerts(),
      ]);
      
      setState(() {
        _threatFeeds = results[0] as List<ThreatFeed>;
        _recentIPChecks = results[1] as List<IPReputationResult>;
        _geoAnomalies = results[2] as List<GeolocationAnomaly>;
        _activeAlerts = results[3] as List<ThreatAlert>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading threat data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Threat Intelligence Dashboard'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadThreatData,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showThreatSettings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.feed), text: 'Threat Feeds'),
            Tab(icon: Icon(Icons.location_on), text: 'IP Reputation'),
            Tab(icon: Icon(Icons.map), text: 'Geo Anomalies'),
            Tab(icon: Icon(Icons.warning), text: 'Active Alerts'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildThreatFeedsTab(),
                _buildIPReputationTab(),
                _buildGeoAnomaliesTab(),
                _buildActiveAlertsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _runThreatScan,
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.security),
        label: const Text('Run Threat Scan'),
      ),
    );
  }

  Widget _buildThreatFeedsTab() {
    return RefreshIndicator(
      onRefresh: _loadThreatData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildThreatOverviewCards(),
          const SizedBox(height: 16),
          _buildThreatFeedsList(),
        ],
      ),
    );
  }

  Widget _buildThreatOverviewCards() {
    final criticalThreats = _threatFeeds.where((t) => t.severity == ThreatSeverity.critical).length;
    final highThreats = _threatFeeds.where((t) => t.severity == ThreatSeverity.high).length;
    final blockedIPs = _recentIPChecks.where((ip) => ip.isBlocked).length;
    final geoAnomaliesCount = _geoAnomalies.length;

    return Row(
      children: [
        Expanded(child: _buildThreatCard('Critical Threats', criticalThreats.toString(), 
            Colors.red, Icons.dangerous)),
        const SizedBox(width: 8),
        Expanded(child: _buildThreatCard('High Priority', highThreats.toString(), 
            Colors.orange, Icons.warning)),
        const SizedBox(width: 8),
        Expanded(child: _buildThreatCard('Blocked IPs', blockedIPs.toString(), 
            Colors.blue, Icons.block)),
        const SizedBox(width: 8),
        Expanded(child: _buildThreatCard('Geo Anomalies', geoAnomaliesCount.toString(), 
            Colors.purple, Icons.location_off)),
      ],
    );
  }

  Widget _buildThreatCard(String title, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildThreatFeedsList() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Recent Threat Intelligence', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _threatFeeds.take(10).length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final threat = _threatFeeds[index];
              return ListTile(
                leading: _getThreatIcon(threat.severity),
                title: Text(threat.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${threat.source} • ${DateFormat.yMd().add_Hm().format(threat.timestamp)}'),
                trailing: Chip(
                  label: Text(threat.severity.name.toUpperCase()),
                  backgroundColor: _getSeverityColor(threat.severity),
                  labelStyle: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                onTap: () => _showThreatDetails(threat),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIPReputationTab() {
    return RefreshIndicator(
      onRefresh: _loadThreatData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildIPReputationChart(),
          const SizedBox(height: 16),
          _buildIPReputationList(),
        ],
      ),
    );
  }

  Widget _buildIPReputationChart() {
    final maliciousCount = _recentIPChecks.where((ip) => ip.reputation == IPReputation.malicious).length;
    final suspiciousCount = _recentIPChecks.where((ip) => ip.reputation == IPReputation.suspicious).length;
    final cleanCount = _recentIPChecks.where((ip) => ip.reputation == IPReputation.clean).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('IP Reputation Distribution', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: maliciousCount.toDouble(),
                      title: 'Malicious\n$maliciousCount',
                      color: Colors.red,
                      radius: 80,
                    ),
                    PieChartSectionData(
                      value: suspiciousCount.toDouble(),
                      title: 'Suspicious\n$suspiciousCount',
                      color: Colors.orange,
                      radius: 80,
                    ),
                    PieChartSectionData(
                      value: cleanCount.toDouble(),
                      title: 'Clean\n$cleanCount',
                      color: Colors.green,
                      radius: 80,
                    ),
                  ],
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIPReputationList() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent IP Checks', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _checkNewIP,
                  icon: const Icon(Icons.search),
                  label: const Text('Check IP'),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentIPChecks.take(15).length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final ipCheck = _recentIPChecks[index];
              return ListTile(
                leading: Icon(
                  _getIPReputationIcon(ipCheck.reputation),
                  color: _getIPReputationColor(ipCheck.reputation),
                ),
                title: Text(ipCheck.ipAddress, style: const TextStyle(fontFamily: 'monospace')),
                subtitle: Text('${ipCheck.country} • ${ipCheck.provider ?? 'Unknown ISP'}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Chip(
                      label: Text(ipCheck.reputation.name.toUpperCase()),
                      backgroundColor: _getIPReputationColor(ipCheck.reputation),
                      labelStyle: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    if (ipCheck.isBlocked)
                      const Icon(Icons.block, color: Colors.red, size: 16),
                  ],
                ),
                onTap: () => _showIPDetails(ipCheck),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGeoAnomaliesTab() {
    return RefreshIndicator(
      onRefresh: _loadThreatData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGeoAnomaliesMap(),
          const SizedBox(height: 16),
          _buildGeoAnomaliesList(),
        ],
      ),
    );
  }

  Widget _buildGeoAnomaliesMap() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Geographic Anomalies Heatmap', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: Colors.grey),
                    Text('Interactive Map Coming Soon', style: TextStyle(color: Colors.grey)),
                    Text('Will show login locations and anomalies', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeoAnomaliesList() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Recent Geographic Anomalies', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _geoAnomalies.take(10).length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final anomaly = _geoAnomalies[index];
              return ListTile(
                leading: Icon(
                  Icons.location_off,
                  color: _getAnomalyColor(anomaly.riskLevel),
                ),
                title: Text(anomaly.userEmail),
                subtitle: Text('${anomaly.location} • Distance: ${anomaly.distanceFromUsual.toStringAsFixed(0)}km'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Chip(
                      label: Text(anomaly.riskLevel.name.toUpperCase()),
                      backgroundColor: _getAnomalyColor(anomaly.riskLevel),
                      labelStyle: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    Text(DateFormat.Hm().format(anomaly.timestamp), 
                        style: const TextStyle(fontSize: 10)),
                  ],
                ),
                onTap: () => _showAnomalyDetails(anomaly),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAlertsTab() {
    return RefreshIndicator(
      onRefresh: _loadThreatData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAlertsOverview(),
          const SizedBox(height: 16),
          _buildActiveAlertsList(),
        ],
      ),
    );
  }

  Widget _buildAlertsOverview() {
    final criticalAlerts = _activeAlerts.where((a) => a.severity == AlertSeverity.critical).length;
    final highAlerts = _activeAlerts.where((a) => a.severity == AlertSeverity.high).length;
    final mediumAlerts = _activeAlerts.where((a) => a.severity == AlertSeverity.medium).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Active Alerts Overview', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAlertCounter('Critical', criticalAlerts, Colors.red),
                _buildAlertCounter('High', highAlerts, Colors.orange),
                _buildAlertCounter('Medium', mediumAlerts, Colors.yellow.shade700),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCounter(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActiveAlertsList() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Active Security Alerts', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _acknowledgeAllAlerts,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Acknowledge All'),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _activeAlerts.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final alert = _activeAlerts[index];
              return ListTile(
                leading: Icon(
                  _getAlertIcon(alert.type),
                  color: _getAlertSeverityColor(alert.severity),
                ),
                title: Text(alert.title),
                subtitle: Text('${alert.description}\n${DateFormat.yMd().add_Hm().format(alert.timestamp)}'),
                isThreeLine: true,
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'acknowledge', child: Text('Acknowledge')),
                    const PopupMenuItem(value: 'escalate', child: Text('Escalate')),
                    const PopupMenuItem(value: 'dismiss', child: Text('Dismiss')),
                  ],
                  onSelected: (value) => _handleAlertAction(alert, value as String),
                ),
                onTap: () => _showAlertDetails(alert),
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper methods for UI
  Widget _getThreatIcon(ThreatSeverity severity) {
    switch (severity) {
      case ThreatSeverity.critical:
        return const Icon(Icons.dangerous, color: Colors.red);
      case ThreatSeverity.high:
        return const Icon(Icons.warning, color: Colors.orange);
      case ThreatSeverity.medium:
        return const Icon(Icons.info, color: Colors.yellow);
      case ThreatSeverity.low:
        return const Icon(Icons.info_outline, color: Colors.blue);
    }
  }

  Color _getSeverityColor(ThreatSeverity severity) {
    switch (severity) {
      case ThreatSeverity.critical:
        return Colors.red;
      case ThreatSeverity.high:
        return Colors.orange;
      case ThreatSeverity.medium:
        return Colors.yellow.shade700;
      case ThreatSeverity.low:
        return Colors.blue;
    }
  }

  IconData _getIPReputationIcon(IPReputation reputation) {
    switch (reputation) {
      case IPReputation.malicious:
        return Icons.dangerous;
      case IPReputation.suspicious:
        return Icons.warning;
      case IPReputation.clean:
        return Icons.check_circle;
      case IPReputation.unknown:
        return Icons.help;
    }
  }

  Color _getIPReputationColor(IPReputation reputation) {
    switch (reputation) {
      case IPReputation.malicious:
        return Colors.red;
      case IPReputation.suspicious:
        return Colors.orange;
      case IPReputation.clean:
        return Colors.green;
      case IPReputation.unknown:
        return Colors.grey;
    }
  }

  Color _getAnomalyColor(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.critical:
        return Colors.red;
      case RiskLevel.high:
        return Colors.orange;
      case RiskLevel.medium:
        return Colors.yellow.shade700;
      case RiskLevel.low:
        return Colors.blue;
    }
  }

  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.suspiciousLogin:
        return Icons.login;
      case AlertType.bruteForce:
        return Icons.security;
      case AlertType.malwareDetection:
        return Icons.bug_report;
      case AlertType.dataExfiltration:
        return Icons.cloud_download;
      case AlertType.anomalousActivity:
        return Icons.trending_up;
    }
  }

  Color _getAlertSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Colors.red;
      case AlertSeverity.high:
        return Colors.orange;
      case AlertSeverity.medium:
        return Colors.yellow.shade700;
      case AlertSeverity.low:
        return Colors.blue;
    }
  }

  // Action methods
  void _showThreatSettings() {
    // TODO: Implement threat settings dialog
  }

  Future<void> _runThreatScan() async {
    // TODO: Implement manual threat scan
  }

  void _showThreatDetails(ThreatFeed threat) {
    // TODO: Show detailed threat information
  }

  void _checkNewIP() {
    // TODO: Show IP check dialog
  }

  void _showIPDetails(IPReputationResult ipCheck) {
    // TODO: Show detailed IP information
  }

  void _showAnomalyDetails(GeolocationAnomaly anomaly) {
    // TODO: Show detailed anomaly information
  }

  void _acknowledgeAllAlerts() {
    // TODO: Acknowledge all active alerts
  }

  void _handleAlertAction(ThreatAlert alert, String action) {
    // TODO: Handle alert actions (acknowledge, escalate, dismiss)
  }

  void _showAlertDetails(ThreatAlert alert) {
    // TODO: Show detailed alert information
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
