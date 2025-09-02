import 'dart:async';
import 'dart:developer' as developer;

class RateLimitRule {
  final String ruleId;
  final String name;
  final String endpoint;
  final int requestsPerMinute;
  final int requestsPerHour;
  final int requestsPerDay;
  final List<String> exemptUsers;
  final Map<String, dynamic> customLimits;

  RateLimitRule({
    required this.ruleId,
    required this.name,
    required this.endpoint,
    required this.requestsPerMinute,
    required this.requestsPerHour,
    required this.requestsPerDay,
    this.exemptUsers = const [],
    this.customLimits = const {},
  });

  Map<String, dynamic> toJson() => {
    'rule_id': ruleId,
    'name': name,
    'endpoint': endpoint,
    'requests_per_minute': requestsPerMinute,
    'requests_per_hour': requestsPerHour,
    'requests_per_day': requestsPerDay,
    'exempt_users': exemptUsers,
    'custom_limits': customLimits,
  };
}

class ApiRequest {
  final String requestId;
  final String userId;
  final String endpoint;
  final String method;
  final Map<String, String> headers;
  final String? body;
  final DateTime timestamp;
  final String ipAddress;
  final String userAgent;

  ApiRequest({
    required this.requestId,
    required this.userId,
    required this.endpoint,
    required this.method,
    required this.headers,
    this.body,
    required this.timestamp,
    required this.ipAddress,
    required this.userAgent,
  });

  Map<String, dynamic> toJson() => {
    'request_id': requestId,
    'user_id': userId,
    'endpoint': endpoint,
    'method': method,
    'headers': headers,
    'body': body,
    'timestamp': timestamp.toIso8601String(),
    'ip_address': ipAddress,
    'user_agent': userAgent,
  };
}

class ApiResponse {
  final String requestId;
  final int statusCode;
  final Map<String, String> headers;
  final String? body;
  final int responseTimeMs;
  final DateTime timestamp;

  ApiResponse({
    required this.requestId,
    required this.statusCode,
    required this.headers,
    this.body,
    required this.responseTimeMs,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'request_id': requestId,
    'status_code': statusCode,
    'headers': headers,
    'body': body,
    'response_time_ms': responseTimeMs,
    'timestamp': timestamp.toIso8601String(),
  };
}

class RateLimitStatus {
  final String userId;
  final String endpoint;
  final int requestsThisMinute;
  final int requestsThisHour;
  final int requestsThisDay;
  final DateTime windowStart;
  final bool isLimited;

  RateLimitStatus({
    required this.userId,
    required this.endpoint,
    required this.requestsThisMinute,
    required this.requestsThisHour,
    required this.requestsThisDay,
    required this.windowStart,
    required this.isLimited,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'endpoint': endpoint,
    'requests_this_minute': requestsThisMinute,
    'requests_this_hour': requestsThisHour,
    'requests_this_day': requestsThisDay,
    'window_start': windowStart.toIso8601String(),
    'is_limited': isLimited,
  };
}

class ApiGatewayService {
  static final ApiGatewayService _instance = ApiGatewayService._internal();
  factory ApiGatewayService() => _instance;
  ApiGatewayService._internal();

  final Map<String, RateLimitRule> _rateLimitRules = {};
  final Map<String, Map<String, RateLimitStatus>> _rateLimitStatus = {};
  final List<ApiRequest> _requests = [];
  final List<ApiResponse> _responses = [];
  final Map<String, List<String>> _blockedIps = {};
  final Map<String, DateTime> _suspiciousActivity = {};
  
  final StreamController<ApiRequest> _requestController = StreamController.broadcast();
  final StreamController<ApiResponse> _responseController = StreamController.broadcast();
  final StreamController<RateLimitStatus> _rateLimitController = StreamController.broadcast();

  Stream<ApiRequest> get requestStream => _requestController.stream;
  Stream<ApiResponse> get responseStream => _responseController.stream;
  Stream<RateLimitStatus> get rateLimitStream => _rateLimitController.stream;

  Timer? _cleanupTimer;

  Future<void> initialize() async {
    await _setupDefaultRateLimits();
    _startCleanupTimer();
    
    developer.log('API Gateway Service initialized', name: 'ApiGatewayService');
  }

