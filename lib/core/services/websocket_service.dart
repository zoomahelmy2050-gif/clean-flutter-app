import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:logger/logger.dart';

enum WebSocketState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class WebSocketMessage {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  WebSocketMessage({
    required this.type,
    required this.data,
    required this.timestamp,
  });

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: json['type'] ?? '',
      data: json['data'] ?? {},
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class WebSocketService with ChangeNotifier {
  static const String _baseUrl = 'ws://192.168.100.21:3000';
  static const int _reconnectDelay = 5; // seconds
  static const int _maxReconnectAttempts = 10;
  
  final Logger _logger = Logger();
  WebSocketChannel? _channel;
  WebSocketState _state = WebSocketState.disconnected;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  String? _authToken;
  String? _userId;
  
  // Message streams
  final StreamController<WebSocketMessage> _messageController = 
      StreamController<WebSocketMessage>.broadcast();
  final StreamController<WebSocketState> _stateController = 
      StreamController<WebSocketState>.broadcast();
  
  // Getters
  WebSocketState get state => _state;
  Stream<WebSocketMessage> get messageStream => _messageController.stream;
  Stream<WebSocketState> get stateStream => _stateController.stream;
  bool get isConnected => _state == WebSocketState.connected;
  
  /// Initialize WebSocket connection
  Future<void> connect({String? authToken, String? userId}) async {
    _authToken = authToken;
    _userId = userId;
    
    if (_state == WebSocketState.connecting || _state == WebSocketState.connected) {
      return;
    }
    
    _setState(WebSocketState.connecting);
    
    try {
      final uri = Uri.parse('$_baseUrl/ws');
      final headers = <String, String>{};
      
      if (_authToken != null) {
        headers['Authorization'] = 'Bearer $_authToken';
      }
      
      _channel = WebSocketChannel.connect(uri);
      
      // Listen to messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDisconnected,
      );
      
      _setState(WebSocketState.connected);
      _reconnectAttempts = 0;
      _startHeartbeat();
      
      // Send authentication message
      if (_authToken != null && _userId != null) {
        await _sendAuthMessage();
      }
      
      _logger.i('WebSocket connected successfully');
      
    } catch (e) {
      _logger.e('WebSocket connection failed: $e');
      _setState(WebSocketState.error);
      _scheduleReconnect();
    }
  }
  
  /// Disconnect WebSocket
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    
    if (_channel != null) {
      await _channel!.sink.close(status.goingAway);
      _channel = null;
    }
    
    _setState(WebSocketState.disconnected);
    _logger.i('WebSocket disconnected');
  }
  
  /// Send message through WebSocket
  Future<void> sendMessage(String type, Map<String, dynamic> data) async {
    if (!isConnected) {
      _logger.w('Cannot send message: WebSocket not connected');
      return;
    }
    
    final message = WebSocketMessage(
      type: type,
      data: data,
      timestamp: DateTime.now(),
    );
    
    try {
      _channel!.sink.add(jsonEncode(message.toJson()));
      _logger.d('Sent message: $type');
    } catch (e) {
      _logger.e('Failed to send message: $e');
    }
  }
  
  /// Subscribe to specific message types
  Stream<WebSocketMessage> subscribeToType(String messageType) {
    return messageStream.where((message) => message.type == messageType);
  }
  
  /// Send authentication message
  Future<void> _sendAuthMessage() async {
    await sendMessage('auth', {
      'token': _authToken,
      'userId': _userId,
    });
  }
  
  /// Handle incoming messages
  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final message = WebSocketMessage.fromJson(json);
      
      _logger.d('Received message: ${message.type}');
      
      // Handle special message types
      switch (message.type) {
        case 'pong':
          _logger.d('Received pong');
          break;
        case 'auth_success':
          _logger.i('Authentication successful');
          break;
        case 'auth_failed':
          _logger.e('Authentication failed');
          _setState(WebSocketState.error);
          break;
        default:
          _messageController.add(message);
      }
      
    } catch (e) {
      _logger.e('Failed to parse message: $e');
    }
  }
  
  /// Handle WebSocket errors
  void _onError(error) {
    _logger.e('WebSocket error: $error');
    _setState(WebSocketState.error);
    _scheduleReconnect();
  }
  
  /// Handle WebSocket disconnection
  void _onDisconnected() {
    _logger.w('WebSocket disconnected');
    _setState(WebSocketState.disconnected);
    _heartbeatTimer?.cancel();
    _scheduleReconnect();
  }
  
  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logger.e('Max reconnection attempts reached');
      _setState(WebSocketState.error);
      return;
    }
    
    _reconnectAttempts++;
    _setState(WebSocketState.reconnecting);
    
    final delay = Duration(seconds: _reconnectDelay * _reconnectAttempts);
    _logger.i('Scheduling reconnect in ${delay.inSeconds} seconds (attempt $_reconnectAttempts)');
    
    _reconnectTimer = Timer(delay, () {
      connect(authToken: _authToken, userId: _userId);
    });
  }
  
  /// Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (isConnected) {
        sendMessage('ping', {});
      } else {
        timer.cancel();
      }
    });
  }
  
  /// Set WebSocket state and notify listeners
  void _setState(WebSocketState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(_state);
      notifyListeners();
    }
  }
  
  /// Send real-time notification
  Future<void> sendRealtimeNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'notification',
  }) async {
    await sendMessage('notification', {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
    });
  }
  
  /// Send user activity update
  Future<void> sendUserActivity({
    required String userId,
    required String activity,
    Map<String, dynamic>? metadata,
  }) async {
    await sendMessage('user_activity', {
      'userId': userId,
      'activity': activity,
      'metadata': metadata ?? {},
    });
  }
  
  /// Send security event
  Future<void> sendSecurityEvent({
    required String userId,
    required String event,
    required String severity,
    Map<String, dynamic>? details,
  }) async {
    await sendMessage('security_event', {
      'userId': userId,
      'event': event,
      'severity': severity,
      'details': details ?? {},
    });
  }
  
  /// Request real-time data sync
  Future<void> requestDataSync(String dataType) async {
    await sendMessage('sync_request', {
      'dataType': dataType,
      'userId': _userId,
    });
  }
  
  @override
  void dispose() {
    disconnect();
    _messageController.close();
    _stateController.close();
    super.dispose();
  }
}
