import 'package:flutter/material.dart';
import '../../core/services/conflict_resolution_service.dart';
import '../../core/models/conflict_models.dart';
import '../../locator.dart';
import 'create_conflict_rule_dialog.dart';

class ConflictResolutionPage extends StatefulWidget {
  const ConflictResolutionPage({super.key});

  @override
  State<ConflictResolutionPage> createState() => _ConflictResolutionPageState();
}

class _ConflictResolutionPageState extends State<ConflictResolutionPage>
    with SingleTickerProviderStateMixin {
  late ConflictResolutionService _conflictService;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _conflictService = locator<ConflictResolutionService>();
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
        title: const Text('Conflict Resolution'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending', icon: Icon(Icons.warning)),
            Tab(text: 'Rules', icon: Icon(Icons.rule)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingTab(),
          _buildRulesTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    return ListenableBuilder(
      listenable: _conflictService,
      builder: (context, child) {
        final conflicts = _conflictService.pendingConflicts;

        if (conflicts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text('No pending conflicts', style: TextStyle(fontSize: 18)),
                Text('All data is synchronized', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Text(
                    '${conflicts.length} conflicts need resolution',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  PopupMenuButton<ConflictResolution>(
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Resolve All'),
                        Icon(Icons.arrow_drop_down),
                      ],
                    ),
                    onSelected: (resolution) {
                      _showResolveAllDialog(resolution);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: ConflictResolution.useLocal,
                        child: Text('Use Local'),
                      ),
                      const PopupMenuItem(
                        value: ConflictResolution.useRemote,
                        child: Text('Use Remote'),
                      ),
                      const PopupMenuItem(
                        value: ConflictResolution.skip,
                        child: Text('Skip All'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: conflicts.length,
                itemBuilder: (context, index) {
                  final conflict = conflicts[index];
                  return _buildConflictCard(conflict);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConflictCard(SyncConflict conflict) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: Icon(
          _getConflictIcon(conflict.itemType),
          color: Colors.orange[700],
        ),
        title: Text(
          conflict.itemId,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(conflict.description),
            const SizedBox(height: 4),
            Text(
              'Type: ${conflict.itemType} • ${_formatTime(conflict.timestamp)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDataComparison(conflict),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildResolutionButton(
                      'Use Local',
                      Icons.phone_android,
                      Colors.blue,
                      () => _resolveConflict(conflict, ConflictResolution.useLocal),
                    ),
                    _buildResolutionButton(
                      'Use Remote',
                      Icons.cloud,
                      Colors.green,
                      () => _resolveConflict(conflict, ConflictResolution.useRemote),
                    ),
                    _buildResolutionButton(
                      'Merge',
                      Icons.merge,
                      Colors.purple,
                      () => _resolveConflict(conflict, ConflictResolution.merge),
                    ),
                    _buildResolutionButton(
                      'Skip',
                      Icons.skip_next,
                      Colors.grey,
                      () => _resolveConflict(conflict, ConflictResolution.skip),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataComparison(SyncConflict conflict) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Local Data', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatData(conflict.localData),
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Remote Data', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatData(conflict.remoteData),
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResolutionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withOpacity(0.1),
            foregroundColor: color,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
          ),
          child: Icon(icon),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildRulesTab() {
    return ListenableBuilder(
      listenable: _conflictService,
      builder: (context, child) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Auto-resolve conflicts', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Switch(
                    value: _conflictService.autoResolveEnabled,
                    onChanged: (_) => _conflictService.toggleAutoResolve(),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: _conflictService.rules.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.rule, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No resolution rules', style: TextStyle(fontSize: 18)),
                          const Text('Rules will be created as you resolve conflicts'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _showAddRuleDialog,
                            child: const Text('Add Rule'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _conflictService.rules.length,
                      itemBuilder: (context, index) {
                        final rule = _conflictService.rules[index];
                        return _buildRuleCard(rule);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRuleCard(ConflictResolutionRule rule) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(_getConflictTypeIcon(rule.conflictType)),
        title: Text('${rule.itemType} - ${rule.conflictType.name}'),
        subtitle: Text('Strategy: ${rule.strategy.name}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _deleteRule(rule),
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return ListenableBuilder(
      listenable: _conflictService,
      builder: (context, child) {
        final stats = _conflictService.getConflictStatistics();
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatCard('Total Resolved', stats['totalResolved'].toString()),
            _buildStatCard('Active Rules', stats['rulesCount'].toString()),
            _buildStatCard('Pending Conflicts', stats['pendingCount'].toString()),
            const SizedBox(height: 16),
            const Text('Resolution Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...((stats['resolutionHistory'] as Map<String, int>).entries.map(
              (entry) => ListTile(
                title: Text(entry.key),
                trailing: Text(entry.value.toString()),
              ),
            )),
            const SizedBox(height: 16),
            const Text('Conflict Types', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...((stats['typeBreakdown'] as Map<String, int>).entries.map(
              (entry) => ListTile(
                title: Text(entry.key),
                trailing: Text(entry.value.toString()),
              ),
            )),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 18, color: Colors.blue)),
          ],
        ),
      ),
    );
  }

  void _resolveConflict(SyncConflict conflict, ConflictResolution resolution) {
    _conflictService.resolveConflict(conflict.id, resolution);
    
    // Ask if user wants to create a rule
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Resolution Rule?'),
        content: Text('Would you like to automatically resolve similar conflicts with "${resolution.name}" in the future?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              _conflictService.createRuleFromResolution(conflict, resolution);
              Navigator.pop(context);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _showResolveAllDialog(ConflictResolution resolution) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve All Conflicts'),
        content: Text('Are you sure you want to resolve all conflicts with "${resolution.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _conflictService.resolveAllConflicts(resolution);
              Navigator.pop(context);
            },
            child: const Text('Resolve All'),
          ),
        ],
      ),
    );
  }

  void _showAddRuleDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateConflictRuleDialog(
        onRuleCreated: (rule) {
          _conflictService.addCustomRule(rule);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Custom rule created successfully')),
          );
        },
      ),
    );
  }

  void _deleteRule(ConflictResolutionRule rule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rule'),
        content: Text('Are you sure you want to delete the rule for ${rule.itemType} - ${rule.conflictType.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _conflictService.removeRule(rule.itemType, rule.conflictType);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getConflictIcon(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'totp':
        return Icons.security;
      case 'user':
        return Icons.person;
      default:
        return Icons.data_object;
    }
  }

  IconData _getConflictTypeIcon(ConflictType type) {
    switch (type) {
      case ConflictType.duplicateContent:
        return Icons.content_copy;
      case ConflictType.modifiedContent:
        return Icons.edit;
      case ConflictType.deletedContent:
        return Icons.delete;
      case ConflictType.nameConflict:
        return Icons.label;
      case ConflictType.locationConflict:
        return Icons.location_on;
      case ConflictType.permissionConflict:
        return Icons.security;
      case ConflictType.metadataConflict:
        return Icons.info;
      case ConflictType.versionConflict:
        return Icons.history;
      case ConflictType.dataModified:
        return Icons.edit;
      case ConflictType.dataDeleted:
        return Icons.delete;
      case ConflictType.dataCreated:
        return Icons.add;
      case ConflictType.versionMismatch:
        return Icons.sync_problem;
      case ConflictType.schemaConflict:
        return Icons.schema;
    }
  }

  String _formatData(Map<String, dynamic> data) {
    if (data.isEmpty) return 'No data';
    
    final buffer = StringBuffer();
    data.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    return buffer.toString().trim();
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
