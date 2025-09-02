import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:clean_flutter/core/services/ai_api_service.dart';
import 'package:clean_flutter/core/services/chat_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExpertMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool hasCode;
  final List<CodeBlock>? codeBlocks;
  final Map<String, dynamic>? metadata;
  final List<String>? suggestions;

  ExpertMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.hasCode = false,
    this.codeBlocks,
    this.metadata,
    this.suggestions,
  });
}

class CodeBlock {
  final String language;
  final String code;
  final String? description;

  CodeBlock({
    required this.language,
    required this.code,
    this.description,
  });
}

class AIEngineeringExpertService extends ChangeNotifier {
  final List<ExpertMessage> _messages = [];
  bool _isTyping = false;
  String _currentMode = 'engineering';
  
  // Enhanced features
  late AIApiService _aiApiService;
  ChatStorageService? _storageService;
  final List<Map<String, dynamic>> _conversationContext = [];
  final int _maxContextSize = 10;
  StreamSubscription<String>? _currentStream;
  final StringBuffer _streamBuffer = StringBuffer();
  bool _isStreaming = false;
  String? _currentSessionId;

  List<ExpertMessage> get messages => _messages;
  bool get isTyping => _isTyping;
  bool get isStreaming => _isStreaming;
  String? get currentSessionId => _currentSessionId;

  AIEngineeringExpertService() {
    _aiApiService = AIApiService();
    _initializeStorage();
  }
  
