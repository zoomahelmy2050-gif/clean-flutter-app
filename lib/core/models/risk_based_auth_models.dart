enum RiskLevel { very_low, low, medium, high, very_high }
enum AuthenticationMethod { password, sms, email, totp, biometric, hardware_key, push_notification }
enum DeviceTrustLevel { unknown, untrusted, trusted, highly_trusted }
enum LocationRiskLevel { safe, low_risk, medium_risk, high_risk, blocked }

class RiskAssessment {
  final String id;
  final String userId;
  final String sessionId;
  final RiskLevel overallRisk;
  final double riskScore;
  final DateTime assessedAt;
  final Map<String, RiskFactor> riskFactors;
  final List<String> triggeredRules;
  final AuthenticationRequirement authRequirement;
  final Duration validityPeriod;
  final Map<String, dynamic> metadata;

  RiskAssessment({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.overallRisk,
    required this.riskScore,
    required this.assessedAt,
    this.riskFactors = const {},
    this.triggeredRules = const [],
    required this.authRequirement,
    required this.validityPeriod,
    this.metadata = const {},
  });

  factory RiskAssessment.fromJson(Map<String, dynamic> json) {
    return RiskAssessment(
      id: json['id'],
      userId: json['userId'],
      sessionId: json['sessionId'],
      overallRisk: RiskLevel.values.byName(json['overallRisk']),
      riskScore: json['riskScore'].toDouble(),
      assessedAt: DateTime.parse(json['assessedAt']),
      riskFactors: Map<String, RiskFactor>.from(
        (json['riskFactors'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, RiskFactor.fromJson(value)),
        ) ?? {},
      ),
      triggeredRules: List<String>.from(json['triggeredRules'] ?? []),
      authRequirement: AuthenticationRequirement.fromJson(json['authRequirement']),
      validityPeriod: Duration(seconds: json['validityPeriod']),
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'sessionId': sessionId,
      'overallRisk': overallRisk.name,
      'riskScore': riskScore,
      'assessedAt': assessedAt.toIso8601String(),
      'riskFactors': riskFactors.map((key, value) => MapEntry(key, value.toJson())),
      'triggeredRules': triggeredRules,
      'authRequirement': authRequirement.toJson(),
      'validityPeriod': validityPeriod.inSeconds,
      'metadata': metadata,
    };
  }
}

class RiskFactor {
  final String name;
  final double weight;
  final double score;
  final String description;
  final RiskLevel level;
  final Map<String, dynamic> details;

  RiskFactor({
    required this.name,
    required this.weight,
    required this.score,
    required this.description,
    required this.level,
    this.details = const {},
  });

  factory RiskFactor.fromJson(Map<String, dynamic> json) {
    return RiskFactor(
      name: json['name'],
      weight: json['weight'].toDouble(),
      score: json['score'].toDouble(),
      description: json['description'],
      level: RiskLevel.values.byName(json['level']),
      details: json['details'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'weight': weight,
      'score': score,
      'description': description,
      'level': level.name,
      'details': details,
    };
  }
}

class AuthenticationRequirement {
  final List<AuthenticationMethod> requiredMethods;
  final int minimumFactors;
  final bool allowRememberDevice;
  final Duration sessionTimeout;
  final bool requireReauth;
  final List<String> allowedMethods;
  final Map<String, dynamic> constraints;

  AuthenticationRequirement({
    this.requiredMethods = const [],
    this.minimumFactors = 1,
    this.allowRememberDevice = true,
    required this.sessionTimeout,
    this.requireReauth = false,
    this.allowedMethods = const [],
    this.constraints = const {},
  });

  factory AuthenticationRequirement.fromJson(Map<String, dynamic> json) {
    return AuthenticationRequirement(
      requiredMethods: (json['requiredMethods'] as List?)
          ?.map((e) => AuthenticationMethod.values.byName(e))
          .toList() ?? [],
      minimumFactors: json['minimumFactors'] ?? 1,
      allowRememberDevice: json['allowRememberDevice'] ?? true,
      sessionTimeout: Duration(seconds: json['sessionTimeout']),
      requireReauth: json['requireReauth'] ?? false,
      allowedMethods: List<String>.from(json['allowedMethods'] ?? []),
      constraints: json['constraints'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requiredMethods': requiredMethods.map((e) => e.name).toList(),
      'minimumFactors': minimumFactors,
      'allowRememberDevice': allowRememberDevice,
      'sessionTimeout': sessionTimeout.inSeconds,
      'requireReauth': requireReauth,
      'allowedMethods': allowedMethods,
      'constraints': constraints,
    };
  }
}

class TrustedDevice {
  final String id;
  final String userId;
  final String deviceFingerprint;
  final String deviceName;
  final String deviceType;
  final String operatingSystem;
  final String browser;
  final DeviceTrustLevel trustLevel;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final DateTime? trustedAt;
  final String? trustedBy;
  final bool isActive;
  final int loginCount;
  final List<String> ipAddresses;
  final Map<String, dynamic> attributes;

