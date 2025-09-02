import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import '../models/notification_models.dart';
import 'api_service.dart';

class NotificationService with ChangeNotifier {
  static const String _notificationsKey = 'app_notifications';
  static const String _settingsKey = 'notification_settings';
  
  final ApiService? _apiService;
  List<NotificationMessage> _notifications = [];
  NotificationSettings _settings = NotificationSettings();
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  
  // Push notifications token
  String? _fcmToken;
  
  // Local notifications
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  NotificationService(this._apiService) {
    developer.log('NotificationService initialized', name: 'NotificationService');
  }
  
  List<NotificationMessage> get notifications => _notifications;
  NotificationSettings get settings => _settings;
  
  Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _loadNotifications();
    await _loadSettings();
    _isInitialized = true;
  }
  
  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsData = prefs.getStringList(_notificationsKey) ?? [];
    _notifications = notificationsData
        .map((data) => NotificationMessage.fromJson(jsonDecode(data)))
        .toList();
    notifyListeners();
  }
  
  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = _notifications
        .map((n) => jsonEncode(n.toJson()))
        .toList();
    await prefs.setStringList(_notificationsKey, notificationsJson);
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);
    if (settingsJson != null) {
      final settings = jsonDecode(settingsJson);
      _settings = NotificationSettings.fromJson(settings);
      notifyListeners();
    }
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = jsonEncode(_settings.toJson());
    await prefs.setString(_settingsKey, settingsJson);
  }
  
  Future<void> sendNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    String? actionUrl,
  }) async {
    final notification = NotificationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      severity: _mapTypeToSeverity(type),
      category: NotificationCategory.system,
      createdAt: DateTime.now(),
      metadata: actionUrl != null ? {'actionUrl': actionUrl} : {},
    );
    
    _notifications.insert(0, notification);
    await _saveNotifications();
    notifyListeners();
    
    // Show local notification
    await _showLocalNotification(notification);
  }
  
  Future<void> _showLocalNotification(NotificationMessage notification) async {
    try {
      // Check if notifications are enabled and not in quiet hours
      if (!_settings.pushNotifications || _isInQuietHours()) {
        return;
      }
      
      // Haptic feedback
      await HapticFeedback.lightImpact();
      
      // Show local notification
      await _showLocalNotificationDetails(notification);
    } catch (e) {
      developer.log('Failed to show system notification: $e', name: 'NotificationService');
    }
  }
  
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = NotificationMessage(
        id: _notifications[index].id,
        title: _notifications[index].title,
        message: _notifications[index].message,
        severity: _notifications[index].severity,
        category: _notifications[index].category,
        createdAt: _notifications[index].createdAt,
        status: NotificationStatus.delivered,
        metadata: _notifications[index].metadata,
        recipients: _notifications[index].recipients,
        channels: _notifications[index].channels,
      );
      await _saveNotifications();
      notifyListeners();
    }
  }
  
  Future<void> markAllAsRead() async {
    _notifications = _notifications
        .map((n) => NotificationMessage(
          id: n.id,
          title: n.title,
          message: n.message,
          severity: n.severity,
          category: n.category,
          createdAt: n.createdAt,
          status: NotificationStatus.delivered,
          metadata: n.metadata,
          recipients: n.recipients,
          channels: n.channels,
        ))
        .toList();
    await _saveNotifications();
    notifyListeners();
  }
  
  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    await _saveNotifications();
    notifyListeners();
  }
  
  Future<void> clearAllNotifications() async {
    _notifications.clear();
    await _saveNotifications();
    notifyListeners();
  }

  // Missing methods for BackgroundSyncService and RealtimeNotificationService
  Future<void> showNotification({
    required String title,
    required String body,
    NotificationType type = NotificationType.info,
  }) async {
    await addNotificationInternal(title, body, type);
  }

  Future<void> addNotification(Map<String, dynamic> notification) async {
    await addNotificationInternal(
      notification['title'] ?? 'Notification',
      notification['body'] ?? '',
      NotificationType.info,
    );
  }

  Future<void> addNotificationInternal(String title, String body, NotificationType type) async {
    final notification = NotificationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: body,
      severity: _mapTypeToSeverity(type),
      category: NotificationCategory.system,
      createdAt: DateTime.now(),
    );

    _notifications.insert(0, notification);
    await _saveNotifications();
    notifyListeners();
  }

  NotificationSeverity _mapTypeToSeverity(NotificationType type) {
    switch (type) {
      case NotificationType.error:
        return NotificationSeverity.error;
      case NotificationType.warning:
        return NotificationSeverity.warning;
      case NotificationType.success:
      case NotificationType.info:
      case NotificationType.system:
      default:
        return NotificationSeverity.info;
    }
  }
  
  Future<void> updateSettings(NotificationSettings newSettings) async {
    _settings = newSettings;
    await _saveSettings();
    
    // Sync with backend if available
    if (_apiService != null) {
      await _syncSettingsWithBackend(newSettings);
    }
    
    notifyListeners();
  }

  Future<bool> _syncSettingsWithBackend(NotificationSettings settings) async {
    try {
      final response = await _apiService!.put('/api/notifications/settings', 
          body: settings.toJson());
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  Future<bool> loadNotificationsFromBackend(String userId) async {
    if (_apiService == null) return false;
    
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get<List<dynamic>>('/api/users/$userId/notifications');
      
      if (response.isSuccess && response.data != null) {
        _notifications = response.data!
            .map((notificationData) => NotificationMessage.fromJson(notificationData))
            .toList();
        await _saveNotifications();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to load notifications: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendPushNotification(String userId, String title, String message) async {
    if (_apiService == null) return false;

    try {
      final response = await _apiService.post('/api/notifications/push', body: {
        'userId': userId,
        'title': title,
        'message': message,
      });
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }
  
  // Test notification methods
  Future<void> sendTestNotification() async {
    await sendNotification(
      title: 'Test Notification',
      message: 'This is a test notification sent at ${DateTime.now().toString().substring(11, 19)}',
      type: NotificationType.info,
    );
  }
  
  Future<void> sendSecurityAlert() async {
    await sendNotification(
      title: 'Security Alert',
      message: 'Suspicious login attempt detected from new device',
      type: NotificationType.security,
    );
  }
  
  Future<void> sendLoginNotification() async {
    await sendNotification(
      title: 'Login Successful',
      message: 'You have successfully logged in to your account',
      type: NotificationType.success,
    );
  }
  
  int get unreadCount => _notifications.where((n) => n.status != NotificationStatus.delivered).length;
  
  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Request permissions
    await _requestNotificationPermissions();
  }
  
  /// Request notification permissions
  Future<void> _requestNotificationPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (status != PermissionStatus.granted) {
        developer.log('Notification permission denied', name: 'NotificationService');
      }
    }
  }
  
  /// Show local notification details
  Future<void> _showLocalNotificationDetails(NotificationMessage notification) async {
    final androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Notifications',
      channelDescription: 'Default notification channel',
      importance: _getImportanceFromType(notification.severity),
      priority: _getPriorityFromType(notification.severity),
      icon: '@mipmap/ic_launcher',
      color: _getColorFromType(notification.severity),
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.message,
      details,
      payload: jsonEncode(notification.metadata),
    );
  }
  
  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      // Handle deep link or action URL
      _handleNotificationAction(response.payload!);
    }
  }
  
  /// Handle foreground Firebase messages
  Future<void> _handleForegroundMessage(Map<String, dynamic> message) async {
    final notification = NotificationMessage(
      id: message['messageId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message['notification']?['title'] ?? 'New Message',
      message: message['notification']?['body'] ?? '',
      severity: _mapTypeToSeverity(NotificationType.info),
      category: NotificationCategory.system,
      createdAt: DateTime.now(),
    );

    _notifications.insert(0, notification);
    _saveNotifications();
    notifyListeners();
    
    await _showLocalNotificationDetails(notification);
  }
  
  /// Handle background Firebase messages
  void _handleBackgroundMessage(Map<String, dynamic> message) {
    final notification = NotificationMessage(
      id: message['messageId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message['notification']?['title'] ?? 'New Message',
      message: message['notification']?['body'] ?? '',
      severity: _mapTypeToSeverity(NotificationType.info),
      category: NotificationCategory.system,
      createdAt: DateTime.now(),
    );

    _notifications.insert(0, notification);
    _saveNotifications();
    notifyListeners();
  }
  
  /// Check if currently in quiet hours
  bool _isInQuietHours() {
    final now = TimeOfDay.now();
    final start = _parseTimeOfDay(_settings.quietHoursStart);
    final end = _parseTimeOfDay(_settings.quietHoursEnd);
    
    if (start.hour < end.hour) {
      // Same day quiet hours (e.g., 22:00 to 08:00 next day)
      return now.hour >= start.hour || now.hour < end.hour;
    } else {
      // Cross-day quiet hours (e.g., 08:00 to 22:00)
      return now.hour >= start.hour && now.hour < end.hour;
    }
  }
  
  /// Parse time string to TimeOfDay
  TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
  
  /// Get Android importance from notification type
  Importance _getImportanceFromType(NotificationSeverity type) {
    switch (type) {
      case NotificationSeverity.error:
      case NotificationSeverity.critical:
        return Importance.high;
      case NotificationSeverity.warning:
        return Importance.defaultImportance;
      case NotificationSeverity.info:
        return Importance.low;
    }
  }
  
  /// Get Android priority from notification type
  Priority _getPriorityFromType(NotificationSeverity type) {
    switch (type) {
      case NotificationSeverity.error:
      case NotificationSeverity.critical:
        return Priority.high;
      case NotificationSeverity.warning:
        return Priority.defaultPriority;
      case NotificationSeverity.info:
        return Priority.low;
    }
  }
  
  /// Get color from notification type
  Color _getColorFromType(NotificationSeverity type) {
    switch (type) {
      case NotificationSeverity.error:
      case NotificationSeverity.critical:
        return Colors.red;
      case NotificationSeverity.warning:
        return Colors.orange;
      case NotificationSeverity.info:
        return Colors.blue;
    }
  }
  
  /// Handle notification action/deep link
  void _handleNotificationAction(String actionUrl) {
    // This would typically handle deep links or navigation
    developer.log('Handling notification action: $actionUrl', name: 'NotificationService');
  }
  
  
  /// Schedule notification for later
  Future<void> scheduleNotification({
    required String title,
    required String message,
    required DateTime scheduledTime,
    NotificationType type = NotificationType.info,
    String? actionUrl,
  }) async {
    final notification = NotificationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      severity: _mapTypeToSeverity(type),
      category: NotificationCategory.system,
      createdAt: scheduledTime,
      metadata: actionUrl != null ? {'actionUrl': actionUrl} : {},
    );
    
    final androidDetails = AndroidNotificationDetails(
      'scheduled_channel',
      'Scheduled Notifications',
      channelDescription: 'Scheduled notification channel',
      importance: _getImportanceFromType(notification.severity),
      priority: _getPriorityFromType(notification.severity),
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.zonedSchedule(
      notification.id.hashCode,
      title,
      message,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      payload: actionUrl,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
  
  /// Cancel scheduled notification
  Future<void> cancelScheduledNotification(int id) async {
    await _localNotifications.cancel(id);
  }
  
  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}

enum NotificationType {
  info,
  success,
  warning,
  error,
  security,
  system,
}

class NotificationSettings {
  final bool pushNotifications;
  final bool emailNotifications;
  final bool securityAlerts;
  final bool loginNotifications;
  final bool systemUpdates;
  final String quietHoursStart;
  final String quietHoursEnd;
  
  NotificationSettings({
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.securityAlerts = true,
    this.loginNotifications = true,
    this.systemUpdates = true,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
  });
  
  NotificationSettings copyWith({
    bool? pushNotifications,
    bool? emailNotifications,
    bool? securityAlerts,
    bool? loginNotifications,
    bool? systemUpdates,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) {
    return NotificationSettings(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      securityAlerts: securityAlerts ?? this.securityAlerts,
      loginNotifications: loginNotifications ?? this.loginNotifications,
      systemUpdates: systemUpdates ?? this.systemUpdates,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'securityAlerts': securityAlerts,
      'loginNotifications': loginNotifications,
      'systemUpdates': systemUpdates,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
    };
  }
  
  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      pushNotifications: json['pushNotifications'] ?? true,
      emailNotifications: json['emailNotifications'] ?? true,
      securityAlerts: json['securityAlerts'] ?? true,
      loginNotifications: json['loginNotifications'] ?? true,
      systemUpdates: json['systemUpdates'] ?? true,
      quietHoursStart: json['quietHoursStart'] ?? '22:00',
      quietHoursEnd: json['quietHoursEnd'] ?? '08:00',
    );
  }
}




