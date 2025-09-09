import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../locator.dart';
import '../models/chat_models.dart' as chat_models;
import '../services/ai_chat_engine.dart';

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<chat_models.ActionItem>? actions;
  final bool requiresConfirmation;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.actions,
    this.requiresConfirmation = false,
  });
}

class AIWorkflowsScreen extends StatefulWidget {
  const AIWorkflowsScreen({super.key});

  @override
  State<AIWorkflowsScreen> createState() => _AIWorkflowsScreenState();
}

class _AIWorkflowsScreenState extends State<AIWorkflowsScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final AIChatEngine _chatEngine = locator<AIChatEngine>();
  bool _isTyping = false;
  bool _isDarkMode = true;
  bool _isSidebarExpanded = true;
  late AnimationController _typingController;
  final List<String> _conversationHistory = [
    'Security Analysis Chat',
    'User Management Discussion',
    'Threat Detection Review',
  ];

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _typingController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        content: '👋 Hello! I\'m your AI security assistant. How can I help you manage your security workflows today?',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      body: Row(
        children: [
          // ChatGPT-style Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isSidebarExpanded ? 260 : 0,
            child: _buildSidebar(),
          ),
          // Main Chat Area
          Expanded(
            child: Column(
              children: [
                _buildChatHeader(),
                Expanded(
                  child: _messages.isEmpty 
                    ? _buildWelcomeScreen()
                    : _buildChatMessages(),
                ),
                if (_isTyping) _buildTypingIndicator(),
                _buildInputArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      color: _isDarkMode ? const Color(0xFF202020) : const Color(0xFFF7F7F8),
      child: Column(
        children: [
          // New Chat Button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startNewChat,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isDarkMode ? const Color(0xFF2D2D30) : Colors.white,
                  foregroundColor: _isDarkMode ? Colors.white : Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: _isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E5E5),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Conversation History
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _conversationHistory.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    title: Text(
                      _conversationHistory[index],
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white70 : Colors.black87,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading: Icon(
                      Icons.chat_bubble_outline,
                      size: 16,
                      color: _isDarkMode ? Colors.white54 : Colors.black54,
                    ),
                    onTap: () => _loadConversation(index),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hoverColor: _isDarkMode ? const Color(0xFF2D2D30) : const Color(0xFFF0F0F0),
                  ),
                );
              },
            ),
          ),
          // User Profile Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: _isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E5E5),
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.purple,
                  child: const Text(
                    'A',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Admin User',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _toggleTheme,
                  icon: Icon(
                    _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: _isDarkMode ? Colors.white70 : Colors.black54,
                    size: 20,
                  ),
                  tooltip: _isDarkMode ? 'Light mode' : 'Dark mode',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E5E5),
          ),
        ),
      ),
      child: Row(
        children: [
          if (!_isSidebarExpanded)
            IconButton(
              onPressed: () => setState(() => _isSidebarExpanded = true),
              icon: Icon(
                Icons.menu,
                color: _isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          if (_isSidebarExpanded)
            IconButton(
              onPressed: () => setState(() => _isSidebarExpanded = false),
              icon: Icon(
                Icons.close,
                color: _isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          const SizedBox(width: 8),
          Text(
            'AI Security Assistant',
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _exportChat,
            icon: Icon(
              Icons.download,
              color: _isDarkMode ? Colors.white70 : Colors.black54,
            ),
            tooltip: 'Export chat',
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.smart_toy,
                size: 40,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'AI Security Assistant',
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'How can I help you today?',
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            _buildQuickActionCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCards() {
    final quickActions = [
      {
        'title': 'Analyze Security Logs',
        'subtitle': 'Review recent security events',
        'icon': Icons.security,
      },
      {
        'title': 'User Management',
        'subtitle': 'Manage users and permissions',
        'icon': Icons.people,
      },
      {
        'title': 'Generate Report',
        'subtitle': 'Create security reports',
        'icon': Icons.assessment,
      },
      {
        'title': 'System Health Check',
        'subtitle': 'Check system status',
        'icon': Icons.health_and_safety,
      },
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: quickActions.map((action) {
        return SizedBox(
          width: 200,
          child: Card(
            color: _isDarkMode ? const Color(0xFF2D2D30) : Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E5E5),
              ),
            ),
            child: InkWell(
              onTap: () => _sendQuickAction(action['title'] as String),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      action['icon'] as IconData,
                      color: Colors.green,
                      size: 24,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      action['title'] as String,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action['subtitle'] as String,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white60 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChatMessages() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: message.isUser ? Colors.deepPurple : Colors.green,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              message.isUser ? Icons.person : Icons.smart_toy,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          // Message Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.isUser ? 'You' : 'AI Assistant',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? const Color(0xFF2D2D30) : const Color(0xFFF7F7F8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                if (message.actions != null && message.actions!.isNotEmpty)
                  _buildActionChips(message.actions!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChips(List<chat_models.ActionItem> actions) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: actions.map((action) {
          return ActionChip(
            label: Text(
              action.name,
              style: const TextStyle(fontSize: 12),
            ),
            onPressed: () => _executeAction(action),
            backgroundColor: _isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E5E5),
            labelStyle: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _isDarkMode ? const Color(0xFF2D2D30) : const Color(0xFFF7F7F8),
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
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedBuilder(
      animation: _typingController,
      builder: (context, child) {
        final animation = Tween<double>(
          begin: 0.4,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _typingController,
          curve: Interval(
            index * 0.2,
            (index * 0.2) + 0.4,
            curve: Curves.easeInOut,
          ),
        ));

        return FadeTransition(
          opacity: animation,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.white70 : Colors.black54,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: _isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E5E5),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF2D2D30) : const Color(0xFFF7F7F8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E5E5),
                ),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Message AI Assistant...',
                  hintStyle: TextStyle(
                    color: _isDarkMode ? Colors.white54 : Colors.black54,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: _messageController.text.trim().isNotEmpty 
                ? Colors.green 
                : (_isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E5E5)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: _messageController.text.trim().isNotEmpty ? _sendMessage : null,
              icon: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startNewChat() {
    setState(() {
      _messages.clear();
    });
    _addWelcomeMessage();
  }

  void _loadConversation(int index) {
    setState(() {
      _messages.clear();
    });
    _addWelcomeMessage();
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _exportChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat exported successfully')),
    );
  }

  void _sendQuickAction(String action) {
    _messageController.text = action;
    _sendMessage();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(
        content: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _typingController.repeat();
    _scrollToBottom();

    try {
      final response = await _chatEngine.processMessage(userMessage);
      
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          content: response.message,
          isUser: false,
          timestamp: DateTime.now(),
          actions: response.actions,
          requiresConfirmation: response.requiresConfirmation,
        ));
      });

      _typingController.stop();
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          content: 'Sorry, I encountered an error processing your request. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _typingController.stop();
    }
  }

  Future<void> _executeAction(chat_models.ActionItem action) async {
    // ActionItem doesn't have requiresConfirmation, so we'll ask for confirmation on sensitive actions
    if (action.type.contains('delete') || action.type.contains('remove') || action.type.contains('block')) {
      final confirmed = await _showConfirmationDialog(action);
      if (!confirmed) return;
    }

    try {
      await _chatEngine.executeAction(action.type, action.parameters);
      
      setState(() {
        _messages.add(ChatMessage(
          content: '✅ Action "${action.name}" executed successfully.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          content: '❌ Failed to execute action "${action.name}": ${e.toString()}',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }

    _scrollToBottom();
  }

  Future<bool> _showConfirmationDialog(chat_models.ActionItem action) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF2D2D30) : Colors.white,
        title: Text(
          'Confirm Action',
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          'Are you sure you want to execute "${action.name}"?\n\n${action.type}',
          style: TextStyle(
            color: _isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Execute'),
          ),
        ],
      ),
    ) ?? false;
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
}
