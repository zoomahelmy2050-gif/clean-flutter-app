import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:clean_flutter/locator.dart';
import 'package:clean_flutter/features/admin/services/dynamic_workflow_service.dart';

/// Advanced login attempt with comprehensive tracking
class LoginAttempt {
  final String email;
  final DateTime timestamp;
  final bool successful;
  final String? ipAddress;
  final String? userAgent;
  final String? deviceId;
  final String? location;
  final double riskScore;
  final Map<String, dynamic> metadata;
  final String attemptId;
  final Duration? responseTime;
  final List<String> securityFlags;

  LoginAttempt({
    required this.email,
    required this.timestamp,
    required this.successful,
    this.ipAddress,
    this.userAgent,
    this.deviceId,
    this.location,
    required this.riskScore,
    Map<String, dynamic>? metadata,
    String? attemptId,
    this.responseTime,
    List<String>? securityFlags,
  })  : metadata = metadata ?? {},
        attemptId = attemptId ?? _generateAttemptId(),
        securityFlags = securityFlags ?? [];

  static String _generateAttemptId() {
    final random = Random();
    return '${DateTime.now().millisecondsSinceEpoch}-${random.nextInt(999999)}';
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'timestamp': timestamp.toIso8601String(),
        'successful': successful,
        'ipAddress': ipAddress,
        'userAgent': userAgent,
        'deviceId': deviceId,
        'location': location,
        'riskScore': riskScore,
        'metadata': metadata,
        'attemptId': attemptId,
        'responseTime': responseTime?.inMilliseconds,
        'securityFlags': securityFlags,
      };

  factory LoginAttempt.fromJson(Map<String, dynamic> json) {
    return LoginAttempt(
      email: json['email'],
      timestamp: DateTime.parse(json['timestamp']),
      successful: json['successful'],
      ipAddress: json['ipAddress'],
      userAgent: json['userAgent'],
      deviceId: json['deviceId'],
      location: json['location'],
      riskScore: (json['riskScore'] ?? 0.0).toDouble(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      attemptId: json['attemptId'],
      responseTime: json['responseTime'] != null
          ? Duration(milliseconds: json['responseTime'])
          : null,
      securityFlags: List<String>.from(json['securityFlags'] ?? []),
    );
  }

  // Provide map-like accessor for tests that expect bracket syntax
  dynamic operator [](String key) {
    switch (key) {
      case 'email':
        return email;
      case 'timestamp':
        return timestamp.toIso8601String();
      case 'successful':
        return successful;
      case 'ipAddress':
        return ipAddress;
      case 'userAgent':
        return userAgent;
      case 'deviceId':
        return deviceId;
      case 'location':
        return location;
      case 'riskScore':
        return riskScore;
      case 'metadata':
        return metadata;
      case 'attemptId':
        return attemptId;
      case 'responseTime':
        return responseTime?.inMilliseconds;
      case 'securityFlags':
        return securityFlags;
      default:
        return null;
    }
  }
}

/// Security profile for a user
class UserSecurityProfile {
  final String email;
  final List<String> trustedDevices;
  final List<String> trustedLocations;
  final Map<String, DateTime> deviceLastSeen;
  final Map<String, int> locationFrequency;
  final double baselineRiskScore;
  final DateTime lastSuccessfulLogin;
  final Map<String, dynamic> behaviorPattern;
  final int totalLogins;
  final int suspiciousAttempts;

  UserSecurityProfile({
    required this.email,
    List<String>? trustedDevices,
    List<String>? trustedLocations,
    Map<String, DateTime>? deviceLastSeen,
    Map<String, int>? locationFrequency,
    double? baselineRiskScore,
    DateTime? lastSuccessfulLogin,
    Map<String, dynamic>? behaviorPattern,
    int? totalLogins,
    int? suspiciousAttempts,
  })  : trustedDevices = trustedDevices ?? [],
        trustedLocations = trustedLocations ?? [],
        deviceLastSeen = deviceLastSeen ?? {},
        locationFrequency = locationFrequency ?? {},
        baselineRiskScore = baselineRiskScore ?? 0.1,
        lastSuccessfulLogin = lastSuccessfulLogin ?? DateTime.now(),
        behaviorPattern = behaviorPattern ?? {},
        totalLogins = totalLogins ?? 0,
        suspiciousAttempts = suspiciousAttempts ?? 0;

