import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  conflict,
  offline,
  paused,
}

enum SyncOperation {
  upload,
  download,
  delete,
  update,
  conflict_resolution,
}

class SyncProgress {
  final int total;
  final int completed;
  final int failed;
  final int conflicts;
  final String? currentItem;
  final SyncOperation? currentOperation;
  final DateTime startTime;
  final DateTime? endTime;

  SyncProgress({
    required this.total,
    required this.completed,
    required this.failed,
    required this.conflicts,
    this.currentItem,
    this.currentOperation,
    required this.startTime,
    this.endTime,
  });

  double get progress => total > 0 ? (completed + failed) / total : 0.0;
  bool get isCompleted => endTime != null;
  Duration get elapsed => (endTime ?? DateTime.now()).difference(startTime);
  bool get hasErrors => failed > 0 || conflicts > 0;
}

class SyncStatusService extends ChangeNotifier {
  SyncStatus _status = SyncStatus.idle;
  SyncProgress? _currentProgress;
  String? _lastError;
  DateTime? _lastSyncTime;
  Timer? _statusTimer;
  List<String> _syncLog = [];
  bool _autoSync = true;
  Duration _autoSyncInterval = const Duration(minutes: 5);
  Timer? _autoSyncTimer;
  
  // Network status
  bool _isOnline = true;
  StreamSubscription? _connectivitySubscription;
  
  // Conflict tracking
  List<SyncConflict> _conflicts = [];
  
  static const int _maxLogEntries = 100;

  // Getters
  SyncStatus get status => _status;
  SyncProgress? get currentProgress => _currentProgress;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;
  List<String> get syncLog => List.unmodifiable(_syncLog);
  bool get autoSync => _autoSync;
  Duration get autoSyncInterval => _autoSyncInterval;
  bool get isOnline => _isOnline;
  List<SyncConflict> get conflicts => List.unmodifiable(_conflicts);
  bool get hasConflicts => _conflicts.isNotEmpty;
  bool get isSyncing => _status == SyncStatus.syncing;
  bool get canSync => _isOnline && _status != SyncStatus.syncing;

  /// Start sync operation
  Future<void> startSync({
    required int totalItems,
    String? operationName,
  }) async {
    if (_status == SyncStatus.syncing) {
      throw Exception('Sync already in progress');
    }

    _status = SyncStatus.syncing;
    _lastError = null;
    _currentProgress = SyncProgress(
      total: totalItems,
      completed: 0,
      failed: 0,
      conflicts: 0,
      startTime: DateTime.now(),
    );

    _addToLog('Sync started: ${operationName ?? 'Manual sync'}');
    notifyListeners();

    // Start progress monitoring
    _startProgressMonitoring();
  }

  /// Update sync progress
  void updateProgress({
    int? completed,
    int? failed,
    int? conflicts,
    String? currentItem,
    SyncOperation? currentOperation,
  }) {
    if (_currentProgress == null) return;

    _currentProgress = SyncProgress(
      total: _currentProgress!.total,
      completed: completed ?? _currentProgress!.completed,
      failed: failed ?? _currentProgress!.failed,
      conflicts: conflicts ?? _currentProgress!.conflicts,
      currentItem: currentItem,
      currentOperation: currentOperation,
      startTime: _currentProgress!.startTime,
    );

    notifyListeners();
  }

  /// Complete sync operation
  void completeSync({bool success = true, String? error}) {
    if (_currentProgress == null) return;

    _currentProgress = SyncProgress(
      total: _currentProgress!.total,
      completed: _currentProgress!.completed,
      failed: _currentProgress!.failed,
      conflicts: _currentProgress!.conflicts,
      startTime: _currentProgress!.startTime,
      endTime: DateTime.now(),
    );

    if (success && error == null) {
      _status = _conflicts.isNotEmpty ? SyncStatus.conflict : SyncStatus.success;
      _lastSyncTime = DateTime.now();
      _addToLog('Sync completed successfully');
    } else {
      _status = SyncStatus.error;
      _lastError = error ?? 'Unknown sync error';
      _addToLog('Sync failed: $_lastError');
    }

    _stopProgressMonitoring();
    notifyListeners();

    // Auto-clear status after delay
    _scheduleStatusClear();
  }

  /// Cancel sync operation
  void cancelSync() {
    if (_status != SyncStatus.syncing) return;

    _status = SyncStatus.idle;
    _currentProgress = null;
    _addToLog('Sync cancelled by user');
    _stopProgressMonitoring();
    notifyListeners();
  }

  /// Pause sync operation
  void pauseSync() {
    if (_status != SyncStatus.syncing) return;

    _status = SyncStatus.paused;
    _addToLog('Sync paused');
    notifyListeners();
  }

  /// Resume sync operation
  void resumeSync() {
    if (_status != SyncStatus.paused) return;

    _status = SyncStatus.syncing;
    _addToLog('Sync resumed');
    notifyListeners();
  }

