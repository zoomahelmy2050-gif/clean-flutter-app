import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/audit_trail_service.dart';
import '../../core/theme/app_theme.dart';

class AuditTrailPage extends StatefulWidget {
  const AuditTrailPage({Key? key}) : super(key: key);

  @override
  State<AuditTrailPage> createState() => _AuditTrailPageState();
}

class _AuditTrailPageState extends State<AuditTrailPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  DateTimeRange? _dateRange;
  AuditEventType? _selectedEventType;
  AuditSeverity? _selectedSeverity;
  bool? _selectedSuccess;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Trail & Forensics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Dashboard', icon: Icon(Icons.dashboard)),
            Tab(text: 'Events', icon: Icon(Icons.event_note)),
            Tab(text: 'Forensics', icon: Icon(Icons.search)),
            Tab(text: 'Reports', icon: Icon(Icons.assessment)),
          ],
        ),
      ),
      body: Consumer<AuditTrailService>(
        builder: (context, auditService, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildDashboardTab(auditService),
              _buildEventsTab(auditService),
              _buildForensicsTab(auditService),
              _buildReportsTab(auditService),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDashboardTab(AuditTrailService auditService) {
    final stats = auditService.getAuditStatistics();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Total Events', stats['total_events'].toString(), Icons.event, Colors.blue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard('Events (24h)', stats['events_24h'].toString(), Icons.today, Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Critical Events', stats['critical_events'].toString(), Icons.error, Colors.red),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard('Success Rate', '${stats['success_rate']}%', Icons.check_circle, Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recent Security Events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ...auditService.auditEvents
                      .where((e) => e.eventType == AuditEventType.securityEvent || e.severity == AuditSeverity.critical)
                      .take(5)
                      .map((event) => _buildEventTile(event))
                      .toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab(AuditTrailService auditService) {
    final filteredEvents = _getFilteredEvents(auditService);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search events...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
        Expanded(
          child: filteredEvents.isEmpty
            ? const Center(child: Text('No events found'))
            : ListView.builder(
                itemCount: filteredEvents.length,
                itemBuilder: (context, index) {
                  final event = filteredEvents[index];
                  return _buildDetailedEventTile(event);
                },
              ),
        ),
      ],
    );
  }

  Widget _buildForensicsTab(AuditTrailService auditService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Search Templates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _performQuickSearch(auditService, 'failed_logins'),
                        icon: const Icon(Icons.error),
                        label: const Text('Failed Logins'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _performQuickSearch(auditService, 'admin_actions'),
                        icon: const Icon(Icons.admin_panel_settings),
                        label: const Text('Admin Actions'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _performQuickSearch(auditService, 'security_events'),
                        icon: const Icon(Icons.security),
                        label: const Text('Security Events'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab(AuditTrailService auditService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Generate Reports', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _generateReport(auditService, 'daily'),
                          icon: const Icon(Icons.today),
                          label: const Text('Daily Report'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _generateReport(auditService, 'weekly'),
                          icon: const Icon(Icons.date_range),
                          label: const Text('Weekly Report'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTile(AuditEvent event) {
    return ListTile(
      leading: Icon(_getEventTypeIcon(event.eventType), color: _getSeverityColor(event.severity)),
      title: Text(event.action),
      subtitle: Text('${event.userId ?? 'System'} • ${_formatDateTime(event.timestamp)}'),
      trailing: Icon(
        event.success ? Icons.check_circle : Icons.error,
        color: event.success ? Colors.green : Colors.red,
        size: 16,
      ),
      onTap: () => _showEventDetails(event),
    );
  }

  Widget _buildDetailedEventTile(AuditEvent event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: Icon(_getEventTypeIcon(event.eventType), color: _getSeverityColor(event.severity)),
        title: Text(event.action),
        subtitle: Text('${event.userId ?? 'System'} • ${event.eventType.name}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Timestamp: ${_formatDateTime(event.timestamp)}'),
                Text('User ID: ${event.userId ?? 'N/A'}'),
                Text('Severity: ${event.severity.name.toUpperCase()}'),
                Text('Success: ${event.success ? 'Yes' : 'No'}'),
                if (event.errorMessage != null)
                  Text('Error: ${event.errorMessage}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<AuditEvent> _getFilteredEvents(AuditTrailService auditService) {
    return auditService.searchEvents(
      action: _searchController.text.isNotEmpty ? _searchController.text : null,
      limit: 1000,
    );
  }

  IconData _getEventTypeIcon(AuditEventType eventType) {
    switch (eventType) {
      case AuditEventType.authentication:
        return Icons.login;
      case AuditEventType.authorization:
        return Icons.security;
      case AuditEventType.dataAccess:
        return Icons.folder_open;
      case AuditEventType.dataModification:
        return Icons.edit;
      case AuditEventType.systemConfiguration:
        return Icons.settings;
      case AuditEventType.userManagement:
        return Icons.people;
      case AuditEventType.securityEvent:
        return Icons.warning;
      case AuditEventType.adminAction:
        return Icons.admin_panel_settings;
      case AuditEventType.apiCall:
        return Icons.api;
      case AuditEventType.fileAccess:
        return Icons.file_open;
    }
  }

  Color _getSeverityColor(AuditSeverity severity) {
    switch (severity) {
      case AuditSeverity.critical:
        return Colors.red;
      case AuditSeverity.error:
        return Colors.orange;
      case AuditSeverity.warning:
        return Colors.yellow;
      case AuditSeverity.info:
        return Colors.blue;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _performQuickSearch(AuditTrailService auditService, String searchType) {
    List<AuditEvent> results = [];
    
    switch (searchType) {
      case 'failed_logins':
        results = auditService.searchEvents(action: 'login', success: false);
        break;
      case 'admin_actions':
        results = auditService.searchEvents(eventType: AuditEventType.adminAction);
        break;
      case 'security_events':
        results = auditService.searchEvents(eventType: AuditEventType.securityEvent);
        break;
    }
    
    _showQueryResults(searchType.replaceAll('_', ' ').toUpperCase(), results);
  }

  void _showQueryResults(String queryName, List<AuditEvent> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$queryName Results'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: results.isEmpty
            ? const Center(child: Text('No results found'))
            : ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final event = results[index];
                  return _buildEventTile(event);
                },
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _generateReport(AuditTrailService auditService, String reportType) {
    DateTime startDate;
    final now = DateTime.now();
    
    switch (reportType) {
      case 'daily':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'weekly':
        startDate = now.subtract(const Duration(days: 7));
        break;
      default:
        startDate = now.subtract(const Duration(days: 30));
    }
    
    final report = auditService.generateAuditReport(startDate: startDate, endDate: now);
    _showReportDialog(reportType.toUpperCase(), report);
  }

  void _showReportDialog(String reportType, Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$reportType Report'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Events: ${report['summary']['total_events']}'),
              Text('Success Rate: ${report['summary']['success_rate']}%'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEventDetails(AuditEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Event Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Action: ${event.action}'),
              Text('Event Type: ${event.eventType.name}'),
              Text('Timestamp: ${_formatDateTime(event.timestamp)}'),
              Text('User ID: ${event.userId ?? 'N/A'}'),
              Text('Success: ${event.success ? 'Yes' : 'No'}'),
              if (event.errorMessage != null)
                Text('Error: ${event.errorMessage}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
