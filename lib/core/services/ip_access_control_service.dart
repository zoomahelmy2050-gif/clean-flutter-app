import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

enum AccessControlAction {
  allow,
  block,
  challenge,
  monitor,
}

enum LocationRiskLevel {
  low,
  medium,
  high,
  critical,
}

class IPAccessRule {
  final String id;
  final String name;
  final String ipPattern; // IP, CIDR, or range
  final AccessControlAction action;
  final bool enabled;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? reason;
  final Map<String, dynamic> metadata;

  IPAccessRule({
    required this.id,
    required this.name,
    required this.ipPattern,
    required this.action,
    this.enabled = true,
    required this.createdAt,
    this.expiresAt,
    this.reason,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'ipPattern': ipPattern,
    'action': action.name,
    'enabled': enabled,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
    'reason': reason,
    'metadata': metadata,
  };

  factory IPAccessRule.fromJson(Map<String, dynamic> json) {
    return IPAccessRule(
      id: json['id'],
      name: json['name'],
      ipPattern: json['ipPattern'],
      action: AccessControlAction.values.firstWhere((e) => e.name == json['action']),
      enabled: json['enabled'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      reason: json['reason'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

class GeolocationInfo {
  final String ip;
  final String? country;
  final String? countryCode;
  final String? region;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? timezone;
  final String? isp;
  final bool isVPN;
  final bool isProxy;
  final bool isTor;
  final LocationRiskLevel riskLevel;
  final DateTime timestamp;

  GeolocationInfo({
    required this.ip,
    this.country,
    this.countryCode,
    this.region,
    this.city,
    this.latitude,
    this.longitude,
    this.timezone,
    this.isp,
    this.isVPN = false,
    this.isProxy = false,
    this.isTor = false,
    this.riskLevel = LocationRiskLevel.low,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'ip': ip,
    'country': country,
    'countryCode': countryCode,
    'region': region,
    'city': city,
    'latitude': latitude,
    'longitude': longitude,
    'timezone': timezone,
    'isp': isp,
    'isVPN': isVPN,
    'isProxy': isProxy,
    'isTor': isTor,
    'riskLevel': riskLevel.name,
    'timestamp': timestamp.toIso8601String(),
  };

  factory GeolocationInfo.fromJson(Map<String, dynamic> json) {
    return GeolocationInfo(
      ip: json['ip'],
      country: json['country'],
      countryCode: json['countryCode'],
      region: json['region'],
      city: json['city'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      timezone: json['timezone'],
      isp: json['isp'],
      isVPN: json['isVPN'] ?? false,
      isProxy: json['isProxy'] ?? false,
      isTor: json['isTor'] ?? false,
      riskLevel: LocationRiskLevel.values.firstWhere(
        (e) => e.name == json['riskLevel'],
        orElse: () => LocationRiskLevel.low,
      ),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class AccessAttempt {
  final String id;
  final String ip;
  final String? userEmail;
  final AccessControlAction action;
  final String? reason;
  final DateTime timestamp;
  final GeolocationInfo? location;
  final Map<String, dynamic> metadata;

  AccessAttempt({
    required this.id,
    required this.ip,
    this.userEmail,
    required this.action,
    this.reason,
    required this.timestamp,
    this.location,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'ip': ip,
    'userEmail': userEmail,
    'action': action.name,
    'reason': reason,
    'timestamp': timestamp.toIso8601String(),
    'location': location?.toJson(),
    'metadata': metadata,
  };

  factory AccessAttempt.fromJson(Map<String, dynamic> json) {
    return AccessAttempt(
      id: json['id'],
      ip: json['ip'],
      userEmail: json['userEmail'],
      action: AccessControlAction.values.firstWhere((e) => e.name == json['action']),
      reason: json['reason'],
      timestamp: DateTime.parse(json['timestamp']),
      location: json['location'] != null ? GeolocationInfo.fromJson(json['location']) : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

class IPAccessControlService extends ChangeNotifier {
  final List<IPAccessRule> _rules = [];
  final List<AccessAttempt> _attempts = [];
  final Map<String, GeolocationInfo> _locationCache = {};
  final Set<String> _blockedCountries = {};
  
  static const String _rulesKey = 'ip_access_rules';
  static const String _attemptsKey = 'access_attempts';
  static const String _blockedCountriesKey = 'blocked_countries';
  static const String _locationCacheKey = 'location_cache';

  // Getters
  List<IPAccessRule> get rules => List.unmodifiable(_rules);
  List<AccessAttempt> get attempts => List.unmodifiable(_attempts);
  Set<String> get blockedCountries => Set.unmodifiable(_blockedCountries);

  /// Initialize IP access control service
  Future<void> initialize() async {
    await _loadRules();
    await _loadAttempts();
    await _loadBlockedCountries();
    await _loadLocationCache();
    await _initializeDefaultRules();
  }

  /// Load rules from storage
  Future<void> _loadRules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rulesJson = prefs.getStringList(_rulesKey) ?? [];
      
      _rules.clear();
      for (final ruleJson in rulesJson) {
        final Map<String, dynamic> data = jsonDecode(ruleJson);
        _rules.add(IPAccessRule.fromJson(data));
      }
    } catch (e) {
      debugPrint('Error loading IP rules: $e');
    }
  }

  /// Save rules to storage
  Future<void> _saveRules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rulesJson = _rules.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList(_rulesKey, rulesJson);
    } catch (e) {
      debugPrint('Error saving IP rules: $e');
    }
  }

  /// Load access attempts from storage
  Future<void> _loadAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attemptsJson = prefs.getStringList(_attemptsKey) ?? [];
      
      _attempts.clear();
      for (final attemptJson in attemptsJson) {
        final Map<String, dynamic> data = jsonDecode(attemptJson);
        _attempts.add(AccessAttempt.fromJson(data));
      }
    } catch (e) {
      debugPrint('Error loading access attempts: $e');
    }
  }

  /// Save access attempts to storage
  Future<void> _saveAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attemptsJson = _attempts.map((a) => jsonEncode(a.toJson())).toList();
      await prefs.setStringList(_attemptsKey, attemptsJson);
    } catch (e) {
      debugPrint('Error saving access attempts: $e');
    }
  }

  /// Load blocked countries from storage
  Future<void> _loadBlockedCountries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final countries = prefs.getStringList(_blockedCountriesKey) ?? [];
      _blockedCountries.clear();
      _blockedCountries.addAll(countries);
    } catch (e) {
      debugPrint('Error loading blocked countries: $e');
    }
  }

  /// Save blocked countries to storage
  Future<void> _saveBlockedCountries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_blockedCountriesKey, _blockedCountries.toList());
    } catch (e) {
      debugPrint('Error saving blocked countries: $e');
    }
  }

  /// Load location cache from storage
  Future<void> _loadLocationCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_locationCacheKey);
      if (cacheJson != null) {
        final Map<String, dynamic> data = jsonDecode(cacheJson);
        _locationCache.clear();
        data.forEach((ip, locationData) {
          _locationCache[ip] = GeolocationInfo.fromJson(locationData);
        });
      }
    } catch (e) {
      debugPrint('Error loading location cache: $e');
    }
  }

  /// Save location cache to storage
  Future<void> _saveLocationCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = <String, dynamic>{};
      _locationCache.forEach((ip, location) {
        cacheData[ip] = location.toJson();
      });
      await prefs.setString(_locationCacheKey, jsonEncode(cacheData));
    } catch (e) {
      debugPrint('Error saving location cache: $e');
    }
  }

  /// Initialize default rules
  Future<void> _initializeDefaultRules() async {
    if (_rules.isNotEmpty) return;

    final defaultRules = [
      IPAccessRule(
        id: 'allow_local',
        name: 'Allow Local Network',
        ipPattern: '192.168.0.0/16',
        action: AccessControlAction.allow,
        createdAt: DateTime.now(),
        reason: 'Local network access',
      ),
      IPAccessRule(
        id: 'allow_localhost',
        name: 'Allow Localhost',
        ipPattern: '127.0.0.1',
        action: AccessControlAction.allow,
        createdAt: DateTime.now(),
        reason: 'Localhost access',
      ),
    ];

    _rules.addAll(defaultRules);
    await _saveRules();
  }

  /// Check IP access
  Future<AccessControlAction> checkIPAccess(String ip, {String? userEmail}) async {
    // Get geolocation info
    final location = await getGeolocationInfo(ip);
    
    // Check country-level blocks first
    if (location?.countryCode != null && _blockedCountries.contains(location!.countryCode)) {
      await _logAccessAttempt(ip, AccessControlAction.block, 'Country blocked', userEmail, location);
      return AccessControlAction.block;
    }

    // Check IP-specific rules
    for (final rule in _rules.where((r) => r.enabled)) {
      if (_isIPMatch(ip, rule.ipPattern)) {
        await _logAccessAttempt(ip, rule.action, rule.reason, userEmail, location);
        return rule.action;
      }
    }

    // Check for high-risk indicators
    if (location != null) {
      if (location.isVPN || location.isProxy || location.isTor) {
        await _logAccessAttempt(ip, AccessControlAction.challenge, 'VPN/Proxy/Tor detected', userEmail, location);
        return AccessControlAction.challenge;
      }

      if (location.riskLevel == LocationRiskLevel.high || location.riskLevel == LocationRiskLevel.critical) {
        await _logAccessAttempt(ip, AccessControlAction.challenge, 'High risk location', userEmail, location);
        return AccessControlAction.challenge;
      }
    }

    // Default allow with monitoring
    await _logAccessAttempt(ip, AccessControlAction.allow, 'Default allow', userEmail, location);
    return AccessControlAction.allow;
  }

  /// Get geolocation information for IP
  Future<GeolocationInfo?> getGeolocationInfo(String ip) async {
    // Check cache first
    if (_locationCache.containsKey(ip)) {
      final cached = _locationCache[ip]!;
      // Use cached data if less than 24 hours old
      if (DateTime.now().difference(cached.timestamp).inHours < 24) {
        return cached;
      }
    }

    try {
      // In a real implementation, you would use a geolocation API like:
      // - ipapi.co
      // - ip-api.com
      // - MaxMind GeoIP
      // For demo purposes, we'll simulate the response
      final location = await _simulateGeolocationLookup(ip);
      
      if (location != null) {
        _locationCache[ip] = location;
        await _saveLocationCache();
      }
      
      return location;
    } catch (e) {
      debugPrint('Error getting geolocation for $ip: $e');
      return null;
    }
  }

  /// Simulate geolocation lookup (replace with real API call)
  Future<GeolocationInfo?> _simulateGeolocationLookup(String ip) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    final random = Random();
    final countries = ['US', 'CA', 'GB', 'DE', 'FR', 'JP', 'AU', 'RU', 'CN', 'BR'];
    final cities = ['New York', 'London', 'Tokyo', 'Sydney', 'Moscow', 'Beijing'];
    
    return GeolocationInfo(
      ip: ip,
      country: countries[random.nextInt(countries.length)],
      countryCode: countries[random.nextInt(countries.length)],
      city: cities[random.nextInt(cities.length)],
      latitude: random.nextDouble() * 180 - 90,
      longitude: random.nextDouble() * 360 - 180,
      isVPN: random.nextDouble() < 0.1, // 10% chance of VPN
      isProxy: random.nextDouble() < 0.05, // 5% chance of proxy
      isTor: random.nextDouble() < 0.02, // 2% chance of Tor
      riskLevel: LocationRiskLevel.values[random.nextInt(LocationRiskLevel.values.length)],
      timestamp: DateTime.now(),
    );
  }

  /// Check if IP matches pattern
  bool _isIPMatch(String ip, String pattern) {
    // Simple IP matching - in production, use proper CIDR/range matching
    if (pattern == ip) return true;
    
    // Handle CIDR notation (simplified)
    if (pattern.contains('/')) {
      final parts = pattern.split('/');
      final baseIP = parts[0];
      final prefixLength = int.tryParse(parts[1]) ?? 32;
      
      // Simplified CIDR matching
      if (prefixLength >= 24) {
        final basePrefix = baseIP.substring(0, baseIP.lastIndexOf('.'));
        final ipPrefix = ip.substring(0, ip.lastIndexOf('.'));
        return basePrefix == ipPrefix;
      }
    }
    
    // Handle wildcard patterns
    if (pattern.contains('*')) {
      final regex = RegExp(pattern.replaceAll('*', r'[0-9]+'));
      return regex.hasMatch(ip);
    }
    
    return false;
  }

  /// Log access attempt
  Future<void> _logAccessAttempt(
    String ip,
    AccessControlAction action,
    String? reason,
    String? userEmail,
    GeolocationInfo? location,
  ) async {
    final attempt = AccessAttempt(
      id: 'attempt_${DateTime.now().millisecondsSinceEpoch}',
      ip: ip,
      userEmail: userEmail,
      action: action,
      reason: reason,
      timestamp: DateTime.now(),
      location: location,
    );

    _attempts.insert(0, attempt);
    
    // Keep only last 10000 attempts
    if (_attempts.length > 10000) {
      _attempts.removeRange(10000, _attempts.length);
    }
    
    await _saveAttempts();
    notifyListeners();
  }

  /// Add IP access rule
  Future<void> addRule(IPAccessRule rule) async {
    _rules.add(rule);
    await _saveRules();
    notifyListeners();
  }

  /// Update IP access rule
  Future<void> updateRule(IPAccessRule rule) async {
    final index = _rules.indexWhere((r) => r.id == rule.id);
    if (index != -1) {
      _rules[index] = rule;
      await _saveRules();
      notifyListeners();
    }
  }

  /// Remove IP access rule
  Future<void> removeRule(String ruleId) async {
    _rules.removeWhere((r) => r.id == ruleId);
    await _saveRules();
    notifyListeners();
  }

  /// Block country
  Future<void> blockCountry(String countryCode) async {
    _blockedCountries.add(countryCode.toUpperCase());
    await _saveBlockedCountries();
    notifyListeners();
  }

  /// Unblock country
  Future<void> unblockCountry(String countryCode) async {
    _blockedCountries.remove(countryCode.toUpperCase());
    await _saveBlockedCountries();
    notifyListeners();
  }

  /// Get access statistics
  Map<String, dynamic> getAccessStatistics() {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));
    final last7d = now.subtract(const Duration(days: 7));
    
    final attempts24h = _attempts.where((a) => a.timestamp.isAfter(last24h)).toList();
    final attempts7d = _attempts.where((a) => a.timestamp.isAfter(last7d)).toList();
    
    return {
      'total_attempts': _attempts.length,
      'attempts_24h': attempts24h.length,
      'attempts_7d': attempts7d.length,
      'blocked_attempts': _attempts.where((a) => a.action == AccessControlAction.block).length,
      'challenged_attempts': _attempts.where((a) => a.action == AccessControlAction.challenge).length,
      'allowed_attempts': _attempts.where((a) => a.action == AccessControlAction.allow).length,
      'unique_ips': _attempts.map((a) => a.ip).toSet().length,
      'blocked_countries': _blockedCountries.length,
      'active_rules': _rules.where((r) => r.enabled).length,
      'by_country': _getAttemptsByCountry(),
      'by_action': _getAttemptsByAction(),
    };
  }

  /// Get attempts by country
  Map<String, int> _getAttemptsByCountry() {
    final Map<String, int> byCountry = {};
    for (final attempt in _attempts) {
      final country = attempt.location?.countryCode ?? 'Unknown';
      byCountry[country] = (byCountry[country] ?? 0) + 1;
    }
    return byCountry;
  }

  /// Get attempts by action
  Map<String, int> _getAttemptsByAction() {
    final Map<String, int> byAction = {};
    for (final attempt in _attempts) {
      byAction[attempt.action.name] = (byAction[attempt.action.name] ?? 0) + 1;
    }
    return byAction;
  }

  /// Export access control data
  Map<String, dynamic> exportAccessControlData() {
    return {
      'rules': _rules.map((r) => r.toJson()).toList(),
      'attempts': _attempts.map((a) => a.toJson()).toList(),
      'blocked_countries': _blockedCountries.toList(),
      'statistics': getAccessStatistics(),
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  /// Clear old attempts
  Future<void> clearOldAttempts({int daysToKeep = 30}) async {
    final cutoff = DateTime.now().subtract(Duration(days: daysToKeep));
    _attempts.removeWhere((attempt) => attempt.timestamp.isBefore(cutoff));
    await _saveAttempts();
    notifyListeners();
  }
}