  Future<void> _setupDefaultRateLimits() async {
    // Authentication endpoints
    await addRateLimitRule(RateLimitRule(
      ruleId: 'auth_login',
      name: 'Login Rate Limit',
      endpoint: '/api/auth/login',
      requestsPerMinute: 5,
      requestsPerHour: 20,
      requestsPerDay: 100,
    ));

    await addRateLimitRule(RateLimitRule(
      ruleId: 'auth_register',
      name: 'Registration Rate Limit',
      endpoint: '/api/auth/register',
      requestsPerMinute: 2,
      requestsPerHour: 5,
      requestsPerDay: 10,
    ));

    // API endpoints
    await addRateLimitRule(RateLimitRule(
      ruleId: 'api_general',
      name: 'General API Rate Limit',
      endpoint: '/api/*',
      requestsPerMinute: 60,
      requestsPerHour: 1000,
      requestsPerDay: 10000,
      exemptUsers: ['admin', 'system'],
    ));

    // Security endpoints
    await addRateLimitRule(RateLimitRule(
      ruleId: 'security_scan',
      name: 'Security Scan Rate Limit',
      endpoint: '/api/security/scan',
      requestsPerMinute: 2,
      requestsPerHour: 10,
      requestsPerDay: 50,
    ));

    // Threat intelligence endpoints
    await addRateLimitRule(RateLimitRule(
      ruleId: 'threat_intel',
      name: 'Threat Intelligence Rate Limit',
      endpoint: '/api/threat-intelligence/*',
      requestsPerMinute: 30,
      requestsPerHour: 500,
      requestsPerDay: 2000,
    ));

    // Analytics endpoints
    await addRateLimitRule(RateLimitRule(
      ruleId: 'analytics',
      name: 'Analytics Rate Limit',
      endpoint: '/api/analytics/*',
      requestsPerMinute: 20,
      requestsPerHour: 200,
      requestsPerDay: 1000,
    ));

    // File upload endpoints
    await addRateLimitRule(RateLimitRule(
      ruleId: 'file_upload',
      name: 'File Upload Rate Limit',
      endpoint: '/api/upload/*',
      requestsPerMinute: 5,
      requestsPerHour: 20,
      requestsPerDay: 100,
    ));
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupOldData();
    });
  }

  void _cleanupOldData() {
    final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
    
    // Clean old requests
    _requests.removeWhere((request) => request.timestamp.isBefore(cutoffTime));
    
    // Clean old responses
    _responses.removeWhere((response) => response.timestamp.isBefore(cutoffTime));
    
    // Clean old rate limit status
    _rateLimitStatus.removeWhere((userId, endpoints) {
      endpoints.removeWhere((endpoint, status) => 
        status.windowStart.isBefore(cutoffTime));
      return endpoints.isEmpty;
    });
    
    // Clean old suspicious activity
    _suspiciousActivity.removeWhere((ip, timestamp) => 
      timestamp.isBefore(cutoffTime));
  }

  Future<RateLimitRule> addRateLimitRule(RateLimitRule rule) async {
    _rateLimitRules[rule.ruleId] = rule;
    
    developer.log('Added rate limit rule: ${rule.name}', name: 'ApiGatewayService');
    
    return rule;
  }

  Future<bool> processRequest(ApiRequest request) async {
    _requests.add(request);
    _requestController.add(request);
    
    // Check if IP is blocked
    if (_isIpBlocked(request.ipAddress)) {
      await _sendResponse(ApiResponse(
        requestId: request.requestId,
        statusCode: 403,
        headers: {'Content-Type': 'application/json'},
        body: '{"error": "IP address blocked"}',
        responseTimeMs: 1,
        timestamp: DateTime.now(),
      ));
      return false;
    }
    
    // Check rate limits
    final rateLimitResult = await _checkRateLimit(request);
    if (!rateLimitResult) {
      await _sendResponse(ApiResponse(
        requestId: request.requestId,
        statusCode: 429,
        headers: {
          'Content-Type': 'application/json',
          'Retry-After': '60',
        },
        body: '{"error": "Rate limit exceeded"}',
        responseTimeMs: 2,
        timestamp: DateTime.now(),
      ));
      return false;
    }
    
    // Check for suspicious activity
    await _checkSuspiciousActivity(request);
    
    // Process the request (mock processing)
    final processingTime = await _mockProcessRequest(request);
    
    await _sendResponse(ApiResponse(
      requestId: request.requestId,
      statusCode: 200,
      headers: {'Content-Type': 'application/json'},
      body: '{"status": "success", "data": {}}',
      responseTimeMs: processingTime,
      timestamp: DateTime.now(),
    ));
    
    return true;
  }

  bool _isIpBlocked(String ipAddress) {
    return _blockedIps.containsKey(ipAddress);
  }

