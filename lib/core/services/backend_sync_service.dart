import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'database_service.dart';

class BackendSyncService extends ChangeNotifier {
  final DatabaseService _databaseService;
  
  Timer? _syncTimer;
  bool _isSyncing = false;
  SyncStatus? _syncStatus;
  String? _lastSyncError;
  DateTime? _lastSyncTime;
  final List<SyncQueueItem> _pendingItems = [];
  
  BackendSyncService(this._databaseService);
  
  bool get isSyncing => _isSyncing;
  SyncStatus? get syncStatus => _syncStatus;
  String? get lastSyncError => _lastSyncError;
  DateTime? get lastSyncTime => _lastSyncTime;
  List<SyncQueueItem> get pendingItems => List.unmodifiable(_pendingItems);
  
  // Start auto-sync with interval (in seconds)
  void startAutoSync({int intervalSeconds = 30}) {
    stopAutoSync();
    _syncTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => syncAll(),
    );
    // Initial sync
    syncAll();
  }
  
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
  
  // Add item to sync queue
  Future<void> addToSyncQueue({
    required String operation,
    required String entity,
    required String entityId,
    required Map<String, dynamic> data,
  }) async {
    final item = SyncQueueItem(
      operation: operation,
      entity: entity,
      entityId: entityId,
      data: data,
      createdAt: DateTime.now(),
    );
    
    _pendingItems.add(item);
    
    // Try to sync immediately if online
    if (!_isSyncing) {
      await _processSyncQueue();
    }
    
    notifyListeners();
  }
  
  // Main sync method
  Future<void> syncAll() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    _lastSyncError = null;
    notifyListeners();
    
    try {
      // Get sync status from backend
      await _fetchSyncStatus();
      
      // Process pending items
      await _processSyncQueue();
      
      // Sync local data with backend
      await _syncLocalData();
      
      _lastSyncTime = DateTime.now();
      _lastSyncError = null;
    } catch (e) {
      _lastSyncError = e.toString();
      debugPrint('Sync error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
  
  Future<void> _fetchSyncStatus() async {
    final token = await _databaseService.authToken;
    if (token == null) return;
    
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.backendUrl}/sync/status'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _syncStatus = SyncStatus.fromJson(data);
      }
    } catch (e) {
      debugPrint('Failed to fetch sync status: $e');
    }
  }
  
  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    final token = _databaseService.authToken;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
  
  Future<void> _processSyncQueue() async {
    if (_pendingItems.isEmpty) return;
    
    final itemsToSync = List<SyncQueueItem>.from(_pendingItems);
    
    for (final item in itemsToSync) {
      try {
        final response = await http.post(
          Uri.parse('${AppConfig.backendUrl}/sync/queue'),
          headers: _headers,
          body: json.encode({
            'operation': item.operation,
            'entity': item.entity,
            'entityId': item.entityId,
            'data': item.data,
          }),
        );
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          _pendingItems.remove(item);
        } else {
          item.retryCount++;
          if (item.retryCount > 3) {
            item.status = 'failed';
          }
        }
      } catch (e) {
        item.retryCount++;
        item.lastError = e.toString();
        debugPrint('Failed to sync item ${item.entityId}: $e');
      }
    }
    
    // Process the queue on backend
    try {
      await http.post(
        Uri.parse('${AppConfig.backendUrl}/sync/process'),
        headers: _headers,
      );
    } catch (e) {
      debugPrint('Failed to process sync queue: $e');
    }
  }
  
  Future<void> _syncLocalData() async {
    // Sync devices
    await _syncDevices();
    
    // Sync security logs
    await _syncSecurityLogs();
    
    // Sync encrypted blobs
    await _syncBlobs();
  }
  
  Future<void> _syncDevices() async {
    try {
      final devices = await _databaseService.getAllDevices();
      for (final device in devices) {
        if (device['syncStatus'] == 'pending') {
          await addToSyncQueue(
            operation: 'CREATE',
            entity: 'device',
            entityId: device['id'],
            data: device,
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to sync devices: $e');
    }
  }
  
  Future<void> _syncSecurityLogs() async {
    try {
      final logs = await _databaseService.getUnsyncedSecurityLogs();
      for (final log in logs) {
        await addToSyncQueue(
          operation: 'CREATE',
          entity: 'securityLog',
          entityId: log['id'],
          data: log,
        );
      }
    } catch (e) {
      debugPrint('Failed to sync security logs: $e');
    }
  }
  
  Future<void> _syncBlobs() async {
    try {
      final blobs = await _databaseService.getUnsyncedBlobs();
      for (final blob in blobs) {
        await addToSyncQueue(
          operation: blob['id'] == null ? 'CREATE' : 'UPDATE',
          entity: 'blob',
          entityId: blob['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          data: blob,
        );
      }
    } catch (e) {
      debugPrint('Failed to sync blobs: $e');
    }
  }
  
  Future<void> syncDevice(Map<String, dynamic> device) async {
    if (_databaseService.authToken == null) return;
    
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.backendUrl}/sync/device'),
        headers: _headers,
        body: json.encode(device),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Device synced successfully');
      } else {
        debugPrint('Failed to sync device: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to sync device: $e');
    }
  }
  
  // Force sync a specific entity
  Future<bool> syncEntity(String entity, String entityId) async {
    final token = _databaseService.authToken;
    if (token == null) return false;
    
    try {
      // Get entity data from local database
      Map<String, dynamic>? entityData;
      
      switch (entity) {
        case 'device':
          entityData = await _databaseService.getDevice(entityId);
          break;
        case 'blob':
          entityData = await _databaseService.getBlob(entityId);
          break;
        default:
          return false;
      }
      
      if (entityData == null) return false;
      
      await addToSyncQueue(
        operation: 'UPDATE',
        entity: entity,
        entityId: entityId,
        data: entityData,
      );
      
      await _processSyncQueue();
      return true;
    } catch (e) {
      debugPrint('Failed to sync entity $entityId: $e');
      return false;
    }
  }
  
  // Clear sync queue
  Future<void> clearSyncQueue() async {
    _pendingItems.clear();
    notifyListeners();
  }
  
  @override
  void dispose() {
    stopAutoSync();
    super.dispose();
  }
}

class SyncQueueItem {
  final String operation;
  final String entity;
  final String entityId;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  String status;
  int retryCount;
  String? lastError;
  
  SyncQueueItem({
    required this.operation,
    required this.entity,
    required this.entityId,
    required this.data,
    required this.createdAt,
    this.status = 'pending',
    this.retryCount = 0,
    this.lastError,
  });
}

class SyncStatus {
  final SyncQueueStatus queue;
  final List<DeviceSync> devices;
  final DateTime? lastSync;
  
  SyncStatus({
    required this.queue,
    required this.devices,
    this.lastSync,
  });
  
  factory SyncStatus.fromJson(Map<String, dynamic> json) {
    return SyncStatus(
      queue: SyncQueueStatus.fromJson(json['queue']),
      devices: (json['devices'] as List?)
          ?.map((d) => DeviceSync.fromJson(d))
          .toList() ?? [],
      lastSync: json['lastSync'] != null 
          ? DateTime.parse(json['lastSync']) 
          : null,
    );
  }
}

class SyncQueueStatus {
  final int pending;
  final int completed;
  final int failed;
  
  SyncQueueStatus({
    required this.pending,
    required this.completed,
    required this.failed,
  });
  
  factory SyncQueueStatus.fromJson(Map<String, dynamic> json) {
    return SyncQueueStatus(
      pending: json['pending'] ?? 0,
      completed: json['completed'] ?? 0,
      failed: json['failed'] ?? 0,
    );
  }
}

class DeviceSync {
  final String id;
  final String name;
  final String syncStatus;
  final DateTime? lastSyncAt;
  final bool isOnline;
  
  DeviceSync({
    required this.id,
    required this.name,
    required this.syncStatus,
    this.lastSyncAt,
    required this.isOnline,
  });
  
  factory DeviceSync.fromJson(Map<String, dynamic> json) {
    return DeviceSync(
      id: json['id'],
      name: json['name'],
      syncStatus: json['syncStatus'],
      lastSyncAt: json['lastSyncAt'] != null 
          ? DateTime.parse(json['lastSyncAt']) 
          : null,
      isOnline: json['isOnline'] ?? false,
    );
  }
}
