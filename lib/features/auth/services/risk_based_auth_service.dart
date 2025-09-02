import 'dart:async';
import 'dart:math';
import 'dart:developer' as developer;
import '../../../core/models/risk_based_auth_models.dart';

class RiskBasedAuthService {
  static final RiskBasedAuthService _instance = RiskBasedAuthService._internal();
  factory RiskBasedAuthService() => _instance;
  RiskBasedAuthService._internal();

  final Random _random = Random();
  Timer? _riskUpdateTimer;

  // Streams for real-time updates
  final StreamController<RiskAssessment> _riskAssessmentController = StreamController<RiskAssessment>.broadcast();
  final StreamController<List<TrustedDevice>> _trustedDevicesController = StreamController<List<TrustedDevice>>.broadcast();
  final StreamController<BehavioralBiometrics> _biometricsController = StreamController<BehavioralBiometrics>.broadcast();

  Stream<RiskAssessment> get riskAssessmentStream => _riskAssessmentController.stream;
  Stream<List<TrustedDevice>> get trustedDevicesStream => _trustedDevicesController.stream;
  Stream<BehavioralBiometrics> get biometricsStream => _biometricsController.stream;

  // Data storage
  final Map<String, RiskAssessment> _riskAssessments = {};
  final Map<String, List<TrustedDevice>> _userTrustedDevices = {};
  final Map<String, List<WebAuthnCredential>> _userCredentials = {};
  final Map<String, BehavioralBiometrics> _userBiometrics = {};
  final Map<String, GeolocationData> _userLocations = {};

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    developer.log('Initializing Risk-Based Authentication Service', name: 'RiskBasedAuthService');
    
    await _generateInitialData();
    _startRealTimeUpdates();
    
