import 'package:flutter/material.dart';

class SimpleChatInput extends StatefulWidget {
  final Function(String) onSend;
  
  const SimpleChatInput({
    Key? key,
    required this.onSend,
  }) : super(key: key);

  @override
  State<SimpleChatInput> createState() => _SimpleChatInputState();
}

class _SimpleChatInputState extends State<SimpleChatInput> {
  final TextEditingController _controller = TextEditingController();
  bool _canSend = false;
  
  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final canSend = _controller.text.trim().isNotEmpty;
      if (canSend != _canSend) {
        setState(() => _canSend = canSend);
      }
    });
  }
  
  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
      setState(() => _canSend = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // FIXED HEIGHT CONTAINER - NO EXPANSION
    return Container(
      height: 56.0, // Fixed height
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Input field container
          Expanded(
            child: Container(
              height: 40, // Fixed height for input
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  // Text input
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.2,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type a message',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: theme.hintColor.withOpacity(0.6),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        maxLines: 1, // Single line only
                        textAlignVertical: TextAlignVertical.center,
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                  ),
                  
                  // Send button inside input container
                  if (_canSend)
                    GestureDetector(
                      onTap: _handleSend,
                      child: Container(
                        margin: const EdgeInsets.only(right: 4),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_upward,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  
                  // Mic button when no text
                  if (!_canSend)
                    GestureDetector(
                      onTap: () {
                        // Voice input placeholder
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 4),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mic_none,
                          color: theme.iconTheme.color?.withOpacity(0.6),
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
