import 'package:google_generative_ai/google_generative_ai.dart';

/// Direct Gemini service that works immediately without complex initialization
class DirectGeminiService {
  static const String apiKey = 'AIzaSyAsY0c9WCzzoo0j2ndTUaJ6XsmH7fK_YAM';
  
  static Future<String> chat(String message) async {
    try {
      print('🚀 Direct Gemini: Processing "$message"');
      
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );
      
      final content = [Content.text(message)];
      final response = await model.generateContent(content);
      final text = response.text;
      
      if (text != null && text.isNotEmpty) {
        print('✅ Direct Gemini: Got response!');
        return text;
      } else {
        print('⚠️ Direct Gemini: Empty response');
        return 'I apologize, but I couldn\'t generate a response. Please try again.';
      }
    } catch (e) {
      print('❌ Direct Gemini Error: $e');
      return 'Error connecting to Gemini AI: ${e.toString()}';
    }
  }
}
