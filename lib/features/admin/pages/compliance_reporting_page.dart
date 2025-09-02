import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/compliance_reporting_service.dart';

class ComplianceReportingPage extends StatefulWidget {
  const ComplianceReportingPage({Key? key}) : super(key: key);

  @override
  State<ComplianceReportingPage> createState() => _ComplianceReportingPageState();
}

class _ComplianceReportingPageState extends State<ComplianceReportingPage> with SingleTickerProviderStateMixin {
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
        title: const Text('Compliance & Reporting'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Frameworks'),
            Tab(text: 'Reports'),
            Tab(text: 'Tasks'),
          ],
        ),
      ),
      body: Consumer<ComplianceReportingService>(
        builder: (context, service, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildDashboard(service),
              _buildFrameworks(service),
              _buildReports(service),
              _buildTasks(service),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDashboard(ComplianceReportingService service) {
    final metrics = service.getComplianceMetrics();
    final complianceRate = metrics['total']! > 0
        ? (metrics['compliant']! / metrics['total']! * 100)
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Overall Compliance',
                  value: '${complianceRate.toStringAsFixed(1)}%',
                  icon: Icons.shield,
                  color: complianceRate >= 90 ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MetricCard(
                  title: 'Active Frameworks',
                  value: '${service.frameworks.length}',
                  icon: Icons.book,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Compliance Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: service.isAssessing ? null : () => service.runAutomatedAssessment(),
                icon: service.isAssessing 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh),
                label: Text(service.isAssessing ? 'Assessing...' : 'Run Assessment'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...service.frameworks.map((framework) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(_getFrameworkIcon(framework.id), color: _getStatusColor(framework.status)),
              title: Text(framework.name),
              subtitle: Text('Score: ${framework.overallScore.toStringAsFixed(1)}% • ${framework.status}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Next Assessment', style: TextStyle(fontSize: 12)),
                  Text(DateFormat('MMM dd').format(framework.nextAssessment)),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFrameworks(ComplianceReportingService service) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: service.frameworks.length,
      itemBuilder: (context, index) {
        final framework = service.frameworks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: Icon(_getFrameworkIcon(framework.id)),
            title: Text('${framework.name} v${framework.version}'),
            subtitle: Text(framework.description),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Overall Score: ${framework.overallScore.toStringAsFixed(1)}%'),
                    const SizedBox(height: 8),
                    Text('Controls (${framework.controls.length}):', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ...framework.controls.map((control) => ListTile(
                      dense: true,
                      leading: Icon(
                        control.status == 'Compliant' ? Icons.check_circle : Icons.warning,
                        color: _getStatusColor(control.status),
                        size: 20,
                      ),
                      title: Text('${control.id}: ${control.name}'),
                      subtitle: Text(control.description),
                      trailing: Text('${control.score.toStringAsFixed(0)}%'),
                    )),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _generateReport(context, service, framework.id),
                          child: const Text('Generate Report'),
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

  Widget _buildReports(ComplianceReportingService service) {
    if (service.reports.isEmpty) {
      return const Center(child: Text('No reports generated yet'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: service.reports.length,
      itemBuilder: (context, index) {
        final report = service.reports[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.article),
            title: Text(report.title),
            subtitle: Text('${report.type} • ${report.framework}\n${DateFormat('MMM dd, yyyy').format(report.createdDate)}'),
            trailing: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Downloading ${report.title}...')),
              ),
            ),
            onTap: () => _showReportDetails(context, report),
          ),
        );
      },
    );
  }

  Widget _buildTasks(ComplianceReportingService service) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Compliance Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: () => _createTask(context, service),
              icon: const Icon(Icons.add),
              label: const Text('New Task'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...service.tasks.map((task) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(task.priority).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(task.priority, style: TextStyle(color: _getPriorityColor(task.priority), fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    Text(task.framework, style: const TextStyle(fontSize: 12)),
                    const Spacer(),
                    Text(DateFormat('MMM dd').format(task.dueDate)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(task.description),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('${task.assignee} • ${task.progress.toInt()}%'),
                    const Spacer(),
                    Text(task.status),
                  ],
                ),
                LinearProgressIndicator(value: task.progress / 100),
              ],
            ),
          ),
        )),
      ],
    );
  }

  void _generateReport(BuildContext context, ComplianceReportingService service, String frameworkId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.assessment),
              title: const Text('Compliance Assessment'),
              onTap: () {
                Navigator.pop(context);
                service.generateReport(frameworkId, 'Assessment');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Generating report...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Gap Analysis'),
              onTap: () {
                Navigator.pop(context);
                service.generateReport(frameworkId, 'Gap Analysis');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Generating report...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDetails(BuildContext context, AuditReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type: ${report.type}'),
              Text('Framework: ${report.framework}'),
              Text('Status: ${report.status}'),
              Text('Created: ${DateFormat('MMM dd, yyyy').format(report.createdDate)}'),
              const SizedBox(height: 16),
              const Text('Executive Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(report.executiveSummary),
              const SizedBox(height: 16),
              const Text('Recommendations:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...report.recommendations.map((r) => Text('• $r')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _createTask(BuildContext context, ComplianceReportingService service) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 16),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                service.createTask(
                  titleController.text,
                  descriptionController.text,
                  'GDPR',
                  'Assigned User',
                  'Medium',
                  DateTime.now().add(const Duration(days: 7)),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  IconData _getFrameworkIcon(String id) {
    switch (id) {
      case 'pci-dss': return Icons.credit_card;
      case 'iso-27001': return Icons.security;
      case 'gdpr': return Icons.privacy_tip;
      case 'hipaa': return Icons.medical_services;
      default: return Icons.book;
    }
  }

  Color _getStatusColor(String status) {
    if (status.contains('Compliant') && !status.contains('Non')) {
      return Colors.green;
    }
    return Colors.orange;
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Critical': return Colors.red;
      case 'High': return Colors.orange;
      case 'Medium': return Colors.yellow;
      default: return Colors.grey;
    }
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
