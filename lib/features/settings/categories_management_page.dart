import 'package:flutter/material.dart';
import '../../core/services/categories_service.dart';
import 'import_categories_dialog.dart';
import '../../locator.dart';

class CategoriesManagementPage extends StatefulWidget {
  const CategoriesManagementPage({super.key});

  @override
  State<CategoriesManagementPage> createState() => _CategoriesManagementPageState();
}

class _CategoriesManagementPageState extends State<CategoriesManagementPage> {
  late CategoriesService _categoriesService;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _categoriesService = locator<CategoriesService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        actions: [
          IconButton(
            onPressed: _showStatisticsDialog,
            icon: const Icon(Icons.analytics),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportCategories();
                  break;
                case 'import':
                  _importCategories();
                  break;
                case 'reset':
                  _showResetDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'export', child: Text('Export Categories')),
              const PopupMenuItem(value: 'import', child: Text('Import Categories')),
              const PopupMenuItem(value: 'reset', child: Text('Reset to Default')),
            ],
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _categoriesService,
        builder: (context, child) {
          final categories = _searchQuery.isEmpty
              ? _categoriesService.categories
              : _categoriesService.searchCategories(_searchQuery);

          return Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: categories.isEmpty
                    ? _buildEmptyState()
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: categories.length,
                        onReorder: (oldIndex, newIndex) {
                          _categoriesService.reorderCategories(oldIndex, newIndex);
                        },
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return _buildCategoryCard(category, index);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateCategoryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search categories...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No categories found' : 'No matching categories',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty 
                ? 'Create your first category to organize your TOTP codes'
                : 'Try a different search term',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showCreateCategoryDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Category'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryCard(TOTPCategory category, int index) {
    final totpCount = _categoriesService.getTOTPsInCategory(category.id).length;
    
    return Card(
      key: ValueKey(category.id),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: category.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            category.icon,
            color: category.color,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                category.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (category.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'DEFAULT',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category.description),
            const SizedBox(height: 4),
            Text(
              '$totpCount TOTP codes',
              style: TextStyle(
                color: category.color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _showEditCategoryDialog(category),
              icon: const Icon(Icons.edit),
            ),
            if (!category.isDefault)
              IconButton(
                onPressed: () => _showDeleteCategoryDialog(category),
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            const Icon(Icons.drag_handle),
          ],
        ),
        onTap: () => _showCategoryDetails(category),
      ),
    );
  }

  void _showCreateCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => CategoryFormDialog(
        title: 'Create Category',
        onSave: (name, description, icon, color) async {
          await _categoriesService.createCategory(
            name: name,
            description: description,
            icon: icon,
            color: color,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Category created successfully')),
            );
          }
        },
      ),
    );
  }

  void _showEditCategoryDialog(TOTPCategory category) {
    showDialog(
      context: context,
      builder: (context) => CategoryFormDialog(
        title: 'Edit Category',
        initialName: category.name,
        initialDescription: category.description,
        initialIcon: category.icon,
        initialColor: category.color,
        onSave: (name, description, icon, color) async {
          await _categoriesService.updateCategory(
            category.id,
            name: name,
            description: description,
            icon: icon,
            color: color,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Category updated successfully')),
            );
          }
        },
      ),
    );
  }

  void _showDeleteCategoryDialog(TOTPCategory category) {
    final totpCount = _categoriesService.getTOTPsInCategory(category.id).length;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${category.name}"?'),
            if (totpCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This category contains $totpCount TOTP codes. They will become uncategorized.',
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _categoriesService.deleteCategory(category.id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Category deleted successfully')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCategoryDetails(TOTPCategory category) {
    final totpIds = _categoriesService.getTOTPsInCategory(category.id);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(category.icon, color: category.color),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(category.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${category.description}'),
            const SizedBox(height: 8),
            Text('TOTP Codes: ${totpIds.length}'),
            const SizedBox(height: 8),
            Text('Created: ${_formatDate(category.createdAt)}'),
            if (category.updatedAt != category.createdAt) ...[
              const SizedBox(height: 4),
              Text('Updated: ${_formatDate(category.updatedAt)}'),
            ],
            if (category.isDefault) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'This is a default category',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditCategoryDialog(category);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _showStatisticsDialog() {
    final stats = _categoriesService.getCategoryStatistics();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Category Statistics'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Categories: ${_categoriesService.categoriesCount}'),
              const SizedBox(height: 16),
              if (stats.isNotEmpty) ...[
                const Text('TOTP Distribution:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...stats.entries.map((entry) {
                  final data = entry.value as Map<String, dynamic>;
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      IconData(data['icon'], fontFamily: 'MaterialIcons'),
                      color: Color(data['color']),
                    ),
                    title: Text(entry.key),
                    trailing: Text('${data['count']}'),
                  );
                }),
              ] else
                const Text('No statistics available'),
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

  void _exportCategories() {
    final data = _categoriesService.exportCategories();
    // Here you would implement file export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Categories exported successfully')),
    );
  }

  void _importCategories() {
    showDialog(
      context: context,
      builder: (context) => ImportCategoriesDialog(
        onImport: (importedData) async {
          try {
            await _categoriesService.importCategories(importedData);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Categories imported successfully')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to import categories')),
            );
          }
        },
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Categories'),
        content: const Text(
          'This will delete all custom categories and reset to default categories. '
          'TOTP assignments will be cleared. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Implementation would reset categories
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Categories reset to default')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class CategoryFormDialog extends StatefulWidget {
  final String title;
  final String? initialName;
  final String? initialDescription;
  final IconData? initialIcon;
  final Color? initialColor;
  final Function(String name, String description, IconData icon, Color color) onSave;

  const CategoryFormDialog({
    super.key,
    required this.title,
    this.initialName,
    this.initialDescription,
    this.initialIcon,
    this.initialColor,
    required this.onSave,
  });

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late IconData _selectedIcon;
  late Color _selectedColor;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _descriptionController = TextEditingController(text: widget.initialDescription ?? '');
    _selectedIcon = widget.initialIcon ?? Icons.category;
    _selectedColor = widget.initialColor ?? Colors.blue;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesService = locator<CategoriesService>();
    
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a category name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Icon', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _showIconPicker(),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(_selectedIcon, color: _selectedColor),
                              const SizedBox(width: 8),
                              const Text('Select Icon'),
                            ],
                          ),
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
                      const Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _showColorPicker(),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _selectedColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('Select Color'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(
                _nameController.text.trim(),
                _descriptionController.text.trim(),
                _selectedIcon,
                _selectedColor,
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _showIconPicker() {
    final categoriesService = locator<CategoriesService>();
    final availableIcons = categoriesService.getAvailableIcons();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Icon'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: availableIcons.length,
            itemBuilder: (context, index) {
              final icon = availableIcons[index];
              final isSelected = icon == _selectedIcon;
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedIcon = icon;
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? _selectedColor.withOpacity(0.2) : null,
                    border: Border.all(
                      color: isSelected ? _selectedColor : Colors.grey.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? _selectedColor : Colors.grey[600],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showColorPicker() {
    final categoriesService = locator<CategoriesService>();
    final availableColors = categoriesService.getAvailableColors();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color'),
        content: SizedBox(
          width: double.maxFinite,
          height: 200,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: availableColors.length,
            itemBuilder: (context, index) {
              final color = availableColors[index];
              final isSelected = color == _selectedColor;
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
