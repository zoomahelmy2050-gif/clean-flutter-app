import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
// import 'package:workmanager/workmanager.dart'; // Temporarily disabled
import 'totp_manager_service.dart';
import 'encrypted_storage_service.dart';
import 'api_service.dart';
import 'notification_service.dart';
import 'database_service.dart';
import 'connectivity_service.dart';

// Background task identifiers
const String syncTaskName = "periodic-sync";
const String immediateTaskName = "immediate-sync";
const String backupTaskName = "backup-sync";

// Helper functions removed - workmanager temporarily disabled

class BackgroundSyncService extends ChangeNotifier {
  final ApiService _apiService;
  final NotificationService _notificationService;
  final TotpManagerService _totpManager;
  final EncryptedStorageService _encryptedStorage;
  final DatabaseService _databaseService;
  final ConnectivityService _connectivityService;
  
  Timer? _syncTimer;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  int _syncFailureCount = 0;
  final List<SyncTask> _pendingTasks = [];
  StreamSubscription? _connectivitySubscription;
  
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  List<SyncTask> get pendingTasks => List.unmodifiable(_pendingTasks);
  
  BackgroundSyncService({
    required ApiService apiService,
    required NotificationService notificationService,
    required TotpManagerService totpManager,
    required EncryptedStorageService encryptedStorage,
    required DatabaseService databaseService,
    required ConnectivityService connectivityService,
  })  : _apiService = apiService,
        _notificationService = notificationService,
        _totpManager = totpManager,
        _encryptedStorage = encryptedStorage,
        _databaseService = databaseService,
        _connectivityService = connectivityService;
  
  Future<void> initialize() async {
    try {
      // Background tasks temporarily disabled - workmanager compatibility issue
      // Will use foreground sync only for now
      
      // Load last sync time
      _lastSyncTime = await _databaseService.getLastSyncTime();
      
      // Listen to connectivity changes
      _connectivitySubscription = _connectivityService.connectivityStream.listen((isConnected) {
        if (isConnected && _pendingTasks.isNotEmpty) {
          _processPendingTasks();
        }
      });
      
      // Start foreground sync timer (every 5 minutes when app is active)
      _startForegroundSync();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Background sync initialization error: $e');
    }
  }
  
