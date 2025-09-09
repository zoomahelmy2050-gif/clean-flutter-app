import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../core/models/rbac_models.dart' as rbac;
import '../../auth/services/auth_service.dart';
import '../../../core/services/performance_monitoring_service.dart';
import '../../../core/services/role_management_service.dart' as role_service;
import '../services/ai_chat_engine.dart';
import '../services/ai_action_executor.dart';
import '../services/ai_action_handler.dart';
import '../services/ai_feature_registry.dart';
import '../services/ai_context_manager.dart';
import '../widgets/chat_message_widget.dart';
import '../widgets/minimal_chat_input.dart';
import '../widgets/action_confirmation_dialog.dart';
import '../models/chat_models.dart';
import '../../../locator.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({Key? key}) : super(key: key);

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen>
    with TickerProviderStateMixin {
  late final AIChatEngine _chatEngine;
  late final AIActionExecutor _actionExecutor;
  late final AIActionHandler _actionHandler;
  late final AIContextManager _contextManager;
  late final AuthService _authService;
  late final role_service.RoleManagementService _roleService;
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  
  final List<ChatMessage> _messages = [];
  final Map<String, ActionExecutionStatus> _actionStatuses = {};
  
  bool _isTyping = false;
  bool _isExecutingAction = false;
  List<FeatureDefinition> _suggestions = [];
  
  late AnimationController _typingAnimationController;
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupAnimations();
    _loadInitialContext();
    _initializeAsync();
  }

  void _initializeServices() {
    _authService = locator<AuthService>();
    _roleService = locator<role_service.RoleManagementService>();
    
    _chatEngine = AIChatEngine();
    _actionExecutor = AIActionExecutor();
    _contextManager = AIContextManager();
    
    _actionHandler = AIActionHandler(
      authService: _authService,
      performanceService: locator<PerformanceMonitoringService>(),
      actionExecutor: _actionExecutor,
    );
  }

  void _setupAnimations() {
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _typingAnimationController.repeat(reverse: true);
  }

  void _loadInitialContext() {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      final roleServiceRole = _roleService.getUserRole(currentUser);
      final userRole = _mapUserRole(roleServiceRole);
      _updateSuggestions(userRole);
    }
  }
  
  Future<void> _initializeAsync() async {
    print('🚀 Starting async initialization...');
    await _chatEngine.initialize();
    print('✅ Chat Engine initialized');
    
    // Send welcome message after initialization
    if (mounted) {
      _sendWelcomeMessage();
    }
  }

  void _sendWelcomeMessage() {
    _addMessage(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: 'Hello! I\'m your AI assistant. I can help you manage and control every aspect of your application. What would you like to do today?',
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.text,
    ));
    
    _addQuickActions();
  }

  void _addQuickActions() {
    final quickActions = [
      QuickAction(
        icon: Icons.security,
        label: 'Run Security Scan',
        action: () => _sendMessage('Run a security scan'),
        color: Colors.blue,
      ),
      QuickAction(
        icon: Icons.analytics,
        label: 'View Analytics',
        action: () => _sendMessage('Show me the analytics dashboard'),
        color: Colors.green,
      ),
      QuickAction(
        icon: Icons.group,
        label: 'Manage Users',
        action: () => _sendMessage('List all users'),
        color: Colors.orange,
      ),
      QuickAction(
        icon: Icons.monitor_heart,
        label: 'System Health',
        action: () => _sendMessage('Check system health'),
        color: Colors.purple,
      ),
    ];
    
    _addMessage(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: '',
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.quickActions,
      quickActions: quickActions,
    ));
  }

  void _sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    
    _addMessage(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: message,
      isUser: true,
      timestamp: DateTime.now(),
      type: MessageType.text,
    ));
    
    _messageController.clear();
    setState(() => _isTyping = true);
    
    try {
      final response = await _chatEngine.processMessage(message);
      
      setState(() => _isTyping = false);
      await _handleAIResponse(response, _mapUserRole(_roleService.getUserRole(_authService.currentUser ?? '')));
      
    } catch (e) {
      setState(() => _isTyping = false);
      _addMessage(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'I encountered an error processing your request: $e',
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.error,
      ));
    }
  }

  Future<void> _handleAIResponse(AIResponse response, rbac.UserRole userRole) async {
    _addMessage(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: response.message,
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.text,
      sentiment: response.sentiment,
    ));
    
    if (response.actions.isNotEmpty) {
      for (final action in response.actions) {
        await _executeAction(action, userRole);
      }
    }
    
    if (response.suggestions.isNotEmpty) {
      _addMessage(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '',
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.suggestions,
        suggestions: response.suggestions,
      ));
    }
    
    _updateSuggestions(userRole);
  }

  Future<void> _executeAction(ActionItem action, rbac.UserRole userRole) async {
    final feature = AIFeatureRegistry.getFeature(action.type);
    if (feature != null && feature.requiresConfirmation) {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ActionConfirmationDialog(
          action: action,
          feature: feature,
        ),
      );
      
      if (!(confirmed ?? false)) {
        _addMessage(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: 'Action cancelled: ${feature.name}',
          isUser: false,
          timestamp: DateTime.now(),
          type: MessageType.info,
        ));
        return;
      }
    }
    
    final executionId = DateTime.now().millisecondsSinceEpoch.toString();
    _addMessage(ChatMessage(
      id: executionId,
      content: 'Executing: ${action.type}',
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.action,
      action: action,
    ));
    
    setState(() {
      _isExecutingAction = true;
      _actionStatuses[executionId] = ActionExecutionStatus.running;
    });
    
    try {
      final result = await _actionHandler.executeAction(
        featureId: action.type,
        parameters: action.parameters,
        userRole: userRole,
        userId: _authService.currentUser?.toString(),
        context: action.context,
      );
      
      setState(() {
        _isExecutingAction = false;
        _actionStatuses[executionId] = result.success
            ? ActionExecutionStatus.success
            : ActionExecutionStatus.failed;
      });
      
      _addMessage(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: result.message ?? (result.success 
            ? 'Action completed successfully'
            : 'Action failed: ${result.error}'),
        isUser: false,
        timestamp: DateTime.now(),
        type: result.success ? MessageType.success : MessageType.error,
        data: result.data,
      ));
      
      if (result.warnings != null) {
        for (final warning in result.warnings!) {
          _addMessage(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: '⚠️ Warning: $warning',
            isUser: false,
            timestamp: DateTime.now(),
            type: MessageType.warning,
          ));
        }
      }
      
    } catch (e) {
      setState(() {
        _isExecutingAction = false;
        _actionStatuses[executionId] = ActionExecutionStatus.failed;
      });
      
      _addMessage(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Action execution failed: $e',
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.error,
      ));
    }
  }

  void _updateSuggestions(rbac.UserRole userRole) {
    setState(() {
      _suggestions = AIFeatureRegistry.getSuggestions(
        userRole: userRole,
        limit: 5,
      );
    });
  }

    rbac.UserRole _mapUserRole(role_service.UserRole roleServiceRole) {
    switch (roleServiceRole) {
            case role_service.UserRole.superAdmin:
        return rbac.UserRole.superuser;
            case role_service.UserRole.admin:
        return rbac.UserRole.admin;
            case role_service.UserRole.moderator:
        return rbac.UserRole.staff;
            case role_service.UserRole.user:
        return rbac.UserRole.user;
            case role_service.UserRole.guest:
        return rbac.UserRole.user;
    }
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('AI Assistant'),
            const Spacer(),
            if (_isExecutingAction)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Executing...', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Chat History',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return const TypingIndicator();
                }
                return ChatMessageWidget(
                  message: _messages[index],
                  actionStatus: _actionStatuses[_messages[index].id],
                  onSuggestionTap: _sendMessage,
                );
              },
            ),
          ),
          
          if (_suggestions.isNotEmpty)
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(suggestion.name),
                      onPressed: () => _sendMessage(suggestion.commands.first),
                    ),
                  );
                },
              ),
            ),
          
          MinimalChatInput(
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _typingAnimationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _contextManager.dispose();
    super.dispose();
  }
}

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.psychology, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: const [
                _DotAnimation(delay: 0),
                SizedBox(width: 4),
                _DotAnimation(delay: 200),
                SizedBox(width: 4),
                _DotAnimation(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DotAnimation extends StatefulWidget {
  final int delay;
  
  const _DotAnimation({Key? key, required this.delay}) : super(key: key);

  @override
  State<_DotAnimation> createState() => _DotAnimationState();
}

class _DotAnimationState extends State<_DotAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_animation.value * 4),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
