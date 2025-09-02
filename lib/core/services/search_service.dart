import 'package:flutter/material.dart';

class SearchService extends ChangeNotifier {
  String _searchQuery = '';
  List<String> _searchHistory = [];
  List<String> _recentSearches = [];
  bool _isSearchActive = false;
  
  static const int _maxHistoryItems = 20;
  static const int _maxRecentItems = 5;

  String get searchQuery => _searchQuery;
  List<String> get searchHistory => List.unmodifiable(_searchHistory);
  List<String> get recentSearches => List.unmodifiable(_recentSearches);
  bool get isSearchActive => _isSearchActive;
  bool get hasQuery => _searchQuery.isNotEmpty;

  /// Set search query and notify listeners
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query.trim();
      _isSearchActive = _searchQuery.isNotEmpty;
      notifyListeners();
    }
  }

  /// Add search to history
  void addToHistory(String query) {
    if (query.trim().isEmpty) return;
    
    final trimmedQuery = query.trim().toLowerCase();
    
    // Remove if already exists
    _searchHistory.removeWhere((item) => item.toLowerCase() == trimmedQuery);
    _recentSearches.removeWhere((item) => item.toLowerCase() == trimmedQuery);
    
    // Add to beginning
    _searchHistory.insert(0, query.trim());
    _recentSearches.insert(0, query.trim());
    
    // Limit size
    if (_searchHistory.length > _maxHistoryItems) {
      _searchHistory = _searchHistory.take(_maxHistoryItems).toList();
    }
    if (_recentSearches.length > _maxRecentItems) {
      _recentSearches = _recentSearches.take(_maxRecentItems).toList();
    }
    
    notifyListeners();
  }

  /// Clear search query
  void clearSearch() {
    _searchQuery = '';
    _isSearchActive = false;
    notifyListeners();
  }

  /// Clear search history
  void clearHistory() {
    _searchHistory.clear();
    notifyListeners();
  }

  /// Clear recent searches
  void clearRecent() {
    _recentSearches.clear();
    notifyListeners();
  }

  /// Remove specific item from history
  void removeFromHistory(String query) {
    _searchHistory.remove(query);
    _recentSearches.remove(query);
    notifyListeners();
  }

  /// Search and filter TOTP entries
  List<T> filterItems<T>(
    List<T> items,
    String Function(T) getSearchableText, {
    bool caseSensitive = false,
  }) {
    if (_searchQuery.isEmpty) return items;

    final query = caseSensitive ? _searchQuery : _searchQuery.toLowerCase();
    
    return items.where((item) {
      final text = caseSensitive 
          ? getSearchableText(item)
          : getSearchableText(item).toLowerCase();
      
      // Support multiple search terms
      final searchTerms = query.split(' ').where((term) => term.isNotEmpty);
      
      return searchTerms.every((term) => text.contains(term));
    }).toList();
  }

  /// Get search suggestions based on history
  List<String> getSuggestions(String partialQuery) {
    if (partialQuery.isEmpty) return _recentSearches;
    
    final query = partialQuery.toLowerCase();
    
    return _searchHistory
        .where((item) => item.toLowerCase().contains(query))
        .take(5)
        .toList();
  }

  /// Highlight search terms in text
  List<TextSpan> highlightSearchTerms(
    String text,
    TextStyle normalStyle,
    TextStyle highlightStyle,
  ) {
    if (_searchQuery.isEmpty) {
      return [TextSpan(text: text, style: normalStyle)];
    }

    final spans = <TextSpan>[];
    final searchTerms = _searchQuery.toLowerCase().split(' ')
        .where((term) => term.isNotEmpty)
        .toList();
    
    if (searchTerms.isEmpty) {
      return [TextSpan(text: text, style: normalStyle)];
    }

    String remainingText = text;
    int currentIndex = 0;

    while (remainingText.isNotEmpty) {
      int earliestMatch = remainingText.length;
      String matchedTerm = '';

      // Find the earliest match among all search terms
      for (final term in searchTerms) {
        final index = remainingText.toLowerCase().indexOf(term);
        if (index != -1 && index < earliestMatch) {
          earliestMatch = index;
          matchedTerm = term;
        }
      }

      if (matchedTerm.isEmpty) {
        // No more matches, add remaining text
        spans.add(TextSpan(text: remainingText, style: normalStyle));
        break;
      }

      // Add text before match
      if (earliestMatch > 0) {
        spans.add(TextSpan(
          text: remainingText.substring(0, earliestMatch),
          style: normalStyle,
        ));
      }

      // Add highlighted match
      final matchLength = matchedTerm.length;
      spans.add(TextSpan(
        text: remainingText.substring(earliestMatch, earliestMatch + matchLength),
        style: highlightStyle,
      ));

      // Continue with remaining text
      remainingText = remainingText.substring(earliestMatch + matchLength);
    }

    return spans;
  }
}

