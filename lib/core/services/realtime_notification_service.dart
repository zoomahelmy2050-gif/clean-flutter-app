import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'notification_service.dart';
import 'api_service.dart';
import 'dart:developer' as developer;

class RealtimeNotificationService extends ChangeNotifier {
  final NotificationService _notificationService;
  final ApiService _apiService;
  
  WebSocketChannel? _channel;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _connectivitySubscription;
  
  bool _isConnected = false;
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  DateTime? _lastHeartbeat;
  
  // Queue for offline messages
  final List<Map<String, dynamic>> _offlineQueue = [];
  
  // Real-time event streams
  final StreamController<SecurityEvent> _securityEventStream = StreamController<SecurityEvent>.broadcast();
  final StreamController<SystemAlert> _systemAlertStream = StreamController<SystemAlert>.broadcast();
  final StreamController<UserActivity> _userActivityStream = StreamController<UserActivity>.broadcast();
  
  bool get isConnected => _isConnected;
  Stream<SecurityEvent> get securityEvents => _securityEventStream.stream;
  Stream<SystemAlert> get systemAlerts => _systemAlertStream.stream;
  Stream<UserActivity> get userActivities => _userActivityStream.stream;
  
  RealtimeNotificationService({
    required NotificationService notificationService,
    required ApiService apiService,
  }) : _notificationService = notificationService,
       _apiService = apiService {
    _initializeConnectivityListener();
  }
  
  Future<void> connect() async {
    if (_isConnected || _isReconnecting) return;
    
    try {
      final token = await _apiService.getAuthToken();
      if (token == null) {
        developer.log('No auth token available for WebSocket connection', name: 'RealtimeNotification');
        return;
      }
      
      final wsUrl = _apiService.baseUrl.replaceFirst('http', 'ws');
      final uri = Uri.parse('$wsUrl/notifications/ws?token=$token');
      
      _channel = WebSocketChannel.connect(uri);
      
      _messageSubscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );
      
      // Send initial handshake
      _sendMessage({
        'type': 'handshake',
        'version': '1.0',
        'capabilities': ['security_events', 'system_alerts', 'user_activities'],
      });
      
      _startHeartbeat();
      _isConnected = true;
      _reconnectAttempts = 0;
      notifyListeners();
      
      developer.log('WebSocket connected successfully', name: 'RealtimeNotification');
      
      // Process offline queue
      _processOfflineQueue();
      
    } catch (e) {
      developer.log('Failed to connect WebSocket: $e', name: 'RealtimeNotification');
      _scheduleReconnect();
    }
  }
  
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      _lastHeartbeat = DateTime.now();
      
      switch (data['type']) {
        case 'security_event':
          _handleSecurityEvent(data['payload']);
          break;
        case 'system_alert':
          _handleSystemAlert(data['payload']);
          break;
        case 'user_activity':
          _handleUserActivity(data['payload']);
          break;
        case 'notification':
          _handleNotification(data['payload']);
          break;
        case 'heartbeat':
          _handleHeartbeat(data);
          break;
        case 'ack':
          _handleAcknowledgment(data);
          break;
        default:
          developer.log('Unknown message type: ${data['type']}', name: 'RealtimeNotification');
      }
    } catch (e) {
      developer.log('Error handling WebSocket message: $e', name: 'RealtimeNotification');
    }
  }
  
  void _handleSecurityEvent(Map<String, dynamic> payload) {
    final event = SecurityEvent.fromJson(payload);
    _securityEventStream.add(event);
    
    // Create notification for critical events
    if (event.severity == 'critical' || event.severity == 'high') {
      _notificationService.addNotification({
        'title': 'Security Alert: ${event.type}',
        'body': event.description,
        'type': 'security',
        'priority': event.severity == 'critical' ? 'high' : 'medium',
      });
    }
  }
  
  void _handleSystemAlert(Map<String, dynamic> payload) {
    final alert = SystemAlert.fromJson(payload);
    _systemAlertStream.add(alert);
    
    _notificationService.addNotification({
      'title': alert.title,
      'body': alert.message,
      'type': 'system',
      'priority': alert.priority,
    });
  }
  
  Future<void> _handleUserActivity(Map<String, dynamic> payload) async {
    final activity = UserActivity.fromJson(payload);
    _userActivityStream.add(activity);
    
    // Only notify for suspicious activities
    if (activity.isSuspicious) {
      await _notificationService.addNotification({
        'title': 'Security Alert',
        'body': 'Suspicious login attempt detected',
      });
    }
  }
  
  void _handleNotification(Map<String, dynamic> payload) {
    _notificationService.addNotification({
      'title': payload['title'],
      'body': payload['message'],
      'type': payload['type'] ?? 'info',
      'priority': payload['priority'] ?? 'normal',
      ...?payload['data'],
    });
  }
  
  void _handleHeartbeat(Map<String, dynamic> data) {
    // Respond to server heartbeat
    _sendMessage({
      'type': 'heartbeat_ack',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  void _handleAcknowledgment(Map<String, dynamic> data) {
    developer.log('Message acknowledged: ${data['messageId']}', name: 'RealtimeNotification');
  }
  
  void _handleError(error) {
    developer.log('WebSocket error: $error', name: 'RealtimeNotification');
    _scheduleReconnect();
  }
  
  void _handleDisconnect() {
    developer.log('WebSocket disconnected', name: 'RealtimeNotification');
    _isConnected = false;
    _stopHeartbeat();
    notifyListeners();
    _scheduleReconnect();
  }
  
  void _scheduleReconnect() {
    if (_isReconnecting || _reconnectAttempts >= _maxReconnectAttempts) return;
    
    _isReconnecting = true;
    _reconnectAttempts++;
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay * _reconnectAttempts, () async {
      developer.log('Attempting reconnect #$_reconnectAttempts', name: 'RealtimeNotification');
      _isReconnecting = false;
      await connect();
    });
  }
  
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConnected) {
        _sendMessage({
          'type': 'heartbeat',
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        // Check for stale connection
        if (_lastHeartbeat != null) {
          final timeSinceLastHeartbeat = DateTime.now().difference(_lastHeartbeat!);
          if (timeSinceLastHeartbeat > const Duration(minutes: 2)) {
            developer.log('Connection stale, reconnecting...', name: 'RealtimeNotification');
            disconnect();
            connect();
          }
        }
      }
    });
  }
  
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
  
  void _initializeConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none && !_isConnected) {
        developer.log('Network available, attempting to connect...', name: 'RealtimeNotification');
        connect();
      }
    });
  }
  
  void _sendMessage(Map<String, dynamic> message) {
    if (_channel == null) {
      _offlineQueue.add(message);
      return;
    }
    
    try {
      message['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      developer.log('Failed to send message: $e', name: 'RealtimeNotification');
      _offlineQueue.add(message);
    }
  }
  
  void _processOfflineQueue() {
    if (_offlineQueue.isEmpty) return;
    
    developer.log('Processing ${_offlineQueue.length} offline messages', name: 'RealtimeNotification');
    final messages = List<Map<String, dynamic>>.from(_offlineQueue);
    _offlineQueue.clear();
    
    for (final message in messages) {
      _sendMessage(message);
    }
  }
  
  // Public methods for sending real-time updates
  void sendSecurityUpdate(String type, Map<String, dynamic> data) {
    _sendMessage({
      'type': 'security_update',
      'payload': {
        'updateType': type,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      },
    });
  }
  
  void reportSuspiciousActivity(String activityType, String description) {
    _sendMessage({
      'type': 'suspicious_activity',
      'payload': {
        'activityType': activityType,
        'description': description,
        'timestamp': DateTime.now().toIso8601String(),
        'deviceInfo': {
          'platform': 'flutter',
          // Add more device info as needed
        },
      },
    });
  }
  
  void subscribeToChannel(String channel) {
    _sendMessage({
      'type': 'subscribe',
      'channel': channel,
    });
  }
  
  void unsubscribeFromChannel(String channel) {
    _sendMessage({
      'type': 'unsubscribe',
      'channel': channel,
    });
  }
  
  void disconnect() {
    _isConnected = false;
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    _messageSubscription?.cancel();
    _channel?.sink.close(status.normalClosure);
    _channel = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    disconnect();
    _connectivitySubscription?.cancel();
    _securityEventStream.close();
    _systemAlertStream.close();
    _userActivityStream.close();
    super.dispose();
  }
}