  Map<String, dynamic> toJson() => {
        'email': email,
        'trustedDevices': trustedDevices,
        'trustedLocations': trustedLocations,
        'deviceLastSeen': deviceLastSeen.map((k, v) => MapEntry(k, v.toIso8601String())),
        'locationFrequency': locationFrequency,
        'baselineRiskScore': baselineRiskScore,
        'lastSuccessfulLogin': lastSuccessfulLogin.toIso8601String(),
        'behaviorPattern': behaviorPattern,
        'totalLogins': totalLogins,
        'suspiciousAttempts': suspiciousAttempts,
      };

  factory UserSecurityProfile.fromJson(Map<String, dynamic> json) {
    return UserSecurityProfile(
      email: json['email'],
      trustedDevices: List<String>.from(json['trustedDevices'] ?? []),
      trustedLocations: List<String>.from(json['trustedLocations'] ?? []),
      deviceLastSeen: (json['deviceLastSeen'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, DateTime.parse(v)),
          ) ??
          {},
      locationFrequency: Map<String, int>.from(json['locationFrequency'] ?? {}),
      baselineRiskScore: (json['baselineRiskScore'] ?? 0.1).toDouble(),
      lastSuccessfulLogin: DateTime.parse(json['lastSuccessfulLogin']),
      behaviorPattern: Map<String, dynamic>.from(json['behaviorPattern'] ?? {}),
      totalLogins: json['totalLogins'] ?? 0,
      suspiciousAttempts: json['suspiciousAttempts'] ?? 0,
    );
  }

  UserSecurityProfile copyWith({
    List<String>? trustedDevices,
    List<String>? trustedLocations,
    Map<String, DateTime>? deviceLastSeen,
    Map<String, int>? locationFrequency,
    double? baselineRiskScore,
    DateTime? lastSuccessfulLogin,
    Map<String, dynamic>? behaviorPattern,
    int? totalLogins,
    int? suspiciousAttempts,
  }) {
    return UserSecurityProfile(
      email: email,
      trustedDevices: trustedDevices ?? this.trustedDevices,
      trustedLocations: trustedLocations ?? this.trustedLocations,
      deviceLastSeen: deviceLastSeen ?? this.deviceLastSeen,
      locationFrequency: locationFrequency ?? this.locationFrequency,
      baselineRiskScore: baselineRiskScore ?? this.baselineRiskScore,
      lastSuccessfulLogin: lastSuccessfulLogin ?? this.lastSuccessfulLogin,
      behaviorPattern: behaviorPattern ?? this.behaviorPattern,
      totalLogins: totalLogins ?? this.totalLogins,
      suspiciousAttempts: suspiciousAttempts ?? this.suspiciousAttempts,
    );
  }
}

/// Login permission result
class LoginPermission {
  final bool allowed;
  final String? reason;
  final int? lockoutMinutes;
  final int? attemptsRemaining;
  final bool requiresCaptcha;
  final bool requiresMFA;
  final int delaySeconds;
  final double riskScore;
  final String riskLevel;

  LoginPermission({
    required this.allowed,
    this.reason,
    this.lockoutMinutes,
    this.attemptsRemaining,
    this.requiresCaptcha = false,
    this.requiresMFA = false,
    this.delaySeconds = 0,
    this.riskScore = 0.0,
    this.riskLevel = 'low',
  });
}

/// Advanced login attempt monitoring service with AI-based risk scoring
class AdvancedLoginMonitor extends ChangeNotifier {
  static const String _storagePrefix = 'advanced_login_monitor_';
  static const String _attemptsKey = '${_storagePrefix}attempts';
  static const String _profilesKey = '${_storagePrefix}profiles';
  static const String _blacklistKey = '${_storagePrefix}blacklist';
  static const String _whitelistKey = '${_storagePrefix}whitelist';
  
  late SharedPreferences _prefs;
  bool _isInitialized = false;
  
  // In-memory caches
  final List<LoginAttempt> _attempts = [];
  final Map<String, UserSecurityProfile> _profiles = {};
  final Set<String> _blacklistedIPs = {};
  final Set<String> _whitelistedEmails = {};
  final Map<String, DateTime> _temporaryBlocks = {};
  
