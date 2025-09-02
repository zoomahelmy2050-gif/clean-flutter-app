import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/migration_service.dart';
import '../../../core/services/backend_sync_service.dart';
import '../../../core/config/app_config.dart';
import 'backend_login_dialog.dart';

class DatabaseMigrationScreen extends StatefulWidget {
  const DatabaseMigrationScreen({Key? key}) : super(key: key);

  @override
  _DatabaseMigrationScreenState createState() => _DatabaseMigrationScreenState();
}

class _DatabaseMigrationScreenState extends State<DatabaseMigrationScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadStatus();
    _startAutoSync();
  }
  
  Future<void> _checkAuthAndLoadStatus() async {
    // Show login dialog if no auth token
    final migrationService = context.read<MigrationService>();
    if (!migrationService.hasAuthToken) {
      final success = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => ChangeNotifierProvider.value(
          value: migrationService,
          child: const BackendLoginDialog(),
        ),
      );
      if (success != true) {
        // User cancelled login
        return;
      }
    }
    _loadMigrationStatus();
  }

  void _loadMigrationStatus() {
    Future.microtask(() {
      context.read<MigrationService>().fetchMigrationStatus();
    });
  }

  void _startAutoSync() {
    Future.microtask(() {
      context.read<BackendSyncService>().startAutoSync(intervalSeconds: 30);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMigrationStatus,
          ),
        ],
      ),
      body: Consumer2<MigrationService, BackendSyncService>(
        builder: (context, migrationService, syncService, child) {
          if (migrationService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDatabaseStatus(migrationService),
                const SizedBox(height: 24),
                _buildSyncStatus(syncService),
                const SizedBox(height: 24),
                _buildMigrationsList(migrationService),
                const SizedBox(height: 24),
                _buildActions(migrationService, syncService),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDatabaseStatus(MigrationService service) {
    final status = service.status;
    final isConnected = status?.databaseConnected ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isConnected ? Icons.check_circle : Icons.error,
                  color: isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Database Status',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Connection', isConnected ? 'Connected' : 'Disconnected'),
            _buildInfoRow('Environment', AppConfig.environment),
            _buildInfoRow('Backend URL', AppConfig.backendUrl),
            if (status?.error != null)
              _buildInfoRow('Error', status!.error!, isError: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatus(BackendSyncService service) {
    final status = service.syncStatus;
    final pendingCount = service.pendingItems.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  service.isSyncing
                      ? Icons.sync
                      : (pendingCount > 0 ? Icons.sync_problem : Icons.sync_disabled),
                  color: service.isSyncing
                      ? Colors.blue
                      : (pendingCount > 0 ? Colors.orange : Colors.grey),
                ),
                const SizedBox(width: 8),
                Text(
                  'Sync Status',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (service.isSyncing)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Status', service.isSyncing ? 'Syncing...' : 'Idle'),
            _buildInfoRow('Pending Items', pendingCount.toString()),
            if (status != null) ...[
              _buildInfoRow('Queue - Pending', status.queue.pending.toString()),
              _buildInfoRow('Queue - Completed', status.queue.completed.toString()),
              _buildInfoRow('Queue - Failed', status.queue.failed.toString()),
            ],
            if (service.lastSyncTime != null)
              _buildInfoRow(
                'Last Sync',
                _formatDateTime(service.lastSyncTime!),
              ),
            if (service.lastSyncError != null)
              _buildInfoRow('Last Error', service.lastSyncError!, isError: true),
          ],
        ),
      ),
    );
  }

  Widget _buildMigrationsList(MigrationService service) {
    final migrations = service.migrations;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Migrations History',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (migrations.isEmpty)
              const Text('No migrations found')
            else
              ...migrations.map((migration) => _buildMigrationItem(migration)),
          ],
        ),
      ),
    );
  }

  Widget _buildMigrationItem(Migration migration) {
    IconData icon;
    Color color;

    if (migration.isApplied) {
      icon = Icons.check_circle;
      color = Colors.green;
    } else if (migration.isFailed) {
      icon = Icons.error;
      color = Colors.red;
    } else if (migration.isRolledBack) {
      icon = Icons.undo;
      color = Colors.orange;
    } else {
      icon = Icons.pending;
      color = Colors.grey;
    }

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(migration.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Version: ${migration.version}'),
          Text('Status: ${migration.status}'),
          if (migration.appliedAt != null)
            Text('Applied: ${_formatDateTime(migration.appliedAt!)}'),
          if (migration.error != null)
            Text(
              'Error: ${migration.error}',
              style: const TextStyle(color: Colors.red),
            ),
        ],
      ),
      dense: true,
    );
  }

  Widget _buildActions(MigrationService migrationService, BackendSyncService syncService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: migrationService.isLoading
                      ? null
                      : () => _applyMigrations(migrationService),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Apply Migrations'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: syncService.isSyncing
                      ? null
                      : () => syncService.syncAll(),
                  icon: const Icon(Icons.sync),
                  label: const Text('Force Sync'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
                if (syncService.pendingItems.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => _clearSyncQueue(syncService),
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Sync Queue'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                if (AppConfig.environment != 'production')
                  ElevatedButton.icon(
                    onPressed: migrationService.isLoading
                        ? null
                        : () => _resetDatabase(migrationService),
                    icon: const Icon(Icons.warning),
                    label: const Text('Reset Database'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isError ? Colors.red : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _applyMigrations(MigrationService service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply Migrations'),
        content: const Text('Are you sure you want to apply pending database migrations?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await service.applyMigrations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Migrations applied successfully'
                  : 'Failed to apply migrations: ${service.error}',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resetDatabase(MigrationService service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Database'),
        content: const Text(
          'WARNING: This will delete all data and reset the database. This action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await service.resetDatabase();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Database reset successfully'
                  : 'Failed to reset database: ${service.error}',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearSyncQueue(BackendSyncService service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Sync Queue'),
        content: const Text('Are you sure you want to clear all pending sync items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await service.clearSyncQueue();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync queue cleared'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Stop auto-sync when leaving the screen
    context.read<BackendSyncService>().stopAutoSync();
    super.dispose();
  }
}
