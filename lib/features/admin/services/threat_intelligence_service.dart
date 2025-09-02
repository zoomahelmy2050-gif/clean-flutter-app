import 'dart:async';
import 'dart:math';
import '../../../core/models/threat_models.dart';
import '../../../core/services/external_threat_intelligence_service.dart' as ext_threat;
import '../../../locator.dart';
import 'dart:developer' as developer;

class ThreatIntelligenceService {
  static const String _abuseIPDBKey = 'YOUR_ABUSEIPDB_API_KEY';
  static const String _virusTotalKey = 'YOUR_VIRUSTOTAL_API_KEY';
  
  final List<ThreatFeed> _threatFeeds = [];
  final List<IPReputationResult> _ipChecks = [];
  final List<GeolocationAnomaly> _geoAnomalies = [];
  final List<ThreatAlert> _activeAlerts = [];
  final Map<String, UserRiskProfile> _userRiskProfiles = {};
  
  Timer? _feedUpdateTimer;
  
  ThreatIntelligenceService() {
    _initializeMockData();
    _startThreatFeedUpdates();
    _initializeProductionIntegration();
  }

  void _initializeProductionIntegration() {
    try {
      final ext_threat.ExternalThreatIntelligenceService _externalService = locator<ext_threat.ExternalThreatIntelligenceService>();
      
      // Subscribe to external threat intelligence feeds
      _externalService.threatReportsStream.listen((feed) {
        _threatFeeds.insert(0, ThreatFeed(
          id: feed.id,
          title: feed.name, // Use name from report
          description: feed.description,
          severity: ThreatSeverity.medium, // No severity in report, using default
          source: feed.source,
          timestamp: feed.created, // Use created from report
          metadata: {
            'author': feed.author,
            'tags': feed.tags,
            'tlp': feed.tlp,
          },
        ));
        
        if (_threatFeeds.length > 100) {
          _threatFeeds.removeRange(100, _threatFeeds.length);
        }
      });
      
      developer.log('Connected to external threat intelligence service', name: 'ThreatIntelligenceService');
    } catch (e) {
      developer.log('Failed to connect to external threat intelligence: $e', name: 'ThreatIntelligenceService');
    }
  }

