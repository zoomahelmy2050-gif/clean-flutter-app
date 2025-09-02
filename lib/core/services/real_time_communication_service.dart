import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RealTimeCommunicationService extends ChangeNotifier {
  static RealTimeCommunicationService? _instance;
  static RealTimeCommunicationService get instance => _instance ??= RealTimeCommunicationService._();
  RealTimeCommunicationService._();

  // Private fields
  WebSocketChannel? _wsChannel;
  io.Socket? _socketIO;
  bool _isConnected = false;
  bool _isInitialized = false;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  
  // Configuration from environment
  String _websocketUrl = '';
  String _socketIOUrl = '';
  String _authToken = '';
  bool _useRealConnection = false;

  // Stream controllers for different event types
  final StreamController<Map<String, dynamic>> _threatAlertsController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _complianceEventsController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _deviceEventsController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _forensicAlertsController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _systemEventsController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Additional stream controllers for specific event types
  final StreamController<Map<String, dynamic>> _userActivityController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _securityIncidentController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _policyUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _auditLogController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _threatIntelligenceController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _systemHealthController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _complianceAlertController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _deviceEventController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _networkActivityController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _vulnerabilityAlertController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _mdmEventController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Public streams for the additional controllers
  Stream<Map<String, dynamic>> get userActivityStream => _userActivityController.stream;
  Stream<Map<String, dynamic>> get securityIncidentStream => _securityIncidentController.stream;
  Stream<Map<String, dynamic>> get policyUpdateStream => _policyUpdateController.stream;
  Stream<Map<String, dynamic>> get auditLogStream => _auditLogController.stream;
  Stream<Map<String, dynamic>> get threatIntelligenceStream => _threatIntelligenceController.stream;
  Stream<Map<String, dynamic>> get systemHealthStream => _systemHealthController.stream;
  Stream<Map<String, dynamic>> get complianceAlertStream => _complianceAlertController.stream;
  Stream<Map<String, dynamic>> get deviceEventStream => _deviceEventController.stream;
  Stream<Map<String, dynamic>> get networkActivityStream => _networkActivityController.stream;
  Stream<Map<String, dynamic>> get vulnerabilityAlertStream => _vulnerabilityAlertController.stream;
  Stream<Map<String, dynamic>> get mdmEventStream => _mdmEventController.stream;

  // Public streams
  Stream<Map<String, dynamic>> get threatAlertsStream => _threatAlertsController.stream;
  Stream<Map<String, dynamic>> get complianceEventsStream => _complianceEventsController.stream;
  Stream<Map<String, dynamic>> get deviceEventsStream => _deviceEventsController.stream;
  Stream<Map<String, dynamic>> get forensicAlertsStream => _forensicAlertsController.stream;
  Stream<Map<String, dynamic>> get systemEventsStream => _systemEventsController.stream;

  bool get isConnected => _isConnected;

  // Configuration loaded from environment
  String get websocketUrl => _websocketUrl;
  String get socketIOUrl => _socketIOUrl;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load configuration from environment
      _websocketUrl = dotenv.env['WEBSOCKET_URL'] ?? '';
      _socketIOUrl = dotenv.env['SOCKETIO_URL'] ?? '';
      _authToken = await _getAuthToken() ?? '';
      
      _useRealConnection = _websocketUrl.isNotEmpty && _socketIOUrl.isNotEmpty;
      
      if (_useRealConnection) {
        await _connectWebSocket();
        await _connectSocketIO();
        _startHeartbeat();
        developer.log('Real-time communication service initialized with real connections');
      } else {
        developer.log('Real-time communication service initialized in mock mode - no URLs configured');
        _startMockDataGeneration();
      }
      
      _isInitialized = true;
    } catch (e) {
      developer.log('Failed to initialize real-time communication: $e');
      _isInitialized = true;
      _startMockDataGeneration();
    }
  }

  Future<void> _connectWebSocket() async {
    if (!_useRealConnection || _websocketUrl.isEmpty) {
      developer.log('WebSocket connection skipped - no URL configured');
      return;
    }
    
    try {
      final uri = Uri.parse(_websocketUrl);
      final headers = <String, String>{};
      
      if (_authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_authToken';
      }
      
      _wsChannel = WebSocketChannel.connect(uri);
      _wsChannel!.stream.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketDone,
        cancelOnError: false, // Don't cancel on error to allow reconnection
      );
      _isConnected = true;
      _reconnectAttempts = 0;
      developer.log('WebSocket connected to $_websocketUrl');
      
      // Subscribe to all event types
      _subscribeToEvents();
    } catch (e) {
      developer.log('WebSocket connection error: $e');
      _isConnected = false;
      // Don't schedule reconnect if we're using placeholder URLs
      if (!_websocketUrl.contains('your-api.com')) {
        _scheduleReconnect();
      }
    }
  }
  
  void _subscribeToEvents() {
    if (!_isConnected) return;
    
    final subscription = {
      'type': 'subscribe',
      'events': [
        'threat_alerts',
        'compliance_events',
        'device_events',
        'forensic_alerts',
        'system_events',
        'user_activity',
        'security_incidents',
        'policy_updates',
        'audit_logs',
        'threat_intelligence',
        'system_health',
        'compliance_alerts',
        'device_events',
        'network_activity',
        'vulnerability_alerts',
        'mdm_events',
      ],
    };
    
    _wsChannel?.sink.add(jsonEncode(subscription));
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      final dynamic decodedMessage = message is String ? jsonDecode(message) : message;
      final Map<String, dynamic> data = decodedMessage is Map<String, dynamic>
          ? decodedMessage
          : decodedMessage is Map
              ? Map<String, dynamic>.from(decodedMessage)
              : <String, dynamic>{};
              
      final String? eventType = data['event_type']?.toString();
      final Map<String, dynamic> eventData = data['data'] is Map
          ? Map<String, dynamic>.from(data['data'] as Map)
          : <String, dynamic>{};
      final timestamp = DateTime.tryParse(data['timestamp']?.toString() ?? '') ?? DateTime.now();

      if (eventType == null) {
        developer.log('Received message with no event type: $data');
        return;
      }

      // Add common metadata to all events
      final Map<String, dynamic> enrichedData = {
        ...eventData,
        'eventType': eventType,
        'timestamp': timestamp.toIso8601String(),
        'receivedAt': DateTime.now().toIso8601String(),
      };

      // Route the message to the appropriate stream based on event type
      switch (eventType) {
        // User activity events
        case 'user_login':
        case 'user_logout':
        case 'user_activity':
          _userActivityController.add(enrichedData);
          break;
          
        // Security events
        case 'security_incident':
        case 'security_alert':
        case 'intrusion_detection':
          _securityIncidentController.add(enrichedData);
          break;
          
        // Policy and compliance events
        case 'policy_update':
        case 'policy_violation':
        case 'compliance_alert':
        case 'compliance_check':
          _policyUpdateController.add(enrichedData);
          _complianceAlertController.add(enrichedData);
          break;
          
        // Audit and logging
        case 'audit_log':
        case 'audit_trail':
          _auditLogController.add(enrichedData);
          break;
          
        // Threat intelligence
        case 'threat_intel':
        case 'threat_intelligence':
        case 'ioc_update':
          _threatIntelligenceController.add(enrichedData);
          break;
          
        // System health and monitoring
        case 'system_health':
        case 'health_check':
        case 'performance_metrics':
          _systemHealthController.add(enrichedData);
          break;
          
        // Device management events
        case 'device_event':
        case 'device_status':
        case 'device_enrolled':
        case 'device_unenrolled':
        case 'device_compliance':
          _deviceEventController.add(enrichedData);
          _mdmEventController.add(enrichedData);
          break;
          
        // Network activity
        case 'network_activity':
        case 'network_alert':
        case 'network_anomaly':
          _networkActivityController.add(enrichedData);
          break;
          
        // Vulnerability management
        case 'vulnerability_alert':
        case 'vulnerability_scan':
        case 'patch_status':
          _vulnerabilityAlertController.add(enrichedData);
          break;
          
        // MDM-specific events
        case 'mdm_policy_applied':
        case 'mdm_device_action':
        case 'mdm_compliance_status':
          _mdmEventController.add(enrichedData);
          _deviceEventController.add(enrichedData);
          break;
          
        // System events
        case 'heartbeat':
          // Optionally emit heartbeat to system health stream
          _systemHealthController.add({
            'eventType': 'heartbeat',
            'timestamp': timestamp.toIso8601String(),
            'status': 'alive',
          });
          break;
          
        default:
          developer.log('Unhandled event type: $eventType', level: 900);
          // Optionally send unhandled events to a debug stream or log them
          break;
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error handling WebSocket message: $e',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      
      // Optionally send error to a dedicated error stream
      _systemHealthController.add({
        'eventType': 'error',
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
        'stackTrace': stackTrace.toString(),
      });
    }
  }

  void _handleWebSocketError(Object error) {
    developer.log('WebSocket error: $error');
    _handleConnectionError();
  }

  void _handleWebSocketDone() {
    developer.log('WebSocket connection closed');
    _handleConnectionError();
  }

  Future<void> _connectSocketIO() async {
    if (!_useRealConnection || _socketIOUrl.isEmpty) {
      developer.log('Socket.IO connection skipped - no URL configured');
      return;
    }
    
    try {
      _socketIO = io.io(_socketIOUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'timeout': 20000,
        'auth': {
          'token': _authToken,
        },
      });

      _socketIO!.on('connect', (_) {
        developer.log('Socket.IO connected to $_socketIOUrl');
        _isConnected = true;
        _reconnectAttempts = 0;
        notifyListeners();
      });

      _socketIO!.on('disconnect', (_) {
        developer.log('Socket.IO disconnected');
        _handleConnectionError();
      });

      // Register all event listeners
      _registerSocketIOListeners();

      _socketIO!.on('error', (error) {
        developer.log('Socket.IO error: $error');
        _handleConnectionError();
      });

      _socketIO!.connect();
    } catch (e) {
      developer.log('Socket.IO connection failed: $e');
      _handleConnectionError();
    }
  }

  void _handleConnectionError() {
    _isConnected = false;
    notifyListeners();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      developer.log('Max reconnection attempts reached, switching to mock mode');
      _startMockDataGeneration();
      return;
    }

    // Don't reconnect if using placeholder URLs
    if (_websocketUrl.contains('your-api.com') || _socketIOUrl.contains('your-api.com')) {
      developer.log('Placeholder URLs detected, switching to mock mode');
      _startMockDataGeneration();
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: (2 << _reconnectAttempts)), () {
      _reconnectAttempts++;
      developer.log('Attempting to reconnect (attempt $_reconnectAttempts)');
      initialize();
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected) {
        _sendHeartbeat();
      }
    });
  }

  void _sendHeartbeat() {
    try {
      _wsChannel?.sink.add(jsonEncode({
        'type': 'ping',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }));

      _socketIO?.emit('ping', {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      developer.log('Error sending heartbeat: $e');
    }
  }

  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null && token.isNotEmpty) {
        return token;
      }
      
      // Fallback to environment variable
      return dotenv.env['AUTH_TOKEN'];
    } catch (e) {
      developer.log('Error getting auth token: $e');
      return null;
    }
  }

  void _registerSocketIOListeners() {
    if (_socketIO == null) return;
    
    _socketIO!.on('threat_alert', (data) {
      _threatAlertsController.add(Map<String, dynamic>.from(data));
    });

    _socketIO!.on('compliance_event', (data) {
      _complianceEventsController.add(Map<String, dynamic>.from(data));
    });

    _socketIO!.on('device_event', (data) {
      _deviceEventsController.add(Map<String, dynamic>.from(data));
    });

    _socketIO!.on('forensic_alert', (data) {
      _forensicAlertsController.add(Map<String, dynamic>.from(data));
    });

    _socketIO!.on('system_event', (data) {
      _systemEventsController.add(Map<String, dynamic>.from(data));
    });

    _socketIO!.on('user_activity', (data) {
      _userActivityController.add(Map<String, dynamic>.from(data));
    });

    _socketIO!.on('security_incident', (data) {
      _securityIncidentController.add(Map<String, dynamic>.from(data));
    });

    _socketIO!.on('policy_update', (data) {
      _policyUpdateController.add(Map<String, dynamic>.from(data));
    });

    _socketIO!.on('audit_log', (data) {
      _auditLogController.add(Map<String, dynamic>.from(data));
    });

    _socketIO!.on('threat_intelligence', (data) {
      _threatIntelligenceController.add(Map<String, dynamic>.from(data));
    });

    _socketIO!.on('system_health', (data) {
      _systemHealthController.add(Map<String, dynamic>.from(data));
    });

    _socketIO!.on('compliance_alert', (data) {
      _complianceAlertController.add(Map<String, dynamic>.from(data));
    });

    _socketIO!.on('network_activity', (data) {
      _networkActivityController.add(Map<String, dynamic>.from(data));
    });

    _socketIO!.on('vulnerability_alert', (data) {
      _vulnerabilityAlertController.add(Map<String, dynamic>.from(data));
    });

    _socketIO!.on('mdm_event', (data) {
      _mdmEventController.add(Map<String, dynamic>.from(data));
    });
  }

  void _startMockDataGeneration() {
    // Generate mock real-time events for development/testing
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!_isInitialized) {
        timer.cancel();
        return;
      }
      
      _generateMockThreatAlert();
    });
    
    Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!_isInitialized) {
        timer.cancel();
        return;
      }
      
      _generateMockSystemEvent();
    });
    
    Timer.periodic(const Duration(seconds: 20), (timer) {
      if (!_isInitialized) {
        timer.cancel();
        return;
      }
      
      _generateMockComplianceEvent();
    });
  }
  
  void _generateMockThreatAlert() {
    final mockAlert = {
      'id': 'threat_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'malware_detected',
      'severity': 'high',
      'source': 'endpoint_protection',
      'target': 'workstation_${(DateTime.now().millisecondsSinceEpoch % 100) + 1}',
      'description': 'Suspicious file activity detected',
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'active',
      'isMock': true,
    };
    
    _threatAlertsController.add(mockAlert);
  }
  
  void _generateMockSystemEvent() {
    final mockEvent = {
      'id': 'system_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'system_health',
      'component': 'database',
      'status': 'healthy',
      'metrics': {
        'cpu_usage': (DateTime.now().millisecondsSinceEpoch % 100).toDouble(),
        'memory_usage': (DateTime.now().millisecondsSinceEpoch % 80).toDouble(),
        'disk_usage': (DateTime.now().millisecondsSinceEpoch % 60).toDouble(),
      },
      'timestamp': DateTime.now().toIso8601String(),
      'isMock': true,
    };
    
    _systemEventsController.add(mockEvent);
  }
  
  void _generateMockComplianceEvent() {
    final mockEvent = {
      'id': 'compliance_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'policy_violation',
      'policy': 'password_policy',
      'user': 'user_${(DateTime.now().millisecondsSinceEpoch % 50) + 1}',
      'violation': 'weak_password_detected',
      'severity': 'medium',
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'pending_review',
      'isMock': true,
    };
    
    _complianceEventsController.add(mockEvent);
  }

  // Public methods to send events
  Future<void> sendThreatAlert(Map<String, dynamic> alert) async {
    await _sendMessage('threat_alert', alert);
  }

  Future<void> sendComplianceEvent(Map<String, dynamic> event) async {
    await _sendMessage('compliance_event', event);
  }

  Future<void> sendDeviceEvent(Map<String, dynamic> event) async {
    await _sendMessage('device_event', event);
  }

  Future<void> sendForensicAlert(Map<String, dynamic> alert) async {
    await _sendMessage('forensic_alert', alert);
  }

  Future<void> sendSystemEvent(Map<String, dynamic> event) async {
    await _sendMessage('system_event', event);
  }

  Future<void> _sendMessage(String type, Map<String, dynamic> data) async {
    if (!_isConnected) {
      developer.log('Cannot send message: not connected');
      return;
    }

    try {
      final message = {
        'type': type,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Send via WebSocket
      _wsChannel?.sink.add(jsonEncode(message));

      // Send via Socket.IO
      _socketIO?.emit(type, data);
    } catch (e) {
      developer.log('Error sending message: $e');
    }
  }

  // Subscribe to specific channels
  Future<void> subscribeToChannel(String channel) async {
    await _sendMessage('subscribe', {'channel': channel});
  }

  Future<void> unsubscribeFromChannel(String channel) async {
    await _sendMessage('unsubscribe', {'channel': channel});
  }

  // Join user-specific room for personalized events
  Future<void> joinUserRoom(String userId) async {
    await _sendMessage('join_room', {'room': 'user_$userId'});
  }

  Future<void> leaveUserRoom(String userId) async {
    await _sendMessage('leave_room', {'room': 'user_$userId'});
  }

  // Admin-specific channels
  Future<void> joinAdminChannels() async {
    await subscribeToChannel('admin_alerts');
    await subscribeToChannel('system_status');
    await subscribeToChannel('security_events');
  }

  @override
  void dispose() {
    try {
      // Close WebSocket connection
      _wsChannel?.sink.close();
      _wsChannel = null;
      
      // Close Socket.IO connection
      _socketIO?.disconnect();
      _socketIO?.dispose();
      _socketIO = null;
      
      // Cancel timers
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;
      
      // Close all stream controllers
      _closeStreamController(_userActivityController);
      _closeStreamController(_securityIncidentController);
      _closeStreamController(_policyUpdateController);
      _closeStreamController(_auditLogController);
      _closeStreamController(_threatIntelligenceController);
      _closeStreamController(_systemHealthController);
      _closeStreamController(_complianceAlertController);
      _closeStreamController(_deviceEventController);
      _closeStreamController(_networkActivityController);
      _closeStreamController(_vulnerabilityAlertController);
      _closeStreamController(_mdmEventController);
      
      _isConnected = false;
      super.dispose();
    } catch (e, stackTrace) {
      developer.log(
        'Error disposing RealTimeCommunicationService: $e',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }
  
  void _closeStreamController(StreamController controller) {
    try {
      if (!controller.isClosed) {
        controller.close();
      }
    } catch (e) {
      developer.log('Error closing stream controller: $e', level: 900);
    }
  }
}
