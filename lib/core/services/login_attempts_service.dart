import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class LoginAttempt {
  final String email;
  final DateTime timestamp;
  final bool successful;
  final String? ipAddress;
  final String? userAgent;

  LoginAttempt({
    required this.email,
    required this.timestamp,
    required this.successful,
    this.ipAddress,
    this.userAgent,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'timestamp': timestamp.toIso8601String(),
    'successful': successful,
    'ipAddress': ipAddress,
    'userAgent': userAgent,
  };

  factory LoginAttempt.fromJson(Map<String, dynamic> json) => LoginAttempt(
    email: json['email'],
    timestamp: DateTime.parse(json['timestamp']),
    successful: json['successful'],
    ipAddress: json['ipAddress'],
    userAgent: json['userAgent'],
  );
}

class LoginAttemptsService with ChangeNotifier {
  static const _attemptsKey = 'login_attempts_v1';
  static const _blockedUsersKey = 'blocked_users_v1';
  
  // Configuration
  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  static const Duration attemptWindowDuration = Duration(minutes: 30);
  
  late SharedPreferences _prefs;
  final List<LoginAttempt> _attempts = [];
  final Map<String, DateTime> _lockedUsers = {};
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    await _loadAttempts();
    await _loadLockedUsers();
    
    // Clean up old attempts and expired lockouts
    await _cleanupOldData();
    
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadAttempts() async {
    try {
      final attemptsJson = _prefs.getString(_attemptsKey);
      if (attemptsJson != null) {
        final List<dynamic> attemptsList = jsonDecode(attemptsJson);
        _attempts.clear();
        _attempts.addAll(
          attemptsList.map((json) => LoginAttempt.fromJson(json)).toList(),
        );
      }
    } catch (e) {
      developer.log('Error loading login attempts: $e', name: 'LoginAttemptsService');
      await _prefs.remove(_attemptsKey);
    }
  }

  Future<void> _loadLockedUsers() async {
    try {
      final lockedJson = _prefs.getString(_blockedUsersKey);
      if (lockedJson != null) {
        final Map<String, dynamic> lockedMap = jsonDecode(lockedJson);
        _lockedUsers.clear();
        lockedMap.forEach((email, timestampStr) {
          _lockedUsers[email] = DateTime.parse(timestampStr);
        });
      }
    } catch (e) {
      developer.log('Error loading locked users: $e', name: 'LoginAttemptsService');
      await _prefs.remove(_blockedUsersKey);
    }
  }

  Future<void> _saveAttempts() async {
    try {
      final attemptsJson = jsonEncode(_attempts.map((a) => a.toJson()).toList());
      await _prefs.setString(_attemptsKey, attemptsJson);
    } catch (e) {
      developer.log('Error saving login attempts: $e', name: 'LoginAttemptsService');
    }
  }

  Future<void> _saveLockedUsers() async {
    try {
      final lockedMap = <String, String>{};
      _lockedUsers.forEach((email, timestamp) {
        lockedMap[email] = timestamp.toIso8601String();
      });
      await _prefs.setString(_blockedUsersKey, jsonEncode(lockedMap));
    } catch (e) {
      developer.log('Error saving locked users: $e', name: 'LoginAttemptsService');
    }
  }

  Future<void> _cleanupOldData() async {
    final now = DateTime.now();
    bool needsSave = false;

    // Remove old attempts (older than attempt window)
    _attempts.removeWhere((attempt) {
      final isOld = now.difference(attempt.timestamp) > attemptWindowDuration;
      if (isOld) needsSave = true;
      return isOld;
    });

    // Remove expired lockouts
    final expiredUsers = <String>[];
    _lockedUsers.forEach((email, lockTime) {
      if (now.difference(lockTime) > lockoutDuration) {
        expiredUsers.add(email);
      }
    });

    for (final email in expiredUsers) {
      _lockedUsers.remove(email);
      needsSave = true;
    }

    if (needsSave) {
      await _saveAttempts();
      await _saveLockedUsers();
      notifyListeners();
    }
  }

  /// Record a login attempt
  Future<void> recordAttempt({
    required String email,
    required bool successful,
    String? ipAddress,
    String? userAgent,
  }) async {
    if (!_isInitialized) {
      developer.log('Warning: LoginAttemptsService not initialized. Cannot record attempt.', name: 'LoginAttemptsService');
      return;
    }
    
    final e = email.toLowerCase();
    
    // Don't record attempts for admin user to prevent lockout
    if (e == 'env.hygiene@gmail.com') {
      developer.log('Skipping attempt recording for admin user', name: 'LoginAttemptsService');
      return;
    }
    
    final attempt = LoginAttempt(
      email: e,
      timestamp: DateTime.now(),
      successful: successful,
      ipAddress: ipAddress,
      userAgent: userAgent,
    );
    
    _attempts.add(attempt);
    
    // Save attempts to persistent storage
    await _saveAttempts();
    
    developer.log('Recording login attempt for ${attempt.email}: ${successful ? "SUCCESS" : "FAILED"}', name: 'LoginAttemptsService');
    
    // Check if we need to lock the user
    if (!successful) {
      final recentFailedAttempts = getFailedAttemptsCount(email);
      developer.log('Failed attempts for $email: $recentFailedAttempts/$maxFailedAttempts', name: 'LoginAttemptsService');
      
      if (recentFailedAttempts >= maxFailedAttempts) {
        await _lockUser(email);
      }
    }
    notifyListeners();
  }

  Future<void> _lockUser(String email) async {
    final now = DateTime.now();
    _lockedUsers[email.toLowerCase()] = now.add(lockoutDuration);
    await _saveLockedUsers();
    developer.log('User $email locked due to too many failed attempts', name: 'LoginAttemptsService');
  }

  /// Check if a user is currently locked out
  bool checkIfUserLocked(String email) {
    final e = email.toLowerCase();
    
    // Admin user is never locked out
    if (e == 'env.hygiene@gmail.com') {
      return false;
    }
    
    if (_lockedUsers.containsKey(e)) {
      final lockoutExpiry = _lockedUsers[e]!;
      if (DateTime.now().isBefore(lockoutExpiry)) {
        return true;
      } else {
        // Lockout has expired, remove from locked users
        _lockedUsers.remove(e);
        _saveLockedUsers();
      }
    }
    
    return false;
  }

  /// Get remaining lockout time for a user
  Duration? getRemainingLockoutTime(String email) {
    final e = email.toLowerCase();
    
    // Admin user is never locked out
    if (e == 'env.hygiene@gmail.com') {
      return null;
    }
    
    if (_lockedUsers.containsKey(e)) {
      final lockoutExpiry = _lockedUsers[e]!;
      final remainingTime = lockoutExpiry.difference(DateTime.now());
      if (remainingTime.inMinutes > 0) {
        return remainingTime;
      } else {
        // Lockout has expired, remove from locked users
        _lockedUsers.remove(e);
        _saveLockedUsers();
      }
    }
    
    return null;
  }

  /// Get failed attempt count for a user in the current window
  int getFailedAttemptsCount(String email) {
    final e = email.toLowerCase();
    final now = DateTime.now();
    final count = _attempts.where((attempt) =>
      attempt.email == e &&
      !attempt.successful &&
      now.difference(attempt.timestamp) <= attemptWindowDuration
    ).length;
    developer.log('Failed attempts count for $e: $count', name: 'LoginAttemptsService');
    return count;
  }

  /// Get recent login attempts for a user
  List<LoginAttempt> getRecentAttempts(String email, {int limit = 10}) {
    final e = email.toLowerCase();
    final attempts = _attempts
        .where((attempt) => attempt.email == e)
        .toList()
        .reversed
        .take(limit)
        .toList();
    developer.log('Recent attempts for $e: ${attempts.length}', name: 'LoginAttemptsService');
    return attempts;
  }

  /// Get all recent attempts (admin function)
  List<LoginAttempt> getAllRecentAttempts({int limit = 50}) {
    final sortedAttempts = List<LoginAttempt>.from(_attempts);
    sortedAttempts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sortedAttempts.take(limit).toList();
  }

  /// Manually unlock a user (admin function)
  Future<void> unlockUser(String email) async {
    final e = email.toLowerCase();
    _lockedUsers.remove(e);
    await _saveLockedUsers();
    developer.log('User $e unlocked', name: 'LoginAttemptsService');
    notifyListeners();
  }

  /// Clear all attempts for a user (admin function)
  Future<void> clearUserAttempts(String email) async {
    _attempts.removeWhere((attempt) => attempt.email == email.toLowerCase());
    _lockedUsers.remove(email.toLowerCase());
    await _saveAttempts();
    await _saveLockedUsers();
    notifyListeners();
  }

  /// Get security statistics
  Map<String, dynamic> getSecurityStats() {
    final now = DateTime.now();
    final recentAttempts = _attempts.where((attempt) =>
      now.difference(attempt.timestamp) <= Duration(hours: 24)
    ).toList();

    final failedAttempts = recentAttempts.where((a) => !a.successful).length;
    final successfulAttempts = recentAttempts.where((a) => a.successful).length;
    final uniqueUsers = recentAttempts.map((a) => a.email).toSet().length;

    return {
      'totalAttempts24h': recentAttempts.length,
      'failedAttempts24h': failedAttempts,
      'successfulAttempts24h': successfulAttempts,
      'uniqueUsers24h': uniqueUsers,
      'currentlyLocked': _lockedUsers.length,
      'failureRate': recentAttempts.isEmpty ? 0.0 : failedAttempts / recentAttempts.length,
    };
  }

  /// Check if login should be allowed (not locked)
  Map<String, dynamic> checkLoginAllowed(String email) {
    final e = email.toLowerCase();
    
    // Admin user is always allowed to login
    if (e == 'env.hygiene@gmail.com') {
      return {
        'allowed': true,
        'attemptsRemaining': 999,
        'failedAttempts': 0,
      };
    }
    
    // Check if user is currently locked
    if (checkIfUserLocked(e)) {
      final lockoutExpiry = _lockedUsers[e]!;
      final remainingMinutes = lockoutExpiry.difference(DateTime.now()).inMinutes;
      return {
        'allowed': false,
        'reason': 'Account locked due to too many failed attempts',
        'remainingLockoutTime': remainingMinutes,
        'attemptsRemaining': 0,
        'failedAttempts': maxFailedAttempts,
      };
    }
    
    final failedCount = getFailedAttemptsCount(email);
    return {
      'allowed': true,
      'attemptsRemaining': maxFailedAttempts - failedCount,
      'failedAttempts': failedCount,
    };
  }
}
