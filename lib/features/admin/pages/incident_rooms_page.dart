import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clean_flutter/locator.dart';
import 'package:clean_flutter/features/admin/services/incident_room_service.dart';
import 'package:clean_flutter/features/admin/services/slack_teams_bridge_service.dart';

class IncidentRoomsPage extends StatefulWidget {
  const IncidentRoomsPage({super.key});

  @override
  State<IncidentRoomsPage> createState() => _IncidentRoomsPageState();
}

class _IncidentRoomsPageState extends State<IncidentRoomsPage> {
  final TextEditingController _roomTitle = TextEditingController();
  final TextEditingController _message = TextEditingController();
  String? _selectedRoomId;

  @override
  Widget build(BuildContext context) {
    final rooms = context.watch<IncidentRoomService>().list(limit: 50);
    final bridge = context.watch<SlackTeamsBridgeService>();
    _selectedRoomId ??= rooms.isNotEmpty ? rooms.first.id : null;
    final selected = rooms.firstWhere((r) => r.id == _selectedRoomId, orElse: () => rooms.isNotEmpty ? rooms.first : IncidentRoom(id: 'none', title: 'No rooms'));

    return Scaffold(
      appBar: AppBar(title: const Text('Incident Rooms')),
      body: Row(
        children: [
          SizedBox(
            width: 300,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(child: TextField(controller: _roomTitle, decoration: const InputDecoration(hintText: 'New room title'))),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          if (_roomTitle.text.trim().isEmpty) return;
                          final r = locator<IncidentRoomService>().create(title: _roomTitle.text.trim());
                          setState(() => _selectedRoomId = r.id);
                          _roomTitle.clear();
                        },
                        child: const Text('Create'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: rooms.length,
                    itemBuilder: (_, i) {
                      final r = rooms[i];
                      return ListTile(
                        selected: r.id == _selectedRoomId,
                        title: Text(r.title),
                        subtitle: Text('Severity: ${r.severity} • Tasks: ${r.tasks.where((t) => !t.done).length}/${r.tasks.length}')
                      ,
                        onTap: () => setState(() => _selectedRoomId = r.id),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: selected.id == 'none' ? const Center(child: Text('No rooms.')) : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(selected.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      PopupMenuButton<String>(
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'slack', child: Text('Connect Slack channel')),
                          PopupMenuItem(value: 'teams', child: Text('Connect Teams channel')),
                        ],
                        onSelected: (v) async {
                          final ctrl = TextEditingController();
                          await showDialog(context: context, builder: (_) => AlertDialog(
                            title: Text('Connect ${v == 'slack' ? 'Slack' : 'Teams'}'),
                            content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Channel name')),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                              FilledButton(onPressed: () async { await bridge.connectChannel(platform: v, channel: ctrl.text.trim()); Navigator.pop(context); }, child: const Text('Connect')),
                            ],
                          ));
                        },
                        icon: const Icon(Icons.link),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _tasksList(selected)),
                      const SizedBox(width: 12),
                      Expanded(child: _messages(selected, bridge)),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _tasksList(IncidentRoom room) {
    final ctrl = TextEditingController();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'New task'))),
              IconButton(onPressed: () { if (ctrl.text.trim().isEmpty) return; locator<IncidentRoomService>().addTask(room.id, ctrl.text.trim()); ctrl.clear(); }, icon: const Icon(Icons.add_task)),
            ]),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: room.tasks.map((t) => CheckboxListTile(
                  value: t.done,
                  onChanged: (v) => locator<IncidentRoomService>().toggleTask(room.id, t.id, v ?? false),
                  title: Text(t.title),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messages(IncidentRoom room, SlackTeamsBridgeService bridge) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bridge & Messages', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(spacing: 6, children: bridge.channels.map((c) => Chip(label: Text('${c['platform']}#${c['channel']}'))).toList()),
            const Divider(),
            Expanded(
              child: ListView(
                children: room.messages.map((m) => ListTile(
                  dense: true,
                  title: Text(m.text),
                  subtitle: Text('${m.author} • ${m.timestamp.toLocal()}'),
                )).toList(),
              ),
            ),
            Row(children: [
              Expanded(child: TextField(controller: _message, decoration: const InputDecoration(hintText: 'Type a message'))),
              IconButton(onPressed: () {
                if (_selectedRoomId == null || _message.text.trim().isEmpty) return;
                locator<IncidentRoomService>().postMessage(_selectedRoomId!, author: 'admin', text: _message.text.trim());
                for (final ch in bridge.channels) {
                  bridge.sendMessage(platform: ch['platform']!, channel: ch['channel']!, text: _message.text.trim());
                }
                _message.clear();
              }, icon: const Icon(Icons.send)),
            ])
          ],
        ),
      ),
    );
  }
}


