import 'dart:async';
import 'dart:developer' as developer;

class TrustScore {
  final double score;
  final DateTime timestamp;
  final Map<String, double> factors;
  final String reason;

  TrustScore({
    required this.score,
    required this.timestamp,
    required this.factors,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
    'score': score,
    'timestamp': timestamp.toIso8601String(),
    'factors': factors,
    'reason': reason,
  };

  factory TrustScore.fromJson(Map<String, dynamic> json) => TrustScore(
    score: json['score'].toDouble(),
    timestamp: DateTime.parse(json['timestamp']),
    factors: Map<String, double>.from(json['factors']),
    reason: json['reason'],
  );
}

class DeviceFingerprint {
  final String deviceId;
  final String platform;
  final String osVersion;
  final String appVersion;
  final Map<String, dynamic> hardwareInfo;
  final Map<String, dynamic> networkInfo;
  final DateTime lastSeen;

  DeviceFingerprint({
    required this.deviceId,
    required this.platform,
    required this.osVersion,
    required this.appVersion,
    required this.hardwareInfo,
    required this.networkInfo,
    required this.lastSeen,
  });

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'platform': platform,
    'os_version': osVersion,
    'app_version': appVersion,
    'hardware_info': hardwareInfo,
    'network_info': networkInfo,
    'last_seen': lastSeen.toIso8601String(),
  };
}

class AccessRequest {
  final String id;
  final String userId;
  final String resource;
  final String action;
  final Map<String, dynamic> context;
  final DateTime timestamp;
  final TrustScore trustScore;

  AccessRequest({
    required this.id,
    required this.userId,
    required this.resource,
    required this.action,
    required this.context,
    required this.timestamp,
    required this.trustScore,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'resource': resource,
    'action': action,
    'context': context,
    'timestamp': timestamp.toIso8601String(),
    'trust_score': trustScore.toJson(),
  };
}

class SecurityPolicy {
  final String id;
  final String name;
  final String resource;
  final List<String> allowedActions;
  final double minTrustScore;
  final Map<String, dynamic> conditions;
  final bool isActive;

  SecurityPolicy({
    required this.id,
    required this.name,
    required this.resource,
    required this.allowedActions,
    required this.minTrustScore,
    required this.conditions,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'resource': resource,
    'allowed_actions': allowedActions,
    'min_trust_score': minTrustScore,
    'conditions': conditions,
    'is_active': isActive,
  };
}

class ZeroTrustService {
  static final ZeroTrustService _instance = ZeroTrustService._internal();
  factory ZeroTrustService() => _instance;
  ZeroTrustService._internal();

  final Map<String, TrustScore> _userTrustScores = {};
  final Map<String, DeviceFingerprint> _deviceFingerprints = {};
  final List<SecurityPolicy> _policies = [];
  final List<AccessRequest> _accessLog = [];
  
  final StreamController<TrustScore> _trustScoreController = StreamController.broadcast();
  final StreamController<AccessRequest> _accessController = StreamController.broadcast();
  
  Timer? _continuousVerificationTimer;
  bool _isMonitoring = false;

  Stream<TrustScore> get trustScoreStream => _trustScoreController.stream;
  Stream<AccessRequest> get accessStream => _accessController.stream;

  Future<void> initialize() async {
    await _loadDefaultPolicies();
    _startContinuousVerification();
    
    developer.log('Zero Trust Service initialized', name: 'ZeroTrustService');
  }

  Future<void> _loadDefaultPolicies() async {
    _policies.addAll([
      SecurityPolicy(
        id: 'admin_access',
        name: 'Admin Access Policy',
        resource: 'admin/*',
        allowedActions: ['read', 'write', 'delete'],
        minTrustScore: 0.8,
        conditions: {
          'require_mfa': true,
          'max_session_duration': 3600,
          'allowed_locations': ['office', 'home'],
        },
      ),
      SecurityPolicy(
        id: 'user_data',
        name: 'User Data Access',
        resource: 'user/data/*',
        allowedActions: ['read', 'write'],
        minTrustScore: 0.6,
        conditions: {
          'require_device_trust': true,
          'max_idle_time': 1800,
        },
      ),
      SecurityPolicy(
        id: 'security_settings',
        name: 'Security Settings',
        resource: 'security/*',
        allowedActions: ['read'],
        minTrustScore: 0.9,
        conditions: {
          'require_biometric': true,
          'require_recent_auth': 300,
        },
      ),
    ]);
  }

