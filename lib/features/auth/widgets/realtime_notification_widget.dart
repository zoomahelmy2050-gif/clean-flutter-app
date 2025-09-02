import 'package:flutter/material.dart';
import '../../../core/services/realtime_notification_service.dart';
import '../../../locator.dart';
import 'dart:async';

class RealtimeNotificationWidget extends StatefulWidget {
  final Widget child;
  
  const RealtimeNotificationWidget({
    Key? key,
    required this.child,
  }) : super(key: key);
  
  @override
  State<RealtimeNotificationWidget> createState() => _RealtimeNotificationWidgetState();
}

class _RealtimeNotificationWidgetState extends State<RealtimeNotificationWidget> 
    with TickerProviderStateMixin {
  final RealtimeNotificationService _realtimeService = locator<RealtimeNotificationService>();
  final List<_NotificationItem> _activeNotifications = [];
  StreamSubscription<SecurityEvent>? _securityEventSubscription;
  StreamSubscription<SystemAlert>? _systemAlertSubscription;
  StreamSubscription<UserActivity>? _userActivitySubscription;
  
  @override
  void initState() {
    super.initState();
    _subscribeToEvents();
  }
  
  void _subscribeToEvents() {
    _securityEventSubscription = _realtimeService.securityEvents.listen((event) {
      _showNotification(
        title: 'Security Alert',
        message: event.description,
        severity: event.severity,
        icon: Icons.security,
        color: _getSeverityColor(event.severity),
      );
    });
    
    _systemAlertSubscription = _realtimeService.systemAlerts.listen((alert) {
      _showNotification(
        title: alert.title,
        message: alert.message,
        severity: alert.priority,
        icon: Icons.warning_amber_rounded,
        color: _getSeverityColor(alert.priority),
      );
    });
    
    _userActivitySubscription = _realtimeService.userActivities.listen((activity) {
      if (activity.isSuspicious) {
        _showNotification(
          title: 'Suspicious Activity',
          message: activity.description,
          severity: 'high',
          icon: Icons.person_off,
          color: Colors.orange,
        );
      }
    });
  }
  
  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow[700]!;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
  
  void _showNotification({
    required String title,
    required String message,
    required String severity,
    required IconData icon,
    required Color color,
  }) {
    final animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    final slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOutCubic,
    ));
    
    final notification = _NotificationItem(
      key: UniqueKey(),
      title: title,
      message: message,
      severity: severity,
      icon: icon,
      color: color,
      animationController: animationController,
      slideAnimation: slideAnimation,
      onDismiss: () => _removeNotification,
    );
    
    setState(() {
      _activeNotifications.add(notification);
    });
    
    animationController.forward();
    
    // Auto-dismiss after 5 seconds for non-critical notifications
    if (severity.toLowerCase() != 'critical') {
      Future.delayed(const Duration(seconds: 5), () {
        _removeNotification(notification);
      });
    }
  }
  
  void _removeNotification(_NotificationItem notification) async {
    await notification.animationController.reverse();
    if (mounted) {
      setState(() {
        _activeNotifications.remove(notification);
      });
    }
    notification.animationController.dispose();
  }
  
  @override
  void dispose() {
    _securityEventSubscription?.cancel();
    _systemAlertSubscription?.cancel();
    _userActivitySubscription?.cancel();
    for (final notification in _activeNotifications) {
      notification.animationController.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          if (_activeNotifications.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _activeNotifications.map((notification) {
                  return SlideTransition(
                    position: notification.slideAnimation,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: _NotificationCard(
                        notification: notification,
                        onDismiss: () => _removeNotification(notification),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          // Connection status indicator
          Positioned(
            bottom: 24,
            left: 24,
            child: AnimatedBuilder(
              animation: _realtimeService,
              builder: (context, child) {
                if (!_realtimeService.isConnected) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Text(
                          'Reconnecting...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem {
  final Key key;
  final String title;
  final String message;
  final String severity;
  final IconData icon;
  final Color color;
  final AnimationController animationController;
  final Animation<Offset> slideAnimation;
  final Function onDismiss;
  
  _NotificationItem({
    required this.key,
    required this.title,
    required this.message,
    required this.severity,
    required this.icon,
    required this.color,
    required this.animationController,
    required this.slideAnimation,
    required this.onDismiss,
  });
}

class _NotificationCard extends StatelessWidget {
  final _NotificationItem notification;
  final VoidCallback onDismiss;
  
  const _NotificationCard({
    required this.notification,
    required this.onDismiss,
  });
  
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: notification.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  notification.icon,
                  color: notification.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 16),
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
