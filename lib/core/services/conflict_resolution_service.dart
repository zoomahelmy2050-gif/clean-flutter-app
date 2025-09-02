import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conflict_models.dart';

enum ResolutionStrategy {
  manual,
  useLocal,
  useRemote,
  merge,
  newerWins,
  userPreference,
}

class ConflictResolutionRule {
  final String itemType;
  final ConflictType conflictType;
  final ResolutionStrategy strategy;
  final Map<String, dynamic>? conditions;

  ConflictResolutionRule({
    required this.itemType,
    required this.conflictType,
    required this.strategy,
    this.conditions,
  });

  Map<String, dynamic> toJson() => {
    'itemType': itemType,
    'conflictType': conflictType.name,
    'strategy': strategy.name,
    'conditions': conditions,
  };

  factory ConflictResolutionRule.fromJson(Map<String, dynamic> json) {
    return ConflictResolutionRule(
      itemType: json['itemType'],
      conflictType: ConflictType.values.firstWhere(
        (e) => e.name == json['conflictType'],
      ),
      strategy: ResolutionStrategy.values.firstWhere(
        (e) => e.name == json['strategy'],
      ),
      conditions: json['conditions'],
    );
  }
}

class ConflictResolutionService extends ChangeNotifier {
  List<ConflictResolutionRule> _rules = [];
  List<SyncConflict> _pendingConflicts = [];
  Map<String, dynamic> _resolutionHistory = {};
  bool _autoResolveEnabled = false;
  
  static const String _rulesKey = 'conflict_resolution_rules';
  static const String _historyKey = 'conflict_resolution_history';
  static const String _autoResolveKey = 'auto_resolve_enabled';

  ConflictResolutionService() {
    _loadSettings();
  }

  // Getters
  List<ConflictResolutionRule> get rules => List.unmodifiable(_rules);
  List<SyncConflict> get pendingConflicts => List.unmodifiable(_pendingConflicts);
  bool get autoResolveEnabled => _autoResolveEnabled;
  int get pendingCount => _pendingConflicts.length;
  Map<String, dynamic> get resolutionHistory => Map.unmodifiable(_resolutionHistory);

  /// Load settings from storage
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load rules
      final rulesJson = prefs.getString(_rulesKey);
      if (rulesJson != null) {
        final rulesList = jsonDecode(rulesJson) as List;
        _rules = rulesList.map((json) => ConflictResolutionRule.fromJson(json)).toList();
      }
      
      // Load history
      final historyJson = prefs.getString(_historyKey);
      if (historyJson != null) {
        _resolutionHistory = jsonDecode(historyJson);
      }
      
