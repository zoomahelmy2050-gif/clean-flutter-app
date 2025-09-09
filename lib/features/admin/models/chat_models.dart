import 'package:flutter/material.dart';

enum MessageType {
  text,
  quickActions,
  suggestions,
  action,
  error,
  warning,
  success,
  info,
}

enum ActionExecutionStatus {
  pending,
  running,
  success,
  failed,
}

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;
  final String? sentiment;
  final List<QuickAction>? quickActions;
  final List<String>? suggestions;
  final ActionItem? action;
  final Map<String, dynamic>? data;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    required this.type,
    this.sentiment,
    this.quickActions,
    this.suggestions,
    this.action,
    this.data,
  });
}

class QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback action;
  final Color color;

  QuickAction({
    required this.icon,
    required this.label,
    required this.action,
    required this.color,
  });
}

class ActionItem {
  final String type;
  final String name;
  final Map<String, dynamic> parameters;
  final Map<String, dynamic>? context;
  final double confidence;

  ActionItem({
    required this.type,
    required this.name,
    required this.parameters,
    this.context,
    this.confidence = 1.0,
  });
}

class AIResponse {
  final String message;
  final List<ActionItem> actions;
  final List<String> suggestions;
  final String? sentiment;
  final Map<String, dynamic>? context;
  final bool requiresConfirmation;

  AIResponse({
    required this.message,
    this.actions = const [],
    this.suggestions = const [],
    this.sentiment,
    this.context,
    this.requiresConfirmation = false,
  });
}
