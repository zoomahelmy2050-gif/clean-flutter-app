import 'package:flutter/material.dart';
import '../services/search_service.dart';

class SearchBarWidget extends StatefulWidget {
  final SearchService searchService;
  final String hintText;
  final VoidCallback? onSearchChanged;
  final bool showFilters;
  final bool autofocus;

  const SearchBarWidget({
    super.key,
    required this.searchService,
    this.hintText = 'Search...',
    this.onSearchChanged,
    this.showFilters = false,
    this.autofocus = false,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchService.searchQuery);
    _focusNode = FocusNode();
    
    _focusNode.addListener(() {
      setState(() {
        _showSuggestions = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    widget.searchService.setSearchQuery(query);
    widget.onSearchChanged?.call();
    setState(() {});
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      widget.searchService.addToHistory(query.trim());
      _focusNode.unfocus();
    }
  }

  void _selectSuggestion(String suggestion) {
    _controller.text = suggestion;
    widget.searchService.setSearchQuery(suggestion);
    widget.searchService.addToHistory(suggestion);
    widget.onSearchChanged?.call();
    _focusNode.unfocus();
  }

  void _clearSearch() {
    _controller.clear();
    widget.searchService.clearSearch();
    widget.onSearchChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focusNode.hasFocus
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              width: _focusNode.hasFocus ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: widget.autofocus,
                  onChanged: _onSearchChanged,
                  onSubmitted: _onSearchSubmitted,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              if (widget.searchService.hasQuery) ...[
                IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear search',
                ),
              ],
              if (widget.showFilters) ...[
                IconButton(
                  onPressed: () => _showFilterMenu(context),
                  icon: const Icon(Icons.tune),
                  tooltip: 'Filter options',
                ),
              ],
            ],
          ),
        ),
        if (_showSuggestions && _focusNode.hasFocus) ...[
          _buildSuggestions(),
        ],
      ],
    );
  }

  Widget _buildSuggestions() {
    final suggestions = widget.searchService.getSuggestions(_controller.text);
    
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.searchService.recentSearches.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recent searches',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      widget.searchService.clearRecent();
                      setState(() {});
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          ],
          ...suggestions.map((suggestion) => ListTile(
            dense: true,
            leading: Icon(
              Icons.search,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: Text(suggestion),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: () {
                widget.searchService.removeFromHistory(suggestion);
                setState(() {});
              },
            ),
            onTap: () => _selectSuggestion(suggestion),
          )),
        ],
      ),
    );
  }

  void _showFilterMenu(BuildContext context) {
    if (widget.searchService is! AdvancedSearchService) return;
    
    final advancedSearch = widget.searchService as AdvancedSearchService;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => _FilterBottomSheet(
        searchService: advancedSearch,
        onChanged: () {
          widget.onSearchChanged?.call();
        },
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final AdvancedSearchService searchService;
  final VoidCallback? onChanged;

  const _FilterBottomSheet({
    required this.searchService,
    this.onChanged,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune),
              const SizedBox(width: 8),
              Text(
                'Filter & Sort',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Filter by',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: SearchFilter.values.map((filter) {
              final isSelected = widget.searchService.currentFilter == filter;
              return FilterChip(
                label: Text(_getFilterLabel(filter)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    widget.searchService.setFilter(filter);
                    widget.onChanged?.call();
                    setState(() {});
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Sort by',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...SearchSort.values.map((sort) {
            final isSelected = widget.searchService.currentSort == sort;
            return RadioListTile<SearchSort>(
              title: Text(_getSortLabel(sort)),
              value: sort,
              groupValue: widget.searchService.currentSort,
              onChanged: (value) {
                if (value != null) {
                  widget.searchService.setSort(value);
                  widget.onChanged?.call();
                  setState(() {});
                }
              },
            );
          }),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Ascending order'),
            subtitle: Text(
              widget.searchService.sortAscending ? 'A to Z' : 'Z to A',
            ),
            value: widget.searchService.sortAscending,
            onChanged: (value) {
              widget.searchService.toggleSortOrder();
              widget.onChanged?.call();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(SearchFilter filter) {
    switch (filter) {
      case SearchFilter.all:
        return 'All';
      case SearchFilter.favorites:
        return 'Favorites';
      case SearchFilter.categories:
        return 'Categorized';
      case SearchFilter.recent:
        return 'Recent';
    }
  }

  String _getSortLabel(SearchSort sort) {
    switch (sort) {
      case SearchSort.alphabetical:
        return 'Alphabetical';
      case SearchSort.dateAdded:
        return 'Date Added';
      case SearchSort.lastUsed:
        return 'Last Used';
      case SearchSort.category:
        return 'Category';
    }
  }
}
