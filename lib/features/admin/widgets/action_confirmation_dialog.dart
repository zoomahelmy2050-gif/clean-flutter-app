import 'package:flutter/material.dart';
import '../models/chat_models.dart';
import '../services/ai_feature_registry.dart';

class ActionConfirmationDialog extends StatelessWidget {
  final ActionItem action;
  final FeatureDefinition feature;

  const ActionConfirmationDialog({
    Key? key,
    required this.action,
    required this.feature,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            _getImpactIcon(feature.impact),
            color: _getImpactColor(feature.impact),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confirm Action',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature.name,
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(feature.description),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Impact Level
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getImpactColor(feature.impact).withOpacity(0.1),
                border: Border.all(
                  color: _getImpactColor(feature.impact).withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _getImpactIcon(feature.impact),
                    color: _getImpactColor(feature.impact),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Impact Level: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getImpactColor(feature.impact),
                    ),
                  ),
                  Text(
                    feature.impact.name.toUpperCase(),
                    style: TextStyle(
                      color: _getImpactColor(feature.impact),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Parameters
            if (action.parameters.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.settings,
                          size: 16,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Parameters',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...action.parameters.entries.map((entry) {
                      final paramDef = feature.parameters[entry.key] ?? ParameterDefinition(
                          name: entry.key,
                          type: String,
                          description: '',
                          required: false,
                        );
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _formatParameterValue(entry.value, paramDef),
                                style: TextStyle(
                                  fontFamily: paramDef.sensitive ? 'monospace' : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Permissions Required
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Required Role: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  Text(
                    feature.permissions.first.name.toUpperCase(),
                    style: TextStyle(
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Warning Message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getWarningMessage(feature.impact),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getImpactColor(feature.impact),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          icon: const Icon(Icons.check),
          label: const Text('Confirm & Execute'),
        ),
      ],
    );
  }

  IconData _getImpactIcon(ImpactLevel impact) {
    switch (impact) {
      case ImpactLevel.low:
        return Icons.info_outline;
      case ImpactLevel.medium:
        return Icons.warning_amber;
      case ImpactLevel.high:
        return Icons.warning;
      case ImpactLevel.critical:
        return Icons.dangerous;
    }
  }

  Color _getImpactColor(ImpactLevel impact) {
    switch (impact) {
      case ImpactLevel.low:
        return Colors.blue;
      case ImpactLevel.medium:
        return Colors.orange;
      case ImpactLevel.high:
        return Colors.deepOrange;
      case ImpactLevel.critical:
        return Colors.red;
    }
  }

  String _getWarningMessage(ImpactLevel impact) {
    switch (impact) {
      case ImpactLevel.low:
        return 'This action has minimal impact and can be easily reversed if needed.';
      case ImpactLevel.medium:
        return 'This action may affect system behavior. Please review the parameters carefully.';
      case ImpactLevel.high:
        return 'This action will make significant changes. Ensure you understand the implications.';
      case ImpactLevel.critical:
        return 'CRITICAL: This action may have irreversible effects on the system. Proceed with extreme caution!';
    }
  }

  String _formatParameterValue(dynamic value, ParameterDefinition paramDef) {
    if (paramDef.sensitive) {
      return '••••••••';
    }
    
    if (value is List) {
      return value.join(', ');
    } else if (value is Map) {
      return value.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    } else if (value is bool) {
      return value ? 'Yes' : 'No';
    }
    
    return value.toString();
  }
}