  void _initializeMockData() {
    // Mock threat feeds
    _threatFeeds.addAll([
      ThreatFeed(
        id: '1',
        title: 'New Botnet C2 Infrastructure Detected',
        description: 'Multiple IP addresses identified as part of a new botnet command and control infrastructure',
        severity: ThreatSeverity.critical,
        source: 'CyberThreat Intelligence',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        metadata: {'ips': ['192.168.1.100', '10.0.0.50'], 'botnet': 'Mirai-variant'},
      ),
      ThreatFeed(
        id: '2',
        title: 'Credential Stuffing Campaign Active',
        description: 'Large-scale credential stuffing attacks targeting multiple platforms',
        severity: ThreatSeverity.high,
        source: 'Security Operations Center',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        metadata: {'targets': ['login portals', 'banking'], 'volume': 'high'},
      ),
      ThreatFeed(
        id: '3',
        title: 'Phishing Campaign Using COVID-19 Themes',
        description: 'New phishing emails leveraging COVID-19 health information themes',
        severity: ThreatSeverity.medium,
        source: 'Anti-Phishing Working Group',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        metadata: {'theme': 'covid-19', 'vector': 'email'},
      ),
    ]);

    // Mock IP reputation results
    _ipChecks.addAll([
      IPReputationResult(
        ipAddress: '192.168.1.100',
        reputation: IPReputation.malicious,
        country: 'Russia',
        provider: 'Unknown ISP',
        isBlocked: true,
        checkedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        threatCategories: ['botnet', 'malware'],
        riskScore: 95.0,
      ),
      IPReputationResult(
        ipAddress: '203.0.113.45',
        reputation: IPReputation.suspicious,
        country: 'China',
        provider: 'China Telecom',
        isBlocked: false,
        checkedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        threatCategories: ['scanning'],
        riskScore: 65.0,
      ),
      IPReputationResult(
        ipAddress: '8.8.8.8',
        reputation: IPReputation.clean,
        country: 'United States',
        provider: 'Google LLC',
        isBlocked: false,
        checkedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        threatCategories: [],
        riskScore: 5.0,
      ),
    ]);

    // Mock geolocation anomalies
    _geoAnomalies.addAll([
      GeolocationAnomaly(
        id: '1',
        userEmail: 'user@example.com',
        location: 'Moscow, Russia',
        latitude: 55.7558,
        longitude: 37.6176,
        distanceFromUsual: 8500.0,
        riskLevel: RiskLevel.critical,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        ipAddress: '192.168.1.100',
        isBlocked: true,
      ),
      GeolocationAnomaly(
        id: '2',
        userEmail: 'admin@company.com',
        location: 'Beijing, China',
        latitude: 39.9042,
        longitude: 116.4074,
        distanceFromUsual: 12000.0,
        riskLevel: RiskLevel.high,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ipAddress: '203.0.113.45',
        isBlocked: false,
      ),
    ]);

    // Mock active alerts
    _activeAlerts.addAll([
      ThreatAlert(
        id: '1',
        title: 'Multiple Failed Login Attempts',
        description: 'User account has 15 failed login attempts in the last 10 minutes',
        severity: AlertSeverity.high,
        type: AlertType.bruteForce,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        userEmail: 'user@example.com',
        ipAddress: '192.168.1.100',
        isAcknowledged: false,
        metadata: {'attempts': 15, 'timeWindow': '10min'},
      ),
      ThreatAlert(
        id: '2',
        title: 'Suspicious Login from New Location',
        description: 'Login detected from unusual geographic location',
        severity: AlertSeverity.medium,
        type: AlertType.suspiciousLogin,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        userEmail: 'admin@company.com',
        ipAddress: '203.0.113.45',
        isAcknowledged: false,
        metadata: {'location': 'Beijing, China', 'distance': '12000km'},
      ),
    ]);

    // Mock user risk profiles
    _userRiskProfiles['user@example.com'] = UserRiskProfile(
      userEmail: 'user@example.com',
      riskScore: 85.0,
      riskLevel: RiskLevel.high,
      lastUpdated: DateTime.now(),
      riskFactors: [
        RiskFactor(
          type: 'Geographic Anomaly',
          description: 'Login from unusual location (Moscow)',
          impact: 40.0,
          detectedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
        RiskFactor(
          type: 'Brute Force Attack',
          description: 'Multiple failed login attempts',
          impact: 45.0,
          detectedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ],
      scoreHistory: [
        RiskScoreHistory(
          timestamp: DateTime.now().subtract(const Duration(hours: 24)),
          score: 25.0,
          reason: 'Baseline score',
        ),
        RiskScoreHistory(
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          score: 65.0,
          reason: 'Geographic anomaly detected',
        ),
        RiskScoreHistory(
          timestamp: DateTime.now(),
          score: 85.0,
          reason: 'Brute force attack detected',
        ),
      ],
    );
  }

  void _startThreatFeedUpdates() {
    _feedUpdateTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _updateThreatFeeds();
    });
  }

  void _updateThreatFeeds() {
    // Simulate new threat feeds
    final random = Random();
    if (random.nextBool()) {
      final newThreat = ThreatFeed(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _generateRandomThreatTitle(),
        description: _generateRandomThreatDescription(),
        severity: ThreatSeverity.values[random.nextInt(ThreatSeverity.values.length)],
        source: _getRandomSource(),
        timestamp: DateTime.now(),
        metadata: {'auto_generated': true},
      );
      
      _threatFeeds.insert(0, newThreat);
      
      // Keep only last 100 feeds
      if (_threatFeeds.length > 100) {
        _threatFeeds.removeRange(100, _threatFeeds.length);
      }
      
      developer.log('New threat feed added: ${newThreat.title}', name: 'ThreatIntelligence');
    }
  }

