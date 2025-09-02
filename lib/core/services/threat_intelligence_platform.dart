import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:developer' as developer;

class ThreatIntelligence {
  final String threatId;
  final String type;
  final String severity;
  final String source;
  final String description;
  final Map<String, dynamic> indicators;
  final List<String> affectedSystems;
  final DateTime discoveredAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> mitigation;

  ThreatIntelligence({
    required this.threatId,
    required this.type,
    required this.severity,
    required this.source,
    required this.description,
    required this.indicators,
    required this.affectedSystems,
    required this.discoveredAt,
    this.expiresAt,
    this.mitigation = const {},
  });

  Map<String, dynamic> toJson() => {
    'threat_id': threatId,
    'type': type,
    'severity': severity,
    'source': source,
    'description': description,
    'indicators': indicators,
    'affected_systems': affectedSystems,
    'discovered_at': discoveredAt.toIso8601String(),
    'expires_at': expiresAt?.toIso8601String(),
    'mitigation': mitigation,
  };
}

class DarkWebIntelligence {
  final String intelligenceId;
  final String category;
  final String content;
  final String source;
  final double confidenceScore;
  final List<String> relatedAssets;
  final DateTime collectedAt;
  final Map<String, dynamic> metadata;

  DarkWebIntelligence({
    required this.intelligenceId,
    required this.category,
    required this.content,
    required this.source,
    required this.confidenceScore,
    required this.relatedAssets,
    required this.collectedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'intelligence_id': intelligenceId,
    'category': category,
    'content': content,
    'source': source,
    'confidence_score': confidenceScore,
    'related_assets': relatedAssets,
    'collected_at': collectedAt.toIso8601String(),
    'metadata': metadata,
  };
}

class ThreatActor {
  final String actorId;
  final String name;
  final List<String> aliases;
  final String motivation;
  final List<String> targetSectors;
  final List<String> techniques;
  final String sophisticationLevel;
  final Map<String, dynamic> attribution;
  final DateTime firstSeen;
  final DateTime lastActivity;

  ThreatActor({
    required this.actorId,
    required this.name,
    required this.aliases,
    required this.motivation,
    required this.targetSectors,
    required this.techniques,
    required this.sophisticationLevel,
    required this.attribution,
    required this.firstSeen,
    required this.lastActivity,
  });

  Map<String, dynamic> toJson() => {
    'actor_id': actorId,
    'name': name,
    'aliases': aliases,
    'motivation': motivation,
    'target_sectors': targetSectors,
    'techniques': techniques,
    'sophistication_level': sophisticationLevel,
    'attribution': attribution,
    'first_seen': firstSeen.toIso8601String(),
    'last_activity': lastActivity.toIso8601String(),
  };
}

class ThreatIntelligencePlatform {
  static final ThreatIntelligencePlatform _instance = ThreatIntelligencePlatform._internal();
  factory ThreatIntelligencePlatform() => _instance;
  ThreatIntelligencePlatform._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  final List<ThreatIntelligence> _threatIntelligence = [];
  final List<DarkWebIntelligence> _darkWebIntelligence = [];
  final List<ThreatActor> _threatActors = [];
  final Map<String, List<String>> _iocDatabase = {};
  final Map<String, dynamic> _threatLandscape = {};
  
  final StreamController<ThreatIntelligence> _threatController = StreamController.broadcast();
  final StreamController<DarkWebIntelligence> _darkWebController = StreamController.broadcast();

  Stream<ThreatIntelligence> get threatStream => _threatController.stream;
  Stream<DarkWebIntelligence> get darkWebStream => _darkWebController.stream;

  Timer? _collectionTimer;
  final Random _random = Random();

  Future<void> initialize() async {
    await _setupThreatActors();
    await _initializeIOCDatabase();
    await _collectInitialIntelligence();
    _startContinuousCollection();
    _isInitialized = true;
    
    developer.log('Threat Intelligence Platform initialized', name: 'ThreatIntelligencePlatform');
  }