  void _startForegroundSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (!_isSyncing) {
        performSync();
      }
    });
  }
  
  Future<void> performSync({bool force = false}) async {
    if (_isSyncing && !force) return;
    
    _isSyncing = true;
    notifyListeners();
    
    try {
      // Check connectivity
      if (!await _connectivityService.hasConnection()) {
        _addPendingTask(SyncTask(
          type: SyncTaskType.fullSync,
          timestamp: DateTime.now(),
          data: {},
        ));
        return;
      }
      
      // Sync TOTP entries
      await _syncTotpEntries();
      
      // Sync user profile
      await _syncUserProfile();
      
      // Sync security settings
      await _syncSecuritySettings();
      
      // Sync activity logs
      await _syncActivityLogs();
      
      // Upload encrypted backup if needed
      if (_shouldPerformBackup()) {
        await _performCloudBackup();
      }
      
      _lastSyncTime = DateTime.now();
      await _databaseService.updateLastSyncTime(_lastSyncTime!);
      _syncFailureCount = 0;
      
      // Process any pending tasks
      await _processPendingTasks();
      
    } catch (e) {
      debugPrint('Sync error: $e');
      _syncFailureCount++;
      
      if (_syncFailureCount >= 3) {
        await _notificationService.addNotification({
          'title': 'Sync Failed',
          'message': 'Unable to sync data after multiple attempts',
          'severity': 'error',
          'category': 'system',
        });
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
  
  Future<void> _syncTotpEntries() async {
    try {
      final entries = _totpManager.entries;
      if (entries.isEmpty) return;
      
      final entriesData = {'entries': entries.map((e) => e.toJson()).toList()};
      final encryptedEntries = await _encryptedStorage.encryptData(entriesData);
      
      await _apiService.syncTotpEntries({'data': encryptedEntries});
    } catch (e) {
      debugPrint('TOTP sync error: $e');
      _addPendingTask(SyncTask(
        type: SyncTaskType.totpSync,
        timestamp: DateTime.now(),
        data: {},
      ));
    }
  }
  
  Future<void> _syncUserProfile() async {
    try {
      final profile = await _databaseService.getUserProfile();
      if (profile != null) {
        await _apiService.syncUserProfile(profile);
      }
    } catch (e) {
      debugPrint('Profile sync error: $e');
      _addPendingTask(SyncTask(
        type: SyncTaskType.profileSync,
        timestamp: DateTime.now(),
        data: {},
      ));
    }
  }
  
  Future<void> _syncSecuritySettings() async {
    try {
      final settings = await _databaseService.getSecuritySettings();
      if (settings != null) {
        await _apiService.syncSecuritySettings(settings);
      }
    } catch (e) {
      debugPrint('Settings sync error: $e');
      _addPendingTask(SyncTask(
        type: SyncTaskType.settingsSync,
        timestamp: DateTime.now(),
        data: {},
      ));
    }
  }
  
  Future<void> _syncActivityLogs() async {
    List<Map<String, dynamic>> logs = [];
    try {
      logs = await _databaseService.getUnsyncdLogs();
      if (logs.isNotEmpty) {
        await _apiService.syncActivityLogs(logs);
        await _databaseService.markLogsAsSynced(logs);
      }
    } catch (e) {
      debugPrint('Activity log sync error: $e');
      _addPendingTask(SyncTask(
        type: SyncTaskType.logsSync,
        timestamp: DateTime.now(),
        data: {'logs': logs},
      ));
    }
  }
  
  Future<void> _performCloudBackup() async {
    try {
      final backupData = await _createBackupData();
      await _apiService.uploadBackup(backupData);
      
      await _notificationService.addNotification({
        'title': 'Backup Complete',
        'message': 'Your data has been securely backed up to the cloud',
        'severity': 'info',
        'category': 'system',
      });
    } catch (e) {
      debugPrint('Cloud backup error: $e');
      _addPendingTask(SyncTask(
        type: SyncTaskType.backup,
        timestamp: DateTime.now(),
        data: {},
      ));
    }
  }
  
  Future<Map<String, dynamic>> _createBackupData() async {
    final totpData = await _encryptedStorage.exportAllData();
    final profile = await _databaseService.getUserProfile();
    final settings = await _databaseService.getSecuritySettings();
    
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'data': {
        'totp': totpData,
        'profile': profile,
        'settings': settings,
      },
    };
  }
  
  bool _shouldPerformBackup() {
    if (_lastSyncTime == null) return true;
    
    final hoursSinceLastSync = DateTime.now().difference(_lastSyncTime!).inHours;
    return hoursSinceLastSync >= 24; // Backup once per day
  }
  
  void _addPendingTask(SyncTask task) {
    _pendingTasks.add(task);
    if (_pendingTasks.length > 100) {
      _pendingTasks.removeAt(0); // Remove oldest task if queue is too large
    }
    notifyListeners();
  }
  
  Future<void> _processPendingTasks() async {
    if (_pendingTasks.isEmpty) return;
    
    final tasksToProcess = List<SyncTask>.from(_pendingTasks);
    _pendingTasks.clear();
    
    for (final task in tasksToProcess) {
      try {
        switch (task.type) {
          case SyncTaskType.fullSync:
            await performSync(force: true);
            break;
          case SyncTaskType.totpSync:
            await _syncTotpEntries();
            break;
          case SyncTaskType.profileSync:
            await _syncUserProfile();
            break;
          case SyncTaskType.settingsSync:
            await _syncSecuritySettings();
            break;
          case SyncTaskType.logsSync:
            await _syncActivityLogs();
            break;
          case SyncTaskType.backup:
            await _performCloudBackup();
            break;
        }
      } catch (e) {
        debugPrint('Error processing pending task ${task.type}: $e');
        _addPendingTask(task); // Re-add failed task
      }
    }
  }
  
  Future<void> triggerImmediateSync() async {
    // Background tasks temporarily disabled - using foreground sync only
    await performSync(force: true);
  }
  
  Future<void> triggerBackup() async {
    // Background tasks temporarily disabled - using foreground backup only
    await _performCloudBackup();
  }
  
  Future<void> restoreFromBackup(String backupId) async {
    try {
      _isSyncing = true;
      notifyListeners();
      
      final backupData = await _apiService.downloadBackup(backupId);
      
      if (backupData != null && backupData['data'] != null) {
        // Restore TOTP entries
        if (backupData['data']['totp'] != null) {
          await _encryptedStorage.importData(backupData['data']['totp']);
          await _totpManager.initialize(); // Reload entries
        }
        
        // Restore profile
        if (backupData['data']['profile'] != null) {
          await _databaseService.updateUserProfile(backupData['data']['profile']);
        }
        
        // Restore settings
        if (backupData['data']['settings'] != null) {
          await _databaseService.updateSecuritySettings(backupData['data']['settings']);
        }
        
        await _notificationService.addNotification({
          'title': 'Sync Success',
          'message': 'TOTP entries synced successfully',
          'severity': 'info',
          'category': 'system',
        });
      }
    } catch (e) {
      debugPrint('Restore error: $e');
      await _notificationService.addNotification({
        'title': 'Restore Failed',
        'message': 'Unable to restore data from backup',
        'severity': 'error',
        'category': 'system',
      });
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

enum SyncTaskType {
  fullSync,
  totpSync,
  profileSync,
  settingsSync,
  logsSync,
  backup,
}

class SyncTask {
  final SyncTaskType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  
  SyncTask({
    required this.type,
    required this.timestamp,
    required this.data,
  });
}
