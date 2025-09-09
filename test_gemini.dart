import 'dart:io';
import 'lib/core/config/ai_config.dart';
import 'lib/core/services/gemini_ai_service.dart';

void main() async {
  print('🧪 Testing Gemini AI Integration\n');
  print('='*50);
  
  // Initialize AI Config
  print('\n1️⃣ Initializing AI Config...');
  await AIConfig.initialize();
  
  // Check API key
  print('\n2️⃣ Checking API Key...');
  final apiKey = await AIConfig.getGeminiApiKey();
  if (apiKey != null && apiKey.isNotEmpty) {
    print('✅ API Key found: ${apiKey.substring(0, 10)}...');
  } else {
    print('❌ NO API KEY FOUND!');
    exit(1);
  }
  
  // Initialize Gemini Service
  print('\n3️⃣ Initializing Gemini Service...');
  final geminiService = GeminiAIService();
  final initialized = await geminiService.initialize();
  
  if (!initialized) {
    print('❌ FAILED to initialize Gemini!');
    print('Check console output above for errors');
    exit(1);
  }
  
  print('✅ Gemini initialized successfully!');
  
  // Test a simple query
  print('\n4️⃣ Testing AI Response...');
  print('Query: "Hello, how are you?"');
  
  final response = await geminiService.generateSecurityResponse(
    'Hello, how are you?',
    context: {'test': true},
  );
  
  print('\n📝 Response:');
  print(response);
  
  print('\n' + '='*50);
  
  // Check if it's a real AI response or fallback
  if (response.contains('I\'m your AI security assistant')) {
    print('⚠️ WARNING: This looks like a FALLBACK response!');
    print('Gemini might not be working properly.');
  } else {
    print('✅ SUCCESS: Real Gemini AI response received!');
  }
  
  exit(0);
}
