import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../locator.dart';
import 'services/threat_intelligence_service.dart';
import '../../core/models/threat_models.dart';

class UserRiskScoringPage extends StatefulWidget {
  const UserRiskScoringPage({super.key});

  @override
  State<UserRiskScoringPage> createState() => _UserRiskScoringPageState();
}

class _UserRiskScoringPageState extends State<UserRiskScoringPage> 
    with TickerProviderStateMixin {
  final _threatService = locator<ThreatIntelligenceService>();
  late TabController _tabController;
  
  List<UserRiskProfile> _riskProfiles = [];
  List<UserRiskProfile> _highRiskUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRiskData();
  }

  Future<void> _loadRiskData() async {
    setState(() => _isLoading = true);
    
    try {
      // Mock user list - in real app, get from user service
      final userEmails = [
        'user@example.com',
        'admin@company.com', 
        'john.doe@company.com',
        'jane.smith@company.com',
        'security@company.com',
        'guest@company.com',
      ];
      
      final profiles = <UserRiskProfile>[];
      for (final email in userEmails) {
        final profile = await _threatService.getUserRiskProfile(email);
        profiles.add(profile);
      }
      
      setState(() {
        _riskProfiles = profiles;
        _highRiskUsers = profiles.where((p) => 
          p.riskLevel == RiskLevel.high || p.riskLevel == RiskLevel.critical
        ).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading risk data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Risk Scoring'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRiskData,
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showRiskAnalytics,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'All Users'),
            Tab(icon: Icon(Icons.warning), text: 'High Risk'),
            Tab(icon: Icon(Icons.timeline), text: 'Risk Trends'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAllUsersTab(),
                _buildHighRiskTab(),
                _buildRiskTrendsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _runRiskAssessment,
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.assessment),
        label: const Text('Run Assessment'),
      ),
    );
  }

  Widget _buildAllUsersTab() {
    final filteredProfiles = _riskProfiles.where((profile) =>
      _searchQuery.isEmpty || 
      profile.userEmail.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Column(
      children: [
        _buildRiskOverviewCards(),
        _buildSearchBar(),
        Expanded(child: _buildUserRiskList(filteredProfiles)),
      ],
    );
  }

  Widget _buildRiskOverviewCards() {
    final criticalUsers = _riskProfiles.where((p) => p.riskLevel == RiskLevel.critical).length;
    final highUsers = _riskProfiles.where((p) => p.riskLevel == RiskLevel.high).length;
    final mediumUsers = _riskProfiles.where((p) => p.riskLevel == RiskLevel.medium).length;
    final lowUsers = _riskProfiles.where((p) => p.riskLevel == RiskLevel.low).length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildRiskCard('Critical', criticalUsers, Colors.red)),
          const SizedBox(width: 8),
          Expanded(child: _buildRiskCard('High', highUsers, Colors.orange)),
          const SizedBox(width: 8),
          Expanded(child: _buildRiskCard('Medium', mediumUsers, Colors.yellow.shade700)),
          const SizedBox(width: 8),
          Expanded(child: _buildRiskCard('Low', lowUsers, Colors.green)),
        ],
      ),
    );
  }

  Widget _buildRiskCard(String title, int count, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  count.toString(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search users...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildUserRiskList(List<UserRiskProfile> profiles) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: profiles.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final profile = profiles[index];
        return _buildUserRiskCard(profile);
      },
    );
  }

  Widget _buildUserRiskCard(UserRiskProfile profile) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRiskLevelColor(profile.riskLevel),
          child: Text(
            profile.riskScore.toInt().toString(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(profile.userEmail),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(profile.riskLevel.name.toUpperCase()),
                  backgroundColor: _getRiskLevelColor(profile.riskLevel),
                  labelStyle: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                const SizedBox(width: 8),
                Text('Score: ${profile.riskScore.toStringAsFixed(1)}'),
              ],
            ),
            if (profile.riskFactors.isNotEmpty)
              Text(
                'Factors: ${profile.riskFactors.map((f) => f.type).join(', ')}',
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View Details')),
            const PopupMenuItem(value: 'adjust', child: Text('Adjust Score')),
            const PopupMenuItem(value: 'monitor', child: Text('Enhanced Monitoring')),
          ],
          onSelected: (value) => _handleUserAction(profile, value as String),
        ),
        onTap: () => _showUserRiskDetails(profile),
      ),
    );
  }

  Widget _buildHighRiskTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade700, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'High Risk Users Alert',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        Text(
                          '${_highRiskUsers.length} users require immediate attention',
                          style: TextStyle(color: Colors.red.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: _buildUserRiskList(_highRiskUsers)),
      ],
    );
  }

  Widget _buildRiskTrendsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildRiskTrendsChart(),
        const SizedBox(height: 16),
        _buildRiskFactorsAnalysis(),
        const SizedBox(height: 16),
        _buildRiskPredictions(),
      ],
    );
  }

  Widget _buildRiskTrendsChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Risk Score Trends (Last 7 Days)',
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
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString());
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          if (value.toInt() < days.length) {
                            return Text(days[value.toInt()]);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateRiskTrendData(),
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                  minY: 0,
                  maxY: 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _generateRiskTrendData() {
    // Mock trend data - in real app, calculate from historical data
    return [
      const FlSpot(0, 25),
      const FlSpot(1, 30),
      const FlSpot(2, 45),
      const FlSpot(3, 35),
      const FlSpot(4, 55),
      const FlSpot(5, 40),
      const FlSpot(6, 50),
    ];
  }

  Widget _buildRiskFactorsAnalysis() {
    final riskFactors = {
      'Geographic Anomalies': 35,
      'Failed Login Attempts': 28,
      'Unusual Access Patterns': 20,
      'Suspicious IP Addresses': 12,
      'Off-hours Activity': 5,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Risk Factors Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...riskFactors.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(entry.key),
                  ),
                  Expanded(
                    flex: 2,
                    child: LinearProgressIndicator(
                      value: entry.value / 100,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getFactorColor(entry.value),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${entry.value}%'),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Color _getFactorColor(int percentage) {
    if (percentage > 30) return Colors.red;
    if (percentage > 20) return Colors.orange;
    if (percentage > 10) return Colors.yellow.shade700;
    return Colors.green;
  }

  Widget _buildRiskPredictions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Risk Predictions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPredictionItem(
              'user@example.com',
              'High risk of account compromise',
              85,
              Colors.red,
              'Based on recent geographic anomalies and failed login attempts',
            ),
            const Divider(),
            _buildPredictionItem(
              'john.doe@company.com',
              'Potential insider threat',
              70,
              Colors.orange,
              'Unusual data access patterns detected',
            ),
            const Divider(),
            _buildPredictionItem(
              'jane.smith@company.com',
              'Elevated privilege escalation risk',
              60,
              Colors.yellow.shade700,
              'Recent role changes and access requests',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionItem(String user, String prediction, int confidence, 
      Color color, String details) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  user,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Chip(
                label: Text('${confidence}%'),
                backgroundColor: color,
                labelStyle: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            prediction,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            details,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Color _getRiskLevelColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.critical:
        return Colors.red;
      case RiskLevel.high:
        return Colors.orange;
      case RiskLevel.medium:
        return Colors.yellow.shade700;
      case RiskLevel.low:
        return Colors.green;
    }
  }

  void _showRiskAnalytics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Risk Analytics Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.timeline),
              title: Text('Trend Analysis Period'),
              subtitle: Text('Configure historical analysis timeframe'),
            ),
            ListTile(
              leading: Icon(Icons.tune),
              title: Text('Risk Thresholds'),
              subtitle: Text('Adjust risk level boundaries'),
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Alert Configuration'),
              subtitle: Text('Set up automated risk alerts'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Configure'),
          ),
        ],
      ),
    );
  }

  Future<void> _runRiskAssessment() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Running comprehensive risk assessment...'),
          ],
        ),
      ),
    );

    // Simulate assessment
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Risk assessment completed. 2 new high-risk users identified.'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadRiskData();
    }
  }

  void _handleUserAction(UserRiskProfile profile, String action) {
    switch (action) {
      case 'view':
        _showUserRiskDetails(profile);
        break;
      case 'adjust':
        _showAdjustScoreDialog(profile);
        break;
      case 'monitor':
        _enableEnhancedMonitoring(profile);
        break;
    }
  }

  void _showUserRiskDetails(UserRiskProfile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Risk Profile: ${profile.userEmail}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Risk Score: ${profile.riskScore.toStringAsFixed(1)}'),
                  const Spacer(),
                  Chip(
                    label: Text(profile.riskLevel.name.toUpperCase()),
                    backgroundColor: _getRiskLevelColor(profile.riskLevel),
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Risk Factors:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...profile.riskFactors.map((factor) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.warning, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(child: Text(factor.description)),
                    Text('+${factor.impact.toStringAsFixed(0)}'),
                  ],
                ),
              )),
              if (profile.riskFactors.isEmpty)
                const Text('No specific risk factors identified.'),
              const SizedBox(height: 16),
              Text('Last Updated: ${DateFormat.yMd().add_Hm().format(profile.lastUpdated)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showAdjustScoreDialog(profile);
            },
            child: const Text('Adjust Score'),
          ),
        ],
      ),
    );
  }

  void _showAdjustScoreDialog(UserRiskProfile profile) {
    final scoreController = TextEditingController(text: profile.riskScore.toStringAsFixed(1));
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adjust Risk Score: ${profile.userEmail}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: scoreController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'New Risk Score (0-100)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for adjustment',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newScore = double.tryParse(scoreController.text);
              if (newScore != null && newScore >= 0 && newScore <= 100) {
                await _threatService.updateUserRiskScore(
                  profile.userEmail,
                  newScore,
                  reasonController.text.isEmpty ? 'Manual adjustment' : reasonController.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                  _loadRiskData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Risk score updated for ${profile.userEmail}')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _enableEnhancedMonitoring(UserRiskProfile profile) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Enhanced monitoring enabled for ${profile.userEmail}'),
        action: SnackBarAction(
          label: 'Configure',
          onPressed: () {
            // TODO: Show monitoring configuration
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