  // Configuration - More user-friendly settings
  static const int _maxAttempts = 5; // Lockout after 5 failed attempts
  static const Duration _initialLockoutDuration = Duration(minutes: 5); // Start with 5 min
  static const Duration _attemptWindow = Duration(minutes: 10); // Shorter window
  static const int _maxAttemptsInWindow = 7; // Fewer attempts allowed in window
  static const double _highRiskThreshold = 0.7; // More aggressive risk scoring
  static const double _mediumRiskThreshold = 0.4;
  
  // AI/ML simulation parameters
  final Random _random = Random();
  
  bool get isInitialized => _isInitialized;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    await _loadData();
    
    // Add admin to whitelist
    _whitelistedEmails.add('env.hygiene@gmail.com');
    
    _isInitialized = true;
    notifyListeners();
    
    developer.log('AdvancedLoginMonitor initialized', name: 'LoginMonitor');
  }

  /// Load persisted data
  Future<void> _loadData() async {
    try {
      // Load attempts
      final attemptsJson = _prefs.getString(_attemptsKey);
      if (attemptsJson != null) {
        final attemptsList = jsonDecode(attemptsJson) as List;
        _attempts.clear();
        _attempts.addAll(
          attemptsList.map((json) => LoginAttempt.fromJson(json)),
        );
        // Keep only recent attempts (last 7 days)
        final cutoff = DateTime.now().subtract(const Duration(days: 7));
        _attempts.removeWhere((a) => a.timestamp.isBefore(cutoff));
      }

      // Load profiles
      final profilesJson = _prefs.getString(_profilesKey);
      if (profilesJson != null) {
        final profilesMap = jsonDecode(profilesJson) as Map<String, dynamic>;
        _profiles.clear();
        profilesMap.forEach((email, json) {
          _profiles[email] = UserSecurityProfile.fromJson(json);
        });
      }

      // Load blacklist
      final blacklistJson = _prefs.getString(_blacklistKey);
      if (blacklistJson != null) {
        _blacklistedIPs.clear();
        _blacklistedIPs.addAll(List<String>.from(jsonDecode(blacklistJson)));
      }

      // Load whitelist
      final whitelistJson = _prefs.getString(_whitelistKey);
      if (whitelistJson != null) {
        _whitelistedEmails.clear();
        _whitelistedEmails.addAll(List<String>.from(jsonDecode(whitelistJson)));
      }
    } catch (e) {
      developer.log('Error loading data: $e', name: 'LoginMonitor', error: e);
    }
  }

  /// Save data to storage
  Future<void> _saveData() async {
    try {
      // Save attempts (keep last 1000)
      final recentAttempts = _attempts.take(1000).toList();
      await _prefs.setString(
        _attemptsKey,
        jsonEncode(recentAttempts.map((a) => a.toJson()).toList()),
      );

      // Save profiles
      await _prefs.setString(
        _profilesKey,
        jsonEncode(_profiles.map((k, v) => MapEntry(k, v.toJson()))),
      );

      // Save blacklist
      await _prefs.setString(_blacklistKey, jsonEncode(_blacklistedIPs.toList()));

      // Save whitelist
      await _prefs.setString(_whitelistKey, jsonEncode(_whitelistedEmails.toList()));
    } catch (e) {
      developer.log('Error saving data: $e', name: 'LoginMonitor', error: e);
    }
  }

