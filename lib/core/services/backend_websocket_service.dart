import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'backend_config.dart';

class BackendWebSocketService {
  static final BackendWebSocketService _instance = BackendWebSocketService._internal();
  factory BackendWebSocketService() => _instance;
  BackendWebSocketService._internal();

  final Map<String, WebSocketChannel> _channels = {};
  final Map<String, StreamController> _controllers = {};
  final Map<String, Timer> _reconnectTimers = {};
  final Map<String, int> _reconnectAttempts = {};
  final Map<String, Timer> _pingTimers = {};

  Future<void> initialize() async {
    developer.log('Backend WebSocket Service initialized', name: 'BackendWebSocketService');
  }

  Stream<T> connect<T>({
    required String endpoint,
    required T Function(Map<String, dynamic>) parser,
    Map<String, String>? headers,
    Duration? reconnectDelay,
    int? maxReconnectAttempts,
  }) {
    final channelKey = endpoint;
    
    if (_controllers.containsKey(channelKey)) {
      return _controllers[channelKey]!.stream.cast<T>();
    }

    final controller = StreamController<T>.broadcast();
    _controllers[channelKey] = controller;

    _connectWebSocket<T>(
      endpoint: endpoint,
      parser: parser,
      headers: headers,
      reconnectDelay: reconnectDelay ?? BackendConfig.wsReconnectDelay,
      maxReconnectAttempts: maxReconnectAttempts ?? BackendConfig.wsMaxReconnectAttempts,
      controller: controller,
    );

    return controller.stream;
  }

