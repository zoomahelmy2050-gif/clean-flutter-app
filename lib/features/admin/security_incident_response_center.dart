import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../locator.dart';
import 'services/incident_response_service.dart';
import '../../core/models/threat_models.dart';

class SecurityIncidentResponseCenter extends StatefulWidget {
  const SecurityIncidentResponseCenter({super.key});

  @override
  State<SecurityIncidentResponseCenter> createState() => _SecurityIncidentResponseCenterState();
}

class _SecurityIncidentResponseCenterState extends State<SecurityIncidentResponseCenter> 
    with TickerProviderStateMixin {
  final _incidentService = locator<IncidentResponseService>();
  late TabController _tabController;
  
  List<SecurityIncident> _activeIncidents = [];
  List<SecurityIncident> _resolvedIncidents = [];
  List<SecurityPlaybook> _playbooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadIncidentData();
  }

  Future<void> _loadIncidentData() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _incidentService.getActiveIncidents(),
        _incidentService.getResolvedIncidents(),
        _incidentService.getSecurityPlaybooks(),
      ]);
      
      setState(() {
        _activeIncidents = results[0] as List<SecurityIncident>;
        _resolvedIncidents = results[1] as List<SecurityIncident>;
        _playbooks = results[2] as List<SecurityPlaybook>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading incident data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Incident Response'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIncidentData,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showIncidentSettings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.crisis_alert), text: 'Active'),
            Tab(icon: Icon(Icons.check_circle), text: 'Resolved'),
            Tab(icon: Icon(Icons.book), text: 'Playbooks'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActiveIncidentsTab(),
                _buildResolvedIncidentsTab(),
                _buildPlaybooksTab(),
                _buildAnalyticsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewIncident,
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alert),
        label: const Text('New Incident'),
      ),
    );
  }

  Widget _buildActiveIncidentsTab() {
    return Column(
      children: [
        _buildIncidentOverview(),
        Expanded(child: _buildIncidentsList(_activeIncidents, isActive: true)),
      ],
    );
  }

  Widget _buildIncidentOverview() {
    final criticalCount = _activeIncidents.where((i) => i.severity == AlertSeverity.critical).length;
    final highCount = _activeIncidents.where((i) => i.severity == AlertSeverity.high).length;
    final mediumCount = _activeIncidents.where((i) => i.severity == AlertSeverity.medium).length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.crisis_alert, color: Colors.red.shade700, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Security Incidents',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        Text(
                          '${_activeIncidents.length} incidents require attention',
                          style: TextStyle(color: Colors.red.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSeverityCounter('Critical', criticalCount, Colors.red),
                  _buildSeverityCounter('High', highCount, Colors.orange),
                  _buildSeverityCounter('Medium', mediumCount, Colors.yellow.shade700),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityCounter(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildIncidentsList(List<SecurityIncident> incidents, {bool isActive = false}) {
    if (incidents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.security : Icons.check_circle,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? 'No active incidents' : 'No resolved incidents',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: incidents.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final incident = incidents[index];
        return _buildIncidentCard(incident, isActive);
      },
    );
  }

  Widget _buildIncidentCard(SecurityIncident incident, bool isActive) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIncidentIcon(incident.severity),
                  color: _getSeverityColor(incident.severity),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    incident.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text(incident.severity.name.toUpperCase()),
                  backgroundColor: _getSeverityColor(incident.severity),
                  labelStyle: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(incident.description),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('Assigned: ${incident.assignedTo}'),
                const Spacer(),
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(DateFormat.yMd().add_Hm().format(incident.createdAt)),
              ],
            ),
            if (incident.affectedUsers.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: incident.affectedUsers.take(3).map((user) => 
                  Chip(
                    label: Text(user),
                    backgroundColor: Colors.grey.shade200,
                    labelStyle: const TextStyle(fontSize: 10),
                  ),
                ).toList(),
              ),
              if (incident.affectedUsers.length > 3)
                Text('+${incident.affectedUsers.length - 3} more users'),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showIncidentDetails(incident),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 8),
                if (isActive) ...[
                  ElevatedButton.icon(
                    onPressed: () => _escalateIncident(incident),
                    icon: const Icon(Icons.trending_up),
                    label: const Text('Escalate'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _resolveIncident(incident),
                    icon: const Icon(Icons.check),
                    label: const Text('Resolve'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResolvedIncidentsTab() {
    return _buildIncidentsList(_resolvedIncidents, isActive: false);
  }

  Widget _buildPlaybooksTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.book, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'Security Playbooks',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _createNewPlaybook,
                      icon: const Icon(Icons.add),
                      label: const Text('New Playbook'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Automated response procedures for common security incidents',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ..._playbooks.map((playbook) => _buildPlaybookCard(playbook)),
      ],
    );
  }

  Widget _buildPlaybookCard(SecurityPlaybook playbook) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getPlaybookIcon(playbook.type),
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    playbook.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text(playbook.type.toUpperCase()),
                  backgroundColor: Colors.blue.shade100,
                  labelStyle: TextStyle(color: Colors.blue.shade700, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(playbook.description),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('${playbook.steps.length} steps'),
                const SizedBox(width: 16),
                Icon(Icons.timer, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('~${playbook.estimatedDuration} min'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _viewPlaybook(playbook),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Steps'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _executePlaybook(playbook),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Execute'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildIncidentMetrics(),
        const SizedBox(height: 16),
        _buildResponseTimeChart(),
        const SizedBox(height: 16),
        _buildIncidentTrends(),
      ],
    );
  }

  Widget _buildIncidentMetrics() {
    final totalIncidents = _activeIncidents.length + _resolvedIncidents.length;
    final avgResponseTime = _calculateAverageResponseTime();
    final resolutionRate = _resolvedIncidents.length / totalIncidents * 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Incident Response Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard('Total Incidents', totalIncidents.toString(), Icons.crisis_alert),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard('Avg Response', '${avgResponseTime}min', Icons.timer),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard('Resolution Rate', '${resolutionRate.toStringAsFixed(1)}%', Icons.check_circle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue.shade700),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResponseTimeChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Response Time Trends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timeline, size: 48, color: Colors.grey),
                    Text('Response Time Chart', style: TextStyle(color: Colors.grey)),
                    Text('Historical data visualization', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentTrends() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Incident Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildCategoryItem('Malware Detection', 35, Colors.red),
            _buildCategoryItem('Phishing Attempts', 28, Colors.orange),
            _buildCategoryItem('Data Breach', 20, Colors.purple),
            _buildCategoryItem('Unauthorized Access', 12, Colors.blue),
            _buildCategoryItem('DDoS Attack', 5, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String category, int percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(category),
          ),
          Expanded(
            flex: 2,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          Text('${percentage}%'),
        ],
      ),
    );
  }

  // Helper methods
  IconData _getIncidentIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Icons.dangerous;
      case AlertSeverity.high:
        return Icons.warning;
      case AlertSeverity.medium:
        return Icons.info;
      case AlertSeverity.low:
        return Icons.info_outline;
    }
  }

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Colors.red;
      case AlertSeverity.high:
        return Colors.orange;
      case AlertSeverity.medium:
        return Colors.yellow.shade700;
      case AlertSeverity.low:
        return Colors.blue;
    }
  }

  IconData _getPlaybookIcon(String type) {
    switch (type.toLowerCase()) {
      case 'malware':
        return Icons.bug_report;
      case 'phishing':
        return Icons.phishing;
      case 'breach':
        return Icons.security;
      case 'ddos':
        return Icons.shield;
      default:
        return Icons.book;
    }
  }

  int _calculateAverageResponseTime() {
    if (_resolvedIncidents.isEmpty) return 0;
    
    int totalMinutes = 0;
    for (final incident in _resolvedIncidents) {
      if (incident.resolvedAt != null) {
        final responseTime = incident.resolvedAt!.difference(incident.createdAt).inMinutes;
        totalMinutes += responseTime;
      }
    }
    
    return totalMinutes ~/ _resolvedIncidents.length;
  }

  // Action methods
  void _showIncidentSettings() {
    // TODO: Implement incident settings
  }

  void _createNewIncident() {
    showDialog(
      context: context,
      builder: (context) => _buildCreateIncidentDialog(),
    );
  }

  Widget _buildCreateIncidentDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    AlertSeverity selectedSeverity = AlertSeverity.medium;

    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Create New Incident'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Incident Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AlertSeverity>(
                value: selectedSeverity,
                decoration: const InputDecoration(
                  labelText: 'Severity',
                  border: OutlineInputBorder(),
                ),
                items: AlertSeverity.values.map((severity) => 
                  DropdownMenuItem(
                    value: severity,
                    child: Text(severity.name.toUpperCase()),
                  ),
                ).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedSeverity = value);
                  }
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
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                await _incidentService.createIncident(
                  titleController.text,
                  descriptionController.text,
                  selectedSeverity,
                );
                if (mounted) {
                  Navigator.pop(context);
                  _loadIncidentData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incident created successfully')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showIncidentDetails(SecurityIncident incident) {
    // TODO: Show detailed incident view
  }

  void _escalateIncident(SecurityIncident incident) {
    // TODO: Implement incident escalation
  }

  void _resolveIncident(SecurityIncident incident) {
    // TODO: Implement incident resolution
  }

  void _createNewPlaybook() {
    // TODO: Implement playbook creation
  }

  void _viewPlaybook(SecurityPlaybook playbook) {
    // TODO: Show playbook details
  }

  void _executePlaybook(SecurityPlaybook playbook) {
    // TODO: Execute playbook steps
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Additional models for playbooks
class SecurityPlaybook {
  final String id;
  final String title;
  final String description;
  final String type;
  final List<PlaybookStep> steps;
  final int estimatedDuration;
  final DateTime createdAt;

  SecurityPlaybook({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.steps,
    required this.estimatedDuration,
    required this.createdAt,
  });
}

class PlaybookStep {
  final String id;
  final String title;
  final String description;
  final String action;
  final bool isAutomated;
  final int estimatedMinutes;

  PlaybookStep({
    required this.id,
    required this.title,
    required this.description,
    required this.action,
    required this.isAutomated,
    required this.estimatedMinutes,
  });
}
