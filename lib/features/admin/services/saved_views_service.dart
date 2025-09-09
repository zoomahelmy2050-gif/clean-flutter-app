import 'package:flutter/foundation.dart';

class SavedView {
  final String id;
  final String name;
  final Map<String, dynamic> query; // arbitrary filters/params
  SavedView({required this.id, required this.name, required this.query});
}

class SavedViewsService with ChangeNotifier {
  final List<SavedView> _views = [];

  List<SavedView> list() => List.unmodifiable(_views);

  void save(String name, Map<String, dynamic> query) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _views.add(SavedView(id: id, name: name, query: Map<String, dynamic>.from(query)));
    notifyListeners();
  }

  bool remove(String id) {
    final idx = _views.indexWhere((v) => v.id == id);
    if (idx == -1) return false;
    _views.removeAt(idx);
    notifyListeners();
    return true;
  }
}


