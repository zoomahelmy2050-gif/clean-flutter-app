import 'package:flutter/material.dart';
import 'dart:async';
import '../services/advanced_ai_core.dart';
import '../services/ai_models.dart';

class AdvancedAIChatWidget extends StatefulWidget {
  const AdvancedAIChatWidget({Key? key}) : super(key: key);

  @override
  State<AdvancedAIChatWidget> createState() => _AdvancedAIChatWidgetState();
}

class _AdvancedAIChatWidgetState extends State<AdvancedAIChatWidget> 
    with SingleTickerProviderStateMixin {
  late AdvancedAICore _aiCore;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  List<AIMessage> _messages = [];
  List<AIInsight> _insights = [];
  List<AIAction> _pendingActions = [];
  AISystemStatus? _systemStatus;
  bool _isProcessing = false;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  
  StreamSubscription<AIMessage>? _messageSubscription;
  StreamSubscription<AIInsight>? _insightSubscription;
  StreamSubscription<AIAction>? _actionSubscription;
  StreamSubscription<AISystemStatus>? _statusSubscription;
  
  @override
  void initState() {
    super.initState();
    _initializeAI();
    _setupAnimations();
  }
  
  void _initializeAI() {
    _aiCore = AdvancedAICore();
    
    // Subscribe to AI streams
    _messageSubscription = _aiCore.messageStream.listen((message) {
      setState(() {
        final conversation = _aiCore.getActiveConversation();
        _messages = conversation?.messages ?? [];
      });
      _scrollToBottom();
    });
    
    _insightSubscription = _aiCore.insightStream.listen((insight) {
      setState(() {
        _insights.add(insight);
        if (_insights.length > 5) {
          _insights.removeAt(0);
        }
      });
    });
    
    _actionSubscription = _aiCore.actionStream.listen((action) {
      setState(() {
        if (action.status == 'pending') {
          _pendingActions.add(action);
        } else {
          _pendingActions.removeWhere((a) => a.id == action.id);
        }
      });
    });
    
    _statusSubscription = _aiCore.statusStream.listen((status) {
      setState(() {
        _systemStatus = status;
      });
    });
    
    // Get initial data
    final conversation = _aiCore.getActiveConversation();
    if (conversation != null) {
      _messages = conversation.messages;
    }
    _systemStatus = _aiCore.getSystemStatus();
  }
  
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _messageSubscription?.cancel();
    _insightSubscription?.cancel();
    _actionSubscription?.cancel();
    _statusSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    _aiCore.dispose();
    super.dispose();
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    _messageController.clear();
    
    try {
      await _aiCore.processMessage(text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // System Status Bar
        _buildStatusBar(theme),
        
        // Main Content Area
        Expanded(
          child: Row(
            children: [
              // Chat Area
              Expanded(
                flex: 3,
                child: _buildChatArea(theme),
              ),
              
              // Side Panel with Insights and Actions
              if (MediaQuery.of(context).size.width > 900)
                Container(
                  width: 350,
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: theme.dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: _buildSidePanel(theme),
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatusBar(ThemeData theme) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // AI Status
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _systemStatus?.isOnline == true ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getStatusColor(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            'AI Core ${_systemStatus?.health?.toUpperCase() ?? "INITIALIZING"}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          
          // System Metrics
          if (_systemStatus != null) ...[
            _buildMetric(
              'Load',
              '${(_systemStatus!.processingLoad * 100).toInt()}%',
              theme,
            ),
            const SizedBox(width: 16),
            _buildMetric(
              'Memory',
              '${(_systemStatus!.memoryUsage * 100).toInt()}%',
              theme,
            ),
            const SizedBox(width: 16),
            _buildMetric(
              'Connections',
              '${_systemStatus!.activeConnections}',
              theme,
            ),
            const SizedBox(width: 16),
            _buildMetric(
              'Uptime',
              _formatUptime(_systemStatus!.uptime),
              theme,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildMetric(String label, String value, ThemeData theme) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
  
  Widget _buildChatArea(ThemeData theme) {
    return Column(
      children: [
        // Messages
        Expanded(
          child: _messages.isEmpty
              ? _buildWelcomeScreen(theme)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessage(_messages[index], theme);
                  },
                ),
        ),
        
        // Input Area
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: theme.dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  enabled: !_isProcessing,
                  decoration: InputDecoration(
                    hintText: 'Ask about security, users, performance, or threats...',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: IconButton.filled(
                  onPressed: _isProcessing ? null : _sendMessage,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildWelcomeScreen(ThemeData theme) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hub,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            Text(
              'Advanced AI Security Assistant',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Deep integration with Security Center • Real-time analysis • Automated actions',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('Analyze current threats', theme),
                _buildSuggestionChip('Check system security', theme),
                _buildSuggestionChip('Review user activities', theme),
                _buildSuggestionChip('Generate security report', theme),
                _buildSuggestionChip('Investigate recent incidents', theme),
                _buildSuggestionChip('Optimize performance', theme),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSuggestionChip(String text, ThemeData theme) {
    return InkWell(
      onTap: () {
        _messageController.text = text;
        _sendMessage();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }
  
  Widget _buildMessage(AIMessage message, ThemeData theme) {
    final isUser = message.role == 'user';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.hub, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.content,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (message.metadata.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (message.metadata['intent'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              message.metadata['intent'],
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        if (message.metadata['confidence'] != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Confidence: ${(message.metadata['confidence'] * 100).toInt()}%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: theme.colorScheme.secondary,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSidePanel(ThemeData theme) {
    return Column(
      children: [
        // Insights Section
        Expanded(
          child: _buildInsightsSection(theme),
        ),
        
        // Divider
        Divider(height: 1, color: theme.dividerColor),
        
        // Actions Section
        Expanded(
          child: _buildActionsSection(theme),
        ),
      ],
    );
  }
  
  Widget _buildInsightsSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Real-time Insights',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _insights.isEmpty
                ? Center(
                    child: Text(
                      'No insights yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _insights.length,
                    itemBuilder: (context, index) {
                      return _buildInsightCard(_insights[index], theme);
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInsightCard(AIInsight insight, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getInsightIcon(insight.type),
          color: _getSeverityColor(insight.severity),
          size: 20,
        ),
        title: Text(
          insight.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              insight.description,
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(insight.severity).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    insight.severity.toUpperCase(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(insight.confidence * 100).toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionsSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on,
                size: 20,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Automated Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _pendingActions.isEmpty
                ? Center(
                    child: Text(
                      'No pending actions',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _pendingActions.length,
                    itemBuilder: (context, index) {
                      return _buildActionCard(_pendingActions[index], theme);
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionCard(AIAction action, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getActionIcon(action.type),
          color: _getPriorityColor(action.priority),
          size: 20,
        ),
        title: Text(
          action.description,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Type: ${action.type}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(action.priority).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    action.priority.toUpperCase(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (action.requiresConfirmation)
                  Icon(
                    Icons.warning,
                    size: 14,
                    color: theme.colorScheme.error,
                  ),
              ],
            ),
          ],
        ),
        trailing: action.status == 'pending'
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                action.status == 'completed' ? Icons.check : Icons.close,
                color: action.status == 'completed' ? Colors.green : Colors.red,
                size: 20,
              ),
      ),
    );
  }
  
  Color _getStatusColor() {
    if (_systemStatus?.isOnline != true) return Colors.grey;
    switch (_systemStatus?.health) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'fair':
        return Colors.orange;
      case 'degraded':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
  
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getInsightIcon(String type) {
    switch (type) {
      case 'security_anomaly':
        return Icons.security;
      case 'performance_degradation':
        return Icons.speed;
      case 'user_risk':
        return Icons.person_off;
      case 'threat_pattern':
        return Icons.pattern;
      case 'correlation':
        return Icons.link;
      case 'prediction':
        return Icons.trending_up;
      default:
        return Icons.info;
    }
  }
  
  IconData _getActionIcon(String type) {
    switch (type) {
      case 'security_scan':
        return Icons.radar;
      case 'block_threat':
        return Icons.block;
      case 'user_management':
        return Icons.manage_accounts;
      case 'system_optimization':
        return Icons.tune;
      case 'generate_report':
        return Icons.description;
      case 'investigate':
        return Icons.search;
      case 'monitor':
        return Icons.visibility;
      default:
        return Icons.play_arrow;
    }
  }
  
  String _formatUptime(Duration uptime) {
    final days = uptime.inDays;
    final hours = uptime.inHours % 24;
    final minutes = uptime.inMinutes % 60;
    
    if (days > 0) {
      return '${days}d ${hours}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
