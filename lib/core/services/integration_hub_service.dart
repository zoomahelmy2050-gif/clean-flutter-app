import 'dart:async';
import 'dart:developer' as developer;

class IntegrationConfig {
  final String integrationId;
  final String name;
  final String type;
  final String status;
  final Map<String, dynamic> credentials;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime? lastSyncAt;

  IntegrationConfig({
    required this.integrationId,
    required this.name,
    required this.type,
    required this.status,
    required this.credentials,
    required this.settings,
    required this.createdAt,
    this.lastSyncAt,
  });

  Map<String, dynamic> toJson() => {
    'integration_id': integrationId,
    'name': name,
    'type': type,
    'status': status,
    'credentials': credentials,
    'settings': settings,
    'created_at': createdAt.toIso8601String(),
    'last_sync_at': lastSyncAt?.toIso8601String(),
  };
}

class IntegrationMessage {
  final String messageId;
  final String integrationId;
  final String type;
  final String title;
  final String content;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final String status;

  IntegrationMessage({
    required this.messageId,
    required this.integrationId,
    required this.type,
    required this.title,
    required this.content,
    required this.metadata,
    required this.timestamp,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
    'message_id': messageId,
    'integration_id': integrationId,
    'type': type,
    'title': title,
    'content': content,
    'metadata': metadata,
    'timestamp': timestamp.toIso8601String(),
    'status': status,
  };
}

class IntegrationEvent {
  final String eventId;
  final String integrationId;
  final String eventType;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String severity;

  IntegrationEvent({
    required this.eventId,
    required this.integrationId,
    required this.eventType,
    required this.data,
    required this.timestamp,
    this.severity = 'info',
  });

  Map<String, dynamic> toJson() => {
    'event_id': eventId,
    'integration_id': integrationId,
    'event_type': eventType,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'severity': severity,
  };
}

class IntegrationHubService {
  static final IntegrationHubService _instance = IntegrationHubService._internal();
  factory IntegrationHubService() => _instance;
  IntegrationHubService._internal();

  final Map<String, IntegrationConfig> _integrations = {};
  final List<IntegrationMessage> _messages = [];
  final List<IntegrationEvent> _events = [];
  
  final StreamController<IntegrationMessage> _messageController = StreamController.broadcast();
  final StreamController<IntegrationEvent> _eventController = StreamController.broadcast();
  final StreamController<IntegrationConfig> _integrationController = StreamController.broadcast();

  Stream<IntegrationMessage> get messageStream => _messageController.stream;
  Stream<IntegrationEvent> get eventStream => _eventController.stream;
  Stream<IntegrationConfig> get integrationStream => _integrationController.stream;

  Timer? _syncTimer;

  Future<void> initialize() async {
    await _setupDefaultIntegrations();
    _startPeriodicSync();
    
    developer.log('Integration Hub Service initialized', name: 'IntegrationHubService');
  }