  Future<void> _setupThreatActors() async {
    final actors = [
      ThreatActor(
        actorId: 'apt29',
        name: 'APT29 (Cozy Bear)',
        aliases: ['The Dukes', 'CozyDuke', 'Minidiuke'],
        motivation: 'espionage',
        targetSectors: ['government', 'healthcare', 'technology'],
        techniques: ['spear_phishing', 'supply_chain', 'cloud_exploitation'],
        sophisticationLevel: 'advanced',
        attribution: {
          'country': 'Russia',
          'confidence': 'high',
          'organization': 'SVR',
        },
        firstSeen: DateTime.now().subtract(const Duration(days: 2000)),
        lastActivity: DateTime.now().subtract(const Duration(days: 30)),
      ),
      ThreatActor(
        actorId: 'lazarus',
        name: 'Lazarus Group',
        aliases: ['Hidden Cobra', 'Guardians of Peace'],
        motivation: 'financial_espionage',
        targetSectors: ['financial', 'cryptocurrency', 'entertainment'],
        techniques: ['destructive_malware', 'cryptocurrency_theft', 'supply_chain'],
        sophisticationLevel: 'advanced',
        attribution: {
          'country': 'North Korea',
          'confidence': 'high',
          'organization': 'RGB',
        },
        firstSeen: DateTime.now().subtract(const Duration(days: 1800)),
        lastActivity: DateTime.now().subtract(const Duration(days: 15)),
      ),
      ThreatActor(
        actorId: 'carbanak',
        name: 'Carbanak',
        aliases: ['FIN7', 'Carbon Spider'],
        motivation: 'financial',
        targetSectors: ['financial', 'retail', 'hospitality'],
        techniques: ['pos_malware', 'atm_jackpotting', 'business_email_compromise'],
        sophisticationLevel: 'intermediate',
        attribution: {
          'country': 'Unknown',
          'confidence': 'medium',
          'organization': 'Criminal',
        },
        firstSeen: DateTime.now().subtract(const Duration(days: 1500)),
        lastActivity: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];

    _threatActors.addAll(actors);
  }

  Future<void> _initializeIOCDatabase() async {
    _iocDatabase.addAll({
      'malicious_ips': [
        '192.168.100.50',
        '10.0.0.100',
        '172.16.0.50',
        '203.0.113.1',
        '198.51.100.1',
      ],
      'malicious_domains': [
        'malicious-site.com',
        'phishing-bank.net',
        'fake-update.org',
        'credential-harvest.info',
        'malware-drop.biz',
      ],
      'file_hashes': [
        'a1b2c3d4e5f6789012345678901234567890abcd',
        'fedcba0987654321098765432109876543210fedcb',
        '1234567890abcdef1234567890abcdef12345678',
        'abcdef1234567890abcdef1234567890abcdef12',
        '9876543210fedcba9876543210fedcba98765432',
      ],
      'email_indicators': [
        'phishing@malicious-site.com',
        'admin@fake-bank.net',
        'security@credential-harvest.info',
      ],
      'url_patterns': [
        '/admin/login.php',
        '/wp-admin/admin-ajax.php',
        '/api/v1/auth/bypass',
        '/system/config/backup',
      ],
    });
  }

  Future<void> _collectInitialIntelligence() async {
    await _collectThreatIntelligence();
    await _collectDarkWebIntelligence();
    await _analyzeThreatLandscape();
  }

  Future<void> _collectThreatIntelligence() async {
    final threatTypes = [
      'malware',
      'phishing',
      'ransomware',
      'apt_campaign',
      'vulnerability_exploit',
      'data_breach',
      'supply_chain_attack',
    ];

    for (int i = 0; i < 15; i++) {
      final threat = await _generateThreatIntelligence(threatTypes[_random.nextInt(threatTypes.length)]);
      _threatIntelligence.add(threat);
      _threatController.add(threat);
    }
  }

  Future<ThreatIntelligence> _generateThreatIntelligence(String type) async {
    final threatId = 'threat_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}';
    
    switch (type) {
      case 'malware':
        return ThreatIntelligence(
          threatId: threatId,
          type: type,
          severity: ['High', 'Critical'][_random.nextInt(2)],
          source: 'Malware Analysis Lab',
          description: 'New malware variant targeting financial institutions',
          indicators: {
            'file_hash': _iocDatabase['file_hashes']![_random.nextInt(_iocDatabase['file_hashes']!.length)],
            'c2_domain': _iocDatabase['malicious_domains']![_random.nextInt(_iocDatabase['malicious_domains']!.length)],
            'encryption_method': 'AES-256',
            'persistence_mechanism': 'registry_modification',
          },
          affectedSystems: ['Windows', 'macOS'],
          discoveredAt: DateTime.now().subtract(Duration(hours: _random.nextInt(72))),
          expiresAt: DateTime.now().add(Duration(days: 30 + _random.nextInt(60))),
          mitigation: {
            'block_domains': true,
            'update_signatures': true,
            'monitor_registry': true,
          },
        );

      case 'phishing':
        return ThreatIntelligence(
          threatId: threatId,
          type: type,
          severity: ['Medium', 'High'][_random.nextInt(2)],
          source: 'Email Security Gateway',
          description: 'Sophisticated phishing campaign impersonating banking services',
          indicators: {
            'sender_email': _iocDatabase['email_indicators']![_random.nextInt(_iocDatabase['email_indicators']!.length)],
            'phishing_url': 'https://${_iocDatabase['malicious_domains']![_random.nextInt(_iocDatabase['malicious_domains']!.length)]}/login',
            'subject_pattern': 'Urgent: Verify Your Account',
            'attachment_hash': _iocDatabase['file_hashes']![_random.nextInt(_iocDatabase['file_hashes']!.length)],
          },
          affectedSystems: ['Email', 'Web Browsers'],
          discoveredAt: DateTime.now().subtract(Duration(hours: _random.nextInt(48))),
          expiresAt: DateTime.now().add(Duration(days: 14 + _random.nextInt(30))),
          mitigation: {
            'block_sender': true,
            'url_filtering': true,
            'user_awareness': true,
          },
        );

      case 'ransomware':
        return ThreatIntelligence(
          threatId: threatId,
          type: type,
          severity: 'Critical',
          source: 'Incident Response Team',
          description: 'New ransomware strain with advanced evasion techniques',
          indicators: {
            'file_hash': _iocDatabase['file_hashes']![_random.nextInt(_iocDatabase['file_hashes']!.length)],
            'ransom_note_filename': 'READ_ME_NOW.txt',
            'file_extension': '.encrypted',
            'payment_address': 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh',
          },
          affectedSystems: ['Windows', 'Linux', 'Network Shares'],
          discoveredAt: DateTime.now().subtract(Duration(hours: _random.nextInt(24))),
          expiresAt: DateTime.now().add(Duration(days: 60 + _random.nextInt(30))),
          mitigation: {
            'backup_verification': true,
            'network_segmentation': true,
            'endpoint_protection': true,
          },
        );

      default:
        return ThreatIntelligence(
          threatId: threatId,
          type: type,
          severity: 'Medium',
          source: 'Open Source Intelligence',
          description: 'Generic threat intelligence from multiple sources',
          indicators: {
            'ip_address': _iocDatabase['malicious_ips']![_random.nextInt(_iocDatabase['malicious_ips']!.length)],
            'domain': _iocDatabase['malicious_domains']![_random.nextInt(_iocDatabase['malicious_domains']!.length)],
          },
          affectedSystems: ['All Systems'],
          discoveredAt: DateTime.now().subtract(Duration(hours: _random.nextInt(96))),
          expiresAt: DateTime.now().add(Duration(days: 30)),
          mitigation: {
            'monitor_traffic': true,
            'update_blocklists': true,
          },
        );
    }
  }

  Future<void> _collectDarkWebIntelligence() async {
    final categories = [
      'credential_dumps',
      'malware_sales',
      'vulnerability_trading',
      'corporate_data_leaks',
      'attack_planning',
      'tool_development',
    ];

    for (int i = 0; i < 10; i++) {
      final intelligence = await _generateDarkWebIntelligence(categories[_random.nextInt(categories.length)]);
      _darkWebIntelligence.add(intelligence);
      _darkWebController.add(intelligence);
    }
  }

  Future<DarkWebIntelligence> _generateDarkWebIntelligence(String category) async {
    final intelligenceId = 'darkweb_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}';
    
    switch (category) {
      case 'credential_dumps':
        return DarkWebIntelligence(
          intelligenceId: intelligenceId,
          category: category,
          content: 'Large credential dump containing corporate email accounts',
          source: 'Dark Web Forum Monitoring',
          confidenceScore: 0.8 + (_random.nextDouble() * 0.2),
          relatedAssets: ['corporate_emails', 'user_accounts'],
          collectedAt: DateTime.now().subtract(Duration(hours: _random.nextInt(48))),
          metadata: {
            'forum_name': 'underground_market',
            'post_date': DateTime.now().subtract(Duration(hours: _random.nextInt(72))).toIso8601String(),
            'price_btc': 0.5 + (_random.nextDouble() * 2.0),
            'record_count': 10000 + _random.nextInt(90000),
          },
        );

      case 'malware_sales':
        return DarkWebIntelligence(
          intelligenceId: intelligenceId,
          category: category,
          content: 'New banking trojan being sold with source code',
          source: 'Marketplace Monitoring',
          confidenceScore: 0.7 + (_random.nextDouble() * 0.3),
          relatedAssets: ['banking_systems', 'customer_data'],
          collectedAt: DateTime.now().subtract(Duration(hours: _random.nextInt(24))),
          metadata: {
            'marketplace': 'dark_bazaar',
            'seller_reputation': 4.2 + (_random.nextDouble() * 0.8),
            'price_usd': 5000 + _random.nextInt(15000),
            'capabilities': ['credential_theft', 'screen_capture', 'keylogging'],
          },
        );

      case 'corporate_data_leaks':
        return DarkWebIntelligence(
          intelligenceId: intelligenceId,
          category: category,
          content: 'Corporate database allegedly stolen from tech company',
          source: 'Leak Site Monitoring',
          confidenceScore: 0.6 + (_random.nextDouble() * 0.4),
          relatedAssets: ['customer_database', 'internal_documents'],
          collectedAt: DateTime.now().subtract(Duration(hours: _random.nextInt(12))),
          metadata: {
            'leak_site': 'data_leaks_forum',
            'company_sector': 'technology',
            'data_types': ['customer_info', 'financial_records', 'source_code'],
            'verification_status': 'pending',
          },
        );

      default:
        return DarkWebIntelligence(
          intelligenceId: intelligenceId,
          category: category,
          content: 'General dark web intelligence gathering',
          source: 'Automated Crawling',
          confidenceScore: 0.5 + (_random.nextDouble() * 0.5),
          relatedAssets: ['general_assets'],
          collectedAt: DateTime.now().subtract(Duration(hours: _random.nextInt(96))),
          metadata: {
            'collection_method': 'automated',
            'keywords_matched': ['security', 'breach', 'exploit'],
          },
        );
    }
  }

  Future<void> _analyzeThreatLandscape() async {
    _threatLandscape.addAll({
      'active_campaigns': _threatIntelligence.length,
      'threat_actors_tracked': _threatActors.length,
      'dark_web_sources': 15,
      'ioc_indicators': _iocDatabase.values.fold(0, (sum, list) => sum + list.length),
      'threat_severity_distribution': _calculateSeverityDistribution(),
      'top_threat_types': _calculateTopThreatTypes(),
      'geographic_distribution': _calculateGeographicDistribution(),
      'industry_targeting': _calculateIndustryTargeting(),
      'last_updated': DateTime.now().toIso8601String(),
    });
  }

  Map<String, int> _calculateSeverityDistribution() {
    final distribution = <String, int>{};
    for (final threat in _threatIntelligence) {
      distribution[threat.severity] = (distribution[threat.severity] ?? 0) + 1;
    }
    return distribution;
  }

  Map<String, int> _calculateTopThreatTypes() {
    final types = <String, int>{};
    for (final threat in _threatIntelligence) {
      types[threat.type] = (types[threat.type] ?? 0) + 1;
    }
    return types;
  }

  Map<String, int> _calculateGeographicDistribution() {
    final distribution = <String, int>{};
    for (final actor in _threatActors) {
      final country = actor.attribution['country'] ?? 'Unknown';
      distribution[country] = (distribution[country] ?? 0) + 1;
    }
    return distribution;
  }

  Map<String, int> _calculateIndustryTargeting() {
    final targeting = <String, int>{};
    for (final actor in _threatActors) {
      for (final sector in actor.targetSectors) {
        targeting[sector] = (targeting[sector] ?? 0) + 1;
      }
    }
    return targeting;
  }

  void _startContinuousCollection() {
    _collectionTimer = Timer.periodic(const Duration(hours: 6), (_) {
      _performPeriodicCollection();
    });
  }

  Future<void> _performPeriodicCollection() async {
    try {
      // Collect new threat intelligence
      if (_random.nextDouble() < 0.7) {
        final threatTypes = ['malware', 'phishing', 'ransomware', 'apt_campaign'];
        final threat = await _generateThreatIntelligence(threatTypes[_random.nextInt(threatTypes.length)]);
        _threatIntelligence.add(threat);
        _threatController.add(threat);
      }

      // Collect new dark web intelligence
      if (_random.nextDouble() < 0.5) {
        final categories = ['credential_dumps', 'malware_sales', 'corporate_data_leaks'];
        final intelligence = await _generateDarkWebIntelligence(categories[_random.nextInt(categories.length)]);
        _darkWebIntelligence.add(intelligence);
        _darkWebController.add(intelligence);
      }

      // Update threat landscape
      await _analyzeThreatLandscape();

      // Clean up expired intelligence
      _cleanupExpiredIntelligence();

    } catch (e) {
      developer.log('Error during periodic collection: $e', name: 'ThreatIntelligencePlatform');
    }
  }

  void _cleanupExpiredIntelligence() {
    final now = DateTime.now();
    _threatIntelligence.removeWhere((threat) => 
      threat.expiresAt != null && threat.expiresAt!.isBefore(now));
  }

  Future<List<ThreatIntelligence>> searchThreats({
    String? type,
    String? severity,
    String? source,
    DateTime? since,
  }) async {
    var threats = List<ThreatIntelligence>.from(_threatIntelligence);

    if (type != null) {
      threats = threats.where((t) => t.type == type).toList();
    }

    if (severity != null) {
      threats = threats.where((t) => t.severity == severity).toList();
    }

    if (source != null) {
      threats = threats.where((t) => t.source.contains(source)).toList();
    }

    if (since != null) {
      threats = threats.where((t) => t.discoveredAt.isAfter(since)).toList();
    }

    return threats;
  }

  Future<bool> checkIOC(String indicator, String type) async {
    final iocList = _iocDatabase[type];
    if (iocList == null) return false;

    return iocList.contains(indicator);
  }

  Future<List<ThreatActor>> getThreatActors({String? motivation}) async {
    if (motivation != null) {
      return _threatActors.where((actor) => actor.motivation == motivation).toList();
    }
    return List.from(_threatActors);
  }

  Future<Map<String, dynamic>> generateThreatReport() async {
    return {
      'report_id': 'report_${DateTime.now().millisecondsSinceEpoch}',
      'generated_at': DateTime.now().toIso8601String(),
      'threat_landscape': _threatLandscape,
      'recent_threats': _threatIntelligence.take(10).map((t) => t.toJson()).toList(),
      'dark_web_highlights': _darkWebIntelligence.take(5).map((d) => d.toJson()).toList(),
      'active_threat_actors': _threatActors.map((a) => a.toJson()).toList(),
      'ioc_summary': {
        'total_indicators': _iocDatabase.values.fold(0, (sum, list) => sum + list.length),
        'by_type': _iocDatabase.map((key, value) => MapEntry(key, value.length)),
      },
      'recommendations': _generateRecommendations(),
    };
  }

  List<String> _generateRecommendations() {
    return [
      'Monitor for indicators of compromise from recent threat intelligence',
      'Update security controls based on latest threat actor techniques',
      'Review dark web intelligence for potential data exposure',
      'Implement additional controls for high-severity threats',
      'Enhance monitoring for targeted industry sectors',
    ];
  }

  List<ThreatIntelligence> getThreatIntelligence() {
    return List.from(_threatIntelligence);
  }

  List<DarkWebIntelligence> getDarkWebIntelligence() {
    return List.from(_darkWebIntelligence);
  }

  Map<String, dynamic> getThreatLandscape() {
    return Map.from(_threatLandscape);
  }

  Map<String, dynamic> getPlatformMetrics() {
    return {
      'total_threat_intelligence': _threatIntelligence.length,
      'dark_web_intelligence': _darkWebIntelligence.length,
      'threat_actors_tracked': _threatActors.length,
      'ioc_indicators': _iocDatabase.values.fold(0, (sum, list) => sum + list.length),
      'collection_sources': 8,
      'last_collection': DateTime.now().toIso8601String(),
      'platform_uptime': '99.9%',
      'data_freshness_hours': 6,
    };
  }

  Future<List<ThreatIntelligence>> collectThreatIntelligence(String source, Map<String, dynamic> parameters) async {
    final intelligence = <ThreatIntelligence>[];
    
    // Simulate threat intelligence collection
    for (int i = 0; i < 5; i++) {
      intelligence.add(ThreatIntelligence(
        threatId: 'intel_${DateTime.now().millisecondsSinceEpoch}_$i',
        type: ['malware', 'phishing', 'ransomware', 'apt'][_random.nextInt(4)],
        severity: ['low', 'medium', 'high', 'critical'][_random.nextInt(4)],
        source: source,
        description: 'Threat intelligence from $source',
        indicators: {'ip': '192.168.1.${_random.nextInt(255)}', 'domain': 'malicious${_random.nextInt(100)}.com'},
        affectedSystems: ['web_server', 'database', 'email_server'],
        discoveredAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: 30)),
        mitigation: parameters,
      ));
    }
    
    _threatIntelligence.addAll(intelligence);
    return intelligence;
  }

  List<ThreatActor> searchThreatActors(String query) {
    return _threatActors.where((actor) => 
      actor.name.toLowerCase().contains(query.toLowerCase()) ||
      actor.aliases.any((alias) => alias.toLowerCase().contains(query.toLowerCase()))
    ).toList();
  }

  void dispose() {
    _collectionTimer?.cancel();
    _threatController.close();
    _darkWebController.close();
  }
}
