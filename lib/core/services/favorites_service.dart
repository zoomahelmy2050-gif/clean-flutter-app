import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService extends ChangeNotifier {
  static const String _favoritesKey = 'favorites_list';
  static const String _pinnedKey = 'pinned_list';
  
  Set<String> _favorites = {};
  List<String> _pinned = [];
  
  Set<String> get favorites => Set.unmodifiable(_favorites);
  List<String> get pinned => List.unmodifiable(_pinned);
  
  FavoritesService() {
    _loadFavorites();
  }

  /// Load favorites and pinned items from storage
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    
    final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];
    _favorites = favoritesJson.toSet();
    
    final pinnedJson = prefs.getStringList(_pinnedKey) ?? [];
    _pinned = pinnedJson;
    
    notifyListeners();
  }

  /// Save favorites to storage
  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, _favorites.toList());
    await prefs.setStringList(_pinnedKey, _pinned);
  }

  /// Check if item is favorite
  bool isFavorite(String itemId) {
    return _favorites.contains(itemId);
  }

  /// Check if item is pinned
  bool isPinned(String itemId) {
    return _pinned.contains(itemId);
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String itemId) async {
    if (_favorites.contains(itemId)) {
      _favorites.remove(itemId);
      // Also remove from pinned if it was pinned
      _pinned.remove(itemId);
    } else {
      _favorites.add(itemId);
    }
    
    await _saveFavorites();
    notifyListeners();
  }

  /// Add to favorites
  Future<void> addFavorite(String itemId) async {
    if (!_favorites.contains(itemId)) {
      _favorites.add(itemId);
      await _saveFavorites();
      notifyListeners();
    }
  }

  /// Remove from favorites
  Future<void> removeFavorite(String itemId) async {
    if (_favorites.contains(itemId)) {
      _favorites.remove(itemId);
      _pinned.remove(itemId); // Also remove from pinned
      await _saveFavorites();
      notifyListeners();
    }
  }

  /// Toggle pin status (only favorites can be pinned)
  Future<void> togglePin(String itemId) async {
    if (!_favorites.contains(itemId)) {
      // Must be favorite first
      await addFavorite(itemId);
    }
    
    if (_pinned.contains(itemId)) {
      _pinned.remove(itemId);
    } else {
      _pinned.insert(0, itemId); // Add to top
    }
    
    await _saveFavorites();
    notifyListeners();
  }

  /// Pin item to top
  Future<void> pinItem(String itemId) async {
    if (!_favorites.contains(itemId)) {
      await addFavorite(itemId);
    }
    
    if (!_pinned.contains(itemId)) {
      _pinned.insert(0, itemId);
      await _saveFavorites();
      notifyListeners();
    }
  }

  /// Unpin item
  Future<void> unpinItem(String itemId) async {
    if (_pinned.contains(itemId)) {
      _pinned.remove(itemId);
      await _saveFavorites();
      notifyListeners();
    }
  }

  /// Reorder pinned items
  Future<void> reorderPinned(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final item = _pinned.removeAt(oldIndex);
    _pinned.insert(newIndex, item);
    
    await _saveFavorites();
    notifyListeners();
  }

  /// Get favorites count
  int get favoritesCount => _favorites.length;

  /// Get pinned count
  int get pinnedCount => _pinned.length;

  /// Clear all favorites
  Future<void> clearFavorites() async {
    _favorites.clear();
    _pinned.clear();
    await _saveFavorites();
    notifyListeners();
  }

  /// Get pinned items in order
  List<String> getPinnedInOrder() {
    return List.from(_pinned);
  }

  /// Filter items by favorite status
  List<T> filterFavorites<T>(
    List<T> items,
    String Function(T) getId, {
    bool favoritesOnly = false,
  }) {
    if (!favoritesOnly) return items;
    
    return items.where((item) => isFavorite(getId(item))).toList();
  }

  /// Sort items with pinned first, then favorites, then others
  List<T> sortByPriority<T>(
    List<T> items,
    String Function(T) getId,
  ) {
    final pinnedItems = <T>[];
    final favoriteItems = <T>[];
    final regularItems = <T>[];
    
    for (final item in items) {
      final id = getId(item);
      if (isPinned(id)) {
        pinnedItems.add(item);
      } else if (isFavorite(id)) {
        favoriteItems.add(item);
      } else {
        regularItems.add(item);
      }
    }
    
    // Sort pinned items by their order
    pinnedItems.sort((a, b) {
      final aIndex = _pinned.indexOf(getId(a));
      final bIndex = _pinned.indexOf(getId(b));
      return aIndex.compareTo(bIndex);
    });
    
    return [...pinnedItems, ...favoriteItems, ...regularItems];
  }

  /// Bulk operations
  Future<void> addMultipleFavorites(List<String> itemIds) async {
    bool changed = false;
    for (final id in itemIds) {
      if (!_favorites.contains(id)) {
        _favorites.add(id);
        changed = true;
      }
    }
    
    if (changed) {
      await _saveFavorites();
      notifyListeners();
    }
  }

  Future<void> removeMultipleFavorites(List<String> itemIds) async {
    bool changed = false;
    for (final id in itemIds) {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
        _pinned.remove(id);
        changed = true;
      }
    }
    
    if (changed) {
      await _saveFavorites();
      notifyListeners();
    }
  }

  /// Export favorites for backup
  Map<String, dynamic> exportFavorites() {
    return {
      'favorites': _favorites.toList(),
      'pinned': _pinned,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Import favorites from backup
  Future<void> importFavorites(Map<String, dynamic> data) async {
    try {
      final favoritesList = data['favorites'] as List<dynamic>?;
      final pinnedList = data['pinned'] as List<dynamic>?;
      
      if (favoritesList != null) {
        _favorites = favoritesList.cast<String>().toSet();
      }
      
      if (pinnedList != null) {
        _pinned = pinnedList.cast<String>();
      }
      
      await _saveFavorites();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to import favorites: $e');
    }
  }
}
