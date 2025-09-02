import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/totp_manager_service.dart';
import '../../../core/models/totp_entry.dart';
import 'dart:async';

class TotpQuickAccessWidget extends StatefulWidget {
  final int maxEntries;
  final bool showTimer;
  final VoidCallback? onViewAll;

  const TotpQuickAccessWidget({
    Key? key,
    this.maxEntries = 3,
    this.showTimer = true,
    this.onViewAll,
  }) : super(key: key);

  @override
  State<TotpQuickAccessWidget> createState() => _TotpQuickAccessWidgetState();
}

class _TotpQuickAccessWidgetState extends State<TotpQuickAccessWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Force refresh to update remaining time and codes
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<TotpManagerService>(
      builder: (context, totpManager, _) {
        final entries = totpManager.entries.take(widget.maxEntries).toList();
        
        if (entries.isEmpty) {
          return _buildEmptyState(theme);
        }
        
        return Card(
          margin: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.security,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Quick TOTP Access',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (widget.onViewAll != null)
                      TextButton(
                        onPressed: widget.onViewAll,
                        child: const Text('View All'),
                      ),
                  ],
                ),
              ),
              ...entries.map((entry) => _buildTotpTile(entry, totpManager, theme)),
              if (entries.length < totpManager.entries.length)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    '${totpManager.entries.length - entries.length} more codes available',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.security,
              size: 48,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No TOTP codes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add TOTP codes for quick access',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: widget.onViewAll,
              icon: const Icon(Icons.add),
              label: const Text('Add TOTP'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotpTile(TotpEntry entry, TotpManagerService manager, ThemeData theme) {
    final code = manager.getCode(entry.id) ?? '------';
    final remainingSeconds = manager.getRemainingSeconds(entry.id) ?? 0;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getColorFromString(entry.color),
        radius: 20,
        child: Text(
          entry.icon ?? entry.name[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        entry.name,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        entry.issuer,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCode(code),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (widget.showTimer)
                Text(
                  '${remainingSeconds}s',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: remainingSeconds <= 10 ? Colors.red : theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          if (widget.showTimer)
            _buildMiniTimer(remainingSeconds, theme),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () => _copyCode(code, entry.id, manager),
            tooltip: 'Copy code',
          ),
        ],
      ),
      onTap: () => _copyCode(code, entry.id, manager),
    );
  }

  Widget _buildMiniTimer(int seconds, ThemeData theme) {
    final progress = seconds / 30;
    final color = seconds <= 5
        ? Colors.red
        : seconds <= 10
            ? Colors.orange
            : theme.colorScheme.primary;
    
    return SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        value: progress,
        strokeWidth: 2,
        backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }

  String _formatCode(String code) {
    if (code.length == 6) {
      return '${code.substring(0, 3)} ${code.substring(3)}';
    }
    return code;
  }

  Color _getColorFromString(String? colorString) {
    if (colorString == null) return Colors.blue;
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (_) {
      return Colors.blue;
    }
  }

  void _copyCode(String code, String entryId, TotpManagerService manager) {
    if (code != '------') {
      Clipboard.setData(ClipboardData(text: code));
      manager.markAsUsed(entryId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Code copied: $code'),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }
}
