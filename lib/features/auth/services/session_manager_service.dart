import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';

class SessionManagerService extends ChangeNotifier {
  static const String _sessionsKey = 'user_sessions';
  static const String _currentSessionKey = 'current_session';
  static const Duration _sessionTimeout = Duration(hours: 24);
  static const Duration _refreshThreshold = Duration(hours: 1);
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();
  
  List<SessionInfo> _sessions = [];
  SessionInfo? _currentSession;
  Timer? _sessionTimer;
  Timer? _activityTimer;
  DateTime _lastActivity = DateTime.now();
  
  List<SessionInfo> get sessions => List.unmodifiable(_sessions);
  SessionInfo? get currentSession => _currentSession;
  bool get isSessionActive => _currentSession != null && !_currentSession!.isExpired;
  
  SessionManagerService() {
    _initialize();
  }
  
  Future<void> _initialize() async {
    await _loadSessions();
    _startSessionMonitor();
    _startActivityMonitor();
    
    // Listen to auth state changes
    _auth.authStateChanges().listen((user) {
      if (user == null) {
        endCurrentSession();
      }
    });
  }
  
  // Create a new session
  Future<SessionInfo> createSession({
    required String userId,
    String? email,
    String? phoneNumber,
    Map<String, dynamic>? metadata,
  }) async {
    final deviceInfo = await _getDeviceInfo();
    
    final session = SessionInfo(
      id: _uuid.v4(),
      userId: userId,
      email: email,
      phoneNumber: phoneNumber,
      deviceId: deviceInfo['deviceId'] ?? 'unknown',
      deviceName: deviceInfo['deviceName'] ?? 'Unknown Device',
      deviceType: deviceInfo['deviceType'] ?? 'unknown',
      ipAddress: await _getIpAddress(),
      location: await _getLocation(),
      userAgent: deviceInfo['userAgent'],
      createdAt: DateTime.now(),
      lastActivityAt: DateTime.now(),
      expiresAt: DateTime.now().add(_sessionTimeout),
      isActive: true,
      metadata: metadata ?? {},
    );
    
    _sessions.add(session);
    _currentSession = session;
    await _saveSessions();
    await _saveCurrentSession(session);
    
    notifyListeners();
    return session;
  }
  
  // End current session
  Future<void> endCurrentSession() async {
    if (_currentSession != null) {
      _currentSession!.isActive = false;
      _currentSession!.endedAt = DateTime.now();
      await _saveSessions();
      await _storage.delete(key: _currentSessionKey);
      _currentSession = null;
      notifyListeners();
    }
  }
  
  // End a specific session
  Future<void> endSession(String sessionId) async {
    final session = _sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => throw Exception('Session not found'),
    );
    
    session.isActive = false;
    session.endedAt = DateTime.now();
    
    if (_currentSession?.id == sessionId) {
      _currentSession = null;
      await _storage.delete(key: _currentSessionKey);
    }
    
