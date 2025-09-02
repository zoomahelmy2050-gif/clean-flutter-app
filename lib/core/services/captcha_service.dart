import 'dart:async';
import 'dart:math';
import 'dart:developer' as developer;
import '../models/captcha_models.dart';

class CaptchaService {
  static final CaptchaService _instance = CaptchaService._internal();
  factory CaptchaService() => _instance;
  CaptchaService._internal();

  final Map<String, CaptchaChallenge> _activeChallenges = {};
  final Map<String, CaptchaConfig> _configs = {};
  final Map<String, BehaviorPattern> _behaviorPatterns = {};
  final Map<String, List<CaptchaVerificationResult>> _verificationHistory = {};
  
  final StreamController<CaptchaChallenge> _challengeController = StreamController<CaptchaChallenge>.broadcast();
  final StreamController<CaptchaVerificationResult> _verificationController = StreamController<CaptchaVerificationResult>.broadcast();
  final StreamController<BotDetectionResult> _botDetectionController = StreamController<BotDetectionResult>.broadcast();

  Stream<CaptchaChallenge> get challengeStream => _challengeController.stream;
  Stream<CaptchaVerificationResult> get verificationStream => _verificationController.stream;
  Stream<BotDetectionResult> get botDetectionStream => _botDetectionController.stream;

  final Random _random = Random();
  Timer? _cleanupTimer;

  Future<void> initialize() async {
    developer.log('Initializing Captcha Service', name: 'CaptchaService');
    
    _setupDefaultConfigs();
    _startCleanupTimer();
    
    developer.log('Captcha Service initialized', name: 'CaptchaService');
  }

