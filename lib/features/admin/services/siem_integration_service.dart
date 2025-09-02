import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:developer' as developer;
import '../../../core/models/siem_integration_models.dart';

class SIEMIntegrationService {
  static final SIEMIntegrationService _instance = SIEMIntegrationService._internal();
  factory SIEMIntegrationService() => _instance;
  SIEMIntegrationService._internal();

  final StreamController<List<SIEMConnection>> _connectionsController = StreamController<List<SIEMConnection>>.broadcast();
  final StreamController<List<AutomatedPlaybook>> _playbooksController = StreamController<List<AutomatedPlaybook>>.broadcast();
  final StreamController<List<PlaybookExecution>> _executionsController = StreamController<List<PlaybookExecution>>.broadcast();
  final StreamController<List<SIEMDataSync>> _syncHistoryController = StreamController<List<SIEMDataSync>>.broadcast();
  final StreamController<List<SIEMAlert>> _siemAlertsController = StreamController<List<SIEMAlert>>.broadcast();
  final StreamController<List<SIEMQuery>> _queriesController = StreamController<List<SIEMQuery>>.broadcast();

  Stream<List<SIEMConnection>> get connectionsStream => _connectionsController.stream;
  Stream<List<AutomatedPlaybook>> get playbooksStream => _playbooksController.stream;
  Stream<List<PlaybookExecution>> get executionsStream => _executionsController.stream;
  Stream<List<SIEMDataSync>> get syncHistoryStream => _syncHistoryController.stream;
  Stream<List<SIEMAlert>> get siemAlertsStream => _siemAlertsController.stream;
  Stream<List<SIEMQuery>> get queriesStream => _queriesController.stream;

  final List<SIEMConnection> _connections = [];
  final List<AutomatedPlaybook> _playbooks = [];
  final List<PlaybookExecution> _executions = [];
  final List<SIEMDataSync> _syncHistory = [];
  final List<SIEMAlert> _siemAlerts = [];
  final List<SIEMQuery> _queries = [];

  final Random _random = Random();
  Timer? _dataUpdateTimer;

  Future<void> initialize() async {
    developer.log('Initializing SIEM Integration Service', name: 'SIEMIntegrationService');
    
    _generateMockConnections();
    _generateMockPlaybooks();
    _generateMockExecutions();
    _generateMockSyncHistory();
    _generateMockSIEMAlerts();
    _generateMockQueries();
    
    _startDataUpdates();
    
    developer.log('SIEM Integration Service initialized', name: 'SIEMIntegrationService');
  }

