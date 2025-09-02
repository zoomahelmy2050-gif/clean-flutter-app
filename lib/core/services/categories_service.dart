import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TOTPCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int sortOrder;
  final bool isDefault;

  TOTPCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    required this.sortOrder,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'icon': icon.codePoint,
    'color': color.value,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'sortOrder': sortOrder,
    'isDefault': isDefault,
  };

  factory TOTPCategory.fromJson(Map<String, dynamic> json) {
    return TOTPCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
      color: Color(json['color']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      sortOrder: json['sortOrder'],
      isDefault: json['isDefault'] ?? false,
    );
  }

  TOTPCategory copyWith({
    String? name,
    String? description,
    IconData? icon,
    Color? color,
    DateTime? updatedAt,
    int? sortOrder,
  }) {
    return TOTPCategory(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      sortOrder: sortOrder ?? this.sortOrder,
      isDefault: isDefault,
    );
  }
}

class CategoriesService extends ChangeNotifier {
  List<TOTPCategory> _categories = [];
  Map<String, String> _totpCategories = {}; // TOTP ID -> Category ID
  String? _selectedCategoryId;
  
  static const String _categoriesKey = 'totp_categories';
  static const String _totpCategoriesKey = 'totp_category_assignments';
  static const String _selectedCategoryKey = 'selected_category_id';