  String _generateRandomThreatTitle() {
    final titles = [
      'New Malware Variant Detected',
      'DDoS Attack Infrastructure Identified',
      'Phishing Campaign Targeting Financial Sector',
      'Zero-Day Exploit in Popular Software',
      'Ransomware Group Launches New Campaign',
      'APT Group Activity Detected',
      'Cryptocurrency Mining Botnet Discovered',
      'Supply Chain Attack Vector Identified',
    ];
    return titles[Random().nextInt(titles.length)];
  }

  String _generateRandomThreatDescription() {
    final descriptions = [
      'Security researchers have identified a new threat targeting enterprise networks',
      'Multiple indicators of compromise have been detected across various platforms',
      'Threat actors are leveraging new techniques to evade detection',
      'Critical vulnerability being actively exploited in the wild',
      'Large-scale campaign affecting multiple organizations globally',
    ];
    return descriptions[Random().nextInt(descriptions.length)];
  }

  String _getRandomSource() {
    final sources = [
      'CyberThreat Intelligence',
      'Security Operations Center',
      'Anti-Malware Research',
      'Incident Response Team',
      'Threat Hunting Unit',
    ];
    return sources[Random().nextInt(sources.length)];
  }

  // Public API methods
  Future<List<ThreatFeed>> getLatestThreatFeeds({int limit = 50}) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API delay
    return _threatFeeds.take(limit).toList();
  }

  Future<List<IPReputationResult>> getRecentIPChecks({int limit = 50}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _ipChecks.take(limit).toList();
  }

  Future<List<GeolocationAnomaly>> getGeolocationAnomalies({int limit = 50}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _geoAnomalies.take(limit).toList();
  }

  Future<List<ThreatAlert>> getActiveAlerts() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _activeAlerts.where((alert) => !alert.isAcknowledged).toList();
  }

  Future<IPReputationResult> checkIPReputation(String ipAddress) async {
    developer.log('Checking IP reputation for: $ipAddress', name: 'ThreatIntelligence');
    
    // Check if we already have this IP
    final existing = _ipChecks.where((check) => check.ipAddress == ipAddress).firstOrNull;
    if (existing != null && 
        DateTime.now().difference(existing.checkedAt).inMinutes < 60) {
      return existing;
    }

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Mock reputation check
    final result = _mockIPReputationCheck(ipAddress);
    _ipChecks.insert(0, result);
    
    // Keep only last 1000 checks
    if (_ipChecks.length > 1000) {
      _ipChecks.removeRange(1000, _ipChecks.length);
    }
    
    return result;
  }

  IPReputationResult _mockIPReputationCheck(String ipAddress) {
    final random = Random();
    
    // Some known bad IPs for demo
    final knownBadIPs = ['192.168.1.100', '10.0.0.50', '203.0.113.45'];
    final isKnownBad = knownBadIPs.contains(ipAddress);
    
    IPReputation reputation;
    List<String> categories = [];
    double riskScore;
    
    if (isKnownBad) {
      reputation = IPReputation.malicious;
      categories = ['botnet', 'malware'];
      riskScore = 90.0 + random.nextDouble() * 10;
    } else if (ipAddress.startsWith('192.168.') || ipAddress.startsWith('10.')) {
      reputation = IPReputation.clean;
      categories = [];
      riskScore = random.nextDouble() * 20;
    } else {
      final rand = random.nextDouble();
      if (rand < 0.1) {
        reputation = IPReputation.malicious;
        categories = ['scanning', 'malware'];
        riskScore = 80.0 + random.nextDouble() * 20;
      } else if (rand < 0.3) {
        reputation = IPReputation.suspicious;
        categories = ['scanning'];
        riskScore = 40.0 + random.nextDouble() * 40;
      } else {
        reputation = IPReputation.clean;
        categories = [];
        riskScore = random.nextDouble() * 30;
      }
    }
    
    final countries = ['United States', 'China', 'Russia', 'Germany', 'Japan', 'Brazil'];
    final providers = ['Google LLC', 'Amazon', 'Cloudflare', 'China Telecom', 'Unknown ISP'];
    
    return IPReputationResult(
      ipAddress: ipAddress,
      reputation: reputation,
      country: countries[random.nextInt(countries.length)],
      provider: providers[random.nextInt(providers.length)],
      isBlocked: reputation == IPReputation.malicious,
      riskScore: reputation == IPReputation.malicious ? 95.0 : 
                 reputation == IPReputation.suspicious ? 65.0 : 15.0,
      checkedAt: DateTime.now(),
    );
  }

  Future<UserRiskProfile> getUserRiskProfile(String userEmail) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return _userRiskProfiles[userEmail] ?? UserRiskProfile(
      userEmail: userEmail,
      riskScore: 25.0,
      riskLevel: RiskLevel.low,
      lastUpdated: DateTime.now(),
      riskFactors: [],
      scoreHistory: [
        RiskScoreHistory(
          timestamp: DateTime.now(),
          score: 25.0,
          reason: 'Baseline score',
        ),
      ],
    );
  }

  Future<void> updateUserRiskScore(String userEmail, double newScore, String reason) async {
    final profile = await getUserRiskProfile(userEmail);
    
    final newRiskLevel = calculateRiskLevel(newScore);
    final updatedProfile = UserRiskProfile(
      userEmail: userEmail,
      riskScore: newScore,
      riskLevel: newRiskLevel,
      lastUpdated: DateTime.now(),
      riskFactors: profile.riskFactors,
      scoreHistory: [
        ...profile.scoreHistory,
        RiskScoreHistory(
          timestamp: DateTime.now(),
          score: newScore,
          reason: reason,
        ),
      ],
    );
    
    _userRiskProfiles[userEmail] = updatedProfile;
    
    // Generate alert if risk level is high
    if (newRiskLevel == RiskLevel.high || newRiskLevel == RiskLevel.critical) {
      generateRiskAlert(userEmail, newScore, reason);
    }
  }

  // Helper methods
  RiskLevel calculateRiskLevel(double score) {
    if (score >= 80) return RiskLevel.critical;
    if (score >= 60) return RiskLevel.high;
    if (score >= 40) return RiskLevel.medium;
    return RiskLevel.low;
  }

  void generateRiskAlert(String userEmail, double score, String reason) {
    final alert = ThreatAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'High Risk User Detected',
      description: 'User $userEmail has elevated risk score: ${score.toStringAsFixed(1)}',
      severity: score >= 80 ? AlertSeverity.critical : AlertSeverity.high,
      type: AlertType.anomalousActivity,
      timestamp: DateTime.now(),
      userEmail: userEmail,
      ipAddress: null,
      isAcknowledged: false,
      metadata: {'riskScore': score, 'reason': reason},
    );
    
    _activeAlerts.insert(0, alert);
  }

  List<Map<String, double>> _getUserUsualLocations(String userEmail) {
    // Mock usual locations - in real implementation, this would come from database
    return [
      {'lat': 40.7128, 'lng': -74.0060}, // New York
      {'lat': 37.7749, 'lng': -122.4194}, // San Francisco
    ];
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  RiskLevel _calculateGeoRiskLevel(double distance) {
    if (distance > 5000) return RiskLevel.critical;
    if (distance > 2000) return RiskLevel.high;
    if (distance > 1000) return RiskLevel.medium;
    return RiskLevel.low;
  }

  String _getLocationName(double latitude, double longitude) {
    // Mock location names - in real implementation, use reverse geocoding
    final cities = [
      'New York, USA',
      'London, UK', 
      'Tokyo, Japan',
      'Moscow, Russia',
      'Beijing, China',
      'Sydney, Australia',
    ];
    return cities[Random().nextInt(cities.length)];
  }

  Future<void> acknowledgeAlert(String alertId) async {
    final alertIndex = _activeAlerts.indexWhere((alert) => alert.id == alertId);
    if (alertIndex != -1) {
      final alert = _activeAlerts[alertIndex];
      final updatedAlert = ThreatAlert(
        id: alert.id,
        title: alert.title,
        description: alert.description,
        severity: alert.severity,
        type: alert.type,
        timestamp: alert.timestamp,
        userEmail: alert.userEmail,
        ipAddress: alert.ipAddress,
        isAcknowledged: true,
        metadata: alert.metadata,
      );
      _activeAlerts[alertIndex] = updatedAlert;
    }
  }

  Future<void> blockIP(String ipAddress) async {
    developer.log('Blocking IP: $ipAddress', name: 'ThreatIntelligence');
    
    // Update existing IP check if exists
    final checkIndex = _ipChecks.indexWhere((check) => check.ipAddress == ipAddress);
    if (checkIndex != -1) {
      final check = _ipChecks[checkIndex];
      final updatedCheck = IPReputationResult(
        ipAddress: check.ipAddress,
        reputation: IPReputation.malicious,
        country: check.country,
        provider: check.provider,
        isBlocked: true,
        checkedAt: DateTime.now(),
        threatCategories: check.threatCategories,
        riskScore: 100.0,
      );
      _ipChecks[checkIndex] = updatedCheck;
    }
    
    // Generate blocking alert
    final alert = ThreatAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'IP Address Blocked',
      description: 'IP address $ipAddress has been blocked due to malicious activity',
      severity: AlertSeverity.high,
      type: AlertType.anomalousActivity,
      timestamp: DateTime.now(),
      userEmail: null,
      ipAddress: ipAddress,
      isAcknowledged: false,
      metadata: {'action': 'blocked', 'automatic': false},
    );
    
    _activeAlerts.insert(0, alert);
  }

  Future<void> analyzeGeolocation(String userEmail, String ipAddress, 
      double latitude, double longitude) async {
    
    // Get user's usual locations (mock data)
    final usualLocations = _getUserUsualLocations(userEmail);
    
    if (usualLocations.isEmpty) {
      // First login, establish baseline
      return;
    }
    
    // Calculate distance from usual locations
    double minDistance = double.infinity;
    for (final location in usualLocations) {
      final distance = _calculateDistance(
        latitude, longitude, 
        location['lat']!, location['lng']!
      );
      if (distance < minDistance) {
        minDistance = distance;
      }
    }
    
    // Generate anomaly if distance is significant
    if (minDistance > 500) { // 500km threshold
      final riskLevel = _calculateGeoRiskLevel(minDistance);
      
      final anomaly = GeolocationAnomaly(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userEmail: userEmail,
        location: _getLocationName(latitude, longitude),
        latitude: latitude,
        longitude: longitude,
        distanceFromUsual: minDistance,
        riskLevel: riskLevel,
        timestamp: DateTime.now(),
        ipAddress: ipAddress,
        isBlocked: riskLevel == RiskLevel.critical,
      );
      
      _geoAnomalies.insert(0, anomaly);
      
      // Generate alert for high-risk anomalies
      if (riskLevel == RiskLevel.high || riskLevel == RiskLevel.critical) {
        final alert = ThreatAlert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Geolocation Anomaly Detected',
          description: 'User $userEmail logged in from unusual location: ${_getLocationName(latitude, longitude)}',
          severity: riskLevel == RiskLevel.critical ? AlertSeverity.critical : AlertSeverity.high,
          type: AlertType.anomalousActivity,
          timestamp: DateTime.now(),
          userEmail: userEmail,
          ipAddress: ipAddress,
          isAcknowledged: false,
          metadata: {
            'distance': minDistance,
            'latitude': latitude,
            'longitude': longitude,
          },
        );
        
        _activeAlerts.insert(0, alert);
      }
    }
  }

  void dispose() {
    _feedUpdateTimer?.cancel();
  }
}