  /// Calculate risk score - more balanced and user-friendly
  double _calculateRiskScore({
    required String email,
    String? ipAddress,
    String? deviceId,
    String? userAgent,
    String? location,
  }) {
    double riskScore = 0.0;
    final normalizedEmail = email.toLowerCase();
    
    // Factor 1: Failed attempts (increased weight)
    final recentAttempts = _getRecentAttemptsForEmail(normalizedEmail, _attemptWindow);
    final failedCount = recentAttempts.where((a) => !a.successful).length;
    if (failedCount > 0) {
      riskScore += (failedCount / _maxAttempts) * 0.3; // 30% weight, steeper curve
    }
    
    // Check if whitelisted (admin)
    if (_whitelistedEmails.contains(normalizedEmail)) {
      return 0.0; // No risk for whitelisted users
    }
    
    // Check if IP is blacklisted
    if (ipAddress != null && _blacklistedIPs.contains(ipAddress)) {
      riskScore += 0.5; // Slightly reduced impact, but still significant
    }
    
    // New user penalty
    final profile = _profiles[normalizedEmail];
    if (profile == null) {
      riskScore += 0.3;
    } else {
      // Check device trust
      if (deviceId != null && !profile.trustedDevices.contains(deviceId)) { // Unknown device
        riskScore += 0.25;
        
        // Device never seen before
        if (!profile.deviceLastSeen.containsKey(deviceId)) {
          riskScore += 0.2; // Higher penalty for completely new device
        }
      }
      
      // Check location trust
      if (location != null && !profile.trustedLocations.contains(location)) { // Unknown location
        riskScore += 0.2;
      }
      
      // Time-based analysis
      final now = DateTime.now();
      final hourOfDay = now.hour;
      
      // Unusual time (midnight to 4 AM, 10 PM to midnight)
      if ((hourOfDay >= 0 && hourOfDay < 4) || (hourOfDay >= 22 && hourOfDay < 24)) {
        riskScore += 0.15;
      }
      
      // Factor 2: Velocity of attempts (less aggressive)
      if (recentAttempts.length >= 5) {  // Need more attempts to trigger
        final timeDiffs = <Duration>[];
        for (int i = 1; i < min(5, recentAttempts.length); i++) {
          timeDiffs.add(recentAttempts[i].timestamp.difference(recentAttempts[i-1].timestamp));
        }
        final avgDiff = timeDiffs.reduce((a, b) => a + b) ~/ timeDiffs.length;
        if (avgDiff.inSeconds < 3) {  // Very fast attempts
          riskScore += 0.3; // Higher penalty for extremely fast attempts
        } else if (avgDiff.inSeconds < 10) {
          riskScore += 0.15; // Still fast, moderate penalty
        }
      }

      // User agent analysis
      if (userAgent != null && userAgent.toLowerCase().contains('bot')) {
        riskScore += 0.4; // Significant penalty for bot-like user agents
      }
      
      // Behavioral anomaly detection (simulated)
      if (profile.behaviorPattern.isNotEmpty) {
        // Simulate ML-based anomaly detection
        final anomalyScore = _simulateAnomalyDetection(profile, userAgent);
        riskScore += anomalyScore * 0.3;
      }
    }
    
    // Normalize to 0-1 range
    return min(1.0, max(0.0, riskScore));
  }

  /// Simulate ML-based anomaly detection
  double _simulateAnomalyDetection(UserSecurityProfile profile, String? userAgent) {
    // Simulate complex ML model output
    // In production, this would use actual ML models
    return _random.nextDouble() * 0.5;
  }

  /// Get recent attempts for an email
  List<LoginAttempt> _getRecentAttemptsForEmail(String email, Duration window) {
    final cutoff = DateTime.now().subtract(window);
    return _attempts
        .where((a) => a.email == email && a.timestamp.isAfter(cutoff))
        .toList();
  }

