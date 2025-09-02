import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

enum RiskLevel { low, medium, high, critical }

class SecurityAttempt {
  final String id;
  final String email;
  final DateTime timestamp;
  final bool successful;
  final String? ipAddress;
  final String? userAgent;
  final RiskLevel riskLevel;
  final double riskScore;

  SecurityAttempt({
    required this.id,
    required this.email,
    required this.timestamp,
    required this.successful,
    this.ipAddress,
    this.userAgent,
    this.riskLevel = RiskLevel.low,
    this.riskScore = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'timestamp': timestamp.toIso8601String(),
    'successful': successful,
    'ipAddress': ipAddress,
    'userAgent': userAgent,
    'riskLevel': riskLevel.name,
    'riskScore': riskScore,
  };

  factory SecurityAttempt.fromJson(Map<String, dynamic> json) => SecurityAttempt(
    id: json['id'] ?? '',
    email: json['email'] ?? '',
    timestamp: DateTime.parse(json['timestamp']),
    successful: json['successful'] ?? false,
    ipAddress: json['ipAddress'],
    userAgent: json['userAgent'],
    riskLevel: RiskLevel.values.firstWhere((e) => e.name == json['riskLevel'], orElse: () => RiskLevel.low),
    riskScore: (json['riskScore'] ?? 0.0).toDouble(),
  );
}

class AdvancedLoginSecurityService with ChangeNotifier {
  static const _attemptsKey = 'advanced_security_attempts_v1';
  static const _ipBlocksKey = 'advanced_ip_blocks_v1';
  static const _userLocksKey = 'advanced_user_locks_v1';
  static const _securityConfigKey = 'advanced_security_config_v1';
  
  static const int maxFailedAttempts = 5;
  static const int maxIpAttempts = 10;
  static const Duration lockoutDuration = Duration(minutes: 10);
  static const Duration ipLockoutDuration = Duration(hours: 1);
  static const Duration windowDuration = Duration(minutes: 30);

  late SharedPreferences _prefs;
  final List<SecurityAttempt> _attempts = [];
  final Map<String, DateTime> _blockedIps = {};
  final Map<String, DateTime> _lockedUsers = {};
  final Set<String> _maliciousIps = {};
  final Map<String, dynamic> _securityConfig = {};
  bool _isInitialized = false;
  Timer? _cleanupTimer;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    await _loadData();
    await _initializeDefaultConfig();
    await _cleanup();
    
    // Start periodic cleanup
    _cleanupTimer = Timer.periodic(Duration(hours: 1), (_) => _cleanup());
    
    _isInitialized = true;
    developer.log('AdvancedLoginSecurityService initialized', name: 'AdvancedSecurity');
    notifyListeners();
  }

  Future<void> _loadData() async {
    try {
      // Load attempts
      final attemptsJson = _prefs.getString(_attemptsKey);
      if (attemptsJson != null) {
        final List<dynamic> list = jsonDecode(attemptsJson);
        _attempts.addAll(list.map((json) => SecurityAttempt.fromJson(json)));
      }

      // Load IP blocks
      final ipJson = _prefs.getString(_ipBlocksKey);
      if (ipJson != null) {
        final Map<String, dynamic> ipMap = jsonDecode(ipJson);
        ipMap.forEach((ip, timestamp) {
          _blockedIps[ip] = DateTime.parse(timestamp);
        });
      }

      // Load user locks
      final userJson = _prefs.getString(_userLocksKey);
      if (userJson != null) {
        final Map<String, dynamic> userMap = jsonDecode(userJson);
        userMap.forEach((email, timestamp) {
          _lockedUsers[email] = DateTime.parse(timestamp);
        });
      }

      // Load security config
      final configJson = _prefs.getString(_securityConfigKey);
      if (configJson != null) {
        _securityConfig.addAll(jsonDecode(configJson));
      }
    } catch (e) {
      developer.log('Error loading security data: $e', name: 'AdvancedSecurity');
    }
  }

  Future<void> _initializeDefaultConfig() async {
    if (_securityConfig.isEmpty) {
      _securityConfig.addAll({
        'enableIpBlocking': true,
        'enableProgressiveDelays': true,
        'maxRiskScore': 80.0,
        'enableCaptchaAfterAttempts': 3,
      });
      await _saveData();
    }
  }

  RiskLevel _getRiskLevel(double score) {
    if (score >= 80.0) return RiskLevel.critical;
    if (score >= 60.0) return RiskLevel.high;
    if (score >= 30.0) return RiskLevel.medium;
    return RiskLevel.low;
  }

