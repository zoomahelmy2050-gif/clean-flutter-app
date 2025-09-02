import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../locator.dart';
import '../auth/services/auth_service.dart';
import 'services/logging_service.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../core/services/enhanced_rbac_service.dart';

class SecurityAnalyticsPage extends StatefulWidget {
  const SecurityAnalyticsPage({super.key});

  @override
  State<SecurityAnalyticsPage> createState() => _SecurityAnalyticsPageState();
}

class _SecurityAnalyticsPageState extends State<SecurityAnalyticsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTimeRange = 7; // days
  
  final _rbacService = locator<EnhancedRBACService>();
  final _authService = locator<AuthService>();
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkPermissions();
  }
  
  Future<void> _checkPermissions() async {
    final currentUserEmail = _authService.currentUser;
    if (currentUserEmail != null) {
      // Always grant access to superadmin email
      if (currentUserEmail.toLowerCase() == 'env.hygiene@gmail.com') {
        if (mounted) {
          setState(() {
            _hasPermission = true;
          });
        }
        return;
      }
      
      // Initialize RBAC service for other users
      await _rbacService.initialize(currentUserEmail);
      
      // Check if user has permission to view analytics
      final hasPermission = await _rbacService.hasPermission(
        Permission.viewAnalytics,
      );
      if (mounted) {
        setState(() {
          _hasPermission = hasPermission;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check permissions and show access denied if user doesn't have permission
    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Security Analytics'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 100,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Access Denied',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'You need the "View Analytics" permission to access this page.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Analytics'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Risk Scoring', icon: Icon(Icons.warning_amber)),
            Tab(text: 'Anomaly Detection', icon: Icon(Icons.search)),
            Tab(text: 'Threat Intelligence', icon: Icon(Icons.security)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildRiskScoringTab(),
          _buildAnomalyDetectionTab(),
          _buildThreatIntelligenceTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeRangeSelector(),
          const SizedBox(height: 20),
          _buildSecurityMetricsGrid(),
          const SizedBox(height: 20),
          _buildLoginTrendsChart(),
          const SizedBox(height: 20),
          _buildThreatLevelIndicator(),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('Time Range: ', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 7, label: Text('7 Days')),
                ButtonSegment(value: 30, label: Text('30 Days')),
                ButtonSegment(value: 90, label: Text('90 Days')),
              ],
              selected: {_selectedTimeRange},
              onSelectionChanged: (Set<int> selection) {
                setState(() {
                  _selectedTimeRange = selection.first;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityMetricsGrid() {
    final loggingService = locator<LoggingService>();
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildMetricCard(
          'Total Logins',
          loggingService.successfulLogins.length.toString(),
          Icons.login,
          Colors.green,
          '+12% vs last period',
        ),
        _buildMetricCard(
          'Failed Attempts',
          loggingService.failedAttempts.length.toString(),
          Icons.warning,
          Colors.red,
          '-5% vs last period',
        ),
        _buildMetricCard(
          'MFA Usage',
          '${(loggingService.mfaUsed.length / max(loggingService.successfulLogins.length, 1) * 100).toInt()}%',
          Icons.verified_user,
          Colors.blue,
          '+8% vs last period',
        ),
        _buildMetricCard(
          'Risk Score',
          _calculateOverallRiskScore().toString(),
          Icons.security,
          _getRiskColor(_calculateOverallRiskScore()),
          'Medium risk level',
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String trend) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              trend,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginTrendsChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Login Trends',
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
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.now().subtract(Duration(days: _selectedTimeRange - value.toInt()));
                          return Text(DateFormat('MM/dd').format(date));
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateLoginTrendData(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: _generateFailedLoginTrendData(),
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
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
                _buildLegendItem('Successful Logins', Colors.blue),
                const SizedBox(width: 20),
                _buildLegendItem('Failed Attempts', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreatLevelIndicator() {
    final threatLevel = _calculateThreatLevel();
    final color = _getThreatLevelColor(threatLevel);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Threat Level',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.2),
                    border: Border.all(color: color, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      threatLevel,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Threat Level: $threatLevel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getThreatLevelDescription(threatLevel),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskScoringTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Risk Scores',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildRiskScoreList(),
          const SizedBox(height: 20),
          const Text(
            'Risk Factors',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildRiskFactorsGrid(),
        ],
      ),
    );
  }

  Widget _buildRiskScoreList() {
    final authService = locator<AuthService>();
    final users = authService.getAllUsers();
    
    return Card(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: min(users.length, 10), // Show top 10
        itemBuilder: (context, index) {
          final user = users[index];
          final riskScore = _calculateUserRiskScore(user);
          final riskLevel = _getRiskLevel(riskScore);
          final color = _getRiskColor(riskScore);
          
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Text(
                user.substring(0, 1).toUpperCase(),
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(user),
            subtitle: Text('Risk Level: $riskLevel'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                riskScore.toString(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () => _showUserRiskDetails(user, riskScore),
          );
        },
      ),
    );
  }

  Widget _buildRiskFactorsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildRiskFactorCard('Failed Logins', 'High', Icons.warning, Colors.red),
        _buildRiskFactorCard('Unusual Locations', 'Medium', Icons.location_on, Colors.orange),
        _buildRiskFactorCard('Device Changes', 'Low', Icons.devices, Colors.green),
        _buildRiskFactorCard('Time Anomalies', 'Medium', Icons.access_time, Colors.orange),
      ],
    );
  }

  Widget _buildRiskFactorCard(String title, String level, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                level,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyDetectionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detected Anomalies',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildAnomalyList(),
          const SizedBox(height: 20),
          const Text(
            'Anomaly Detection Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildAnomalySettings(),
        ],
      ),
    );
  }

  Widget _buildAnomalyList() {
    final anomalies = _generateAnomalies();
    
    return Card(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: anomalies.length,
        itemBuilder: (context, index) {
          final anomaly = anomalies[index];
          return ListTile(
            leading: Icon(
              anomaly.icon,
              color: anomaly.severity == 'High' ? Colors.red : 
                     anomaly.severity == 'Medium' ? Colors.orange : Colors.yellow,
            ),
            title: Text(anomaly.title),
            subtitle: Text('${anomaly.description}\n${DateFormat.yMMMd().add_jm().format(anomaly.timestamp)}'),
            trailing: Chip(
              label: Text(anomaly.severity),
              backgroundColor: (anomaly.severity == 'High' ? Colors.red : 
                              anomaly.severity == 'Medium' ? Colors.orange : Colors.yellow).withOpacity(0.1),
            ),
            isThreeLine: true,
            onTap: () => _showAnomalyDetails(anomaly),
          );
        },
      ),
    );
  }

  Widget _buildAnomalySettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Login Location Monitoring'),
              subtitle: const Text('Detect logins from unusual locations'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('Failed Login Threshold'),
              subtitle: const Text('Alert on multiple failed attempts'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('Time-based Anomalies'),
              subtitle: const Text('Detect unusual login times'),
              value: false,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('Device Fingerprinting'),
              subtitle: const Text('Monitor new device logins'),
              value: true,
              onChanged: (value) {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreatIntelligenceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Threat Intelligence Feed',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildThreatFeed(),
          const SizedBox(height: 20),
          const Text(
            'IP Reputation',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildIPReputationList(),
        ],
      ),
    );
  }

  Widget _buildThreatFeed() {
    final threats = _generateThreatIntelligence();
    
    return Card(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: threats.length,
        itemBuilder: (context, index) {
          final threat = threats[index];
          return ListTile(
            leading: Icon(
              threat.type == 'Malware' ? Icons.bug_report :
              threat.type == 'Phishing' ? Icons.phishing :
              threat.type == 'Brute Force' ? Icons.security :
              Icons.warning,
              color: Colors.red,
            ),
            title: Text(threat.title),
            subtitle: Text('${threat.description}\nSource: ${threat.source}'),
            trailing: Text(
              DateFormat('MMM dd').format(threat.timestamp),
              style: TextStyle(color: Colors.grey[600]),
            ),
            isThreeLine: true,
          );
        },
      ),
    );
  }

  Widget _buildIPReputationList() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: const Text('192.168.1.100'),
            subtitle: const Text('Blocked - Malicious activity detected'),
            trailing: IconButton(
              icon: const Icon(Icons.info),
              onPressed: () {},
            ),
          ),
          ListTile(
            leading: const Icon(Icons.warning, color: Colors.orange),
            title: const Text('10.0.0.50'),
            subtitle: const Text('Suspicious - Multiple failed attempts'),
            trailing: IconButton(
              icon: const Icon(Icons.info),
              onPressed: () {},
            ),
          ),
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text('203.0.113.1'),
            subtitle: const Text('Clean - No threats detected'),
            trailing: IconButton(
              icon: const Icon(Icons.info),
              onPressed: () {},
            ),
          ),
        ],
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
  List<FlSpot> _generateLoginTrendData() {
    return List.generate(_selectedTimeRange, (index) {
      return FlSpot(index.toDouble(), (Random().nextInt(50) + 10).toDouble());
    });
  }

  List<FlSpot> _generateFailedLoginTrendData() {
    return List.generate(_selectedTimeRange, (index) {
      return FlSpot(index.toDouble(), (Random().nextInt(20) + 2).toDouble());
    });
  }

  int _calculateOverallRiskScore() {
    final loggingService = locator<LoggingService>();
    final failedAttempts = loggingService.failedAttempts.length;
    final successfulLogins = loggingService.successfulLogins.length;
    
    if (successfulLogins == 0) return 0;
    
    final failureRate = (failedAttempts / (failedAttempts + successfulLogins)) * 100;
    return failureRate.round();
  }

  int _calculateUserRiskScore(String user) {
    return Random().nextInt(100);
  }

  String _getRiskLevel(int score) {
    if (score >= 70) return 'High';
    if (score >= 40) return 'Medium';
    return 'Low';
  }

  Color _getRiskColor(int score) {
    if (score >= 70) return Colors.red;
    if (score >= 40) return Colors.orange;
    return Colors.green;
  }

  String _calculateThreatLevel() {
    final riskScore = _calculateOverallRiskScore();
    if (riskScore >= 70) return 'HIGH';
    if (riskScore >= 40) return 'MEDIUM';
    return 'LOW';
  }

  Color _getThreatLevelColor(String level) {
    switch (level) {
      case 'HIGH': return Colors.red;
      case 'MEDIUM': return Colors.orange;
      default: return Colors.green;
    }
  }

  String _getThreatLevelDescription(String level) {
    switch (level) {
      case 'HIGH': return 'Immediate attention required. Multiple security incidents detected.';
      case 'MEDIUM': return 'Monitor closely. Some suspicious activities detected.';
      default: return 'Normal operations. No significant threats detected.';
    }
  }

  List<_Anomaly> _generateAnomalies() {
    return [
      _Anomaly(
        'Unusual Login Location',
        'User john@example.com logged in from a new country',
        'High',
        Icons.location_on,
        DateTime.now().subtract(const Duration(hours: 2)),
      ),
      _Anomaly(
        'Multiple Failed Attempts',
        'User admin@example.com had 15 failed login attempts',
        'Medium',
        Icons.warning,
        DateTime.now().subtract(const Duration(hours: 6)),
      ),
      _Anomaly(
        'Off-hours Access',
        'User manager@example.com accessed system at 3 AM',
        'Low',
        Icons.access_time,
        DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ];
  }

  List<_ThreatIntel> _generateThreatIntelligence() {
    return [
      _ThreatIntel(
        'New Phishing Campaign Detected',
        'Targeting financial institutions with fake login pages',
        'Phishing',
        'ThreatFeed Pro',
        DateTime.now().subtract(const Duration(hours: 1)),
      ),
      _ThreatIntel(
        'Malware Signature Update',
        'New variant of banking trojan identified',
        'Malware',
        'Security Vendor',
        DateTime.now().subtract(const Duration(hours: 4)),
      ),
      _ThreatIntel(
        'Brute Force Attack Pattern',
        'Coordinated attack on SSH services detected',
        'Brute Force',
        'Honeypot Network',
        DateTime.now().subtract(const Duration(hours: 8)),
      ),
    ];
  }

  void _showUserRiskDetails(String user, int riskScore) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Risk Details: $user'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Risk Score: $riskScore'),
            Text('Risk Level: ${_getRiskLevel(riskScore)}'),
            const SizedBox(height: 12),
            const Text('Risk Factors:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('• Failed login attempts: 3'),
            const Text('• New device detected: Yes'),
            const Text('• Unusual login time: No'),
            const Text('• Geographic anomaly: No'),
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

  void _showAnomalyDetails(_Anomaly anomaly) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(anomaly.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${anomaly.description}'),
            Text('Severity: ${anomaly.severity}'),
            Text('Time: ${DateFormat.yMMMd().add_jm().format(anomaly.timestamp)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle anomaly action
            },
            child: const Text('Investigate'),
          ),
        ],
      ),
    );
  }
}

class _Anomaly {
  final String title;
  final String description;
  final String severity;
  final IconData icon;
  final DateTime timestamp;

  _Anomaly(this.title, this.description, this.severity, this.icon, this.timestamp);
}

class _ThreatIntel {
  final String title;
  final String description;
  final String type;
  final String source;
  final DateTime timestamp;

  _ThreatIntel(this.title, this.description, this.type, this.source, this.timestamp);
}
