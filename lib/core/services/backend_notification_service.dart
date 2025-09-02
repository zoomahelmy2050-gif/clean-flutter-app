import 'dart:async';
import 'dart:developer' as developer;
import 'api_client.dart';
import 'backend_config.dart';
import '../models/notification_models.dart';

class BackendNotificationService {
  static final BackendNotificationService _instance = BackendNotificationService._internal();
  factory BackendNotificationService() => _instance;
  BackendNotificationService._internal();

  final ApiClient _apiClient = ApiClient();
  StreamSubscription? _notificationSubscription;

  Future<void> initialize() async {
    developer.log('Backend Notification Service initialized', name: 'BackendNotificationService');
  }

  Future<ApiResponse<List<NotificationMessage>>> getNotifications(String userId, {
    String? status,
    String? type,
    String? priority,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (type != null) queryParams['type'] = type;
      if (priority != null) queryParams['priority'] = priority;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final response = await _apiClient.get<List<dynamic>>(
        '${BackendConfig.notificationsEndpoint}/$userId',
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        final notifications = response.data!.map((n) => NotificationMessage.fromJson(n)).toList();
        return ApiResponse.success(notifications);
      }

      return ApiResponse.error(response.error ?? 'Failed to get notifications');
    } catch (e) {
      developer.log('Get notifications failed: $e', name: 'BackendNotificationService');
      return ApiResponse.error('Get notifications failed: $e');
    }
  }

  Future<ApiResponse<NotificationMessage>> sendNotification({
    required String userId,
    required String title,
    required String message,
    String? type,
    String? priority,
    List<String>? channels,
    Map<String, dynamic>? data,
    DateTime? scheduledAt,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        BackendConfig.notificationsEndpoint,
        body: {
          'user_id': userId,
          'title': title,
          'message': message,
          'type': type ?? 'info',
          'priority': priority ?? 'medium',
          'channels': channels ?? ['in_app'],
          'data': data ?? {},
          'scheduled_at': scheduledAt?.toIso8601String(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.success && response.data != null) {
        final notification = NotificationMessage.fromJson(response.data!);
        return ApiResponse.success(notification);
      }

      return ApiResponse.error(response.error ?? 'Failed to send notification');
    } catch (e) {
      developer.log('Send notification failed: $e', name: 'BackendNotificationService');
      return ApiResponse.error('Send notification failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> sendBulkNotification({
    required List<String> userIds,
    required String title,
    required String message,
    String? type,
    String? priority,
    List<String>? channels,
    Map<String, dynamic>? data,
    DateTime? scheduledAt,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.notificationsEndpoint}/bulk',
        body: {
          'user_ids': userIds,
          'title': title,
          'message': message,
          'type': type ?? 'info',
          'priority': priority ?? 'medium',
          'channels': channels ?? ['in_app'],
          'data': data ?? {},
          'scheduled_at': scheduledAt?.toIso8601String(),
          'timestamp': DateTime.now().toIso8601String(),
        },
        timeout: BackendConfig.longOperationTimeout,
      );

      return response;
    } catch (e) {
      developer.log('Send bulk notification failed: $e', name: 'BackendNotificationService');
      return ApiResponse.error('Send bulk notification failed: $e');
    }
  }

  Future<ApiResponse<NotificationMessage>> markAsRead(String notificationId) async {
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '${BackendConfig.notificationsEndpoint}/$notificationId/read',
        body: {'timestamp': DateTime.now().toIso8601String()},
      );

      if (response.success && response.data != null) {
        final notification = NotificationMessage.fromJson(response.data!);
        return ApiResponse.success(notification);
      }

