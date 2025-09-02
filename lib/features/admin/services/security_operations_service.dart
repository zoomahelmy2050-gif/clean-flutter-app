import 'dart:async';
import 'dart:math';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../core/models/admin_models.dart';
import '../../../core/services/real_time_communication_service.dart';
import '../../../locator.dart';

class SecurityOperationsService {
  static final SecurityOperationsService _instance = SecurityOperationsService._internal();
  factory SecurityOperationsService() => _instance;
  SecurityOperationsService._internal();

  final Random _random = Random();
  Timer? _threatMapTimer;
  Timer? _metricsTimer;
  Timer? _feedTimer;

  // Streams for real-time updates
  final StreamController<List<ThreatLocation>> _threatLocationsController = StreamController<List<ThreatLocation>>.broadcast();
  final StreamController<SecurityScoreTrend> _securityTrendController = StreamController<SecurityScoreTrend>.broadcast();
  final StreamController<SecurityOperationsMetrics> _metricsController = StreamController<SecurityOperationsMetrics>.broadcast();
  final StreamController<List<LiveThreatFeed>> _threatFeedController = StreamController<List<LiveThreatFeed>>.broadcast();
  final StreamController<List<ExecutiveKPI>> _kpiController = StreamController<List<ExecutiveKPI>>.broadcast();

  Stream<List<ThreatLocation>> get threatLocationsStream => _threatLocationsController.stream;
  Stream<SecurityScoreTrend> get securityTrendStream => _securityTrendController.stream;
  Stream<SecurityOperationsMetrics> get metricsStream => _metricsController.stream;
  Stream<List<LiveThreatFeed>> get threatFeedStream => _threatFeedController.stream;
  Stream<List<ExecutiveKPI>> get kpiStream => _kpiController.stream;

  // Data storage
  final List<ThreatLocation> _threatLocations = [];
  final List<SecurityScoreTrend> _securityTrends = [];
  final List<ThreatHunterQuery> _huntQueries = [];
  final List<ThreatHuntResult> _huntResults = [];
  final List<ExecutiveKPI> _executiveKPIs = [];
  final List<LiveThreatFeed> _threatFeeds = [];
  SecurityOperationsMetrics? _currentMetrics;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    developer.log('Initializing Security Operations Service', name: 'SecurityOperationsService');
    
    await _generateInitialData();
    _startRealTimeUpdates();
    _connectToRealTimeService();
    
