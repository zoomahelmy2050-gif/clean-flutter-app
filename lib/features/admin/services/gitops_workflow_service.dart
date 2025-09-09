import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:clean_flutter/features/admin/services/dynamic_workflow_service.dart';
import 'package:clean_flutter/locator.dart';

class GitOpsWorkflowService with ChangeNotifier {
  String exportAll() {
    final svc = locator<DynamicWorkflowService>();
    final list = svc.list(limit: 1000);
    final map = {for (final w in list) w.id: w.toJson()};
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  Future<int> importFrom(String jsonText, {bool overwrite = false}) async {
    final data = jsonDecode(jsonText) as Map<String, dynamic>;
    final svc = locator<DynamicWorkflowService>();
    int count = 0;
    for (final entry in data.entries) {
      final wf = DynamicWorkflow.fromJson(Map<String, dynamic>.from(entry.value));
      final existing = svc.getById(wf.id);
      if (existing == null) {
        final ok = await svc.create(wf);
        if (ok) count++;
      } else if (overwrite) {
        final ok = await svc.update(wf);
        if (ok) count++;
      }
    }
    notifyListeners();
    return count;
  }
}