      // Load auto-resolve setting
      _autoResolveEnabled = prefs.getBool(_autoResolveKey) ?? false;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading conflict resolution settings: $e');
    }
  }

  /// Save settings to storage
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save rules
      final rulesJson = jsonEncode(_rules.map((rule) => rule.toJson()).toList());
      await prefs.setString(_rulesKey, rulesJson);
      
      // Save history
      await prefs.setString(_historyKey, jsonEncode(_resolutionHistory));
      
      // Save auto-resolve setting
      await prefs.setBool(_autoResolveKey, _autoResolveEnabled);
    } catch (e) {
      debugPrint('Error saving conflict resolution settings: $e');
    }
  }

  /// Add conflict resolution rule
  Future<void> addRule(ConflictResolutionRule rule) async {
    // Remove existing rule for same item type and conflict type
    _rules.removeWhere((r) => 
      r.itemType == rule.itemType && r.conflictType == rule.conflictType);
    
    _rules.add(rule);
    await _saveSettings();
    notifyListeners();
  }

  /// Add custom conflict rule (alias for addRule)
  Future<void> addCustomRule(ConflictRule rule) async {
    final conflictRule = ConflictResolutionRule(
      itemType: rule.itemType,
      conflictType: rule.conflictType,
      strategy: _mapResolutionActionToStrategy(rule.resolutionAction),
    );
    await addRule(conflictRule);
  }

  /// Map ResolutionAction to ResolutionStrategy
  ResolutionStrategy _mapResolutionActionToStrategy(ResolutionAction action) {
    switch (action) {
      case ResolutionAction.useLocal:
        return ResolutionStrategy.useLocal;
      case ResolutionAction.useRemote:
        return ResolutionStrategy.useRemote;
      case ResolutionAction.merge:
        return ResolutionStrategy.merge;
      case ResolutionAction.newerWins:
        return ResolutionStrategy.newerWins;
      case ResolutionAction.userPreference:
        return ResolutionStrategy.userPreference;
      case ResolutionAction.askUser:
      case ResolutionAction.skip:
      default:
        return ResolutionStrategy.manual;
    }
  }

  /// Remove conflict resolution rule
  Future<void> removeRule(String itemType, ConflictType conflictType) async {
    _rules.removeWhere((r) => 
      r.itemType == itemType && r.conflictType == conflictType);
    await _saveSettings();
    notifyListeners();
  }

  /// Get rule for specific conflict
  ConflictResolutionRule? getRule(String itemType, ConflictType conflictType) {
    try {
      return _rules.firstWhere(
        (rule) => rule.itemType == itemType && rule.conflictType == conflictType,
      );
    } catch (e) {
      return null;
    }
  }

  /// Handle new conflict
  Future<ConflictResolution?> handleConflict(SyncConflict conflict) async {
    _pendingConflicts.add(conflict);
    notifyListeners();

    // Try auto-resolution if enabled
    if (_autoResolveEnabled) {
      final resolution = await _attemptAutoResolution(conflict);
      if (resolution != null) {
        return resolution;
      }
    }

    // Return null to indicate manual resolution needed
    return null;
  }

  /// Attempt automatic resolution
  Future<ConflictResolution?> _attemptAutoResolution(SyncConflict conflict) async {
    final conflictType = _determineConflictType(conflict);
    final rule = getRule(conflict.itemType, conflictType);
    
    if (rule == null || rule.strategy == ResolutionStrategy.manual) {
      return null;
    }

    ConflictResolution? resolution;
    
    switch (rule.strategy) {
      case ResolutionStrategy.useLocal:
        resolution = ConflictResolution.useLocal;
        break;
      case ResolutionStrategy.useRemote:
        resolution = ConflictResolution.useRemote;
        break;
      case ResolutionStrategy.merge:
        resolution = await _attemptMerge(conflict);
        break;
      case ResolutionStrategy.newerWins:
        resolution = _resolveByTimestamp(conflict);
        break;
      case ResolutionStrategy.userPreference:
        resolution = _resolveByUserPreference(conflict);
        break;
      case ResolutionStrategy.manual:
        return null;
    }

    if (resolution != null) {
      await resolveConflict(conflict.id, resolution);
      _recordResolution(conflict, resolution, true);
    }

    return resolution;
  }

  /// Resolve conflict manually
  Future<void> resolveConflict(String conflictId, ConflictResolution resolution) async {
    SyncConflict? conflict;
    try {
      conflict = _pendingConflicts.firstWhere((c) => c.id == conflictId);
    } catch (e) {
      return; // Conflict not found
    }

    _pendingConflicts.removeWhere((c) => c.id == conflictId);
    // Note: In a real implementation, this would call the sync service
    _recordResolution(conflict, resolution, false);
    
    notifyListeners();
  }

  /// Resolve all conflicts with same strategy
  Future<void> resolveAllConflicts(ConflictResolution resolution) async {
    final conflicts = List<SyncConflict>.from(_pendingConflicts);
    
    for (final conflict in conflicts) {
      await resolveConflict(conflict.id, resolution);
    }
  }

  /// Create rule from resolution
  Future<void> createRuleFromResolution(
    SyncConflict conflict,
    ConflictResolution resolution,
  ) async {
    final conflictType = _determineConflictType(conflict);
    ResolutionStrategy strategy;
    
    switch (resolution) {
      case ConflictResolution.useLocal:
        strategy = ResolutionStrategy.useLocal;
        break;
      case ConflictResolution.useRemote:
        strategy = ResolutionStrategy.useRemote;
        break;
      case ConflictResolution.merge:
        strategy = ResolutionStrategy.merge;
        break;
      case ConflictResolution.skip:
        return; // Don't create rule for skip
    }
    
    final rule = ConflictResolutionRule(
      itemType: conflict.itemType,
      conflictType: conflictType,
      strategy: strategy,
    );
    
    await addRule(rule);
  }

  /// Determine conflict type from conflict data
  ConflictType _determineConflictType(SyncConflict conflict) {
    // Simple heuristic - could be enhanced based on actual data analysis
    if (conflict.localData.isEmpty) {
      return ConflictType.dataDeleted;
    } else if (conflict.remoteData.isEmpty) {
      return ConflictType.dataCreated;
    } else {
      return ConflictType.dataModified;
    }
  }

  /// Attempt to merge conflict data
  Future<ConflictResolution?> _attemptMerge(SyncConflict conflict) async {
    // Simple merge strategy - take non-null values from both
    // This is a basic implementation and should be enhanced based on data structure
    try {
      final merged = <String, dynamic>{};
      
      // Add all local data
      merged.addAll(conflict.localData);
      
      // Add remote data, preferring non-null values
      conflict.remoteData.forEach((key, value) {
        if (value != null && (merged[key] == null || _isNewer(value, merged[key]))) {
          merged[key] = value;
        }
      });
      
      // For now, return merge resolution
      // In a real implementation, you'd apply the merged data
      return ConflictResolution.merge;
    } catch (e) {
      return null;
    }
  }

  /// Resolve by timestamp (newer wins)
  ConflictResolution _resolveByTimestamp(SyncConflict conflict) {
    final localTimestamp = _extractTimestamp(conflict.localData);
    final remoteTimestamp = _extractTimestamp(conflict.remoteData);
    
    if (localTimestamp != null && remoteTimestamp != null) {
      return localTimestamp.isAfter(remoteTimestamp) 
          ? ConflictResolution.useLocal 
          : ConflictResolution.useRemote;
    }
    
    return ConflictResolution.useLocal; // Default fallback
  }

  /// Resolve by user preference
  ConflictResolution _resolveByUserPreference(SyncConflict conflict) {
    // Check resolution history for similar conflicts
    final historyKey = '${conflict.itemType}_${_determineConflictType(conflict).name}';
    final lastResolution = _resolutionHistory[historyKey];
    
    if (lastResolution != null) {
      return ConflictResolution.values.firstWhere(
        (r) => r.name == lastResolution,
        orElse: () => ConflictResolution.useLocal,
      );
    }
    
    return ConflictResolution.useLocal; // Default fallback
  }

  /// Extract timestamp from data
  DateTime? _extractTimestamp(Map<String, dynamic> data) {
    final timestampFields = ['updatedAt', 'modifiedAt', 'timestamp', 'lastModified'];
    
    for (final field in timestampFields) {
      final value = data[field];
      if (value != null) {
        try {
          return DateTime.parse(value.toString());
        } catch (e) {
          continue;
        }
      }
    }
    
    return null;
  }

  /// Check if value is newer
  bool _isNewer(dynamic newValue, dynamic oldValue) {
    if (newValue is String && oldValue is String) {
      try {
        final newDate = DateTime.parse(newValue);
        final oldDate = DateTime.parse(oldValue);
        return newDate.isAfter(oldDate);
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  /// Record resolution in history
  void _recordResolution(
    SyncConflict conflict,
    ConflictResolution resolution,
    bool wasAutomatic,
  ) {
    final historyKey = '${conflict.itemType}_${_determineConflictType(conflict).name}';
    _resolutionHistory[historyKey] = resolution.name;
    
    // Keep history limited
    if (_resolutionHistory.length > 100) {
      final keys = _resolutionHistory.keys.toList();
      keys.take(20).forEach(_resolutionHistory.remove);
    }
    
    _saveSettings();
  }

  /// Toggle auto-resolve
  Future<void> toggleAutoResolve() async {
    _autoResolveEnabled = !_autoResolveEnabled;
    await _saveSettings();
    notifyListeners();
  }

  /// Clear all pending conflicts
  void clearPendingConflicts() {
    _pendingConflicts.clear();
    notifyListeners();
  }

  /// Get conflict statistics
  Map<String, dynamic> getConflictStatistics() {
    final typeCount = <String, int>{};
    final resolutionCount = <String, int>{};
    
    for (final conflict in _pendingConflicts) {
      final type = _determineConflictType(conflict).name;
      typeCount[type] = (typeCount[type] ?? 0) + 1;
    }
    
    for (final resolution in _resolutionHistory.values) {
      resolutionCount[resolution] = (resolutionCount[resolution] ?? 0) + 1;
    }
    
    return {
      'pendingCount': _pendingConflicts.length,
      'rulesCount': _rules.length,
      'autoResolveEnabled': _autoResolveEnabled,
      'typeBreakdown': typeCount,
      'resolutionHistory': resolutionCount,
      'totalResolved': _resolutionHistory.length,
    };
  }

  /// Export conflict resolution settings
  Map<String, dynamic> exportSettings() {
    return {
      'rules': _rules.map((rule) => rule.toJson()).toList(),
      'autoResolveEnabled': _autoResolveEnabled,
      'resolutionHistory': _resolutionHistory,
    };
  }

  /// Import conflict resolution settings
  Future<void> importSettings(Map<String, dynamic> settings) async {
    try {
      if (settings['rules'] != null) {
        final rulesList = settings['rules'] as List;
        _rules = rulesList.map((json) => ConflictResolutionRule.fromJson(json)).toList();
      }
      
      if (settings['autoResolveEnabled'] != null) {
        _autoResolveEnabled = settings['autoResolveEnabled'];
      }
      
      if (settings['resolutionHistory'] != null) {
        _resolutionHistory = Map<String, dynamic>.from(settings['resolutionHistory']);
      }
      
      await _saveSettings();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to import conflict resolution settings: $e');
    }
  }
}
