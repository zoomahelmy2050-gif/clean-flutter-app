/// Model for AI responses with action proposals
class AIResponse {
  final String message;
  final List<AppAction> suggestedActions;
  final AppAction? proposedAction;  // Action AI wants to execute
  final Map<String, dynamic>? data;
  final String? sessionId;
  final DateTime timestamp;

  AIResponse({
    required this.message,
    this.suggestedActions = const [],
    this.proposedAction,
    this.data,
    this.sessionId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Model for executable actions
class AppAction {
  final String name;
  final String label;
  final String? description;
  final Map<String, dynamic> parameters;
  final ActionType type;
  final RiskLevel riskLevel;
  final String? icon;
  final bool requiresConfirmation;

  AppAction({
    required this.name,
    required this.label,
    this.description,
    this.parameters = const {},
    required this.type,
    this.riskLevel = RiskLevel.medium,
    this.icon,
    this.requiresConfirmation = true,
  });
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
  low,
  medium,
  high,
  critical,
}
