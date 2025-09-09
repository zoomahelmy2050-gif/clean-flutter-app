import 'dart:async';
import 'package:flutter/foundation.dart';

enum JitStatus { pending, approved, denied, expired }

class JitRequest {
  final String id;
  final String user;
  final String reason;
  final DateTime requestedAt;
  final Duration requestedDuration;
  JitStatus status;
  DateTime? approvedUntil;

  JitRequest({
    required this.id,
    required this.user,
    required this.reason,
    required this.requestedAt,
    required this.requestedDuration,
    this.status = JitStatus.pending,
    this.approvedUntil,
  });
}

class JitAccessService with ChangeNotifier {
  final List<JitRequest> _requests = [];
  final Map<String, Timer> _timers = {};

  List<JitRequest> list({int limit = 50}) {
    final copy = List<JitRequest>.from(_requests);
    copy.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return copy.take(limit).toList();
  }

  JitRequest requestElevation({required String user, required String reason, Duration duration = const Duration(minutes: 30)}) {
    final req = JitRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      user: user.toLowerCase(),
      reason: reason,
      requestedAt: DateTime.now(),
      requestedDuration: duration,
    );
    _requests.add(req);
    notifyListeners();
    return req;
  }

  bool approve(String id) {
    final req = _requests.firstWhere((r) => r.id == id, orElse: () => JitRequest(id: '', user: '', reason: '', requestedAt: DateTime.now(), requestedDuration: Duration.zero));
    if (req.id.isEmpty) return false;
    req.status = JitStatus.approved;
    req.approvedUntil = DateTime.now().add(req.requestedDuration);
    _scheduleExpiry(req);
    notifyListeners();
    return true;
  }

  bool deny(String id) {
    final req = _requests.firstWhere((r) => r.id == id, orElse: () => JitRequest(id: '', user: '', reason: '', requestedAt: DateTime.now(), requestedDuration: Duration.zero));
    if (req.id.isEmpty) return false;
    req.status = JitStatus.denied;
    _cancelTimer(id);
    notifyListeners();
    return true;
  }

  bool isElevated(String user) {
    final now = DateTime.now();
    final u = user.toLowerCase();
    final active = _requests.any((r) => r.user == u && r.status == JitStatus.approved && r.approvedUntil != null && now.isBefore(r.approvedUntil!));
    return active;
  }

  void _scheduleExpiry(JitRequest req) {
    _cancelTimer(req.id);
    final until = req.approvedUntil;
    if (until == null) return;
    final dur = until.difference(DateTime.now());
    if (dur.isNegative) {
      _expire(req);
      return;
    }
    _timers[req.id] = Timer(dur, () => _expire(req));
  }

  void _expire(JitRequest req) {
    req.status = JitStatus.expired;
    notifyListeners();
  }

  void _cancelTimer(String id) {
    _timers[id]?.cancel();
    _timers.remove(id);
  }

  @override
  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    super.dispose();
  }
}


