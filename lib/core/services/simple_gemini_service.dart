import 'package:google_generative_ai/google_generative_ai.dart';

class SimpleGeminiService {
  GenerativeModel? _model;
  bool _initialized = false;
  
  // Hardcode the API key temporarily for testing
  static const String _apiKey = 'AIzaSyAsY0c9WCzzoo0j2ndTUaJ6XsmH7fK_YAM';
  
  Future<bool> initialize() async {
    try {
      print('🔧 Initializing Simple Gemini Service...');
      
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );
      
      _initialized = true;
      print('✅ Simple Gemini initialized!');
      return true;
    } catch (e) {
      print('❌ Failed to initialize: $e');
      return false;
    }
  }
  
  Future<String> chat(String message) async {
    if (!_initialized) {
      await initialize();
    }
    
    if (_model == null) {
      return 'Sorry, AI is not available right now.';
    }
    
    try {
      print('📤 Sending to Gemini: "$message"');
      final content = [Content.text(message)];
      final response = await _model!.generateContent(content);
      final text = response.text ?? 'No response from AI';
      print('✅ Got response: ${text.substring(0, text.length.clamp(0, 50))}...');
      return text;
    } catch (e) {
      print('❌ Error: $e');
      return 'Error: Could not get AI response - $e';
    }
  }
  
  bool get isInitialized => _initialized;
}
