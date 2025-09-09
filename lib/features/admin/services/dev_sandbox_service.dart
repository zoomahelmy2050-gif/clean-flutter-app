import 'package:flutter/foundation.dart';

class SandboxIncident {
  final String id;
  final String title;
  final List<Map<String, dynamic>> events; // timestamp,type,data
  SandboxIncident({required this.id, required this.title, required this.events});
}

class DevSandboxService with ChangeNotifier {
  final List<SandboxIncident> _catalog = [
    SandboxIncident(
      id: 'inc_demo_1',
      title: 'Brute-force login from suspicious IP',
      events: [
        {'ts': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(), 'type': 'login_failed', 'data': {'email': 'alice@example.com', 'ip': '203.0.113.10'}},
        {'ts': DateTime.now().subtract(const Duration(minutes: 14)).toIso8601String(), 'type': 'ip_blocked', 'data': {'ip': '203.0.113.10'}},
      ],
    ),
    SandboxIncident(
      id: 'inc_demo_2',
      title: 'Anomalous spike in EU tenant',
      events: [
        {'ts': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(), 'type': 'anomaly_detected', 'data': {'region': 'EU', 'z': 4.2}},
      ],
    ),
  ];

  List<SandboxIncident> listIncidents() => List.unmodifiable(_catalog);

  Future<Map<String, dynamic>> replay(String incidentId) async {
    final inc = _catalog.firstWhere((e) => e.id == incidentId, orElse: () => SandboxIncident(id: 'none', title: 'not found', events: const []));
    if (inc.id == 'none') return {'ok': false, 'error': 'Incident not found'};
    await Future.delayed(const Duration(milliseconds: 200));
    return {'ok': true, 'replayed_events': inc.events.length, 'title': inc.title};
  }
}


