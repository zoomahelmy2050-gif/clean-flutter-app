import 'package:flutter/widgets.dart';
import 'dart:math';

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? category;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.category,
  });
}

class GeneralAIChatService extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  final _random = Random();
  
  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;

  List<String> getSuggestions() {
    return [
      'Tell me a joke',
      'What can you help me with?',
      'Explain quantum computing',
      'Write a short story',
      'How does photosynthesis work?',
      'What are the latest tech trends?',
      'Help me with coding',
      'Explain machine learning',
      'What is the meaning of life?',
      'Tell me about space exploration',
      'Translate something for me',
      'Give me a recipe',
    ];
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    
    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    _messages.add(userMessage);
    _isTyping = true;
    notifyListeners();
    
    // Simulate AI response time
    await Future.delayed(Duration(milliseconds: 1000 + _random.nextInt(1500)));
    
    final response = _generateResponse(content);
    
    final aiMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: response,
      isUser: false,
      timestamp: DateTime.now(),
    );
    
    _messages.add(aiMessage);
    _isTyping = false;
    notifyListeners();
  }

  String _generateResponse(String query) {
    final lowerQuery = query.toLowerCase();
    
    // Jokes
    if (lowerQuery.contains('joke')) {
      final jokes = [
        "Why don't scientists trust atoms? Because they make up everything! 😄",
        "Why did the scarecrow win an award? He was outstanding in his field! 🌾",
        "Why don't eggs tell jokes? They'd crack each other up! 🥚",
        "What do you call a bear with no teeth? A gummy bear! 🐻",
        "Why did the math book look so sad? Because it had too many problems! 📚",
      ];
      return jokes[_random.nextInt(jokes.length)] + "\n\nWant to hear another one?";
    }
    
    // Help/Capabilities
    if (lowerQuery.contains('help') || lowerQuery.contains('what can you')) {
      return """I'm your friendly AI assistant! I can help you with:

• 💬 General conversation and chat
• 📚 Explaining complex topics simply
• ✍️ Creative writing and storytelling
• 💻 Coding and technical help
• 🎯 Problem-solving and brainstorming
• 🔬 Science and technology questions
• 🎨 Creative ideas and inspiration
• 🧮 Math and calculations
• 🌍 General knowledge and facts

Just ask me anything! I'm here to chat and help.""";
    }
    
    // Quantum computing
    if (lowerQuery.contains('quantum')) {
      return """Quantum computing is fascinating! Here's a simple explanation:

Traditional computers use bits that are either 0 or 1. Quantum computers use quantum bits (qubits) that can be 0, 1, or both at the same time through "superposition."

Think of it like this: If you're looking for a specific book in a library, a regular computer checks each book one by one. A quantum computer could check multiple books simultaneously!

Key concepts:
• **Superposition**: Being in multiple states at once
• **Entanglement**: Qubits can be mysteriously connected
• **Quantum advantage**: Solving certain problems exponentially faster

Potential applications include drug discovery, cryptography, weather prediction, and optimization problems.

Would you like me to explain any specific aspect in more detail?""";
    }
    
    // Story writing
    if (lowerQuery.contains('story')) {
      return """Here's a short story for you:

**The Last Library**

In the year 2145, Maya discovered something extraordinary in the ruins of old Tokyo - a physical library. Books made of paper, not holograms or neural downloads.

She touched the dusty spines, feeling the texture her generation had never known. Opening a random book, she found handwritten notes in the margins - someone's thoughts from a century ago.

"Books were conversations across time," her grandmother had said. Now Maya understood. Each annotation was a voice reaching through decades, sharing wonder, disagreement, or simple joy.

She sat among the ruins and began to read, connecting with minds long gone, discovering that some things - curiosity, love, hope - never change.

Would you like me to write another story or continue this one?""";
    }
    
    // Photosynthesis
    if (lowerQuery.contains('photosynth')) {
      return """Photosynthesis is how plants make their own food using sunlight! 🌱

**Simple explanation:**
Plants are like natural solar panels. They capture sunlight and use it to turn water and carbon dioxide into sugar (their food) and oxygen (what we breathe).

**The equation:**
6CO₂ + 6H₂O + light energy → C₆H₁₂O₆ + 6O₂
(Carbon dioxide + Water + Light → Sugar + Oxygen)

**Two main stages:**
1. **Light reactions** - Capture solar energy in chloroplasts
2. **Calvin cycle** - Use that energy to make sugar

**Fun fact:** All the oxygen we breathe comes from photosynthesis - both from plants on land and algae in the oceans!

It's nature's way of converting solar energy into chemical energy, powering most life on Earth. Pretty amazing, right?""";
    }
    
    // Coding help
    if (lowerQuery.contains('code') || lowerQuery.contains('programming')) {
      return """I'd love to help with coding! 💻

I can assist with:
• Writing code in various languages (Python, JavaScript, Java, C++, etc.)
• Debugging and fixing errors
• Explaining algorithms and data structures
• Code optimization and best practices
• Web development (HTML, CSS, React, etc.)
• Database queries and design
• API development
• Mobile app development

What programming challenge are you working on? Share your code or describe what you're trying to build, and I'll help you out!""";
    }
    
    // Meaning of life
    if (lowerQuery.contains('meaning of life') || lowerQuery.contains('42')) {
      return """Ah, the ultimate question! 🌟

Douglas Adams famously said the answer is 42, but the real answer varies for everyone:

**Philosophical perspectives:**
• **Existentialism**: We create our own meaning through choices
• **Stoicism**: Find meaning in virtue and wisdom
• **Buddhism**: End suffering through enlightenment
• **Humanism**: Meaning comes from human connection and progress

**My take:**
Life's meaning might be found in:
• 💝 Connections with others
• 🌱 Personal growth and learning
• 🎨 Creating something beautiful or useful
• 🤝 Making a positive impact
• 🎉 Experiencing joy and wonder

Perhaps the meaning isn't a destination but the journey itself - the experiences, relationships, and growth along the way.

What gives your life meaning?""";
    }
    
    // Tech trends
    if (lowerQuery.contains('tech') || lowerQuery.contains('trend')) {
      return """Here are the exciting tech trends right now! 🚀

**2024's Hot Topics:**
• **AI Everything**: From ChatGPT to Midjourney, AI is revolutionizing creativity and productivity
• **Quantum Computing**: Getting closer to practical applications
• **AR/VR/Metaverse**: Apple Vision Pro and Meta Quest pushing boundaries
• **Sustainable Tech**: Green energy and eco-friendly innovations
• **Biotech**: CRISPR, synthetic biology, and personalized medicine
• **Web3 & Blockchain**: Evolving beyond crypto into real utilities
• **Edge Computing**: Processing data closer to where it's created
• **Neuromorphic Computing**: Chips that mimic the human brain

The pace of innovation is incredible! What tech area interests you most?""";
    }
    
    // Space
    if (lowerQuery.contains('space')) {
      return """Space exploration is experiencing a new golden age! 🚀✨

**Recent achievements:**
• James Webb telescope revealing the early universe
• Artemis program returning to the Moon
• Mars rovers and helicopter exploring the Red Planet
• Private companies like SpaceX revolutionizing access to space

**Exciting future missions:**
• Europa Clipper to Jupiter's moon (looking for life!)
• Human Mars missions planned for 2030s
• Space tourism becoming reality
• Asteroid mining possibilities

**Mind-blowing facts:**
• There are more stars than grains of sand on Earth
• Space is completely silent (no air for sound waves)
• A day on Venus is longer than its year
• You could fit all planets between Earth and Moon

The universe is vast and full of mysteries. What aspect of space fascinates you most?""";
    }
    
    // Machine Learning
    if (lowerQuery.contains('machine learning') || lowerQuery.contains(' ml ')) {
      return """Machine Learning is teaching computers to learn from data! 🤖

**Simple explanation:**
Instead of programming exact rules, we show the computer examples and it figures out patterns itself.

**Three main types:**
1. **Supervised Learning**: Learning with labeled examples (like teaching a child with flashcards)
2. **Unsupervised Learning**: Finding patterns without labels (like sorting Legos by similarity)
3. **Reinforcement Learning**: Learning through trial and error with rewards

**Real-world applications:**
• Netflix recommendations
• Spam email filtering
• Face recognition
• Medical diagnosis
• Self-driving cars
• Voice assistants

**Getting started:**
Python with libraries like TensorFlow or PyTorch is the most popular path. Start with simple projects like digit recognition!

Want me to explain any specific ML concept?""";
    }
    
    // Default friendly response
    final responses = [
      "That's an interesting topic! While I don't have specific information about that exact query, I'm here to chat about anything. What would you like to explore - maybe something about science, creativity, or just have a fun conversation?",
      
      "Great question! I'd love to help you explore that. Could you tell me a bit more about what specifically interests you about this topic? I'm here to chat, explain, brainstorm, or just have a friendly conversation!",
      
      "I'm excited to chat with you about this! While I might not have all the answers, I'm here to think through things together. What aspect would you like to dive into?",
      
      "That sounds fascinating! I'm here to help however I can - whether it's answering questions, being creative, solving problems, or just having a good conversation. What would be most helpful for you?",
    ];
    
    return responses[_random.nextInt(responses.length)];
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }

  void dispose() {
    super.dispose();
  }
}
