import 'package:flutter/material.dart';
import '../services/sync_status_service.dart';

class SyncStatusIndicator extends StatelessWidget {
  final SyncStatusService syncService;
  final bool showText;
  final bool compact;

  const SyncStatusIndicator({
    super.key,
    required this.syncService,
    this.showText = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: syncService,
      builder: (context, child) {
        if (compact) {
          return _buildCompactIndicator(context);
        }
        return _buildFullIndicator(context);
      },
    );
  }

  Widget _buildCompactIndicator(BuildContext context) {
    final status = syncService.status;
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == SyncStatus.syncing)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          else
            Icon(icon, size: 12, color: color),
          if (showText) ...[
            const SizedBox(width: 4),
            Text(
              _getStatusText(status),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullIndicator(BuildContext context) {
    final status = syncService.status;
    final progress = syncService.currentProgress;
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (status == SyncStatus.syncing)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              else
                Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getStatusText(status),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (syncService.lastSyncTime != null)
                Text(
                  _formatLastSync(syncService.lastSyncTime!),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          if (progress != null && status == SyncStatus.syncing) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progress.completed + progress.failed}/${progress.total}',
                  style: const TextStyle(fontSize: 12),
                ),
                if (progress.currentItem != null)
                  Expanded(
                    child: Text(
                      progress.currentItem!,
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
          if (syncService.lastError != null && status == SyncStatus.error) ...[
            const SizedBox(height: 4),
            Text(
              syncService.lastError!,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (syncService.hasConflicts) ...[
            const SizedBox(height: 4),
            Text(
              '${syncService.conflicts.length} conflicts need resolution',
              style: TextStyle(
                color: Colors.orange[700],
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return Colors.grey;
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.success:
        return Colors.green;
      case SyncStatus.error:
        return Colors.red;
      case SyncStatus.conflict:
        return Colors.orange;
      case SyncStatus.offline:
        return Colors.grey;
      case SyncStatus.paused:
        return Colors.amber;
    }
  }

  IconData _getStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return Icons.sync;
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.success:
        return Icons.check_circle;
      case SyncStatus.error:
        return Icons.error;
      case SyncStatus.conflict:
        return Icons.warning;
      case SyncStatus.offline:
        return Icons.cloud_off;
      case SyncStatus.paused:
        return Icons.pause_circle;
    }
  }

  String _getStatusText(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return 'Ready';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.success:
        return 'Synced';
      case SyncStatus.error:
        return 'Error';
      case SyncStatus.conflict:
        return 'Conflicts';
      case SyncStatus.offline:
        return 'Offline';
      case SyncStatus.paused:
        return 'Paused';
    }
  }

  String _formatLastSync(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class SyncProgressDialog extends StatelessWidget {
  final SyncStatusService syncService;
  final VoidCallback? onCancel;

  const SyncProgressDialog({
    super.key,
    required this.syncService,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: syncService,
      builder: (context, child) {
        final progress = syncService.currentProgress;
        final status = syncService.status;

        if (progress == null || status != SyncStatus.syncing) {
          return const SizedBox.shrink();
        }

        return AlertDialog(
          title: const Text('Syncing Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: progress.progress,
                backgroundColor: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text('Progress: ${progress.completed + progress.failed}/${progress.total}'),
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
              if (progress.conflicts > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Conflicts: ${progress.conflicts}',
                  style: TextStyle(color: Colors.orange[600]),
                ),
              ],
              if (progress.currentItem != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Current: ${progress.currentItem}',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Elapsed: ${_formatDuration(progress.elapsed)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            if (onCancel != null)
              TextButton(
                onPressed: onCancel,
                child: const Text('Cancel'),
              ),
            TextButton(
              onPressed: () => syncService.pauseSync(),
              child: const Text('Pause'),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}

class SyncStatusAppBar extends StatelessWidget implements PreferredSizeWidget {
  final SyncStatusService syncService;
  final String title;
  final List<Widget>? actions;

  const SyncStatusAppBar({
    super.key,
    required this.syncService,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        SyncStatusIndicator(
          syncService: syncService,
          compact: true,
          showText: false,
        ),
        const SizedBox(width: 8),
        ...?actions,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
