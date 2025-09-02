import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/user_activity_service.dart';

class UserActivityPage extends StatefulWidget {
  const UserActivityPage({Key? key}) : super(key: key);

  @override
  State<UserActivityPage> createState() => _UserActivityPageState();
}

class _UserActivityPageState extends State<UserActivityPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ActivityType? _selectedType;
  ActivitySeverity? _selectedSeverity;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserActivityService>().initialize();
    });
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
        title: const Text('User Activity'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.history), text: 'Activity Logs'),
            Tab(icon: Icon(Icons.devices), text: 'Sessions'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'cleanup_logs':
                  _showCleanupDialog(true);
                  break;
                case 'cleanup_sessions':
                  _showCleanupDialog(false);
                  break;
                case 'export':
                  _exportData();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'cleanup_logs', child: Text('Cleanup Old Logs')),
              const PopupMenuItem(value: 'cleanup_sessions', child: Text('Cleanup Old Sessions')),
              const PopupMenuItem(value: 'export', child: Text('Export Data')),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActivityLogsTab(),
          _buildSessionsTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildActivityLogsTab() {
    return Consumer<UserActivityService>(
      builder: (context, activityService, child) {
        if (activityService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        var logs = activityService.activityLogs;
        
        // Apply filters
        if (_searchQuery.isNotEmpty) {
          logs = activityService.searchActivities(_searchQuery);
        }
        if (_selectedType != null) {
          logs = logs.where((log) => log.type == _selectedType).toList();
        }
        if (_selectedSeverity != null) {
          logs = logs.where((log) => log.severity == _selectedSeverity).toList();
        }
        if (_startDate != null && _endDate != null) {
          logs = logs.where((log) => 
            log.timestamp.isAfter(_startDate!) && log.timestamp.isBefore(_endDate!)
          ).toList();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search activities...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            if (_hasActiveFilters())
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (_selectedType != null)
                      _buildFilterChip('Type: ${_selectedType!.name}', () => setState(() => _selectedType = null)),
                    if (_selectedSeverity != null)
                      _buildFilterChip('Severity: ${_selectedSeverity!.name}', () => setState(() => _selectedSeverity = null)),
                    if (_startDate != null && _endDate != null)
                      _buildFilterChip('Date Range', () => setState(() {
                        _startDate = null;
                        _endDate = null;
                      })),
                  ],
                ),
              ),
            Expanded(
              child: logs.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No activity logs found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return _buildActivityLogCard(log);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActivityLogCard(ActivityLog log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getSeverityColor(log.severity),
          child: Icon(
            _getActivityIcon(log.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(log.description, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${log.userEmail} • ${_formatDateTime(log.timestamp)}'),
            Row(
              children: [
                Chip(
                  label: Text(log.type.name, style: const TextStyle(fontSize: 10)),
                  backgroundColor: Colors.blue[100],
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(log.severity.name, style: const TextStyle(fontSize: 10)),
                  backgroundColor: _getSeverityColor(log.severity).withOpacity(0.2),
                ),
                if (!log.isSuccessful) ...[
                  const SizedBox(width: 8),
                  const Chip(
                    label: Text('Failed', style: TextStyle(fontSize: 10)),
                    backgroundColor: Colors.red,
                  ),
                ],
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('IP Address', log.ipAddress),
                _buildDetailRow('Device', log.deviceInfo),
                _buildDetailRow('User Agent', log.userAgent),
                if (log.sessionId != null)
                  _buildDetailRow('Session ID', log.sessionId!),
                if (log.errorMessage != null)
                  _buildDetailRow('Error', log.errorMessage!, isError: true),
                if (log.metadata.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Metadata:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...log.metadata.entries.map((entry) => 
                    _buildDetailRow(entry.key, entry.value.toString())
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsTab() {
    return Consumer<UserActivityService>(
      builder: (context, activityService, child) {
        if (activityService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final sessions = activityService.userSessions;
        final activeSessions = activityService.getActiveSessions();

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(Icons.devices, color: Colors.green),
                            const SizedBox(height: 8),
                            Text('${activeSessions.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            const Text('Active Sessions'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(Icons.history, color: Colors.blue),
                            const SizedBox(height: 8),
                            Text('${sessions.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            const Text('Total Sessions'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: sessions.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.devices_other, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No sessions found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        return _buildSessionCard(session, activityService);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSessionCard(UserSession session, UserActivityService activityService) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: session.isActive ? Colors.green[50] : null,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: session.isActive ? Colors.green : Colors.grey,
          child: Icon(
            session.isActive ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: Colors.white,
          ),
        ),
        title: Text(session.userEmail, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Started: ${_formatDateTime(session.startTime)}'),
            if (session.endTime != null)
              Text('Ended: ${_formatDateTime(session.endTime!)}'),
            Text('Duration: ${_formatDuration(session.duration)}'),
            Row(
              children: [
                Chip(
                  label: Text(session.isActive ? 'Active' : 'Ended', style: const TextStyle(fontSize: 10)),
                  backgroundColor: session.isActive ? Colors.green[100] : Colors.grey[300],
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text('${session.activityIds.length} activities', style: const TextStyle(fontSize: 10)),
                  backgroundColor: Colors.blue[100],
                ),
              ],
            ),
          ],
        ),
        trailing: session.isActive
            ? IconButton(
                icon: const Icon(Icons.stop, color: Colors.red),
                onPressed: () => _endSession(session, activityService),
                tooltip: 'End Session',
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('IP Address', session.ipAddress),
                _buildDetailRow('Device', session.deviceInfo),
                _buildDetailRow('User Agent', session.userAgent),
                _buildDetailRow('Session ID', session.id),
                if (session.activityIds.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Recent Activities:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...session.activityIds.take(5).map((activityId) {
                    final activity = activityService.activityLogs.firstWhere(
                      (log) => log.id == activityId,
                      orElse: () => ActivityLog(
                        id: '',
                        userId: '',
                        userEmail: '',
                        type: ActivityType.systemAccess,
                        severity: ActivitySeverity.low,
                        description: 'Activity not found',
                        ipAddress: '',
                        userAgent: '',
                        deviceInfo: '',
                        timestamp: DateTime.now(),
                      ),
                    );
                    return activity.id.isNotEmpty
                        ? ListTile(
                            dense: true,
                            leading: Icon(_getActivityIcon(activity.type), size: 16),
                            title: Text(activity.description, style: const TextStyle(fontSize: 12)),
                            subtitle: Text(_formatDateTime(activity.timestamp), style: const TextStyle(fontSize: 10)),
                          )
                        : const SizedBox.shrink();
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Consumer<UserActivityService>(
      builder: (context, activityService, child) {
        if (activityService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final typeDistribution = activityService.getActivityTypeDistribution();
        final severityDistribution = activityService.getSeverityDistribution();
        final userCounts = activityService.getUserActivityCounts();
        final failedActivities = activityService.getFailedActivities(limit: 10);
        final suspiciousIps = activityService.getSuspiciousIpAddresses();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              Row(
                children: [
                  Expanded(child: _buildAnalyticsCard('Total Activities', activityService.activityLogs.length.toString(), Icons.history, Colors.blue)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildAnalyticsCard('Failed Activities', failedActivities.length.toString(), Icons.error, Colors.red)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildAnalyticsCard('Active Sessions', activityService.getActiveSessions().length.toString(), Icons.devices, Colors.green)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildAnalyticsCard('Suspicious IPs', suspiciousIps.length.toString(), Icons.warning, Colors.orange)),
                ],
              ),
              const SizedBox(height: 24),

              // Activity Type Distribution
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Activity Type Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ...typeDistribution.entries.where((e) => e.value > 0).map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key),
                            Chip(label: Text(entry.value.toString()), backgroundColor: Colors.blue[100]),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Severity Distribution
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Severity Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ...severityDistribution.entries.where((e) => e.value > 0).map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key),
                            Chip(
                              label: Text(entry.value.toString()),
                              backgroundColor: _getSeverityColor(ActivitySeverity.values.firstWhere((s) => s.name == entry.key)).withOpacity(0.2),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Top Users
              if (userCounts.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Most Active Users', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        ...userCounts.entries.take(10).map((entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(entry.key, overflow: TextOverflow.ellipsis)),
                              Chip(label: Text(entry.value.toString()), backgroundColor: Colors.green[100]),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),

              // Suspicious IPs
              if (suspiciousIps.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            Text('Suspicious IP Addresses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[700])),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...suspiciousIps.map((ip) => ListTile(
                          leading: Icon(Icons.computer, color: Colors.red[700]),
                          title: Text(ip),
                          subtitle: const Text('High activity detected'),
                          trailing: TextButton(
                            onPressed: () => _blockIpAddress(ip),
                            child: const Text('Block'),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
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

  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: isError ? Colors.red : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDeleted) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        onDeleted: onDeleted,
        backgroundColor: Colors.blue[100],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedType != null || _selectedSeverity != null || (_startDate != null && _endDate != null);
  }

  Color _getSeverityColor(ActivitySeverity severity) {
    switch (severity) {
      case ActivitySeverity.low:
        return Colors.green;
      case ActivitySeverity.medium:
        return Colors.orange;
      case ActivitySeverity.high:
        return Colors.red;
      case ActivitySeverity.critical:
        return Colors.purple;
    }
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.login:
        return Icons.login;
      case ActivityType.logout:
        return Icons.logout;
      case ActivityType.passwordChange:
        return Icons.lock;
      case ActivityType.profileUpdate:
        return Icons.person;
      case ActivityType.securitySettingChange:
        return Icons.security;
      case ActivityType.roleAssignment:
        return Icons.admin_panel_settings;
      case ActivityType.dataExport:
        return Icons.download;
      case ActivityType.dataImport:
        return Icons.upload;
      case ActivityType.userCreation:
        return Icons.person_add;
      case ActivityType.userDeletion:
        return Icons.person_remove;
      case ActivityType.systemAccess:
        return Icons.computer;
      case ActivityType.apiCall:
        return Icons.api;
      case ActivityType.fileUpload:
        return Icons.cloud_upload;
      case ActivityType.fileDownload:
        return Icons.cloud_download;
      case ActivityType.securityAlert:
        return Icons.warning;
      case ActivityType.failedLogin:
        return Icons.error;
      case ActivityType.suspiciousActivity:
        return Icons.report;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Activities'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ActivityType>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Activity Type'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Types')),
                  ...ActivityType.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.name),
                  )),
                ],
                onChanged: (value) => setState(() => _selectedType = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ActivitySeverity>(
                value: _selectedSeverity,
                decoration: const InputDecoration(labelText: 'Severity'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Severities')),
                  ...ActivitySeverity.values.map((severity) => DropdownMenuItem(
                    value: severity,
                    child: Text(severity.name),
                  )),
                ],
                onChanged: (value) => setState(() => _selectedSeverity = value),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 7)),
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setState(() => _startDate = date);
                      },
                      child: Text(_startDate == null ? 'Start Date' : _formatDate(_startDate!)),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setState(() => _endDate = date);
                      },
                      child: Text(_endDate == null ? 'End Date' : _formatDate(_endDate!)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedType = null;
                _selectedSeverity = null;
                _startDate = null;
                _endDate = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showCleanupDialog(bool isLogs) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cleanup Old ${isLogs ? 'Logs' : 'Sessions'}'),
        content: Text('Remove ${isLogs ? 'logs' : 'sessions'} older than 30 days?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final activityService = context.read<UserActivityService>();
              if (isLogs) {
                await activityService.cleanupOldLogs();
              } else {
                await activityService.cleanupOldSessions();
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${isLogs ? 'Logs' : 'Sessions'} cleaned up successfully')),
              );
            },
            child: const Text('Cleanup'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality would be implemented here')),
    );
  }

  void _endSession(UserSession session, UserActivityService activityService) {
    activityService.endSession(session.id, session.userId, session.userEmail);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session ended successfully')),
    );
  }

  void _blockIpAddress(String ip) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('IP address $ip would be blocked')),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}