// Data models for real-time events
class SecurityEvent {
  final String id;
  final String type;
  final String severity;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  
  SecurityEvent({
    required this.id,
    required this.type,
    required this.severity,
    required this.description,
    required this.timestamp,
    this.metadata,
  });
  
  factory SecurityEvent.fromJson(Map<String, dynamic> json) {
    return SecurityEvent(
      id: json['id'],
      type: json['type'],
      severity: json['severity'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'],
    );
  }
}

class SystemAlert {
  final String id;
  final String title;
  final String message;
  final String priority;
  final DateTime timestamp;
  final Map<String, dynamic>? actions;
  
  SystemAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.priority,
    required this.timestamp,
    this.actions,
  });
  
  factory SystemAlert.fromJson(Map<String, dynamic> json) {
    return SystemAlert(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      priority: json['priority'],
      timestamp: DateTime.parse(json['timestamp']),
      actions: json['actions'],
    );
  }
}

class UserActivity {
  final String id;
  final String userId;
  final String activityType;
  final String description;
  final bool isSuspicious;
  final DateTime timestamp;
  final Map<String, dynamic>? details;
  
  UserActivity({
    required this.id,
    required this.userId,
    required this.activityType,
    required this.description,
    required this.isSuspicious,
    required this.timestamp,
    this.details,
  });
  
  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      id: json['id'],
      userId: json['userId'],
      activityType: json['activityType'],
      description: json['description'],
      isSuspicious: json['isSuspicious'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
      details: json['details'],
    );
  }
}
