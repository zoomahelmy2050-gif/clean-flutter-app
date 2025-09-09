import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onSend;

  const ChatInputWidget({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
  }) : super(key: key);

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  bool _isRecording = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _handleSend() {
    final text = widget.controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
    }
  }

  void _toggleVoiceInput() {
    setState(() => _isRecording = !_isRecording);
    if (_isRecording) {
      // Start voice recording
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice input started...'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      // Stop voice recording
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice input stopped'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Attach Image'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Image attachment coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_copy),
              title: const Text('Attach File'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File attachment coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Code Snippet'),
              onTap: () {
                Navigator.pop(context);
                _showCodeSnippetDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCodeSnippetDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Code Snippet'),
        content: TextField(
          controller: codeController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Paste your code here...',
            border: OutlineInputBorder(),
          ),
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (codeController.text.isNotEmpty) {
                widget.controller.text = '```\n${codeController.text}\n```';
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Recording indicator
            if (_isRecording)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Recording...',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Input row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attach button
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: IconButton(
                    icon: const Icon(Icons.attach_file, size: 20),
                    onPressed: _showAttachmentOptions,
                    tooltip: 'Attach',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ),
                
                const SizedBox(width: 4),
                
                // Input field
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 40,
                      maxHeight: 100,
                    ),
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      decoration: InputDecoration(
                        hintText: 'Message AI Assistant...',
                        hintStyle: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 14),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _handleSend(),
                      minLines: 1,
                      maxLines: 4,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(2000),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 4),
                
                // Send/Voice button
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _hasText
                        ? Container(
                            key: const ValueKey('send'),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.send, size: 18),
                              onPressed: _handleSend,
                              color: Colors.white,
                              tooltip: 'Send',
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                            ),
                          )
                        : IconButton(
                            key: const ValueKey('mic'),
                            icon: Icon(
                              _isRecording ? Icons.stop : Icons.mic,
                              color: _isRecording ? Colors.red : theme.iconTheme.color,
                              size: 20,
                            ),
                            onPressed: _toggleVoiceInput,
                            tooltip: _isRecording ? 'Stop Recording' : 'Voice Input',
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }
}