  TrustedDevice({
    required this.id,
    required this.userId,
    required this.deviceFingerprint,
    required this.deviceName,
    required this.deviceType,
    required this.operatingSystem,
    required this.browser,
    required this.trustLevel,
    required this.firstSeen,
    required this.lastSeen,
    this.trustedAt,
    this.trustedBy,
    this.isActive = true,
    this.loginCount = 0,
    this.ipAddresses = const [],
    this.attributes = const {},
  });

  factory TrustedDevice.fromJson(Map<String, dynamic> json) {
    return TrustedDevice(
      id: json['id'],
      userId: json['userId'],
      deviceFingerprint: json['deviceFingerprint'],
      deviceName: json['deviceName'],
      deviceType: json['deviceType'],
      operatingSystem: json['operatingSystem'],
      browser: json['browser'],
      trustLevel: DeviceTrustLevel.values.byName(json['trustLevel']),
      firstSeen: DateTime.parse(json['firstSeen']),
      lastSeen: DateTime.parse(json['lastSeen']),
      trustedAt: json['trustedAt'] != null ? DateTime.parse(json['trustedAt']) : null,
      trustedBy: json['trustedBy'],
      isActive: json['isActive'] ?? true,
      loginCount: json['loginCount'] ?? 0,
      ipAddresses: List<String>.from(json['ipAddresses'] ?? []),
      attributes: json['attributes'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'deviceFingerprint': deviceFingerprint,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'operatingSystem': operatingSystem,
      'browser': browser,
      'trustLevel': trustLevel.name,
      'firstSeen': firstSeen.toIso8601String(),
      'lastSeen': lastSeen.toIso8601String(),
      'trustedAt': trustedAt?.toIso8601String(),
      'trustedBy': trustedBy,
      'isActive': isActive,
      'loginCount': loginCount,
      'ipAddresses': ipAddresses,
      'attributes': attributes,
    };
  }
}

class GeolocationData {
  final String id;
  final double latitude;
  final double longitude;
  final String country;
  final String region;
  final String city;
  final String timezone;
  final String ipAddress;
  final LocationRiskLevel riskLevel;
  final bool isVpn;
  final bool isTor;
  final bool isProxy;
  final String isp;
  final DateTime detectedAt;
  final Map<String, dynamic> metadata;

  GeolocationData({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.country,
    required this.region,
    required this.city,
    required this.timezone,
    required this.ipAddress,
    required this.riskLevel,
    this.isVpn = false,
    this.isTor = false,
    this.isProxy = false,
    required this.isp,
    required this.detectedAt,
    this.metadata = const {},
  });

