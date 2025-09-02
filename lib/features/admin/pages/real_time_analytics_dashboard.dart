import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:math';
import 'package:clean_flutter/core/services/real_time_analytics_service.dart';
import 'package:clean_flutter/locator.dart';

class RealTimeAnalyticsDashboard extends StatefulWidget {
  const RealTimeAnalyticsDashboard({super.key});

  @override
  State<RealTimeAnalyticsDashboard> createState() => _RealTimeAnalyticsDashboardState();
}

class _RealTimeAnalyticsDashboardState extends State<RealTimeAnalyticsDashboard>
    with TickerProviderStateMixin {
  final RealTimeAnalyticsService _analyticsService = locator<RealTimeAnalyticsService>();
  
  late TabController _tabController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  List<SecurityMetrics> _metricsData = [];
  List<ThreatEvent> _threatData = [];
  List<UserActivity> _activityData = [];
  SystemHealth? _currentHealth;
  ComplianceStatus? _currentCompliance;
  Map<String, dynamic> _analyticsSummary = {};

  StreamSubscription<SecurityMetrics>? _metricsSubscription;
  StreamSubscription<ThreatEvent>? _threatSubscription;
  StreamSubscription<UserActivity>? _activitySubscription;
  StreamSubscription<SystemHealth>? _healthSubscription;
  StreamSubscription<ComplianceStatus>? _complianceSubscription;

  bool _isLiveMode = true;
  String _selectedTimeRange = '1H';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _initializeStreams();
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _metricsSubscription?.cancel();
    _threatSubscription?.cancel();
    _activitySubscription?.cancel();
    _healthSubscription?.cancel();
    _complianceSubscription?.cancel();
    super.dispose();
  }

  void _initializeStreams() {
    if (_isLiveMode) {
      _metricsSubscription = _analyticsService.metricsStream.listen((metrics) {
        setState(() {
          _metricsData.add(metrics);
          if (_metricsData.length > 50) _metricsData.removeAt(0);
        });
      });

      _threatSubscription = _analyticsService.threatStream.listen((threat) {
        setState(() {
          _threatData.add(threat);
          if (_threatData.length > 20) _threatData.removeAt(0);
        });
      });

      _activitySubscription = _analyticsService.activityStream.listen((activity) {
        setState(() {
          _activityData.add(activity);
          if (_activityData.length > 100) _activityData.removeAt(0);
        });
      });

      _healthSubscription = _analyticsService.healthStream.listen((health) {
        setState(() {
          _currentHealth = health;
        });
      });

      _complianceSubscription = _analyticsService.complianceStream.listen((compliance) {
        setState(() {
          _currentCompliance = compliance;
        });
      });
    }
  }

  void _loadInitialData() {
    final period = _getSelectedPeriod();
    setState(() {
      _metricsData = _analyticsService.getMetricsHistory(period: period);
      _threatData = _analyticsService.getThreatHistory(period: period);
      _activityData = _analyticsService.getActivityHistory(period: period);
      _analyticsSummary = _analyticsService.getAnalyticsSummary();
    });
  }

  Duration _getSelectedPeriod() {
    switch (_selectedTimeRange) {
      case '15M':
        return const Duration(minutes: 15);
      case '1H':
        return const Duration(hours: 1);
      case '6H':
        return const Duration(hours: 6);
      case '24H':
        return const Duration(hours: 24);
      default:
        return const Duration(hours: 1);
    }
  }

  void _toggleLiveMode() {
    setState(() {
      _isLiveMode = !_isLiveMode;
    });
    
    if (_isLiveMode) {
      _initializeStreams();
    } else {
      _metricsSubscription?.cancel();
      _threatSubscription?.cancel();
      _activitySubscription?.cancel();
      _healthSubscription?.cancel();
      _complianceSubscription?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildControlPanel(),
          _buildSummaryCards(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSecurityMetricsTab(),
                _buildThreatAnalysisTab(),
                _buildUserActivityTab(),
                _buildSystemHealthTab(),
                _buildComplianceTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A1F3A),
      elevation: 0,
      title: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isLiveMode ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _isLiveMode ? Colors.red : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          const Text(
            'Real-Time Security Analytics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isLiveMode ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
          ),
          onPressed: _toggleLiveMode,
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadInitialData,
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF00D4AA),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(text: 'Metrics'),
          Tab(text: 'Threats'),
          Tab(text: 'Activity'),
          Tab(text: 'Health'),
          Tab(text: 'Compliance'),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1A1F3A),
      child: Row(
        children: [
          const Text(
            'Time Range:',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          ...['15M', '1H', '6H', '24H'].map((range) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(range),
                selected: _selectedTimeRange == range,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedTimeRange = range;
                    });
                    _loadInitialData();
                  }
                },
                selectedColor: const Color(0xFF00D4AA),
                backgroundColor: const Color(0xFF2A2F4A),
                labelStyle: TextStyle(
                  color: _selectedTimeRange == range ? Colors.black : Colors.white,
                ),
              ),
            );
          }).toList(),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isLiveMode ? Colors.red.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isLiveMode ? Colors.red : Colors.grey,
                width: 1,
              ),
            ),
            child: Text(
              _isLiveMode ? 'LIVE' : 'PAUSED',
              style: TextStyle(
                color: _isLiveMode ? Colors.red : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildSummaryCard('Active Threats', '${_analyticsSummary['critical_threats'] ?? 0}', Colors.red, Icons.warning)),
          const SizedBox(width: 12),
          Expanded(child: _buildSummaryCard('Total Events', '${_analyticsSummary['total_activities'] ?? 0}', Colors.blue, Icons.event)),
          const SizedBox(width: 12),
          Expanded(child: _buildSummaryCard('Avg Response', '${(_analyticsSummary['average_response_time'] ?? 0).toStringAsFixed(1)}ms', Colors.green, Icons.speed)),
          const SizedBox(width: 12),
          Expanded(child: _buildSummaryCard('Security Score', '${(_analyticsSummary['average_security_score'] ?? 0).toStringAsFixed(1)}/10', Colors.orange, Icons.security)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Placeholder tab methods - will be implemented in separate files
  Widget _buildSecurityMetricsTab() {
    return const Center(
      child: Text(
        'Security Metrics - Real-time charts and performance data',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  Widget _buildThreatAnalysisTab() {
    return const Center(
      child: Text(
        'Threat Analysis - Advanced threat visualization and timeline',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  Widget _buildUserActivityTab() {
    return const Center(
      child: Text(
        'User Activity - Activity monitoring and behavior analysis',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  Widget _buildSystemHealthTab() {
    return const Center(
      child: Text(
        'System Health - Infrastructure monitoring and alerts',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  Widget _buildComplianceTab() {
    return const Center(
      child: Text(
        'Compliance - Regulatory compliance tracking and reporting',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
