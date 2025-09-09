import 'package:flutter/material.dart';
import '../services/ai_chat_engine.dart';
import '../widgets/advanced_chat_input.dart';
import '../models/chat_models.dart';
import '../../auth/services/auth_service.dart';
import '../../../locator.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  late final AIChatEngine _chatEngine;
  late final AuthService _authService;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _authService = locator<AuthService>();
    _chatEngine = AIChatEngine();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    await _chatEngine.initialize();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '👋 Hello! I\'m your AI Security Assistant powered by Google\'s Gemini AI.\n\nI can help you with:\n• Security Analysis & Monitoring\n• User Management\n• Threat Detection\n• System Reports\n\nWhat would you like to do today?',
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.text,
      ));
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: message,
        isUser: true,
        timestamp: DateTime.now(),
        type: MessageType.text,
      ));
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      // Process message with AI
      final response = await _chatEngine.processMessage(message);

      // Add AI response
      setState(() {
        _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: response.message,
          isUser: false,
          timestamp: DateTime.now(),
          type: MessageType.text,
        ));
        _isTyping = false;
      });

      // Add suggestions if any
      if (response.suggestions.isNotEmpty) {
        setState(() {
          _messages.add(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: '',
            isUser: false,
            timestamp: DateTime.now(),
            type: MessageType.suggestions,
            suggestions: response.suggestions,
          ));
        });
      }

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: 'Sorry, I encountered an error: $e',
          isUser: false,
          timestamp: DateTime.now(),
          type: MessageType.error,
        ));
        _isTyping = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Security Assistant',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  _isTyping ? 'typing...' : 'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isTyping 
                        ? theme.colorScheme.primary 
                        : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
            },
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessage(message, theme);
              },
            ),
          ),
          
          // Typing indicator
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTypingDot(0),
                        const SizedBox(width: 4),
                        _buildTypingDot(1),
                        const SizedBox(width: 4),
                        _buildTypingDot(2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Input area
          AdvancedChatInput(
            onSend: _sendMessage,
            onAttach: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Attachments coming soon!')),
              );
            },
            onVoice: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice input coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message, ThemeData theme) {
    if (message.type == MessageType.suggestions && message.suggestions != null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: message.suggestions!.map((suggestion) {
            return ActionChip(
              label: Text(suggestion, style: const TextStyle(fontSize: 12)),
              onPressed: () => _sendMessage(suggestion),
              backgroundColor: theme.colorScheme.primaryContainer,
            );
          }).toList(),
        ),
      );
    }

    final isUser = message.isUser;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.smart_toy, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isUser 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: isUser ? null : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : null,
                ),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  fontSize: 14,
                  color: isUser ? Colors.white : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.secondary,
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3 + (value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
