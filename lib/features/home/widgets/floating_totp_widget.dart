import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/totp_manager_service.dart';
import '../../../core/models/totp_entry.dart';
import 'dart:async';

class FloatingTotpWidget extends StatefulWidget {
  const FloatingTotpWidget({Key? key}) : super(key: key);

  @override
  State<FloatingTotpWidget> createState() => _FloatingTotpWidgetState();
}

class _FloatingTotpWidgetState extends State<FloatingTotpWidget>
    with TickerProviderStateMixin {
  Timer? _timer;
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _startTimer();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.25,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));
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
    _animationController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _animationController.forward();
      _rotationController.forward();
    } else {
      _animationController.reverse();
      _rotationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<TotpManagerService>(
      builder: (context, totpManager, _) {
        final entries = totpManager.entries.take(3).toList();
        
        if (entries.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Positioned(
          right: 16,
          bottom: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Expanded TOTP codes
              SizeTransition(
                sizeFactor: _expandAnimation,
                axisAlignment: 1.0,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  constraints: const BoxConstraints(maxWidth: 280),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: theme.colorScheme.onPrimaryContainer,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Quick TOTP',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${totpManager.entries.length}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...entries.map((entry) => _buildFloatingTotpTile(entry, totpManager, theme)),
                    ],
                  ),
                ),
              ),
              
              // Floating action button
              FloatingActionButton(
                mini: true,
                onPressed: _toggleExpanded,
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                child: AnimatedBuilder(
                  animation: _rotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value * 2 * 3.14159,
                      child: Icon(
                        _isExpanded ? Icons.close : Icons.security,
                        size: 20,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingTotpTile(TotpEntry entry, TotpManagerService manager, ThemeData theme) {
    final code = manager.getCode(entry.id) ?? '------';
    final remainingSeconds = manager.getRemainingSeconds(entry.id) ?? 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _getColorFromString(entry.color),
            radius: 12,
            child: Text(
              entry.icon ?? entry.name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  entry.issuer,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCode(code),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontSize: 12,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${remainingSeconds}s',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: remainingSeconds <= 10 
                          ? Colors.red 
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      value: remainingSeconds / 30,
                      strokeWidth: 1.5,
                      backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation(
                        remainingSeconds <= 5
                            ? Colors.red
                            : remainingSeconds <= 10
                                ? Colors.orange
                                : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.copy, size: 14),
            onPressed: () => _copyCode(code, entry.id, manager),
            tooltip: 'Copy',
            constraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 24,
            ),
            padding: const EdgeInsets.all(4),
          ),
        ],
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
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text('Copied: $code', style: const TextStyle(fontSize: 12)),
            ],
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}