  /// Check if login is allowed for a user
  Future<LoginPermission> checkLoginPermission({
    required String email,
    String? ipAddress,
    String? deviceId,
    String? userAgent,
    String? location,
  }) async {
    if (!_isInitialized) {
      return LoginPermission(
        allowed: false,
        reason: 'Security service not initialized',
      );
    }

    final normalizedEmail = email.toLowerCase();
    
    // Admin bypass
    if (_whitelistedEmails.contains(normalizedEmail)) {
      return LoginPermission(
        allowed: true,
        reason: 'whitelisted',
        riskScore: 0.0,
        riskLevel: 'none',
        attemptsRemaining: 999,
        requiresMFA: false,
        requiresCaptcha: false,
      );
    }
    
    // Check temporary blocks
    if (_temporaryBlocks.containsKey(normalizedEmail)) {
      final blockExpiry = _temporaryBlocks[normalizedEmail]!;
      if (DateTime.now().isBefore(blockExpiry)) {
        final remaining = blockExpiry.difference(DateTime.now());
        return LoginPermission(
          allowed: false,
          reason: 'Account temporarily locked',
          lockoutMinutes: remaining.inMinutes,
        );
      } else {
        _temporaryBlocks.remove(normalizedEmail);
      }
    }
    // If expired, let it proceed naturally below
    // _temporaryBlocks.remove(normalizedEmail); // Handled by cleanup
    
    // Check IP blacklist
    if (ipAddress != null && _blacklistedIPs.contains(ipAddress)) {
      return LoginPermission(
        allowed: false,
        reason: 'Access denied from this IP address (blacklisted)',
        riskLevel: 'critical', // Assume critical risk for blacklisted IPs
      );
    }
    
    // Calculate risk score
    final riskScore = _calculateRiskScore(
      email: normalizedEmail,
      ipAddress: ipAddress,
      deviceId: deviceId,
      userAgent: userAgent,
      location: location,
    );
    
    // Determine risk level based on updated thresholds
    final String riskLevel = _getRiskLevelString(riskScore);
    
    // Check recent attempts
    final recentAttempts = _getRecentAttemptsForEmail(normalizedEmail, _attemptWindow);
    final failedAttempts = recentAttempts.where((a) => !a.successful).toList();
    final attemptsRemaining = max(0, _maxAttempts - failedAttempts.length);
    
    // Apply progressive security measures based on failed attempts
    bool requiresMFA = false;
    bool requiresCaptcha = false;
    int delaySeconds = 0;
    
    if (failedAttempts.length >= 4) {
      requiresCaptcha = true;
      delaySeconds = 3; // Delay for CAPTCHA challenge
    } else if (failedAttempts.length >= 3) {
      delaySeconds = 2; // Increased delay
    } else if (failedAttempts.length >= 1) {
      delaySeconds = 1; // Initial small delay
    }

    // Further escalate for higher risk scores
    if (riskScore >= _highRiskThreshold) {
      requiresMFA = true; // Always require MFA for high risk
      delaySeconds = max(delaySeconds, 5); // Ensure at least 5s delay
    } else if (riskScore >= _mediumRiskThreshold) {
      requiresCaptcha = max(requiresCaptcha ? 1 : 0, 1) == 1; // Ensure CAPTCHA
      delaySeconds = max(delaySeconds, 3); // Ensure at least 3s delay
    }
    
    // Check if max attempts exceeded with escalating lockouts
    if (failedAttempts.length >= _maxAttempts) { // Now set to 5
      // Calculate escalating lockout duration based on previous lockouts
      final previousLockouts = _getRecentLockoutsForEmail(normalizedEmail);
      final lockoutMultiplier = min(previousLockouts + 1, 6);  // Cap at 6x
      final lockoutDuration = _initialLockoutDuration * lockoutMultiplier;
      
      _temporaryBlocks[normalizedEmail] = DateTime.now().add(lockoutDuration);
      await _saveData();
      
      // Record this as a lockout in metadata
      _attempts.add(LoginAttempt(
        email: normalizedEmail,
        successful: false,
        timestamp: DateTime.now(),
        ipAddress: ipAddress,
        deviceId: deviceId,
        userAgent: userAgent,
        location: location,
        riskScore: riskScore,
        metadata: {'lockout': true, 'lockoutDuration': lockoutDuration.inMinutes},
      ));
      
      return LoginPermission(
        allowed: false,
        reason: 'Too many attempts. Please wait ${lockoutDuration.inMinutes} minutes before trying again.',
        lockoutMinutes: lockoutDuration.inMinutes,
        attemptsRemaining: 0,
        riskScore: riskScore,
        riskLevel: riskLevel,
      );
    }
    
    return LoginPermission(
      allowed: true,
      riskScore: riskScore,
      riskLevel: riskLevel,
      attemptsRemaining: attemptsRemaining,
      requiresMFA: requiresMFA,
      requiresCaptcha: requiresCaptcha,
      delaySeconds: delaySeconds,
    );
  }

  /// Synchronous version of checkLoginPermission
  LoginPermission checkLoginPermissionSync({required String email}) {
    final normalizedEmail = email.toLowerCase();
    
    // Admin bypass
    if (_whitelistedEmails.contains(normalizedEmail)) {
      return LoginPermission(
        allowed: true,
        reason: 'whitelisted',
        riskScore: 0.0,
        riskLevel: 'none',
      );
    }
    
    // Check temporary blocks
    if (_temporaryBlocks.containsKey(normalizedEmail)) {
      final blockExpiry = _temporaryBlocks[normalizedEmail]!;
      if (DateTime.now().isBefore(blockExpiry)) {
        final remaining = blockExpiry.difference(DateTime.now());
        return LoginPermission(
          allowed: false,
          reason: 'Account temporarily locked',
          lockoutMinutes: remaining.inMinutes,
        );
      }
    }
    
    return LoginPermission(allowed: true);
  }

