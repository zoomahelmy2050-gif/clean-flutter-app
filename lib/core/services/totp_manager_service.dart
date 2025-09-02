import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/totp_entry.dart';
import '../models/totp_category.dart';
import 'encrypted_storage_service.dart';
import '../../features/auth/services/totp_service.dart';

class TotpManagerService extends ChangeNotifier {
  static const String _entriesKey = 'totp_entries';
  static const String _categoriesKey = 'totp_categories';
  
  final EncryptedStorageService _storage = EncryptedStorageService();
  final TotpService _totpService = TotpService();
  final Uuid _uuid = const Uuid();
  
  List<TotpEntry> _entries = [];
  List<TotpCategory> _categories = [];
  Timer? _refreshTimer;
  
  List<TotpEntry> get entries => _entries;
  List<TotpCategory> get categories => _categories;
  
  // Current TOTP codes cache
  final Map<String, String> _currentCodes = {};
  final Map<String, int> _remainingSeconds = {};
  
  String? getCode(String entryId) => _currentCodes[entryId];
  int? getRemainingSeconds(String entryId) => _remainingSeconds[entryId];
  
  Future<void> initialize() async {
    // EncryptedStorageService is already initialized in main.dart
    await loadEntries();
    await loadCategories();
    _startRefreshTimer();
  }
  
  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateAllCodes();
    });
  }
  
  void _updateAllCodes() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final remainingTime = 30 - (now % 30);
    
    for (final entry in _entries) {
      // Generate TOTP code
      final code = _generateCode(entry.secret);
      _currentCodes[entry.id] = code;
      _remainingSeconds[entry.id] = remainingTime;
    }
    
    notifyListeners();
  }
  
  String _generateCode(String secret) {
    try {
      // Use the real TOTP service to generate codes
      return _totpService.generateCode(secret);
    } catch (e) {
      print('Error generating TOTP code: $e');
      return '000000';
    }
  }
  
  Future<void> loadEntries() async {
    final data = await _storage.getSecureJson(_entriesKey);
    if (data != null && data['entries'] != null) {
      final entriesList = data['entries'] as List;
      _entries = entriesList
          .map((e) => TotpEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      _updateAllCodes();
      notifyListeners();
    }
  }
  
  Future<void> loadCategories() async {
    final data = await _storage.getSecureJson(_categoriesKey);
    if (data != null && data['categories'] != null) {
      final categoriesList = data['categories'] as List;
      _categories = categoriesList
          .map((e) => TotpCategory.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } else {
      // Create default categories
      await _createDefaultCategories();
    }
  }
  
  Future<void> _createDefaultCategories() async {
    _categories = [
      TotpCategory(
        id: _uuid.v4(),
        name: 'Personal',
        icon: '👤',
        color: '#2196F3',
        order: 0,
      ),
      TotpCategory(
        id: _uuid.v4(),
        name: 'Work',
        icon: '💼',
        color: '#4CAF50',
        order: 1,
      ),
      TotpCategory(
        id: _uuid.v4(),
        name: 'Finance',
        icon: '💰',
        color: '#FF9800',
        order: 2,
      ),
      TotpCategory(
        id: _uuid.v4(),
        name: 'Social',
        icon: '🌐',
        color: '#9C27B0',
        order: 3,
      ),
    ];
    await saveCategories();
  }
  
  Future<void> saveEntries() async {
    await _storage.storeSecureJson(_entriesKey, {
      'entries': _entries.map((e) => e.toJson()).toList(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
  
  Future<void> saveCategories() async {
    await _storage.storeSecureJson(_categoriesKey, {
      'categories': _categories.map((e) => e.toJson()).toList(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
  
  Future<TotpEntry> addEntry({
    required String name,
    required String issuer,
    required String secret,
    String? category,
    String? icon,
    String? color,
    Map<String, dynamic>? metadata,
  }) async {
    final entry = TotpEntry(
      id: _uuid.v4(),
      name: name,
      issuer: issuer,
      secret: secret,
      category: category,
      icon: icon,
      color: color,
      createdAt: DateTime.now(),
      metadata: metadata,
    );
    
    _entries.add(entry);
    await saveEntries();
    _updateAllCodes();
    notifyListeners();
    
    return entry;
  }
  
  Future<void> updateEntry(TotpEntry entry) async {
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      _entries[index] = entry;
      await saveEntries();
      _updateAllCodes();
      notifyListeners();
    }
  }
  
  Future<void> deleteEntry(String entryId) async {
    _entries.removeWhere((e) => e.id == entryId);
    _currentCodes.remove(entryId);
    _remainingSeconds.remove(entryId);
    await saveEntries();
    notifyListeners();
  }
  
  Future<void> markAsUsed(String entryId) async {
    final index = _entries.indexWhere((e) => e.id == entryId);
    if (index != -1) {
      _entries[index] = _entries[index].copyWith(
        lastUsedAt: DateTime.now(),
      );
      await saveEntries();
      notifyListeners();
    }
  }
  
  Future<TotpCategory> addCategory({
    required String name,
    String? icon,
    String? color,
  }) async {
    final category = TotpCategory(
      id: _uuid.v4(),
      name: name,
      icon: icon,
      color: color,
      order: _categories.length,
    );
    
    _categories.add(category);
    await saveCategories();
    notifyListeners();
    
    return category;
  }
  
  Future<void> updateCategory(TotpCategory category) async {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      await saveCategories();
      notifyListeners();
    }
  }
  
  Future<void> deleteCategory(String categoryId) async {
    // Move entries from this category to uncategorized
    for (var i = 0; i < _entries.length; i++) {
      if (_entries[i].category == categoryId) {
        _entries[i] = _entries[i].copyWith(category: null);
      }
    }
    
    _categories.removeWhere((c) => c.id == categoryId);
    await saveCategories();
    await saveEntries();
    notifyListeners();
  }
  
  List<TotpEntry> getEntriesByCategory(String? categoryId) {
    if (categoryId == null) {
      return _entries.where((e) => e.category == null).toList();
    }
    return _entries.where((e) => e.category == categoryId).toList();
  }
  
  List<TotpEntry> searchEntries(String query) {
    final lowerQuery = query.toLowerCase();
    return _entries.where((e) =>
      e.name.toLowerCase().contains(lowerQuery) ||
      e.issuer.toLowerCase().contains(lowerQuery)
    ).toList();
  }
  
  Future<String> exportBackup(String password) async {
    // Export both entries and categories
    final backup = {
      'entries': _entries.map((e) => e.toJson()).toList(),
      'categories': _categories.map((c) => c.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
    
    // Use encrypted storage's backup feature
    await _storage.storeSecureJson('temp_backup', backup);
    final encryptedBackup = await _storage.exportEncryptedBackup(password);
    await _storage.deleteSecure('temp_backup');
    
    return encryptedBackup;
  }
  
  Future<void> importBackup(String backupData, String password) async {
    try {
      await _storage.importEncryptedBackup(backupData, password);
      
      // Reload entries and categories
      await loadEntries();
      await loadCategories();
      
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to import backup: $e');
    }
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