  Future<void> _saveData() async {
    try {
      await _prefs.setString(_attemptsKey, jsonEncode(_attempts.map((a) => a.toJson()).toList()));
      
      final ipMap = <String, String>{};
      _blockedIps.forEach((ip, time) => ipMap[ip] = time.toIso8601String());
      await _prefs.setString(_ipBlocksKey, jsonEncode(ipMap));
      
      final userMap = <String, String>{};
      _lockedUsers.forEach((email, time) => userMap[email] = time.toIso8601String());
      await _prefs.setString(_userLocksKey, jsonEncode(userMap));
    } catch (e) {
      developer.log('Error saving security data: $e', name: 'AdvancedSecurity');
    }
  }

  double _calculateRisk(String email, String? ipAddress) {
    double risk = 0.0;
    
    if (ipAddress != null && _maliciousIps.contains(ipAddress)) risk += 50.0;
    
    final failedCount = _getFailedCount(email);
    risk += failedCount * 8.0;
    
    final ipFailedCount = ipAddress != null ? _getIpFailedCount(ipAddress) : 0;
    risk += ipFailedCount * 3.0;
    
    return math.min(risk, 100.0);
  }

  /// Check if login should be allowed
  Future<Map<String, dynamic>> checkLoginAllowed({
    required String email,
    String? ipAddress,
    String? userAgent,
  }) async {
    if (!_isInitialized) {
      return {'allowed': false, 'error': 'Security service not ready'};
    }

    final normalizedEmail = email.toLowerCase();
    
    // Admin bypass
    if (normalizedEmail == 'env.hygiene@gmail.com') {
      return {
        'allowed': true,
        'isAdmin': true,
        'riskScore': 0.0,
        'attemptsRemaining': 999,
      };
    }

    // Check user lockout
    if (_lockedUsers.containsKey(normalizedEmail)) {
      final lockExpiry = _lockedUsers[normalizedEmail]!;
      if (DateTime.now().isBefore(lockExpiry)) {
        final remainingMinutes = lockExpiry.difference(DateTime.now()).inMinutes;
        return {
          'allowed': false,
          'error': 'Account locked due to failed attempts',
          'lockoutMinutes': remainingMinutes,
          'attemptsRemaining': 0,
        };
      } else {
        _lockedUsers.remove(normalizedEmail);
      }
    }

    // Check IP blocking
    if (ipAddress != null && _blockedIps.containsKey(ipAddress)) {
      final blockExpiry = _blockedIps[ipAddress]!;
      if (DateTime.now().isBefore(blockExpiry)) {
        return {
          'allowed': false,
          'error': 'IP address temporarily blocked',
          'lockoutMinutes': blockExpiry.difference(DateTime.now()).inMinutes,
        };
      } else {
        _blockedIps.remove(ipAddress);
      }
    }

    final failedCount = _getFailedCount(normalizedEmail);
    final ipFailedCount = ipAddress != null ? _getIpFailedCount(ipAddress) : 0;
    final riskScore = _calculateRisk(normalizedEmail, ipAddress);
    
    // Check thresholds
    if (failedCount >= maxFailedAttempts) {
      await _lockUser(normalizedEmail);
      return {
        'allowed': false,
        'error': 'Too many failed attempts',
        'lockoutMinutes': lockoutDuration.inMinutes,
        'attemptsRemaining': 0,
      };
    }

    if (ipFailedCount >= maxIpAttempts && ipAddress != null) {
      await _blockIp(ipAddress);
      return {
        'allowed': false,
        'error': 'Too many attempts from this location',
      };
    }

    return {
      'allowed': true,
      'riskScore': riskScore,
      'riskLevel': _getRiskLevel(riskScore).name,
      'attemptsRemaining': maxFailedAttempts - failedCount,
      'requiresCaptcha': failedCount >= 3,
      'progressiveDelay': failedCount > 0 ? math.pow(2, failedCount).round() : 0,
    };
  }

  /// Record login attempt
  Future<void> recordAttempt({
    required String email,
    required bool successful,
    String? ipAddress,
    String? userAgent,
  }) async {
    if (!_isInitialized) return;

    final normalizedEmail = email.toLowerCase();
    if (normalizedEmail == 'env.hygiene@gmail.com') return; // Skip admin

    final riskScore = _calculateRisk(normalizedEmail, ipAddress);
    final attempt = SecurityAttempt(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: normalizedEmail,
      timestamp: DateTime.now(),
      successful: successful,
      ipAddress: ipAddress,
      userAgent: userAgent,
      riskLevel: _getRiskLevel(riskScore),
      riskScore: riskScore,
    );

    _attempts.add(attempt);
    await _saveData();
    
    developer.log('Recorded ${successful ? 'successful' : 'failed'} attempt for $normalizedEmail', name: 'AdvancedSecurity');
    notifyListeners();
  }