  /// Record a login attempt
  Future<void> recordAttempt({
    required String email,
    required bool successful,
    String? ipAddress,
    String? userAgent,
    String? deviceId,
    String? location,
  }) async {
    return recordLoginAttempt(
      email: email,
      successful: successful,
      ipAddress: ipAddress,
      userAgent: userAgent,
      deviceId: deviceId,
      location: location,
    );
  }

  /// Record a login attempt
  Future<void> recordLoginAttempt({
    required String email,
    required bool successful,
    String? ipAddress,
    String? deviceId,
    String? userAgent,
    String? location,
    Duration? responseTime,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) return;
    
    final normalizedEmail = email.toLowerCase();
    final stopwatch = Stopwatch()..start();
    
    // Calculate risk score for this attempt
    final riskScore = _calculateRiskScore(
      email: normalizedEmail,
      ipAddress: ipAddress,
      deviceId: deviceId,
      userAgent: userAgent,
      location: location,
    );
    
    // Determine security flags
    final securityFlags = <String>[];
    if (riskScore >= _highRiskThreshold) securityFlags.add('HIGH_RISK');
    if (ipAddress != null && _blacklistedIPs.contains(ipAddress)) {
      securityFlags.add('BLACKLISTED_IP');
    }
    if (!successful && _getRecentAttemptsForEmail(normalizedEmail, const Duration(minutes: 1)).length > 2) {
      securityFlags.add('RAPID_FAILED_ATTEMPTS');
    }
    
    // Create attempt record
    final attempt = LoginAttempt(
      email: normalizedEmail,
      timestamp: DateTime.now(),
      successful: successful,
      ipAddress: ipAddress,
      deviceId: deviceId,
      userAgent: userAgent,
      location: location,
      riskScore: riskScore,
      responseTime: responseTime,
      metadata: metadata,
      securityFlags: securityFlags,
    );
    
    // Add to attempts list
    _attempts.insert(0, attempt);
    
    // Trigger dynamic workflow on high risk or blacklist/rapid failures
    try {
      if (securityFlags.contains('HIGH_RISK') || securityFlags.contains('BLACKLISTED_IP') || securityFlags.contains('RAPID_FAILED_ATTEMPTS')) {
        final svc = locator<DynamicWorkflowService>();
        final wf = svc.list().firstWhere(
          (w) => w.triggers['type'] == 'security_incident',
          orElse: () => DynamicWorkflow(
            id: 'auto_security_response',
            name: 'Auto Security Response',
            description: 'Auto-run on high-risk login incidents',
            steps: [
              DynamicWorkflowStep(id: 'isolate', name: 'Isolate Threat', action: 'security.isolate_threat', onSuccess: 'analyze', onFailure: 'alert'),
              DynamicWorkflowStep(id: 'analyze', name: 'Analyze Threat', action: 'security.deep_analysis', onSuccess: 'mitigate', onFailure: 'alert'),
              DynamicWorkflowStep(id: 'mitigate', name: 'Apply Mitigation', action: 'security.apply_mitigation', onSuccess: 'report', onFailure: 'alert'),
              DynamicWorkflowStep(id: 'report', name: 'Generate Report', action: 'reporting.incident_report', onSuccess: null, onFailure: 'alert'),
              DynamicWorkflowStep(id: 'alert', name: 'Alert Administrators', action: 'notification.alert_admins', onSuccess: null, onFailure: null, parameters: {'priority': 'high'}),
            ],
            triggers: {'type': 'security_incident'},
          ),
        );
        // Ensure persisted if this is the default created on the fly
        if (svc.getById(wf.id) == null) {
          await svc.create(wf);
        }
        await svc.execute(wf.id, context: {
          'email': normalizedEmail,
          'ipAddress': ipAddress,
          'riskScore': riskScore,
          'flags': securityFlags,
        });
      }
    } catch (e) {
      developer.log('Dynamic workflow trigger failed: $e', name: 'LoginMonitor');
    }
    
    // Update user profile
    await _updateUserProfile(
      email: normalizedEmail,
      successful: successful,
      deviceId: deviceId,
      location: location,
      riskScore: riskScore,
    );
    
    // Auto-blacklist IPs with too many failures
    if (!successful && ipAddress != null) {
      final ipFailures = _attempts
          .where((a) => a.ipAddress == ipAddress && !a.successful)
          .take(10)
          .length;
      
      if (ipFailures >= 8) {
        _blacklistedIPs.add(ipAddress);
        developer.log('Auto-blacklisted IP: $ipAddress', name: 'LoginMonitor');
      }
    }
    
    await _saveData();
    notifyListeners();
    
    stopwatch.stop();
    developer.log(
      'Recorded ${successful ? "successful" : "failed"} attempt for $normalizedEmail '
      'Risk: ${riskScore.toStringAsFixed(2)} '
      'Flags: ${securityFlags.join(", ")} '
      'Time: ${stopwatch.elapsedMilliseconds}ms',
      name: 'LoginMonitor',
    );
  }

