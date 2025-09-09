import 'dart:async';
import 'dart:math';
import 'package:flutter/widgets.dart';

class AINLPProcessor {
  // Pattern recognition data
  final Map<String, List<String>> _intentPatterns = {
    'security.threat_analysis': [
      'threat', 'attack', 'malware', 'virus', 'breach', 'intrusion',
      'vulnerability', 'exploit', 'compromise', 'suspicious', 'anomaly',
      'risk', 'danger', 'security issue', 'hacking', 'phishing'
    ],
    'security.scan': [
      'scan', 'check security', 'analyze security', 'security status',
      'security assessment', 'audit', 'security review', 'test security'
    ],
    'user.management': [
      'user', 'account', 'permission', 'access', 'role', 'privilege',
      'authentication', 'authorization', 'login', 'logout', 'session',
      'create user', 'delete user', 'modify user', 'user activity'
    ],
    'user.behavior': [
      'user behavior', 'user pattern', 'activity pattern', 'usage',
      'behavior analysis', 'user tracking', 'user monitoring'
    ],
    'performance.analysis': [
      'performance', 'slow', 'speed', 'latency', 'response time',
      'throughput', 'bottleneck', 'optimization', 'resource usage',
      'cpu', 'memory', 'disk', 'network', 'load', 'capacity'
    ],
    'performance.optimize': [
      'optimize', 'improve performance', 'speed up', 'enhance',
      'boost', 'accelerate', 'tune', 'fix slow', 'reduce latency'
    ],
    'monitoring.setup': [
      'monitor', 'watch', 'track', 'observe', 'surveillance',
      'real-time monitoring', 'continuous monitoring', 'alert'
    ],
    'monitoring.status': [
      'monitoring status', 'what are you monitoring', 'active monitors',
      'monitoring dashboard', 'monitoring report'
    ],
    'investigation.forensic': [
      'investigate', 'forensic', 'incident', 'root cause', 'analyze',
      'deep dive', 'examination', 'inspection', 'trace', 'evidence'
    ],
    'investigation.timeline': [
      'timeline', 'when did', 'history', 'sequence', 'events',
      'chronology', 'what happened', 'reconstruction'
    ],
    'reporting.generate': [
      'report', 'summary', 'statistics', 'metrics', 'dashboard',
      'export', 'document', 'analysis report', 'generate report'
    ],
    'reporting.compliance': [
      'compliance', 'regulation', 'standard', 'policy', 'requirement',
      'gdpr', 'hipaa', 'pci', 'sox', 'audit report'
    ],
    'automation.create': [
      'automate', 'automation', 'workflow', 'process', 'script',
      'automatic', 'scheduled', 'trigger', 'rule', 'policy'
    ],
    'automation.manage': [
      'automation status', 'active automations', 'stop automation',
      'pause automation', 'modify automation', 'automation list'
    ],
    'system.status': [
      'system status', 'health', 'status', 'overview', 'dashboard',
      'system info', 'system health', 'uptime', 'availability'
    ],
    'system.configuration': [
      'config', 'configuration', 'settings', 'setup', 'parameter',
      'preference', 'option', 'customize', 'configure'
    ],
    'help.general': [
      'help', 'how to', 'what can', 'assist', 'guide', 'tutorial',
      'documentation', 'manual', 'instructions', 'explain'
    ],
    'help.capabilities': [
      'what can you do', 'capabilities', 'features', 'functions',
      'abilities', 'commands', 'operations'
    ]
  };
  