  int _getFailedCount(String email) {
    final now = DateTime.now();
    return _attempts.where((a) => 
      a.email == email.toLowerCase() && 
      !a.successful && 
      now.difference(a.timestamp) <= windowDuration
    ).length;
  }

  int _getIpFailedCount(String ipAddress) {
    final now = DateTime.now();
    return _attempts.where((a) => 
      a.ipAddress == ipAddress && 
      !a.successful && 
      now.difference(a.timestamp) <= windowDuration
    ).length;
  }

  Future<void> _lockUser(String email) async {
    _lockedUsers[email] = DateTime.now().add(lockoutDuration);
    developer.log('User $email locked for ${lockoutDuration.inMinutes} minutes', name: 'AdvancedSecurity');
  }

  Future<void> _blockIp(String ipAddress) async {
    _blockedIps[ipAddress] = DateTime.now().add(ipLockoutDuration);
    developer.log('IP $ipAddress blocked for ${ipLockoutDuration.inHours} hours', name: 'AdvancedSecurity');
  }

  Future<void> _unlockUser(String email) async {
    _lockedUsers.remove(email);
    developer.log('User $email unlocked', name: 'AdvancedSecurity');
  }

  Future<void> _unblockIp(String ipAddress) async {
    _blockedIps.remove(ipAddress);
    developer.log('IP $ipAddress unblocked', name: 'AdvancedSecurity');
  }

  Future<void> _cleanup() async {
    final now = DateTime.now();
    
    // Remove old attempts
    _attempts.removeWhere((a) => now.difference(a.timestamp) > Duration(days: 7));
    
    // Remove expired locks
    _lockedUsers.removeWhere((_, time) => now.isAfter(time));
    _blockedIps.removeWhere((_, time) => now.isAfter(time));
    
    await _saveData();
  }

  // Admin functions
  Future<void> unlockUser(String email) async {
    await _unlockUser(email.toLowerCase());
    await _saveData();
    notifyListeners();
  }

  Future<void> unblockIp(String ipAddress) async {
    await _unblockIp(ipAddress);
    await _saveData();
    notifyListeners();
  }

  Future<void> clearUserAttempts(String email) async {
    _attempts.removeWhere((a) => a.email == email.toLowerCase());
    _lockedUsers.remove(email.toLowerCase());
    await _saveData();
    notifyListeners();
  }

  List<SecurityAttempt> getRecentAttempts({int limit = 50}) {
    final sorted = List<SecurityAttempt>.from(_attempts);
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(limit).toList();
  }

  Map<String, dynamic> getSecurityStats() {
    final now = DateTime.now();
    final recent = _attempts.where((a) => now.difference(a.timestamp) <= Duration(hours: 24)).toList();
    final failed = recent.where((a) => !a.successful).length;
    final successful = recent.where((a) => a.successful).length;

    return {
      'totalAttempts24h': recent.length,
      'failedAttempts24h': failed,
      'successfulAttempts24h': successful,
      'blockedIps': _blockedIps.length,
      'lockedUsers': _lockedUsers.length,
      'failureRate': recent.isEmpty ? 0.0 : failed / recent.length,
    };
  }

  bool isUserLocked(String email) {
    final normalizedEmail = email.toLowerCase();
    if (normalizedEmail == 'env.hygiene@gmail.com') return false;
    
    if (_lockedUsers.containsKey(normalizedEmail)) {
      final lockExpiry = _lockedUsers[normalizedEmail]!;
      if (DateTime.now().isBefore(lockExpiry)) {
        return true;
      } else {
        _lockedUsers.remove(normalizedEmail);
        _saveData();
      }
    }
    return false;
  }

  Duration? getRemainingLockoutTime(String email) {
    final normalizedEmail = email.toLowerCase();
    if (normalizedEmail == 'env.hygiene@gmail.com') return null;
    
    if (_lockedUsers.containsKey(normalizedEmail)) {
      final lockExpiry = _lockedUsers[normalizedEmail]!;
      final remaining = lockExpiry.difference(DateTime.now());
      if (remaining.inSeconds > 0) {
        return remaining;
      } else {
        _lockedUsers.remove(normalizedEmail);
        _saveData();
      }
    }
    return null;
  }


  void dispose() {
    _cleanupTimer?.cancel();
    super.dispose();
  }
}