  void _startContinuousVerification() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _continuousVerificationTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _performContinuousVerification(),
    );
    
    developer.log('Started continuous verification', name: 'ZeroTrustService');
  }

  Future<TrustScore> calculateTrustScore(String userId, {
    Map<String, dynamic>? context,
  }) async {
    final factors = <String, double>{};
    
    // Device trust factor
    final deviceTrust = await _calculateDeviceTrust(userId, context);
    factors['device_trust'] = deviceTrust;
    
    // Location factor
    final locationTrust = _calculateLocationTrust(context);
    factors['location_trust'] = locationTrust;
    
    // Behavioral factor
    final behaviorTrust = await _calculateBehaviorTrust(userId, context);
    factors['behavior_trust'] = behaviorTrust;
    
    // Time-based factor
    final timeTrust = _calculateTimeTrust(context);
    factors['time_trust'] = timeTrust;
    
    // Authentication recency
    final authTrust = _calculateAuthTrust(context);
    factors['auth_trust'] = authTrust;
    
    // Network trust
    final networkTrust = _calculateNetworkTrust(context);
    factors['network_trust'] = networkTrust;
    
    // Calculate weighted score
    final score = _calculateWeightedScore(factors);
    
    final trustScore = TrustScore(
      score: score,
      timestamp: DateTime.now(),
      factors: factors,
      reason: _generateTrustReason(factors, score),
    );
    
    _userTrustScores[userId] = trustScore;
    _trustScoreController.add(trustScore);
    
    developer.log('Calculated trust score for $userId: $score', name: 'ZeroTrustService');
    
    return trustScore;
  }

  Future<double> _calculateDeviceTrust(String userId, Map<String, dynamic>? context) async {
    if (context == null || !context.containsKey('device_id')) return 0.5;
    
    final deviceId = context['device_id'] as String;
    final fingerprint = _deviceFingerprints[deviceId];
    
    if (fingerprint == null) return 0.3; // Unknown device
    
    // Check if device is recently seen
    final daysSinceLastSeen = DateTime.now().difference(fingerprint.lastSeen).inDays;
    if (daysSinceLastSeen > 30) return 0.4; // Device not seen recently
    
    // Check device consistency
    final currentPlatform = context['platform'] as String?;
    if (currentPlatform != fingerprint.platform) return 0.2; // Platform mismatch
    
    return 0.9; // Trusted device
  }

  double _calculateLocationTrust(Map<String, dynamic>? context) {
    if (context == null || !context.containsKey('location')) return 0.7;
    
    final location = context['location'] as Map<String, dynamic>;
    final country = location['country'] as String?;
    final isVPN = location['is_vpn'] as bool? ?? false;
    
    // Check for high-risk countries
    final highRiskCountries = ['XX', 'YY']; // Mock high-risk countries
    if (country != null && highRiskCountries.contains(country)) return 0.3;
    
    // VPN usage reduces trust slightly
    if (isVPN) return 0.6;
    
    return 0.8;
  }

  Future<double> _calculateBehaviorTrust(String userId, Map<String, dynamic>? context) async {
    if (context == null) return 0.7;
    
    // Analyze typing patterns, mouse movements, etc.
    final typingPattern = context['typing_pattern'] as Map<String, dynamic>?;
    if (typingPattern != null) {
      final avgSpeed = typingPattern['avg_speed'] as double? ?? 0;
      final rhythm = typingPattern['rhythm_score'] as double? ?? 0;
      
      // Compare with baseline (mock implementation)
      if (avgSpeed > 50 && avgSpeed < 200 && rhythm > 0.7) {
        return 0.9; // Normal typing pattern
      }
    }
    
    return 0.7; // Default behavioral trust
  }