  factory GeolocationData.fromJson(Map<String, dynamic> json) {
    return GeolocationData(
      id: json['id'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      country: json['country'],
      region: json['region'],
      city: json['city'],
      timezone: json['timezone'],
      ipAddress: json['ipAddress'],
      riskLevel: LocationRiskLevel.values.byName(json['riskLevel']),
      isVpn: json['isVpn'] ?? false,
      isTor: json['isTor'] ?? false,
      isProxy: json['isProxy'] ?? false,
      isp: json['isp'],
      detectedAt: DateTime.parse(json['detectedAt']),
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'country': country,
      'region': region,
      'city': city,
      'timezone': timezone,
      'ipAddress': ipAddress,
      'riskLevel': riskLevel.name,
      'isVpn': isVpn,
      'isTor': isTor,
      'isProxy': isProxy,
      'isp': isp,
      'detectedAt': detectedAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}

class BehavioralBiometrics {
  final String id;
  final String userId;
  final String sessionId;
  final KeystrokeDynamics keystrokeDynamics;
  final MouseMovementPattern mousePattern;
  final TouchBehavior? touchBehavior;
  final double confidenceScore;
  final bool isAuthentic;
  final DateTime capturedAt;
  final Map<String, dynamic> rawData;

  BehavioralBiometrics({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.keystrokeDynamics,
    required this.mousePattern,
    this.touchBehavior,
    required this.confidenceScore,
    required this.isAuthentic,
    required this.capturedAt,
    this.rawData = const {},
  });

  factory BehavioralBiometrics.fromJson(Map<String, dynamic> json) {
    return BehavioralBiometrics(
      id: json['id'],
      userId: json['userId'],
      sessionId: json['sessionId'],
      keystrokeDynamics: KeystrokeDynamics.fromJson(json['keystrokeDynamics']),
      mousePattern: MouseMovementPattern.fromJson(json['mousePattern']),
      touchBehavior: json['touchBehavior'] != null 
          ? TouchBehavior.fromJson(json['touchBehavior']) 
          : null,
      confidenceScore: json['confidenceScore'].toDouble(),
      isAuthentic: json['isAuthentic'],
      capturedAt: DateTime.parse(json['capturedAt']),
      rawData: json['rawData'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'sessionId': sessionId,
      'keystrokeDynamics': keystrokeDynamics.toJson(),
      'mousePattern': mousePattern.toJson(),
      'touchBehavior': touchBehavior?.toJson(),
      'confidenceScore': confidenceScore,
      'isAuthentic': isAuthentic,
      'capturedAt': capturedAt.toIso8601String(),
      'rawData': rawData,
    };
  }
}

class KeystrokeDynamics {
  final double avgDwellTime;
  final double avgFlightTime;
  final double typingSpeed;
  final double rhythmConsistency;
  final Map<String, double> keyPairTimings;
  final List<double> pressureLevels;

  KeystrokeDynamics({
    required this.avgDwellTime,
    required this.avgFlightTime,
    required this.typingSpeed,
    required this.rhythmConsistency,
    this.keyPairTimings = const {},
    this.pressureLevels = const [],
  });

  factory KeystrokeDynamics.fromJson(Map<String, dynamic> json) {
    return KeystrokeDynamics(
      avgDwellTime: json['avgDwellTime'].toDouble(),
      avgFlightTime: json['avgFlightTime'].toDouble(),
      typingSpeed: json['typingSpeed'].toDouble(),
      rhythmConsistency: json['rhythmConsistency'].toDouble(),
      keyPairTimings: Map<String, double>.from(json['keyPairTimings'] ?? {}),
      pressureLevels: List<double>.from(json['pressureLevels'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avgDwellTime': avgDwellTime,
      'avgFlightTime': avgFlightTime,
      'typingSpeed': typingSpeed,
      'rhythmConsistency': rhythmConsistency,
      'keyPairTimings': keyPairTimings,
      'pressureLevels': pressureLevels,
    };
  }
}

class MouseMovementPattern {
  final double avgVelocity;
  final double avgAcceleration;
  final double clickFrequency;
  final double movementSmoothness;
  final List<double> trajectoryAngles;
  final double pauseDuration;

  MouseMovementPattern({
    required this.avgVelocity,
    required this.avgAcceleration,
    required this.clickFrequency,
    required this.movementSmoothness,
    this.trajectoryAngles = const [],
    required this.pauseDuration,
  });

  factory MouseMovementPattern.fromJson(Map<String, dynamic> json) {
    return MouseMovementPattern(
      avgVelocity: json['avgVelocity'].toDouble(),
      avgAcceleration: json['avgAcceleration'].toDouble(),
      clickFrequency: json['clickFrequency'].toDouble(),
      movementSmoothness: json['movementSmoothness'].toDouble(),
      trajectoryAngles: List<double>.from(json['trajectoryAngles'] ?? []),
      pauseDuration: json['pauseDuration'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avgVelocity': avgVelocity,
      'avgAcceleration': avgAcceleration,
      'clickFrequency': clickFrequency,
      'movementSmoothness': movementSmoothness,
      'trajectoryAngles': trajectoryAngles,
      'pauseDuration': pauseDuration,
    };
  }
}

class TouchBehavior {
  final double avgPressure;
  final double avgTouchArea;
  final double swipeVelocity;
  final double tapDuration;
  final List<double> gesturePatterns;

  TouchBehavior({
    required this.avgPressure,
    required this.avgTouchArea,
    required this.swipeVelocity,
    required this.tapDuration,
    this.gesturePatterns = const [],
  });

  factory TouchBehavior.fromJson(Map<String, dynamic> json) {
    return TouchBehavior(
      avgPressure: json['avgPressure'].toDouble(),
      avgTouchArea: json['avgTouchArea'].toDouble(),
      swipeVelocity: json['swipeVelocity'].toDouble(),
      tapDuration: json['tapDuration'].toDouble(),
      gesturePatterns: List<double>.from(json['gesturePatterns'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avgPressure': avgPressure,
      'avgTouchArea': avgTouchArea,
      'swipeVelocity': swipeVelocity,
      'tapDuration': tapDuration,
      'gesturePatterns': gesturePatterns,
    };
  }
}

class WebAuthnCredential {
  final String id;
  final String userId;
  final String credentialId;
  final String publicKey;
  final String authenticatorType;
  final bool isResident;
  final List<String> transports;
  final DateTime createdAt;
  final DateTime? lastUsed;
  final int useCount;
  final String name;
  final bool isActive;
  final Map<String, dynamic> metadata;

  WebAuthnCredential({
    required this.id,
    required this.userId,
    required this.credentialId,
    required this.publicKey,
    required this.authenticatorType,
    this.isResident = false,
    this.transports = const [],
    required this.createdAt,
    this.lastUsed,
    this.useCount = 0,
    required this.name,
    this.isActive = true,
    this.metadata = const {},
  });

  factory WebAuthnCredential.fromJson(Map<String, dynamic> json) {
    return WebAuthnCredential(
      id: json['id'],
      userId: json['userId'],
      credentialId: json['credentialId'],
      publicKey: json['publicKey'],
      authenticatorType: json['authenticatorType'],
      isResident: json['isResident'] ?? false,
      transports: List<String>.from(json['transports'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      lastUsed: json['lastUsed'] != null ? DateTime.parse(json['lastUsed']) : null,
      useCount: json['useCount'] ?? 0,
      name: json['name'],
      isActive: json['isActive'] ?? true,
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'credentialId': credentialId,
      'publicKey': publicKey,
      'authenticatorType': authenticatorType,
      'isResident': isResident,
      'transports': transports,
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed?.toIso8601String(),
      'useCount': useCount,
      'name': name,
      'isActive': isActive,
      'metadata': metadata,
    };
  }
}
