import 'package:flutter/foundation.dart';
import 'package:clean_flutter/locator.dart';
import 'package:clean_flutter/core/services/advanced_login_security_service.dart';

class GraphNode {
  final String id;
  final String label;
  final String type; // user/ip/device/session
  final Map<String, dynamic> meta;
  GraphNode({required this.id, required this.label, required this.type, Map<String, dynamic>? meta})
      : meta = meta ?? const {};
}

class GraphEdge {
  final String from;
  final String to;
  final String relation; // used_by, originated_from
  GraphEdge({required this.from, required this.to, required this.relation});
}

class SessionGraph with ChangeNotifier {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  SessionGraph({required this.nodes, required this.edges});
}

class SessionGraphService with ChangeNotifier {
  Future<SessionGraph> build({String? seedUser, String? seedIp}) async {
    final sec = locator<AdvancedLoginSecurityService>();
    if (!sec.isInitialized) await sec.initialize();
    final attempts = sec.getRecentAttempts(limit: 100);

    final nodes = <String, GraphNode>{};
    final edges = <GraphEdge>[];

    String deviceIdFromUA(String? ua) {
      if (ua == null || ua.isEmpty) return 'device:unknown';
      return 'device:${ua.hashCode}';
    }

    Map<String, dynamic> enrichIp(String? ip) {
      if (ip == null) return {};
      // simple mock enrichments
      final last = int.tryParse(ip.split('.').lastOrNull ?? '') ?? 0;
      final geo = (last % 3 == 0) ? 'US' : (last % 3 == 1) ? 'EU' : 'APAC';
      final asn = 1000 + (last % 200);
      final isTor = last % 17 == 0;
      return {'geo': geo, 'asn': 'AS$asn', 'tor': isTor};
    }

    for (final a in attempts) {
      if (seedUser != null && a.email != seedUser.toLowerCase()) continue;
      if (seedIp != null && a.ipAddress != seedIp) continue;

      // user node
      nodes.putIfAbsent('user:${a.email}', () => GraphNode(id: 'user:${a.email}', label: a.email, type: 'user'));

      // ip node
      if (a.ipAddress != null) {
        final meta = enrichIp(a.ipAddress);
        nodes.putIfAbsent('ip:${a.ipAddress}', () => GraphNode(
              id: 'ip:${a.ipAddress}',
              label: a.ipAddress!,
              type: 'ip',
              meta: meta,
            ));
        edges.add(GraphEdge(from: 'ip:${a.ipAddress}', to: 'user:${a.email}', relation: 'connected_to'));
      }

      // device node (from UA hash)
      final devId = deviceIdFromUA(a.userAgent);
      nodes.putIfAbsent(devId, () => GraphNode(id: devId, label: devId.replaceFirst('device:', 'device-'), type: 'device'));
      edges.add(GraphEdge(from: devId, to: 'user:${a.email}', relation: 'used_by'));

      // session node
      final sessId = 'sess:${a.id}';
      nodes.putIfAbsent(sessId, () => GraphNode(id: sessId, label: a.id, type: 'session', meta: {'success': a.successful, 'risk': a.riskScore}));
      edges.add(GraphEdge(from: 'user:${a.email}', to: sessId, relation: 'initiated'));
      if (a.ipAddress != null) edges.add(GraphEdge(from: 'ip:${a.ipAddress}', to: sessId, relation: 'origin'));
      edges.add(GraphEdge(from: devId, to: sessId, relation: 'device'));
    }

    return SessionGraph(nodes: nodes.values.toList(), edges: edges);
  }
}

extension _LastOrNull on List<String> {
  String? get lastOrNull => isEmpty ? null : last;
}


