import 'package:flutter/material.dart';
import 'package:clean_flutter/locator.dart';
import 'package:clean_flutter/features/admin/services/compliance_service.dart';
import 'package:clean_flutter/features/admin/services/dynamic_workflow_service.dart';
import 'package:clean_flutter/core/services/xai_logger.dart';
import 'package:clean_flutter/core/models/compliance_models.dart';
import 'package:clean_flutter/features/admin/pages/workflow_builder_page.dart';
import 'package:clean_flutter/features/admin/services/evidence_pack_service.dart';
import 'package:clean_flutter/features/admin/services/safe_mode_service.dart';
import 'package:clean_flutter/features/admin/pages/session_graph_page.dart';
import 'package:clean_flutter/features/admin/services/jit_access_service.dart';
import 'package:clean_flutter/features/admin/pages/slo_dashboard_page.dart';
import 'package:provider/provider.dart';
import 'package:clean_flutter/features/admin/services/safety_validation_service.dart';
import 'package:clean_flutter/features/admin/pages/incident_rooms_page.dart';
import 'package:clean_flutter/features/admin/services/pii_redaction_service.dart';
import 'package:clean_flutter/features/admin/services/dev_sandbox_service.dart';
import 'package:clean_flutter/features/admin/services/gitops_workflow_service.dart';
import 'package:clean_flutter/features/admin/services/saved_views_service.dart';
import 'package:clean_flutter/features/admin/widgets/command_palette.dart';
import 'package:clean_flutter/features/admin/services/dev_sandbox_service.dart';
import 'package:clean_flutter/features/admin/services/gitops_workflow_service.dart';

class AdminSecurityCenterPage extends StatefulWidget {
  const AdminSecurityCenterPage({super.key});

  @override
  State<AdminSecurityCenterPage> createState() => _AdminSecurityCenterPageState();
}

class _AdminSecurityCenterPageState extends State<AdminSecurityCenterPage> {
  ComplianceReport? _report;
  List<DynamicWorkflow> _workflows = const [];
  List<Map<String, dynamic>> _xaiLogs = const [];
  bool _loadingCompliance = false;
  bool _runningWorkflow = false;
  bool _generatingPack = false;

  @override
  void initState() {
    super.initState();
    _refreshWorkflows();
    _refreshXaiLogs();
  }

  Future<void> _refreshWorkflows() async {
    final svc = locator<DynamicWorkflowService>();
    setState(() {
      _workflows = svc.list(limit: 100);
    });
  }

  Future<void> _refreshXaiLogs() async {
    final logs = XaiLogger.instance.export(limit: 50);
    setState(() {
      _xaiLogs = logs;
    });
  }

  Future<void> _runCompliance() async {
    setState(() {
      _loadingCompliance = true;
    });
    try {
      final svc = locator<ComplianceService>();
      final r = await svc.runChecks();
      setState(() {
        _report = r;
      });
    } finally {
      setState(() {
        _loadingCompliance = false;
      });
    }
  }

