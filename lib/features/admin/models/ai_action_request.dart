/// Model for AI action requests that need user confirmation
class AIActionRequest {
  final String id;
  final String action;
  final String description;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;
  final String? reason;
  final ActionType type;
  final RiskLevel riskLevel;

  AIActionRequest({
    required this.id,
    required this.action,
    required this.description,
    required this.parameters,
    required this.timestamp,
    this.reason,
    required this.type,
    required this.riskLevel,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'action': action,
    'description': description,
    'parameters': parameters,
    'timestamp': timestamp.toIso8601String(),
    'reason': reason,
    'type': type.toString(),
    'riskLevel': riskLevel.toString(),
  };
}

enum ActionType {
  blockUser,
  unblockUser,
  deleteUser,
  resetPassword,
  disableMFA,
  changeRole,
  blockIP,
  unblockIP,
  clearLogs,
  runScan,
  generateReport,
  sendNotification,
  executeWorkflow,
  modifySettings,
}

enum RiskLevel {
  low,    // Safe actions like generating reports
  medium, // Moderate actions like password reset
  high,   // Critical actions like deleting users
  critical, // System-wide changes
}

extension ActionTypeExtension on ActionType {
  String get displayName {
    switch (this) {
      case ActionType.blockUser:
        return 'Block User';
      case ActionType.unblockUser:
        return 'Unblock User';
      case ActionType.deleteUser:
        return 'Delete User';
      case ActionType.resetPassword:
        return 'Reset Password';
      case ActionType.disableMFA:
        return 'Disable MFA';
      case ActionType.changeRole:
        return 'Change Role';
      case ActionType.blockIP:
        return 'Block IP Address';
      case ActionType.unblockIP:
        return 'Unblock IP Address';
      case ActionType.clearLogs:
        return 'Clear Logs';
      case ActionType.runScan:
        return 'Run Security Scan';
      case ActionType.generateReport:
        return 'Generate Report';
      case ActionType.sendNotification:
        return 'Send Notification';
      case ActionType.executeWorkflow:
        return 'Execute Workflow';
      case ActionType.modifySettings:
        return 'Modify Settings';
    }
  }

  String get icon {
    switch (this) {
      case ActionType.blockUser:
      case ActionType.blockIP:
        return '🚫';
      case ActionType.unblockUser:
      case ActionType.unblockIP:
        return '✅';
      case ActionType.deleteUser:
        return '🗑️';
      case ActionType.resetPassword:
        return '🔑';
      case ActionType.disableMFA:
        return '🔓';
      case ActionType.changeRole:
        return '👤';
      case ActionType.clearLogs:
        return '📝';
      case ActionType.runScan:
        return '🔍';
      case ActionType.generateReport:
        return '📊';
      case ActionType.sendNotification:
        return '📧';
      case ActionType.executeWorkflow:
        return '⚡';
      case ActionType.modifySettings:
        return '⚙️';
    }
  }
}

extension RiskLevelExtension on RiskLevel {
  String get displayName {
    switch (this) {
      case RiskLevel.low:
        return 'Low Risk';
      case RiskLevel.medium:
        return 'Medium Risk';
      case RiskLevel.high:
        return 'High Risk';
      case RiskLevel.critical:
        return 'Critical';
    }
  }

  String get color {
    switch (this) {
      case RiskLevel.low:
        return '🟢';
      case RiskLevel.medium:
        return '🟡';
      case RiskLevel.high:
        return '🟠';
      case RiskLevel.critical:
        return '🔴';
    }
  }
}