  double _calculateTimeTrust(Map<String, dynamic>? context) {
    final now = DateTime.now();
    final hour = now.hour;
    
    // Business hours are more trusted
    if (hour >= 9 && hour <= 17) return 0.9;
    
    // Evening hours
    if (hour >= 18 && hour <= 22) return 0.7;
    
    // Night hours are less trusted
    return 0.4;
  }

  double _calculateAuthTrust(Map<String, dynamic>? context) {
    if (context == null || !context.containsKey('last_auth')) return 0.5;
    
    final lastAuth = DateTime.parse(context['last_auth'] as String);
    final minutesSinceAuth = DateTime.now().difference(lastAuth).inMinutes;
    
    if (minutesSinceAuth < 5) return 1.0;   // Very recent auth
    if (minutesSinceAuth < 30) return 0.9;  // Recent auth
    if (minutesSinceAuth < 60) return 0.7;  // Moderate
    if (minutesSinceAuth < 240) return 0.5; // Old auth
    
    return 0.3; // Very old auth
  }

  double _calculateNetworkTrust(Map<String, dynamic>? context) {
    if (context == null || !context.containsKey('network')) return 0.7;
    
    final network = context['network'] as Map<String, dynamic>;
    final networkType = network['type'] as String?;
    final isSecure = network['is_secure'] as bool? ?? false;
    
    if (networkType == 'corporate' && isSecure) return 0.95;
    if (networkType == 'home' && isSecure) return 0.8;
    if (networkType == 'public' && isSecure) return 0.6;
    if (networkType == 'public' && !isSecure) return 0.3;
    
    return 0.7;
  }

  double _calculateWeightedScore(Map<String, double> factors) {
    const weights = {
      'device_trust': 0.25,
      'location_trust': 0.15,
      'behavior_trust': 0.20,
      'time_trust': 0.10,
      'auth_trust': 0.20,
      'network_trust': 0.10,
    };
    
    double score = 0.0;
    for (final entry in factors.entries) {
      final weight = weights[entry.key] ?? 0.0;
      score += entry.value * weight;
    }
    
    return score.clamp(0.0, 1.0);
  }

  String _generateTrustReason(Map<String, double> factors, double score) {
    final lowFactors = factors.entries
        .where((entry) => entry.value < 0.5)
        .map((entry) => entry.key)
        .toList();
    
    if (score >= 0.8) return 'High trust - all factors positive';
    if (score >= 0.6) return 'Medium trust - minor concerns';
    if (lowFactors.isNotEmpty) return 'Low trust - issues with: ${lowFactors.join(', ')}';
    
    return 'Trust assessment completed';
  }

  Future<bool> authorizeAccess({
    required String userId,
    required String resource,
    required String action,
    Map<String, dynamic>? context,
  }) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Calculate current trust score
    final trustScore = await calculateTrustScore(userId, context: context);
    
    // Find applicable policy
    final policy = _findApplicablePolicy(resource, action);
    
    final accessRequest = AccessRequest(
      id: requestId,
      userId: userId,
      resource: resource,
      action: action,
      context: context ?? {},
      timestamp: DateTime.now(),
      trustScore: trustScore,
    );
    
    _accessLog.add(accessRequest);
    _accessController.add(accessRequest);
    
    bool authorized = false;
    
    if (policy != null) {
      authorized = _evaluatePolicy(policy, trustScore, context);
    } else {
      // Default deny if no policy found
      authorized = false;
    }
    
    developer.log(
      'Access ${authorized ? 'granted' : 'denied'} for $userId to $resource:$action (trust: ${trustScore.score})',
      name: 'ZeroTrustService',
    );
    
