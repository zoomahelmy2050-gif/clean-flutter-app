import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

enum BulkOperationType {
  delete,
  export,
  favorite,
  unfavorite,
  pin,
  unpin,
  categorize,
  backup,
}

class BulkOperationProgress {
  final int total;
  final int completed;
  final int failed;
  final String? currentItem;
  final List<String> errors;

  BulkOperationProgress({
    required this.total,
    required this.completed,
    required this.failed,
    this.currentItem,
    this.errors = const [],
  });

  double get progress => total > 0 ? completed / total : 0.0;
  bool get isCompleted => completed + failed >= total;
  bool get hasErrors => errors.isNotEmpty;
}

class BulkOperationsService extends ChangeNotifier {
  final Set<String> _selectedItems = {};
  bool _isSelectionMode = false;
  BulkOperationProgress? _currentProgress;
  StreamController<BulkOperationProgress>? _progressController;

  Set<String> get selectedItems => Set.unmodifiable(_selectedItems);
  bool get isSelectionMode => _isSelectionMode;
  int get selectedCount => _selectedItems.length;
  bool get hasSelection => _selectedItems.isNotEmpty;
  BulkOperationProgress? get currentProgress => _currentProgress;
  Stream<BulkOperationProgress>? get progressStream => _progressController?.stream;

  /// Enter selection mode
  void enterSelectionMode() {
    if (!_isSelectionMode) {
      _isSelectionMode = true;
      notifyListeners();
    }
  }

  /// Exit selection mode
  void exitSelectionMode() {
    if (_isSelectionMode) {
      _isSelectionMode = false;
      _selectedItems.clear();
      notifyListeners();
    }
  }

  /// Toggle item selection
  void toggleSelection(String itemId) {
    if (_selectedItems.contains(itemId)) {
      _selectedItems.remove(itemId);
    } else {
      _selectedItems.add(itemId);
    }
    
    // Auto-exit selection mode if no items selected
    if (_selectedItems.isEmpty && _isSelectionMode) {
      _isSelectionMode = false;
    }
    
    notifyListeners();
  }

  /// Select item
  void selectItem(String itemId) {
    if (!_selectedItems.contains(itemId)) {
      _selectedItems.add(itemId);
      if (!_isSelectionMode) {
        _isSelectionMode = true;
      }
      notifyListeners();
    }
  }

  /// Deselect item
  void deselectItem(String itemId) {
    if (_selectedItems.contains(itemId)) {
      _selectedItems.remove(itemId);
      
      // Auto-exit selection mode if no items selected
      if (_selectedItems.isEmpty && _isSelectionMode) {
        _isSelectionMode = false;
      }
      
      notifyListeners();
    }
  }

  /// Select all items
  void selectAll(List<String> allItemIds) {
    _selectedItems.clear();
    _selectedItems.addAll(allItemIds);
    if (!_isSelectionMode) {
      _isSelectionMode = true;
    }
    notifyListeners();
  }

  /// Deselect all items
  void deselectAll() {
    _selectedItems.clear();
    notifyListeners();
  }

  /// Check if item is selected
  bool isSelected(String itemId) {
    return _selectedItems.contains(itemId);
  }

  /// Perform bulk operation
  Future<BulkOperationProgress> performBulkOperation(
    BulkOperationType operation,
    Future<bool> Function(String itemId) operationFunction, {
    String? operationName,
  }) async {
    if (_selectedItems.isEmpty) {
      throw Exception('No items selected for bulk operation');
    }

    final items = List<String>.from(_selectedItems);
    final total = items.length;
    int completed = 0;
    int failed = 0;
    final errors = <String>[];

    // Initialize progress tracking
    _progressController = StreamController<BulkOperationProgress>.broadcast();
    
    _currentProgress = BulkOperationProgress(
      total: total,
      completed: 0,
      failed: 0,
      errors: [],
    );

    try {
      for (int i = 0; i < items.length; i++) {
        final itemId = items[i];
        
        // Update current progress
        _currentProgress = BulkOperationProgress(
          total: total,
          completed: completed,
          failed: failed,
          currentItem: itemId,
          errors: List.from(errors),
        );
        
        _progressController?.add(_currentProgress!);
        notifyListeners();

        try {
          final success = await operationFunction(itemId);
          if (success) {
            completed++;
          } else {
            failed++;
            errors.add('Failed to process item: $itemId');
          }
        } catch (e) {
          failed++;
          errors.add('Error processing $itemId: $e');
        }

        // Small delay to prevent overwhelming the UI
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Final progress update
      _currentProgress = BulkOperationProgress(
        total: total,
        completed: completed,
        failed: failed,
        errors: List.from(errors),
      );
      
      _progressController?.add(_currentProgress!);
      notifyListeners();

      return _currentProgress!;
    } finally {
      // Clean up
      await _progressController?.close();
      _progressController = null;
      
      // Clear selection after operation
      exitSelectionMode();
    }
  }

  /// Get operation display name
  String getOperationName(BulkOperationType operation) {
    switch (operation) {
      case BulkOperationType.delete:
        return 'Delete';
      case BulkOperationType.export:
        return 'Export';
      case BulkOperationType.favorite:
        return 'Add to Favorites';
      case BulkOperationType.unfavorite:
        return 'Remove from Favorites';
      case BulkOperationType.pin:
        return 'Pin';
      case BulkOperationType.unpin:
        return 'Unpin';
      case BulkOperationType.categorize:
        return 'Categorize';
      case BulkOperationType.backup:
        return 'Backup';
    }
  }

  /// Get operation icon
  IconData getOperationIcon(BulkOperationType operation) {
    switch (operation) {
      case BulkOperationType.delete:
        return Icons.delete;
      case BulkOperationType.export:
        return Icons.file_download;
      case BulkOperationType.favorite:
        return Icons.favorite;
      case BulkOperationType.unfavorite:
        return Icons.favorite_border;
      case BulkOperationType.pin:
        return Icons.push_pin;
      case BulkOperationType.unpin:
        return Icons.push_pin_outlined;
      case BulkOperationType.categorize:
        return Icons.category;
      case BulkOperationType.backup:
        return Icons.backup;
    }
  }

  /// Cancel current operation
  void cancelOperation() {
    _progressController?.close();
    _progressController = null;
    _currentProgress = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _progressController?.close();
    super.dispose();
  }
}
