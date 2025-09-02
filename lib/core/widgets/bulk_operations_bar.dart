import 'package:flutter/material.dart';
import '../services/bulk_operations_service.dart';

class BulkOperationsBar extends StatelessWidget {
  final BulkOperationsService bulkService;
  final List<BulkOperationType> availableOperations;
  final Function(BulkOperationType) onOperationSelected;
  final VoidCallback? onCancel;

  const BulkOperationsBar({
    super.key,
    required this.bulkService,
    required this.availableOperations,
    required this.onOperationSelected,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: bulkService,
      builder: (context, child) {
        if (!bulkService.isSelectionMode) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onCancel ?? bulkService.exitSelectionMode,
                    icon: const Icon(Icons.close),
                    tooltip: 'Cancel selection',
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${bulkService.selectedCount} selected',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (bulkService.hasSelection) ...[
                    ...availableOperations.map((operation) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: IconButton(
                        onPressed: () => onOperationSelected(operation),
                        icon: Icon(bulkService.getOperationIcon(operation)),
                        tooltip: bulkService.getOperationName(operation),
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class BulkOperationProgressDialog extends StatefulWidget {
  final BulkOperationsService bulkService;
  final String operationName;
  final VoidCallback? onCancel;

  const BulkOperationProgressDialog({
    super.key,
    required this.bulkService,
    required this.operationName,
    this.onCancel,
  });

  @override
  State<BulkOperationProgressDialog> createState() => _BulkOperationProgressDialogState();
}

class _BulkOperationProgressDialogState extends State<BulkOperationProgressDialog> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.bulkService,
      builder: (context, child) {
        final progress = widget.bulkService.currentProgress;
        
        if (progress == null) {
          return const SizedBox.shrink();
        }

        return AlertDialog(
          title: Text(widget.operationName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: progress.progress,
                backgroundColor: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Progress: ${progress.completed + progress.failed}/${progress.total}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (progress.completed > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Completed: ${progress.completed}',
                  style: TextStyle(color: Colors.green[600]),
                ),
              ],
              if (progress.failed > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Failed: ${progress.failed}',
                  style: TextStyle(color: Colors.red[600]),
                ),
              ],
              if (progress.currentItem != null && !progress.isCompleted) ...[
                const SizedBox(height: 8),
                Text(
                  'Processing: ${progress.currentItem}',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (progress.hasErrors) ...[
                const SizedBox(height: 12),
                ExpansionTile(
                  title: Text(
                    'Errors (${progress.errors.length})',
                    style: TextStyle(color: Colors.red[600]),
                  ),
                  children: progress.errors.map((error) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    child: Text(
                      error,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red[600],
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ],
          ),
          actions: [
            if (!progress.isCompleted && widget.onCancel != null)
              TextButton(
                onPressed: widget.onCancel,
                child: const Text('Cancel'),
              ),
            if (progress.isCompleted)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
          ],
        );
      },
    );
  }
}

class SelectableListTile extends StatelessWidget {
  final String itemId;
  final BulkOperationsService bulkService;
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const SelectableListTile({
    super.key,
    required this.itemId,
    required this.bulkService,
    required this.child,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: bulkService,
      builder: (context, _) {
        final isSelected = bulkService.isSelected(itemId);
        final isSelectionMode = bulkService.isSelectionMode;

        return GestureDetector(
          onTap: () {
            if (isSelectionMode) {
              bulkService.toggleSelection(itemId);
            } else {
              onTap?.call();
            }
          },
          onLongPress: () {
            if (!isSelectionMode) {
              bulkService.enterSelectionMode();
              bulkService.selectItem(itemId);
            }
            onLongPress?.call();
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected 
                  ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                  : null,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                child,
                if (isSelectionMode)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        isSelected ? Icons.check : null,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BulkOperationsFloatingButton extends StatelessWidget {
  final BulkOperationsService bulkService;
  final VoidCallback onPressed;
  final String tooltip;

  const BulkOperationsFloatingButton({
    super.key,
    required this.bulkService,
    required this.onPressed,
    this.tooltip = 'Select items',
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: bulkService,
      builder: (context, child) {
        if (bulkService.isSelectionMode) {
          return const SizedBox.shrink();
        }

        return FloatingActionButton(
          onPressed: onPressed,
          tooltip: tooltip,
          child: const Icon(Icons.checklist),
        );
      },
    );
  }
}
