import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AIApiService {
  static const String _openAIEndpoint = 'https://api.openai.com/v1/chat/completions';
  static const String _claudeEndpoint = 'https://api.anthropic.com/v1/messages';
  
  String? _openAIKey;
  String? _claudeKey;
  String _activeProvider = 'openai'; // 'openai' or 'claude'
  
  // Model configurations
  static const Map<String, String> models = {
    'openai': 'gpt-4-turbo-preview',
    'claude': 'claude-3-opus-20240229',
  };

  void setApiKeys({String? openAIKey, String? claudeKey}) {
    _openAIKey = openAIKey;
    _claudeKey = claudeKey;
  }

  void setActiveProvider(String provider) {
    if (provider == 'openai' || provider == 'claude') {
      _activeProvider = provider;
    }
  }

  bool get hasValidApiKey {
    if (_activeProvider == 'openai') return _openAIKey != null && _openAIKey!.isNotEmpty;
    if (_activeProvider == 'claude') return _claudeKey != null && _claudeKey!.isNotEmpty;
    return false;
  }

  Stream<String> streamCompletion({
    required String prompt,
    required List<Map<String, dynamic>> messages,
    String? systemPrompt,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    if (!hasValidApiKey) {
      yield 'Error: No API key configured for $_activeProvider';
      return;
    }

    try {
      if (_activeProvider == 'openai') {
        yield* _streamOpenAI(messages, systemPrompt, temperature, maxTokens);
      } else if (_activeProvider == 'claude') {
        yield* _streamClaude(messages, systemPrompt, temperature, maxTokens);
      }
    } catch (e) {
      yield 'Error: ${e.toString()}';
    }
  }

  Stream<String> _streamOpenAI(
    List<Map<String, dynamic>> messages,
    String? systemPrompt,
    double temperature,
    int maxTokens,
  ) async* {
    final requestMessages = [
      if (systemPrompt != null) {'role': 'system', 'content': systemPrompt},
      ...messages,
    ];

    final request = http.Request('POST', Uri.parse(_openAIEndpoint));
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_openAIKey',
    });

    request.body = jsonEncode({
      'model': models['openai'],
      'messages': requestMessages,
      'temperature': temperature,
      'max_tokens': maxTokens,
      'stream': true,
    });

    final response = await request.send();
    
    if (response.statusCode != 200) {
      yield 'Error: API returned status ${response.statusCode}';
      return;
    }

    await for (final chunk in response.stream.transform(utf8.decoder)) {
      final lines = chunk.split('\n');
      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') break;
          
          try {
            final json = jsonDecode(data);
            final content = json['choices']?[0]?['delta']?['content'];
            if (content != null) {
              yield content;
            }
          } catch (e) {
            // Skip invalid JSON chunks
          }
        }
      }
    }
  }

  Stream<String> _streamClaude(
    List<Map<String, dynamic>> messages,
    String? systemPrompt,
    double temperature,
    int maxTokens,
  ) async* {
    final request = http.Request('POST', Uri.parse(_claudeEndpoint));
    request.headers.addAll({
      'Content-Type': 'application/json',
      'x-api-key': _claudeKey!,
      'anthropic-version': '2023-06-01',
    });

    request.body = jsonEncode({
      'model': models['claude'],
      'messages': messages.map((m) => {
        'role': m['role'] == 'system' ? 'assistant' : m['role'],
        'content': m['content'],
      }).toList(),
      'system': systemPrompt ?? '',
      'temperature': temperature,
      'max_tokens': maxTokens,
      'stream': true,
    });

    final response = await request.send();
    
    if (response.statusCode != 200) {
      yield 'Error: API returned status ${response.statusCode}';
      return;
    }

    await for (final chunk in response.stream.transform(utf8.decoder)) {
      final lines = chunk.split('\n');
      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          
          try {
            final json = jsonDecode(data);
            if (json['type'] == 'content_block_delta') {
              final text = json['delta']?['text'];
              if (text != null) {
                yield text;
              }
            }
          } catch (e) {
            // Skip invalid JSON chunks
          }
        }
      }
    }
  }

  Future<String> getCompletion({
    required String prompt,
    required List<Map<String, dynamic>> messages,
    String? systemPrompt,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    final buffer = StringBuffer();
    await for (final chunk in streamCompletion(
      prompt: prompt,
      messages: messages,
      systemPrompt: systemPrompt,
      temperature: temperature,
      maxTokens: maxTokens,
    )) {
      buffer.write(chunk);
    }
    return buffer.toString();
  }
}