  Future<void> _initializeStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _storageService = ChatStorageService(prefs);
      await loadLastSession();
    } catch (e) {
      print('Failed to initialize storage: $e');
    }
  }

  void sendMessage(String content, {String mode = 'engineering', bool useAI = true}) {
    _currentMode = mode;
    
    // Add user message
    final userMessage = ExpertMessage(
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    
    // Update context
    _updateContext('user', content);
    
    // Save to storage
    _saveMessages();
    notifyListeners();
    
    if (useAI && _aiApiService.hasValidApiKey) {
      _streamAIResponse(content);
    } else {
      // Fallback to simulated response
      _isTyping = true;
      notifyListeners();
      
      Future.delayed(const Duration(seconds: 2), () {
        _generateExpertResponse(content, mode);
      });
    }
  }
  
  void _streamAIResponse(String content) async {
    _isStreaming = true;
    _isTyping = true;
    _streamBuffer.clear();
    notifyListeners();
    
    // Create initial AI message
    final aiMessage = ExpertMessage(
      content: '',
      isUser: false,
      timestamp: DateTime.now(),
      metadata: {'mode': _currentMode, 'streaming': true},
    );
    _messages.add(aiMessage);
    
    try {
      final systemPrompt = _getSystemPrompt();
      
      _currentStream = _aiApiService.streamCompletion(
        prompt: content,
        messages: _conversationContext,
        systemPrompt: systemPrompt,
        temperature: 0.7,
        maxTokens: 2048,
      ).listen(
        (chunk) {
          _streamBuffer.write(chunk);
          // Update the last message with streamed content
          _messages.last = ExpertMessage(
            content: _streamBuffer.toString(),
            isUser: false,
            timestamp: aiMessage.timestamp,
            metadata: aiMessage.metadata,
          );
          notifyListeners();
        },
        onDone: () {
          _isStreaming = false;
          _isTyping = false;
          _updateContext('assistant', _streamBuffer.toString());
          _saveMessages();
          notifyListeners();
        },
        onError: (error) {
          _isStreaming = false;
          _isTyping = false;
          _messages.last = ExpertMessage(
            content: 'Error: Failed to get AI response. $error',
            isUser: false,
            timestamp: aiMessage.timestamp,
            metadata: {'error': true},
          );
          notifyListeners();
        },
      );
    } catch (e) {
      _isStreaming = false;
      _isTyping = false;
      _messages.add(ExpertMessage(
        content: 'Error: Failed to connect to AI service. $e',
        isUser: false,
        timestamp: DateTime.now(),
        metadata: {'error': true},
      ));
      notifyListeners();
    }
  }
  
  String _getSystemPrompt() {
    const basePrompt = '''You are an advanced AI Engineering Expert with deep knowledge in:
- Software architecture and design patterns
- Full-stack development (Flutter, React, Node.js, Python, etc.)
- Performance optimization and debugging
- Security best practices
- Code review and refactoring
- DevOps and CI/CD
- Database design and optimization
- API design and integration
- Testing strategies

Provide expert-level, actionable advice with code examples when relevant.''';
    
    final modePrompts = {
      'engineering': 'Focus on practical engineering solutions and best practices.',
      'architecture': 'Emphasize system design, scalability, and architectural patterns.',
      'debugging': 'Help identify and fix bugs, provide debugging strategies.',
      'optimization': 'Focus on performance improvements and optimization techniques.',
      'security': 'Prioritize security considerations and vulnerability prevention.',
      'review': 'Provide thorough code review with constructive feedback.',
    };
    
    return '$basePrompt\n\nCurrent mode: $_currentMode\n${modePrompts[_currentMode] ?? ""}';
  }
  
  void _updateContext(String role, String content) {
    _conversationContext.add({
      'role': role,
      'content': content,
    });
    
    // Keep context size manageable
    if (_conversationContext.length > _maxContextSize) {
      _conversationContext.removeAt(0);
    }
  }

  void _generateExpertResponse(String userMessage, String mode) {
    final lowerMessage = userMessage.toLowerCase();
    ExpertMessage response;

    if (lowerMessage.contains('rest api') || lowerMessage.contains('api')) {
      response = _generateAPIResponse();
    } else if (lowerMessage.contains('flutter') || lowerMessage.contains('widget')) {
      response = _generateFlutterResponse();
    } else if (lowerMessage.contains('debug') || lowerMessage.contains('error')) {
      response = _generateDebugResponse();
    } else if (lowerMessage.contains('optimize') || lowerMessage.contains('performance')) {
      response = _generateOptimizationResponse();
    } else if (lowerMessage.contains('security') || lowerMessage.contains('audit')) {
      response = _generateSecurityResponse();
    } else {
      response = _generateGenericExpertResponse(mode);
    }

    _messages.add(response);
    _isTyping = false;
    notifyListeners();
  }

  ExpertMessage _generateAPIResponse() {
    return ExpertMessage(
      content: 'I\'ve designed a comprehensive REST API solution with authentication, rate limiting, and error handling.',
      isUser: false,
      timestamp: DateTime.now(),
      hasCode: true,
      codeBlocks: [
        CodeBlock(
          language: 'javascript',
          code: '''const express = require('express');
const jwt = require('jsonwebtoken');
const app = express();

// Authentication middleware
const authenticate = (req, res, next) => {
  const token = req.headers['authorization']?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token' });
  
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch (error) {
    res.status(403).json({ error: 'Invalid token' });
  }
};

// Protected route
app.get('/api/users/:id', authenticate, async (req, res) => {
  const user = await User.findById(req.params.id);
  res.json(user);
});''',
        ),
      ],
      metadata: {'mode': 'engineering', 'confidence': 98},
      suggestions: [
        'Add input validation',
        'Implement refresh tokens',
        'Add Swagger documentation',
      ],
    );
  }

  ExpertMessage _generateFlutterResponse() {
    return ExpertMessage(
      content: 'Here\'s an optimized Flutter widget with best practices:',
      isUser: false,
      timestamp: DateTime.now(),
      hasCode: true,
      codeBlocks: [
        CodeBlock(
          language: 'dart',
          code: '''class OptimizedWidget extends StatefulWidget {
  final String title;
  final VoidCallback onTap;
  
  const OptimizedWidget({
    Key? key,
    required this.title,
    required this.onTap,
  }) : super(key: key);
  
  @override
  State<OptimizedWidget> createState() => _OptimizedWidgetState();
}

class _OptimizedWidgetState extends State<OptimizedWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_controller.value * 0.1),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.purple],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(widget.title),
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
}''',
        ),
      ],
      metadata: {'mode': 'engineering', 'confidence': 96},
      suggestions: [
        'Add gesture detection',
        'Implement state management',
        'Add accessibility features',
      ],
    );
  }

  ExpertMessage _generateDebugResponse() {
    return ExpertMessage(
      content: 'I\'ve identified the issue. Here\'s a debugging solution:',
      isUser: false,
      timestamp: DateTime.now(),
      hasCode: true,
      codeBlocks: [
        CodeBlock(
          language: 'dart',
          code: '''class DebugHelper {
  static void log(String msg, {dynamic data}) {
    final ts = DateTime.now().toIso8601String();
    print('[\\\$ts] DEBUG: \\\$msg');
    if (data != null) {
      print('Data: \\\${data.toString()}');
    }
  }
  
  static void traceFunction(String funcName, Function fn) {
    final sw = Stopwatch()..start();
    try {
      log('Entering: \\\$funcName');
      fn();
      log('Completed: \\\$funcName (\\\${sw.elapsedMilliseconds}ms)');
    } catch (err, stack) {
      log('Error in \\\$funcName: \\\$err');
      print(stack);
      rethrow;
    }
  }
}''',
        ),
      ],
      metadata: {'mode': 'debugging', 'confidence': 95},
      suggestions: [
        'Add network interceptor',
        'Implement crash reporting',
        'Add memory leak detection',
      ],
    );
  }

  ExpertMessage _generateOptimizationResponse() {
    return ExpertMessage(
      content: 'Performance analysis complete. Here are key optimizations:',
      isUser: false,
      timestamp: DateTime.now(),
      hasCode: true,
      codeBlocks: [
        CodeBlock(
          language: 'dart',
          code: '''// Memoization for expensive operations
class MemoizedCache<T> {
  final Map<String, T> _cache = {};
  final Duration expiry;
  
  MemoizedCache({this.expiry = const Duration(minutes: 5)});
  
  Future<T> get(String key, Future<T> Function() fetcher) async {
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }
    final value = await fetcher();
    _cache[key] = value;
    Future.delayed(expiry, () => _cache.remove(key));
    return value;
  }
}

// Debounced search
class DebouncedSearch {
  Timer? _timer;
  
  void search(String query, Function(String) onSearch) {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 500), () {
      onSearch(query);
    });
  }
}''',
        ),
      ],
      metadata: {'mode': 'optimization', 'confidence': 97},
      suggestions: [
        'Implement lazy loading',
        'Add virtual scrolling',
        'Optimize bundle size',
      ],
    );
  }

  ExpertMessage _generateSecurityResponse() {
    return ExpertMessage(
      content: 'Security audit complete. Critical improvements implemented:',
      isUser: false,
      timestamp: DateTime.now(),
      hasCode: true,
      codeBlocks: [
        CodeBlock(
          language: 'dart',
          code: '''import 'package:crypto/crypto.dart';

class SecurityManager {
  // Input validation
  static bool validateEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}\$').hasMatch(email);
  }
  
  // Password hashing
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }
  
  // Rate limiting
  static final Map<String, List<DateTime>> _attempts = {};
  
  static bool checkRateLimit(String id, {int max = 5}) {
    final now = DateTime.now();
    final list = _attempts[id] ?? [];
    list.removeWhere((t) => now.difference(t).inMinutes > 15);
    
    if (list.length >= max) return false;
    list.add(now);
    _attempts[id] = list;
    return true;
  }
  
  // XSS protection
  static String sanitize(String input) {
    return input
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
  }
}''',
        ),
      ],
      metadata: {'mode': 'security', 'confidence': 98},
      suggestions: [
        'Add encryption at rest',
        'Implement 2FA',
        'Add security headers',
      ],
    );
  }

  ExpertMessage _generateGenericExpertResponse(String mode) {
    final responses = {
      'engineering': 'Let me architect a scalable solution for your requirement...',
      'architecture': 'I\'ll design a clean architecture with proper separation of concerns...',
      'debugging': 'I\'ll help you trace through the execution to find the issue...',
      'optimization': 'Let me analyze the performance bottlenecks...',
      'security': 'I\'ll perform a comprehensive security audit...',
      'review': 'Let me review your code for improvements...',
    };

    return ExpertMessage(
      content: responses[mode] ?? 'I\'ll help you with this technical challenge...',
      isUser: false,
      timestamp: DateTime.now(),
      metadata: {'mode': mode, 'confidence': 90},
      suggestions: [
        'Provide more specific details',
        'Share your current implementation',
        'Describe the expected behavior',
      ],
    );
  }

  void clearChat() {
    _messages.clear();
    _conversationContext.clear();
    _currentSessionId = null;
    _saveMessages();
    notifyListeners();
  }
  
  Future<void> startNewSession({String? title}) async {
    if (_messages.isNotEmpty && _storageService != null) {
      // Save current session
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      await _storageService!.saveSession(_currentSessionId!, _messages, title: title);
    }
    clearChat();
  }
  
  Future<void> loadSession(String sessionId) async {
    if (_storageService == null) return;
    
    final messages = await _storageService!.loadSession(sessionId);
    if (messages != null) {
      _messages.clear();
      _messages.addAll(messages);
      _currentSessionId = sessionId;
      
      // Rebuild context from loaded messages
      _conversationContext.clear();
      for (final message in messages) {
        _updateContext(
          message.isUser ? 'user' : 'assistant',
          message.content,
        );
      }
      
      notifyListeners();
    }
  }
  
  Future<void> loadLastSession() async {
    if (_storageService == null) return;
    
    final messages = await _storageService!.loadMessages();
    if (messages.isNotEmpty) {
      _messages.addAll(messages);
      
      // Rebuild context
      for (final message in messages.take(_maxContextSize)) {
        _updateContext(
          message.isUser ? 'user' : 'assistant',
          message.content,
        );
      }
      
      notifyListeners();
    }
  }
  
  Future<Map<String, dynamic>> getSessions() async {
    if (_storageService == null) return {};
    return await _storageService!.loadSessions();
  }
  
  Future<void> deleteSession(String sessionId) async {
    if (_storageService == null) return;
    await _storageService!.deleteSession(sessionId);
    if (_currentSessionId == sessionId) {
      clearChat();
    }
  }
  
  Future<void> _saveMessages() async {
    if (_storageService == null) return;
    await _storageService!.saveMessages(_messages);
  }

  Future<void> exportChat({String format = 'json'}) async {
    if (_messages.isEmpty) return;
    
    try {
      String exportContent;
      String fileName;
      
      if (format == 'json') {
        exportContent = _storageService?.exportToJson(_messages) ?? 
                       jsonEncode(_messages.map((m) => {
                         'content': m.content,
                         'isUser': m.isUser,
                         'timestamp': m.timestamp.toIso8601String(),
                       }).toList());
        fileName = 'ai_chat_${DateTime.now().millisecondsSinceEpoch}.json';
      } else {
        exportContent = _storageService?.exportToMarkdown(_messages) ?? 
                       _messages.map((m) => 
                         '${m.isUser ? "User" : "AI"}: ${m.content}'
                       ).join('\n\n');
        fileName = 'ai_chat_${DateTime.now().millisecondsSinceEpoch}.md';
      }
      
      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(exportContent);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'AI Engineering Expert Chat Export',
      );
    } catch (e) {
      print('Error exporting chat: $e');
    }
  }
  
  void setApiKey(String provider, String apiKey) {
    if (provider == 'openai') {
      _aiApiService.setApiKeys(openAIKey: apiKey);
    } else if (provider == 'claude') {
      _aiApiService.setApiKeys(claudeKey: apiKey);
    }
    _aiApiService.setActiveProvider(provider);
  }
  
  bool get hasApiKey => _aiApiService.hasValidApiKey;
  
  void cancelStream() {
    _currentStream?.cancel();
    _currentStream = null;
    _isStreaming = false;
    _isTyping = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _currentStream?.cancel();
    super.dispose();
  }
}