  // Entity patterns
  final Map<String, RegExp> _entityPatterns = {
    'user_id': RegExp(r'\b(?:user[_\s-]?(?:id)?[:\s]*)([a-zA-Z0-9_-]+)'),
    'email': RegExp(r'\b([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})\b'),
    'ip_address': RegExp(r'\b(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\b'),
    'port': RegExp(r'\b(?:port[:\s]*)(\d{1,5})\b'),
    'url': RegExp(r'https?://[^\s]+'),
    'file_path': RegExp(r'(?:[/\\][\w.-]+)+'),
    'time_relative': RegExp(r'\b(last|past|next|previous)\s+(\d+)\s+(second|minute|hour|day|week|month|year)s?\b'),
    'time_specific': RegExp(r'\b(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(am|pm)?\b', caseSensitive: false),
    'date': RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})\b'),
    'percentage': RegExp(r'\b(\d+(?:\.\d+)?)\s*%'),
    'number': RegExp(r'\b(\d+(?:\.\d+)?)\b'),
    'severity': RegExp(r'\b(critical|high|medium|low|info|debug)\b', caseSensitive: false),
  };
  
  // Sentiment patterns
  final Map<String, List<String>> _sentimentIndicators = {
    'urgent': ['urgent', 'immediately', 'asap', 'critical', 'emergency', 'now', 'quickly'],
    'negative': ['problem', 'issue', 'error', 'failed', 'broken', 'wrong', 'bad', 'not working'],
    'positive': ['good', 'great', 'excellent', 'perfect', 'working', 'success', 'resolved'],
    'questioning': ['why', 'how', 'what', 'when', 'where', 'who', 'which', '?'],
  };
  
  // Context window for maintaining conversation context
  final List<ProcessedText> _contextWindow = [];
  static const int _maxContextSize = 10;
  
  // Caching
  final Map<String, NLPResult> _cache = {};
  static const int _maxCacheSize = 100;
  
  final _random = Random();
  
  AINLPProcessor();
  
  Future<NLPResult> processText(String text) async {
    // Check cache
    if (_cache.containsKey(text)) {
      return _cache[text]!;
    }
    
    await Future.delayed(Duration(milliseconds: 50 + _random.nextInt(100)));
    
    final normalizedText = _normalizeText(text);
    
    // Extract intents
    final intents = _extractIntents(normalizedText);
    
    // Extract entities
    final entities = _extractEntities(text);
    
    // Analyze sentiment
    final sentiment = _analyzeSentiment(normalizedText);
    
    // Extract keywords
    final keywords = _extractKeywords(normalizedText);
    
    // Determine context
    final context = _determineContext(normalizedText, intents);
    
    // Generate suggestions
    final suggestions = _generateSuggestions(intents, entities);
    
    // Create result
    final result = NLPResult(
      originalText: text,
      processedText: normalizedText,
      intents: intents,
      entities: entities,
      sentiment: sentiment,
      keywords: keywords,
      context: context,
      suggestions: suggestions,
      confidence: _calculateConfidence(intents, entities),
      timestamp: DateTime.now(),
    );
    
    // Update cache and context
    _updateCache(text, result);
    _updateContext(result);
    
    return result;
  }
  
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s@#.-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
  
  List<Intent> _extractIntents(String text) {
    final intents = <Intent>[];
    
    _intentPatterns.forEach((intentType, patterns) {
      double score = 0;
      int matchCount = 0;
      
      for (final pattern in patterns) {
        if (text.contains(pattern)) {
          matchCount++;
          score += 1.0 / patterns.length;
        }
      }
      
      if (matchCount > 0) {
        final parts = intentType.split('.');
        intents.add(Intent(
          type: intentType,
          category: parts[0],
          action: parts.length > 1 ? parts[1] : 'general',
          confidence: min(score * 1.5, 1.0),
          matchedPatterns: patterns.where((p) => text.contains(p)).toList(),
        ));
      }
    });
    
    // Sort by confidence
    intents.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    // If no specific intent found, add general
    if (intents.isEmpty) {
      intents.add(Intent(
        type: 'general.query',
        category: 'general',
        action: 'query',
        confidence: 0.3,
        matchedPatterns: [],
      ));
    }
    
    return intents.take(3).toList();
  }
  
  Map<String, List<Entity>> _extractEntities(String text) {
    final entities = <String, List<Entity>>{};
    
    _entityPatterns.forEach((entityType, pattern) {
      final matches = pattern.allMatches(text);
      if (matches.isNotEmpty) {
        entities[entityType] = matches.map((match) {
          return Entity(
            type: entityType,
            value: match.group(match.groupCount > 0 ? 1 : 0) ?? match.group(0)!,
            position: match.start,
            rawText: match.group(0)!,
            confidence: _calculateEntityConfidence(entityType, match.group(0)!),
          );
        }).toList();
      }
    });
    
    // Extract custom entities based on context
    _extractCustomEntities(text, entities);
    
    return entities;
  }
  
  void _extractCustomEntities(String text, Map<String, List<Entity>> entities) {
    // Extract threat types
    final threatTypes = ['ddos', 'sql injection', 'xss', 'brute force', 'malware', 'ransomware'];
    for (final threat in threatTypes) {
      if (text.toLowerCase().contains(threat)) {
        entities['threat_type'] ??= [];
        entities['threat_type']!.add(Entity(
          type: 'threat_type',
          value: threat,
          position: text.toLowerCase().indexOf(threat),
          rawText: threat,
          confidence: 0.9,
        ));
      }
    }
    
    // Extract service names
    final services = ['auth', 'api', 'database', 'cache', 'frontend', 'backend'];
    for (final service in services) {
      if (text.toLowerCase().contains(service)) {
        entities['service'] ??= [];
        entities['service']!.add(Entity(
          type: 'service',
          value: service,
          position: text.toLowerCase().indexOf(service),
          rawText: service,
          confidence: 0.85,
        ));
      }
    }
  }
  
  Sentiment _analyzeSentiment(String text) {
    double urgency = 0;
    double negativity = 0;
    double positivity = 0;
    bool isQuestion = false;
    
    // Check for urgent indicators
    for (final indicator in _sentimentIndicators['urgent']!) {
      if (text.contains(indicator)) {
        urgency += 0.3;
      }
    }
    
    // Check for negative indicators
    for (final indicator in _sentimentIndicators['negative']!) {
      if (text.contains(indicator)) {
        negativity += 0.2;
      }
    }
    
    // Check for positive indicators
    for (final indicator in _sentimentIndicators['positive']!) {
      if (text.contains(indicator)) {
        positivity += 0.2;
      }
    }
    
    // Check if it's a question
    for (final indicator in _sentimentIndicators['questioning']!) {
      if (text.contains(indicator)) {
        isQuestion = true;
        break;
      }
    }
    
    // Determine overall sentiment
    String overall = 'neutral';
    if (negativity > positivity && negativity > 0.3) {
      overall = 'negative';
    } else if (positivity > negativity && positivity > 0.3) {
      overall = 'positive';
    }
    
    return Sentiment(
      overall: overall,
      urgency: min(urgency, 1.0),
      negativity: min(negativity, 1.0),
      positivity: min(positivity, 1.0),
      isQuestion: isQuestion,
    );
  }
  
  List<String> _extractKeywords(String text) {
    final words = text.split(' ');
    final keywords = <String>[];
    
    // Filter stop words and extract meaningful keywords
    final stopWords = {'the', 'is', 'at', 'on', 'in', 'for', 'to', 'a', 'an', 'and', 'or', 'but', 'with', 'from', 'as', 'by', 'of', 'can', 'you', 'please', 'help', 'me', 'my', 'i'};
    
    for (final word in words) {
      if (word.length > 3 && !stopWords.contains(word)) {
        keywords.add(word);
      }
    }
    
    // Add phrases
    if (text.contains('sql injection')) keywords.add('sql injection');
    if (text.contains('brute force')) keywords.add('brute force');
    if (text.contains('access control')) keywords.add('access control');
    if (text.contains('threat detection')) keywords.add('threat detection');
    if (text.contains('performance optimization')) keywords.add('performance optimization');
    
    return keywords.take(10).toList();
  }
  
  Map<String, dynamic> _determineContext(String text, List<Intent> intents) {
    final context = <String, dynamic>{};
    
    // Determine domain
    if (intents.isNotEmpty) {
      context['domain'] = intents.first.category;
    }
    
    // Check for temporal context
    if (text.contains('now') || text.contains('current') || text.contains('real-time')) {
      context['temporal'] = 'present';
    } else if (text.contains('last') || text.contains('previous') || text.contains('yesterday')) {
      context['temporal'] = 'past';
    } else if (text.contains('next') || text.contains('future') || text.contains('tomorrow')) {
      context['temporal'] = 'future';
    }
    
    // Check for scope
    if (text.contains('all') || text.contains('entire') || text.contains('whole')) {
      context['scope'] = 'global';
    } else if (text.contains('specific') || text.contains('particular') || text.contains('single')) {
      context['scope'] = 'specific';
    }
    
    // Reference to previous context
    if (_contextWindow.isNotEmpty) {
      context['has_history'] = true;
      context['previous_intent'] = _contextWindow.last.intents.firstOrNull?.type;
    }
    
    return context;
  }
  
  List<String> _generateSuggestions(List<Intent> intents, Map<String, List<Entity>> entities) {
    final suggestions = <String>[];
    
    if (intents.isEmpty) {
      return ['Try asking about security threats', 'Check system performance', 'Review user activities'];
    }
    
    final primaryIntent = intents.first;
    
    switch (primaryIntent.category) {
      case 'security':
        suggestions.add('Run a comprehensive security scan');
        suggestions.add('View recent security incidents');
        suggestions.add('Check vulnerability status');
        break;
      case 'user':
        suggestions.add('Review user access logs');
        suggestions.add('Check user permissions');
        suggestions.add('Analyze user behavior patterns');
        break;
      case 'performance':
        suggestions.add('View performance metrics dashboard');
        suggestions.add('Identify performance bottlenecks');
        suggestions.add('Optimize system resources');
        break;
      case 'monitoring':
        suggestions.add('Configure alert thresholds');
        suggestions.add('View real-time monitoring dashboard');
        suggestions.add('Set up automated monitoring');
        break;
      case 'investigation':
        suggestions.add('Generate forensic report');
        suggestions.add('Trace attack timeline');
        suggestions.add('Collect evidence artifacts');
        break;
      case 'reporting':
        suggestions.add('Generate comprehensive report');
        suggestions.add('Export data to CSV');
        suggestions.add('Schedule automated reports');
        break;
      case 'automation':
        suggestions.add('Create automation workflow');
        suggestions.add('View active automations');
        suggestions.add('Configure automation triggers');
        break;
      default:
        suggestions.add('Ask about specific security concerns');
        suggestions.add('Request a system health check');
        suggestions.add('View available commands');
    }
    
    return suggestions.take(3).toList();
  }
  
  double _calculateConfidence(List<Intent> intents, Map<String, List<Entity>> entities) {
    if (intents.isEmpty) return 0.3;
    
    double confidence = intents.first.confidence;
    
    // Boost confidence if entities are found
    if (entities.isNotEmpty) {
      confidence = min(confidence + 0.1, 1.0);
    }
    
    // Boost confidence if multiple matching intents
    if (intents.length > 1 && intents[1].confidence > 0.5) {
      confidence = min(confidence + 0.05, 1.0);
    }
    
    return confidence;
  }
  
  double _calculateEntityConfidence(String type, String value) {
    switch (type) {
      case 'email':
        return 0.95; // Email pattern is very specific
      case 'ip_address':
        return 0.9; // IP pattern is quite specific
      case 'url':
        return 0.9;
      case 'user_id':
        return 0.7; // Could be ambiguous
      case 'number':
        return 0.6; // Numbers can mean many things
      default:
        return 0.75;
    }
  }
  
  void _updateCache(String text, NLPResult result) {
    _cache[text] = result;
    
    // Limit cache size
    if (_cache.length > _maxCacheSize) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }
  }
  
  void _updateContext(NLPResult result) {
    _contextWindow.add(ProcessedText(
      text: result.originalText,
      intents: result.intents,
      timestamp: result.timestamp,
    ));
    
    // Limit context window size
    while (_contextWindow.length > _maxContextSize) {
      _contextWindow.removeAt(0);
    }
  }
  
  // Advanced features
  Future<List<Intent>> classifyMultiIntent(String text) async {
    final sentences = text.split(RegExp(r'[.!?]'));
    final allIntents = <Intent>[];
    
    for (final sentence in sentences) {
      if (sentence.trim().isNotEmpty) {
        final result = await processText(sentence);
        allIntents.addAll(result.intents);
      }
    }
    
    // Deduplicate and sort by confidence
    final uniqueIntents = <String, Intent>{};
    for (final intent in allIntents) {
      if (!uniqueIntents.containsKey(intent.type) || 
          uniqueIntents[intent.type]!.confidence < intent.confidence) {
        uniqueIntents[intent.type] = intent;
      }
    }
    
    return uniqueIntents.values.toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
  }
  
  Future<Map<String, dynamic>> extractComplexRelations(String text) async {
    final result = await processText(text);
    final relations = <String, dynamic>{};
    
    // Extract subject-action-object relations
    if (result.entities.containsKey('user_id') && result.intents.isNotEmpty) {
      final user = result.entities['user_id']!.first;
      final action = result.intents.first.action;
      relations['user_action'] = {
        'subject': user.value,
        'action': action,
        'confidence': user.confidence * result.intents.first.confidence,
      };
    }
    
    // Extract temporal relations
    if (result.entities.containsKey('time_relative')) {
      final time = result.entities['time_relative']!.first;
      relations['temporal'] = {
        'reference': time.value,
        'context': result.context['temporal'] ?? 'unknown',
      };
    }
    
    // Extract causal relations
    if (text.contains('because') || text.contains('due to') || text.contains('caused by')) {
      final parts = text.split(RegExp(r'because|due to|caused by'));
      if (parts.length > 1) {
        relations['causal'] = {
          'effect': parts[0].trim(),
          'cause': parts[1].trim(),
        };
      }
    }
    
    return relations;
  }
  
  List<ProcessedText> getConversationContext() {
    return List.unmodifiable(_contextWindow);
  }
  
  void clearContext() {
    _contextWindow.clear();
    _cache.clear();
  }
  
  Map<String, dynamic> getStatistics() {
    return {
      'cache_size': _cache.length,
      'context_size': _contextWindow.length,
      'known_intents': _intentPatterns.length,
      'entity_types': _entityPatterns.length,
    };
  }
}

