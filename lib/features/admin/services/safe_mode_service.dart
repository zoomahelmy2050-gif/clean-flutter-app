import 'dart:async';
import 'package:flutter/foundation.dart';

class SafeModeState {
  final bool enabled;
  final DateTime? expiresAt;
  const SafeModeState({required this.enabled, this.expiresAt});
}

class SafeModeService with ChangeNotifier {
  SafeModeState _state = const SafeModeState(enabled: false, expiresAt: null);
  Timer? _timer;

  SafeModeState get state => _state;

  void enable({Duration duration = const Duration(minutes: 15)}) {
    final expiry = DateTime.now().add(duration);
    _state = SafeModeState(enabled: true, expiresAt: expiry);
    _timer?.cancel();
    _timer = Timer(duration, _autoDisable);
    notifyListeners();
  }

  void _autoDisable() {
    _state = const SafeModeState(enabled: false, expiresAt: null);
    notifyListeners();
  }

  void disable() {
    _timer?.cancel();
    _state = const SafeModeState(enabled: false, expiresAt: null);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}