  void _startDataUpdates() {
    _dataUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateRealTimeData();
    });
  }

  void _updateRealTimeData() {
    // Update connection statuses
    for (int i = 0; i < _connections.length; i++) {
      if (_random.nextDouble() < 0.1) {
        final connection = _connections[i];
        final newStatus = _random.nextBool() ? IntegrationStatus.connected : IntegrationStatus.syncing;
        _connections[i] = SIEMConnection(
          id: connection.id,
          name: connection.name,
          platform: connection.platform,
          endpoint: connection.endpoint,
          credentials: connection.credentials,
          status: newStatus,
          createdAt: connection.createdAt,
          lastConnected: DateTime.now(),
          lastSynced: newStatus == IntegrationStatus.syncing ? DateTime.now() : connection.lastSynced,
          configuration: connection.configuration,
          enabledDataSources: connection.enabledDataSources,
          isActive: connection.isActive,
          errorMessage: connection.errorMessage,
        );
      }
    }

    // Add new SIEM alerts
    if (_random.nextDouble() < 0.3) {
      _siemAlerts.add(_generateRandomSIEMAlert());
    }

    // Add new sync operations
    if (_random.nextDouble() < 0.2) {
      _syncHistory.add(_generateRandomSyncOperation());
    }

    // Update streams
    _connectionsController.add(List.from(_connections));
    _siemAlertsController.add(List.from(_siemAlerts));
    _syncHistoryController.add(List.from(_syncHistory));
  }

  void _generateMockConnections() {
    final platforms = SIEMPlatform.values;
    final statuses = [IntegrationStatus.connected, IntegrationStatus.disconnected, IntegrationStatus.syncing];
    
    for (int i = 0; i < 5; i++) {
      final platform = platforms[_random.nextInt(platforms.length)];
      final status = statuses[_random.nextInt(statuses.length)];
      
      _connections.add(SIEMConnection(
        id: 'conn_${i + 1}',
        name: '${platform.name.toUpperCase()} Production',
        platform: platform,
        endpoint: _getEndpointForPlatform(platform),
        credentials: {
          'username': 'admin',
          'token': 'encrypted_token_${i + 1}',
        },
        status: status,
        createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
        lastConnected: status == IntegrationStatus.connected ? DateTime.now().subtract(Duration(minutes: _random.nextInt(60))) : null,
        lastSynced: DateTime.now().subtract(Duration(hours: _random.nextInt(24))),
        configuration: {
          'timeout': 30000,
          'retryAttempts': 3,
          'batchSize': 1000,
        },
        enabledDataSources: _getRandomDataSources(),
        isActive: _random.nextBool(),
      ));
    }
    
    _connectionsController.add(List.from(_connections));
  }

  void _generateMockPlaybooks() {
    final playbookTemplates = [
      {
        'name': 'Malware Detection Response',
        'description': 'Automated response to malware detection alerts',
        'triggers': ['malware_detected', 'suspicious_file'],
        'actions': [
          {'type': 'isolate_endpoint', 'name': 'Isolate Infected Endpoint'},
          {'type': 'collect_artifacts', 'name': 'Collect Forensic Artifacts'},
          {'type': 'notify_team', 'name': 'Notify Security Team'},
          {'type': 'create_ticket', 'name': 'Create Incident Ticket'},
        ],
      },
      {
        'name': 'Phishing Email Response',
        'description': 'Automated response to phishing email detection',
        'triggers': ['phishing_email', 'suspicious_attachment'],
        'actions': [
          {'type': 'block_sender', 'name': 'Block Sender Domain'},
          {'type': 'quarantine_emails', 'name': 'Quarantine Similar Emails'},
          {'type': 'notify_users', 'name': 'Notify Affected Users'},
          {'type': 'update_filters', 'name': 'Update Email Filters'},
        ],
      },
      {
        'name': 'Brute Force Attack Response',
        'description': 'Automated response to brute force login attempts',
        'triggers': ['brute_force_detected', 'multiple_failed_logins'],
        'actions': [
          {'type': 'block_ip', 'name': 'Block Source IP'},
          {'type': 'lock_account', 'name': 'Lock Target Account'},
          {'type': 'notify_user', 'name': 'Notify Account Owner'},
          {'type': 'escalate_incident', 'name': 'Escalate to SOC'},
        ],
      },
      {
        'name': 'Data Exfiltration Response',
        'description': 'Automated response to data exfiltration attempts',
        'triggers': ['data_exfiltration', 'unusual_data_transfer'],
        'actions': [
          {'type': 'block_network', 'name': 'Block Network Traffic'},
          {'type': 'preserve_evidence', 'name': 'Preserve Digital Evidence'},
          {'type': 'notify_legal', 'name': 'Notify Legal Team'},
          {'type': 'create_forensic_image', 'name': 'Create Forensic Image'},
        ],
      },
    ];

    for (int i = 0; i < playbookTemplates.length; i++) {
      final template = playbookTemplates[i];
      final actions = (template['actions'] as List).map((actionData) {
        return PlaybookAction(
          id: 'action_${i}_${actionData['type']}',
          type: actionData['type'],
          name: actionData['name'],
          parameters: {
            'timeout': 300,
            'retryCount': 3,
          },
          order: (template['actions'] as List).indexOf(actionData),
        );
      }).toList();

      _playbooks.add(AutomatedPlaybook(
        id: 'playbook_${i + 1}',
        name: template['name'] as String,
        description: template['description'] as String,
        triggers: List<String>.from(template['triggers'] as List),
        actions: actions,
        conditions: {
          'severity': 'high',
          'confidence': 0.8,
        },
        isEnabled: _random.nextBool(),
        createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(60))),
        lastModified: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
        createdBy: 'admin@company.com',
        executionCount: _random.nextInt(50),
        lastExecuted: DateTime.now().subtract(Duration(hours: _random.nextInt(48))),
        successRate: 0.7 + (_random.nextDouble() * 0.3),
        tags: ['automated', 'incident-response', template['name'].toString().split(' ').first.toLowerCase()],
      ));
    }
    
    _playbooksController.add(List.from(_playbooks));
  }

  void _generateMockExecutions() {
    final statuses = ['running', 'completed', 'failed', 'cancelled'];
    
    for (int i = 0; i < 10; i++) {
      final playbook = _playbooks[_random.nextInt(_playbooks.length)];
      final status = statuses[_random.nextInt(statuses.length)];
      final startedAt = DateTime.now().subtract(Duration(minutes: _random.nextInt(120)));
      
      final actionExecutions = playbook.actions.map((action) {
        final actionStatus = status == 'running' && action.order == 0 ? 'running' : 
                           status == 'failed' && action.order == 1 ? 'failed' : 'completed';
        
        return ActionExecution(
          id: 'exec_${i}_${action.id}',
          actionId: action.id,
          actionType: action.type,
          startedAt: startedAt.add(Duration(seconds: action.order * 30)),
          completedAt: actionStatus == 'running' ? null : startedAt.add(Duration(seconds: (action.order + 1) * 30)),
          status: actionStatus,
          input: action.parameters,
          output: actionStatus == 'completed' ? {'result': 'success', 'details': 'Action completed successfully'} : {},
          errorMessage: actionStatus == 'failed' ? 'Action failed due to timeout' : null,
          executionTime: actionStatus != 'running' ? Duration(seconds: 30) : null,
        );
      }).toList();

      _executions.add(PlaybookExecution(
        id: 'execution_${i + 1}',
        playbookId: playbook.id,
        triggeredBy: 'alert_${i + 1}',
        startedAt: startedAt,
        completedAt: status == 'running' ? null : startedAt.add(Duration(minutes: 5)),
        status: status,
        actionExecutions: actionExecutions,
        context: {
          'alertId': 'alert_${i + 1}',
          'severity': 'high',
          'sourceIp': '192.168.1.${_random.nextInt(255)}',
        },
        errorMessage: status == 'failed' ? 'Playbook execution failed at step 2' : null,
        results: status == 'completed' ? {
          'actionsExecuted': actionExecutions.length,
          'successfulActions': actionExecutions.where((a) => a.status == 'completed').length,
          'totalTime': '5 minutes',
        } : {},
      ));
    }
    
    _executionsController.add(List.from(_executions));
  }

  void _generateMockSyncHistory() {
    final dataTypes = DataSourceType.values;
    final directions = SyncDirection.values;
    final statuses = ['completed', 'running', 'failed'];
    
    for (int i = 0; i < 15; i++) {
      _syncHistory.add(_generateRandomSyncOperation());
    }
    
    _syncHistoryController.add(List.from(_syncHistory));
  }

  SIEMDataSync _generateRandomSyncOperation() {
    final connection = _connections[_random.nextInt(_connections.length)];
    final dataType = DataSourceType.values[_random.nextInt(DataSourceType.values.length)];
    final direction = SyncDirection.values[_random.nextInt(SyncDirection.values.length)];
    final status = ['completed', 'running', 'failed'][_random.nextInt(3)];
    final startedAt = DateTime.now().subtract(Duration(minutes: _random.nextInt(1440)));
    
    final recordsProcessed = _random.nextInt(10000);
    final recordsSuccessful = status == 'completed' ? recordsProcessed : _random.nextInt(recordsProcessed);
    final recordsFailed = recordsProcessed - recordsSuccessful;
    
    return SIEMDataSync(
      id: 'sync_${DateTime.now().millisecondsSinceEpoch}',
      connectionId: connection.id,
      dataType: dataType,
      direction: direction,
      startedAt: startedAt,
      completedAt: status == 'running' ? null : startedAt.add(Duration(minutes: _random.nextInt(60))),
      status: status,
      recordsProcessed: recordsProcessed,
      recordsSuccessful: recordsSuccessful,
      recordsFailed: recordsFailed,
      filters: {
        'timeRange': '24h',
        'severity': 'medium,high,critical',
      },
      errorMessage: status == 'failed' ? 'Connection timeout during sync' : null,
      statistics: {
        'throughput': '${_random.nextInt(1000)} records/min',
        'dataSize': '${_random.nextInt(500)} MB',
      },
    );
  }

  void _generateMockSIEMAlerts() {
    final severities = ['low', 'medium', 'high', 'critical'];
    final statuses = ['new', 'investigating', 'resolved', 'false_positive'];
    
    for (int i = 0; i < 20; i++) {
      _siemAlerts.add(_generateRandomSIEMAlert());
    }
    
    _siemAlertsController.add(List.from(_siemAlerts));
  }

  SIEMAlert _generateRandomSIEMAlert() {
    final connection = _connections[_random.nextInt(_connections.length)];
    final severity = ['low', 'medium', 'high', 'critical'][_random.nextInt(4)];
    final status = ['new', 'investigating', 'resolved', 'false_positive'][_random.nextInt(4)];
    
    final alertTypes = [
      'Malware Detection',
      'Suspicious Network Activity',
      'Failed Login Attempts',
      'Data Exfiltration',
      'Privilege Escalation',
      'Phishing Email',
      'DDoS Attack',
      'Insider Threat',
    ];
    
    final alertType = alertTypes[_random.nextInt(alertTypes.length)];
    
    return SIEMAlert(
      id: 'alert_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
      sourceId: connection.id,
      title: alertType,
      description: 'Detected $alertType from ${connection.platform.name}',
      severity: severity,
      createdAt: DateTime.now().subtract(Duration(minutes: _random.nextInt(1440))),
      rawData: {
        'sourceIp': '192.168.1.${_random.nextInt(255)}',
        'destinationIp': '10.0.0.${_random.nextInt(255)}',
        'protocol': ['TCP', 'UDP', 'HTTP', 'HTTPS'][_random.nextInt(4)],
        'port': _random.nextInt(65535),
      },
      indicators: [
        '192.168.1.${_random.nextInt(255)}',
        'suspicious_file.exe',
        'malicious_domain.com',
      ],
      enrichment: {
        'geoLocation': 'US',
        'reputation': 'malicious',
        'confidence': _random.nextDouble(),
      },
      status: status,
      assignedTo: status != 'new' ? 'analyst@company.com' : null,
      tags: ['automated', severity, alertType.toLowerCase().replaceAll(' ', '_')],
    );
  }

  void _generateMockQueries() {
    final platforms = SIEMPlatform.values;
    
    final queryTemplates = [
      {
        'name': 'Failed Login Analysis',
        'query': 'index=security sourcetype=auth action=failure | stats count by user, src_ip | where count > 5',
        'platform': SIEMPlatform.splunk,
      },
      {
        'name': 'Network Anomaly Detection',
        'query': 'SELECT * FROM flows WHERE bytes_out > 1000000 AND protocol = "TCP"',
        'platform': SIEMPlatform.qradar,
      },
      {
        'name': 'Malware Indicators',
        'query': 'event.category:malware AND event.outcome:success',
        'platform': SIEMPlatform.elastic_security,
      },
      {
        'name': 'Privilege Escalation Hunt',
        'query': 'SecurityEvent | where EventID == 4672 | summarize count() by Account',
        'platform': SIEMPlatform.sentinel,
      },
    ];

    for (int i = 0; i < queryTemplates.length; i++) {
      final template = queryTemplates[i];
      
      _queries.add(SIEMQuery(
        id: 'query_${i + 1}',
        name: template['name'] as String,
        query: template['query'] as String,
        targetPlatform: template['platform'] as SIEMPlatform,
        parameters: {
          'timeRange': '24h',
          'maxResults': 1000,
        },
        createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
        createdBy: 'analyst@company.com',
        isScheduled: _random.nextBool(),
        schedule: _random.nextBool() ? '0 */6 * * *' : null,
        lastExecuted: DateTime.now().subtract(Duration(hours: _random.nextInt(24))),
        executionCount: _random.nextInt(100),
      ));
    }
    
    _queriesController.add(List.from(_queries));
  }

  String _getEndpointForPlatform(SIEMPlatform platform) {
    switch (platform) {
      case SIEMPlatform.splunk:
        return 'https://splunk.company.com:8089';
      case SIEMPlatform.qradar:
        return 'https://qradar.company.com/api';
      case SIEMPlatform.elastic_security:
        return 'https://elastic.company.com:9200';
      case SIEMPlatform.sentinel:
        return 'https://management.azure.com/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.OperationalInsights/workspaces/xxx';
      case SIEMPlatform.sumo_logic:
        return 'https://api.sumologic.com/api/v1';
      case SIEMPlatform.chronicle:
        return 'https://chronicle.googleapis.com/v1';
    }
  }

  List<String> _getRandomDataSources() {
    final allSources = DataSourceType.values.map((e) => e.name).toList();
    final count = 1 + _random.nextInt(allSources.length);
    allSources.shuffle(_random);
    return allSources.take(count).toList();
  }

  // API Methods
  Future<SIEMConnection> createConnection(SIEMConnection connection) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _connections.add(connection);
    _connectionsController.add(List.from(_connections));
    return connection;
  }

  Future<void> testConnection(String connectionId) async {
    await Future.delayed(const Duration(seconds: 2));
    final index = _connections.indexWhere((c) => c.id == connectionId);
    if (index != -1) {
      final connection = _connections[index];
      _connections[index] = SIEMConnection(
        id: connection.id,
        name: connection.name,
        platform: connection.platform,
        endpoint: connection.endpoint,
        credentials: connection.credentials,
        status: _random.nextBool() ? IntegrationStatus.connected : IntegrationStatus.error,
        createdAt: connection.createdAt,
        lastConnected: DateTime.now(),
        lastSynced: connection.lastSynced,
        configuration: connection.configuration,
        enabledDataSources: connection.enabledDataSources,
        isActive: connection.isActive,
        errorMessage: _random.nextBool() ? null : 'Authentication failed',
      );
      _connectionsController.add(List.from(_connections));
    }
  }

  Future<AutomatedPlaybook> createPlaybook(AutomatedPlaybook playbook) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _playbooks.add(playbook);
    _playbooksController.add(List.from(_playbooks));
    return playbook;
  }

  Future<PlaybookExecution> executePlaybook(String playbookId, Map<String, dynamic> context) async {
    await Future.delayed(const Duration(seconds: 1));
    
    final playbook = _playbooks.firstWhere((p) => p.id == playbookId);
    final execution = PlaybookExecution(
      id: 'exec_${DateTime.now().millisecondsSinceEpoch}',
      playbookId: playbookId,
      triggeredBy: 'manual',
      startedAt: DateTime.now(),
      status: 'running',
      context: context,
    );
    
    _executions.add(execution);
    _executionsController.add(List.from(_executions));
    
    return execution;
  }

  Future<SIEMDataSync> startDataSync(String connectionId, DataSourceType dataType, SyncDirection direction) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final sync = SIEMDataSync(
      id: 'sync_${DateTime.now().millisecondsSinceEpoch}',
      connectionId: connectionId,
      dataType: dataType,
      direction: direction,
      startedAt: DateTime.now(),
      status: 'running',
    );
    
    _syncHistory.add(sync);
    _syncHistoryController.add(List.from(_syncHistory));
    
    return sync;
  }

  Future<List<SIEMAlert>> executeQuery(String queryId) async {
    await Future.delayed(const Duration(seconds: 2));
    
    // Generate mock results
    final results = <SIEMAlert>[];
    for (int i = 0; i < _random.nextInt(10); i++) {
      results.add(_generateRandomSIEMAlert());
    }
    
    return results;
  }

  List<SIEMConnection> getConnections() => List.from(_connections);
  List<AutomatedPlaybook> getPlaybooks() => List.from(_playbooks);
  List<PlaybookExecution> getExecutions() => List.from(_executions);
  List<SIEMDataSync> getSyncHistory() => List.from(_syncHistory);
  List<SIEMAlert> getSIEMAlerts() => List.from(_siemAlerts);
  List<SIEMQuery> getQueries() => List.from(_queries);

  void dispose() {
    _dataUpdateTimer?.cancel();
    _connectionsController.close();
    _playbooksController.close();
    _executionsController.close();
    _syncHistoryController.close();
    _siemAlertsController.close();
    _queriesController.close();
  }
}