  Future<void> _executeWorkflow(DynamicWorkflow wf) async {
    setState(() {
      _runningWorkflow = true;
    });
    try {
      final svc = locator<DynamicWorkflowService>();
      await svc.execute(wf.id, context: {'source': 'admin_ui'});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Executed workflow: ${wf.name}')),
      );
    } finally {
      setState(() {
        _runningWorkflow = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Security Center'),
        actions: [
          IconButton(
            tooltip: 'Command Palette (Ctrl/Cmd+K)',
            onPressed: _openCommandPalette,
            icon: const Icon(Icons.keyboard_command_key),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/anomaly-dashboard'),
                  icon: const Icon(Icons.analytics),
                  label: const Text('Anomaly Dashboard'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SessionGraphPage()),
                    );
                  },
                  icon: const Icon(Icons.graphic_eq),
                  label: const Text('Session Graph'),
                ),
                const SizedBox(width: 12),
                Consumer<SafeModeService>(
                  builder: (context, safe, _) {
                    final enabled = safe.state.enabled;
                    final expires = safe.state.expiresAt;
                    return Tooltip(
                      message: enabled && expires != null ? 'Auto-revert at ${expires.toLocal()}' : 'Enable safe mode (auto-reverts)',
                      child: SizedBox(
                        width: 220,
                        child: SwitchListTile.adaptive(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(enabled ? 'Safe Mode ON' : 'Safe Mode OFF'),
                          value: enabled,
                          onChanged: (v) {
                            if (v) {
                              locator<SafeModeService>().enable(duration: const Duration(minutes: 15));
                            } else {
                              locator<SafeModeService>().disable();
                            }
                            setState(() {});
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _loadingCompliance ? null : _runCompliance,
                  child: _loadingCompliance ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Run Compliance Checks'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _generatingPack ? null : _generateEvidencePack,
                  icon: const Icon(Icons.archive),
                  label: _generatingPack ? const Text('Generating...') : const Text('Evidence Pack'),
                ),
                if (_report != null)
                  Chip(label: Text('Score: ${((_report!.findings['score'] ?? 0.0) as num).toStringAsFixed(0)}%')),
              ],
            ),
            const SizedBox(height: 8),
            if (_report != null) _buildComplianceReport(_report!),
            const Divider(height: 32),
            Row(
              children: [
                const Text('Workflows', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const IncidentRoomsPage()));
                  },
                  icon: const Icon(Icons.meeting_room_outlined),
                  label: const Text('Incident Rooms'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WorkflowBuilderPage()),
                    );
                    _refreshWorkflows();
                  },
                  icon: const Icon(Icons.build),
                  label: const Text('Open Builder'),
                ),
                IconButton(onPressed: _refreshWorkflows, icon: const Icon(Icons.refresh)),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: _buildWorkflowsSection(),
              );
            }),
            const Divider(height: 32),
            LayoutBuilder(builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: _buildJitAccessSection(),
              );
            }),
            const Divider(height: 32),
            LayoutBuilder(builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: _buildSafetyValidationsSection(),
              );
            }),
            const Divider(height: 32),
            _buildPiiRedactionSection(),
            const Divider(height: 32),
            _buildSavedViewsSection(),
            const Divider(height: 32),
            Row(
              children: [
                const Text('Observability', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SloDashboardPage())),
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('Open SLO Dashboard'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 32),
            Row(
              children: [
                const Text('XAI Decision Logs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(onPressed: _refreshXaiLogs, icon: const Icon(Icons.refresh)),
              ],
            ),
            const SizedBox(height: 8),
            _buildXaiLogsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildJitAccessSection() {
    return Consumer<JitAccessService>(builder: (context, jit, _) {
      final items = jit.list(limit: 20);
      final userCtrl = TextEditingController();
      final reasonCtrl = TextEditingController();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('JIT Admin Elevation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Request Admin Elevation'),
                      content: SizedBox(
                        width: 400,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'User email')),
                            TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Reason')),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        FilledButton(onPressed: () { locator<JitAccessService>().requestElevation(user: userCtrl.text.trim(), reason: reasonCtrl.text.trim()); Navigator.pop(context); }, child: const Text('Submit')),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.vpn_key),
                label: const Text('Request'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty) const Text('No JIT requests.') else ...items.map((r) => Card(
            child: ListTile(
              title: Text('${r.user} • ${r.status.name.toUpperCase()}'),
              subtitle: Text('Reason: ${r.reason} • Requested: ${r.requestedAt} • Duration: ${r.requestedDuration.inMinutes}m'
                  '${r.approvedUntil != null ? ' • Until: ${r.approvedUntil}' : ''}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Approve',
                    onPressed: r.status == JitStatus.pending ? () => locator<JitAccessService>().approve(r.id) : null,
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                  IconButton(
                    tooltip: 'Deny',
                    onPressed: r.status == JitStatus.pending ? () => locator<JitAccessService>().deny(r.id) : null,
                    icon: const Icon(Icons.cancel, color: Colors.red),
                  ),
                ],
              ),
            ),
          )),
        ],
      );
    });
  }

  Widget _buildSafetyValidationsSection() {
    final svc = locator<SafetyValidationService>();
    final workflows = _workflows;
    if (workflows.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Text('Safety Validations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ...workflows.take(5).map((wf) {
          final pre = svc.preflight(wf.id);
          final sim = svc.simulateBlastRadius(wf.id, scope: {'canary_percent': 5});
          return Card(
            child: ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: Text('Preflight: ${wf.name} • ${pre.wouldSucceed ? 'OK' : 'Risk'}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pre.warnings.isNotEmpty) Text('Warnings: ${pre.warnings.join('; ')}'),
                  Text('Steps: ${pre.metrics['steps']} • External: ${pre.metrics['external_calls']} • Est: ${pre.metrics['estimated_duration_ms']}ms'),
                  Text('Blast radius (5%): users=${sim.estimatedAffectedUsers}, sessions=${sim.estimatedAffectedSessions}, risk=${sim.riskLevel}'),
                ],
              ),
              trailing: TextButton.icon(
                onPressed: () async {
                  final dry = locator<DynamicWorkflowService>().preflight(wf.id);
                  await showDialog(context: context, builder: (_) => AlertDialog(
                    title: const Text('Dry Run Result'),
                    content: SizedBox(width: 420, child: SingleChildScrollView(child: Text(dry['warnings']?.join('\n') ?? dry.toString()))),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                  ));
                },
                icon: const Icon(Icons.science),
                label: const Text('Dry Run'),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPiiRedactionSection() {
    final svc = locator<PiiRedactionService>();
    final sample = 'Contact: john.doe@example.com, phone +1 415-555-1234, IP 192.168.0.10, card 4242 4242 4242 4242';
    final rules = svc.availableRules;
    final selected = rules.map((r) => r.id).toList();
    final prev = svc.preview(sample, ruleIds: selected);
    final counts = (prev['counts'] as Map<String, int>);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PII Redaction Preview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: rules.map((r) => Chip(label: Text('${r.label} (${counts[r.id] ?? 0})'))).toList()),
            const SizedBox(height: 8),
            const Text('Input:'),
            Text(sample),
            const SizedBox(height: 8),
            const Text('Redacted:'),
            Text('${prev['output']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedViewsSection() {
    final svc = locator<SavedViewsService>();
    final views = svc.list();
    final nameCtrl = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('Saved Views', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          FilledButton.icon(
            onPressed: () async {
              await showDialog(context: context, builder: (_) => AlertDialog(
                title: const Text('Save Current View'),
                content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  FilledButton(onPressed: () { locator<SavedViewsService>().save(nameCtrl.text.trim().isEmpty ? 'Untitled' : nameCtrl.text.trim(), {
                    'hasReport': _report != null,
                    'workflowsCount': _workflows.length,
                  }); Navigator.pop(context); setState(() {}); }, child: const Text('Save')),
                ],
              ));
            },
            icon: const Icon(Icons.save),
            label: const Text('Save View'),
          ),
        ]),
        const SizedBox(height: 8),
        if (views.isEmpty) const Text('No saved views.') else ...views.map((v) => Card(
          child: ListTile(
            leading: const Icon(Icons.visibility_outlined),
            title: Text(v.name),
            subtitle: Text('Query: ${v.query}'),
            trailing: IconButton(
              tooltip: 'Delete',
              onPressed: () { locator<SavedViewsService>().remove(v.id); setState(() {}); },
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        )),
      ],
    );
  }

  void _openCommandPalette() {
    final commands = <CommandItem>[
      CommandItem(title: 'Run Compliance Checks', subtitle: 'Compliance', icon: Icons.rule, onRun: (ctx) async { await _runCompliance(); }),
      CommandItem(title: 'Open Anomaly Dashboard', subtitle: 'Dashboards', icon: Icons.analytics, onRun: (ctx) async { Navigator.of(ctx).pushNamed('/anomaly-dashboard'); }),
      CommandItem(title: 'Open Session Graph', subtitle: 'Investigations', icon: Icons.graphic_eq, onRun: (ctx) async { Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const SessionGraphPage())); }),
      CommandItem(title: 'Open SLO Dashboard', subtitle: 'Observability', icon: Icons.analytics_outlined, onRun: (ctx) async { Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const SloDashboardPage())); }),
      CommandItem(title: 'Export Workflows (GitOps)', subtitle: 'Workflows', icon: Icons.file_download, onRun: (ctx) async { final json = locator<GitOpsWorkflowService>().exportAll(); await showDialog(context: ctx, builder: (_) => AlertDialog(title: const Text('Exported Workflows'), content: SizedBox(width: 500, child: SingleChildScrollView(child: Text(json))), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],)); }),
      CommandItem(title: 'Replay Sample Incident', subtitle: 'Dev Sandbox', icon: Icons.play_circle_outline, onRun: (ctx) async { final sb = locator<DevSandboxService>(); final items = sb.listIncidents(); if (items.isNotEmpty) { final r = await sb.replay(items.first.id); ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(r['ok'] == true ? 'Replayed ${r['replayed_events']} events' : 'Replay failed'))); } }),
    ];
    showDialog(context: context, builder: (_) => CommandPalette(commands: commands));
  }

  Future<void> _generateEvidencePack() async {
    setState(() => _generatingPack = true);
    try {
      final svc = locator<EvidencePackService>();
      final pack = await svc.generate(incidentContext: {
        'requestedBy': 'admin_ui',
      });
      final pretty = svc.toPrettyJson(pack);
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Incident Evidence Pack'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(child: Text(pretty)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _generatingPack = false);
    }
  }

  Widget _buildComplianceReport(ComplianceReport report) {
    final scoreVal = (report.findings['score'] ?? 0.0) as num;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Generated: ${report.generatedAt.toLocal()} • Score: ${scoreVal.toStringAsFixed(0)}%'),
            const SizedBox(height: 8),
            ...((report.findings['results'] as List?)?.map((r) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon((r['passed'] == true) ? Icons.check_circle : Icons.error, color: (r['passed'] == true) ? Colors.green : Colors.red),
                  title: Text('${r['name']}'),
                  subtitle: r['details'] != null ? Text('${r['details']}') : null,
                  trailing: Text('${(r['severity'] ?? '').toString().toUpperCase()}'),
                )) ?? const <Widget>[]) ,
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowsSection() {
    if (_workflows.isEmpty) {
      return const Text('No workflows found. Use AI chat command to generate or create one.');
    }
    return Column(
      children: _workflows.map((wf) => Card(
        child: ListTile(
          title: Text(wf.name),
          subtitle: Text(wf.description),
          trailing: ElevatedButton(
            onPressed: _runningWorkflow ? null : () => _executeWorkflow(wf),
            child: _runningWorkflow ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Execute'),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildXaiLogsSection() {
    if (_xaiLogs.isEmpty) {
      return const Text('No recent XAI decision logs.');
    }
    return Column(
      children: _xaiLogs.map((e) {
        final factors = (e['factors'] as List?)?.cast<Map<String, dynamic>>();
        return ExpansionTile(
          leading: const Icon(Icons.bubble_chart),
          title: Text('${e['component']} • ${e['decision']}'),
          subtitle: Text(e['rationale'] ?? ''),
          children: [
            if (factors != null && factors.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Why this decision?', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    ...factors.take(6).map((f) => Row(
                      children: [
                        Expanded(child: Text('${f['name']}: ${f['value']}')),
                        Text('w=${(f['weight'] ?? '-')}'),
                        const SizedBox(width: 8),
                        Text('impact=${(f['impact'] ?? '-')}'),
                      ],
                    )),
                  ],
                ),
              ),
          ],
        );
      }).toList(),
    );
  }
}
