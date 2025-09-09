import 'package:flutter/material.dart';
import 'package:clean_flutter/locator.dart';
import 'package:clean_flutter/features/admin/services/dynamic_workflow_service.dart';

class WorkflowBuilderPage extends StatefulWidget {
  const WorkflowBuilderPage({super.key});

  @override
  State<WorkflowBuilderPage> createState() => _WorkflowBuilderPageState();
}

class _WorkflowBuilderPageState extends State<WorkflowBuilderPage> {
  late final DynamicWorkflowService _service;
  late List<DynamicWorkflow> _workflows;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _service = locator<DynamicWorkflowService>();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _workflows = _service.list(limit: 200);
    });
  }

  Future<void> _createSampleWorkflow() async {
    setState(() => _busy = true);
    final wf = DynamicWorkflow(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Mitigate suspicious login',
      description: 'Isolate, analyze, and notify admins',
      steps: [
        DynamicWorkflowStep(
          id: 's1',
          name: 'Isolate threat',
          action: 'security.isolate_threat',
          onSuccess: 's2',
          onFailure: null,
        ),
        DynamicWorkflowStep(
          id: 's2',
          name: 'Deep analysis',
          action: 'security.deep_analysis',
          onSuccess: 's3',
          onFailure: null,
        ),
        DynamicWorkflowStep(
          id: 's3',
          name: 'Notify admins',
          action: 'notification.alert_admins',
          parameters: {'priority': 'high'},
          onSuccess: null,
          onFailure: null,
        ),
      ],
    );
    await _service.create(wf);
    _refresh();
    setState(() => _busy = false);
  }

  Future<void> _editName(DynamicWorkflow wf) async {
    final controller = TextEditingController(text: wf.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Workflow'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      final updated = DynamicWorkflow(
        id: wf.id,
        name: newName,
        description: wf.description,
        steps: wf.steps,
        triggers: wf.triggers,
        metadata: wf.metadata,
        createdAt: wf.createdAt,
        updatedAt: DateTime.now(),
      );
      await _service.update(updated);
      _refresh();
    }
  }

  Future<void> _dryRun(DynamicWorkflow wf) async {
    setState(() => _busy = true);
    final pre = _service.preflight(wf.id);
    setState(() => _busy = false);
    if (!mounted) return;
    if (pre['ok'] != true) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Preflight Warnings'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Text((pre['warnings'] as List?)?.join('\n') ?? 'Unknown warnings'),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      );
    }
    setState(() => _busy = true);
    final res = await _service.execute(wf.id, context: {'dryRun': true, 'source': 'builder'});
    setState(() => _busy = false);
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dry Run Result'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(child: Text(res.toString())),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _canaryExecute(DynamicWorkflow wf) async {
    setState(() => _busy = true);
    final res = await _service.execute(wf.id, context: {'canary': true, 'canaryPercent': 5, 'source': 'builder'});
    setState(() => _busy = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Canary executed: ${wf.name} → ${res['success'] == true ? 'OK' : 'Failed'}')),
    );
  }

  Future<void> _delete(DynamicWorkflow wf) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workflow?'),
        content: Text('Are you sure you want to delete "${wf.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await _service.remove(wf.id);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workflow Builder'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _createSampleWorkflow,
            icon: const Icon(Icons.add),
            tooltip: 'Create Sample Workflow',
          ),
        ],
      ),
      body: _workflows.isEmpty
          ? const Center(child: Text('No workflows yet. Use + to create a sample.'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _workflows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final wf = _workflows[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(wf.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                            IconButton(onPressed: () => _editName(wf), icon: const Icon(Icons.edit), tooltip: 'Rename'),
                            IconButton(onPressed: () => _delete(wf), icon: const Icon(Icons.delete_outline), tooltip: 'Delete'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(wf.description, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.icon(
                              onPressed: _busy ? null : () => _dryRun(wf),
                              icon: const Icon(Icons.play_circle_fill),
                              label: const Text('Dry Run'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _busy ? null : () => _canaryExecute(wf),
                              icon: const Icon(Icons.scatter_plot),
                              label: const Text('Canary 5%'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Steps:', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Text('${wf.steps.length}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}


