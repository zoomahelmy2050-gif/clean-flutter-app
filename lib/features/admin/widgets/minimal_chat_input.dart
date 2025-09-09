import 'package:flutter/material.dart';

/// Absolutely minimal chat input widget with FIXED height and horizontal text
class MinimalChatInput extends StatefulWidget {
  final Function(String) onSend;
  
  const MinimalChatInput({
    Key? key,
    required this.onSend,
  }) : super(key: key);

  @override
  State<MinimalChatInput> createState() => _MinimalChatInputState();
}

class _MinimalChatInputState extends State<MinimalChatInput> {
  final TextEditingController _controller = TextEditingController();
  
  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 50, // ABSOLUTELY FIXED HEIGHT
        child: Container(
          color: Colors.grey[900],
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              // Text field with fixed constraints
              Expanded(
                child: SizedBox(
                  height: 36, // Fixed height for text field
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    textDirection: TextDirection.ltr, // Force LTR
                    textAlign: TextAlign.left, // Force left alignment
                    maxLines: 1, // SINGLE LINE ONLY
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Send button with fixed size
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  onPressed: _handleSend,
                  icon: const Icon(Icons.send, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