    _isInitialized = true;
    developer.log('Security Operations Service initialized', name: 'SecurityOperationsService');
  }

  void _connectToRealTimeService() {
    try {
      final realTimeService = locator<RealTimeCommunicationService>();
      
      // Mock threat alert subscription - real stream not available
      // realTimeService.threatAlertStream.listen((alert) => {
        final threatLocation = ThreatLocation(
          id: 'threat_${DateTime.now().millisecondsSinceEpoch}',
          latitude: _random.nextDouble() * 180 - 90,
          longitude: _random.nextDouble() * 360 - 180,
          country: 'Unknown',
          city: 'Unknown',
          region: GeographicRegion.north_america,
          attackType: AttackType.brute_force,
          threatLevel: ThreatLevel.medium,
          threatCount: 1,
          timestamp: DateTime.now(),
        );
        
        _threatLocations.insert(0, threatLocation);
        if (_threatLocations.length > 50) {
          _threatLocations.removeRange(50, _threatLocations.length);
        }
        _threatLocationsController.add(List.from(_threatLocations));
      // });
      
      // Mock system event subscription - real stream not available
      // realTimeService.systemEventStream.listen((event) => {
      //   _updateMetricsFromEvent(event);
      // });
      
      developer.log('Connected to real-time communication service', name: 'SecurityOperationsService');
    } catch (e) {
      developer.log('Failed to connect to real-time service: $e', name: 'SecurityOperationsService');
    }
  }

  ThreatSeverity _mapAlertSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return ThreatSeverity.critical;
      case 'high':
        return ThreatSeverity.high;
      case 'medium':
        return ThreatSeverity.medium;
      case 'low':
        return ThreatSeverity.low;
      default:
        return ThreatSeverity.medium;
    }
  }

  void _updateMetricsFromEvent(Map<String, dynamic> event) {
    if (_currentMetrics != null) {
      // Update metrics based on real events
      final updatedMetrics = SecurityOperationsMetrics(
        id: _currentMetrics!.id,
        timestamp: DateTime.now(),
        totalThreats: _currentMetrics!.totalThreats + (event['type'] == 'threat' ? 1 : 0),
        activeThreatHunts: _currentMetrics!.activeThreatHunts,
        resolvedIncidents: _currentMetrics!.resolvedIncidents + (event['status'] == 'resolved' ? 1 : 0),
        pendingAlerts: _currentMetrics!.pendingAlerts,
        meanTimeToDetection: _currentMetrics!.meanTimeToDetection,
        meanTimeToResponse: _currentMetrics!.meanTimeToResponse,
        meanTimeToResolution: _currentMetrics!.meanTimeToResolution,
        threatsByType: _currentMetrics!.threatsByType, // This might need more sophisticated update logic
        threatsBySeverity: _currentMetrics!.threatsBySeverity,
        threatsByRegion: _currentMetrics!.threatsByRegion,
        systemAvailability: _currentMetrics!.systemAvailability,
        securityEffectiveness: _currentMetrics!.securityEffectiveness,
      );
      
      _currentMetrics = updatedMetrics;
      _metricsController.add(updatedMetrics);
    }
  }

  double _calculateSecurityScore() {
    // Calculate based on recent threat activity
    final recentThreats = _threatLocations.where(
      (t) => DateTime.now().difference(t.timestamp).inHours < 24
    ).length;
    
    return (100 - (recentThreats * 2)).clamp(0, 100).toDouble();
  }

  Future<void> _generateInitialData() async {
    // Generate initial threat locations
    _threatLocations.addAll(_generateThreatLocations());
    
    // Generate security trends
    _securityTrends.addAll(_generateSecurityTrends());
    
    // Generate hunt queries
    _huntQueries.addAll(_generateHuntQueries());
    
    // Generate executive KPIs
    _executiveKPIs.addAll(_generateExecutiveKPIs());
    
    // Generate threat feeds
    _threatFeeds.addAll(_generateThreatFeeds());
    
    // Generate current metrics
    _currentMetrics = _generateCurrentMetrics();
  }

  void _startRealTimeUpdates() {
    // Update threat map every 15 seconds
    _threatMapTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _updateThreatMap();
    });

    // Update metrics every 30 seconds
    _metricsTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateMetrics();
    });

    // Update threat feeds every 45 seconds
    _feedTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      _updateThreatFeeds();
    });
  }

  void _updateThreatMap() {
    // Add new threat locations
    if (_random.nextDouble() < 0.4) { // 40% chance
      final newThreat = _generateRandomThreatLocation();
      _threatLocations.insert(0, newThreat);
      
      // Keep only last 100 threats
      if (_threatLocations.length > 100) {
        _threatLocations.removeRange(100, _threatLocations.length);
      }
    }
    
    _threatLocationsController.add(List.from(_threatLocations));
  }

  void _updateMetrics() {
    _currentMetrics = _generateCurrentMetrics();
    _metricsController.add(_currentMetrics!);
    
    // Generate new security trend
    final newTrend = _generateSecurityTrend();
    _securityTrends.insert(0, newTrend);
    if (_securityTrends.length > 50) {
      _securityTrends.removeRange(50, _securityTrends.length);
    }
    _securityTrendController.add(newTrend);
    
    // Update KPIs
    _updateExecutiveKPIs();
    _kpiController.add(List.from(_executiveKPIs));
  }

  void _updateThreatFeeds() {
    if (_random.nextDouble() < 0.3) { // 30% chance
      final newFeed = _generateRandomThreatFeed();
      _threatFeeds.insert(0, newFeed);
      
      // Keep only last 50 feeds
      if (_threatFeeds.length > 50) {
        _threatFeeds.removeRange(50, _threatFeeds.length);
      }
      
      _threatFeedController.add(List.from(_threatFeeds));
    }
  }

  List<ThreatLocation> _generateThreatLocations() {
    final locations = <ThreatLocation>[];
    final cities = [
      {'name': 'New York', 'lat': 40.7128, 'lng': -74.0060, 'country': 'USA', 'region': GeographicRegion.north_america},
      {'name': 'London', 'lat': 51.5074, 'lng': -0.1278, 'country': 'UK', 'region': GeographicRegion.europe},
      {'name': 'Tokyo', 'lat': 35.6762, 'lng': 139.6503, 'country': 'Japan', 'region': GeographicRegion.asia_pacific},
      {'name': 'Moscow', 'lat': 55.7558, 'lng': 37.6176, 'country': 'Russia', 'region': GeographicRegion.europe},
      {'name': 'Beijing', 'lat': 39.9042, 'lng': 116.4074, 'country': 'China', 'region': GeographicRegion.asia_pacific},
      {'name': 'São Paulo', 'lat': -23.5505, 'lng': -46.6333, 'country': 'Brazil', 'region': GeographicRegion.south_america},
      {'name': 'Mumbai', 'lat': 19.0760, 'lng': 72.8777, 'country': 'India', 'region': GeographicRegion.asia_pacific},
      {'name': 'Cairo', 'lat': 30.0444, 'lng': 31.2357, 'country': 'Egypt', 'region': GeographicRegion.africa},
    ];

    for (int i = 0; i < 25; i++) {
      final city = cities[_random.nextInt(cities.length)];
      locations.add(ThreatLocation(
        id: 'threat_${i}_${DateTime.now().millisecondsSinceEpoch}',
        latitude: city['lat'] as double,
        longitude: city['lng'] as double,
        country: city['country'] as String,
        city: city['name'] as String,
        region: city['region'] as GeographicRegion,
        attackType: AttackType.values[_random.nextInt(AttackType.values.length)],
        threatLevel: ThreatLevel.values[_random.nextInt(ThreatLevel.values.length)],
        threatCount: _random.nextInt(50) + 1,
        timestamp: DateTime.now().subtract(Duration(minutes: _random.nextInt(60))),
      ));
    }

    return locations;
  }

  List<SecurityScoreTrend> _generateSecurityTrends() {
    final trends = <SecurityScoreTrend>[];
    var currentScore = 85.0;

    for (int i = 0; i < 30; i++) {
      final previousScore = currentScore;
      currentScore += (-5 + _random.nextDouble() * 10);
      currentScore = currentScore.clamp(60.0, 100.0);

      trends.add(SecurityScoreTrend(
        id: 'trend_$i',
        timestamp: DateTime.now().subtract(Duration(hours: i)),
        overallScore: currentScore,
        previousScore: previousScore,
        changePercent: ((currentScore - previousScore) / previousScore) * 100,
        categoryScores: {
          'Authentication': 80 + _random.nextDouble() * 20,
          'Authorization': 75 + _random.nextDouble() * 25,
          'Data Protection': 85 + _random.nextDouble() * 15,
          'Network Security': 70 + _random.nextDouble() * 30,
          'Compliance': 90 + _random.nextDouble() * 10,
        },
        improvementAreas: _getRandomImprovementAreas(),
        riskFactors: _getRandomRiskFactors(),
        predictedScore: currentScore + (-3 + _random.nextDouble() * 6),
        predictionDate: DateTime.now().add(const Duration(hours: 24)),
        scores: [],
      ));
    }

    return trends.reversed.toList();
  }

  List<ThreatHunterQuery> _generateHuntQueries() {
    return [
      ThreatHunterQuery(
        id: 'query_1',
        name: 'Failed Login Attempts',
        description: 'Search for multiple failed login attempts from same IP',
        query: 'event_type:login AND status:failed | stats count by src_ip | where count > 5',
        queryLanguage: 'SPL',
        dataSource: ['auth_logs', 'security_events'],
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        createdBy: 'security_analyst',
        executionCount: 23,
        lastExecuted: DateTime.now().subtract(const Duration(hours: 2)),
        tags: ['authentication', 'brute_force'],
        isSaved: true,
        parameters: {'threshold': '5'},
      ),
      ThreatHunterQuery(
        id: 'query_2',
        name: 'Suspicious Data Exfiltration',
        description: 'Detect unusual data transfer patterns',
        query: 'bytes_out > 1000000 AND hour >= 22 OR hour <= 6',
        queryLanguage: 'KQL',
        dataSource: ['network_logs', 'firewall_logs'],
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        createdBy: 'threat_hunter',
        executionCount: 15,
        lastExecuted: DateTime.now().subtract(const Duration(hours: 6)),
        tags: ['data_exfiltration', 'anomaly'],
        isSaved: true,
        isScheduled: true,
        schedule: '0 */4 * * *',
        parameters: {'min_bytes': '1000000'},
      ),
    ];
  }

  List<ExecutiveKPI> _generateExecutiveKPIs() {
    return [
      ExecutiveKPI(
        id: 'kpi_1',
        name: 'Mean Time to Detection (MTTD)',
        description: 'Average time to detect security incidents',
        currentValue: 15.5,
        target: 10.0,
        previousValue: 18.2,
        unit: 'minutes',
        category: 'Detection',
        status: ThreatLevel.medium,
        lastUpdated: DateTime.now(),
        trendData: [18.2, 17.1, 16.8, 15.9, 15.5],
      ),
      ExecutiveKPI(
        id: 'kpi_2',
        name: 'Security Score',
        description: 'Overall security posture score',
        currentValue: 87.3,
        target: 90.0,
        previousValue: 85.1,
        unit: 'score',
        category: 'Posture',
        status: ThreatLevel.low,
        lastUpdated: DateTime.now(),
        trendData: [82.5, 84.2, 85.1, 86.7, 87.3],
      ),
      ExecutiveKPI(
        id: 'kpi_3',
        name: 'Critical Vulnerabilities',
        description: 'Number of unpatched critical vulnerabilities',
        currentValue: 3,
        target: 0,
        previousValue: 7,
        unit: 'count',
        category: 'Vulnerabilities',
        status: ThreatLevel.high,
        lastUpdated: DateTime.now(),
        trendData: [12, 9, 7, 5, 3],
      ),
    ];
  }

  List<LiveThreatFeed> _generateThreatFeeds() {
    final feeds = <LiveThreatFeed>[];
    final sources = ['VirusTotal', 'AbuseIPDB', 'MISP', 'Shodan', 'AlienVault'];
    final titles = [
      'New Ransomware Campaign Detected',
      'Suspicious IP Activity Reported',
      'Phishing Campaign Targeting Financial Sector',
      'Zero-Day Exploit in the Wild',
      'Botnet Command & Control Server Identified',
    ];

    for (int i = 0; i < 20; i++) {
      feeds.add(LiveThreatFeed(
        id: 'feed_$i',
        source: sources[_random.nextInt(sources.length)],
        type: AttackType.values[_random.nextInt(AttackType.values.length)],
        severity: ThreatLevel.values[_random.nextInt(ThreatLevel.values.length)],
        title: titles[_random.nextInt(titles.length)],
        description: 'Threat intelligence feed describing security incident details and indicators of compromise.',
        timestamp: DateTime.now().subtract(Duration(minutes: _random.nextInt(1440))),
        indicators: _generateThreatIndicators(),
        confidence: 0.6 + _random.nextDouble() * 0.4,
        isVerified: _random.nextBool(),
        tags: ['apt', 'malware', 'c2', 'ioc'],
      ));
    }

    return feeds;
  }

  SecurityOperationsMetrics _generateCurrentMetrics() {
    return SecurityOperationsMetrics(
      id: 'metrics_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      totalThreats: 150 + _random.nextInt(50),
      activeThreatHunts: 5 + _random.nextInt(10),
      resolvedIncidents: 45 + _random.nextInt(20),
      pendingAlerts: 12 + _random.nextInt(15),
      meanTimeToDetection: 10.5 + _random.nextDouble() * 10,
      meanTimeToResponse: 25.3 + _random.nextDouble() * 15,
      meanTimeToResolution: 120.7 + _random.nextDouble() * 60,
      threatsByType: {
        AttackType.brute_force: 25,
        AttackType.ddos: 15,
        AttackType.malware: 30,
        AttackType.phishing: 40,
        AttackType.sql_injection: 20,
      },
      threatsBySeverity: {
        ThreatLevel.low: 80,
        ThreatLevel.medium: 60,
        ThreatLevel.high: 25,
        ThreatLevel.critical: 5,
      },
      threatsByRegion: {
        GeographicRegion.north_america: 45,
        GeographicRegion.europe: 35,
        GeographicRegion.asia_pacific: 55,
        GeographicRegion.middle_east: 15,
      },
      systemAvailability: 99.2 + _random.nextDouble() * 0.8,
      securityEffectiveness: 85.5 + _random.nextDouble() * 10,
    );
  }

  // Utility methods
  String _generateRandomIP() {
    return '${_random.nextInt(256)}.${_random.nextInt(256)}.${_random.nextInt(256)}.${_random.nextInt(256)}';
  }

  List<String> _getRandomImprovementAreas() {
    final areas = [
      'Multi-factor authentication adoption',
      'Patch management process',
      'Employee security training',
      'Network segmentation',
      'Incident response procedures',
    ];
    areas.shuffle();
    return areas.take(2 + _random.nextInt(2)).toList();
  }

  List<String> _getRandomRiskFactors() {
    final factors = [
      'Unpatched systems',
      'Weak password policies',
      'Insufficient monitoring',
      'Third-party integrations',
      'Remote work security gaps',
    ];
    factors.shuffle();
    return factors.take(1 + _random.nextInt(3)).toList();
  }

  List<String> _generateThreatIndicators() {
    final indicators = [
      _generateRandomIP(),
      'malware.exe',
      'suspicious-domain.com',
      'SHA256:${_generateRandomHash()}',
    ];
    return indicators.take(2 + _random.nextInt(2)).toList();
  }

  String _generateRandomHash() {
    const chars = '0123456789abcdef';
    return List.generate(64, (index) => chars[_random.nextInt(chars.length)]).join();
  }

  ThreatLocation _generateRandomThreatLocation() {
    final cities = [
      {'name': 'Berlin', 'lat': 52.5200, 'lng': 13.4050, 'country': 'Germany', 'region': GeographicRegion.europe},
      {'name': 'Sydney', 'lat': -33.8688, 'lng': 151.2093, 'country': 'Australia', 'region': GeographicRegion.oceania},
      {'name': 'Toronto', 'lat': 43.6532, 'lng': -79.3832, 'country': 'Canada', 'region': GeographicRegion.north_america},
    ];
    
    final city = cities[_random.nextInt(cities.length)];
    return ThreatLocation(
      id: 'threat_${DateTime.now().millisecondsSinceEpoch}',
      latitude: city['lat'] as double,
      longitude: city['lng'] as double,
      country: city['country'] as String,
      city: city['name'] as String,
      region: city['region'] as GeographicRegion,
      attackType: AttackType.values[_random.nextInt(AttackType.values.length)],
      threatLevel: ThreatLevel.values[_random.nextInt(ThreatLevel.values.length)],
      threatCount: 1 + _random.nextInt(5),
      timestamp: DateTime.now(),
      ipAddress: _generateRandomIP(),
      detectedAt: DateTime.now(),
      attackCount: 1 + _random.nextInt(5),
      isBlocked: _random.nextBool(),
    );
  }

  SecurityScoreTrend _generateSecurityTrend() {
    final currentScore = 80 + _random.nextDouble() * 20;
    final previousScore = currentScore + (-5 + _random.nextDouble() * 10);
    
    return SecurityScoreTrend(
      id: 'trend_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      overallScore: currentScore,
      previousScore: previousScore,
      changePercent: ((currentScore - previousScore) / previousScore) * 100,
      categoryScores: {
        'Authentication': 80 + _random.nextDouble() * 20,
        'Authorization': 75 + _random.nextDouble() * 25,
        'Data Protection': 85 + _random.nextDouble() * 15,
        'Network Security': 70 + _random.nextDouble() * 30,
        'Compliance': 90 + _random.nextDouble() * 10,
      },
      improvementAreas: _getRandomImprovementAreas(),
      riskFactors: _getRandomRiskFactors(),
      predictedScore: currentScore + (-3 + _random.nextDouble() * 6),
      predictionDate: DateTime.now().add(const Duration(hours: 24)),
      scores: [],
    );
  }

  LiveThreatFeed _generateRandomThreatFeed() {
    final sources = ['VirusTotal', 'AbuseIPDB', 'MISP', 'Shodan'];
    final titles = [
      'New Malware Variant Detected',
      'Suspicious Network Activity',
      'Credential Stuffing Attack',
      'DDoS Botnet Activity',
    ];
    
    return LiveThreatFeed(
      id: 'feed_${DateTime.now().millisecondsSinceEpoch}',
      source: sources[_random.nextInt(sources.length)],
      type: AttackType.values[_random.nextInt(AttackType.values.length)],
      severity: ThreatLevel.values[_random.nextInt(ThreatLevel.values.length)],
      title: titles[_random.nextInt(titles.length)],
      description: 'Real-time threat intelligence update with actionable indicators.',
      timestamp: DateTime.now(),
      indicators: _generateThreatIndicators(),
      confidence: 0.7 + _random.nextDouble() * 0.3,
      isVerified: _random.nextBool(),
      tags: ['realtime', 'threat', 'intelligence'],
    );
  }

  void _updateExecutiveKPIs() {
    for (int i = 0; i < _executiveKPIs.length; i++) {
      final kpi = _executiveKPIs[i];
      final newValue = kpi.currentValue + (-2 + _random.nextDouble() * 4);
      
      _executiveKPIs[i] = ExecutiveKPI(
        id: kpi.id,
        name: kpi.name,
        description: kpi.description,
        currentValue: newValue,
        target: kpi.target,
        previousValue: kpi.currentValue,
        unit: kpi.unit,
        category: kpi.category,
        status: newValue > kpi.target ? ThreatLevel.low : (newValue < kpi.previousValue ? ThreatLevel.high : ThreatLevel.medium),
        lastUpdated: DateTime.now(),
        trendData: [...kpi.trendData.skip(1), newValue],
        breakdown: kpi.breakdown,
      );
    }
  }

  // Public API methods
  Future<List<ThreatLocation>> getThreatLocations({ThreatLevel? severity}) async {
    await initialize();
    if (severity != null) {
      return _threatLocations.where((t) => t.threatLevel == severity).toList();
    }
    return List.from(_threatLocations);
  }

  Future<List<SecurityScoreTrend>> getSecurityTrends({int? limit}) async {
    await initialize();
    final trends = List<SecurityScoreTrend>.from(_securityTrends);
    if (limit != null && trends.length > limit) {
      return trends.take(limit).toList();
    }
    return trends;
  }

  Future<SecurityOperationsMetrics?> getCurrentMetrics() async {
    await initialize();
    return _currentMetrics;
  }

  Future<List<ExecutiveKPI>> getExecutiveKPIs() async {
    await initialize();
    return List.from(_executiveKPIs);
  }

  Future<List<LiveThreatFeed>> getThreatFeeds({int? limit}) async {
    await initialize();
    final feeds = List<LiveThreatFeed>.from(_threatFeeds);
    if (limit != null && feeds.length > limit) {
      return feeds.take(limit).toList();
    }
    return feeds;
  }

  Future<List<ThreatHunterQuery>> getHuntQueries() async {
    await initialize();
    return List.from(_huntQueries);
  }

  Future<ThreatHuntResult> executeHuntQuery(String queryId) async {
    await initialize();
    
    final query = _huntQueries.firstWhere((q) => q.id == queryId);
    
    // Simulate query execution
    await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(2000)));
    
    final result = ThreatHuntResult(
      id: 'result_${DateTime.now().millisecondsSinceEpoch}',
      queryId: queryId,
      title: 'Hunt Query Result',
      description: 'Results from threat hunting query execution',
      severity: ThreatLevel.medium,
      indicators: ['indicator1', 'indicator2'],
      metadata: {'query_type': 'custom'},
      timestamp: DateTime.now(),
      executedAt: DateTime.now(),
      executionTime: Duration(milliseconds: 500 + _random.nextInt(2000)),
      resultCount: _random.nextInt(100),
      results: _generateMockQueryResults(),
      isSuccessful: _random.nextDouble() > 0.1, // 90% success rate
      statistics: {
        'events_searched': 1000000 + _random.nextInt(5000000),
        'time_range': '24h',
        'data_sources': query.dataSource.length,
      },
    );
    
    _huntResults.add(result);
    
    // Update query execution count
    final queryIndex = _huntQueries.indexWhere((q) => q.id == queryId);
    if (queryIndex != -1) {
      _huntQueries[queryIndex] = ThreatHunterQuery(
        id: query.id,
        name: query.name,
        description: query.description,
        query: query.query,
        queryLanguage: query.queryLanguage,
        dataSource: query.dataSource,
        createdAt: query.createdAt,
        createdBy: query.createdBy,
        lastExecuted: DateTime.now(),
        executionCount: query.executionCount + 1,
        parameters: query.parameters,
        tags: query.tags,
        isSaved: query.isSaved,
        isScheduled: query.isScheduled,
        schedule: query.schedule,
      );
    }
    
    return result;
  }

  List<Map<String, dynamic>> _generateMockQueryResults() {
    final results = <Map<String, dynamic>>[];
    final count = _random.nextInt(20);
    
    for (int i = 0; i < count; i++) {
      results.add({
        'timestamp': DateTime.now().subtract(Duration(minutes: _random.nextInt(1440))).toIso8601String(),
        'src_ip': _generateRandomIP(),
        'event_type': ['login', 'logout', 'failed_auth', 'data_access'][_random.nextInt(4)],
        'user': 'user_${_random.nextInt(1000)}',
        'severity': ThreatLevel.values[_random.nextInt(ThreatLevel.values.length)].name,
      });
    }
    
    return results;
  }

  Future<void> blockThreatLocation(String threatId) async {
    final index = _threatLocations.indexWhere((t) => t.id == threatId);
    if (index != -1) {
      final threat = _threatLocations[index];
      _threatLocations[index] = ThreatLocation(
        id: threat.id,
        latitude: threat.latitude,
        longitude: threat.longitude,
        country: threat.country,
        city: threat.city,
        region: threat.region,
        attackType: threat.attackType,
        threatLevel: threat.threatLevel,
        threatCount: threat.threatCount,
        timestamp: threat.timestamp,
        ipAddress: threat.ipAddress,
        detectedAt: threat.detectedAt,
        attackCount: threat.attackCount,
        isBlocked: true,
        metadata: threat.metadata,
      );
      
      _threatLocationsController.add(List.from(_threatLocations));
    }
  }

  void dispose() {
    _threatMapTimer?.cancel();
    _metricsTimer?.cancel();
    _feedTimer?.cancel();
    
    _threatLocationsController.close();
    _securityTrendController.close();
    _metricsController.close();
    _threatFeedController.close();
    _kpiController.close();
  }
}
