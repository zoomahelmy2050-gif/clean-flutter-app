import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/services/notification_service.dart';
import '../../core/models/notification_models.dart';

class NotificationCenterPage extends StatelessWidget {
  const NotificationCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Center'),
        actions: [
          Consumer<NotificationService>(
            builder: (context, notificationService, child) {
              return PopupMenuButton<String>(
                onSelected: (action) {
                  switch (action) {
                    case 'mark_all_read':
                      notificationService.markAllAsRead();
                      break;
                    case 'clear_all':
                      _showClearAllDialog(context, notificationService);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        Icon(Icons.mark_email_read),
                        SizedBox(width: 8),
                        Text('Mark All as Read'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Clear All'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationService>(
        builder: (context, notificationService, child) {
          final notifications = notificationService.notifications;
          
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You\'re all caught up!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(
                notification: notification,
                onTap: () {
                  if (notification.status != NotificationStatus.delivered) {
                    notificationService.markAsRead(notification.id);
                  }
                },
                onDismiss: () {
                  notificationService.deleteNotification(notification.id);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final notificationService = Provider.of<NotificationService>(context, listen: false);
          notificationService.sendTestNotification();
        },
        child: const Icon(Icons.add_alert),
        tooltip: 'Send Test Notification',
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, NotificationService notificationService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              notificationService.clearAllNotifications();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationMessage notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: notification.status == NotificationStatus.delivered ? Colors.grey[100] : null,
        elevation: notification.status == NotificationStatus.delivered ? 0 : 2,
        child: ListTile(
          leading: _getNotificationIcon(),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.status == NotificationStatus.delivered ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.message,
                style: TextStyle(
                  fontWeight: notification.status == NotificationStatus.delivered ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMM dd, yyyy HH:mm').format(notification.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          trailing: notification.status == NotificationStatus.delivered
              ? null
              : Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getNotificationColor(),
                    shape: BoxShape.circle,
                  ),
                ),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _getNotificationIcon() {
    IconData iconData;
    Color color = _getNotificationColor();
    
    switch (notification.severity) {
      case NotificationSeverity.warning:
        iconData = Icons.warning;
        break;
      case NotificationSeverity.error:
      case NotificationSeverity.critical:
        iconData = Icons.error;
        break;
      case NotificationSeverity.info:
        iconData = Icons.info;
        break;
    }
    
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(iconData, color: color),
    );
  }

  Color _getNotificationColor() {
    switch (notification.severity) {
      case NotificationSeverity.info:
        return Colors.blue;
      case NotificationSeverity.warning:
        return Colors.orange;
      case NotificationSeverity.error:
      case NotificationSeverity.critical:
        return Colors.red;
    }
  }
}
