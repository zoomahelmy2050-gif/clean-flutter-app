import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure configuration service for AI integrations
class AIConfig {
  static const _storage = FlutterSecureStorage();
  static const String _geminiApiKeyKey = 'gemini_api_key';
  
  // Your Google AI Studio API key (stored securely)
  static const String _defaultGeminiApiKey = 'AIzaSyAsY0c9WCzzoo0j2ndTUaJ6XsmH7fK_YAM';
  
  /// Initialize AI configuration with secure storage
  static Future<void> initialize() async {
    // Store the API key securely on first run
    final existingKey = await _storage.read(key: _geminiApiKeyKey);
    if (existingKey == null) {
      await _storage.write(key: _geminiApiKeyKey, value: _defaultGeminiApiKey);
    }
  }
  
  /// Get the Gemini API key from secure storage
  static Future<String?> getGeminiApiKey() async {
    return await _storage.read(key: _geminiApiKeyKey);
  }
  
  /// Update the Gemini API key in secure storage
  static Future<void> setGeminiApiKey(String apiKey) async {
    await _storage.write(key: _geminiApiKeyKey, value: apiKey);
  }
  
  /// Check if Gemini API key is configured
  static Future<bool> isGeminiConfigured() async {
    final apiKey = await getGeminiApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }
  
  /// Clear all AI configuration
  static Future<void> clearConfiguration() async {
    await _storage.delete(key: _geminiApiKeyKey);
  }
}
