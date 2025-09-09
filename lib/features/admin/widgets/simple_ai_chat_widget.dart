import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/general_ai_chat_service.dart';

class SimpleAIChatWidget extends StatefulWidget {
  const SimpleAIChatWidget({super.key});

  @override
  State<SimpleAIChatWidget> createState() => _SimpleAIChatWidgetState();
}

class _SimpleAIChatWidgetState extends State<SimpleAIChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<GeneralAIChatService>(
      builder: (context, chatService, _) {
        // Auto-scroll when new messages arrive
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        
        return Column(
          children: [
            // Chat messages area
            Expanded(
              child: chatService.messages.isEmpty
                  ? _buildWelcomeScreen(context, chatService)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: chatService.messages.length + (chatService.isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < chatService.messages.length) {
                          return _buildMessage(chatService.messages[index], theme);
                        } else {
                          return _buildTypingIndicator(theme);
                        }
                      },
                    ),
            ),
            
            // Input area
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(
                  top: BorderSide(color: theme.dividerColor),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(chatService),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: chatService.isTyping ? null : () => _sendMessage(chatService),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWelcomeScreen(BuildContext context, GeneralAIChatService chatService) {
    final theme = Theme.of(context);
    final suggestions = chatService.getSuggestions();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to AI Chat!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ask me anything - I\'m here to help!',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Try asking:',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.take(6).map((suggestion) {
              return ActionChip(
                label: Text(suggestion),
                onPressed: () {
                  _messageController.text = suggestion;
                  _sendMessage(chatService);
                },
                backgroundColor: theme.colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message, ThemeData theme) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: isUser ? null : Radius.zero,
                  bottomRight: isUser ? Radius.zero : null,
                ),
              ),
              child: SelectableText(
                message.content,
                style: TextStyle(
                  color: isUser 
                      ? Colors.white 
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: theme.colorScheme.secondary,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomLeft: Radius.zero,
              ),
            ),
            child: Row(
              children: [
                _buildDot(0, theme),
                const SizedBox(width: 4),
                _buildDot(1, theme),
                const SizedBox(width: 4),
                _buildDot(2, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.3 + (value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {
        setState(() {});
      },
    );
  }

  void _sendMessage(GeneralAIChatService chatService) {
    final text = _messageController.text.trim();
    if (text.isEmpty || chatService.isTyping) return;
    
    chatService.sendMessage(text);
    _messageController.clear();
    _focusNode.requestFocus();
  }
}
