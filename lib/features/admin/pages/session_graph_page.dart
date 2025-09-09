import 'package:flutter/material.dart';
import 'package:clean_flutter/locator.dart';
import 'package:clean_flutter/features/admin/services/session_graph_service.dart';

class SessionGraphPage extends StatefulWidget {
  final String? seedUser;
  final String? seedIp;
  const SessionGraphPage({super.key, this.seedUser, this.seedIp});

  @override
  State<SessionGraphPage> createState() => _SessionGraphPageState();
}

class _SessionGraphPageState extends State<SessionGraphPage> {
  late Future<SessionGraph> _future;
  @override
  void initState() {
    super.initState();
    _future = locator<SessionGraphService>().build(seedUser: widget.seedUser, seedIp: widget.seedIp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session Investigation Graph')),
      body: FutureBuilder<SessionGraph>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final g = snap.data!;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(child: Text('Nodes: ${g.nodes.length}  Edges: ${g.edges.length}')),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: () => setState(() => _future = locator<SessionGraphService>().build(seedUser: widget.seedUser, seedIp: widget.seedIp)),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    const Text('Nodes', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...g.nodes.map((n) => ListTile(
                          dense: true,
                          leading: Icon(_iconFor(n.type), color: _colorFor(n.type)),
                          title: Text('${n.label} (${n.type})'),
                          subtitle: n.meta.isEmpty ? null : Text(n.meta.entries.map((e) => '${e.key}: ${e.value}').join(' • ')),
                        )),
                    const Divider(),
                    const Text('Edges', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...g.edges.map((e) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.linear_scale),
                          title: Text('${e.from} → ${e.to}'),
                          subtitle: Text(e.relation),
                        )),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'user':
        return Icons.person;
      case 'ip':
        return Icons.public;
      case 'device':
        return Icons.devices_other;
      case 'session':
        return Icons.event;
      default:
        return Icons.circle;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'user':
        return Colors.blue;
      case 'ip':
        return Colors.orange;
      case 'device':
        return Colors.green;
      case 'session':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}


