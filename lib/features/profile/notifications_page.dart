import 'package:flutter/material.dart';
import 'package:clean_flutter/locator.dart';
import 'package:clean_flutter/features/auth/services/auth_service.dart';
import 'package:clean_flutter/core/services/notification_service.dart';
import 'package:provider/provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _authService = locator<AuthService>();

  bool _isLoading = false;
  String? _currentUser;

  // Notification preferences
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;

  // Security notifications
  bool _securityAlerts = true;
  bool _loginNotifications = true;
  bool _passwordChanges = true;
  bool _suspiciousActivity = true;
  bool _newDeviceLogin = true;

  // App notifications
  bool _appUpdates = true;
  bool _featureAnnouncements = false;
  bool _maintenanceAlerts = true;
  bool _systemStatus = true;

  // Communication preferences
  bool _marketingEmails = false;
  bool _newsletters = false;
  bool _surveys = false;
  bool _promotions = false;

  // Notification timing
  String _quietHoursStart = '22:00';
  String _quietHoursEnd = '08:00';
  bool _quietHoursEnabled = true;
  bool _weekendNotifications = true;

  // Notification frequency
  String _digestFrequency = 'daily';
  bool _instantNotifications = true;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Mock loading notification settings - in real app, load from backend
      await Future.delayed(const Duration(milliseconds: 500));

      // Settings are already initialized with default values above
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load notification settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveNotificationSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Mock save operation - in real app, save to backend
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save notification settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testNotification() async {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    
    setState(() => _isLoading = true);
    
    try {
      // Send multiple test notifications
      await notificationService.sendTestNotification();
      await Future.delayed(const Duration(milliseconds: 500));
      await notificationService.sendSecurityAlert();
      await Future.delayed(const Duration(milliseconds: 500));
      await notificationService.sendLoginNotification();
      
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notifications sent! Check your notification center.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send test notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectTime(String type) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      final timeString =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (type == 'start') {
          _quietHoursStart = timeString;
        } else {
          _quietHoursEnd = timeString;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveNotificationSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notification Methods
                  Text(
                    'Notification Methods',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          icon: Icons.notifications,
                          title: 'Push Notifications',
                          subtitle: 'Receive notifications on this device',
                          value: _pushNotifications,
                          onChanged: (value) {
                            setState(() {
                              _pushNotifications = value;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          icon: Icons.email,
                          title: 'Email Notifications',
                          subtitle: 'Receive notifications via email',
                          value: _emailNotifications,
                          onChanged: (value) {
                            setState(() {
                              _emailNotifications = value;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          icon: Icons.sms,
                          title: 'SMS Notifications',
                          subtitle: 'Receive critical alerts via SMS',
                          value: _smsNotifications,
                          onChanged: (value) {
                            setState(() {
                              _smsNotifications = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Security Notifications
                  Text(
                    'Security Notifications',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          icon: Icons.security,
                          title: 'Security Alerts',
                          subtitle: 'Important security notifications',
                          value: _securityAlerts,
                          onChanged: (value) {
                            setState(() {
                              _securityAlerts = value;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          icon: Icons.login,
                          title: 'Login Notifications',
                          subtitle:
                              'Notify when someone logs into your account',
                          value: _loginNotifications,
                          onChanged: (value) {
                            setState(() {
                              _loginNotifications = value;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          icon: Icons.lock,
                          title: 'Password Changes',
                          subtitle: 'Notify when password is changed',
                          value: _passwordChanges,
                          onChanged: (value) {
                            setState(() {
                              _passwordChanges = value;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          icon: Icons.warning,
                          title: 'Suspicious Activity',
                          subtitle: 'Alerts for unusual account activity',
                          value: _suspiciousActivity,
                          onChanged: (value) {
                            setState(() {
                              _suspiciousActivity = value;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          icon: Icons.devices,
                          title: 'New Device Login',
                          subtitle: 'Notify when logging in from new device',
                          value: _newDeviceLogin,
                          onChanged: (value) {
                            setState(() {
                              _newDeviceLogin = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // App Notifications
                  Text(
                    'App Notifications',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          icon: Icons.system_update,
                          title: 'App Updates',
                          subtitle: 'Notifications about app updates',
                          value: _appUpdates,
                          onChanged: (value) {
                            setState(() {
                              _appUpdates = value;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          icon: Icons.new_releases,
                          title: 'Feature Announcements',
                          subtitle: 'Learn about new features',
                          value: _featureAnnouncements,
                          onChanged: (value) {
                            setState(() {
                              _featureAnnouncements = value;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          icon: Icons.build,
                          title: 'Maintenance Alerts',
                          subtitle: 'Scheduled maintenance notifications',
                          value: _maintenanceAlerts,
                          onChanged: (value) {
                            setState(() {
                              _maintenanceAlerts = value;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          icon: Icons.info,
                          title: 'System Status',
                          subtitle: 'Service status and outage notifications',
                          value: _systemStatus,
                          onChanged: (value) {
                            setState(() {
                              _systemStatus = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Communication Preferences
                  Text(
                    'Communication Preferences',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          icon: Icons.campaign,
                          title: 'Marketing Emails',
                          subtitle: 'Promotional and marketing content',
                          value: _marketingEmails,
                          onChanged: (value) {
                            setState(() {
                              _marketingEmails = value;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          icon: Icons.article,
                          title: 'Newsletters',
                          subtitle: 'Company news and updates',
                          value: _newsletters,
                          onChanged: (value) {
                            setState(() {
                              _newsletters = value;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          icon: Icons.poll,
                          title: 'Surveys',
                          subtitle: 'Feedback requests and surveys',
                          value: _surveys,
                          onChanged: (value) {
                            setState(() {
                              _surveys = value;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          icon: Icons.local_offer,
                          title: 'Promotions',
                          subtitle: 'Special offers and discounts',
                          value: _promotions,
                          onChanged: (value) {
                            setState(() {
                              _promotions = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Notification Timing
                  Text(
                    'Notification Timing',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildSwitchTile(
                            icon: Icons.bedtime,
                            title: 'Quiet Hours',
                            subtitle:
                                'Reduce notifications during specified hours',
                            value: _quietHoursEnabled,
                            onChanged: (value) {
                              setState(() {
                                _quietHoursEnabled = value;
                              });
                            },
                          ),
                          if (_quietHoursEnabled) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectTime('start'),
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Start Time',
                                        border: OutlineInputBorder(),
                                      ),
                                      child: Text(_quietHoursStart),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectTime('end'),
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'End Time',
                                        border: OutlineInputBorder(),
                                      ),
                                      child: Text(_quietHoursEnd),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          _buildSwitchTile(
                            icon: Icons.weekend,
                            title: 'Weekend Notifications',
                            subtitle: 'Receive notifications on weekends',
                            value: _weekendNotifications,
                            onChanged: (value) {
                              setState(() {
                                _weekendNotifications = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Notification Frequency
                  Text(
                    'Notification Frequency',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildSwitchTile(
                            icon: Icons.flash_on,
                            title: 'Instant Notifications',
                            subtitle: 'Receive notifications immediately',
                            value: _instantNotifications,
                            onChanged: (value) {
                              setState(() {
                                _instantNotifications = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _digestFrequency,
                            decoration: const InputDecoration(
                              labelText: 'Digest Frequency',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.schedule),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'realtime',
                                child: Text('Real-time'),
                              ),
                              DropdownMenuItem(
                                value: 'hourly',
                                child: Text('Hourly'),
                              ),
                              DropdownMenuItem(
                                value: 'daily',
                                child: Text('Daily'),
                              ),
                              DropdownMenuItem(
                                value: 'weekly',
                                child: Text('Weekly'),
                              ),
                              DropdownMenuItem(
                                value: 'never',
                                child: Text('Never'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _digestFrequency = value ?? 'daily';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Test Notification
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.notifications_active,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Test Notifications',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Send a test notification to verify your settings are working correctly.',
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _testNotification,
                              icon: const Icon(Icons.send),
                              label: const Text('Send Test Notification'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: value
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(value: value, onChanged: onChanged),
      onTap: () => onChanged(!value),
    );
  }
}