    return authorized;
  }

  SecurityPolicy? _findApplicablePolicy(String resource, String action) {
    for (final policy in _policies) {
      if (!policy.isActive) continue;
      
      if (_matchesPattern(resource, policy.resource) && 
          policy.allowedActions.contains(action)) {
        return policy;
      }
    }
    return null;
  }

  bool _matchesPattern(String resource, String pattern) {
    if (pattern.endsWith('*')) {
      final prefix = pattern.substring(0, pattern.length - 1);
      return resource.startsWith(prefix);
    }
    return resource == pattern;
  }

  bool _evaluatePolicy(SecurityPolicy policy, TrustScore trustScore, Map<String, dynamic>? context) {
    // Check minimum trust score
    if (trustScore.score < policy.minTrustScore) return false;
    
    // Evaluate additional conditions
    for (final condition in policy.conditions.entries) {
      if (!_evaluateCondition(condition.key, condition.value, context)) {
        return false;
      }
    }
    
    return true;
  }

  bool _evaluateCondition(String conditionKey, dynamic conditionValue, Map<String, dynamic>? context) {
    switch (conditionKey) {
      case 'require_mfa':
        return context?['mfa_verified'] == true;
      case 'require_biometric':
        return context?['biometric_verified'] == true;
      case 'require_device_trust':
        return (context?['device_trust'] as double? ?? 0) > 0.7;
      case 'require_recent_auth':
        final lastAuth = context?['last_auth'] as String?;
        if (lastAuth == null) return false;
        final authTime = DateTime.parse(lastAuth);
        final maxAge = Duration(seconds: conditionValue as int);
        return DateTime.now().difference(authTime) <= maxAge;
      default:
        return true;
    }
  }

  Future<void> registerDevice(String userId, Map<String, dynamic> deviceInfo) async {
    final fingerprint = DeviceFingerprint(
      deviceId: deviceInfo['device_id'],
      platform: deviceInfo['platform'],
      osVersion: deviceInfo['os_version'],
      appVersion: deviceInfo['app_version'],
      hardwareInfo: deviceInfo['hardware_info'] ?? {},
      networkInfo: deviceInfo['network_info'] ?? {},
      lastSeen: DateTime.now(),
    );
    
    _deviceFingerprints[fingerprint.deviceId] = fingerprint;
    
    developer.log('Registered device ${fingerprint.deviceId} for user $userId', name: 'ZeroTrustService');
  }

  void _performContinuousVerification() {
    for (final userId in _userTrustScores.keys) {
      // Re-evaluate trust scores periodically
      calculateTrustScore(userId);
    }
    
    developer.log('Performed continuous verification for ${_userTrustScores.length} users', name: 'ZeroTrustService');
  }

  List<AccessRequest> getAccessLog({
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
  }) {
    var filtered = _accessLog.where((request) {
      if (userId != null && request.userId != userId) return false;
      if (startTime != null && request.timestamp.isBefore(startTime)) return false;
      if (endTime != null && request.timestamp.isAfter(endTime)) return false;
      return true;
    }).toList();
    
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    if (limit != null && filtered.length > limit) {
      filtered = filtered.take(limit).toList();
    }
    
    return filtered;
  }

  Map<String, dynamic> getSecurityMetrics() {
    final totalRequests = _accessLog.length;
    final deniedRequests = _accessLog.where((r) => r.trustScore.score < 0.5).length;
    
    return {
      'total_access_requests': totalRequests,
      'denied_requests': deniedRequests,
      'approval_rate': totalRequests > 0 ? (totalRequests - deniedRequests) / totalRequests : 0,
      'average_trust_score': _calculateAverageTrustScore(),
      'active_policies': _policies.where((p) => p.isActive).length,
      'registered_devices': _deviceFingerprints.length,
    };
  }

  double _calculateAverageTrustScore() {
    if (_userTrustScores.isEmpty) return 0.0;
    
    final total = _userTrustScores.values.map((ts) => ts.score).reduce((a, b) => a + b);
    return total / _userTrustScores.length;
  }

  void dispose() {
    _continuousVerificationTimer?.cancel();
    _trustScoreController.close();
    _accessController.close();
  }
}
