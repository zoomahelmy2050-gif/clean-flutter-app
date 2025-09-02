class SyncStatus {
  final bool isEnabled;
  final DateTime? lastSync;
  final bool isInProgress;
  final String? error;

  SyncStatus({
    required this.isEnabled,
    this.lastSync,
    required this.isInProgress,
    this.error,
  });

  factory SyncStatus.fromJson(Map<String, dynamic> json) {
    return SyncStatus(
      isEnabled: json['isEnabled'],
      lastSync: json['lastSync'] != null ? DateTime.parse(json['lastSync']) : null,
      isInProgress: json['isInProgress'],
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'lastSync': lastSync?.toIso8601String(),
      'isInProgress': isInProgress,
      'error': error,
    };
  }
}

class SyncData {
  final Map<String, dynamic> totpSecrets;
  final Map<String, dynamic> userSettings;
  final DateTime timestamp;

  SyncData({
    required this.totpSecrets,
    required this.userSettings,
    required this.timestamp,
  });

  factory SyncData.fromJson(Map<String, dynamic> json) {
    return SyncData(
      totpSecrets: Map<String, dynamic>.from(json['totpSecrets']),
      userSettings: Map<String, dynamic>.from(json['userSettings']),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totpSecrets': totpSecrets,
      'userSettings': userSettings,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
