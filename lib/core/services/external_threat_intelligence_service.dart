import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ExternalThreatIntelligenceService extends ChangeNotifier {
  static ExternalThreatIntelligenceService? _instance;
  static ExternalThreatIntelligenceService get instance => _instance ??= ExternalThreatIntelligenceService._();
  ExternalThreatIntelligenceService._();

  final Dio _dio = Dio();
  Timer? _feedUpdateTimer;
  bool _isInitialized = false;

  // API Keys loaded from environment variables
  late String _virusTotalApiKey;
  late String _alienVaultApiKey;
  late String _shodanApiKey;
  late String _abuseIPDBApiKey;
  late String _xForceApiKey;
  late String _xForcePassword;

  // API Endpoints
  static const String virusTotalBaseUrl = 'https://www.virustotal.com/vtapi/v2';
  static const String alienVaultBaseUrl = 'https://otx.alienvault.com/api/v1';
  static const String shodanBaseUrl = 'https://api.shodan.io';
  static const String abuseIPDBBaseUrl = 'https://api.abuseipdb.com/api/v2';

  // Stream controllers
  final StreamController<ThreatIntelligenceReport> _threatReportsController = StreamController.broadcast();
  final StreamController<IPReputationResult> _ipReputationController = StreamController.broadcast();
  final StreamController<MalwareAnalysisResult> _malwareAnalysisController = StreamController.broadcast();
  final StreamController<VulnerabilityAlert> _vulnerabilityAlertsController = StreamController.broadcast();

  // Public streams
  Stream<ThreatIntelligenceReport> get threatReportsStream => _threatReportsController.stream;
  Stream<IPReputationResult> get ipReputationStream => _ipReputationController.stream;
  Stream<MalwareAnalysisResult> get malwareAnalysisStream => _malwareAnalysisController.stream;
  Stream<VulnerabilityAlert> get vulnerabilityAlertsStream => _vulnerabilityAlertsController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load API keys from environment with null safety
      _virusTotalApiKey = dotenv.env['VIRUSTOTAL_API_KEY'] ?? '';
      _alienVaultApiKey = dotenv.env['ALIENVAULT_API_KEY'] ?? '';
      _shodanApiKey = dotenv.env['SHODAN_API_KEY'] ?? '';
      _abuseIPDBApiKey = dotenv.env['ABUSEIPDB_API_KEY'] ?? '';
      _xForceApiKey = dotenv.env['XFORCE_API_KEY'] ?? '';
      _xForcePassword = dotenv.env['XFORCE_PASSWORD'] ?? '';

      _dio.options.connectTimeout = const Duration(seconds: 30);
      _dio.options.receiveTimeout = const Duration(seconds: 30);

      if (_hasValidApiKeys()) {
        _startThreatFeedUpdates();
        developer.log('External threat intelligence service initialized with real APIs');
      } else {
        developer.log('External threat intelligence service initialized in mock mode - no API keys found');
      }
    } catch (e) {
      developer.log('Error initializing External Threat Intelligence Service: $e');
      // Initialize with empty keys to enable mock mode
      _virusTotalApiKey = '';
      _alienVaultApiKey = '';
      _shodanApiKey = '';
      _abuseIPDBApiKey = '';
      _xForceApiKey = '';
      _xForcePassword = '';
      developer.log('Falling back to mock mode due to initialization error');
    }
    
    _isInitialized = true;
  }

  void _startThreatFeedUpdates() {
    _feedUpdateTimer?.cancel();
    _feedUpdateTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      _updateThreatFeeds();
    });
    
    // Initial update
    _updateThreatFeeds();
  }

  Future<void> _updateThreatFeeds() async {
    try {
      // Update from multiple threat intelligence sources
      await Future.wait([
        _updateAlienVaultPulses(),
        _updateVirusTotalFeeds(),
        _updateShodanAlerts(),
      ]);
    } catch (e) {
      developer.log('Error updating threat feeds: $e');
    }
  }

  // VirusTotal Integration
  Future<MalwareAnalysisResult> analyzeFileHash(String fileHash) async {
    try {
      final response = await _dio.get(
        '$virusTotalBaseUrl/file/report',
        queryParameters: {
          'apikey': _virusTotalApiKey,
          'resource': fileHash,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final result = MalwareAnalysisResult(
          fileHash: fileHash,
          detectionRatio: '${data['positives']}/${data['total']}',
          scanDate: DateTime.parse(data['scan_date']),
          permalink: data['permalink'],
          scans: Map<String, dynamic>.from(data['scans'] ?? {}),
          isMalicious: (data['positives'] as int) > 0,
          threatNames: _extractThreatNames(data['scans']),
        );

        _malwareAnalysisController.add(result);
        return result;
      }
    } catch (e) {
      developer.log('VirusTotal analysis error: $e');
    }

    return MalwareAnalysisResult(
      fileHash: fileHash,
      detectionRatio: '0/0',
      scanDate: DateTime.now(),
      permalink: '',
      scans: {},
      isMalicious: false,
      threatNames: [],
    );
  }

  Future<IPReputationResult> checkIPReputation(String ipAddress) async {
    try {
      // Check multiple sources for IP reputation
      final results = await Future.wait([
        _checkVirusTotalIP(ipAddress),
        _checkAbuseIPDB(ipAddress),
        _checkShodanIP(ipAddress),
      ]);

      final combinedResult = _combineIPReputationResults(ipAddress, results);
      _ipReputationController.add(combinedResult);
      return combinedResult;
    } catch (e) {
      developer.log('IP reputation check error: $e');
      return IPReputationResult(
        ipAddress: ipAddress,
        isMalicious: false,
        riskScore: 0,
        sources: [],
        lastSeen: DateTime.now(),
        threatTypes: [],
        geolocation: {},
      );
    }
  }

  Future<Map<String, dynamic>> _checkVirusTotalIP(String ipAddress) async {
    try {
      final response = await _dio.get(
        '$virusTotalBaseUrl/ip-address/report',
        queryParameters: {
          'apikey': _virusTotalApiKey,
          'ip': ipAddress,
        },
      );

      if (response.statusCode == 200) {
        return {
          'source': 'VirusTotal',
          'malicious': response.data['detected_urls']?.isNotEmpty ?? false,
          'detections': response.data['detected_urls']?.length ?? 0,
          'country': response.data['country'],
        };
      }
    } catch (e) {
      developer.log('VirusTotal IP check error: $e');
    }
    return {'source': 'VirusTotal', 'malicious': false, 'detections': 0};
  }

  Future<Map<String, dynamic>> _checkAbuseIPDB(String ipAddress) async {
    try {
      final response = await _dio.get(
        '$abuseIPDBBaseUrl/check',
        queryParameters: {
          'ipAddress': ipAddress,
          'maxAgeInDays': 90,
          'verbose': '',
        },
        options: Options(
          headers: {
            'Key': _abuseIPDBApiKey,
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        return {
          'source': 'AbuseIPDB',
          'malicious': data['abuseConfidencePercentage'] > 25,
          'confidence': data['abuseConfidencePercentage'],
          'usage_type': data['usageType'],
          'country': data['countryCode'],
        };
      }
    } catch (e) {
      developer.log('AbuseIPDB check error: $e');
    }
    return {'source': 'AbuseIPDB', 'malicious': false, 'confidence': 0};
  }

  Future<Map<String, dynamic>> _checkShodanIP(String ipAddress) async {
    try {
      final response = await _dio.get(
        '$shodanBaseUrl/host/$ipAddress',
        queryParameters: {
          'key': _shodanApiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'source': 'Shodan',
          'malicious': data['vulns']?.isNotEmpty ?? false,
          'open_ports': data['ports'] ?? [],
          'vulns': data['vulns'] ?? [],
          'country': data['country_name'],
          'org': data['org'],
        };
      }
    } catch (e) {
      developer.log('Shodan IP check error: $e');
    }
    return {'source': 'Shodan', 'malicious': false, 'open_ports': []};
  }

  // AlienVault OTX Integration
  Future<void> _updateAlienVaultPulses() async {
    try {
      final response = await _dio.get(
        '$alienVaultBaseUrl/pulses/subscribed',
        queryParameters: {
          'limit': 50,
        },
        options: Options(
          headers: {
            'X-OTX-API-KEY': _alienVaultApiKey,
          },
        ),
      );

      if (response.statusCode == 200) {
        final pulses = response.data['results'] as List;
        for (final pulse in pulses) {
          final report = ThreatIntelligenceReport(
            id: pulse['id'],
            name: pulse['name'],
            description: pulse['description'],
            author: pulse['author_name'],
            created: DateTime.parse(pulse['created']),
            modified: DateTime.parse(pulse['modified']),
            tags: List<String>.from(pulse['tags']),
            indicators: _extractIndicators(pulse['indicators']),
            tlp: pulse['TLP'],
            source: 'AlienVault OTX',
          );
          _threatReportsController.add(report);
        }
      }
    } catch (e) {
      developer.log('AlienVault pulse update error: $e');
    }
  }

  Future<void> _updateVirusTotalFeeds() async {
    // VirusTotal doesn't have a public feed API, but we can check recent samples
    try {
      // This would require VirusTotal Intelligence API access
      developer.log('VirusTotal feed update - requires Intelligence API');
    } catch (e) {
      developer.log('VirusTotal feed update error: $e');
    }
  }

  Future<void> _updateShodanAlerts() async {
    try {
      final response = await _dio.get(
        '$shodanBaseUrl/shodan/alert/info',
        queryParameters: {
          'key': _shodanApiKey,
        },
      );

      if (response.statusCode == 200) {
        // Process Shodan alerts
        developer.log('Shodan alerts updated');
      }
    } catch (e) {
      developer.log('Shodan alerts update error: $e');
    }
  }

  // Utility methods
  List<String> _extractThreatNames(Map<String, dynamic>? scans) {
    if (scans == null) return [];
    
    final threatNames = <String>[];
    scans.forEach((engine, result) {
      if (result['detected'] == true && result['result'] != null) {
        threatNames.add(result['result']);
      }
    });
    return threatNames;
  }

  List<ThreatIndicator> _extractIndicators(List<dynamic>? indicators) {
    if (indicators == null) return [];
    
    return indicators.map((indicator) => ThreatIndicator(
      type: indicator['type'],
      indicator: indicator['indicator'],
      description: indicator['description'] ?? '',
    )).toList();
  }

  IPReputationResult _combineIPReputationResults(String ipAddress, List<Map<String, dynamic>> results) {
    bool isMalicious = false;
    int totalRiskScore = 0;
    final sources = <String>[];
    final threatTypes = <String>[];
    final geolocation = <String, dynamic>{};

    for (final result in results) {
      sources.add(result['source']);
      if (result['malicious'] == true) {
        isMalicious = true;
        threatTypes.add(result['source']);
      }
      
      if (result['confidence'] != null) {
        totalRiskScore += result['confidence'] as int;
      }
      
      if (result['country'] != null) {
        geolocation['country'] = result['country'];
      }
    }

    return IPReputationResult(
      ipAddress: ipAddress,
      isMalicious: isMalicious,
      riskScore: results.isNotEmpty ? totalRiskScore ~/ results.length : 0,
      sources: sources,
      lastSeen: DateTime.now(),
      threatTypes: threatTypes,
      geolocation: geolocation,
    );
  }

  bool _hasValidApiKeys() {
    return _virusTotalApiKey.isNotEmpty ||
           _alienVaultApiKey.isNotEmpty ||
           _shodanApiKey.isNotEmpty ||
           _abuseIPDBApiKey.isNotEmpty;
  }

  // IBM X-Force Exchange Integration
  Future<Map<String, dynamic>> checkXForceReputation(String indicator, String type) async {
    if (_xForceApiKey.isEmpty || _xForcePassword.isEmpty) {
      return {'source': 'X-Force', 'malicious': false, 'score': 0};
    }

    try {
      final credentials = base64Encode(utf8.encode('$_xForceApiKey:$_xForcePassword'));
      final response = await _dio.get(
        'https://api.xforce.ibmcloud.com/$type/$indicator',
        options: Options(
          headers: {
            'Authorization': 'Basic $credentials',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'source': 'X-Force',
          'malicious': data['result']?['score'] != null && data['result']['score'] > 3,
          'score': data['result']?['score'] ?? 0,
          'categories': data['result']?['cats'] ?? {},
        };
      }
    } catch (e) {
      developer.log('X-Force reputation check error: $e');
    }
    return {'source': 'X-Force', 'malicious': false, 'score': 0};
  }

  // Enhanced threat hunting capabilities
  Future<List<ThreatIntelligenceReport>> searchThreats(String query, {String? category}) async {
    final reports = <ThreatIntelligenceReport>[];
    
    try {
      // Search across multiple threat intelligence sources
      if (_alienVaultApiKey.isNotEmpty) {
        final otxResults = await _searchOTXPulses(query, category);
        reports.addAll(otxResults);
      }
      
      // Add more threat intelligence sources as needed
      
    } catch (e) {
      developer.log('Threat search error: $e');
    }
    
    return reports;
  }

  Future<List<ThreatIntelligenceReport>> _searchOTXPulses(String query, String? category) async {
    try {
      final response = await _dio.get(
        '$alienVaultBaseUrl/pulses/search',
        queryParameters: {
          'q': query,
          if (category != null) 'category': category,
          'limit': 20,
        },
        options: Options(
          headers: {
            'X-OTX-API-KEY': _alienVaultApiKey,
          },
        ),
      );

      if (response.statusCode == 200) {
        final pulses = response.data['results'] as List;
        return pulses.map((pulse) => ThreatIntelligenceReport(
          id: pulse['id'],
          name: pulse['name'],
          description: pulse['description'] ?? '',
          author: pulse['author_name'] ?? 'Unknown',
          created: DateTime.parse(pulse['created']),
          modified: DateTime.parse(pulse['modified']),
          tags: List<String>.from(pulse['tags'] ?? []),
          indicators: _extractIndicators(pulse['indicators']),
          tlp: pulse['TLP'] ?? 'WHITE',
          source: 'AlienVault OTX',
        )).toList();
      }
    } catch (e) {
      developer.log('OTX search error: $e');
    }
    return [];
  }

  @override
  void dispose() {
    _feedUpdateTimer?.cancel();
    _threatReportsController.close();
    _ipReputationController.close();
    _malwareAnalysisController.close();
    _vulnerabilityAlertsController.close();
    super.dispose();
  }
}

// Data models
class ThreatIntelligenceReport {
  final String id;
  final String name;
  final String description;
  final String author;
  final DateTime created;
  final DateTime modified;
  final List<String> tags;
  final List<ThreatIndicator> indicators;
  final String tlp;
  final String source;

  ThreatIntelligenceReport({
    required this.id,
    required this.name,
    required this.description,
    required this.author,
    required this.created,
    required this.modified,
    required this.tags,
    required this.indicators,
    required this.tlp,
    required this.source,
  });
}

class ThreatIndicator {
  final String type;
  final String indicator;
  final String description;

  ThreatIndicator({
    required this.type,
    required this.indicator,
    required this.description,
  });
}

class IPReputationResult {
  final String ipAddress;
  final bool isMalicious;
  final int riskScore;
  final List<String> sources;
  final DateTime lastSeen;
  final List<String> threatTypes;
  final Map<String, dynamic> geolocation;

  IPReputationResult({
    required this.ipAddress,
    required this.isMalicious,
    required this.riskScore,
    required this.sources,
    required this.lastSeen,
    required this.threatTypes,
    required this.geolocation,
  });
}

class MalwareAnalysisResult {
  final String fileHash;
  final String detectionRatio;
  final DateTime scanDate;
  final String permalink;
  final Map<String, dynamic> scans;
  final bool isMalicious;
  final List<String> threatNames;

  MalwareAnalysisResult({
    required this.fileHash,
    required this.detectionRatio,
    required this.scanDate,
    required this.permalink,
    required this.scans,
    required this.isMalicious,
    required this.threatNames,
  });
}

class VulnerabilityAlert {
  final String cveId;
  final String title;
  final String description;
  final double cvssScore;
  final String severity;
  final DateTime publishedDate;
  final List<String> affectedProducts;

  VulnerabilityAlert({
    required this.cveId,
    required this.title,
    required this.description,
    required this.cvssScore,
    required this.severity,
    required this.publishedDate,
    required this.affectedProducts,
  });
}
