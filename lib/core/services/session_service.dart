import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../locator.dart';
import '../../features/auth/services/auth_service.dart';

class SessionService extends ChangeNotifier {
  static const String _lastActivityKey = 'last_activity';
  static const String _sessionTimeoutKey = 'session_timeout_minutes';
  static const int _defaultTimeoutMinutes = 15;
  
  Timer? _sessionTimer;
  Timer? _warningTimer;
  DateTime? _lastActivity;
  int _timeoutMinutes = _defaultTimeoutMinutes;
  bool _isWarningShown = false;
  
  // Callback for when session expires
  VoidCallback? onSessionExpired;
  
  SessionService() {
    _loadSettings();
    _startSessionMonitoring();
  }

  int get timeoutMinutes => _timeoutMinutes;
  DateTime? get lastActivity => _lastActivity;
  
  /// Load session settings from storage
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _timeoutMinutes = prefs.getInt(_sessionTimeoutKey) ?? _defaultTimeoutMinutes;
    
    final lastActivityMs = prefs.getInt(_lastActivityKey);
    if (lastActivityMs != null) {
      _lastActivity = DateTime.fromMillisecondsSinceEpoch(lastActivityMs);
    }
  }

  /// Set session timeout duration
  Future<void> setSessionTimeout(int minutes) async {
    _timeoutMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionTimeoutKey, minutes);
    
    // Restart monitoring with new timeout
    _startSessionMonitoring();
    notifyListeners();
  }

  /// Record user activity
  Future<void> recordActivity() async {
    _lastActivity = DateTime.now();
    _isWarningShown = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastActivityKey, _lastActivity!.millisecondsSinceEpoch);
    
    // Reset timers
    _startSessionMonitoring();
  }

  /// Start monitoring session timeout
  void _startSessionMonitoring() {
    _sessionTimer?.cancel();
    _warningTimer?.cancel();
    
    if (_timeoutMinutes <= 0) return; // Disabled
    
    final timeoutDuration = Duration(minutes: _timeoutMinutes);
    final warningDuration = Duration(minutes: _timeoutMinutes - 2); // 2 min warning
    
    // Set warning timer (2 minutes before timeout)
    if (_timeoutMinutes > 2) {
      _warningTimer = Timer(warningDuration, () {
        if (!_isWarningShown) {
          _showSessionWarning();
        }
      });
    }
    
    // Set session timeout timer
    _sessionTimer = Timer(timeoutDuration, () {
      _handleSessionTimeout();
    });
  }

  /// Show session timeout warning
  void _showSessionWarning() {
    _isWarningShown = true;
    // This will be handled by the UI layer
    notifyListeners();
  }

  /// Handle session timeout
  Future<void> _handleSessionTimeout() async {
    final authService = locator<AuthService>();
    await authService.logout();
    
    // Clear session data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastActivityKey);
    
    _lastActivity = null;
    
    // Notify UI
    onSessionExpired?.call();
    notifyListeners();
  }

  /// Check if session is about to expire (within 2 minutes)
  bool get isSessionWarning {
    if (_lastActivity == null || _timeoutMinutes <= 0) return false;
    
    final now = DateTime.now();
    final timeSinceActivity = now.difference(_lastActivity!);
    final warningThreshold = Duration(minutes: _timeoutMinutes - 2);
    
    return timeSinceActivity >= warningThreshold && 
           timeSinceActivity < Duration(minutes: _timeoutMinutes);
  }

  /// Get remaining session time in minutes
  int get remainingMinutes {
    if (_lastActivity == null || _timeoutMinutes <= 0) return -1;
    
    final now = DateTime.now();
    final timeSinceActivity = now.difference(_lastActivity!);
    final timeoutDuration = Duration(minutes: _timeoutMinutes);
    final remaining = timeoutDuration - timeSinceActivity;
    
    return remaining.inMinutes.clamp(0, _timeoutMinutes);
  }

  /// Extend session (reset activity)
  Future<void> extendSession() async {
    await recordActivity();
  }

  /// Disable session timeout
  Future<void> disableTimeout() async {
    await setSessionTimeout(0);
  }

  /// Enable session timeout with default duration
  Future<void> enableTimeout([int? minutes]) async {
    await setSessionTimeout(minutes ?? _defaultTimeoutMinutes);
  }

  /// Check if session timeout is enabled
  bool get isTimeoutEnabled => _timeoutMinutes > 0;

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _warningTimer?.cancel();
    super.dispose();
  }
}

/// Widget to wrap app and handle session monitoring
class SessionWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSessionExpired;

  const SessionWrapper({
    super.key,
    required this.child,
    this.onSessionExpired,
  });

  @override
  State<SessionWrapper> createState() => _SessionWrapperState();
}

class _SessionWrapperState extends State<SessionWrapper> with WidgetsBindingObserver {
  late SessionService _sessionService;

  @override
  void initState() {
    super.initState();
    _sessionService = locator<SessionService>();
    _sessionService.onSessionExpired = widget.onSessionExpired;
    _sessionService.addListener(_onSessionChange);
    WidgetsBinding.instance.addObserver(this);
    
    // Record initial activity
    _sessionService.recordActivity();
  }

  @override
  void dispose() {
    _sessionService.removeListener(_onSessionChange);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Record activity when app comes to foreground
      _sessionService.recordActivity();
    }
  }

  void _onSessionChange() {
    if (_sessionService.isSessionWarning && mounted) {
      _showSessionWarningDialog();
    }
  }

  void _showSessionWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Session Timeout Warning'),
          ],
        ),
        content: Text(
          'Your session will expire in ${_sessionService.remainingMinutes} minutes due to inactivity. '
          'Would you like to extend your session?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Let session expire naturally
            },
            child: const Text('Logout'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sessionService.extendSession();
            },
            child: const Text('Stay Active'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _sessionService.recordActivity(),
      onPanDown: (_) => _sessionService.recordActivity(),
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
