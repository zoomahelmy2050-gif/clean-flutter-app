import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/services/usage_analytics_service.dart';
import '../../locator.dart';
import '../../generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:clean_flutter/core/services/language_service.dart';

class UsageDashboardPage extends StatefulWidget {
  const UsageDashboardPage({super.key});

  @override
  State<UsageDashboardPage> createState() => _UsageDashboardPageState();
}

class _UsageDashboardPageState extends State<UsageDashboardPage>
    with SingleTickerProviderStateMixin {
  late UsageAnalyticsService _analyticsService;
  late TabController _tabController;
  String _selectedPeriod = '7d';
  Map<String, dynamic>? _statistics;
  List<Map<String, dynamic>>? _mostUsedFeatures;
  Map<String, dynamic>? _performanceMetrics;

  @override
  void initState() {
    super.initState();
    _analyticsService = locator<UsageAnalyticsService>();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final endDate = DateTime.now();
    DateTime? startDate;
    
    switch (_selectedPeriod) {
      case '1d':
        startDate = endDate.subtract(const Duration(days: 1));
        break;
      case '7d':
        startDate = endDate.subtract(const Duration(days: 7));
        break;
      case '30d':
        startDate = endDate.subtract(const Duration(days: 30));
        break;
      case '90d':
        startDate = endDate.subtract(const Duration(days: 90));
        break;
    }

    setState(() {
      _statistics = _analyticsService.getUsageStatistics(
        startDate: startDate,
        endDate: endDate,
      );
      _mostUsedFeatures = _analyticsService.getMostUsedFeatures(limit: 10);
      _performanceMetrics = _analyticsService.getPerformanceMetrics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<LanguageService>(
          builder: (context, languageService, child) {
            final l10n = AppLocalizations.of(context)!;
            return Text(l10n.usageDashboard);
          },
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.date_range),
            onSelected: (period) {
              setState(() {
                _selectedPeriod = period;
              });
              _loadData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '1d', child: Text('Last 24 hours')),
              const PopupMenuItem(value: '7d', child: Text('Last 7 days')),
              const PopupMenuItem(value: '30d', child: Text('Last 30 days')),
              const PopupMenuItem(value: '90d', child: Text('Last 90 days')),
            ],
          ),
          IconButton(
            onPressed: _showExportDialog,
            icon: const Icon(Icons.download),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Features', icon: Icon(Icons.functions)),
            Tab(text: 'Trends', icon: Icon(Icons.trending_up)),
            Tab(text: 'Performance', icon: Icon(Icons.speed)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildFeaturesTab(),
          _buildTrendsTab(),
          _buildPerformanceTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_statistics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPeriodSelector(),
        const SizedBox(height: 16),
        _buildStatisticsGrid(),
        const SizedBox(height: 16),
        _buildSessionChart(),
        const SizedBox(height: 16),
        _buildEventTypeChart(),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time Period',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildPeriodChip('1d', 'Today'),
                _buildPeriodChip('7d', '7 Days'),
                _buildPeriodChip('30d', '30 Days'),
                _buildPeriodChip('90d', '90 Days'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String value, String label) {
    final isSelected = _selectedPeriod == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPeriod = value;
          });
          _loadData();
        }
      },
    );
  }

  Widget _buildStatisticsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Total Events',
          _statistics!['totalEvents'].toString(),
          Icons.event,
          Colors.blue,
        ),
        _buildStatCard(
          'Sessions',
          _statistics!['totalSessions'].toString(),
          Icons.access_time,
          Colors.green,
        ),
        _buildStatCard(
          'Avg Session',
          '${_statistics!['avgSessionDuration'].toStringAsFixed(1)}m',
          Icons.timer,
          Colors.orange,
        ),
        _buildStatCard(
          'Active Sessions',
          _statistics!['activeSessions'].toString(),
          Icons.play_circle,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
                fontSize: 24,
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

  Widget _buildSessionChart() {
    final dailyUsage = _statistics!['dailyUsage'] as Map<String, int>;
    
    if (dailyUsage.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No session data available'),
        ),
      );
    }

    final spots = dailyUsage.entries.map((entry) {
      final date = DateTime.parse(entry.key);
      return FlSpot(
        date.millisecondsSinceEpoch.toDouble(),
        entry.value.toDouble(),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Sessions',
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
                          final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                          return Text('${date.day}/${date.month}');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTypeChart() {
    final eventTypes = _statistics!['eventTypeBreakdown'] as Map<String, int>;
    
    if (eventTypes.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No event data available'),
        ),
      );
    }

    final sections = eventTypes.entries.map((entry) {
      final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];
      final colorIndex = eventTypes.keys.toList().indexOf(entry.key) % colors.length;
      
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${entry.value}',
        color: colors[colorIndex],
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
              'Event Types',
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
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: eventTypes.entries.map((entry) {
                final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];
                final colorIndex = eventTypes.keys.toList().indexOf(entry.key) % colors.length;
                
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: colors[colorIndex],
                    radius: 6,
                  ),
                  label: Text('${entry.key}: ${entry.value}'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesTab() {
    if (_mostUsedFeatures == null) {
      return const Center(child: CircularProgressIndicator());
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
                  'Most Used Features',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ..._mostUsedFeatures!.map((feature) => _buildFeatureItem(feature)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(Map<String, dynamic> feature) {
    final percentage = feature['percentage'] as double;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                feature['feature'],
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text('${feature['usage']} (${percentage.toStringAsFixed(1)}%)'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.blue.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    final trends = _analyticsService.getUsageTrends(days: 30);
    final dailyEvents = trends['dailyEvents'] as List<Map<String, dynamic>>?;

    if (dailyEvents == null || dailyEvents.isEmpty) {
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
                  'Usage Trends (30 Days)',
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
                              if (index >= 0 && index < dailyEvents.length) {
                                final date = DateTime.parse(dailyEvents[index]['date']);
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
                        LineChartBarData(
                          spots: dailyEvents.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              entry.value['count'].toDouble(),
                            );
                          }).toList(),
                          isCurved: true,
                          color: Colors.green,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceTab() {
    if (_performanceMetrics == null) {
      return const Center(child: CircularProgressIndicator());
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
                  'Performance Metrics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildMetricRow('Average Duration', '${_performanceMetrics!['avgDuration'].toStringAsFixed(2)}ms'),
                _buildMetricRow('Minimum Duration', '${_performanceMetrics!['minDuration'].toStringAsFixed(2)}ms'),
                _buildMetricRow('Maximum Duration', '${_performanceMetrics!['maxDuration'].toStringAsFixed(2)}ms'),
                _buildMetricRow('Median Duration', '${_performanceMetrics!['medianDuration'].toStringAsFixed(2)}ms'),
                _buildMetricRow('Total Operations', _performanceMetrics!['totalOperations'].toString()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.blue)),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Analytics'),
        content: const Text('Export analytics data as JSON file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final data = _analyticsService.exportData();
              // Here you would implement file export functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Analytics data exported')),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }
}