      return ApiResponse.error(response.error ?? 'Failed to mark notification as read');
    } catch (e) {
      developer.log('Mark notification as read failed: $e', name: 'BackendNotificationService');
      return ApiResponse.error('Mark notification as read failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> markAllAsRead(String userId) async {
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '${BackendConfig.notificationsEndpoint}/$userId/read-all',
        body: {'timestamp': DateTime.now().toIso8601String()},
      );

      return response;
    } catch (e) {
      developer.log('Mark all notifications as read failed: $e', name: 'BackendNotificationService');
      return ApiResponse.error('Mark all notifications as read failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> deleteNotification(String notificationId) async {
    try {
      final response = await _apiClient.delete<Map<String, dynamic>>(
        '${BackendConfig.notificationsEndpoint}/$notificationId',
      );

      return response;
    } catch (e) {
      developer.log('Delete notification failed: $e', name: 'BackendNotificationService');
      return ApiResponse.error('Delete notification failed: $e');
    }
  }

  Future<ApiResponse<NotificationPreferences>> getNotificationPreferences(String userId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${BackendConfig.notificationsEndpoint}/$userId/preferences',
      );

      if (response.success && response.data != null) {
        final preferences = NotificationPreferences.fromJson(response.data!);
        return ApiResponse.success(preferences);
      }

      return ApiResponse.error(response.error ?? 'Failed to get notification preferences');
    } catch (e) {
      developer.log('Get notification preferences failed: $e', name: 'BackendNotificationService');
      return ApiResponse.error('Get notification preferences failed: $e');
    }
  }

  Future<ApiResponse<NotificationPreferences>> updateNotificationPreferences(String userId, NotificationPreferences preferences) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '${BackendConfig.notificationsEndpoint}/$userId/preferences',
        body: preferences.toJson(),
      );

      if (response.success && response.data != null) {
        final updatedPreferences = NotificationPreferences.fromJson(response.data!);
        return ApiResponse.success(updatedPreferences);
      }

      return ApiResponse.error(response.error ?? 'Failed to update notification preferences');
    } catch (e) {
      developer.log('Update notification preferences failed: $e', name: 'BackendNotificationService');
      return ApiResponse.error('Update notification preferences failed: $e');
    }
  }

  Future<ApiResponse<List<NotificationTemplate>>> getNotificationTemplates({
    String? type,
    String? category,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (type != null) queryParams['type'] = type;
      if (category != null) queryParams['category'] = category;
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiClient.get<List<dynamic>>(
        '${BackendConfig.notificationsEndpoint}/templates',
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        final templates = response.data!.map((t) => NotificationTemplate.fromJson(t)).toList();
        return ApiResponse.success(templates);
      }

      return ApiResponse.error(response.error ?? 'Failed to get notification templates');
    } catch (e) {
      developer.log('Get notification templates failed: $e', name: 'BackendNotificationService');
      return ApiResponse.error('Get notification templates failed: $e');
    }
  }

  Future<ApiResponse<NotificationTemplate>> createNotificationTemplate(NotificationTemplate template) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.notificationsEndpoint}/templates',
        body: template.toJson(),
      );

      if (response.success && response.data != null) {
        final createdTemplate = NotificationTemplate.fromJson(response.data!);
        return ApiResponse.success(createdTemplate);
      }

      return ApiResponse.error(response.error ?? 'Failed to create notification template');
    } catch (e) {
      developer.log('Create notification template failed: $e', name: 'BackendNotificationService');
      return ApiResponse.error('Create notification template failed: $e');
    }
  }

  Future<ApiResponse<NotificationMessage>> sendFromTemplate({
    required String templateId,
    required String userId,
    Map<String, dynamic>? variables,
    List<String>? channels,
    DateTime? scheduledAt,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.notificationsEndpoint}/send-template',
        body: {
          'template_id': templateId,
          'user_id': userId,
          'variables': variables ?? {},
          'channels': channels ?? ['in_app'],
          'scheduled_at': scheduledAt?.toIso8601String(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.success && response.data != null) {
        final notification = NotificationMessage.fromJson(response.data!);
        return ApiResponse.success(notification);
      }

      return ApiResponse.error(response.error ?? 'Failed to send notification from template');
    } catch (e) {
      developer.log('Send notification from template failed: $e', name: 'BackendNotificationService');
      return ApiResponse.error('Send notification from template failed: $e');
    }
  }

  Stream<NotificationMessage> subscribeToNotifications(String userId) {
    return _apiClient.connectWebSocket<NotificationMessage>(
      '${BackendConfig.wsNotifications}/$userId',
      parser: (data) => NotificationMessage.fromJson(data),
    );
  }

  Future<ApiResponse<List<NotificationChannel>>> getNotificationChannels() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${BackendConfig.notificationsEndpoint}/channels',
      );

      if (response.success && response.data != null) {
        final channels = response.data!.map((c) => NotificationChannel.fromJson(c)).toList();
        return ApiResponse.success(channels);
      }

      return ApiResponse.error(response.error ?? 'Failed to get notification channels');
    } catch (e) {
      developer.log('Get notification channels failed: $e', name: 'BackendNotificationService');
      return ApiResponse.error('Get notification channels failed: $e');
    }
  }

  Future<ApiResponse<NotificationChannel>> configureChannel(NotificationChannel channel) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.notificationsEndpoint}/channels',
        body: {'channel': channel.toJson()},
      );

      if (response.success && response.data != null) {
        final configuredChannel = NotificationChannel.fromJson(response.data!['channel']);
        return ApiResponse.success(configuredChannel);
      }

      return ApiResponse.error(response.error ?? 'Failed to configure notification channel');
    } catch (e) {
      developer.log('Configure notification channel failed: $e', name: 'BackendNotificationService');
      return ApiResponse.error('Configure notification channel failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> testChannel(String channelId, {
    String? testMessage,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.notificationsEndpoint}/channels/$channelId/test',
        body: {
          'test_message': testMessage ?? 'Test notification',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return response;
    } catch (e) {
      developer.log('Test notification channel failed: $e', name: 'BackendNotificationService');
      return ApiResponse.error('Test notification channel failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getNotificationStats({
    String? userId,
    String? timeRange,
    List<String>? metrics,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (userId != null) queryParams['user_id'] = userId;
      if (timeRange != null) queryParams['time_range'] = timeRange;
      if (metrics != null) queryParams['metrics'] = metrics.join(',');

      final response = await _apiClient.get<Map<String, dynamic>>(
        '${BackendConfig.notificationsEndpoint}/stats',
        queryParams: queryParams,
      );

      return response;
    } catch (e) {
      developer.log('Get notification stats failed: $e', name: 'BackendNotificationService');
      return ApiResponse.error('Get notification stats failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> scheduleNotification({
    required String userId,
    required String title,
    required String message,
    required DateTime scheduledAt,
    String? type,
    String? priority,
    List<String>? channels,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${BackendConfig.notificationsEndpoint}/schedule',
        body: {
          'user_id': userId,
          'title': title,
          'message': message,
          'scheduled_at': scheduledAt.toIso8601String(),
          'type': type ?? 'info',
          'priority': priority ?? 'medium',
          'channels': channels ?? ['in_app'],
          'data': data ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return response;
    } catch (e) {
      developer.log('Schedule notification failed: $e', name: 'BackendNotificationService');
      return ApiResponse.error('Schedule notification failed: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> cancelScheduledNotification(String notificationId) async {
    try {
      final response = await _apiClient.delete<Map<String, dynamic>>(
        '${BackendConfig.notificationsEndpoint}/schedule/$notificationId',
      );

      return response;
    } catch (e) {
      developer.log('Cancel scheduled notification failed: $e', name: 'BackendNotificationService');
      return ApiResponse.error('Cancel scheduled notification failed: $e');
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getScheduledNotifications(String userId) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${BackendConfig.notificationsEndpoint}/$userId/scheduled',
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data!.cast<Map<String, dynamic>>());
      }

      return ApiResponse.error(response.error ?? 'Failed to get scheduled notifications');
    } catch (e) {
      developer.log('Get scheduled notifications failed: $e', name: 'BackendNotificationService');
      return ApiResponse.error('Get scheduled notifications failed: $e');
    }
  }

  void dispose() {
    _notificationSubscription?.cancel();
  }
}
