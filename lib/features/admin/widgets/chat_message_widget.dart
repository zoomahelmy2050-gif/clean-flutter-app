import 'package:flutter/material.dart';
import '../models/chat_models.dart';
import '../services/ai_feature_registry.dart';

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final ActionExecutionStatus? actionStatus;
  final Function(String) onSuggestionTap;

  const ChatMessageWidget({
    Key? key,
    required this.message,
    this.actionStatus,
    required this.onSuggestionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return _buildTextMessage(context);
      case MessageType.quickActions:
        return _buildQuickActions(context);
      case MessageType.suggestions:
        return _buildSuggestions(context);
      case MessageType.action:
        return _buildActionMessage(context);
      case MessageType.error:
        return _buildErrorMessage(context);
      case MessageType.warning:
        return _buildWarningMessage(context);
      case MessageType.success:
        return _buildSuccessMessage(context);
      case MessageType.info:
        return _buildInfoMessage(context);
    }
  }

  Widget _buildTextMessage(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primary,
                child: const Icon(Icons.psychology, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUser
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16).copyWith(
                    topLeft: isUser ? null : Radius.zero,
                    topRight: isUser ? Radius.zero : null,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      message.content,
                      style: TextStyle(
                        color: isUser ? Colors.white : null,
                      ),
                    ),
                    if (message.sentiment != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Sentiment: ${message.sentiment}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isUser
                                ? Colors.white.withOpacity(0.7)
                                : theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.secondary,
                child: const Icon(Icons.person, size: 20, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: message.quickActions!.map((action) {
          return ElevatedButton.icon(
            icon: Icon(action.icon, size: 18),
            label: Text(action.label),
            style: ElevatedButton.styleFrom(
              backgroundColor: action.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: action.action,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSuggestions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: message.suggestions!.map((suggestion) {
          return ActionChip(
            label: Text(suggestion),
            onPressed: () => onSuggestionTap(suggestion),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionMessage(BuildContext context) {
    final status = actionStatus ?? ActionExecutionStatus.pending;
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildActionStatusIcon(status),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (message.action != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Type: ${message.action!.type}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (message.action!.parameters.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Parameters: ${message.action!.parameters.entries.map((e) => '${e.key}=${e.value}').join(', ')}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ],
            ),
          ),
          if (status == ActionExecutionStatus.running)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildActionStatusIcon(ActionExecutionStatus status) {
    switch (status) {
      case ActionExecutionStatus.pending:
        return const Icon(Icons.schedule, color: Colors.grey);
      case ActionExecutionStatus.running:
        return const Icon(Icons.play_arrow, color: Colors.blue);
      case ActionExecutionStatus.success:
        return const Icon(Icons.check_circle, color: Colors.green);
      case ActionExecutionStatus.failed:
        return const Icon(Icons.error, color: Colors.red);
    }
  }

  Widget _buildErrorMessage(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message.content,
              style: TextStyle(color: Colors.red.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningMessage(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message.content,
              style: TextStyle(color: Colors.orange.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(color: Colors.green.shade900),
                ),
                if (message.data != null && message.data!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildDataDisplay(message.data!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoMessage(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message.content,
              style: TextStyle(color: Colors.blue.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataDisplay(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.entries.map((entry) {
          final value = _formatValue(entry.value);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.key}: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value is List) {
      return value.join(', ');
    } else if (value is Map) {
      return value.entries
          .map((e) => '${e.key}: ${_formatValue(e.value)}')
          .join(', ');
    }
    return value.toString();
  }
}
