enum ConflictType {
  duplicateContent,
  modifiedContent,
  deletedContent,
  nameConflict,
  locationConflict,
  permissionConflict,
  metadataConflict,
  versionConflict,
  dataModified,
  dataDeleted,
  dataCreated,
  versionMismatch,
  schemaConflict,
}

enum ResolutionAction {
  useLocal,
  useRemote,
  merge,
  skip,
  askUser,
  newerWins,
  userPreference,
  keepLocal,
  keepRemote,
  keepBoth,
  skipItem,
  deleteItem,
  renameItem,
}

enum ConflictResolution {
  useLocal,
  useRemote,
  merge,
  skip,
}

class SyncConflict {
  final String id;
  final String itemType;
  final String itemId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final DateTime timestamp;
  final String description;

  SyncConflict({
    required this.id,
    required this.itemType,
    required this.itemId,
    required this.localData,
    required this.remoteData,
    required this.timestamp,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'itemType': itemType,
    'itemId': itemId,
    'localData': localData,
    'remoteData': remoteData,
    'timestamp': timestamp.toIso8601String(),
    'description': description,
  };

  factory SyncConflict.fromJson(Map<String, dynamic> json) {
    return SyncConflict(
      id: json['id'],
      itemType: json['itemType'],
      itemId: json['itemId'],
      localData: Map<String, dynamic>.from(json['localData']),
      remoteData: Map<String, dynamic>.from(json['remoteData']),
      timestamp: DateTime.parse(json['timestamp']),
      description: json['description'],
    );
  }
}

class ConflictRule {
  final String id;
  final String name;
  final String description;
  final String itemType;
  final ConflictType conflictType;
  final ResolutionAction resolutionAction;
  final int priority;
  final bool enabled;
  final DateTime createdAt;

  ConflictRule({
    required this.id,
    required this.name,
    required this.description,
    required this.itemType,
    required this.conflictType,
    required this.resolutionAction,
    required this.priority,
    required this.enabled,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'itemType': itemType,
    'conflictType': conflictType.name,
    'resolutionAction': resolutionAction.name,
    'priority': priority,
    'enabled': enabled,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ConflictRule.fromJson(Map<String, dynamic> json) {
    return ConflictRule(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      itemType: json['itemType'],
      conflictType: ConflictType.values.firstWhere(
        (e) => e.name == json['conflictType'],
      ),
      resolutionAction: ResolutionAction.values.firstWhere(
        (e) => e.name == json['resolutionAction'],
      ),
      priority: json['priority'],
      enabled: json['enabled'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
