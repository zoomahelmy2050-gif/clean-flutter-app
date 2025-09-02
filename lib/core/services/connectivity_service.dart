import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ConnectivityService extends ChangeNotifier {
  bool _isOnline = true;
  bool _isBackendReachable = true;
  Timer? _connectivityTimer;
  
  bool get isOnline => _isOnline;
  bool get isBackendReachable => _isBackendReachable;
  bool get isFullyConnected => _isOnline && _isBackendReachable;
  
  String get connectionStatus {
    if (!_isOnline) return 'Offline';
    if (!_isBackendReachable) return 'Backend Unavailable';
    return 'Online';
  }

  ConnectivityService() {
    _startConnectivityCheck();
  }

  void _startConnectivityCheck() {
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnectivity(),
    );
    _checkConnectivity(); // Initial check
  }

  Future<void> _checkConnectivity() async {
    final wasOnline = _isOnline;
    final wasBackendReachable = _isBackendReachable;

    // Check internet connectivity
    _isOnline = await _hasInternetConnection();
    
    // Check backend connectivity if online
    if (_isOnline) {
      _isBackendReachable = await _checkBackendHealth();
    } else {
      _isBackendReachable = false;
    }

    // Notify listeners if status changed
    if (wasOnline != _isOnline || wasBackendReachable != _isBackendReachable) {
      notifyListeners();
    }
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _checkBackendHealth() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.100.21:3000/health'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Force connectivity check
  Future<void> checkNow() async {
    await _checkConnectivity();
  }

  // Methods for BackgroundSyncService
  Stream<bool> get connectivityStream {
    return Stream.periodic(const Duration(seconds: 30), (_) => isFullyConnected);
  }

  Future<bool> hasConnection() async {
    await _checkConnectivity();
    return isFullyConnected;
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    super.dispose();
  }
}
