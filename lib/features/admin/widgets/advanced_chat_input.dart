import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdvancedChatInput extends StatefulWidget {
  final Function(String) onSend;
  final VoidCallback? onAttach;
  final VoidCallback? onVoice;
  
  const AdvancedChatInput({
    Key? key,
    required this.onSend,
    this.onAttach,
    this.onVoice,
  }) : super(key: key);

  @override
  State<AdvancedChatInput> createState() => _AdvancedChatInputState();
}

class _AdvancedChatInputState extends State<AdvancedChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 56, // Fixed height for the entire input area
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Attach button
          if (widget.onAttach != null)
            IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              onPressed: widget.onAttach,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
            ),
          
          // Text input
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: theme.hintColor,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          
          const SizedBox(width: 4),
          
          // Send or Voice button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _hasText
                ? IconButton(
                    key: const ValueKey('send'),
                    icon: Icon(
                      Icons.send_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    onPressed: _handleSend,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  )
                : IconButton(
                    key: const ValueKey('voice'),
                    icon: Icon(
                      Icons.mic_none_rounded,
                      color: theme.iconTheme.color,
                      size: 24,
                    ),
                    onPressed: widget.onVoice ?? () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