    _isInitialized = true;
    developer.log('Risk-Based Authentication Service initialized', name: 'RiskBasedAuthService');
  }

  Future<void> _generateInitialData() async {
    // Generate sample trusted devices
    _userTrustedDevices['user1'] = _generateTrustedDevices('user1');
    _userTrustedDevices['admin'] = _generateTrustedDevices('admin');
    
    // Generate sample WebAuthn credentials
    _userCredentials['user1'] = _generateWebAuthnCredentials('user1');
    _userCredentials['admin'] = _generateWebAuthnCredentials('admin');
    
    // Generate sample behavioral biometrics
    _userBiometrics['user1'] = _generateBehavioralBiometrics('user1');
    _userBiometrics['admin'] = _generateBehavioralBiometrics('admin');
    
    // Generate sample geolocation data
    _userLocations['user1'] = _generateGeolocationData('user1');
    _userLocations['admin'] = _generateGeolocationData('admin');
  }

  void _startRealTimeUpdates() {
    // Update risk assessments periodically
    _riskUpdateTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _updateRiskAssessments();
    });
  }

  void _updateRiskAssessments() {
    for (final userId in _userTrustedDevices.keys) {
      final assessment = _generateRiskAssessment(userId);
      _riskAssessments[userId] = assessment;
      _riskAssessmentController.add(assessment);
    }
  }

  List<TrustedDevice> _generateTrustedDevices(String userId) {
    return [
      TrustedDevice(
        id: 'device_1_$userId',
        userId: userId,
        deviceFingerprint: _generateDeviceFingerprint(),
        deviceName: 'iPhone 14 Pro',
        deviceType: 'mobile',
        operatingSystem: 'iOS 17.1',
        browser: 'Safari',
        trustLevel: DeviceTrustLevel.highly_trusted,
        firstSeen: DateTime.now().subtract(const Duration(days: 30)),
        lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
        trustedAt: DateTime.now().subtract(const Duration(days: 25)),
        trustedBy: userId,
        loginCount: 45,
        ipAddresses: ['192.168.1.100', '10.0.0.50'],
      ),
      TrustedDevice(
        id: 'device_2_$userId',
        userId: userId,
        deviceFingerprint: _generateDeviceFingerprint(),
        deviceName: 'MacBook Pro',
        deviceType: 'desktop',
        operatingSystem: 'macOS 14.1',
        browser: 'Chrome',
        trustLevel: DeviceTrustLevel.trusted,
        firstSeen: DateTime.now().subtract(const Duration(days: 60)),
        lastSeen: DateTime.now().subtract(const Duration(hours: 8)),
        trustedAt: DateTime.now().subtract(const Duration(days: 50)),
        trustedBy: userId,
        loginCount: 120,
        ipAddresses: ['192.168.1.101', '203.0.113.45'],
      ),
      TrustedDevice(
        id: 'device_3_$userId',
        userId: userId,
        deviceFingerprint: _generateDeviceFingerprint(),
        deviceName: 'Unknown Device',
        deviceType: 'mobile',
        operatingSystem: 'Android 13',
        browser: 'Chrome Mobile',
        trustLevel: DeviceTrustLevel.unknown,
        firstSeen: DateTime.now().subtract(const Duration(hours: 1)),
        lastSeen: DateTime.now().subtract(const Duration(minutes: 30)),
        loginCount: 1,
        ipAddresses: ['198.51.100.42'],
      ),
    ];
  }

  List<WebAuthnCredential> _generateWebAuthnCredentials(String userId) {
    return [
      WebAuthnCredential(
        id: 'cred_1_$userId',
        userId: userId,
        credentialId: _generateCredentialId(),
        publicKey: _generatePublicKey(),
        authenticatorType: 'platform',
        isResident: true,
        transports: ['internal', 'hybrid'],
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        lastUsed: DateTime.now().subtract(const Duration(hours: 6)),
        useCount: 25,
        name: 'Touch ID - iPhone',
      ),
      WebAuthnCredential(
        id: 'cred_2_$userId',
        userId: userId,
        credentialId: _generateCredentialId(),
        publicKey: _generatePublicKey(),
        authenticatorType: 'cross-platform',
        isResident: false,
        transports: ['usb', 'nfc'],
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        lastUsed: DateTime.now().subtract(const Duration(days: 2)),
        useCount: 8,
        name: 'YubiKey 5 NFC',
      ),
    ];
  }

  BehavioralBiometrics _generateBehavioralBiometrics(String userId) {
    return BehavioralBiometrics(
      id: 'bio_$userId',
      userId: userId,
      sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
      keystrokeDynamics: KeystrokeDynamics(
        avgDwellTime: 80 + _random.nextDouble() * 40,
        avgFlightTime: 120 + _random.nextDouble() * 60,
        typingSpeed: 200 + _random.nextDouble() * 100,
        rhythmConsistency: 0.7 + _random.nextDouble() * 0.3,
        keyPairTimings: {
          'th': 45.2,
          'er': 38.7,
          'in': 52.1,
        },
        pressureLevels: [0.6, 0.8, 0.7, 0.9, 0.5],
      ),
      mousePattern: MouseMovementPattern(
        avgVelocity: 150 + _random.nextDouble() * 100,
        avgAcceleration: 50 + _random.nextDouble() * 30,
        clickFrequency: 2.5 + _random.nextDouble() * 2,
        movementSmoothness: 0.8 + _random.nextDouble() * 0.2,
        trajectoryAngles: [45.0, 90.0, 135.0, 180.0],
        pauseDuration: 500 + _random.nextDouble() * 1000,
      ),
      touchBehavior: TouchBehavior(
        avgPressure: 0.6 + _random.nextDouble() * 0.4,
        avgTouchArea: 15 + _random.nextDouble() * 10,
        swipeVelocity: 200 + _random.nextDouble() * 150,
        tapDuration: 100 + _random.nextDouble() * 50,
        gesturePatterns: [1.2, 0.8, 1.5, 0.9],
      ),
      confidenceScore: 0.85 + _random.nextDouble() * 0.15,
      isAuthentic: true,
      capturedAt: DateTime.now(),
    );
  }

  GeolocationData _generateGeolocationData(String userId) {
    final locations = [
      {'lat': 40.7128, 'lng': -74.0060, 'country': 'USA', 'city': 'New York', 'region': 'NY'},
      {'lat': 51.5074, 'lng': -0.1278, 'country': 'UK', 'city': 'London', 'region': 'England'},
      {'lat': 35.6762, 'lng': 139.6503, 'country': 'Japan', 'city': 'Tokyo', 'region': 'Kanto'},
    ];
    
    final location = locations[_random.nextInt(locations.length)];
    
    return GeolocationData(
      id: 'geo_$userId',
      latitude: location['lat'] as double,
      longitude: location['lng'] as double,
      country: location['country'] as String,
      region: location['region'] as String,
      city: location['city'] as String,
      timezone: 'UTC-5',
      ipAddress: _generateRandomIP(),
      riskLevel: LocationRiskLevel.safe,
      isVpn: _random.nextBool(),
      isTor: false,
      isProxy: _random.nextBool(),
      isp: 'Example ISP',
      detectedAt: DateTime.now(),
    );
  }

  RiskAssessment _generateRiskAssessment(String userId) {
    final riskFactors = <String, RiskFactor>{};
    double totalRiskScore = 0.0;
    
    // Device trust factor
    final devices = _userTrustedDevices[userId] ?? [];
    final currentDevice = devices.isNotEmpty ? devices.first : null;
    if (currentDevice != null) {
      final deviceRisk = _calculateDeviceRisk(currentDevice);
      riskFactors['device_trust'] = deviceRisk;
      totalRiskScore += deviceRisk.score * deviceRisk.weight;
    }
    
    // Location risk factor
    final location = _userLocations[userId];
    if (location != null) {
      final locationRisk = _calculateLocationRisk(location);
      riskFactors['location'] = locationRisk;
      totalRiskScore += locationRisk.score * locationRisk.weight;
    }
    
    // Behavioral biometrics factor
    final biometrics = _userBiometrics[userId];
    if (biometrics != null) {
      final biometricRisk = _calculateBiometricRisk(biometrics);
      riskFactors['behavioral_biometrics'] = biometricRisk;
      totalRiskScore += biometricRisk.score * biometricRisk.weight;
    }
    
    // Time-based factor
    final timeRisk = _calculateTimeBasedRisk();
    riskFactors['time_based'] = timeRisk;
    totalRiskScore += timeRisk.score * timeRisk.weight;
    
    // Determine overall risk level
    final overallRisk = _determineRiskLevel(totalRiskScore);
    final authRequirement = _determineAuthRequirement(overallRisk);
    
    return RiskAssessment(
      id: 'risk_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
      overallRisk: overallRisk,
      riskScore: totalRiskScore,
      assessedAt: DateTime.now(),
      riskFactors: riskFactors,
      triggeredRules: _getTriggeredRules(riskFactors),
      authRequirement: authRequirement,
      validityPeriod: _getValidityPeriod(overallRisk),
    );
  }

  RiskFactor _calculateDeviceRisk(TrustedDevice device) {
    double score = 0.0;
    String description = '';
    RiskLevel level = RiskLevel.low;
    
    switch (device.trustLevel) {
      case DeviceTrustLevel.highly_trusted:
        score = 0.1;
        description = 'Highly trusted device with established usage pattern';
        level = RiskLevel.very_low;
        break;
      case DeviceTrustLevel.trusted:
        score = 0.3;
        description = 'Trusted device with good usage history';
        level = RiskLevel.low;
        break;
      case DeviceTrustLevel.untrusted:
        score = 0.7;
        description = 'Untrusted device requiring additional verification';
        level = RiskLevel.high;
        break;
      case DeviceTrustLevel.unknown:
        score = 0.9;
        description = 'Unknown device with no established trust';
        level = RiskLevel.very_high;
        break;
    }
    
    return RiskFactor(
      name: 'Device Trust',
      weight: 0.3,
      score: score,
      description: description,
      level: level,
      details: {
        'device_name': device.deviceName,
        'trust_level': device.trustLevel.name,
        'login_count': device.loginCount,
      },
    );
  }

  RiskFactor _calculateLocationRisk(GeolocationData location) {
    double score = 0.0;
    String description = '';
    RiskLevel level = RiskLevel.low;
    
    if (location.isVpn || location.isTor || location.isProxy) {
      score = 0.8;
      description = 'Login from VPN/Proxy/Tor network';
      level = RiskLevel.high;
    } else {
      switch (location.riskLevel) {
        case LocationRiskLevel.safe:
          score = 0.1;
          description = 'Login from safe, known location';
          level = RiskLevel.very_low;
          break;
        case LocationRiskLevel.low_risk:
          score = 0.3;
          description = 'Login from low-risk location';
          level = RiskLevel.low;
          break;
        case LocationRiskLevel.medium_risk:
          score = 0.5;
          description = 'Login from medium-risk location';
          level = RiskLevel.medium;
          break;
        case LocationRiskLevel.high_risk:
          score = 0.8;
          description = 'Login from high-risk location';
          level = RiskLevel.high;
          break;
        case LocationRiskLevel.blocked:
          score = 1.0;
          description = 'Login from blocked location';
          level = RiskLevel.very_high;
          break;
      }
    }
    
    return RiskFactor(
      name: 'Location Risk',
      weight: 0.25,
      score: score,
      description: description,
      level: level,
      details: {
        'country': location.country,
        'city': location.city,
        'is_vpn': location.isVpn,
        'is_tor': location.isTor,
        'ip_address': location.ipAddress,
      },
    );
  }

  RiskFactor _calculateBiometricRisk(BehavioralBiometrics biometrics) {
    double score = 1.0 - biometrics.confidenceScore;
    String description = '';
    RiskLevel level = RiskLevel.low;
    
    if (biometrics.confidenceScore >= 0.9) {
      description = 'Strong behavioral match with user profile';
      level = RiskLevel.very_low;
    } else if (biometrics.confidenceScore >= 0.7) {
      description = 'Good behavioral match with minor variations';
      level = RiskLevel.low;
    } else if (biometrics.confidenceScore >= 0.5) {
      description = 'Moderate behavioral match with some concerns';
      level = RiskLevel.medium;
    } else {
      description = 'Poor behavioral match, possible impersonation';
      level = RiskLevel.high;
    }
    
    return RiskFactor(
      name: 'Behavioral Biometrics',
      weight: 0.2,
      score: score,
      description: description,
      level: level,
      details: {
        'confidence_score': biometrics.confidenceScore,
        'typing_speed': biometrics.keystrokeDynamics.typingSpeed,
        'mouse_velocity': biometrics.mousePattern.avgVelocity,
      },
    );
  }

  RiskFactor _calculateTimeBasedRisk() {
    final now = DateTime.now();
    final hour = now.hour;
    
    double score = 0.0;
    String description = '';
    RiskLevel level = RiskLevel.low;
    
    if (hour >= 9 && hour <= 17) {
      // Business hours
      score = 0.1;
      description = 'Login during normal business hours';
      level = RiskLevel.very_low;
    } else if ((hour >= 7 && hour < 9) || (hour > 17 && hour <= 22)) {
      // Extended hours
      score = 0.3;
      description = 'Login during extended hours';
      level = RiskLevel.low;
    } else {
      // Off hours
      score = 0.6;
      description = 'Login during off-hours';
      level = RiskLevel.medium;
    }
    
    return RiskFactor(
      name: 'Time-based Risk',
      weight: 0.15,
      score: score,
      description: description,
      level: level,
      details: {
        'hour': hour,
        'day_of_week': now.weekday,
        'is_weekend': now.weekday >= 6,
      },
    );
  }

  RiskLevel _determineRiskLevel(double score) {
    if (score <= 0.2) return RiskLevel.very_low;
    if (score <= 0.4) return RiskLevel.low;
    if (score <= 0.6) return RiskLevel.medium;
    if (score <= 0.8) return RiskLevel.high;
    return RiskLevel.very_high;
  }

  AuthenticationRequirement _determineAuthRequirement(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.very_low:
        return AuthenticationRequirement(
          requiredMethods: [AuthenticationMethod.password],
          minimumFactors: 1,
          allowRememberDevice: true,
          sessionTimeout: const Duration(hours: 8),
          requireReauth: false,
        );
      case RiskLevel.low:
        return AuthenticationRequirement(
          requiredMethods: [AuthenticationMethod.password],
          minimumFactors: 1,
          allowRememberDevice: true,
          sessionTimeout: const Duration(hours: 4),
          requireReauth: false,
        );
      case RiskLevel.medium:
        return AuthenticationRequirement(
          requiredMethods: [AuthenticationMethod.password, AuthenticationMethod.totp],
          minimumFactors: 2,
          allowRememberDevice: false,
          sessionTimeout: const Duration(hours: 2),
          requireReauth: true,
        );
      case RiskLevel.high:
        return AuthenticationRequirement(
          requiredMethods: [AuthenticationMethod.password, AuthenticationMethod.totp, AuthenticationMethod.biometric],
          minimumFactors: 3,
          allowRememberDevice: false,
          sessionTimeout: const Duration(hours: 1),
          requireReauth: true,
        );
      case RiskLevel.very_high:
        return AuthenticationRequirement(
          requiredMethods: [AuthenticationMethod.password, AuthenticationMethod.hardware_key],
          minimumFactors: 2,
          allowRememberDevice: false,
          sessionTimeout: const Duration(minutes: 30),
          requireReauth: true,
          constraints: {'admin_approval_required': true},
        );
    }
  }

  List<String> _getTriggeredRules(Map<String, RiskFactor> riskFactors) {
    final rules = <String>[];
    
    for (final factor in riskFactors.values) {
      if (factor.level == RiskLevel.high || factor.level == RiskLevel.very_high) {
        rules.add('High risk detected: ${factor.name}');
      }
    }
    
    return rules;
  }

  Duration _getValidityPeriod(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.very_low:
        return const Duration(hours: 24);
      case RiskLevel.low:
        return const Duration(hours: 12);
      case RiskLevel.medium:
        return const Duration(hours: 4);
      case RiskLevel.high:
        return const Duration(hours: 1);
      case RiskLevel.very_high:
        return const Duration(minutes: 15);
    }
  }

  // Utility methods
  String _generateDeviceFingerprint() {
    const chars = '0123456789abcdef';
    return List.generate(32, (index) => chars[_random.nextInt(chars.length)]).join();
  }

  String _generateCredentialId() {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    return List.generate(64, (index) => chars[_random.nextInt(chars.length)]).join();
  }

  String _generatePublicKey() {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/';
    return List.generate(128, (index) => chars[_random.nextInt(chars.length)]).join();
  }

  String _generateRandomIP() {
    return '${_random.nextInt(256)}.${_random.nextInt(256)}.${_random.nextInt(256)}.${_random.nextInt(256)}';
  }

  // Public API methods
  Future<RiskAssessment> assessRisk(String userId, {
    String? deviceFingerprint,
    GeolocationData? location,
    BehavioralBiometrics? biometrics,
  }) async {
    await initialize();
    
    // Update user data if provided
    if (location != null) {
      _userLocations[userId] = location;
    }
    
    if (biometrics != null) {
      _userBiometrics[userId] = biometrics;
      _biometricsController.add(biometrics);
    }
    
    final assessment = _generateRiskAssessment(userId);
    _riskAssessments[userId] = assessment;
    _riskAssessmentController.add(assessment);
    
    return assessment;
  }

  Future<List<TrustedDevice>> getTrustedDevices(String userId) async {
    await initialize();
    return _userTrustedDevices[userId] ?? [];
  }

  Future<TrustedDevice> addTrustedDevice(String userId, {
    required String deviceFingerprint,
    required String deviceName,
    required String deviceType,
    required String operatingSystem,
    required String browser,
  }) async {
    await initialize();
    
    final device = TrustedDevice(
      id: 'device_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      deviceFingerprint: deviceFingerprint,
      deviceName: deviceName,
      deviceType: deviceType,
      operatingSystem: operatingSystem,
      browser: browser,
      trustLevel: DeviceTrustLevel.unknown,
      firstSeen: DateTime.now(),
      lastSeen: DateTime.now(),
    );
    
    _userTrustedDevices.putIfAbsent(userId, () => []).add(device);
    _trustedDevicesController.add(_userTrustedDevices[userId]!);
    
    return device;
  }

  Future<void> updateDeviceTrust(String deviceId, DeviceTrustLevel trustLevel) async {
    await initialize();
    
    for (final devices in _userTrustedDevices.values) {
      final index = devices.indexWhere((d) => d.id == deviceId);
      if (index != -1) {
        final device = devices[index];
        devices[index] = TrustedDevice(
          id: device.id,
          userId: device.userId,
          deviceFingerprint: device.deviceFingerprint,
          deviceName: device.deviceName,
          deviceType: device.deviceType,
          operatingSystem: device.operatingSystem,
          browser: device.browser,
          trustLevel: trustLevel,
          firstSeen: device.firstSeen,
          lastSeen: DateTime.now(),
          trustedAt: trustLevel == DeviceTrustLevel.trusted || trustLevel == DeviceTrustLevel.highly_trusted
              ? DateTime.now()
              : device.trustedAt,
          trustedBy: device.trustedBy,
          isActive: device.isActive,
          loginCount: device.loginCount + 1,
          ipAddresses: device.ipAddresses,
          attributes: device.attributes,
        );
        
        _trustedDevicesController.add(devices);
        break;
      }
    }
  }

  Future<List<WebAuthnCredential>> getWebAuthnCredentials(String userId) async {
    await initialize();
    return _userCredentials[userId] ?? [];
  }

  Future<WebAuthnCredential> registerWebAuthnCredential(String userId, {
    required String credentialId,
    required String publicKey,
    required String authenticatorType,
    required String name,
    List<String> transports = const [],
  }) async {
    await initialize();
    
    final credential = WebAuthnCredential(
      id: 'cred_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      credentialId: credentialId,
      publicKey: publicKey,
      authenticatorType: authenticatorType,
      transports: transports,
      createdAt: DateTime.now(),
      name: name,
    );
    
    _userCredentials.putIfAbsent(userId, () => []).add(credential);
    
    return credential;
  }

  Future<BehavioralBiometrics?> captureBehavioralBiometrics(String userId, {
    required KeystrokeDynamics keystrokeDynamics,
    required MouseMovementPattern mousePattern,
    TouchBehavior? touchBehavior,
  }) async {
    await initialize();
    
    // Simulate biometric analysis
    final confidence = 0.7 + _random.nextDouble() * 0.3;
    
    final biometrics = BehavioralBiometrics(
      id: 'bio_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
      keystrokeDynamics: keystrokeDynamics,
      mousePattern: mousePattern,
      touchBehavior: touchBehavior,
      confidenceScore: confidence,
      isAuthentic: confidence > 0.6,
      capturedAt: DateTime.now(),
    );
    
    _userBiometrics[userId] = biometrics;
    _biometricsController.add(biometrics);
    
    return biometrics;
  }

  Future<GeolocationData> detectGeolocation(String ipAddress) async {
    await initialize();
    
    // Simulate geolocation detection
    final locations = [
      {'lat': 40.7128, 'lng': -74.0060, 'country': 'USA', 'city': 'New York', 'region': 'NY'},
      {'lat': 51.5074, 'lng': -0.1278, 'country': 'UK', 'city': 'London', 'region': 'England'},
    ];
    
    final location = locations[_random.nextInt(locations.length)];
    
    return GeolocationData(
      id: 'geo_${DateTime.now().millisecondsSinceEpoch}',
      latitude: location['lat'] as double,
      longitude: location['lng'] as double,
      country: location['country'] as String,
      region: location['region'] as String,
      city: location['city'] as String,
      timezone: 'UTC-5',
      ipAddress: ipAddress,
      riskLevel: LocationRiskLevel.safe,
      isVpn: _random.nextDouble() < 0.1,
      isTor: false,
      isProxy: _random.nextDouble() < 0.05,
      isp: 'Example ISP',
      detectedAt: DateTime.now(),
    );
  }

  void dispose() {
    _riskUpdateTimer?.cancel();
    
    _riskAssessmentController.close();
    _trustedDevicesController.close();
    _biometricsController.close();
  }
}
