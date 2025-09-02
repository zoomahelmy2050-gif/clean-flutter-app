import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/security_orchestration_service.dart';

class SecurityOrchestrationPage extends StatefulWidget {
  const SecurityOrchestrationPage({super.key});

  @override
  State<SecurityOrchestrationPage> createState() => _SecurityOrchestrationPageState();
}

class _SecurityOrchestrationPageState extends State<SecurityOrchestrationPage> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Orchestration & Automation'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.book), text: 'Playbooks'),
            Tab(icon: Icon(Icons.folder_open), text: 'Cases'),
            Tab(icon: Icon(Icons.timeline), text: 'Workflows'),
          ],
        ),
      ),
      body: Consumer<SecurityOrchestrationService>(
        builder: (context, service, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildDashboard(context, service),
              _buildPlaybooks(context, service),
              _buildCases(context, service),
              _buildWorkflows(context, service),
            ],
          );
        },
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildDashboard(BuildContext context, SecurityOrchestrationService service) {
    final metrics = service.getMetrics();
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metrics Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _MetricCard(
                title: 'Active Playbooks',
                value: '${metrics.activePlaybooks}',
                subtitle: 'of ${metrics.totalPlaybooks} total',
                icon: Icons.play_circle,
                color: Colors.green,
              ),
              _MetricCard(
                title: 'Open Cases',
                value: '${metrics.openCases}',
                subtitle: 'of ${metrics.totalCases} total',
                icon: Icons.folder_open,
                color: Colors.orange,
              ),
              _MetricCard(
                title: 'Avg Resolution',
                value: '${metrics.avgResolutionHours.toStringAsFixed(1)}h',
                subtitle: 'Mean time to resolve',
                icon: Icons.timer,
                color: Colors.blue,
              ),
              _MetricCard(
                title: 'Automation Rate',
                value: '78%',
                subtitle: 'Actions automated',
                icon: Icons.smart_toy,
                color: Colors.purple,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Cases by Priority
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cases by Priority', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  ...CasePriority.values.map((priority) {
                    final count = metrics.casesByPriority[priority] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getPriorityColor(priority),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(priority.name.toUpperCase()),
                          ),
                          Text('$count'),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Recent Playbook Executions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recent Playbook Executions', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  ...metrics.recentExecutions.map((execution) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.play_arrow, size: 20),
                      title: Text(execution['name']),
                      subtitle: Text('Used ${execution['useCount']} times'),
                      trailing: Text(
                        '${(execution['successRate'] * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: execution['successRate'] > 0.9 ? Colors.green : Colors.orange,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybooks(BuildContext context, SecurityOrchestrationService service) {
    final theme = Theme.of(context);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: service.playbooks.length,
      itemBuilder: (context, index) {
        final playbook = service.playbooks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: Icon(
              Icons.book,
              color: _getStatusColor(playbook.status),
            ),
            title: Text(playbook.name),
            subtitle: Text(playbook.description),
            trailing: Chip(
              label: Text(playbook.status.name.toUpperCase()),
              backgroundColor: _getStatusColor(playbook.status).withOpacity(0.2),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Category: ${playbook.category}'),
                        Text('Author: ${playbook.author}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Actions: ${playbook.actions.length}'),
                        Text('Success Rate: ${(playbook.successRate * 100).toStringAsFixed(0)}%'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Actions list
                    if (playbook.actions.isNotEmpty) ...[
                      Text('Actions:', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      ...playbook.actions.map((action) => Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 4),
                        child: Row(
                          children: [
                            Text('${action.order}. '),
                            Expanded(
                              child: Text(action.name),
                            ),
                            Text('~${action.estimatedMinutes} min'),
                          ],
                        ),
                      )),
                    ],
                    
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (playbook.status == PlaybookStatus.draft)
                          TextButton.icon(
                            onPressed: () {
                              service.updatePlaybookStatus(
                                playbook.id, 
                                PlaybookStatus.testing
                              );
                            },
                            icon: const Icon(Icons.science),
                            label: const Text('Test'),
                          ),
                        if (playbook.status == PlaybookStatus.testing)
                          TextButton.icon(
                            onPressed: () {
                              service.updatePlaybookStatus(
                                playbook.id, 
                                PlaybookStatus.active
                              );
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Activate'),
                          ),
                        if (playbook.status == PlaybookStatus.active)
                          TextButton.icon(
                            onPressed: () {
                              service.updatePlaybookStatus(
                                playbook.id, 
                                PlaybookStatus.archived
                              );
                            },
                            icon: const Icon(Icons.archive),
                            label: const Text('Archive'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCases(BuildContext context, SecurityOrchestrationService service) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, HH:mm');
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: service.cases.length,
      itemBuilder: (context, index) {
        final caseItem = service.cases[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: Icon(
              _getCaseIcon(caseItem.type),
              color: _getPriorityColor(caseItem.priority),
            ),
            title: Text(caseItem.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(caseItem.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Chip(
                      label: Text(caseItem.status.name.toUpperCase()),
                      backgroundColor: _getCaseStatusColor(caseItem.status).withOpacity(0.2),
                      labelStyle: TextStyle(fontSize: 10),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateFormat.format(caseItem.createdAt),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Case details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Type: ${caseItem.type.name}'),
                        Text('Priority: ${caseItem.priority.name}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (caseItem.assignee != null)
                      Text('Assignee: ${caseItem.assignee}'),
                    if (caseItem.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children: caseItem.tags.map((tag) => Chip(
                          label: Text(tag, style: const TextStyle(fontSize: 11)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        )).toList(),
                      ),
                    ],
                    
                    // Activities
                    if (caseItem.activities.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Recent Activities:', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      ...caseItem.activities.take(3).map((activity) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 6),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${activity.action}: ${activity.details}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                    
                    // Actions
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (caseItem.playbookId != null)
                          TextButton.icon(
                            onPressed: () {
                              service.executePlaybook(
                                caseItem.playbookId!, 
                                caseItem.id
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Executing playbook...'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Execute Playbook'),
                          ),
                        if (caseItem.assignee == null)
                          TextButton.icon(
                            onPressed: () {
                              service.assignCase(caseItem.id, 'Current User');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Case assigned'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.person_add),
                            label: const Text('Assign to Me'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWorkflows(BuildContext context, SecurityOrchestrationService service) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_tree, size: 64, color: Theme.of(context).disabledColor),
          const SizedBox(height: 16),
          Text(
            'Workflow Designer',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Visual workflow builder coming soon'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Workflow designer will be available in next update'),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Workflow'),
          ),
        ],
      ),
    );
  }

  Widget? _buildFAB(BuildContext context) {
    if (_tabController.index == 1) {  // Playbooks tab
      return FloatingActionButton.extended(
        onPressed: () => _showCreatePlaybookDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Playbook'),
      );
    } else if (_tabController.index == 2) {  // Cases tab
      return FloatingActionButton.extended(
        onPressed: () => _showCreateCaseDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Case'),
      );
    }
    return null;
  }

  void _showCreatePlaybookDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String category = 'Malware';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Playbook'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Playbook Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: ['Malware', 'Data Protection', 'Email Security', 'Network', 'Access Control']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                if (value != null) category = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final service = context.read<SecurityOrchestrationService>();
              service.createPlaybook(
                nameController.text,
                descController.text,
                category,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Playbook created')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCreateCaseDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    CaseType type = CaseType.incident;
    CasePriority priority = CasePriority.medium;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Case'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Case Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CaseType>(
                value: type,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: CaseType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) type = value;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CasePriority>(
                value: priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: CasePriority.values
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) priority = value;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final service = context.read<SecurityOrchestrationService>();
              service.createCase(
                title: titleController.text,
                description: descController.text,
                type: type,
                priority: priority,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Case created')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(PlaybookStatus status) {
    switch (status) {
      case PlaybookStatus.active:
        return Colors.green;
      case PlaybookStatus.testing:
        return Colors.orange;
      case PlaybookStatus.draft:
        return Colors.grey;
      case PlaybookStatus.archived:
        return Colors.brown;
    }
  }

  Color _getPriorityColor(CasePriority priority) {
    switch (priority) {
      case CasePriority.critical:
        return Colors.red;
      case CasePriority.high:
        return Colors.orange;
      case CasePriority.medium:
        return Colors.yellow[700]!;
      case CasePriority.low:
        return Colors.green;
    }
  }

  Color _getCaseStatusColor(CaseStatus status) {
    switch (status) {
      case CaseStatus.open:
        return Colors.blue;
      case CaseStatus.investigating:
        return Colors.orange;
      case CaseStatus.resolved:
        return Colors.green;
      case CaseStatus.closed:
        return Colors.grey;
      case CaseStatus.escalated:
        return Colors.red;
    }
  }

  IconData _getCaseIcon(CaseType type) {
    switch (type) {
      case CaseType.incident:
        return Icons.warning;
      case CaseType.breach:
        return Icons.shield;
      case CaseType.vulnerability:
        return Icons.bug_report;
      case CaseType.compliance:
        return Icons.gavel;
      case CaseType.general:
        return Icons.folder;
    }
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
