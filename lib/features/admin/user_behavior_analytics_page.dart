import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/user_behavior_analytics_service.dart';
import '../../core/theme/app_theme.dart';

class UserBehaviorAnalyticsPage extends StatefulWidget {
  const UserBehaviorAnalyticsPage({Key? key}) : super(key: key);

  @override
  State<UserBehaviorAnalyticsPage> createState() => _UserBehaviorAnalyticsPageState();
}

class _UserBehaviorAnalyticsPageState extends State<UserBehaviorAnalyticsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedUserId = '';
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('User Behavior Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.analytics)),
            Tab(text: 'Anomalies', icon: Icon(Icons.warning)),
            Tab(text: 'Events', icon: Icon(Icons.event)),
          ],
        ),
      ),
      body: Consumer<UserBehaviorAnalyticsService>(
        builder: (context, analyticsService, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(analyticsService),
              _buildAnomaliesTab(analyticsService),
              _buildEventsTab(analyticsService),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(UserBehaviorAnalyticsService analyticsService) {
    final stats = analyticsService.getBehaviorAnalyticsStatistics();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Events',
                  stats['total_events'].toString(),
                  Icons.event,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Events (24h)',
                  stats['events_24h'].toString(),
                  Icons.today,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Anomalies',
                  stats['total_anomalies'].toString(),
                  Icons.warning,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Unresolved',
                  stats['unresolved_anomalies'].toString(),
                  Icons.error,
                  Colors.red,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Top Event Types
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Top Event Types', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ...((stats['top_event_types'] as Map<String, int>).entries.take(5).map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            _getEventTypeIcon(entry.key),
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(entry.key.replaceAll('_', ' ').toUpperCase())),
                          Text(entry.value.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList()),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Anomaly Type Breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Anomaly Type Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ...((stats['anomaly_types'] as Map<String, int>).entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getAnomalyTypeColor(entry.key),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(entry.key.replaceAll('Anomaly', ' Anomaly').toUpperCase())),
                          Text(entry.value.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList()),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Recent Anomalies
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Recent Anomalies', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _tabController.animateTo(1),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (analyticsService.anomalies.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No anomalies detected'),
                      ),
                    )
                  else
                    ...analyticsService.anomalies.take(3).map((anomaly) => _buildAnomalyTile(anomaly)).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnomaliesTab(UserBehaviorAnalyticsService analyticsService) {
    final anomalies = analyticsService.anomalies;
    
    return Column(
      children: [
        // Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search anomalies...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    // TODO: Implement search filtering
                  },
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<AnomalyType>(
                icon: const Icon(Icons.filter_list),
                onSelected: (type) {
                  // TODO: Implement type filtering
                },
                itemBuilder: (context) => AnomalyType.values.map((type) {
                  return PopupMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getAnomalyTypeColor(type.name),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(type.name.replaceAll('Anomaly', ' Anomaly').toUpperCase()),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        
        // Anomalies List
        Expanded(
          child: anomalies.isEmpty
            ? const Center(child: Text('No anomalies detected'))
            : ListView.builder(
                itemCount: anomalies.length,
                itemBuilder: (context, index) {
                  final anomaly = anomalies[index];
                  return _buildDetailedAnomalyTile(anomaly);
                },
              ),
        ),
      ],
    );
  }

  Widget _buildEventsTab(UserBehaviorAnalyticsService analyticsService) {
    final events = analyticsService.events;
    
    return Column(
      children: [
        // Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search events...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    // TODO: Implement search filtering
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.date_range),
                onPressed: _selectDateRange,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddEventDialog(analyticsService),
              ),
            ],
          ),
        ),
        
        // Events List
        Expanded(
          child: events.isEmpty
            ? const Center(child: Text('No events recorded'))
            : ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return _buildEventTile(event);
                },
              ),
        ),
      ],
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

  Widget _buildAnomalyTile(BehaviorAnomaly anomaly) {
    return ListTile(
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: _getAnomalyTypeColor(anomaly.type.name),
          shape: BoxShape.circle,
        ),
      ),
      title: Text(anomaly.description),
      subtitle: Text('User: ${anomaly.userId} • ${_formatDateTime(anomaly.detectedAt)}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${(anomaly.severity * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getSeverityColor(anomaly.severity),
            ),
          ),
          Text(
            '${(anomaly.confidence * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
      onTap: () => _showAnomalyDetails(anomaly),
    );
  }

  Widget _buildDetailedAnomalyTile(BehaviorAnomaly anomaly) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _getAnomalyTypeColor(anomaly.type.name),
            shape: BoxShape.circle,
          ),
        ),
        title: Text(anomaly.description),
        subtitle: Text('User: ${anomaly.userId} • Severity: ${(anomaly.severity * 100).toStringAsFixed(0)}%'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detected: ${_formatDateTime(anomaly.detectedAt)}'),
                Text('Confidence: ${(anomaly.confidence * 100).toStringAsFixed(1)}%'),
                Text('Type: ${anomaly.type.name.replaceAll('Anomaly', ' Anomaly')}'),
                if (anomaly.context.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Context:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...anomaly.context.entries.map((entry) {
                    return Text('${entry.key}: ${entry.value}');
                  }).toList(),
                ],
                const SizedBox(height: 16),
                if (!anomaly.resolved)
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement resolve anomaly
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Anomaly marked as resolved')),
                      );
                    },
                    child: const Text('Mark Resolved'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTile(UserBehaviorEvent event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: ListTile(
        leading: Icon(_getEventTypeIcon(event.eventType)),
        title: Text(event.eventType.replaceAll('_', ' ').toUpperCase()),
        subtitle: Text('User: ${event.userId} • ${_formatDateTime(event.timestamp)}'),
        trailing: event.sessionId != null 
          ? Text('Session: ${event.sessionId!.substring(0, 8)}...')
          : null,
        onTap: () => _showEventDetails(event),
      ),
    );
  }

  Color _getAnomalyTypeColor(String typeName) {
    switch (typeName) {
      case 'timeAnomaly':
        return Colors.blue;
      case 'locationAnomaly':
        return Colors.red;
      case 'deviceAnomaly':
        return Colors.orange;
      case 'usageAnomaly':
        return Colors.purple;
      case 'navigationAnomaly':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getSeverityColor(double severity) {
    if (severity >= 0.8) return Colors.red;
    if (severity >= 0.6) return Colors.orange;
    if (severity >= 0.4) return Colors.yellow;
    return Colors.green;
  }

  IconData _getEventTypeIcon(String eventType) {
    switch (eventType) {
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'failed_login':
        return Icons.error;
      case 'feature_usage':
        return Icons.touch_app;
      case 'admin_action':
        return Icons.admin_panel_settings;
      case 'sensitive_data_access':
        return Icons.security;
      default:
        return Icons.event;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      // TODO: Apply date filter
    }
  }

  void _showAddEventDialog(UserBehaviorAnalyticsService analyticsService) {
    final userIdController = TextEditingController();
    final eventTypeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Test Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userIdController,
              decoration: const InputDecoration(
                labelText: 'User ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: eventTypeController,
              decoration: const InputDecoration(
                labelText: 'Event Type',
                border: OutlineInputBorder(),
              ),
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
              if (userIdController.text.isNotEmpty && eventTypeController.text.isNotEmpty) {
                analyticsService.trackEvent(
                  userId: userIdController.text,
                  eventType: eventTypeController.text,
                  properties: {'test_event': true},
                  sessionId: 'test_session_${DateTime.now().millisecondsSinceEpoch}',
                  deviceId: 'test_device',
                  location: 'Test Location',
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test event added')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAnomalyDetails(BehaviorAnomaly anomaly) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Anomaly Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Description: ${anomaly.description}'),
              Text('User ID: ${anomaly.userId}'),
              Text('Type: ${anomaly.type.name}'),
              Text('Severity: ${(anomaly.severity * 100).toStringAsFixed(1)}%'),
              Text('Confidence: ${(anomaly.confidence * 100).toStringAsFixed(1)}%'),
              Text('Detected: ${_formatDateTime(anomaly.detectedAt)}'),
              Text('Status: ${anomaly.resolved ? 'Resolved' : 'Active'}'),
              if (anomaly.context.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Context:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...anomaly.context.entries.map((entry) {
                  return Text('${entry.key}: ${entry.value}');
                }).toList(),
              ],
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

  void _showEventDetails(UserBehaviorEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Event Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Event Type: ${event.eventType}'),
              Text('User ID: ${event.userId}'),
              Text('Timestamp: ${_formatDateTime(event.timestamp)}'),
              if (event.sessionId != null)
                Text('Session ID: ${event.sessionId}'),
              if (event.deviceId != null)
                Text('Device ID: ${event.deviceId}'),
              if (event.location != null)
                Text('Location: ${event.location}'),
              if (event.properties.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Properties:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...event.properties.entries.map((entry) {
                  return Text('${entry.key}: ${entry.value}');
                }).toList(),
              ],
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
