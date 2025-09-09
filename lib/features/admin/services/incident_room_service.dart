import 'package:flutter/foundation.dart';

class IncidentTask {
  final String id;
  final String title;
  bool done;
  IncidentTask({required this.id, required this.title, this.done = false});
}

class IncidentMessage {
  final String id;
  final String author;
  final String text;
  final DateTime timestamp;
  IncidentMessage({required this.id, required this.author, required this.text, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}

class IncidentRoom {
  final String id;
  String title;
  String severity; // low/medium/high
  final List<IncidentTask> tasks;
  final List<IncidentMessage> messages;
  IncidentRoom({
    required this.id,
    required this.title,
    this.severity = 'medium',
    List<IncidentTask>? tasks,
    List<IncidentMessage>? messages,
  })  : tasks = tasks ?? <IncidentTask>[],
        messages = messages ?? <IncidentMessage>[];
}

class IncidentRoomService with ChangeNotifier {
  final Map<String, IncidentRoom> _rooms = {};

  List<IncidentRoom> list({int limit = 50}) {
    final xs = _rooms.values.toList();
    xs.sort((a, b) => b.id.compareTo(a.id));
    return xs.take(limit).toList();
  }

  IncidentRoom create({required String title, String severity = 'medium'}) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final room = IncidentRoom(id: id, title: title, severity: severity);
    _rooms[id] = room;
    notifyListeners();
    return room;
  }

  bool addTask(String roomId, String title) {
    final room = _rooms[roomId];
    if (room == null) return false;
    room.tasks.add(IncidentTask(id: DateTime.now().microsecondsSinceEpoch.toString(), title: title));
    notifyListeners();
    return true;
  }

  bool toggleTask(String roomId, String taskId, bool done) {
    final room = _rooms[roomId];
    if (room == null) return false;
    final idx = room.tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return false;
    room.tasks[idx].done = done;
    notifyListeners();
    return true;
  }

  bool postMessage(String roomId, {required String author, required String text}) {
    final room = _rooms[roomId];
    if (room == null) return false;
    room.messages.add(IncidentMessage(id: DateTime.now().microsecondsSinceEpoch.toString(), author: author, text: text));
    notifyListeners();
    return true;
  }
}


