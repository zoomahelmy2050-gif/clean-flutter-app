class XaiDecisionLogEntry {
  final DateTime timestamp;
  final String component; // e.g., AdvancedLoginSecurityService
  final String decision;  // e.g., blockIp, allowLogin
  final Map<String, dynamic> context;
  final String rationale;
  final List<Map<String, dynamic>>? factors; // [{name, value, weight, impact}]

  XaiDecisionLogEntry({
    required this.timestamp,
    required this.component,
    required this.decision,
    required this.context,
    required this.rationale,
    this.factors,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'component': component,
    'decision': decision,
    'context': context,
    'rationale': rationale,
    if (factors != null) 'factors': factors,
  };
}

class XaiLogger {
  static final XaiLogger instance = XaiLogger._internal();
  final List<XaiDecisionLogEntry> _logs = [];

  XaiLogger._internal();

  void log({
    required String component,
    required String decision,
    required Map<String, dynamic> context,
    required String rationale,
    List<Map<String, dynamic>>? factors,
  }) {
    _logs.add(XaiDecisionLogEntry(
      timestamp: DateTime.now(),
      component: component,
      decision: decision,
      context: context,
      rationale: rationale,
      factors: factors,
    ));
    if (_logs.length > 500) {
      _logs.removeAt(0);
    }
  }

  List<Map<String, dynamic>> export({int limit = 100}) {
    final recent = _logs.reversed.take(limit).toList();
    return recent.map((e) => e.toJson()).toList();
  }

  void clear() {
    _logs.clear();
  }
}
