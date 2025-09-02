import 'package:flutter/material.dart';
import 'dart:convert';

class ImportCategoriesDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onImport;

  const ImportCategoriesDialog({Key? key, required this.onImport}) : super(key: key);

  @override
  State<ImportCategoriesDialog> createState() => _ImportCategoriesDialogState();
}

class _ImportCategoriesDialogState extends State<ImportCategoriesDialog> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _jsonController = TextEditingController();
  final TextEditingController _csvController = TextEditingController();
  bool _isValidJson = false;
  bool _isValidCsv = false;
  Map<String, dynamic>? _previewData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _jsonController.dispose();
    _csvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            AppBar(
              title: const Text('Import Categories'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.code), text: 'JSON'),
                  Tab(icon: Icon(Icons.table_chart), text: 'CSV'),
                  Tab(icon: Icon(Icons.cloud_upload), text: 'File Upload'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildJsonTab(),
                  _buildCsvTab(),
                  _buildFileUploadTab(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: _canImport() ? _performImport : null,
                    child: const Text('Import'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJsonTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paste JSON Data',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Expected format: {"categories": [{"name": "Category Name", "color": "#FF0000", "icon": "icon_name"}]}',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: _jsonController,
              decoration: InputDecoration(
                hintText: 'Paste your JSON data here...',
                border: const OutlineInputBorder(),
                suffixIcon: _isValidJson 
                    ? const Icon(Icons.check, color: Colors.green)
                    : _jsonController.text.isNotEmpty
                        ? const Icon(Icons.error, color: Colors.red)
                        : null,
              ),
              maxLines: null,
              expands: true,
              onChanged: _validateJson,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _loadSampleJson,
                icon: const Icon(Icons.code),
                label: const Text('Load Sample'),
              ),
              const SizedBox(width: 16),
              if (_isValidJson)
                ElevatedButton.icon(
                  onPressed: _previewJson,
                  icon: const Icon(Icons.preview),
                  label: const Text('Preview'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCsvTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paste CSV Data',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Expected format: name,color,icon\\nCategory Name,#FF0000,icon_name',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: _csvController,
              decoration: InputDecoration(
                hintText: 'Paste your CSV data here...',
                border: const OutlineInputBorder(),
                suffixIcon: _isValidCsv 
                    ? const Icon(Icons.check, color: Colors.green)
                    : _csvController.text.isNotEmpty
                        ? const Icon(Icons.error, color: Colors.red)
                        : null,
              ),
              maxLines: null,
              expands: true,
              onChanged: _validateCsv,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _loadSampleCsv,
                icon: const Icon(Icons.table_chart),
                label: const Text('Load Sample'),
              ),
              const SizedBox(width: 16),
              if (_isValidCsv)
                ElevatedButton.icon(
                  onPressed: _previewCsv,
                  icon: const Icon(Icons.preview),
                  label: const Text('Preview'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFileUploadTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_upload, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'File Upload',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload JSON or CSV files containing category data',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.folder_open),
            label: const Text('Choose File'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Supported formats: .json, .csv',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _validateJson(String value) {
    setState(() {
      try {
        if (value.isEmpty) {
          _isValidJson = false;
          return;
        }
        
        final data = jsonDecode(value);
        if (data is Map<String, dynamic> && data.containsKey('categories')) {
          final categories = data['categories'];
          if (categories is List && categories.isNotEmpty) {
            // Validate each category has required fields
            for (final category in categories) {
              if (category is Map<String, dynamic> && 
                  category.containsKey('name') && 
                  category['name'] is String &&
                  category['name'].toString().isNotEmpty) {
                _isValidJson = true;
              } else {
                _isValidJson = false;
                return;
              }
            }
          } else {
            _isValidJson = false;
          }
        } else {
          _isValidJson = false;
        }
      } catch (e) {
        _isValidJson = false;
      }
    });
  }

  void _validateCsv(String value) {
    setState(() {
      try {
        if (value.isEmpty) {
          _isValidCsv = false;
          return;
        }
        
        final lines = value.split('\n').where((line) => line.trim().isNotEmpty).toList();
        if (lines.length < 2) { // At least header + one data row
          _isValidCsv = false;
          return;
        }
        
        final header = lines[0].toLowerCase();
        if (!header.contains('name')) {
          _isValidCsv = false;
          return;
        }
        
        // Validate data rows
        for (int i = 1; i < lines.length; i++) {
          final parts = lines[i].split(',');
          if (parts.isEmpty || parts[0].trim().isEmpty) {
            _isValidCsv = false;
            return;
          }
        }
        
        _isValidCsv = true;
      } catch (e) {
        _isValidCsv = false;
      }
    });
  }

  void _loadSampleJson() {
    final sample = {
      "categories": [
        {
          "name": "Work",
          "color": "#2196F3",
          "icon": "work",
          "description": "Work-related items"
        },
        {
          "name": "Personal",
          "color": "#4CAF50",
          "icon": "person",
          "description": "Personal items"
        },
        {
          "name": "Finance",
          "color": "#FF9800",
          "icon": "account_balance",
          "description": "Financial documents"
        }
      ]
    };
    
    _jsonController.text = const JsonEncoder.withIndent('  ').convert(sample);
    _validateJson(_jsonController.text);
  }

  void _loadSampleCsv() {
    const sample = '''name,color,icon,description
Work,#2196F3,work,Work-related items
Personal,#4CAF50,person,Personal items
Finance,#FF9800,account_balance,Financial documents
Health,#F44336,local_hospital,Health and medical
Education,#9C27B0,school,Educational materials''';
    
    _csvController.text = sample;
    _validateCsv(_csvController.text);
  }

  void _previewJson() {
    try {
      final data = jsonDecode(_jsonController.text);
      _showPreviewDialog(data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid JSON: $e')),
      );
    }
  }

  void _previewCsv() {
    try {
      final data = _parseCsvToJson(_csvController.text);
      _showPreviewDialog(data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid CSV: $e')),
      );
    }
  }

  Map<String, dynamic> _parseCsvToJson(String csvData) {
    final lines = csvData.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.isEmpty) throw Exception('Empty CSV data');
    
    final headers = lines[0].split(',').map((h) => h.trim().toLowerCase()).toList();
    final nameIndex = headers.indexOf('name');
    final colorIndex = headers.indexOf('color');
    final iconIndex = headers.indexOf('icon');
    final descriptionIndex = headers.indexOf('description');
    
    if (nameIndex == -1) throw Exception('Missing "name" column');
    
    final categories = <Map<String, dynamic>>[];
    
    for (int i = 1; i < lines.length; i++) {
      final parts = lines[i].split(',').map((p) => p.trim()).toList();
      if (parts.length <= nameIndex || parts[nameIndex].isEmpty) continue;
      
      final category = <String, dynamic>{
        'name': parts[nameIndex],
      };
      
      if (colorIndex != -1 && colorIndex < parts.length && parts[colorIndex].isNotEmpty) {
        category['color'] = parts[colorIndex];
      }
      
      if (iconIndex != -1 && iconIndex < parts.length && parts[iconIndex].isNotEmpty) {
        category['icon'] = parts[iconIndex];
      }
      
      if (descriptionIndex != -1 && descriptionIndex < parts.length && parts[descriptionIndex].isNotEmpty) {
        category['description'] = parts[descriptionIndex];
      }
      
      categories.add(category);
    }
    
    return {'categories': categories};
  }

  void _showPreviewDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preview Import Data'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Found ${(data['categories'] as List).length} categories:'),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: (data['categories'] as List).length,
                  itemBuilder: (context, index) {
                    final category = (data['categories'] as List)[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _parseColor(category['color']),
                          child: Icon(
                            _parseIcon(category['icon']),
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        title: Text(category['name']),
                        subtitle: category['description'] != null 
                            ? Text(category['description'])
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _previewData = data);
            },
            child: const Text('Use This Data'),
          ),
        ],
      ),
    );
  }

  void _pickFile() {
    // In a real implementation, you would use file_picker package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File picker would be implemented using file_picker package'),
      ),
    );
  }

  bool _canImport() {
    return _isValidJson || _isValidCsv || _previewData != null;
  }

  void _performImport() {
    Map<String, dynamic>? dataToImport;
    
    if (_previewData != null) {
      dataToImport = _previewData;
    } else if (_isValidJson) {
      try {
        dataToImport = jsonDecode(_jsonController.text);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('JSON parsing error: $e')),
        );
        return;
      }
    } else if (_isValidCsv) {
      try {
        dataToImport = _parseCsvToJson(_csvController.text);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV parsing error: $e')),
        );
        return;
      }
    }
    
    if (dataToImport != null) {
      Navigator.pop(context);
      widget.onImport(dataToImport);
    }
  }

  Color _parseColor(dynamic colorValue) {
    if (colorValue == null) return Colors.blue;
    
    try {
      String colorString = colorValue.toString();
      if (colorString.startsWith('#')) {
        colorString = colorString.substring(1);
      }
      return Color(int.parse('FF$colorString', radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  IconData _parseIcon(dynamic iconValue) {
    if (iconValue == null) return Icons.category;
    
    final iconMap = {
      'work': Icons.work,
      'person': Icons.person,
      'account_balance': Icons.account_balance,
      'local_hospital': Icons.local_hospital,
      'school': Icons.school,
      'home': Icons.home,
      'shopping_cart': Icons.shopping_cart,
      'restaurant': Icons.restaurant,
      'directions_car': Icons.directions_car,
      'flight': Icons.flight,
    };
    
    return iconMap[iconValue.toString()] ?? Icons.category;
  }
}