  /// Update user security profile
  Future<void> _updateUserProfile({
    required String email,
    required bool successful,
    String? deviceId,
    String? location,
    required double riskScore,
  }) async {
    UserSecurityProfile profile = _profiles[email] ?? UserSecurityProfile(email: email);
    
    if (successful) {
      // Update trusted devices
      if (deviceId != null && riskScore < 0.3) {
        final devices = List<String>.from(profile.trustedDevices);
        if (!devices.contains(deviceId)) {
          devices.add(deviceId);
          // Keep only last 5 devices
          if (devices.length > 5) {
            devices.removeAt(0);
          }
        }
        
        final deviceLastSeen = Map<String, DateTime>.from(profile.deviceLastSeen);
        deviceLastSeen[deviceId] = DateTime.now();
        
        profile = profile.copyWith(
          trustedDevices: devices,
          deviceLastSeen: deviceLastSeen,
        );
      }
      
      // Update trusted locations
      if (location != null && riskScore < 0.3) {
        final locations = List<String>.from(profile.trustedLocations);
        if (!locations.contains(location)) {
          locations.add(location);
          // Keep only last 3 locations
          if (locations.length > 3) {
            locations.removeAt(0);
          }
        }
        
        final locationFreq = Map<String, int>.from(profile.locationFrequency);
        locationFreq[location] = (locationFreq[location] ?? 0) + 1;
        
        profile = profile.copyWith(
          trustedLocations: locations,
          locationFrequency: locationFreq,
        );
      }
      
      // Update baseline risk score (moving average)
      final newBaseline = (profile.baselineRiskScore * 0.9) + (riskScore * 0.1);
      
      profile = profile.copyWith(
        lastSuccessfulLogin: DateTime.now(),
        totalLogins: profile.totalLogins + 1,
        baselineRiskScore: newBaseline,
      );
    } else {
      // Track suspicious attempts
      profile = profile.copyWith(
        suspiciousAttempts: profile.suspiciousAttempts + 1,
      );
    }
    
    _profiles[email] = profile;
  }

  /// Get login history for a user
  List<LoginAttempt> getUserLoginHistory(String email, {int limit = 50}) {
    final normalizedEmail = email.toLowerCase();
    return _attempts
        .where((a) => a.email == normalizedEmail)
        .take(limit)
        .toList();
  }

  /// Get recent login attempts
  List<LoginAttempt> getRecentAttempts({int limit = 50}) {
    return _attempts.take(limit).toList();
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    return getSecurityStatistics();
  }