  Future<bool> _checkRateLimit(ApiRequest request) async {
    final applicableRules = _getApplicableRules(request.endpoint);
    
    for (final rule in applicableRules) {
      if (rule.exemptUsers.contains(request.userId)) {
        continue;
      }
      
      final now = DateTime.now();
      
      // Get or create rate limit status
      _rateLimitStatus[request.userId] ??= {};
      var status = _rateLimitStatus[request.userId]![rule.endpoint];
      
      if (status == null || _shouldResetWindow(status.windowStart, now)) {
        status = RateLimitStatus(
          userId: request.userId,
          endpoint: rule.endpoint,
          requestsThisMinute: 0,
          requestsThisHour: 0,
          requestsThisDay: 0,
          windowStart: now,
          isLimited: false,
        );
      }
      
      // Update counters
      final updatedStatus = RateLimitStatus(
        userId: status.userId,
        endpoint: status.endpoint,
        requestsThisMinute: _getRequestsInWindow(status, now, 1) + 1,
        requestsThisHour: _getRequestsInWindow(status, now, 60) + 1,
        requestsThisDay: _getRequestsInWindow(status, now, 1440) + 1,
        windowStart: status.windowStart,
        isLimited: false,
      );
      
      // Check limits
      if (updatedStatus.requestsThisMinute > rule.requestsPerMinute ||
          updatedStatus.requestsThisHour > rule.requestsPerHour ||
          updatedStatus.requestsThisDay > rule.requestsPerDay) {
        
        final limitedStatus = RateLimitStatus(
          userId: updatedStatus.userId,
          endpoint: updatedStatus.endpoint,
          requestsThisMinute: updatedStatus.requestsThisMinute,
          requestsThisHour: updatedStatus.requestsThisHour,
          requestsThisDay: updatedStatus.requestsThisDay,
          windowStart: updatedStatus.windowStart,
          isLimited: true,
        );
        
        _rateLimitStatus[request.userId]![rule.endpoint] = limitedStatus;
        _rateLimitController.add(limitedStatus);
        
        developer.log('Rate limit exceeded for ${request.userId} on ${request.endpoint}', 
                     name: 'ApiGatewayService');
        
        return false;
      }
      
      _rateLimitStatus[request.userId]![rule.endpoint] = updatedStatus;
      _rateLimitController.add(updatedStatus);
    }
    
    return true;
  }

  List<RateLimitRule> _getApplicableRules(String endpoint) {
    return _rateLimitRules.values.where((rule) {
      if (rule.endpoint == endpoint) return true;
      if (rule.endpoint.endsWith('*')) {
        final prefix = rule.endpoint.substring(0, rule.endpoint.length - 1);
        return endpoint.startsWith(prefix);
      }
      return false;
    }).toList();
  }

  bool _shouldResetWindow(DateTime windowStart, DateTime now) {
    return now.difference(windowStart).inMinutes >= 1;
  }

  int _getRequestsInWindow(RateLimitStatus status, DateTime now, int windowMinutes) {
    if (windowMinutes == 1) return status.requestsThisMinute;
    if (windowMinutes == 60) return status.requestsThisHour;
    if (windowMinutes == 1440) return status.requestsThisDay;
    
    return 0;
  }

  Future<void> _checkSuspiciousActivity(ApiRequest request) async {
    final suspiciousPatterns = [
      // Too many different endpoints from same IP
      _checkEndpointDiversity(request),
      // Unusual user agent patterns
      _checkUserAgentPattern(request),
      // High frequency requests
      _checkRequestFrequency(request),
      // Failed authentication attempts
      _checkFailedAuth(request),
    ];
    
    if (suspiciousPatterns.any((pattern) => pattern)) {
      _suspiciousActivity[request.ipAddress] = DateTime.now();
      
      developer.log('Suspicious activity detected from ${request.ipAddress}', 
                   name: 'ApiGatewayService');
      
      // Auto-block after multiple suspicious activities
      final recentSuspicious = _suspiciousActivity.entries
          .where((entry) => 
              entry.key == request.ipAddress &&
              DateTime.now().difference(entry.value).inMinutes < 10)
          .length;
      
      if (recentSuspicious >= 5) {
        await blockIpAddress(request.ipAddress, 'Automated block due to suspicious activity');
      }
    }
  }

  bool _checkEndpointDiversity(ApiRequest request) {
    final recentRequests = _requests.where((r) => 
        r.ipAddress == request.ipAddress &&
        DateTime.now().difference(r.timestamp).inMinutes < 5).toList();
    
    final uniqueEndpoints = recentRequests.map((r) => r.endpoint).toSet();
    return uniqueEndpoints.length > 10; // More than 10 different endpoints in 5 minutes
  }

  bool _checkUserAgentPattern(ApiRequest request) {
    final userAgent = request.userAgent.toLowerCase();
    final suspiciousPatterns = [
      'bot', 'crawler', 'spider', 'scraper', 'curl', 'wget', 'python', 'java'
    ];
    
    return suspiciousPatterns.any((pattern) => userAgent.contains(pattern));
  }

  bool _checkRequestFrequency(ApiRequest request) {
    final recentRequests = _requests.where((r) => 
        r.ipAddress == request.ipAddress &&
        DateTime.now().difference(r.timestamp).inMinutes < 1).length;
    
    return recentRequests > 30; // More than 30 requests per minute
  }

