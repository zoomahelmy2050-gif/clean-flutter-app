import 'dart:async';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/ai_config.dart';

/// Service for integrating Google's Gemini AI into the security management system
class GeminiAIService {
  GenerativeModel? _model;
  ChatSession? _chatSession;
  bool _isInitialized = false;
  
  /// Initialize the Gemini AI service
  Future<bool> initialize() async {
    try {
      print('🔧 Initializing Gemini AI Service...');
      
      final apiKey = await AIConfig.getGeminiApiKey();
      print('🔑 API Key retrieved: ${apiKey != null && apiKey.isNotEmpty ? "✅ Valid" : "❌ Missing"}');
      
      if (apiKey == null || apiKey.isEmpty) {
        print('❌ ERROR: Gemini API key not configured!');
        throw Exception('Gemini API key not configured');
      }
      
      print('📡 Creating Gemini model instance...');
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(_getSystemPrompt()),
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 2048,
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
        ],
      );
      
      print('💬 Starting chat session...');
      _chatSession = _model!.startChat();
      _isInitialized = true;
      print('✅ Gemini AI Service initialized successfully!');
      return true;
    } catch (e) {
      print('❌ Failed to initialize Gemini AI: $e');
      print('Stack trace: ${StackTrace.current}');
      _isInitialized = false;
      return false;
    }
  }
  
  /// Generate AI response for security management context
  Future<String> generateSecurityResponse(String userMessage, {
    Map<String, dynamic>? context,
    List<String>? conversationHistory,
  }) async {
    print('🤖 generateSecurityResponse called for: "$userMessage"');
    
    if (!_isInitialized || _chatSession == null) {
      await initialize();
    }
    
    if (!_isInitialized || _chatSession == null) {
      print('⚠️ Gemini not initialized, returning fallback');
      return _getFallbackResponse(userMessage);
    }
    
    try {
      // Build context-aware prompt
      final contextualPrompt = _buildContextualPrompt(userMessage, context, conversationHistory);
      
      print('📤 Sending message to Gemini AI...');
      final response = await _chatSession!.sendMessage(Content.text(contextualPrompt));
      final responseText = response.text;
      
      if (responseText != null && responseText.isNotEmpty) {
        print('✅ Received Gemini response: ${responseText.substring(0, responseText.length.clamp(0, 100))}...');
        return responseText;
      } else {
        print('⚠️ Empty response from Gemini, using fallback');
        return _getFallbackResponse(userMessage);
      }
    } catch (e) {
      print('Gemini AI error: $e');
      return _getFallbackResponse(userMessage);
    }
  }
  
  /// Generate response for specific security actions
  Future<String> generateActionResponse(String action, Map<String, dynamic> parameters) async {
    if (!_isInitialized || _model == null) {
      await initialize();
    }
    
    if (!_isInitialized || _model == null) {
      return _getFallbackActionResponse(action, parameters);
    }
    
    try {
      final prompt = _buildActionPrompt(action, parameters);
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? _getFallbackActionResponse(action, parameters);
      
    } catch (e) {
      print('Gemini AI action error: $e');
      return _getFallbackActionResponse(action, parameters);
    }
  }
  
  /// Generate security insights and recommendations
  Future<String> generateSecurityInsights(Map<String, dynamic> systemData) async {
    if (!_isInitialized || _model == null) {
      await initialize();
    }
    
    if (!_isInitialized || _model == null) {
      return 'Security analysis temporarily unavailable. Please check system status.';
    }
    
    try {
      final prompt = '''
Analyze the following security system data and provide insights:

System Data: ${systemData.toString()}

Please provide:
1. Security risk assessment
2. Recommended actions
3. Potential vulnerabilities
4. Best practices suggestions

Format your response professionally with clear sections and actionable recommendations.
''';
      
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to generate security insights at this time.';
      
    } catch (e) {
      print('Gemini AI insights error: $e');
      return 'Security analysis encountered an error. Please try again later.';
    }
  }
  
  /// Build system prompt for security management context
  String _getSystemPrompt() {
    return '''
You are an AI assistant for a comprehensive Security Management Center. Your role is to help administrators manage:

- User accounts and permissions (RBAC)
- Security policies and configurations
- Threat monitoring and incident response
- Workflow automation and processes
- System analytics and reporting

Key Guidelines:
1. Always prioritize security best practices
2. Provide clear, actionable recommendations
3. Use professional, helpful tone
4. Include relevant security warnings when appropriate
5. Format responses with emojis and clear structure
6. Suggest specific actions when possible
7. Consider compliance and audit requirements

You have access to:
- User management systems
- Security monitoring tools
- Workflow automation
- Analytics and reporting
- Real-time system status

Always be security-conscious and provide expert-level guidance for enterprise security management.
''';
  }
  
  /// Build contextual prompt with conversation history
  String _buildContextualPrompt(String userMessage, Map<String, dynamic>? context, List<String>? history) {
    final buffer = StringBuffer();
    
    // Add context if available
    if (context != null && context.isNotEmpty) {
      buffer.writeln('Current Context:');
      context.forEach((key, value) {
        buffer.writeln('- $key: $value');
      });
      buffer.writeln();
    }
    
    // Add recent conversation history
    if (history != null && history.isNotEmpty) {
      buffer.writeln('Recent Conversation:');
      for (final message in history.take(5)) {
        buffer.writeln('- $message');
      }
      buffer.writeln();
    }
    
    buffer.writeln('User Message: $userMessage');
    buffer.writeln();
    buffer.writeln('Please provide a helpful, security-focused response as an expert security management assistant.');
    
    return buffer.toString();
  }
  
  /// Build prompt for specific actions
  String _buildActionPrompt(String action, Map<String, dynamic> parameters) {
    return '''
Security Action: $action
Parameters: ${parameters.toString()}

As a security management expert, please:
1. Explain what this action does
2. Highlight any security implications
3. Suggest best practices
4. Provide status update format

Keep the response professional and actionable.
''';
  }
  
  /// Fallback response when AI is unavailable
  String _getFallbackResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();
    
    if (lowerMessage.contains('hello') || lowerMessage.contains('hi')) {
      return '''Hello! 👋 I'm your AI security assistant. 

I'm here to help you manage your security center. I can assist with:
🔐 Security monitoring and analysis
👥 User management and permissions  
⚡ Workflow automation
📊 System analytics and reporting

How can I help you today?''';
    }
    
    if (lowerMessage.contains('security') || lowerMessage.contains('scan')) {
      return '''🔒 Security Management Available

I can help you with:
• Running security scans and assessments
• Configuring security policies
• Monitoring threats and incidents
• Managing user access and permissions

What specific security task would you like assistance with?''';
    }
    
    if (lowerMessage.contains('user') || lowerMessage.contains('account')) {
      return '''👥 User Management Services

I can assist with:
• Creating and managing user accounts
• Setting up role-based permissions
• Monitoring user activity
• Handling authentication issues

What user management task can I help you with?''';
    }
    
    return '''I'm your AI security assistant! 🛡️

I can help you with:
• Security monitoring and threat analysis
• User account management
• System configuration and policies
• Workflow automation
• Analytics and reporting

Please let me know what you'd like to work on, and I'll provide expert guidance!''';
  }
  
  /// Fallback response for actions when AI is unavailable
  String _getFallbackActionResponse(String action, Map<String, dynamic> parameters) {
    switch (action) {
      case 'create_user':
        return '✅ User creation initiated with the provided parameters. The new user account will be set up with appropriate permissions based on the specified role.';
      case 'delete_user':
        return '⚠️ User deletion process started. Please ensure you have proper authorization and consider backing up user data before permanent removal.';
      case 'security_scan':
        return '🔍 Security scan launched. The system will perform a comprehensive security assessment and provide detailed results upon completion.';
      case 'configure_security':
        return '🔧 Security configuration update in progress. Changes will be applied according to your security policies and best practices.';
      case 'create_workflow':
        return '⚡ Workflow creation process initiated. The new automation workflow will be configured based on your specified triggers and actions.';
      case 'execute_workflow':
        return '🚀 Workflow execution started. The automated process will run according to the defined steps and parameters.';
      case 'system_status':
        return '📊 System status check completed. All critical components are being monitored for performance and security.';
      case 'generate_report':
        return '📋 Report generation in progress. Your comprehensive security report will be available shortly with detailed analytics and recommendations.';
      default:
        return '✨ Action processed successfully. The system has executed your request according to security best practices.';
    }
  }
  
  /// Check if the service is properly initialized
  bool get isInitialized => _isInitialized;
  
  /// Dispose of resources
  void dispose() {
    _chatSession = null;
    _model = null;
    _isInitialized = false;
  }
}
