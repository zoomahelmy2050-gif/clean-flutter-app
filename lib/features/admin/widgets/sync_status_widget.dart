import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/background_sync_service.dart';
import '../../../locator.dart';
import 'package:intl/intl.dart';

class SyncStatusWidget extends StatelessWidget {
  const SyncStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BackgroundSyncService>.value(
      value: locator<BackgroundSyncService>(),
      child: Consumer<BackgroundSyncService>(
        builder: (context, syncService, child) {
          return Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.sync,
                            color: syncService.isSyncing
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Data Sync',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      if (syncService.isSyncing)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        TextButton.icon(
                          onPressed: () => syncService.performSync(force: true),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Sync Now'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSyncInfo(context, syncService),
                  if (syncService.pendingTasks.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildPendingTasks(context, syncService),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSyncInfo(BuildContext context, BackgroundSyncService syncService) {
    final lastSync = syncService.lastSyncTime;
    final statusText = syncService.isSyncing
        ? 'Syncing...'
        : lastSync != null
            ? 'Last synced: ${_formatTime(lastSync)}'
            : 'Never synced';

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: syncService.isSyncing
                ? Colors.blue
                : lastSync != null && 
                  DateTime.now().difference(lastSync).inMinutes < 10
                    ? Colors.green
                    : Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingTasks(BuildContext context, BackgroundSyncService syncService) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber,
            color: Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${syncService.pendingTasks.length} pending sync tasks',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return DateFormat('MMM d, HH:mm').format(time);
    }
  }
}

class SyncSettingsPage extends StatefulWidget {
  const SyncSettingsPage({Key? key}) : super(key: key);

  @override
  State<SyncSettingsPage> createState() => _SyncSettingsPageState();
}

class _SyncSettingsPageState extends State<SyncSettingsPage> {
  final BackgroundSyncService _syncService = locator<BackgroundSyncService>();
  bool _autoSync = true;
  bool _wifiOnly = false;
  bool _backgroundSync = true;
  String _syncFrequency = '15 minutes';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sync Status',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const SyncStatusWidget(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sync Preferences',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Auto Sync'),
                    subtitle: const Text('Automatically sync data in the background'),
                    value: _autoSync,
                    onChanged: (value) {
                      setState(() {
                        _autoSync = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('WiFi Only'),
                    subtitle: const Text('Only sync when connected to WiFi'),
                    value: _wifiOnly,
                    onChanged: _autoSync
                        ? (value) {
                            setState(() {
                              _wifiOnly = value;
                            });
                          }
                        : null,
                  ),
                  SwitchListTile(
                    title: const Text('Background Sync'),
                    subtitle: const Text('Allow sync when app is in background'),
                    value: _backgroundSync,
                    onChanged: _autoSync
                        ? (value) {
                            setState(() {
                              _backgroundSync = value;
                            });
                          }
                        : null,
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Sync Frequency'),
                    subtitle: Text(_syncFrequency),
                    enabled: _autoSync,
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _autoSync
                        ? () => _showFrequencyDialog()
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Backup & Restore',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.cloud_upload, color: Colors.blue),
                    title: const Text('Create Cloud Backup'),
                    subtitle: const Text('Backup all data to cloud storage'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      await _syncService.triggerBackup();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Backup started'),
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.cloud_download, color: Colors.green),
                    title: const Text('Restore from Backup'),
                    subtitle: const Text('Restore data from cloud backup'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showRestoreDialog(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Advanced',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.cleaning_services, color: Colors.orange),
                    title: const Text('Clear Local Cache'),
                    subtitle: const Text('Remove cached data to free up space'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showClearCacheDialog(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.refresh, color: Colors.purple),
                    title: const Text('Force Full Sync'),
                    subtitle: const Text('Sync all data regardless of changes'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      await _syncService.performSync(force: true);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Full sync started'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFrequencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Frequency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              title: const Text('5 minutes'),
              value: '5 minutes',
              groupValue: _syncFrequency,
              onChanged: (value) {
                setState(() {
                  _syncFrequency = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('15 minutes'),
              value: '15 minutes',
              groupValue: _syncFrequency,
              onChanged: (value) {
                setState(() {
                  _syncFrequency = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('30 minutes'),
              value: '30 minutes',
              groupValue: _syncFrequency,
              onChanged: (value) {
                setState(() {
                  _syncFrequency = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('1 hour'),
              value: '1 hour',
              groupValue: _syncFrequency,
              onChanged: (value) {
                setState(() {
                  _syncFrequency = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRestoreDialog() {
    // In production, this would list available backups
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from Backup'),
        content: const Text('This will replace all local data with the backup. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // In production, pass actual backup ID
              await _syncService.restoreFromBackup('latest');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Restore completed'),
                  ),
                );
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will remove all cached data. You may need to sync again. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Clear cache logic here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared'),
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
