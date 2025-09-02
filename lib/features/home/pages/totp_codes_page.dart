import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/totp_manager_service.dart';
import '../../../core/models/totp_entry.dart';
import '../../auth/services/totp_service.dart';
import 'add_totp_page.dart';
import 'dart:async';

class TotpCodesPage extends StatefulWidget {
  const TotpCodesPage({Key? key}) : super(key: key);

  @override
  State<TotpCodesPage> createState() => _TotpCodesPageState();
}

class _TotpCodesPageState extends State<TotpCodesPage> {
  String? _selectedCategory;
  String _searchQuery = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Force refresh to update remaining time
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<TotpManagerService>(
      builder: (context, totpManager, _) {
        List<TotpEntry> entries;
        
        if (_searchQuery.isNotEmpty) {
          entries = totpManager.searchEntries(_searchQuery);
        } else if (_selectedCategory != null) {
          entries = totpManager.getEntriesByCategory(_selectedCategory);
        } else {
          entries = totpManager.entries;
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('TOTP Codes'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _showSearchDialog(),
              ),
              IconButton(
                icon: const Icon(Icons.category),
                onPressed: () => _showCategoryDialog(totpManager),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _navigateToAddTotp(),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await totpManager.loadEntries();
            },
            child: entries.isEmpty
                ? _buildEmptyState(theme)
                : _buildCodesList(entries, totpManager, theme),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _navigateToAddTotp,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.security,
            size: 100,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'No TOTP codes yet',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            'Add your first TOTP code to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _navigateToAddTotp,
            icon: const Icon(Icons.add),
            label: const Text('Add TOTP Code'),
          ),
        ],
      ),
    );
  }

  Widget _buildCodesList(
    List<TotpEntry> entries,
    TotpManagerService totpManager,
    ThemeData theme,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final code = totpManager.getCode(entry.id) ?? '------';
        final remainingSeconds = totpManager.getRemainingSeconds(entry.id) ?? 0;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getColorFromString(entry.color),
              child: Text(
                entry.icon ?? entry.name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              entry.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.issuer),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatCode(code),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    _buildTimerIndicator(remainingSeconds, theme),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copyCode(code, entry.id, totpManager),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(
                    value,
                    entry,
                    totpManager,
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () => _copyCode(code, entry.id, totpManager),
          ),
        );
      },
    );
  }

  Widget _buildTimerIndicator(int seconds, ThemeData theme) {
    final progress = seconds / 30;
    final color = seconds <= 5
        ? Colors.red
        : seconds <= 10
            ? Colors.orange
            : theme.colorScheme.primary;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        Text(
          seconds.toString(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatCode(String code) {
    if (code.length == 6) {
      return '${code.substring(0, 3)} ${code.substring(3)}';
    }
    return code;
  }

  Color _getColorFromString(String? colorString) {
    if (colorString == null) return Colors.blue;
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (_) {
      return Colors.blue;
    }
  }

  void _copyCode(String code, String entryId, TotpManagerService manager) {
    if (code != '------') {
      Clipboard.setData(ClipboardData(text: code));
      manager.markAsUsed(entryId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search TOTP Codes'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter search term...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog(TotpManagerService manager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.all_inclusive),
                title: const Text('All'),
                selected: _selectedCategory == null,
                onTap: () {
                  setState(() {
                    _selectedCategory = null;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Uncategorized'),
                selected: _selectedCategory == '',
                onTap: () {
                  setState(() {
                    _selectedCategory = '';
                  });
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ...manager.categories.map((category) => ListTile(
                    leading: Text(
                      category.icon ?? '📁',
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(category.name),
                    selected: _selectedCategory == category.id,
                    onTap: () {
                      setState(() {
                        _selectedCategory = category.id;
                      });
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _showAddCategoryDialog(manager),
            child: const Text('Add Category'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(TotpManagerService manager) {
    final nameController = TextEditingController();
    final iconController = TextEditingController();
    final colorController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g., Finance',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: iconController,
              decoration: const InputDecoration(
                labelText: 'Icon (Emoji)',
                hintText: 'e.g., 💰',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: colorController,
              decoration: const InputDecoration(
                labelText: 'Color (Hex)',
                hintText: 'e.g., #FF5722',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await manager.addCategory(
                  name: nameController.text,
                  icon: iconController.text.isNotEmpty ? iconController.text : null,
                  color: colorController.text.isNotEmpty ? colorController.text : null,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(
    String action,
    TotpEntry entry,
    TotpManagerService manager,
  ) {
    switch (action) {
      case 'edit':
        _showEditDialog(entry, manager);
        break;
      case 'delete':
        _showDeleteConfirmation(entry, manager);
        break;
    }
  }

  void _showEditDialog(TotpEntry entry, TotpManagerService manager) {
    final nameController = TextEditingController(text: entry.name);
    final issuerController = TextEditingController(text: entry.issuer);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit TOTP Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: issuerController,
              decoration: const InputDecoration(
                labelText: 'Issuer',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await manager.updateEntry(
                entry.copyWith(
                  name: nameController.text,
                  issuer: issuerController.text,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(TotpEntry entry, TotpManagerService manager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete TOTP Entry'),
        content: Text('Are you sure you want to delete "${entry.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await manager.deleteEntry(entry.id);
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddTotp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTotpPage()),
    );
  }
}
