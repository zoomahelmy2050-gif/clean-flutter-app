import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clean_flutter/features/admin/services/ai_engineering_expert_service.dart';

class ChatStorageService {
  static const String _chatHistoryKey = 'ai_chat_history';
  static const String _chatSessionsKey = 'ai_chat_sessions';
  static const int _maxHistorySize = 100;
  static const int _maxSessions = 10;
  
  final SharedPreferences _prefs;
  
  ChatStorageService(this._prefs);

  // Save chat messages
  Future<void> saveMessages(List<ExpertMessage> messages) async {
    try {
      final messagesJson = messages.map((m) => _messageToJson(m)).toList();
      
      // Keep only the last _maxHistorySize messages
      if (messagesJson.length > _maxHistorySize) {
        messagesJson.removeRange(0, messagesJson.length - _maxHistorySize);
      }
      
      await _prefs.setString(_chatHistoryKey, jsonEncode(messagesJson));
    } catch (e) {
      print('Error saving messages: $e');
    }
  }

  // Load chat messages
  Future<List<ExpertMessage>> loadMessages() async {
    try {
      final String? historyString = _prefs.getString(_chatHistoryKey);
      if (historyString == null) return [];
      
      final List<dynamic> historyJson = jsonDecode(historyString);
      return historyJson.map((json) => _messageFromJson(json)).toList();
    } catch (e) {
      print('Error loading messages: $e');
      return [];
    }
  }

  // Save a chat session
  Future<void> saveSession(String sessionId, List<ExpertMessage> messages, {String? title}) async {
    try {
      final sessions = await loadSessions();
      
      sessions[sessionId] = {
        'id': sessionId,
        'title': title ?? 'Chat Session ${DateTime.now().toIso8601String()}',
        'timestamp': DateTime.now().toIso8601String(),
        'messageCount': messages.length,
        'messages': messages.map((m) => _messageToJson(m)).toList(),
      };
      
      // Keep only the last _maxSessions
      if (sessions.length > _maxSessions) {
        final sortedKeys = sessions.keys.toList()
          ..sort((a, b) => sessions[b]['timestamp'].compareTo(sessions[a]['timestamp']));
        
        for (int i = _maxSessions; i < sortedKeys.length; i++) {
          sessions.remove(sortedKeys[i]);
        }
      }
      
      await _prefs.setString(_chatSessionsKey, jsonEncode(sessions));
    } catch (e) {
      print('Error saving session: $e');
    }
  }

  // Load all chat sessions
  Future<Map<String, dynamic>> loadSessions() async {
    try {
      final String? sessionsString = _prefs.getString(_chatSessionsKey);
      if (sessionsString == null) return {};
      
      return Map<String, dynamic>.from(jsonDecode(sessionsString));
    } catch (e) {
      print('Error loading sessions: $e');
      return {};
    }
  }

  // Load a specific session
  Future<List<ExpertMessage>?> loadSession(String sessionId) async {
    try {
      final sessions = await loadSessions();
      if (!sessions.containsKey(sessionId)) return null;
      
      final sessionData = sessions[sessionId];
      final messages = sessionData['messages'] as List;
      
      return messages.map((json) => _messageFromJson(json)).toList();
    } catch (e) {
      print('Error loading session $sessionId: $e');
      return null;
    }
  }

  // Delete a session
  Future<void> deleteSession(String sessionId) async {
    try {
      final sessions = await loadSessions();
      sessions.remove(sessionId);
      await _prefs.setString(_chatSessionsKey, jsonEncode(sessions));
    } catch (e) {
      print('Error deleting session: $e');
    }
  }

  // Clear all chat history
  Future<void> clearAllHistory() async {
    await _prefs.remove(_chatHistoryKey);
    await _prefs.remove(_chatSessionsKey);
  }

  // Export chat to JSON
  String exportToJson(List<ExpertMessage> messages) {
    final exportData = {
      'exportDate': DateTime.now().toIso8601String(),
      'messageCount': messages.length,
      'messages': messages.map((m) => _messageToJson(m)).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  // Export chat to Markdown
  String exportToMarkdown(List<ExpertMessage> messages) {
    final buffer = StringBuffer();
    buffer.writeln('# AI Engineering Expert Chat Export');
    buffer.writeln('**Date:** ${DateTime.now().toIso8601String()}');
    buffer.writeln('**Total Messages:** ${messages.length}');
    buffer.writeln('\n---\n');
    
    for (final message in messages) {
      buffer.writeln('## ${message.isUser ? "User" : "AI Expert"}');
      buffer.writeln('*${message.timestamp.toIso8601String()}*\n');
      buffer.writeln(message.content);
      
      if (message.hasCode && message.codeBlocks != null) {
        for (final block in message.codeBlocks!) {
          buffer.writeln('\n```${block.language}');
          buffer.writeln(block.code);
          buffer.writeln('```\n');
        }
      }
      
      if (message.suggestions != null && message.suggestions!.isNotEmpty) {
        buffer.writeln('\n**Suggestions:**');
        for (final suggestion in message.suggestions!) {
          buffer.writeln('- $suggestion');
        }
      }
      
      buffer.writeln('\n---\n');
    }
    
    return buffer.toString();
  }

  Map<String, dynamic> _messageToJson(ExpertMessage message) {
    return {
      'content': message.content,
      'isUser': message.isUser,
      'timestamp': message.timestamp.toIso8601String(),
      'hasCode': message.hasCode,
      'codeBlocks': message.codeBlocks?.map((block) => {
        'language': block.language,
        'code': block.code,
      }).toList(),
      'metadata': message.metadata,
      'suggestions': message.suggestions,
    };
  }

  ExpertMessage _messageFromJson(Map<String, dynamic> json) {
    return ExpertMessage(
      content: json['content'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      hasCode: json['hasCode'] ?? false,
      codeBlocks: json['codeBlocks'] != null
        ? (json['codeBlocks'] as List).map((block) => CodeBlock(
            language: block['language'],
            code: block['code'],
          )).toList()
        : null,
      metadata: json['metadata'],
      suggestions: json['suggestions'] != null
        ? List<String>.from(json['suggestions'])
        : null,
    );
  }
}