  void _connectWebSocket<T>({
    required String endpoint,
    required T Function(Map<String, dynamic>) parser,
    Map<String, String>? headers,
    required Duration reconnectDelay,
    required int maxReconnectAttempts,
    required StreamController<T> controller,
  }) async {
    final channelKey = endpoint;
    
    try {
      final wsUrl = '${BackendConfig.wsUrl}$endpoint';
      developer.log('Connecting to WebSocket: $wsUrl', name: 'BackendWebSocketService');

      final channel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
        protocols: headers != null ? [jsonEncode(headers)] : null,
      );

      _channels[channelKey] = channel;
      _reconnectAttempts[channelKey] = 0;

      // Start ping timer
      _startPingTimer(channelKey, channel);

      // Listen to messages
      channel.stream.listen(
        (data) {
          try {
            final Map<String, dynamic> jsonData = jsonDecode(data);
            final parsedData = parser(jsonData);
            controller.add(parsedData);
          } catch (e) {
            developer.log('Failed to parse WebSocket message: $e', name: 'BackendWebSocketService');
          }
        },
        onError: (error) {
          developer.log('WebSocket error: $error', name: 'BackendWebSocketService');
          _handleReconnect<T>(
            endpoint: endpoint,
            parser: parser,
            headers: headers,
            reconnectDelay: reconnectDelay,
            maxReconnectAttempts: maxReconnectAttempts,
            controller: controller,
          );
        },
        onDone: () {
          developer.log('WebSocket connection closed', name: 'BackendWebSocketService');
          _handleReconnect<T>(
            endpoint: endpoint,
            parser: parser,
            headers: headers,
            reconnectDelay: reconnectDelay,
            maxReconnectAttempts: maxReconnectAttempts,
            controller: controller,
          );
        },
      );

      developer.log('WebSocket connected successfully to $endpoint', name: 'BackendWebSocketService');
    } catch (e) {
      developer.log('Failed to connect WebSocket: $e', name: 'BackendWebSocketService');
      _handleReconnect<T>(
        endpoint: endpoint,
        parser: parser,
        headers: headers,
        reconnectDelay: reconnectDelay,
        maxReconnectAttempts: maxReconnectAttempts,
        controller: controller,
      );
    }
  }

  void _handleReconnect<T>({
    required String endpoint,
    required T Function(Map<String, dynamic>) parser,
    Map<String, String>? headers,
    required Duration reconnectDelay,
    required int maxReconnectAttempts,
    required StreamController<T> controller,
  }) {
    final channelKey = endpoint;
    
    _cleanupChannel(channelKey);
    
    final attempts = _reconnectAttempts[channelKey] ?? 0;
    
    if (attempts >= maxReconnectAttempts) {
      developer.log('Max reconnect attempts reached for $endpoint', name: 'BackendWebSocketService');
      controller.addError('Max reconnect attempts reached');
      return;
    }

    _reconnectAttempts[channelKey] = attempts + 1;
    
    developer.log('Attempting to reconnect to $endpoint (attempt ${attempts + 1}/$maxReconnectAttempts)', 
        name: 'BackendWebSocketService');

    _reconnectTimers[channelKey] = Timer(reconnectDelay, () {
      _connectWebSocket<T>(
        endpoint: endpoint,
        parser: parser,
        headers: headers,
        reconnectDelay: reconnectDelay,
        maxReconnectAttempts: maxReconnectAttempts,
        controller: controller,
      );
    });
  }

  void _startPingTimer(String channelKey, WebSocketChannel channel) {
    _pingTimers[channelKey] = Timer.periodic(BackendConfig.wsPingInterval, (timer) {
      try {
        channel.sink.add(jsonEncode({'type': 'ping', 'timestamp': DateTime.now().toIso8601String()}));
      } catch (e) {
        developer.log('Failed to send ping: $e', name: 'BackendWebSocketService');
        timer.cancel();
      }
    });
  }

  void _cleanupChannel(String channelKey) {
    _channels[channelKey]?.sink.close();
    _channels.remove(channelKey);
    _pingTimers[channelKey]?.cancel();
    _pingTimers.remove(channelKey);
    _reconnectTimers[channelKey]?.cancel();
    _reconnectTimers.remove(channelKey);
  }

  void send(String endpoint, Map<String, dynamic> data) {
    final channelKey = endpoint;
    final channel = _channels[channelKey];
    
    if (channel != null) {
      try {
        channel.sink.add(jsonEncode(data));
      } catch (e) {
        developer.log('Failed to send WebSocket message: $e', name: 'BackendWebSocketService');
      }
    } else {
      developer.log('WebSocket channel not found for $endpoint', name: 'BackendWebSocketService');
    }
  }

  void disconnect(String endpoint) {
    final channelKey = endpoint;
    
    _cleanupChannel(channelKey);
    
    final controller = _controllers[channelKey];
    if (controller != null) {
      controller.close();
      _controllers.remove(channelKey);
    }
    
    _reconnectAttempts.remove(channelKey);
    
    developer.log('Disconnected from WebSocket: $endpoint', name: 'BackendWebSocketService');
  }

  void disconnectAll() {
    final endpoints = List<String>.from(_controllers.keys);
    for (final endpoint in endpoints) {
      disconnect(endpoint);
    }
    
    developer.log('Disconnected from all WebSockets', name: 'BackendWebSocketService');
  }

  bool isConnected(String endpoint) {
    final channelKey = endpoint;
    return _channels.containsKey(channelKey);
  }

  List<String> getConnectedEndpoints() {
    return List<String>.from(_channels.keys);
  }

  // Predefined WebSocket connections for common endpoints
  Stream<Map<String, dynamic>> connectSecurityEvents() {
    return connect<Map<String, dynamic>>(
      endpoint: BackendConfig.wsSecurityEvents,
      parser: (data) => data,
    );
  }

  Stream<Map<String, dynamic>> connectThreatFeed() {
    return connect<Map<String, dynamic>>(
      endpoint: BackendConfig.wsThreatFeed,
      parser: (data) => data,
    );
  }

  Stream<Map<String, dynamic>> connectNotifications() {
    return connect<Map<String, dynamic>>(
      endpoint: BackendConfig.wsNotifications,
      parser: (data) => data,
    );
  }

  Stream<Map<String, dynamic>> connectAnalytics() {
    return connect<Map<String, dynamic>>(
      endpoint: BackendConfig.wsAnalytics,
      parser: (data) => data,
    );
  }

  Stream<Map<String, dynamic>> connectIncidents() {
    return connect<Map<String, dynamic>>(
      endpoint: BackendConfig.wsIncidents,
      parser: (data) => data,
    );
  }

  void dispose() {
    disconnectAll();
  }
}
