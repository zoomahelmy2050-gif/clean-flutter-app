import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clean_flutter/core/services/local_storage_service.dart';
import 'dart:convert';

class LocalDataViewerPage extends StatefulWidget {
  const LocalDataViewerPage({super.key});

  @override
  State<LocalDataViewerPage> createState() => _LocalDataViewerPageState();
}

class _LocalDataViewerPageState extends State<LocalDataViewerPage> {
  final LocalStorageService _localStorage = LocalStorageService();
  Map<String, dynamic> _allData = {};
  List<String> _users = [];
  String? _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      Map<String, dynamic> data = {};
      for (String key in keys) {
        final value = prefs.get(key);
        data[key] = value;
      }

      final users = await _localStorage.getAllUsers();
      final currentUser = await _localStorage.getCurrentUser();

      setState(() {
        _allData = data;
        _users = users;
        _currentUser = currentUser;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('Are you sure you want to delete all local data? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _localStorage.clearAllData();
      await _loadAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All local data cleared')),
        );
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  String _formatValue(dynamic value) {
    if (value is String) {
      try {
        // Try to parse as JSON for pretty printing
        final decoded = jsonDecode(value);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      } catch (e) {
        return value;
      }
    }
    return value.toString();
  }

  Widget _buildDataTile(String key, dynamic value) {
    final formattedValue = _formatValue(value);
    final isJson = formattedValue.contains('\n');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        title: Text(
          key,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: isJson 
          ? const Text('JSON Data - Tap to expand')
          : Text(
              formattedValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Type: ${value.runtimeType}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _copyToClipboard(formattedValue),
                      icon: const Icon(Icons.copy, size: 16),
                      tooltip: 'Copy value',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SelectableText(
                    formattedValue,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Database Viewer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _loadAllData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _clearAllData,
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Clear All Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Card
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Database Summary',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('Total Keys: ${_allData.length}'),
                          Text('Registered Users: ${_users.length}'),
                          if (_currentUser != null)
                            Text('Current User: $_currentUser')
                          else
                            const Text('Current User: None'),
                          const SizedBox(height: 8),
                          if (_users.isNotEmpty) ...[
                            const Text('Users:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ..._users.map((user) => Text('• $user')),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Data List
                  Expanded(
                    child: _allData.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.storage, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No local data found',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Register a user or sync some data to see it here',
                                  style: TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            children: [
                              const Text(
                                'All Stored Data',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ..._allData.entries
                                  .map((entry) => _buildDataTile(entry.key, entry.value))
                                  .toList(),
                            ],
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