  void _setupDefaultConfigs() {
    _configs['default'] = CaptchaConfig(
      siteKey: 'default_site_key',
      secretKey: 'default_secret_key',
      type: CaptchaType.recaptcha_v3,
      detectionLevel: BotDetectionLevel.medium,
    );

    _configs['login'] = CaptchaConfig(
      siteKey: 'login_site_key',
      secretKey: 'login_secret_key',
      type: CaptchaType.recaptcha_v2,
      detectionLevel: BotDetectionLevel.high,
      maxAttempts: 5,
    );

    _configs['registration'] = CaptchaConfig(
      siteKey: 'register_site_key',
      secretKey: 'register_secret_key',
      type: CaptchaType.hcaptcha,
      detectionLevel: BotDetectionLevel.high,
      maxAttempts: 3,
    );
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _cleanupExpiredChallenges();
    });
  }

  void _cleanupExpiredChallenges() {
    final now = DateTime.now();
    final expiredIds = <String>[];
    
    _activeChallenges.forEach((id, challenge) {
      if (challenge.isExpired) {
        expiredIds.add(id);
      }
    });
    
    for (final id in expiredIds) {
      _activeChallenges.remove(id);
    }
    
    if (expiredIds.isNotEmpty) {
      developer.log('Cleaned up ${expiredIds.length} expired challenges', name: 'CaptchaService');
    }
  }

  Future<CaptchaChallenge> generateChallenge(CaptchaType type, {String? configKey}) async {
    final config = _configs[configKey ?? 'default'] ?? _configs['default']!;
    
    final challengeId = 'challenge_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}';
    final now = DateTime.now();
    final expiresAt = now.add(config.challengeTimeout);
    
    CaptchaChallenge challenge;
    
    switch (type) {
      case CaptchaType.recaptcha_v2:
        challenge = _generateRecaptchaV2Challenge(challengeId, now, expiresAt);
        break;
      case CaptchaType.recaptcha_v3:
        challenge = _generateRecaptchaV3Challenge(challengeId, now, expiresAt);
        break;
      case CaptchaType.hcaptcha:
        challenge = _generateHCaptchaChallenge(challengeId, now, expiresAt);
        break;
      case CaptchaType.cloudflare_turnstile:
        challenge = _generateTurnstileChallenge(challengeId, now, expiresAt);
        break;
      case CaptchaType.custom_image:
        challenge = _generateImageChallenge(challengeId, now, expiresAt);
        break;
      case CaptchaType.audio:
        challenge = _generateAudioChallenge(challengeId, now, expiresAt);
        break;
      case CaptchaType.math_puzzle:
        challenge = _generateMathPuzzleChallenge(challengeId, now, expiresAt);
        break;
      case CaptchaType.slider_puzzle:
        challenge = _generateSliderPuzzleChallenge(challengeId, now, expiresAt);
        break;
      case CaptchaType.text_based:
        challenge = _generateTextBasedChallenge(challengeId, now, expiresAt);
        break;
    }
    
    _activeChallenges[challengeId] = challenge;
    _challengeController.add(challenge);
    
    return challenge;
  }

  CaptchaChallenge _generateRecaptchaV2Challenge(String id, DateTime createdAt, DateTime expiresAt) {
    return CaptchaChallenge(
      id: id,
      type: CaptchaType.recaptcha_v2,
      challengeType: ChallengeType.visual,
      challenge: 'Select all images with traffic lights',
      createdAt: createdAt,
      expiresAt: expiresAt,
      difficulty: 2,
      imageUrl: 'https://example.com/captcha/images/$id.jpg',
      metadata: {
        'gridSize': '3x3',
        'targetObject': 'traffic_lights',
        'provider': 'google',
      },
    );
  }

  CaptchaChallenge _generateRecaptchaV3Challenge(String id, DateTime createdAt, DateTime expiresAt) {
    return CaptchaChallenge(
      id: id,
      type: CaptchaType.recaptcha_v3,
      challengeType: ChallengeType.behavioral,
      challenge: 'Behavioral analysis in progress',
      createdAt: createdAt,
      expiresAt: expiresAt,
      difficulty: 1,
      metadata: {
        'scoreThreshold': 0.5,
        'provider': 'google',
        'invisible': true,
      },
    );
  }

  CaptchaChallenge _generateHCaptchaChallenge(String id, DateTime createdAt, DateTime expiresAt) {
    final objects = ['cars', 'bicycles', 'motorcycles', 'buses', 'traffic lights', 'crosswalks'];
    final targetObject = objects[_random.nextInt(objects.length)];
    
    return CaptchaChallenge(
      id: id,
      type: CaptchaType.hcaptcha,
      challengeType: ChallengeType.visual,
      challenge: 'Please click each image containing a $targetObject',
      createdAt: createdAt,
      expiresAt: expiresAt,
      difficulty: 2,
      imageUrl: 'https://example.com/hcaptcha/images/$id.jpg',
      metadata: {
        'targetObject': targetObject,
        'provider': 'hcaptcha',
        'gridSize': '3x3',
      },
    );
  }

  CaptchaChallenge _generateTurnstileChallenge(String id, DateTime createdAt, DateTime expiresAt) {
    return CaptchaChallenge(
      id: id,
      type: CaptchaType.cloudflare_turnstile,
      challengeType: ChallengeType.behavioral,
      challenge: 'Verifying you are human',
      createdAt: createdAt,
      expiresAt: expiresAt,
      difficulty: 1,
      metadata: {
        'provider': 'cloudflare',
        'invisible': true,
        'theme': 'light',
      },
    );
  }

  CaptchaChallenge _generateImageChallenge(String id, DateTime createdAt, DateTime expiresAt) {
    final challenges = [
      'Type the text you see in the image',
      'Enter the numbers shown in the image',
      'What color is the text in the image?',
    ];
    
    return CaptchaChallenge(
      id: id,
      type: CaptchaType.custom_image,
      challengeType: ChallengeType.visual,
      challenge: challenges[_random.nextInt(challenges.length)],
      createdAt: createdAt,
      expiresAt: expiresAt,
      difficulty: 3,
      imageUrl: 'https://example.com/custom/images/$id.png',
      metadata: {
        'expectedAnswer': _generateRandomText(6),
        'caseSensitive': false,
      },
    );
  }

  CaptchaChallenge _generateAudioChallenge(String id, DateTime createdAt, DateTime expiresAt) {
    return CaptchaChallenge(
      id: id,
      type: CaptchaType.audio,
      challengeType: ChallengeType.audio,
      challenge: 'Listen to the audio and type what you hear',
      createdAt: createdAt,
      expiresAt: expiresAt,
      difficulty: 4,
      audioUrl: 'https://example.com/captcha/audio/$id.mp3',
      metadata: {
        'expectedAnswer': _generateRandomText(5),
        'language': 'en',
        'speed': 'normal',
      },
    );
  }

  CaptchaChallenge _generateMathPuzzleChallenge(String id, DateTime createdAt, DateTime expiresAt) {
    final a = _random.nextInt(20) + 1;
    final b = _random.nextInt(20) + 1;
    final operations = ['+', '-', '*'];
    final operation = operations[_random.nextInt(operations.length)];
    
    int answer;
    switch (operation) {
      case '+':
        answer = a + b;
        break;
      case '-':
        answer = a - b;
        break;
      case '*':
        answer = a * b;
        break;
      default:
        answer = a + b;
    }
    
    return CaptchaChallenge(
      id: id,
      type: CaptchaType.math_puzzle,
      challengeType: ChallengeType.interactive,
      challenge: 'What is $a $operation $b?',
      createdAt: createdAt,
      expiresAt: expiresAt,
      difficulty: 2,
      metadata: {
        'expectedAnswer': answer.toString(),
        'equation': '$a $operation $b',
      },
    );
  }

  CaptchaChallenge _generateSliderPuzzleChallenge(String id, DateTime createdAt, DateTime expiresAt) {
    return CaptchaChallenge(
      id: id,
      type: CaptchaType.slider_puzzle,
      challengeType: ChallengeType.interactive,
      challenge: 'Slide the puzzle piece to complete the image',
      createdAt: createdAt,
      expiresAt: expiresAt,
      difficulty: 3,
      imageUrl: 'https://example.com/slider/images/$id.jpg',
      metadata: {
        'targetPosition': {'x': 150, 'y': 75},
        'tolerance': 10,
      },
    );
  }

  CaptchaChallenge _generateTextBasedChallenge(String id, DateTime createdAt, DateTime expiresAt) {
    final questions = [
      {'question': 'What comes after Monday?', 'answer': 'tuesday'},
      {'question': 'How many legs does a cat have?', 'answer': '4'},
      {'question': 'What color is grass?', 'answer': 'green'},
      {'question': 'What is 2 + 2?', 'answer': '4'},
      {'question': 'What is the opposite of hot?', 'answer': 'cold'},
    ];
    
    final selected = questions[_random.nextInt(questions.length)];
    
    return CaptchaChallenge(
      id: id,
      type: CaptchaType.text_based,
      challengeType: ChallengeType.interactive,
      challenge: selected['question']!,
      createdAt: createdAt,
      expiresAt: expiresAt,
      difficulty: 1,
      metadata: {
        'expectedAnswer': selected['answer'],
        'caseSensitive': false,
      },
    );
  }

  String _generateRandomText(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(_random.nextInt(chars.length)))
    );
  }

  Future<CaptchaVerificationResult> verifyChallenge(CaptchaResponse response) async {
    final challenge = _activeChallenges[response.challengeId];
    
    if (challenge == null) {
      return CaptchaVerificationResult(
        challengeId: response.challengeId,
        status: CaptchaStatus.failed,
        isValid: false,
        errorMessage: 'Challenge not found or expired',
        verifiedAt: DateTime.now(),
      );
    }

    if (challenge.isExpired) {
      _activeChallenges.remove(response.challengeId);
      return CaptchaVerificationResult(
        challengeId: response.challengeId,
        status: CaptchaStatus.expired,
        isValid: false,
        errorMessage: 'Challenge has expired',
        verifiedAt: DateTime.now(),
      );
    }

    // Simulate verification delay
    await Future.delayed(Duration(milliseconds: 200 + _random.nextInt(800)));

    final botDetection = await _analyzeBehavior(response);
    final isValidResponse = _validateResponse(challenge, response.response);
    final confidence = _calculateConfidence(challenge, response, botDetection);

    final result = CaptchaVerificationResult(
      challengeId: response.challengeId,
      status: isValidResponse && !botDetection.isBot ? CaptchaStatus.verified : CaptchaStatus.failed,
      isValid: isValidResponse && !botDetection.isBot,
      confidence: confidence,
      verifiedAt: DateTime.now(),
      botDetection: botDetection,
      details: {
        'responseTime': response.responseTime.inMilliseconds,
        'challengeType': challenge.type.name,
        'difficulty': challenge.difficulty,
      },
    );

    // Store verification history
    _verificationHistory.putIfAbsent(response.challengeId, () => []).add(result);

    // Clean up successful challenges
    if (result.isValid) {
      _activeChallenges.remove(response.challengeId);
    }

    _verificationController.add(result);
    _botDetectionController.add(botDetection);

    return result;
  }

  bool _validateResponse(CaptchaChallenge challenge, String response) {
    final expectedAnswer = challenge.metadata['expectedAnswer'] as String?;
    
    if (expectedAnswer == null) {
      // For challenges without expected answers (like reCAPTCHA), simulate success rate
      return _random.nextDouble() > 0.2; // 80% success rate
    }

    final caseSensitive = challenge.metadata['caseSensitive'] as bool? ?? false;
    final userResponse = caseSensitive ? response : response.toLowerCase();
    final expected = caseSensitive ? expectedAnswer : expectedAnswer.toLowerCase();

    return userResponse.trim() == expected.trim();
  }

  Future<BotDetectionResult> _analyzeBehavior(CaptchaResponse response) async {
    final indicators = <String>[];
    double botScore = 0.0;

    // Analyze response time
    if (response.responseTime.inMilliseconds < 500) {
      indicators.add('Response too fast');
      botScore += 0.3;
    } else if (response.responseTime.inMilliseconds > 60000) {
      indicators.add('Response too slow');
      botScore += 0.2;
    }

    // Analyze client data
    final userAgent = response.clientData['userAgent'] as String?;
    if (userAgent != null) {
      if (userAgent.contains('bot') || userAgent.contains('crawler')) {
        indicators.add('Bot user agent detected');
        botScore += 0.5;
      }
    }

    // Simulate additional behavioral analysis
    if (_random.nextDouble() < 0.1) {
      indicators.add('Suspicious mouse movement pattern');
      botScore += 0.2;
    }

    if (_random.nextDouble() < 0.05) {
      indicators.add('No human-like interaction detected');
      botScore += 0.4;
    }

    final riskLevel = botScore > 0.7 ? BotDetectionLevel.high :
                     botScore > 0.4 ? BotDetectionLevel.medium :
                     botScore > 0.2 ? BotDetectionLevel.low : BotDetectionLevel.low;

    return BotDetectionResult(
      isBot: botScore > 0.5,
      botScore: botScore,
      riskLevel: riskLevel,
      indicators: indicators,
      behaviorAnalysis: {
        'responseTime': response.responseTime.inMilliseconds,
        'mouseMovements': _random.nextInt(50),
        'keystrokes': _random.nextInt(20),
      },
      fingerprint: {
        'userAgent': userAgent ?? 'unknown',
        'screenResolution': '${1920 + _random.nextInt(400)}x${1080 + _random.nextInt(200)}',
        'timezone': 'UTC+${_random.nextInt(24) - 12}',
      },
      analyzedAt: DateTime.now(),
    );
  }

  double _calculateConfidence(CaptchaChallenge challenge, CaptchaResponse response, BotDetectionResult botDetection) {
    double confidence = 0.5; // Base confidence

    // Adjust based on challenge difficulty
    confidence += (challenge.difficulty - 2) * 0.1;

    // Adjust based on response time
    final responseTimeMs = response.responseTime.inMilliseconds;
    if (responseTimeMs > 1000 && responseTimeMs < 30000) {
      confidence += 0.2; // Good response time
    }

    // Adjust based on bot detection
    confidence -= botDetection.botScore * 0.3;

    return confidence.clamp(0.0, 1.0);
  }

  Future<CaptchaAnalytics> getAnalytics(String siteKey, DateTime start, DateTime end) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final totalChallenges = 100 + _random.nextInt(900);
    final successfulVerifications = (totalChallenges * (0.7 + _random.nextDouble() * 0.2)).round();
    final failedVerifications = totalChallenges - successfulVerifications;
    final botDetections = (totalChallenges * (0.1 + _random.nextDouble() * 0.1)).round();

    return CaptchaAnalytics(
      siteKey: siteKey,
      totalChallenges: totalChallenges,
      successfulVerifications: successfulVerifications,
      failedVerifications: failedVerifications,
      botDetections: botDetections,
      successRate: successfulVerifications / totalChallenges,
      botRate: botDetections / totalChallenges,
      challengesByType: {
        CaptchaType.recaptcha_v2: _random.nextInt(totalChallenges ~/ 2),
        CaptchaType.recaptcha_v3: _random.nextInt(totalChallenges ~/ 2),
        CaptchaType.hcaptcha: _random.nextInt(totalChallenges ~/ 4),
      },
      failureReasons: {
        'Incorrect response': _random.nextInt(failedVerifications),
        'Timeout': _random.nextInt(failedVerifications ~/ 2),
        'Bot detected': botDetections,
      },
      averageResponseTime: Duration(milliseconds: 5000 + _random.nextInt(10000)),
      periodStart: start,
      periodEnd: end,
    );
  }

  void recordBehaviorPattern(BehaviorPattern pattern) {
    _behaviorPatterns[pattern.sessionId] = pattern;
  }

  CaptchaConfig? getConfig(String key) => _configs[key];
  
  void setConfig(String key, CaptchaConfig config) {
    _configs[key] = config;
  }

  List<CaptchaChallenge> getActiveChallenges() => _activeChallenges.values.toList();
  
  List<CaptchaVerificationResult> getVerificationHistory(String challengeId) {
    return _verificationHistory[challengeId] ?? [];
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _challengeController.close();
    _verificationController.close();
    _botDetectionController.close();
  }
}