  // Getters
  List<TOTPCategory> get categories => List.unmodifiable(_categories);
  Map<String, String> get totpCategories => Map.unmodifiable(_totpCategories);
  String? get selectedCategoryId => _selectedCategoryId;
  TOTPCategory? get selectedCategory => _selectedCategoryId != null 
      ? _categories.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => null as TOTPCategory)
      : null;
  int get categoriesCount => _categories.length;
  bool get hasCategories => _categories.isNotEmpty;

  /// Initialize categories service
  Future<void> initialize() async {
    await _loadData();
    if (_categories.isEmpty) {
      await _createDefaultCategories();
    }
  }

  /// Load data from storage
  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load categories
      final categoriesJson = prefs.getString(_categoriesKey);
      if (categoriesJson != null) {
        final categoriesList = jsonDecode(categoriesJson) as List;
        _categories = categoriesList.map((json) => TOTPCategory.fromJson(json)).toList();
        _categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      }
      
      // Load TOTP category assignments
      final totpCategoriesJson = prefs.getString(_totpCategoriesKey);
      if (totpCategoriesJson != null) {
        _totpCategories = Map<String, String>.from(jsonDecode(totpCategoriesJson));
      }
      
      // Load selected category
      _selectedCategoryId = prefs.getString(_selectedCategoryKey);
    } catch (e) {
      debugPrint('Error loading categories data: $e');
    }
  }

  /// Save data to storage
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save categories
      await prefs.setString(_categoriesKey, 
          jsonEncode(_categories.map((c) => c.toJson()).toList()));
      
      // Save TOTP category assignments
      await prefs.setString(_totpCategoriesKey, jsonEncode(_totpCategories));
      
      // Save selected category
      if (_selectedCategoryId != null) {
        await prefs.setString(_selectedCategoryKey, _selectedCategoryId!);
      } else {
        await prefs.remove(_selectedCategoryKey);
      }
    } catch (e) {
      debugPrint('Error saving categories data: $e');
    }
  }

  /// Create default categories
  Future<void> _createDefaultCategories() async {
    final defaultCategories = [
      TOTPCategory(
        id: _generateId(),
        name: 'Work',
        description: 'Work-related accounts',
        icon: Icons.work,
        color: Colors.blue,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sortOrder: 0,
        isDefault: true,
      ),
      TOTPCategory(
        id: _generateId(),
        name: 'Personal',
        description: 'Personal accounts',
        icon: Icons.person,
        color: Colors.green,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sortOrder: 1,
        isDefault: true,
      ),
      TOTPCategory(
        id: _generateId(),
        name: 'Social',
        description: 'Social media accounts',
        icon: Icons.people,
        color: Colors.purple,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sortOrder: 2,
        isDefault: true,
      ),
      TOTPCategory(
        id: _generateId(),
        name: 'Finance',
        description: 'Banking and financial services',
        icon: Icons.account_balance,
        color: Colors.orange,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sortOrder: 3,
        isDefault: true,
      ),
      TOTPCategory(
        id: _generateId(),
        name: 'Development',
        description: 'Development tools and services',
        icon: Icons.code,
        color: Colors.teal,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sortOrder: 4,
        isDefault: true,
      ),
    ];

    _categories.addAll(defaultCategories);
    await _saveData();
    notifyListeners();
  }

  /// Create new category
  Future<TOTPCategory> createCategory({
    required String name,
    required String description,
    required IconData icon,
    required Color color,
  }) async {
    final category = TOTPCategory(
      id: _generateId(),
      name: name,
      description: description,
      icon: icon,
      color: color,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      sortOrder: _categories.length,
    );

    _categories.add(category);
    await _saveData();
    notifyListeners();
    
    return category;
  }

  /// Update category
  Future<void> updateCategory(
    String categoryId, {
    String? name,
    String? description,
    IconData? icon,
    Color? color,
  }) async {
    final index = _categories.indexWhere((c) => c.id == categoryId);
    if (index != -1) {
      _categories[index] = _categories[index].copyWith(
        name: name,
        description: description,
        icon: icon,
        color: color,
        updatedAt: DateTime.now(),
      );
      
      await _saveData();
      notifyListeners();
    }
  }

  /// Delete category
  Future<void> deleteCategory(String categoryId) async {
    final category = _categories.firstWhere((c) => c.id == categoryId, orElse: () => null as TOTPCategory);
    if (category == null || category.isDefault) return;

    // Remove category assignments
    _totpCategories.removeWhere((totpId, catId) => catId == categoryId);
    
    // Remove category
    _categories.removeWhere((c) => c.id == categoryId);
    
    // Clear selection if deleted category was selected
    if (_selectedCategoryId == categoryId) {
      _selectedCategoryId = null;
    }
    
    await _saveData();
    notifyListeners();
  }

  /// Assign TOTP to category
  Future<void> assignTOTPToCategory(String totpId, String categoryId) async {
    if (_categories.any((c) => c.id == categoryId)) {
      _totpCategories[totpId] = categoryId;
      await _saveData();
      notifyListeners();
    }
  }

  /// Remove TOTP from category
  Future<void> removeTOTPFromCategory(String totpId) async {
    _totpCategories.remove(totpId);
    await _saveData();
    notifyListeners();
  }

  /// Bulk assign TOTPs to category
  Future<void> bulkAssignTOTPs(List<String> totpIds, String categoryId) async {
    if (_categories.any((c) => c.id == categoryId)) {
      for (final totpId in totpIds) {
        _totpCategories[totpId] = categoryId;
      }
      await _saveData();
      notifyListeners();
    }
  }

  /// Get category for TOTP
  TOTPCategory? getCategoryForTOTP(String totpId) {
    final categoryId = _totpCategories[totpId];
    if (categoryId != null) {
      return _categories.firstWhere((c) => c.id == categoryId, orElse: () => null as TOTPCategory);
    }
    return null;
  }

  /// Get TOTPs in category
  List<String> getTOTPsInCategory(String categoryId) {
    return _totpCategories.entries
        .where((entry) => entry.value == categoryId)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get uncategorized TOTPs
  List<String> getUncategorizedTOTPs(List<String> allTotpIds) {
    return allTotpIds.where((id) => !_totpCategories.containsKey(id)).toList();
  }

  /// Set selected category filter
  void setSelectedCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    _saveData();
    notifyListeners();
  }

  /// Clear category filter
  void clearCategoryFilter() {
    _selectedCategoryId = null;
    _saveData();
    notifyListeners();
  }

  /// Reorder categories
  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex--;
    
    final category = _categories.removeAt(oldIndex);
    _categories.insert(newIndex, category);
    
    // Update sort orders
    for (int i = 0; i < _categories.length; i++) {
      _categories[i] = _categories[i].copyWith(sortOrder: i);
    }
    
    await _saveData();
    notifyListeners();
  }

  /// Get category statistics
  Map<String, dynamic> getCategoryStatistics() {
    final stats = <String, dynamic>{};
    
    for (final category in _categories) {
      final totpCount = getTOTPsInCategory(category.id).length;
      stats[category.name] = {
        'id': category.id,
        'count': totpCount,
        'color': category.color.value,
        'icon': category.icon.codePoint,
      };
    }
    
    return stats;
  }

  /// Search categories
  List<TOTPCategory> searchCategories(String query) {
    if (query.isEmpty) return _categories;
    
    final lowerQuery = query.toLowerCase();
    return _categories.where((category) =>
        category.name.toLowerCase().contains(lowerQuery) ||
        category.description.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  /// Get suggested category for TOTP
  TOTPCategory? suggestCategoryForTOTP(String totpName, String? issuer) {
    final name = totpName.toLowerCase();
    final issuerLower = issuer?.toLowerCase() ?? '';
    
    // Work-related keywords
    if (_containsAny(name + issuerLower, ['work', 'office', 'company', 'corp', 'enterprise', 'business', 'slack', 'teams', 'zoom', 'jira', 'confluence'])) {
      return _categories.firstWhere((c) => c.name == 'Work', orElse: () => null as TOTPCategory);
    }
    
    // Social media keywords
    if (_containsAny(name + issuerLower, ['facebook', 'twitter', 'instagram', 'linkedin', 'tiktok', 'snapchat', 'discord', 'reddit', 'social'])) {
      return _categories.firstWhere((c) => c.name == 'Social', orElse: () => null as TOTPCategory);
    }
    
    // Finance keywords
    if (_containsAny(name + issuerLower, ['bank', 'paypal', 'stripe', 'finance', 'money', 'payment', 'credit', 'debit', 'investment'])) {
      return _categories.firstWhere((c) => c.name == 'Finance', orElse: () => null as TOTPCategory);
    }
    
    // Development keywords
    if (_containsAny(name + issuerLower, ['github', 'gitlab', 'bitbucket', 'aws', 'azure', 'google cloud', 'heroku', 'vercel', 'netlify', 'docker', 'kubernetes'])) {
      return _categories.firstWhere((c) => c.name == 'Development', orElse: () => null as TOTPCategory);
    }
    
    // Default to Personal
    return _categories.firstWhere((c) => c.name == 'Personal', orElse: () => null as TOTPCategory);
  }

  /// Export categories
  Map<String, dynamic> exportCategories() {
    return {
      'categories': _categories.map((c) => c.toJson()).toList(),
      'assignments': _totpCategories,
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  /// Import categories
  Future<void> importCategories(Map<String, dynamic> data) async {
    try {
      if (data['categories'] != null) {
        final categoriesList = data['categories'] as List;
        final importedCategories = categoriesList.map((json) => TOTPCategory.fromJson(json)).toList();
        
        // Merge with existing categories (avoid duplicates by name)
        for (final imported in importedCategories) {
          if (!_categories.any((c) => c.name == imported.name)) {
            _categories.add(imported.copyWith(
              updatedAt: DateTime.now(),
            ));
          }
        }
      }
      
      if (data['assignments'] != null) {
        final assignments = Map<String, String>.from(data['assignments']);
        _totpCategories.addAll(assignments);
      }
      
      await _saveData();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to import categories: $e');
    }
  }

  /// Get available icons for categories
  List<IconData> getAvailableIcons() {
    return [
      Icons.work, Icons.person, Icons.people, Icons.account_balance,
      Icons.code, Icons.shopping_cart, Icons.games, Icons.music_note,
      Icons.movie, Icons.sports, Icons.fitness_center, Icons.restaurant,
      Icons.local_hospital, Icons.school, Icons.home, Icons.car_rental,
      Icons.flight, Icons.hotel, Icons.security, Icons.vpn_key,
      Icons.cloud, Icons.storage, Icons.email, Icons.phone,
      Icons.camera, Icons.photo, Icons.video_call, Icons.chat,
      Icons.newspaper, Icons.book, Icons.library_books, Icons.article,
    ];
  }

  /// Get available colors for categories
  List<Color> getAvailableColors() {
    return [
      Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
      Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
      Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
      Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
      Colors.brown, Colors.grey, Colors.blueGrey,
    ];
  }

  /// Helper methods
  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }
}
