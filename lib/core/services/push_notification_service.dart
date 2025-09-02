import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'environment_service.dart';

class PushNotificationService extends ChangeNotifier {
  static PushNotificationService? _instance;
  static PushNotificationService get instance => _instance ??= PushNotificationService._();
  PushNotificationService._();

  bool _isInitialized = false;
  String? _fcmToken;
  final List<Map<String, dynamic>> _notifications = [];
  late EnvironmentService _environmentService;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _environmentService = EnvironmentService.instance;
    await _loadStoredToken();
    await _requestPermission();
    
    _isInitialized = true;
    developer.log('Push notification service initialized');
  }

  Future<void> _loadStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _fcmToken = prefs.getString('fcm_token');
      developer.log('FCM token loaded: ${_fcmToken?.substring(0, 20)}...');
    } catch (e) {
      developer.log('Error loading FCM token: $e');
    }
  }

  Future<void> _requestPermission() async {
    try {
      // In a real implementation, this would use firebase_messaging
      // For now, we'll simulate the permission request
      developer.log('Requesting notification permissions...');
      
      // Simulate token generation
      if (_fcmToken == null) {
        _fcmToken = _generateMockToken();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
        developer.log('Generated mock FCM token: ${_fcmToken!.substring(0, 20)}...');
      }
    } catch (e) {
      developer.log('Error requesting notification permission: $e');
    }
  }

  String _generateMockToken() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return 'mock_fcm_token_$random';
  }

  Future<Map<String, dynamic>> sendNotification({
    required String title,
    required String body,
    String? token,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? sound,
    int? badge,
  }) async {
    if (!_environmentService.isPushNotificationConfigured) {
      return {
        'success': false,
        'error': 'Push notification service not configured'
      };
    }

    try {
      final targetToken = token ?? _fcmToken;
      if (targetToken == null) {
        return {
          'success': false,
          'error': 'No FCM token available'
        };
      }

      final payload = {
        'to': targetToken,
        'notification': {
          'title': title,
          'body': body,
          if (imageUrl != null) 'image': imageUrl,
          if (sound != null) 'sound': sound,
          if (badge != null) 'badge': badge,
        },
        if (data != null) 'data': data,
        'priority': 'high',
        'content_available': true,
      };

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Authorization': 'key=${_environmentService.fcmServerKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        developer.log('Push notification sent successfully');
        
        // Store notification locally
        _addNotificationToHistory(title, body, data);
        
        return {
          'success': true,
          'messageId': responseData['results']?[0]?['message_id'],
          'response': responseData,
        };
      } else {
        developer.log('Failed to send push notification: ${response.body}');
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      developer.log('Error sending push notification: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> sendToMultipleTokens({
    required String title,
    required String body,
    required List<String> tokens,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    if (!_environmentService.isPushNotificationConfigured) {
      return {
        'success': false,
        'error': 'Push notification service not configured'
      };
    }

    try {
      final payload = {
        'registration_ids': tokens,
        'notification': {
          'title': title,
          'body': body,
          if (imageUrl != null) 'image': imageUrl,
        },
        if (data != null) 'data': data,
        'priority': 'high',
        'content_available': true,
      };

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Authorization': 'key=${_environmentService.fcmServerKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        developer.log('Bulk push notification sent successfully');
        
        _addNotificationToHistory(title, body, data);
        
        return {
          'success': true,
          'successCount': responseData['success'] ?? 0,
          'failureCount': responseData['failure'] ?? 0,
          'results': responseData['results'],
        };
      } else {
        developer.log('Failed to send bulk push notification: ${response.body}');
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      developer.log('Error sending bulk push notification: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> sendToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    if (!_environmentService.isPushNotificationConfigured) {
      return {
        'success': false,
        'error': 'Push notification service not configured'
      };
    }

    try {
      final payload = {
        'to': '/topics/$topic',
        'notification': {
          'title': title,
          'body': body,
          if (imageUrl != null) 'image': imageUrl,
        },
        if (data != null) 'data': data,
        'priority': 'high',
        'content_available': true,
      };

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Authorization': 'key=${_environmentService.fcmServerKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        developer.log('Topic push notification sent successfully');
        
        _addNotificationToHistory(title, body, data);
        
        return {
          'success': true,
          'messageId': responseData['message_id'],
          'response': responseData,
        };
      } else {
        developer.log('Failed to send topic push notification: ${response.body}');
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      developer.log('Error sending topic push notification: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> subscribeToTopic(String topic) async {
    if (_fcmToken == null) {
      return {
        'success': false,
        'error': 'No FCM token available'
      };
    }

    try {
      final response = await http.post(
        Uri.parse('https://iid.googleapis.com/iid/v1/${_fcmToken}/rel/topics/$topic'),
        headers: {
          'Authorization': 'key=${_environmentService.fcmServerKey}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        developer.log('Successfully subscribed to topic: $topic');
        return {'success': true};
      } else {
        developer.log('Failed to subscribe to topic: ${response.body}');
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      developer.log('Error subscribing to topic: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> unsubscribeFromTopic(String topic) async {
    if (_fcmToken == null) {
      return {
        'success': false,
        'error': 'No FCM token available'
      };
    }

    try {
      final response = await http.delete(
        Uri.parse('https://iid.googleapis.com/iid/v1/${_fcmToken}/rel/topics/$topic'),
        headers: {
          'Authorization': 'key=${_environmentService.fcmServerKey}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        developer.log('Successfully unsubscribed from topic: $topic');
        return {'success': true};
      } else {
        developer.log('Failed to unsubscribe from topic: ${response.body}');
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      developer.log('Error unsubscribing from topic: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Security-specific notification methods
  Future<void> sendSecurityAlert({
    required String alertType,
    required String message,
    String? deviceId,
    Map<String, dynamic>? metadata,
  }) async {
    await sendNotification(
      title: 'Security Alert: $alertType',
      body: message,
      data: {
        'type': 'security_alert',
        'alert_type': alertType,
        if (deviceId != null) 'device_id': deviceId,
        if (metadata != null) ...metadata,
        'timestamp': DateTime.now().toIso8601String(),
      },
      sound: 'security_alert.wav',
      badge: 1,
    );
  }

  Future<void> sendThreatDetection({
    required String threatType,
    required String description,
    String? sourceIp,
    String? severity,
  }) async {
    await sendNotification(
      title: 'Threat Detected: $threatType',
      body: description,
      data: {
        'type': 'threat_detection',
        'threat_type': threatType,
        'severity': severity ?? 'medium',
        if (sourceIp != null) 'source_ip': sourceIp,
        'timestamp': DateTime.now().toIso8601String(),
      },
      sound: 'threat_alert.wav',
      badge: 1,
    );
  }

  Future<void> sendLoginAlert({
    required String deviceName,
    required String location,
    required String ipAddress,
  }) async {
    await sendNotification(
      title: 'New Login Detected',
      body: 'Login from $deviceName in $location',
      data: {
        'type': 'login_alert',
        'device_name': deviceName,
        'location': location,
        'ip_address': ipAddress,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  void _addNotificationToHistory(String title, String body, Map<String, dynamic>? data) {
    _notifications.insert(0, {
      'title': title,
      'body': body,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'read': false,
    });

    // Keep only last 100 notifications
    if (_notifications.length > 100) {
      _notifications.removeRange(100, _notifications.length);
    }

    notifyListeners();
  }

  // Getters
  String? get fcmToken => _fcmToken;
  List<Map<String, dynamic>> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => n['read'] == false).length;
  bool get isInitialized => _isInitialized;

  // Mark notification as read
  void markAsRead(int index) {
    if (index >= 0 && index < _notifications.length) {
      _notifications[index]['read'] = true;
      notifyListeners();
    }
  }

  // Clear all notifications
  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  // Refresh FCM token
  Future<void> refreshToken() async {
    _fcmToken = _generateMockToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', _fcmToken!);
    notifyListeners();
    developer.log('FCM token refreshed');
  }
}