  /// Set network status
  void setNetworkStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      
      if (!isOnline) {
        if (_status == SyncStatus.syncing) {
          pauseSync();
        }
        _status = SyncStatus.offline;
        _addToLog('Network disconnected - sync paused');
      } else {
        if (_status == SyncStatus.offline) {
          _status = SyncStatus.idle;
          _addToLog('Network reconnected');
        }
      }
      
      notifyListeners();
    }
  }

  /// Add sync conflict
  void addConflict(SyncConflict conflict) {
    _conflicts.add(conflict);
    _addToLog('Conflict detected: ${conflict.itemName}');
    notifyListeners();
  }

  /// Resolve conflict
  void resolveConflict(String conflictId, ConflictResolution resolution) {
    _conflicts.removeWhere((c) => c.id == conflictId);
    _addToLog('Conflict resolved: $conflictId (${resolution.name})');
    
    if (_conflicts.isEmpty && _status == SyncStatus.conflict) {
      _status = SyncStatus.success;
    }
    
    notifyListeners();
  }

  /// Clear all conflicts
  void clearConflicts() {
    _conflicts.clear();
    if (_status == SyncStatus.conflict) {
      _status = SyncStatus.success;
    }
    _addToLog('All conflicts cleared');
    notifyListeners();
  }

  /// Toggle auto sync
  void toggleAutoSync() {
    _autoSync = !_autoSync;
    
    if (_autoSync) {
      _startAutoSync();
      _addToLog('Auto-sync enabled');
    } else {
      _stopAutoSync();
      _addToLog('Auto-sync disabled');
    }
    
    notifyListeners();
  }

  /// Set auto sync interval
  void setAutoSyncInterval(Duration interval) {
    _autoSyncInterval = interval;
    
    if (_autoSync) {
      _stopAutoSync();
      _startAutoSync();
    }
    
    _addToLog('Auto-sync interval changed to ${interval.inMinutes} minutes');
    notifyListeners();
  }

  /// Start auto sync timer
  void _startAutoSync() {
    _stopAutoSync();
    _autoSyncTimer = Timer.periodic(_autoSyncInterval, (timer) {
      if (canSync) {
        _triggerAutoSync();
      }
    });
  }

  /// Stop auto sync timer
  void _stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  /// Trigger auto sync
  void _triggerAutoSync() {
    _addToLog('Auto-sync triggered');
    // This would trigger the actual sync process
    // Implementation depends on the sync service
  }

  /// Start progress monitoring
  void _startProgressMonitoring() {
    _stopProgressMonitoring();
    _statusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Update UI periodically during sync
      notifyListeners();
    });
  }

  /// Stop progress monitoring
  void _stopProgressMonitoring() {
    _statusTimer?.cancel();
    _statusTimer = null;
  }

  /// Schedule status clear
  void _scheduleStatusClear() {
    Timer(const Duration(seconds: 5), () {
      if (_status == SyncStatus.success || _status == SyncStatus.error) {
        _status = SyncStatus.idle;
        _currentProgress = null;
        notifyListeners();
      }
    });
  }

  /// Add entry to sync log
  void _addToLog(String message) {
    final timestamp = DateTime.now().toIso8601String();
    _syncLog.insert(0, '[$timestamp] $message');
    
    if (_syncLog.length > _maxLogEntries) {
      _syncLog = _syncLog.take(_maxLogEntries).toList();
    }
    
    developer.log(message, name: 'SyncStatus');
  }

  /// Clear sync log
  void clearLog() {
    _syncLog.clear();
    notifyListeners();
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStatistics() {
    return {
      'status': _status.name,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'autoSyncEnabled': _autoSync,
      'autoSyncInterval': _autoSyncInterval.inMinutes,
      'conflictsCount': _conflicts.length,
      'isOnline': _isOnline,
      'logEntries': _syncLog.length,
      'currentProgress': _currentProgress != null ? {
        'total': _currentProgress!.total,
        'completed': _currentProgress!.completed,
        'failed': _currentProgress!.failed,
        'conflicts': _currentProgress!.conflicts,
        'progress': _currentProgress!.progress,
        'elapsed': _currentProgress!.elapsed.inSeconds,
      } : null,
    };
  }

  /// Force sync status reset
  void resetStatus() {
    _status = SyncStatus.idle;
    _currentProgress = null;
    _lastError = null;
    _stopProgressMonitoring();
    _addToLog('Sync status reset');
    notifyListeners();
  }

  @override
  void dispose() {
    _stopProgressMonitoring();
    _stopAutoSync();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

class SyncConflict {
  final String id;
  final String itemName;
  final String itemType;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final DateTime conflictTime;
  final String description;

  SyncConflict({
    required this.id,
    required this.itemName,
    required this.itemType,
    required this.localData,
    required this.remoteData,
    required this.conflictTime,
    required this.description,
  });
}

enum ConflictResolution {
  useLocal,
  useRemote,
  merge,
  skip,
}