    await _saveSessions();
    notifyListeners();
  }
  
  // End all sessions except current
  Future<void> endAllOtherSessions() async {
    for (final session in _sessions) {
      if (session.id != _currentSession?.id) {
        session.isActive = false;
        session.endedAt = DateTime.now();
      }
    }
    await _saveSessions();
    notifyListeners();
  }
  
  // Refresh current session
  Future<void> refreshSession() async {
    if (_currentSession != null && !_currentSession!.isExpired) {
      _currentSession!.lastActivityAt = DateTime.now();
      _currentSession!.expiresAt = DateTime.now().add(_sessionTimeout);
      await _saveSessions();
      notifyListeners();
    }
  }
  
  // Update activity timestamp
  void updateActivity() {
    _lastActivity = DateTime.now();
    if (_currentSession != null) {
      _currentSession!.lastActivityAt = _lastActivity;
    }
  }
  
  // Check if session needs refresh
  bool needsRefresh() {
    if (_currentSession == null) return false;
    final timeUntilExpiry = _currentSession!.expiresAt.difference(DateTime.now());
    return timeUntilExpiry <= _refreshThreshold;
  }
  
  // Get active sessions for a user
  List<SessionInfo> getActiveSessions(String userId) {
    return _sessions.where((s) => 
      s.userId == userId && 
      s.isActive && 
      !s.isExpired
    ).toList();
  }
  
  // Get session history for a user
  List<SessionInfo> getSessionHistory(String userId, {int? limit}) {
    var history = _sessions.where((s) => s.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    if (limit != null && history.length > limit) {
      history = history.take(limit).toList();
    }
    
    return history;
  }
  
  // Verify session token
  Future<bool> verifySessionToken(String token) async {
    try {
      final session = _sessions.firstWhere((s) => s.id == token);
      return session.isActive && !session.isExpired;
    } catch (e) {
      return false;
    }
  }
  
  // Clean expired sessions
  Future<void> cleanExpiredSessions() async {
    final now = DateTime.now();
    _sessions.removeWhere((s) => 
      s.expiresAt.isBefore(now.subtract(const Duration(days: 30)))
    );
    await _saveSessions();
    notifyListeners();
  }
  
  // Monitor session timeout
  void _startSessionMonitor() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_currentSession != null && _currentSession!.isExpired) {
        endCurrentSession();
      }
      
      // Auto-refresh if needed
      if (needsRefresh()) {
        refreshSession();
      }
    });
  }
  
  // Monitor user activity
  void _startActivityMonitor() {
    _activityTimer?.cancel();
    _activityTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      final inactivityDuration = DateTime.now().difference(_lastActivity);
      
      // End session after 30 minutes of inactivity
      if (inactivityDuration > const Duration(minutes: 30)) {
        endCurrentSession();
      }
    });
  }
  
  // Get device information
  Future<Map<String, String>> _getDeviceInfo() async {
    final info = <String, String>{};
    
    if (kIsWeb) {
      final webInfo = await _deviceInfo.webBrowserInfo;
      info['deviceId'] = _generateDeviceId(webInfo.userAgent ?? '');
      info['deviceName'] = webInfo.browserName.name;
      info['deviceType'] = 'web';
      info['userAgent'] = webInfo.userAgent ?? '';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await _deviceInfo.androidInfo;
      info['deviceId'] = androidInfo.id;
      info['deviceName'] = '${androidInfo.brand} ${androidInfo.model}';
      info['deviceType'] = 'android';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      info['deviceId'] = iosInfo.identifierForVendor ?? _uuid.v4();
      info['deviceName'] = iosInfo.name;
      info['deviceType'] = 'ios';
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      final windowsInfo = await _deviceInfo.windowsInfo;
      info['deviceId'] = windowsInfo.deviceId;
      info['deviceName'] = windowsInfo.computerName;
      info['deviceType'] = 'windows';
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      final macInfo = await _deviceInfo.macOsInfo;
      info['deviceId'] = macInfo.systemGUID ?? _uuid.v4();
      info['deviceName'] = macInfo.computerName;
      info['deviceType'] = 'macos';
    } else if (defaultTargetPlatform == TargetPlatform.linux) {
      final linuxInfo = await _deviceInfo.linuxInfo;
      info['deviceId'] = linuxInfo.machineId ?? _uuid.v4();
      info['deviceName'] = linuxInfo.prettyName;
      info['deviceType'] = 'linux';
    }
    
    return info;
  }
  
  String _generateDeviceId(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }
  
  // Get IP address (placeholder - would need a real service)
  Future<String?> _getIpAddress() async {
    // In production, call an IP lookup service
    return null;
  }
  
  // Get location (placeholder - would need permissions and service)
  Future<String?> _getLocation() async {
    // In production, use location services with user permission
    return null;
  }
  
  // Save sessions to storage
  Future<void> _saveSessions() async {
    final sessionsJson = _sessions.map((s) => s.toJson()).toList();
    await _storage.write(
      key: _sessionsKey,
      value: jsonEncode(sessionsJson),
    );
  }
  
  // Load sessions from storage
  Future<void> _loadSessions() async {
    try {
      final sessionsStr = await _storage.read(key: _sessionsKey);
      if (sessionsStr != null) {
        final sessionsList = jsonDecode(sessionsStr) as List;
        _sessions = sessionsList.map((s) => SessionInfo.fromJson(s)).toList();
      }
      
      // Load current session
      final currentStr = await _storage.read(key: _currentSessionKey);
      if (currentStr != null) {
        final sessionData = jsonDecode(currentStr);
        _currentSession = SessionInfo.fromJson(sessionData);
        
        // Verify it's still valid
        if (_currentSession!.isExpired) {
          _currentSession = null;
          await _storage.delete(key: _currentSessionKey);
        }
      }
    } catch (e) {
      debugPrint('Error loading sessions: $e');
    }
  }
  
  // Save current session
  Future<void> _saveCurrentSession(SessionInfo session) async {
    await _storage.write(
      key: _currentSessionKey,
      value: jsonEncode(session.toJson()),
    );
  }
  
  @override
  void dispose() {
    _sessionTimer?.cancel();
    _activityTimer?.cancel();
    super.dispose();
  }
}

class SessionInfo {
  final String id;
  final String userId;
  final String? email;
  final String? phoneNumber;
  final String deviceId;
  final String deviceName;
  final String deviceType;
  final String? ipAddress;
  final String? location;
  final String? userAgent;
  final DateTime createdAt;
  DateTime lastActivityAt;
  DateTime expiresAt;
  DateTime? endedAt;
  bool isActive;
  final Map<String, dynamic> metadata;
  
  SessionInfo({
    required this.id,
    required this.userId,
    this.email,
    this.phoneNumber,
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    this.ipAddress,
    this.location,
    this.userAgent,
    required this.createdAt,
    required this.lastActivityAt,
    required this.expiresAt,
    this.endedAt,
    required this.isActive,
    required this.metadata,
  });
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  Duration get timeRemaining => isExpired 
    ? Duration.zero 
    : expiresAt.difference(DateTime.now());
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'email': email,
    'phoneNumber': phoneNumber,
    'deviceId': deviceId,
    'deviceName': deviceName,
    'deviceType': deviceType,
    'ipAddress': ipAddress,
    'location': location,
    'userAgent': userAgent,
    'createdAt': createdAt.toIso8601String(),
    'lastActivityAt': lastActivityAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'isActive': isActive,
    'metadata': metadata,
  };
  
  factory SessionInfo.fromJson(Map<String, dynamic> json) => SessionInfo(
    id: json['id'],
    userId: json['userId'],
    email: json['email'],
    phoneNumber: json['phoneNumber'],
    deviceId: json['deviceId'],
    deviceName: json['deviceName'],
    deviceType: json['deviceType'],
    ipAddress: json['ipAddress'],
    location: json['location'],
    userAgent: json['userAgent'],
    createdAt: DateTime.parse(json['createdAt']),
    lastActivityAt: DateTime.parse(json['lastActivityAt']),
    expiresAt: DateTime.parse(json['expiresAt']),
    endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
    isActive: json['isActive'],
    metadata: json['metadata'] ?? {},
  );
}
