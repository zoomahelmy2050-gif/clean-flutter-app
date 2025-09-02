enum SIEMPlatform { splunk, qradar, elastic_security, sentinel, sumo_logic, chronicle }
enum IntegrationStatus { connected, disconnected, error, authenticating, syncing }
enum DataSourceType { logs, events, alerts, metrics, network_flows, vulnerabilities }
enum SyncDirection { inbound, outbound, bidirectional }

class SIEMConnection {
  final String id;
  final String name;
  final SIEMPlatform platform;
  final String endpoint;
  final Map<String, String> credentials;
  final IntegrationStatus status;
  final DateTime createdAt;
  final DateTime? lastConnected;
  final DateTime? lastSynced;
  final Map<String, dynamic> configuration;
  final List<String> enabledDataSources;
  final bool isActive;
  final String? errorMessage;

  SIEMConnection({
    required this.id,
    required this.name,
    required this.platform,
    required this.endpoint,
    this.credentials = const {},
    required this.status,
    required this.createdAt,
    this.lastConnected,
    this.lastSynced,
    this.configuration = const {},
    this.enabledDataSources = const [],
    this.isActive = true,
    this.errorMessage,
  });

  factory SIEMConnection.fromJson(Map<String, dynamic> json) {
    return SIEMConnection(
      id: json['id'],
      name: json['name'],
      platform: SIEMPlatform.values.byName(json['platform']),
      endpoint: json['endpoint'],
      credentials: Map<String, String>.from(json['credentials'] ?? {}),
      status: IntegrationStatus.values.byName(json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      lastConnected: json['lastConnected'] != null ? DateTime.parse(json['lastConnected']) : null,
      lastSynced: json['lastSynced'] != null ? DateTime.parse(json['lastSynced']) : null,
      configuration: json['configuration'] ?? {},
      enabledDataSources: List<String>.from(json['enabledDataSources'] ?? []),
      isActive: json['isActive'] ?? true,
      errorMessage: json['errorMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'platform': platform.name,
      'endpoint': endpoint,
      'credentials': credentials,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'lastConnected': lastConnected?.toIso8601String(),
      'lastSynced': lastSynced?.toIso8601String(),
      'configuration': configuration,
      'enabledDataSources': enabledDataSources,
      'isActive': isActive,
      'errorMessage': errorMessage,
    };
  }
}

class AutomatedPlaybook {
  final String id;
  final String name;
  final String description;
  final List<String> triggers;
  final List<PlaybookAction> actions;
  final Map<String, dynamic> conditions;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime lastModified;
  final String createdBy;
  final int executionCount;
  final DateTime? lastExecuted;
  final double successRate;
  final List<String> tags;

  AutomatedPlaybook({
    required this.id,
    required this.name,
    required this.description,
    this.triggers = const [],
    this.actions = const [],
    this.conditions = const {},
    this.isEnabled = true,
    required this.createdAt,
    required this.lastModified,
    required this.createdBy,
    this.executionCount = 0,
    this.lastExecuted,
    this.successRate = 0.0,
    this.tags = const [],
  });

  factory AutomatedPlaybook.fromJson(Map<String, dynamic> json) {
    return AutomatedPlaybook(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      triggers: List<String>.from(json['triggers'] ?? []),
      actions: (json['actions'] as List?)?.map((e) => PlaybookAction.fromJson(e)).toList() ?? [],
      conditions: json['conditions'] ?? {},
      isEnabled: json['isEnabled'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      lastModified: DateTime.parse(json['lastModified']),
      createdBy: json['createdBy'],
      executionCount: json['executionCount'] ?? 0,
      lastExecuted: json['lastExecuted'] != null ? DateTime.parse(json['lastExecuted']) : null,
      successRate: json['successRate']?.toDouble() ?? 0.0,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'triggers': triggers,
      'actions': actions.map((e) => e.toJson()).toList(),
      'conditions': conditions,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'createdBy': createdBy,
      'executionCount': executionCount,
      'lastExecuted': lastExecuted?.toIso8601String(),
      'successRate': successRate,
      'tags': tags,
    };
  }
}

class PlaybookAction {
  final String id;
  final String type;
  final String name;
  final Map<String, dynamic> parameters;
  final int order;
  final bool isRequired;
  final Duration? timeout;
  final List<String> dependencies;
  final Map<String, dynamic> conditions;

  PlaybookAction({
    required this.id,
    required this.type,
    required this.name,
    this.parameters = const {},
    required this.order,
    this.isRequired = true,
    this.timeout,
    this.dependencies = const [],
    this.conditions = const {},
  });

  factory PlaybookAction.fromJson(Map<String, dynamic> json) {
    return PlaybookAction(
      id: json['id'],
      type: json['type'],
      name: json['name'],
      parameters: json['parameters'] ?? {},
      order: json['order'],
      isRequired: json['isRequired'] ?? true,
      timeout: json['timeout'] != null ? Duration(seconds: json['timeout']) : null,
      dependencies: List<String>.from(json['dependencies'] ?? []),
      conditions: json['conditions'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'parameters': parameters,
      'order': order,
      'isRequired': isRequired,
      'timeout': timeout?.inSeconds,
      'dependencies': dependencies,
      'conditions': conditions,
    };
  }
}

class PlaybookExecution {
  final String id;
  final String playbookId;
  final String triggeredBy;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String status;
  final List<ActionExecution> actionExecutions;
  final Map<String, dynamic> context;
  final String? errorMessage;
  final Map<String, dynamic> results;

  PlaybookExecution({
    required this.id,
    required this.playbookId,
    required this.triggeredBy,
    required this.startedAt,
    this.completedAt,
    required this.status,
    this.actionExecutions = const [],
    this.context = const {},
    this.errorMessage,
    this.results = const {},
  });

  factory PlaybookExecution.fromJson(Map<String, dynamic> json) {
    return PlaybookExecution(
      id: json['id'],
      playbookId: json['playbookId'],
      triggeredBy: json['triggeredBy'],
      startedAt: DateTime.parse(json['startedAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      status: json['status'],
      actionExecutions: (json['actionExecutions'] as List?)?.map((e) => ActionExecution.fromJson(e)).toList() ?? [],
      context: json['context'] ?? {},
      errorMessage: json['errorMessage'],
      results: json['results'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playbookId': playbookId,
      'triggeredBy': triggeredBy,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'status': status,
      'actionExecutions': actionExecutions.map((e) => e.toJson()).toList(),
      'context': context,
      'errorMessage': errorMessage,
      'results': results,
    };
  }
}

class ActionExecution {
  final String id;
  final String actionId;
  final String actionType;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String status;
  final Map<String, dynamic> input;
  final Map<String, dynamic> output;
  final String? errorMessage;
  final Duration? executionTime;

  ActionExecution({
    required this.id,
    required this.actionId,
    required this.actionType,
    required this.startedAt,
    this.completedAt,
    required this.status,
    this.input = const {},
    this.output = const {},
    this.errorMessage,
    this.executionTime,
  });

  factory ActionExecution.fromJson(Map<String, dynamic> json) {
    return ActionExecution(
      id: json['id'],
      actionId: json['actionId'],
      actionType: json['actionType'],
      startedAt: DateTime.parse(json['startedAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      status: json['status'],
      input: json['input'] ?? {},
      output: json['output'] ?? {},
      errorMessage: json['errorMessage'],
      executionTime: json['executionTime'] != null ? Duration(milliseconds: json['executionTime']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actionId': actionId,
      'actionType': actionType,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'status': status,
      'input': input,
      'output': output,
      'errorMessage': errorMessage,
      'executionTime': executionTime?.inMilliseconds,
    };
  }
}

class SIEMDataSync {
  final String id;
  final String connectionId;
  final DataSourceType dataType;
  final SyncDirection direction;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String status;
  final int recordsProcessed;
  final int recordsSuccessful;
  final int recordsFailed;
  final Map<String, dynamic> filters;
  final String? errorMessage;
  final Map<String, dynamic> statistics;

  SIEMDataSync({
    required this.id,
    required this.connectionId,
    required this.dataType,
    required this.direction,
    required this.startedAt,
    this.completedAt,
    required this.status,
    this.recordsProcessed = 0,
    this.recordsSuccessful = 0,
    this.recordsFailed = 0,
    this.filters = const {},
    this.errorMessage,
    this.statistics = const {},
  });

  factory SIEMDataSync.fromJson(Map<String, dynamic> json) {
    return SIEMDataSync(
      id: json['id'],
      connectionId: json['connectionId'],
      dataType: DataSourceType.values.byName(json['dataType']),
      direction: SyncDirection.values.byName(json['direction']),
      startedAt: DateTime.parse(json['startedAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      status: json['status'],
      recordsProcessed: json['recordsProcessed'] ?? 0,
      recordsSuccessful: json['recordsSuccessful'] ?? 0,
      recordsFailed: json['recordsFailed'] ?? 0,
      filters: json['filters'] ?? {},
      errorMessage: json['errorMessage'],
      statistics: json['statistics'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'connectionId': connectionId,
      'dataType': dataType.name,
      'direction': direction.name,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'status': status,
      'recordsProcessed': recordsProcessed,
      'recordsSuccessful': recordsSuccessful,
      'recordsFailed': recordsFailed,
      'filters': filters,
      'errorMessage': errorMessage,
      'statistics': statistics,
    };
  }
}

class SIEMAlert {
  final String id;
  final String sourceId;
  final String title;
  final String description;
  final String severity;
  final DateTime createdAt;
  final Map<String, dynamic> rawData;
  final List<String> indicators;
  final Map<String, dynamic> enrichment;
  final String status;
  final String? assignedTo;
  final List<String> tags;

  SIEMAlert({
    required this.id,
    required this.sourceId,
    required this.title,
    required this.description,
    required this.severity,
    required this.createdAt,
    this.rawData = const {},
    this.indicators = const [],
    this.enrichment = const {},
    required this.status,
    this.assignedTo,
    this.tags = const [],
  });

  factory SIEMAlert.fromJson(Map<String, dynamic> json) {
    return SIEMAlert(
      id: json['id'],
      sourceId: json['sourceId'],
      title: json['title'],
      description: json['description'],
      severity: json['severity'],
      createdAt: DateTime.parse(json['createdAt']),
      rawData: json['rawData'] ?? {},
      indicators: List<String>.from(json['indicators'] ?? []),
      enrichment: json['enrichment'] ?? {},
      status: json['status'],
      assignedTo: json['assignedTo'],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceId': sourceId,
      'title': title,
      'description': description,
      'severity': severity,
      'createdAt': createdAt.toIso8601String(),
      'rawData': rawData,
      'indicators': indicators,
      'enrichment': enrichment,
      'status': status,
      'assignedTo': assignedTo,
      'tags': tags,
    };
  }
}

class SIEMQuery {
  final String id;
  final String name;
  final String query;
  final SIEMPlatform targetPlatform;
  final Map<String, dynamic> parameters;
  final DateTime createdAt;
  final String createdBy;
  final bool isScheduled;
  final String? schedule;
  final DateTime? lastExecuted;
  final int executionCount;

  SIEMQuery({
    required this.id,
    required this.name,
    required this.query,
    required this.targetPlatform,
    this.parameters = const {},
    required this.createdAt,
    required this.createdBy,
    this.isScheduled = false,
    this.schedule,
    this.lastExecuted,
    this.executionCount = 0,
  });

  factory SIEMQuery.fromJson(Map<String, dynamic> json) {
    return SIEMQuery(
      id: json['id'],
      name: json['name'],
      query: json['query'],
      targetPlatform: SIEMPlatform.values.byName(json['targetPlatform']),
      parameters: json['parameters'] ?? {},
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: json['createdBy'],
      isScheduled: json['isScheduled'] ?? false,
      schedule: json['schedule'],
      lastExecuted: json['lastExecuted'] != null ? DateTime.parse(json['lastExecuted']) : null,
      executionCount: json['executionCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'query': query,
      'targetPlatform': targetPlatform.name,
      'parameters': parameters,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'isScheduled': isScheduled,
      'schedule': schedule,
      'lastExecuted': lastExecuted?.toIso8601String(),
      'executionCount': executionCount,
    };
  }
}