/// Search filter options
enum SearchFilter {
  all,
  favorites,
  categories,
  recent,
}

/// Search sort options
enum SearchSort {
  alphabetical,
  dateAdded,
  lastUsed,
  category,
}

/// Advanced search service with filtering and sorting
class AdvancedSearchService extends SearchService {
  SearchFilter _currentFilter = SearchFilter.all;
  SearchSort _currentSort = SearchSort.alphabetical;
  bool _sortAscending = true;

  SearchFilter get currentFilter => _currentFilter;
  SearchSort get currentSort => _currentSort;
  bool get sortAscending => _sortAscending;

  void setFilter(SearchFilter filter) {
    if (_currentFilter != filter) {
      _currentFilter = filter;
      notifyListeners();
    }
  }

  void setSort(SearchSort sort, {bool? ascending}) {
    bool changed = false;
    
    if (_currentSort != sort) {
      _currentSort = sort;
      changed = true;
    }
    
    if (ascending != null && _sortAscending != ascending) {
      _sortAscending = ascending;
      changed = true;
    }
    
    if (changed) {
      notifyListeners();
    }
  }

  void toggleSortOrder() {
    _sortAscending = !_sortAscending;
    notifyListeners();
  }

  /// Apply advanced filtering and sorting
  List<T> advancedFilter<T>(
    List<T> items,
    String Function(T) getSearchableText, {
    bool Function(T)? isFavorite,
    String Function(T)? getCategory,
    DateTime Function(T)? getDateAdded,
    DateTime Function(T)? getLastUsed,
  }) {
    // First apply basic search filter
    var filteredItems = filterItems(items, getSearchableText);

    // Apply advanced filters
    switch (_currentFilter) {
      case SearchFilter.favorites:
        if (isFavorite != null) {
          filteredItems = filteredItems.where(isFavorite).toList();
        }
        break;
      case SearchFilter.categories:
        if (getCategory != null) {
          filteredItems = filteredItems
              .where((item) => getCategory(item).isNotEmpty)
              .toList();
        }
        break;
      case SearchFilter.recent:
        if (getLastUsed != null) {
          final cutoff = DateTime.now().subtract(const Duration(days: 7));
          filteredItems = filteredItems
              .where((item) => getLastUsed(item).isAfter(cutoff))
              .toList();
        }
        break;
      case SearchFilter.all:
        // No additional filtering
        break;
    }

    // Apply sorting
    switch (_currentSort) {
      case SearchSort.alphabetical:
        filteredItems.sort((a, b) {
          final comparison = getSearchableText(a)
              .toLowerCase()
              .compareTo(getSearchableText(b).toLowerCase());
          return _sortAscending ? comparison : -comparison;
        });
        break;
      case SearchSort.dateAdded:
        if (getDateAdded != null) {
          filteredItems.sort((a, b) {
            final comparison = getDateAdded(a).compareTo(getDateAdded(b));
            return _sortAscending ? comparison : -comparison;
          });
        }
        break;
      case SearchSort.lastUsed:
        if (getLastUsed != null) {
          filteredItems.sort((a, b) {
            final comparison = getLastUsed(a).compareTo(getLastUsed(b));
            return _sortAscending ? comparison : -comparison;
          });
        }
        break;
      case SearchSort.category:
        if (getCategory != null) {
          filteredItems.sort((a, b) {
            final comparison = getCategory(a)
                .toLowerCase()
                .compareTo(getCategory(b).toLowerCase());
            return _sortAscending ? comparison : -comparison;
          });
        }
        break;
    }

    return filteredItems;
  }
}
