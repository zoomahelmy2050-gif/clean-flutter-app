import 'package:flutter/material.dart';
import '../services/categories_service.dart';

class CategoryFilterWidget extends StatelessWidget {
  final CategoriesService categoriesService;
  final Function(String?)? onCategoryChanged;
  final bool showAllOption;
  final bool compact;

  const CategoryFilterWidget({
    super.key,
    required this.categoriesService,
    this.onCategoryChanged,
    this.showAllOption = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: categoriesService,
      builder: (context, child) {
        if (compact) {
          return _buildCompactFilter(context);
        }
        return _buildFullFilter(context);
      },
    );
  }

  Widget _buildCompactFilter(BuildContext context) {
    final categories = categoriesService.categories;
    final selectedCategory = categoriesService.selectedCategory;

    return PopupMenuButton<String?>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selectedCategory != null 
              ? selectedCategory.color.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selectedCategory?.color ?? Colors.grey,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selectedCategory?.icon ?? Icons.filter_list,
              size: 16,
              color: selectedCategory?.color ?? Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              selectedCategory?.name ?? 'All',
              style: TextStyle(
                color: selectedCategory?.color ?? Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: selectedCategory?.color ?? Colors.grey[600],
            ),
          ],
        ),
      ),
      onSelected: (categoryId) {
        categoriesService.setSelectedCategory(categoryId);
        onCategoryChanged?.call(categoryId);
      },
      itemBuilder: (context) => [
        if (showAllOption)
          const PopupMenuItem<String?>(
            value: null,
            child: Row(
              children: [
                Icon(Icons.all_inclusive, size: 20),
                SizedBox(width: 12),
                Text('All Categories'),
              ],
            ),
          ),
        ...categories.map((category) => PopupMenuItem<String?>(
          value: category.id,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  category.icon,
                  size: 16,
                  color: category.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(category.name)),
              Text(
                '${categoriesService.getTOTPsInCategory(category.id).length}',
                style: TextStyle(
                  color: category.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildFullFilter(BuildContext context) {
    final categories = categoriesService.categories;
    final selectedCategoryId = categoriesService.selectedCategoryId;

    return Container(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (showAllOption)
            _buildFilterChip(
              label: 'All',
              icon: Icons.all_inclusive,
              color: Colors.grey,
              isSelected: selectedCategoryId == null,
              count: null,
              onTap: () {
                categoriesService.setSelectedCategory(null);
                onCategoryChanged?.call(null);
              },
            ),
          ...categories.map((category) {
            final count = categoriesService.getTOTPsInCategory(category.id).length;
            return _buildFilterChip(
              label: category.name,
              icon: category.icon,
              color: category.color,
              isSelected: selectedCategoryId == category.id,
              count: count,
              onTap: () {
                categoriesService.setSelectedCategory(category.id);
                onCategoryChanged?.call(category.id);
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required int? count,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        onSelected: (_) => onTap(),
        avatar: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isSelected ? color : color,
          ),
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (count != null && count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.2) : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        selectedColor: color.withOpacity(0.2),
        checkmarkColor: color,
      ),
    );
  }
}

class CategoryAssignmentDialog extends StatefulWidget {
  final List<String> totpIds;
  final CategoriesService categoriesService;
  final Function(String categoryId)? onAssigned;

  const CategoryAssignmentDialog({
    super.key,
    required this.totpIds,
    required this.categoriesService,
    this.onAssigned,
  });

  @override
  State<CategoryAssignmentDialog> createState() => _CategoryAssignmentDialogState();
}

class _CategoryAssignmentDialogState extends State<CategoryAssignmentDialog> {
  String? _selectedCategoryId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final categories = widget.categoriesService.categories;
    
    return AlertDialog(
      title: Text('Assign to Category (${widget.totpIds.length} items)'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Select a category to assign the selected TOTP codes:'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.maxFinite,
            height: 200,
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedCategoryId == category.id;
                
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      category.icon,
                      color: category.color,
                      size: 20,
                    ),
                  ),
                  title: Text(category.name),
                  subtitle: Text(category.description),
                  trailing: Radio<String>(
                    value: category.id,
                    groupValue: _selectedCategoryId,
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                    activeColor: category.color,
                  ),
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = category.id;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading || _selectedCategoryId == null
              ? null
              : () async {
                  setState(() {
                    _isLoading = true;
                  });
                  
                  try {
                    await widget.categoriesService.bulkAssignTOTPs(
                      widget.totpIds,
                      _selectedCategoryId!,
                    );
                    
                    widget.onAssigned?.call(_selectedCategoryId!);
                    
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${widget.totpIds.length} TOTP codes assigned to category',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error assigning category: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Assign'),
        ),
      ],
    );
  }
}

class CategorySuggestionWidget extends StatelessWidget {
  final String totpName;
  final String? issuer;
  final CategoriesService categoriesService;
  final Function(String categoryId)? onSuggestionAccepted;

  const CategorySuggestionWidget({
    super.key,
    required this.totpName,
    this.issuer,
    required this.categoriesService,
    this.onSuggestionAccepted,
  });

  @override
  Widget build(BuildContext context) {
    final suggestedCategory = categoriesService.suggestCategoryForTOTP(totpName, issuer);
    
    if (suggestedCategory == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: suggestedCategory.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: suggestedCategory.color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: suggestedCategory.color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggested Category',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: suggestedCategory.color,
                    fontSize: 12,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      suggestedCategory.icon,
                      size: 16,
                      color: suggestedCategory.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      suggestedCategory.name,
                      style: TextStyle(
                        color: suggestedCategory.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              onSuggestionAccepted?.call(suggestedCategory.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: suggestedCategory.color,
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