// Data models
class NLPResult {
  final String originalText;
  final String processedText;
  final List<Intent> intents;
  final Map<String, List<Entity>> entities;
  final Sentiment sentiment;
  final List<String> keywords;
  final Map<String, dynamic> context;
  final List<String> suggestions;
  final double confidence;
  final DateTime timestamp;
  
  NLPResult({
    required this.originalText,
    required this.processedText,
    required this.intents,
    required this.entities,
    required this.sentiment,
    required this.keywords,
    required this.context,
    required this.suggestions,
    required this.confidence,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'original_text': originalText,
      'processed_text': processedText,
      'intents': intents.map((i) => i.toJson()).toList(),
      'entities': entities.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList())),
      'sentiment': sentiment.toJson(),
      'keywords': keywords,
      'context': context,
      'suggestions': suggestions,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class Intent {
  final String type;
  final String category;
  final String action;
  final double confidence;
  final List<String> matchedPatterns;
  
  Intent({
    required this.type,
    required this.category,
    required this.action,
    required this.confidence,
    required this.matchedPatterns,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'category': category,
      'action': action,
      'confidence': confidence,
      'matched_patterns': matchedPatterns,
    };
  }
}

class Entity {
  final String type;
  final String value;
  final int position;
  final String rawText;
  final double confidence;
  
  Entity({
    required this.type,
    required this.value,
    required this.position,
    required this.rawText,
    required this.confidence,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
      'position': position,
      'raw_text': rawText,
      'confidence': confidence,
    };
  }
}

class Sentiment {
  final String overall;
  final double urgency;
  final double negativity;
  final double positivity;
  final bool isQuestion;
  
  Sentiment({
    required this.overall,
    required this.urgency,
    required this.negativity,
    required this.positivity,
    required this.isQuestion,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'overall': overall,
      'urgency': urgency,
      'negativity': negativity,
      'positivity': positivity,
      'is_question': isQuestion,
    };
  }
}

class ProcessedText {
  final String text;
  final List<Intent> intents;
  final DateTime timestamp;
  
  ProcessedText({
    required this.text,
    required this.intents,
    required this.timestamp,
  });
}
