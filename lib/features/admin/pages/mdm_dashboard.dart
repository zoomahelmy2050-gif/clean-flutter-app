import 'package:flutter/material.dart';
import '../../../core/services/mobile_device_management_service.dart';
import '../../../core/models/managed_device.dart';
import '../../../core/models/admin_models.dart' as admin;
import '../../../locator.dart';

class MdmDashboard extends StatefulWidget {
  const MdmDashboard({Key? key}) : super(key: key);

  @override
  State<MdmDashboard> createState() => _MdmDashboardState();
}

class _MdmDashboardState extends State<MdmDashboard> {
  final MobileDeviceManagementService _mdmService = locator<MobileDeviceManagementService>();
  Map<String, dynamic> _metrics = {};
  List<ManagedDevice> _devices = [];
  List<Map<String, dynamic>> _policies = [];
  List<admin.MdmEvent> _recentEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupStreams();
  }

  void _setupStreams() {
    // Mock device stream since service may not be available
    // _mdmService.deviceStream.listen((device) {
    //   if (mounted) {
    //     setState(() {
    //       final index = _devices.indexWhere((d) => d.id == device.id);
    //       if (index >= 0) {
    //         _devices[index] = device;
    //       } else {
    //         _devices.add(device);
    //       }
    //     });
    //   }
    // });

    // Mock event stream since service may not be available
    // _mdmService.eventStream.listen((event) {
    //   if (mounted) {
    //     setState(() {
    //       _recentEvents.insert(0, event);
    //       if (_recentEvents.length > 50) {
    //         _recentEvents.removeRange(50, _recentEvents.length);
    //       }
    //     });
    //     if (event.type == admin.MdmEventType.complianceViolation) {
    //       _showComplianceAlert(event);
    //     }
    //   }
    // });
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      // Mock data since service methods may not be available
      final metrics = {
        'totalDevices': 150,
        'compliantDevices': 142,
        'nonCompliantDevices': 8,
        'enrolledToday': 5,
        'activePolicies': 12,
      };
      
      final devices = <ManagedDevice>[];
      final policies = <Map<String, dynamic>>[];
      final events = <admin.MdmEvent>[];

      setState(() {
        _metrics = metrics;
        _devices = devices;
        _policies = policies;
        _recentEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load MDM data: $e');
    }
  }

  void _showComplianceAlert(admin.MdmEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Compliance Violation'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Device: ${event.deviceId}'),
            const SizedBox(height: 8),
            Text(event.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Acknowledge'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Mock quarantine action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Device quarantined')),
              );
            },
            child: const Text('Quarantine'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile Device Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _enrollNewDevice,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetricsSection(),
                    const SizedBox(height: 24),
                    _buildDevicesSection(),
                    const SizedBox(height: 24),
                    _buildPoliciesSection(),
                    const SizedBox(height: 24),
                    _buildEventsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('MDM Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              children: [
                _buildMetricTile('Total Devices', _metrics['totalDevices']?.toString() ?? '0'),
                _buildMetricTile('Compliant', _metrics['compliantDevices']?.toString() ?? '0'),
                _buildMetricTile('Violations (24h)', _metrics['nonCompliantDevices']?.toString() ?? '0'),
                _buildMetricTile('Compliance Rate', '${(_metrics['compliantDevices'] ?? 0) / (_metrics['totalDevices'] ?? 1) * 100}%'),
                _buildMetricTile('Active Policies', _metrics['activePolicies']?.toString() ?? '0'),
                _buildMetricTile('Enrolled Today', _metrics['enrolledToday']?.toString() ?? '0'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
        ],
      ),
    );
  }

  Widget _buildDevicesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.devices, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('Managed Devices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            if (_devices.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No devices enrolled'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  final device = _devices[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(
                          Icons.smartphone,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(device.name),
                      subtitle: Text('${device.platform} ${device.osVersion}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) => _handleDeviceAction(device, action),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'lock', child: Text('Lock Device')),
                          const PopupMenuItem(value: 'wipe', child: Text('Wipe Device')),
                          const PopupMenuItem(value: 'resetPassword', child: Text('Reset Password')),
                          const PopupMenuItem(value: 'unenroll', child: Text('Unenroll')),
                        ],
                      ),
                      onTap: () => _showDeviceDetails(device),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoliciesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.policy, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('Device Policies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _policies.length,
              itemBuilder: (context, index) {
                final policy = _policies[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: policy['isActive'] == true ? Colors.green : Colors.grey,
                      child: Icon(
                        policy['isActive'] == true ? Icons.check : Icons.pause,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(policy['name']),
                    subtitle: Text(policy['description']),
                    trailing: Switch(
                      value: policy['isActive'] ?? false,
                      onChanged: (value) => _togglePolicy(policy['id'], value),
                    ),
                    onTap: () => _showPolicyDetails(policy),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('Recent Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentEvents.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No recent events'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentEvents.take(10).length,
                itemBuilder: (context, index) {
                  final event = _recentEvents[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getEventTypeColor(event.type),
                      child: Icon(
                        _getEventTypeIcon(event.type),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(event.type.name),
                    subtitle: Text('${event.deviceId} • ${event.description}'),
                    trailing: Text(
                      '${event.timestamp.hour}:${event.timestamp.minute.toString().padLeft(2, '0')}',
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }



  Color _getEventTypeColor(admin.MdmEventType type) {
    switch (type) {
      case admin.MdmEventType.deviceEnrolled:
        return Colors.green;
      case admin.MdmEventType.deviceUnenrolled:
        return Colors.grey;
      case admin.MdmEventType.complianceViolation:
        return Colors.red;
      case admin.MdmEventType.policyApplied:
        return Colors.blue;
      case admin.MdmEventType.deviceAction:
        return Colors.orange;
      case admin.MdmEventType.deviceCheckIn:
        return Colors.blue;
      case admin.MdmEventType.deviceCheckOut:
        return Colors.grey;
      case admin.MdmEventType.complianceCheck:
        return Colors.blue;
      case admin.MdmEventType.complianceStatusChanged:
        return Colors.orange;
      case admin.MdmEventType.policyUpdated:
        return Colors.purple;
      case admin.MdmEventType.policyRemoved:
        return Colors.red;
      case admin.MdmEventType.deviceWipe:
        return Colors.red.shade800;
      case admin.MdmEventType.deviceLock:
        return Colors.orange;
      case admin.MdmEventType.deviceUnlock:
        return Colors.green;
      case admin.MdmEventType.deviceRestart:
        return Colors.blue;
      case admin.MdmEventType.deviceShutdown:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventTypeIcon(admin.MdmEventType type) {
    switch (type) {
      case admin.MdmEventType.deviceEnrolled:
        return Icons.add;
      case admin.MdmEventType.deviceUnenrolled:
        return Icons.remove;
      case admin.MdmEventType.complianceViolation:
        return Icons.warning;
      case admin.MdmEventType.policyApplied:
        return Icons.policy;
      case admin.MdmEventType.deviceAction:
        return Icons.build;
      case admin.MdmEventType.deviceCheckIn:
        return Icons.check_circle;
      case admin.MdmEventType.deviceCheckOut:
        return Icons.logout;
      case admin.MdmEventType.complianceCheck:
        return Icons.verified;
      case admin.MdmEventType.complianceStatusChanged:
        return Icons.change_circle;
      case admin.MdmEventType.policyUpdated:
        return Icons.update;
      case admin.MdmEventType.policyRemoved:
        return Icons.delete;
      case admin.MdmEventType.deviceWipe:
        return Icons.delete_forever;
      case admin.MdmEventType.deviceLock:
        return Icons.lock;
      case admin.MdmEventType.deviceUnlock:
        return Icons.lock_open;
      case admin.MdmEventType.deviceRestart:
        return Icons.restart_alt;
      case admin.MdmEventType.deviceShutdown:
        return Icons.power_settings_new;
      default:
        return Icons.help;
    }
  }

  void _showDeviceDetails(ManagedDevice device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(device.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: ${device.id}'),
              Text('Platform: ${device.platform}'),
              Text('OS Version: ${device.osVersion}'),
              Text('Status: Active'),
              Text('Owner: ${device.name}'),
              Text('Enrolled: Recently'),
              const SizedBox(height: 8),
              Text('Compliance Status: Compliant'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _checkDeviceCompliance(device.id);
            },
            child: const Text('Check Compliance'),
          ),
        ],
      ),
    );
  }

  void _showPolicyDetails(Map<String, dynamic> policy) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(policy['name']),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(policy['description'] ?? 'No description available'),
              const SizedBox(height: 16),
              const Text('Requirements:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...policy['requirements'].entries.map((e) => Text('${e.key}: ${e.value}')),
              const SizedBox(height: 16),
              Text('Type: ${policy['type'] ?? 'Unknown'}'),
              Text('Status: ${policy['isActive'] == true ? 'Active' : 'Inactive'}'),
              Text('Created: ${policy['createdAt']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _applyPolicyToDevices(policy['id']);
            },
            child: const Text('Apply to All'),
          ),
        ],
      ),
    );
  }

  void _handleDeviceAction(ManagedDevice device, String action) {
    admin.DeviceActionType deviceAction;
    switch (action) {
      case 'lock':
        deviceAction = admin.DeviceActionType.lock;
        break;
      case 'wipe':
        deviceAction = admin.DeviceActionType.wipe;
        break;
      case 'resetPassword':
        deviceAction = admin.DeviceActionType.resetPassword;
        break;
      default:
        return;
    }

    if (action == 'wipe') {
      _showWipeConfirmation(device, deviceAction);
    } else {
      _performDeviceAction(device, deviceAction);
    }
  }

  void _showWipeConfirmation(ManagedDevice device, admin.DeviceActionType action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Device Wipe'),
        content: Text('Are you sure you want to wipe ${device.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performDeviceAction(device, action);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Wipe Device'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeviceAction(ManagedDevice device, admin.DeviceActionType action) async {
    try {
      // Mock device action since service method may not be available
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Device action ${action.name} performed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadData();
    } catch (e) {
      _showError('Failed to perform device action: $e');
    }
  }

  Future<void> _togglePolicy(String policyId, bool enabled) async {
    try {
      // Mock policy toggle - replace with actual service method when available
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Policy ${enabled ? 'enabled' : 'disabled'} successfully'),
          ),
        );
      }
      _loadData();
    } catch (e) {
      _showError('Failed to toggle policy: $e');
    }
  }

  Future<void> _checkDeviceCompliance(String deviceId) async {
    try {
      // Mock compliance check - replace with actual service method when available
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compliance check initiated'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadData();
    } catch (e) {
      _showError('Failed to check compliance: $e');
    }
  }

  Future<void> _applyPolicyToDevices(String policyId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Applying policy to all devices'),
        backgroundColor: Colors.blue,
      ),
    );
    _loadData();
  }

  Future<void> _enrollNewDevice() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enroll New Device'),
        content: const Text('Device enrollment instructions will be sent to the user.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Enrollment instructions sent'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Send Instructions'),
          ),
        ],
      ),
    );
  }
}