  Future<void> _setupDefaultIntegrations() async {
    // Slack Integration
    await addIntegration(IntegrationConfig(
      integrationId: 'slack_security',
      name: 'Slack Security Alerts',
      type: 'slack',
      status: 'active',
      credentials: {
        'webhook_url': 'https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX',
        'channel': '#security-alerts',
        'bot_token': 'xoxb-xxxxxxxxx-xxxxxxxxx-xxxxxxxxxxxx',
      },
      settings: {
        'alert_types': ['critical', 'high', 'incident'],
        'mention_users': ['@security-team'],
        'include_charts': true,
        'thread_replies': true,
      },
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastSyncAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ));

    // Microsoft Teams Integration
    await addIntegration(IntegrationConfig(
      integrationId: 'teams_security',
      name: 'Teams Security Channel',
      type: 'teams',
      status: 'active',
      credentials: {
        'webhook_url': 'https://outlook.office.com/webhook/xxxxx/IncomingWebhook/xxxxx',
        'tenant_id': 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
        'app_id': 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
      },
      settings: {
        'channel_name': 'Security Operations',
        'alert_types': ['critical', 'high', 'medium'],
        'adaptive_cards': true,
        'mention_team': true,
      },
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      lastSyncAt: DateTime.now().subtract(const Duration(minutes: 3)),
    ));

    // Jira Integration
    await addIntegration(IntegrationConfig(
      integrationId: 'jira_security',
      name: 'Jira Security Project',
      type: 'jira',
      status: 'active',
      credentials: {
        'base_url': 'https://company.atlassian.net',
        'username': 'security@company.com',
        'api_token': 'ATATT3xFfGF0xxxxxxxxxxxxxxxxxxxxx',
        'project_key': 'SEC',
      },
      settings: {
        'issue_type': 'Security Incident',
        'priority_mapping': {
          'critical': 'Highest',
          'high': 'High',
          'medium': 'Medium',
          'low': 'Low',
        },
        'auto_assign': true,
        'default_assignee': 'security-lead',
        'labels': ['security', 'automated'],
      },
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      lastSyncAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ));

    // ServiceNow Integration
    await addIntegration(IntegrationConfig(
      integrationId: 'servicenow_security',
      name: 'ServiceNow ITSM',
      type: 'servicenow',
      status: 'active',
      credentials: {
        'instance_url': 'https://company.service-now.com',
        'username': 'security_integration',
        'password': 'encrypted_password_here',
        'client_id': 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
      },
      settings: {
        'table': 'incident',
        'category': 'Security',
        'subcategory': 'Security Incident',
        'priority_mapping': {
          'critical': '1',
          'high': '2',
          'medium': '3',
          'low': '4',
        },
        'assignment_group': 'Security Operations',
      },
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      lastSyncAt: DateTime.now().subtract(const Duration(minutes: 8)),
    ));

    // PagerDuty Integration
    await addIntegration(IntegrationConfig(
      integrationId: 'pagerduty_security',
      name: 'PagerDuty Security Escalation',
      type: 'pagerduty',
      status: 'active',
      credentials: {
        'integration_key': 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
        'api_token': 'u+xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
        'service_id': 'PXXXXXX',
      },
      settings: {
        'escalation_policy': 'Security Team Escalation',
        'severity_mapping': {
          'critical': 'critical',
          'high': 'error',
          'medium': 'warning',
          'low': 'info',
        },
        'auto_resolve': true,
        'timeout_minutes': 30,
      },
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      lastSyncAt: DateTime.now().subtract(const Duration(minutes: 2)),
    ));

    // Email Integration
    await addIntegration(IntegrationConfig(
      integrationId: 'email_security',
      name: 'Security Email Notifications',
      type: 'email',
      status: 'active',
      credentials: {
        'smtp_server': 'smtp.company.com',
        'smtp_port': '587',
        'username': 'security-alerts@company.com',
        'password': 'encrypted_password_here',
        'use_tls': true,
      },
      settings: {
        'from_address': 'security-alerts@company.com',
        'to_addresses': [
          'security-team@company.com',
          'ciso@company.com',
          'it-ops@company.com',
        ],
        'cc_addresses': ['compliance@company.com'],
        'subject_prefix': '[SECURITY ALERT]',
        'include_attachments': true,
      },
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      lastSyncAt: DateTime.now().subtract(const Duration(minutes: 1)),
    ));
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _syncAllIntegrations();
    });
  }

  Future<void> _syncAllIntegrations() async {
    for (final integration in _integrations.values) {
      if (integration.status == 'active') {
        await _syncIntegration(integration.integrationId);
      }
    }
  }

  Future<void> _syncIntegration(String integrationId) async {
    final integration = _integrations[integrationId];
    if (integration == null) return;

    try {
      switch (integration.type) {
        case 'slack':
          await _syncSlack(integration);
          break;
        case 'teams':
          await _syncTeams(integration);
          break;
        case 'jira':
          await _syncJira(integration);
          break;
        case 'servicenow':
          await _syncServiceNow(integration);
          break;
        case 'pagerduty':
          await _syncPagerDuty(integration);
          break;
        case 'email':
          await _syncEmail(integration);
          break;
      }

      // Update last sync time
      final updatedIntegration = IntegrationConfig(
        integrationId: integration.integrationId,
        name: integration.name,
        type: integration.type,
        status: integration.status,
        credentials: integration.credentials,
        settings: integration.settings,
        createdAt: integration.createdAt,
        lastSyncAt: DateTime.now(),
      );

      _integrations[integrationId] = updatedIntegration;
      _integrationController.add(updatedIntegration);

    } catch (e) {
      developer.log('Sync failed for $integrationId: $e', name: 'IntegrationHubService');
      
      _addEvent(IntegrationEvent(
        eventId: 'EVT_${DateTime.now().millisecondsSinceEpoch}',
        integrationId: integrationId,
        eventType: 'sync_error',
        data: {'error': e.toString()},
        timestamp: DateTime.now(),
        severity: 'error',
      ));
    }
  }

  Future<void> _syncSlack(IntegrationConfig integration) async {
    // Mock Slack sync - in real implementation, use Slack API
    await Future.delayed(const Duration(milliseconds: 100));
    
    _addEvent(IntegrationEvent(
      eventId: 'EVT_${DateTime.now().millisecondsSinceEpoch}',
      integrationId: integration.integrationId,
      eventType: 'sync_completed',
      data: {'messages_sent': 3, 'channels_updated': 1},
      timestamp: DateTime.now(),
      severity: 'info',
    ));
  }

  Future<void> _syncTeams(IntegrationConfig integration) async {
    // Mock Teams sync
    await Future.delayed(const Duration(milliseconds: 150));
    
    _addEvent(IntegrationEvent(
      eventId: 'EVT_${DateTime.now().millisecondsSinceEpoch}',
      integrationId: integration.integrationId,
      eventType: 'sync_completed',
      data: {'adaptive_cards_sent': 2, 'mentions_created': 1},
      timestamp: DateTime.now(),
      severity: 'info',
    ));
  }

  Future<void> _syncJira(IntegrationConfig integration) async {
    // Mock Jira sync
    await Future.delayed(const Duration(milliseconds: 200));
    
    _addEvent(IntegrationEvent(
      eventId: 'EVT_${DateTime.now().millisecondsSinceEpoch}',
      integrationId: integration.integrationId,
      eventType: 'sync_completed',
      data: {'issues_created': 1, 'issues_updated': 2},
      timestamp: DateTime.now(),
      severity: 'info',
    ));
  }

  Future<void> _syncServiceNow(IntegrationConfig integration) async {
    // Mock ServiceNow sync
    await Future.delayed(const Duration(milliseconds: 180));
    
    _addEvent(IntegrationEvent(
      eventId: 'EVT_${DateTime.now().millisecondsSinceEpoch}',
      integrationId: integration.integrationId,
      eventType: 'sync_completed',
      data: {'incidents_created': 1, 'incidents_updated': 3},
      timestamp: DateTime.now(),
      severity: 'info',
    ));
  }

  Future<void> _syncPagerDuty(IntegrationConfig integration) async {
    // Mock PagerDuty sync
    await Future.delayed(const Duration(milliseconds: 120));
    
    _addEvent(IntegrationEvent(
      eventId: 'EVT_${DateTime.now().millisecondsSinceEpoch}',
      integrationId: integration.integrationId,
      eventType: 'sync_completed',
      data: {'alerts_triggered': 0, 'incidents_resolved': 1},
      timestamp: DateTime.now(),
      severity: 'info',
    ));
  }

  Future<void> _syncEmail(IntegrationConfig integration) async {
    // Mock Email sync
    await Future.delayed(const Duration(milliseconds: 80));
    
    _addEvent(IntegrationEvent(
      eventId: 'EVT_${DateTime.now().millisecondsSinceEpoch}',
      integrationId: integration.integrationId,
      eventType: 'sync_completed',
      data: {'emails_sent': 5, 'recipients_notified': 12},
      timestamp: DateTime.now(),
      severity: 'info',
    ));
  }

  Future<IntegrationConfig> addIntegration(IntegrationConfig integration) async {
    _integrations[integration.integrationId] = integration;
    _integrationController.add(integration);
    
    developer.log('Added integration: ${integration.name}', name: 'IntegrationHubService');
    
    return integration;
  }

  Future<void> sendSecurityAlert({
    required String title,
    required String message,
    required String severity,
    Map<String, dynamic>? metadata,
    List<String>? targetIntegrations,
  }) async {
    final targets = targetIntegrations ?? _integrations.keys.toList();
    
    for (final integrationId in targets) {
      final integration = _integrations[integrationId];
      if (integration == null || integration.status != 'active') continue;

      final alertMessage = IntegrationMessage(
        messageId: 'MSG_${DateTime.now().millisecondsSinceEpoch}_$integrationId',
        integrationId: integrationId,
        type: 'security_alert',
        title: title,
        content: message,
        metadata: {
          'severity': severity,
          'timestamp': DateTime.now().toIso8601String(),
          ...?metadata,
        },
        timestamp: DateTime.now(),
      );

      await _sendMessage(alertMessage);
    }
  }

  Future<void> _sendMessage(IntegrationMessage message) async {
    _messages.add(message);
    _messageController.add(message);

    final integration = _integrations[message.integrationId];
    if (integration == null) return;

    try {
      switch (integration.type) {
        case 'slack':
          await _sendSlackMessage(integration, message);
          break;
        case 'teams':
          await _sendTeamsMessage(integration, message);
          break;
        case 'jira':
          await _createJiraIssue(integration, message);
          break;
        case 'servicenow':
          await _createServiceNowIncident(integration, message);
          break;
        case 'pagerduty':
          await _triggerPagerDutyAlert(integration, message);
          break;
        case 'email':
          await _sendEmailNotification(integration, message);
          break;
      }

      // Update message status
      final messageIndex = _messages.indexWhere((m) => m.messageId == message.messageId);
      if (messageIndex != -1) {
        _messages[messageIndex] = IntegrationMessage(
          messageId: message.messageId,
          integrationId: message.integrationId,
          type: message.type,
          title: message.title,
          content: message.content,
          metadata: message.metadata,
          timestamp: message.timestamp,
          status: 'sent',
        );
      }

    } catch (e) {
      developer.log('Failed to send message via ${integration.type}: $e', name: 'IntegrationHubService');
      
      // Update message status to failed
      final messageIndex = _messages.indexWhere((m) => m.messageId == message.messageId);
      if (messageIndex != -1) {
        _messages[messageIndex] = IntegrationMessage(
          messageId: message.messageId,
          integrationId: message.integrationId,
          type: message.type,
          title: message.title,
          content: message.content,
          metadata: message.metadata,
          timestamp: message.timestamp,
          status: 'failed',
        );
      }
    }
  }

  Future<void> _sendSlackMessage(IntegrationConfig integration, IntegrationMessage message) async {
    // Mock Slack message sending
    await Future.delayed(const Duration(milliseconds: 100));
    
    developer.log('Sent Slack message: ${message.title}', name: 'IntegrationHubService');
  }

  Future<void> _sendTeamsMessage(IntegrationConfig integration, IntegrationMessage message) async {
    // Mock Teams message sending
    await Future.delayed(const Duration(milliseconds: 150));
    
    developer.log('Sent Teams message: ${message.title}', name: 'IntegrationHubService');
  }

  Future<void> _createJiraIssue(IntegrationConfig integration, IntegrationMessage message) async {
    // Mock Jira issue creation
    await Future.delayed(const Duration(milliseconds: 200));
    
    developer.log('Created Jira issue: ${message.title}', name: 'IntegrationHubService');
  }

  Future<void> _createServiceNowIncident(IntegrationConfig integration, IntegrationMessage message) async {
    // Mock ServiceNow incident creation
    await Future.delayed(const Duration(milliseconds: 180));
    
    developer.log('Created ServiceNow incident: ${message.title}', name: 'IntegrationHubService');
  }

  Future<void> _triggerPagerDutyAlert(IntegrationConfig integration, IntegrationMessage message) async {
    // Mock PagerDuty alert triggering
    await Future.delayed(const Duration(milliseconds: 120));
    
    developer.log('Triggered PagerDuty alert: ${message.title}', name: 'IntegrationHubService');
  }

  Future<void> _sendEmailNotification(IntegrationConfig integration, IntegrationMessage message) async {
    // Mock email sending
    await Future.delayed(const Duration(milliseconds: 80));
    
    developer.log('Sent email notification: ${message.title}', name: 'IntegrationHubService');
  }

  Future<void> createIncidentTicket({
    required String title,
    required String description,
    required String severity,
    String? assignee,
    Map<String, dynamic>? customFields,
  }) async {
    // Create tickets in all configured ticketing systems
    final ticketingSystems = _integrations.values.where(
      (i) => ['jira', 'servicenow'].contains(i.type) && i.status == 'active'
    );

    for (final integration in ticketingSystems) {
      final ticketMessage = IntegrationMessage(
        messageId: 'TKT_${DateTime.now().millisecondsSinceEpoch}_${integration.integrationId}',
        integrationId: integration.integrationId,
        type: 'incident_ticket',
        title: title,
        content: description,
        metadata: {
          'severity': severity,
          'assignee': assignee,
          'custom_fields': customFields ?? {},
          'created_by': 'security_system',
        },
        timestamp: DateTime.now(),
      );

      await _sendMessage(ticketMessage);
    }
  }

  void _addEvent(IntegrationEvent event) {
    _events.add(event);
    _eventController.add(event);
    
    // Keep only last 1000 events
    if (_events.length > 1000) {
      _events.removeAt(0);
    }
  }

  Future<List<IntegrationConfig>> getIntegrations() async {
    return _integrations.values.toList();
  }

  Future<IntegrationConfig?> getIntegration(String integrationId) async {
    return _integrations[integrationId];
  }

  Future<List<IntegrationMessage>> getMessages({
    String? integrationId,
    String? type,
    int? limit,
  }) async {
    var messages = List<IntegrationMessage>.from(_messages);
    
    if (integrationId != null) {
      messages = messages.where((m) => m.integrationId == integrationId).toList();
    }
    
    if (type != null) {
      messages = messages.where((m) => m.type == type).toList();
    }
    
    messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    if (limit != null && limit > 0) {
      messages = messages.take(limit).toList();
    }
    
    return messages;
  }

  Future<List<IntegrationEvent>> getEvents({
    String? integrationId,
    String? eventType,
    int? limit,
  }) async {
    var events = List<IntegrationEvent>.from(_events);
    
    if (integrationId != null) {
      events = events.where((e) => e.integrationId == integrationId).toList();
    }
    
    if (eventType != null) {
      events = events.where((e) => e.eventType == eventType).toList();
    }
    
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    if (limit != null && limit > 0) {
      events = events.take(limit).toList();
    }
    
    return events;
  }

  Map<String, dynamic> getIntegrationMetrics() {
    final activeIntegrations = _integrations.values.where((i) => i.status == 'active').length;
    final totalMessages = _messages.length;
    final successfulMessages = _messages.where((m) => m.status == 'sent').length;
    final failedMessages = _messages.where((m) => m.status == 'failed').length;
    
    final integrationTypes = <String, int>{};
    for (final integration in _integrations.values) {
      integrationTypes[integration.type] = (integrationTypes[integration.type] ?? 0) + 1;
    }
    
    return {
      'total_integrations': _integrations.length,
      'active_integrations': activeIntegrations,
      'integration_types': integrationTypes,
      'total_messages': totalMessages,
      'successful_messages': successfulMessages,
      'failed_messages': failedMessages,
      'success_rate': totalMessages > 0 ? (successfulMessages / totalMessages) * 100 : 0,
      'total_events': _events.length,
    };
  }

  void dispose() {
    _syncTimer?.cancel();
    _messageController.close();
    _eventController.close();
    _integrationController.close();
  }
}
