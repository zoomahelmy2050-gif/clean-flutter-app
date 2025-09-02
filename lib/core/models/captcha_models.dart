enum CaptchaType { 
  recaptcha_v2, 
  recaptcha_v3, 
  hcaptcha, 
  cloudflare_turnstile, 
  custom_image, 
  audio, 
  math_puzzle,
  slider_puzzle,
  text_based
}

enum CaptchaStatus { pending, verified, failed, expired, rate_limited }
enum BotDetectionLevel { low, medium, high, paranoid }
enum ChallengeType { visual, audio, interactive, behavioral }

class CaptchaChallenge {
  final String id;
  final CaptchaType type;
  final ChallengeType challengeType;
  final String challenge;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int difficulty;
  final String? imageUrl;
  final String? audioUrl;
  final List<String>? options;

  CaptchaChallenge({
    required this.id,
    required this.type,
    required this.challengeType,
    required this.challenge,
    this.metadata = const {},
    required this.createdAt,
    required this.expiresAt,
    this.difficulty = 1,
    this.imageUrl,
    this.audioUrl,
    this.options,
  });

  factory CaptchaChallenge.fromJson(Map<String, dynamic> json) {
    return CaptchaChallenge(
      id: json['id'],
      type: CaptchaType.values.byName(json['type']),
      challengeType: ChallengeType.values.byName(json['challengeType']),
      challenge: json['challenge'],
      metadata: json['metadata'] ?? {},
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      difficulty: json['difficulty'] ?? 1,
      imageUrl: json['imageUrl'],
      audioUrl: json['audioUrl'],
      options: json['options'] != null ? List<String>.from(json['options']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'challengeType': challengeType.name,
      'challenge': challenge,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'difficulty': difficulty,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'options': options,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class CaptchaResponse {
  final String challengeId;
  final String response;
  final DateTime submittedAt;
  final Map<String, dynamic> clientData;
  final Duration responseTime;

  CaptchaResponse({
    required this.challengeId,
    required this.response,
    required this.submittedAt,
    this.clientData = const {},
    required this.responseTime,
  });

  factory CaptchaResponse.fromJson(Map<String, dynamic> json) {
    return CaptchaResponse(
      challengeId: json['challengeId'],
      response: json['response'],
      submittedAt: DateTime.parse(json['submittedAt']),
      clientData: json['clientData'] ?? {},
      responseTime: Duration(milliseconds: json['responseTime']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'challengeId': challengeId,
      'response': response,
      'submittedAt': submittedAt.toIso8601String(),
      'clientData': clientData,
      'responseTime': responseTime.inMilliseconds,
    };
  }
}

class CaptchaVerificationResult {
  final String challengeId;
  final CaptchaStatus status;
  final bool isValid;
  final double confidence;
  final String? errorMessage;
  final DateTime verifiedAt;
  final Map<String, dynamic> details;
  final BotDetectionResult? botDetection;

  CaptchaVerificationResult({
    required this.challengeId,
    required this.status,
    required this.isValid,
    this.confidence = 0.0,
    this.errorMessage,
    required this.verifiedAt,
    this.details = const {},
    this.botDetection,
  });

  factory CaptchaVerificationResult.fromJson(Map<String, dynamic> json) {
    return CaptchaVerificationResult(
      challengeId: json['challengeId'],
      status: CaptchaStatus.values.byName(json['status']),
      isValid: json['isValid'],
      confidence: json['confidence']?.toDouble() ?? 0.0,
      errorMessage: json['errorMessage'],
      verifiedAt: DateTime.parse(json['verifiedAt']),
      details: json['details'] ?? {},
      botDetection: json['botDetection'] != null ? BotDetectionResult.fromJson(json['botDetection']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'challengeId': challengeId,
      'status': status.name,
      'isValid': isValid,
      'confidence': confidence,
      'errorMessage': errorMessage,
      'verifiedAt': verifiedAt.toIso8601String(),
      'details': details,
      'botDetection': botDetection?.toJson(),
    };
  }
}

class BotDetectionResult {
  final bool isBot;
  final double botScore;
  final BotDetectionLevel riskLevel;
  final List<String> indicators;
  final Map<String, dynamic> behaviorAnalysis;
  final Map<String, dynamic> fingerprint;
  final DateTime analyzedAt;

  BotDetectionResult({
    required this.isBot,
    required this.botScore,
    required this.riskLevel,
    this.indicators = const [],
    this.behaviorAnalysis = const {},
    this.fingerprint = const {},
    required this.analyzedAt,
  });

  factory BotDetectionResult.fromJson(Map<String, dynamic> json) {
    return BotDetectionResult(
      isBot: json['isBot'],
      botScore: json['botScore'].toDouble(),
      riskLevel: BotDetectionLevel.values.byName(json['riskLevel']),
      indicators: List<String>.from(json['indicators'] ?? []),
      behaviorAnalysis: json['behaviorAnalysis'] ?? {},
      fingerprint: json['fingerprint'] ?? {},
      analyzedAt: DateTime.parse(json['analyzedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isBot': isBot,
      'botScore': botScore,
      'riskLevel': riskLevel.name,
      'indicators': indicators,
      'behaviorAnalysis': behaviorAnalysis,
      'fingerprint': fingerprint,
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }
}

class CaptchaConfig {
  final String siteKey;
  final String secretKey;
  final CaptchaType type;
  final BotDetectionLevel detectionLevel;
  final Duration challengeTimeout;
  final int maxAttempts;
  final bool enableAudio;
  final bool enableAccessibility;
  final Map<String, dynamic> customSettings;
  final List<String> trustedDomains;

  CaptchaConfig({
    required this.siteKey,
    required this.secretKey,
    required this.type,
    this.detectionLevel = BotDetectionLevel.medium,
    this.challengeTimeout = const Duration(minutes: 5),
    this.maxAttempts = 3,
    this.enableAudio = true,
    this.enableAccessibility = true,
    this.customSettings = const {},
    this.trustedDomains = const [],
  });

  factory CaptchaConfig.fromJson(Map<String, dynamic> json) {
    return CaptchaConfig(
      siteKey: json['siteKey'],
      secretKey: json['secretKey'],
      type: CaptchaType.values.byName(json['type']),
      detectionLevel: BotDetectionLevel.values.byName(json['detectionLevel'] ?? 'medium'),
      challengeTimeout: Duration(seconds: json['challengeTimeout'] ?? 300),
      maxAttempts: json['maxAttempts'] ?? 3,
      enableAudio: json['enableAudio'] ?? true,
      enableAccessibility: json['enableAccessibility'] ?? true,
      customSettings: json['customSettings'] ?? {},
      trustedDomains: List<String>.from(json['trustedDomains'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'siteKey': siteKey,
      'secretKey': secretKey,
      'type': type.name,
      'detectionLevel': detectionLevel.name,
      'challengeTimeout': challengeTimeout.inSeconds,
      'maxAttempts': maxAttempts,
      'enableAudio': enableAudio,
      'enableAccessibility': enableAccessibility,
      'customSettings': customSettings,
      'trustedDomains': trustedDomains,
    };
  }
}

class CaptchaAnalytics {
  final String siteKey;
  final int totalChallenges;
  final int successfulVerifications;
  final int failedVerifications;
  final int botDetections;
  final double successRate;
  final double botRate;
  final Map<CaptchaType, int> challengesByType;
  final Map<String, int> failureReasons;
  final Duration averageResponseTime;
  final DateTime periodStart;
  final DateTime periodEnd;

  CaptchaAnalytics({
    required this.siteKey,
    this.totalChallenges = 0,
    this.successfulVerifications = 0,
    this.failedVerifications = 0,
    this.botDetections = 0,
    this.successRate = 0.0,
    this.botRate = 0.0,
    this.challengesByType = const {},
    this.failureReasons = const {},
    this.averageResponseTime = Duration.zero,
    required this.periodStart,
    required this.periodEnd,
  });

  factory CaptchaAnalytics.fromJson(Map<String, dynamic> json) {
    final challengesByTypeMap = <CaptchaType, int>{};
    if (json['challengesByType'] != null) {
      (json['challengesByType'] as Map<String, dynamic>).forEach((key, value) {
        challengesByTypeMap[CaptchaType.values.byName(key)] = value;
      });
    }

    return CaptchaAnalytics(
      siteKey: json['siteKey'],
      totalChallenges: json['totalChallenges'] ?? 0,
      successfulVerifications: json['successfulVerifications'] ?? 0,
      failedVerifications: json['failedVerifications'] ?? 0,
      botDetections: json['botDetections'] ?? 0,
      successRate: json['successRate']?.toDouble() ?? 0.0,
      botRate: json['botRate']?.toDouble() ?? 0.0,
      challengesByType: challengesByTypeMap,
      failureReasons: Map<String, int>.from(json['failureReasons'] ?? {}),
      averageResponseTime: Duration(milliseconds: json['averageResponseTime'] ?? 0),
      periodStart: DateTime.parse(json['periodStart']),
      periodEnd: DateTime.parse(json['periodEnd']),
    );
  }

  Map<String, dynamic> toJson() {
    final challengesByTypeMap = <String, int>{};
    challengesByType.forEach((key, value) {
      challengesByTypeMap[key.name] = value;
    });

    return {
      'siteKey': siteKey,
      'totalChallenges': totalChallenges,
      'successfulVerifications': successfulVerifications,
      'failedVerifications': failedVerifications,
      'botDetections': botDetections,
      'successRate': successRate,
      'botRate': botRate,
      'challengesByType': challengesByTypeMap,
      'failureReasons': failureReasons,
      'averageResponseTime': averageResponseTime.inMilliseconds,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
    };
  }
}

class BehaviorPattern {
  final String sessionId;
  final List<MouseMovement> mouseMovements;
  final List<KeystrokeEvent> keystrokes;
  final List<TouchEvent> touchEvents;
  final Duration sessionDuration;
  final int pageViews;
  final Map<String, dynamic> deviceFingerprint;
  final DateTime recordedAt;

  BehaviorPattern({
    required this.sessionId,
    this.mouseMovements = const [],
    this.keystrokes = const [],
    this.touchEvents = const [],
    required this.sessionDuration,
    this.pageViews = 0,
    this.deviceFingerprint = const {},
    required this.recordedAt,
  });

  factory BehaviorPattern.fromJson(Map<String, dynamic> json) {
    return BehaviorPattern(
      sessionId: json['sessionId'],
      mouseMovements: (json['mouseMovements'] as List?)?.map((e) => MouseMovement.fromJson(e)).toList() ?? [],
      keystrokes: (json['keystrokes'] as List?)?.map((e) => KeystrokeEvent.fromJson(e)).toList() ?? [],
      touchEvents: (json['touchEvents'] as List?)?.map((e) => TouchEvent.fromJson(e)).toList() ?? [],
      sessionDuration: Duration(milliseconds: json['sessionDuration']),
      pageViews: json['pageViews'] ?? 0,
      deviceFingerprint: json['deviceFingerprint'] ?? {},
      recordedAt: DateTime.parse(json['recordedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'mouseMovements': mouseMovements.map((e) => e.toJson()).toList(),
      'keystrokes': keystrokes.map((e) => e.toJson()).toList(),
      'touchEvents': touchEvents.map((e) => e.toJson()).toList(),
      'sessionDuration': sessionDuration.inMilliseconds,
      'pageViews': pageViews,
      'deviceFingerprint': deviceFingerprint,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }
}

class MouseMovement {
  final double x;
  final double y;
  final DateTime timestamp;
  final String eventType;

  MouseMovement({
    required this.x,
    required this.y,
    required this.timestamp,
    required this.eventType,
  });

  factory MouseMovement.fromJson(Map<String, dynamic> json) {
    return MouseMovement(
      x: json['x'].toDouble(),
      y: json['y'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      eventType: json['eventType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'timestamp': timestamp.toIso8601String(),
      'eventType': eventType,
    };
  }
}

class KeystrokeEvent {
  final String key;
  final DateTime timestamp;
  final Duration dwellTime;
  final Duration flightTime;
  final String eventType;

  KeystrokeEvent({
    required this.key,
    required this.timestamp,
    required this.dwellTime,
    required this.flightTime,
    required this.eventType,
  });

  factory KeystrokeEvent.fromJson(Map<String, dynamic> json) {
    return KeystrokeEvent(
      key: json['key'],
      timestamp: DateTime.parse(json['timestamp']),
      dwellTime: Duration(milliseconds: json['dwellTime']),
      flightTime: Duration(milliseconds: json['flightTime']),
      eventType: json['eventType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'timestamp': timestamp.toIso8601String(),
      'dwellTime': dwellTime.inMilliseconds,
      'flightTime': flightTime.inMilliseconds,
      'eventType': eventType,
    };
  }
}

class TouchEvent {
  final double x;
  final double y;
  final double pressure;
  final DateTime timestamp;
  final String eventType;
  final double radius;

  TouchEvent({
    required this.x,
    required this.y,
    required this.pressure,
    required this.timestamp,
    required this.eventType,
    this.radius = 0.0,
  });

  factory TouchEvent.fromJson(Map<String, dynamic> json) {
    return TouchEvent(
      x: json['x'].toDouble(),
      y: json['y'].toDouble(),
      pressure: json['pressure'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      eventType: json['eventType'],
      radius: json['radius']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'pressure': pressure,
      'timestamp': timestamp.toIso8601String(),
      'eventType': eventType,
      'radius': radius,
    };
  }
}
