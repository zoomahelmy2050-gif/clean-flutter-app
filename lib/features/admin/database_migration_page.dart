import 'package:flutter/material.dart';
import '../../locator.dart';
import '../../core/services/database_migration_service.dart';

class DatabaseMigrationPage extends StatefulWidget {
  const DatabaseMigrationPage({super.key});

  @override
  State<DatabaseMigrationPage> createState() => _DatabaseMigrationPageState();
}

class _DatabaseMigrationPageState extends State<DatabaseMigrationPage> {
  final DatabaseMigrationService _migrationService = locator<DatabaseMigrationService>();
  bool _isLoading = false;
  Map<String, dynamic>? _migrationStatus;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    setState(() => _isLoading = true);
    try {
      await _migrationService.initialize();
      setState(() => _isInitialized = true);
      await _loadMigrationStatus();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing service: $e')),
        );
      }
    }
  }

  Future<void> _loadMigrationStatus() async {
    if (!_isInitialized) return;
    
    setState(() => _isLoading = true);
    try {
      await _migrationService.refreshStatus();
      setState(() {
        _migrationStatus = _migrationService.migrationStatus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading status: $e')),
        );
      }
    }
  }

  Future<void> _enableDatabaseMode() async {
    setState(() => _isLoading = true);
    try {
      final success = await _migrationService.enableDatabaseMode();
      if (success) {
        await _loadMigrationStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Database mode enabled successfully')),
          );
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to connect to database server')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error enabling database mode: $e')),
        );
      }
    }
  }

  Future<void> _disableDatabaseMode() async {
    setState(() => _isLoading = true);
    try {
      await _migrationService.disableDatabaseMode();
      await _loadMigrationStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database mode disabled, using local storage')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error disabling database mode: $e')),
        );
      }
    }
  }

  Future<void> _migrateToDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Migrate to Database'),
        content: const Text(
          'This will migrate all local users to the database. '
          'Make sure the database server is running and accessible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Migrate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final success = await _migrationService.migrateLocalDataToDatabase();
      setState(() => _isLoading = false);
      await _loadMigrationStatus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
              ? 'Migration completed successfully'
              : 'Migration failed - check logs for details'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Migration failed: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Migration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMigrationStatus,
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 20),
                  _buildMigrationControls(),
                  const SizedBox(height: 20),
                  _buildInformationCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    if (_migrationStatus == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Loading status...'),
        ),
      );
    }

    final status = _migrationStatus!;
    final localUsers = status['localUsers'] as int;
    final databaseUsers = status['databaseUsers'] as int;
    final storageMode = status['storageMode'] as String;
    final databaseServer = status['databaseServer'] as String;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatusRow('Storage Mode', storageMode),
            _buildStatusRow('Database Server', databaseServer),
            _buildStatusRow('Local Users', localUsers.toString()),
            _buildStatusRow('Database Users', databaseUsers.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    Color? valueColor;
    if (label == 'Database Server') {
      valueColor = value == 'Connected' ? Colors.green : Colors.red;
    } else if (label == 'Storage Mode') {
      valueColor = value == 'Database Mode' ? Colors.blue : Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMigrationControls() {
    if (_migrationStatus == null) return const SizedBox();

    final isDatabaseMode = _migrationStatus!['isDatabaseMode'] as bool;
    final localUsers = _migrationStatus!['localUsers'] as int;
    final databaseServer = _migrationStatus!['databaseServer'] as String;
    final serverHealthy = databaseServer == 'Connected';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Migration Controls',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (!isDatabaseMode) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: serverHealthy ? _enableDatabaseMode : null,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Enable Database Mode'),
                ),
              ),
              const SizedBox(height: 8),
              if (localUsers > 0 && serverHealthy)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _migrateToDatabase,
                    icon: const Icon(Icons.sync),
                    label: Text('Migrate $localUsers Local Users to Database'),
                  ),
                ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _disableDatabaseMode,
                  icon: const Icon(Icons.cloud_off),
                  label: const Text('Switch to Local Storage'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildInformationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Database Mode Benefits:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('• Centralized user management'),
            const Text('• Better scalability and performance'),
            const Text('• Advanced security features'),
            const Text('• Multi-device synchronization'),
            const Text('• Backup and recovery capabilities'),
            const SizedBox(height: 16),
            const Text(
              'Local Storage Benefits:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('• Works offline'),
            const Text('• No network dependency'),
            const Text('• Faster local operations'),
            const Text('• Privacy-focused (data stays on device)'),
          ],
        ),
      ),
    );
  }
}