  /// Get security statistics
  Map<String, dynamic> getSecurityStatistics() {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));
    final last7d = now.subtract(const Duration(days: 7));
    
    final attempts24h = _attempts.where((a) => a.timestamp.isAfter(last24h)).toList();
    final attempts7d = _attempts.where((a) => a.timestamp.isAfter(last7d)).toList();
    
    return {
      'totalAttempts': _attempts.length,
      'attempts24h': attempts24h.length,
      'attempts7d': attempts7d.length,
      'successRate24h': attempts24h.isEmpty
          ? 0.0
          : attempts24h.where((a) => a.successful).length / attempts24h.length,
      'highRiskAttempts': _attempts.where((a) => a.riskScore >= _highRiskThreshold).length,
      'blacklistedIPs': _blacklistedIPs.length,
      'whitelistedUsers': _whitelistedEmails.length,
      'activeBlocks': _temporaryBlocks.length,
      'uniqueUsers': _attempts.map((a) => a.email).toSet().length,
      'averageRiskScore': _attempts.isEmpty
          ? 0.0
          : _attempts.map((a) => a.riskScore).reduce((a, b) => a + b) / _attempts.length,
    };
  }

  /// Clear login attempts for a user
  Future<void> clearAttempts(String email) async {
    return clearUserAttempts(email);
  }

  /// Clear login attempts for a user (admin function)
  Future<void> clearUserAttempts(String email) async {
    final normalizedEmail = email.toLowerCase();
    _attempts.removeWhere((a) => a.email == normalizedEmail);
    _temporaryBlocks.remove(normalizedEmail);
    await _saveData();
    notifyListeners();
  }

  /// Unlock a user account
  Future<void> unlockUser(String email) async {
    final normalizedEmail = email.toLowerCase();
    _temporaryBlocks.remove(normalizedEmail);
    await _saveData();
    notifyListeners();
  }

  /// Add IP to blacklist
  Future<void> blacklistIP(String ipAddress) async {
    _blacklistedIPs.add(ipAddress);
    await _saveData();
    notifyListeners();
  }

  /// Remove IP from blacklist
  Future<void> removeFromBlacklist(String ipAddress) async {
    return unblacklistIP(ipAddress);
  }

  /// Remove IP from blacklist
  Future<void> unblacklistIP(String ipAddress) async {
    _blacklistedIPs.remove(ipAddress);
    await _saveData();
    notifyListeners();
  }

  /// Add email to whitelist
  Future<void> whitelistEmail(String email) async {
    _whitelistedEmails.add(email.toLowerCase());
    await _saveData();
    notifyListeners();
  }

  /// Remove email from whitelist
  Future<void> unwhitelistEmail(String email) async {
    _whitelistedEmails.remove(email.toLowerCase());
    await _saveData();
    notifyListeners();
  }

  /// Get risk assessment for current context
  Map<String, dynamic> getRiskAssessment(String email) {
    final normalizedEmail = email.toLowerCase();
    final profile = _profiles[normalizedEmail];
    final recentAttempts = _getRecentAttemptsForEmail(normalizedEmail, const Duration(hours: 1));
    
    return {
      'email': normalizedEmail,
      'hasProfile': profile != null,
      'trustedDeviceCount': profile?.trustedDevices.length ?? 0,
      'trustedLocationCount': profile?.trustedLocations.length ?? 0,
      'baselineRisk': profile?.baselineRiskScore ?? 0.5,
      'recentAttempts': recentAttempts.length,
      'recentFailures': recentAttempts.where((a) => !a.successful).length,
      'isWhitelisted': _whitelistedEmails.contains(normalizedEmail),
      'isBlocked': _temporaryBlocks.containsKey(normalizedEmail),
      'recommendation': _getSecurityRecommendation(normalizedEmail),
    };
  }

  /// Get recent lockouts count for email (for escalating lockout durations)
  int _getRecentLockoutsForEmail(String email) {
    final normalizedEmail = email.toLowerCase();
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    
    // Count how many times this user was locked out in the last 24 hours
    return _attempts
        .where((a) => a.email == normalizedEmail && 
                     !a.successful && 
                     a.timestamp.isAfter(cutoff) &&
                     (a.metadata?['lockout'] == true || a.metadata?['lockoutDuration'] != null))
        .length; // Count each lockout event, not just successful lockouts
  }

  /// Get security recommendation
  String _getSecurityRecommendation(String email) {
    if (_whitelistedEmails.contains(email)) {
      return 'Trusted user - full access';
    }
    
    if (_temporaryBlocks.containsKey(email)) {
      return 'Currently blocked - wait for timeout';
    }
    
    final profile = _profiles[email];
    if (profile == null) {
      return 'New user - apply standard security';
    }
    
    if (profile.suspiciousAttempts > 10) {
      return 'High-risk user - require additional verification';
    }
    
    if (profile.baselineRiskScore > 0.5) {
      return 'Elevated risk - monitor closely';
    }
    
    return 'Normal user - standard security';
  }

  // Helper to determine risk level string
  String _getRiskLevelString(double score) {
    if (score >= _highRiskThreshold) return 'high';
    if (score >= _mediumRiskThreshold) return 'medium';
    return 'low';
  }

  /// Expose for testing and external services
  Set<String> get blacklistedIPs => Set.from(_blacklistedIPs);

  @override
  void dispose() {
    // _cleanupTimer?.cancel(); // No timer in this class, so no need to cancel
    super.dispose();
  }
}