  bool _checkFailedAuth(ApiRequest request) {
    if (!request.endpoint.contains('/auth/')) return false;
    
    final recentFailedAuth = _responses.where((r) => 
        r.statusCode == 401 &&
        DateTime.now().difference(r.timestamp).inMinutes < 5).length;
    
    return recentFailedAuth > 5; // More than 5 failed auth attempts in 5 minutes
  }

  Future<int> _mockProcessRequest(ApiRequest request) async {
    // Simulate processing time based on endpoint complexity
    int baseTime = 50;
    
    if (request.endpoint.contains('/auth/')) baseTime = 200;
    else if (request.endpoint.contains('/security/')) baseTime = 300;
    else if (request.endpoint.contains('/analytics/')) baseTime = 150;
    else if (request.endpoint.contains('/upload/')) baseTime = 500;
    
    final randomDelay = (DateTime.now().millisecond % 100);
    final totalTime = baseTime + randomDelay;
    
    await Future.delayed(Duration(milliseconds: totalTime));
    
    return totalTime;
  }

  Future<void> _sendResponse(ApiResponse response) async {
    _responses.add(response);
    _responseController.add(response);
  }

  Future<void> blockIpAddress(String ipAddress, String reason) async {
    _blockedIps[ipAddress] = [reason, DateTime.now().toIso8601String()];
    
    developer.log('Blocked IP address $ipAddress: $reason', name: 'ApiGatewayService');
  }

  Future<void> unblockIpAddress(String ipAddress) async {
    _blockedIps.remove(ipAddress);
    
    developer.log('Unblocked IP address $ipAddress', name: 'ApiGatewayService');
  }

  Future<List<RateLimitRule>> getRateLimitRules() async {
    return _rateLimitRules.values.toList();
  }

  Future<RateLimitStatus?> getRateLimitStatus(String userId, String endpoint) async {
    return _rateLimitStatus[userId]?[endpoint];
  }

  Future<List<ApiRequest>> getRequests({
    String? userId,
    String? endpoint,
    String? ipAddress,
    int? limit,
  }) async {
    var requests = List<ApiRequest>.from(_requests);
    
    if (userId != null) {
      requests = requests.where((r) => r.userId == userId).toList();
    }
    
    if (endpoint != null) {
      requests = requests.where((r) => r.endpoint == endpoint).toList();
    }
    
    if (ipAddress != null) {
      requests = requests.where((r) => r.ipAddress == ipAddress).toList();
    }
    
    requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    if (limit != null && limit > 0) {
      requests = requests.take(limit).toList();
    }
    
    return requests;
  }

  Future<List<ApiResponse>> getResponses({
    int? statusCode,
    int? minResponseTime,
    int? limit,
  }) async {
    var responses = List<ApiResponse>.from(_responses);
    
    if (statusCode != null) {
      responses = responses.where((r) => r.statusCode == statusCode).toList();
    }
    
    if (minResponseTime != null) {
      responses = responses.where((r) => r.responseTimeMs >= minResponseTime).toList();
    }
    
    responses.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    if (limit != null && limit > 0) {
      responses = responses.take(limit).toList();
    }
    
    return responses;
  }

  Map<String, dynamic> getGatewayMetrics() {
    return getGatewayAnalytics();
  }

  Map<String, dynamic> getGatewayAnalytics() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    final lastHour = now.subtract(const Duration(hours: 1));
    
    final requests24h = _requests.where((r) => r.timestamp.isAfter(last24Hours)).length;
    final requestsLastHour = _requests.where((r) => r.timestamp.isAfter(lastHour)).length;
    
    final responses24h = _responses.where((r) => r.timestamp.isAfter(last24Hours));
    final successfulResponses = responses24h.where((r) => r.statusCode < 400).length;
    final errorResponses = responses24h.where((r) => r.statusCode >= 400).length;
    
    final avgResponseTime = responses24h.isNotEmpty
        ? responses24h.map((r) => r.responseTimeMs).reduce((a, b) => a + b) / responses24h.length
        : 0.0;
    
    final rateLimitedRequests = responses24h.where((r) => r.statusCode == 429).length;
    
    return {
      'total_requests_24h': requests24h,
      'requests_last_hour': requestsLastHour,
      'successful_responses_24h': successfulResponses,
      'error_responses_24h': errorResponses,
      'rate_limited_requests_24h': rateLimitedRequests,
      'avg_response_time_ms': avgResponseTime,
      'success_rate_24h': requests24h > 0 ? (successfulResponses / requests24h) * 100 : 0,
      'blocked_ips': _blockedIps.length,
      'suspicious_ips': _suspiciousActivity.length,
      'active_rate_limit_rules': _rateLimitRules.length,
      'requests_per_second': requestsLastHour / 3600,
    };
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _requestController.close();
    _responseController.close();
    _rateLimitController.close();
  }
}
