import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DeviceRiskLevel {
  low,
  medium,
  high,
  critical,
}

enum AnomalyType {
  newDevice,
  locationChange,
  behaviorChange,
  timePattern,
  deviceSpoof,
  jailbroken,
  emulator,
  vpnUsage,
}

class DeviceFingerprint {
  final String deviceId;
  final String platform;
  final String model;
  final String osVersion;
  final String appVersion;
  final String screenResolution;
  final String timezone;
  final String locale;
  final List<String> installedApps;
  final Map<String, dynamic> hardwareInfo;
  final Map<String, dynamic> networkInfo;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final int accessCount;
  final DeviceRiskLevel riskLevel;
  final bool isTrusted;
  final bool isJailbroken;
  final bool isEmulator;

  DeviceFingerprint({
    required this.deviceId,
    required this.platform,
    required this.model,
    required this.osVersion,
    required this.appVersion,
    required this.screenResolution,
    required this.timezone,
    required this.locale,
    this.installedApps = const [],
    this.hardwareInfo = const {},
    this.networkInfo = const {},
    required this.firstSeen,
    required this.lastSeen,
    this.accessCount = 1,
    this.riskLevel = DeviceRiskLevel.low,
    this.isTrusted = false,
    this.isJailbroken = false,
    this.isEmulator = false,
  });

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'platform': platform,
    'model': model,
    'osVersion': osVersion,
    'appVersion': appVersion,
    'screenResolution': screenResolution,
    'timezone': timezone,
    'locale': locale,
    'installedApps': installedApps,
    'hardwareInfo': hardwareInfo,
    'networkInfo': networkInfo,
    'firstSeen': firstSeen.toIso8601String(),
    'lastSeen': lastSeen.toIso8601String(),
    'accessCount': accessCount,
    'riskLevel': riskLevel.name,
    'isTrusted': isTrusted,
    'isJailbroken': isJailbroken,
    'isEmulator': isEmulator,
  };

  factory DeviceFingerprint.fromJson(Map<String, dynamic> json) {
    return DeviceFingerprint(
      deviceId: json['deviceId'],
      platform: json['platform'],
      model: json['model'],
      osVersion: json['osVersion'],
      appVersion: json['appVersion'],
      screenResolution: json['screenResolution'],
      timezone: json['timezone'],
      locale: json['locale'],
      installedApps: List<String>.from(json['installedApps'] ?? []),
      hardwareInfo: Map<String, dynamic>.from(json['hardwareInfo'] ?? {}),
      networkInfo: Map<String, dynamic>.from(json['networkInfo'] ?? {}),
      firstSeen: DateTime.parse(json['firstSeen']),
      lastSeen: DateTime.parse(json['lastSeen']),
      accessCount: json['accessCount'] ?? 1,
      riskLevel: DeviceRiskLevel.values.firstWhere(
        (e) => e.name == json['riskLevel'],
        orElse: () => DeviceRiskLevel.low,
      ),
      isTrusted: json['isTrusted'] ?? false,
      isJailbroken: json['isJailbroken'] ?? false,
      isEmulator: json['isEmulator'] ?? false,
    );
  }

  DeviceFingerprint copyWith({
    DateTime? lastSeen,
    int? accessCount,
    DeviceRiskLevel? riskLevel,
    bool? isTrusted,
    bool? isJailbroken,
    bool? isEmulator,
  }) {
    return DeviceFingerprint(
      deviceId: deviceId,
      platform: platform,
      model: model,
      osVersion: osVersion,
      appVersion: appVersion,
      screenResolution: screenResolution,
      timezone: timezone,
      locale: locale,
      installedApps: installedApps,
      hardwareInfo: hardwareInfo,
      networkInfo: networkInfo,
      firstSeen: firstSeen,
      lastSeen: lastSeen ?? this.lastSeen,
      accessCount: accessCount ?? this.accessCount,
      riskLevel: riskLevel ?? this.riskLevel,
      isTrusted: isTrusted ?? this.isTrusted,
      isJailbroken: isJailbroken ?? this.isJailbroken,
      isEmulator: isEmulator ?? this.isEmulator,
    );
  }
}

class DeviceAnomaly {
  final String id;
  final String deviceId;
  final String? userEmail;
  final AnomalyType type;
  final String description;
  final double severity; // 0.0 to 1.0
  final DateTime timestamp;
  final Map<String, dynamic> details;
  final bool resolved;

  DeviceAnomaly({
    required this.id,
    required this.deviceId,
    this.userEmail,
    required this.type,
    required this.description,
    required this.severity,
    required this.timestamp,
    this.details = const {},
    this.resolved = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'deviceId': deviceId,
    'userEmail': userEmail,
    'type': type.name,
    'description': description,
    'severity': severity,
    'timestamp': timestamp.toIso8601String(),
    'details': details,
    'resolved': resolved,
  };

  factory DeviceAnomaly.fromJson(Map<String, dynamic> json) {
    return DeviceAnomaly(
      id: json['id'],
      deviceId: json['deviceId'],
      userEmail: json['userEmail'],
      type: AnomalyType.values.firstWhere((e) => e.name == json['type']),
      description: json['description'],
      severity: json['severity'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      details: Map<String, dynamic>.from(json['details'] ?? {}),
      resolved: json['resolved'] ?? false,
    );
  }
}

class UserBehaviorProfile {
  final String userEmail;
  final Map<String, int> accessPatterns; // hour -> count
  final Map<String, int> locationPatterns; // location -> count
  final Map<String, int> devicePatterns; // deviceId -> count
  final List<String> typicalIPs;
  final Duration averageSessionLength;
  final Map<String, double> featureUsage; // feature -> usage_ratio
  final DateTime lastUpdated;

  UserBehaviorProfile({
    required this.userEmail,
    this.accessPatterns = const {},
    this.locationPatterns = const {},
    this.devicePatterns = const {},
    this.typicalIPs = const [],
    this.averageSessionLength = const Duration(minutes: 30),
    this.featureUsage = const {},
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'userEmail': userEmail,
    'accessPatterns': accessPatterns,
    'locationPatterns': locationPatterns,
    'devicePatterns': devicePatterns,
    'typicalIPs': typicalIPs,
    'averageSessionLength': averageSessionLength.inMilliseconds,
    'featureUsage': featureUsage,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory UserBehaviorProfile.fromJson(Map<String, dynamic> json) {
    return UserBehaviorProfile(
      userEmail: json['userEmail'],
      accessPatterns: Map<String, int>.from(json['accessPatterns'] ?? {}),
      locationPatterns: Map<String, int>.from(json['locationPatterns'] ?? {}),
      devicePatterns: Map<String, int>.from(json['devicePatterns'] ?? {}),
      typicalIPs: List<String>.from(json['typicalIPs'] ?? []),
      averageSessionLength: Duration(milliseconds: json['averageSessionLength'] ?? 1800000),
      featureUsage: Map<String, double>.from(json['featureUsage'] ?? {}),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}

class DeviceFingerprintingService extends ChangeNotifier {
  final Map<String, DeviceFingerprint> _devices = {};
  final List<DeviceAnomaly> _anomalies = [];
  final Map<String, UserBehaviorProfile> _behaviorProfiles = {};
  Timer? _analysisTimer;
  
  static const String _devicesKey = 'device_fingerprints';
  static const String _anomaliesKey = 'device_anomalies';
  static const String _behaviorProfilesKey = 'behavior_profiles';

  // Getters
  List<DeviceFingerprint> get devices => _devices.values.toList();
  List<DeviceAnomaly> get anomalies => List.unmodifiable(_anomalies);
  List<UserBehaviorProfile> get behaviorProfiles => _behaviorProfiles.values.toList();

  /// Initialize device fingerprinting service
  Future<void> initialize() async {
    await _loadDevices();
    await _loadAnomalies();
    await _loadBehaviorProfiles();
    await _startAnalysis();
  }

  /// Load devices from storage
  Future<void> _loadDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final devicesJson = prefs.getStringList(_devicesKey) ?? [];
      
      _devices.clear();
      for (final deviceJson in devicesJson) {
        final Map<String, dynamic> data = jsonDecode(deviceJson);
        final device = DeviceFingerprint.fromJson(data);
        _devices[device.deviceId] = device;
      }
    } catch (e) {
      debugPrint('Error loading devices: $e');
    }
  }

  /// Save devices to storage
  Future<void> _saveDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final devicesJson = _devices.values.map((d) => jsonEncode(d.toJson())).toList();
      await prefs.setStringList(_devicesKey, devicesJson);
    } catch (e) {
      debugPrint('Error saving devices: $e');
    }
  }

  /// Load anomalies from storage
  Future<void> _loadAnomalies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final anomaliesJson = prefs.getStringList(_anomaliesKey) ?? [];
      
      _anomalies.clear();
      for (final anomalyJson in anomaliesJson) {
        final Map<String, dynamic> data = jsonDecode(anomalyJson);
        _anomalies.add(DeviceAnomaly.fromJson(data));
      }
    } catch (e) {
      debugPrint('Error loading anomalies: $e');
    }
  }

  /// Save anomalies to storage
  Future<void> _saveAnomalies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final anomaliesJson = _anomalies.map((a) => jsonEncode(a.toJson())).toList();
      await prefs.setStringList(_anomaliesKey, anomaliesJson);
    } catch (e) {
      debugPrint('Error saving anomalies: $e');
    }
  }

  /// Load behavior profiles from storage
  Future<void> _loadBehaviorProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = prefs.getStringList(_behaviorProfilesKey) ?? [];
      
      _behaviorProfiles.clear();
      for (final profileJson in profilesJson) {
        final Map<String, dynamic> data = jsonDecode(profileJson);
        final profile = UserBehaviorProfile.fromJson(data);
        _behaviorProfiles[profile.userEmail] = profile;
      }
    } catch (e) {
      debugPrint('Error loading behavior profiles: $e');
    }
  }

  /// Save behavior profiles to storage
  Future<void> _saveBehaviorProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = _behaviorProfiles.values.map((p) => jsonEncode(p.toJson())).toList();
      await prefs.setStringList(_behaviorProfilesKey, profilesJson);
    } catch (e) {
      debugPrint('Error saving behavior profiles: $e');
    }
  }

  /// Start continuous analysis
  Future<void> _startAnalysis() async {
    _analysisTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _performAnomalyAnalysis();
    });
  }

  /// Generate device fingerprint
  Future<DeviceFingerprint> generateFingerprint({String? userEmail}) async {
    final deviceInfo = await _getDeviceInfo();
    final screenInfo = _getScreenInfo();
    final localeInfo = _getLocaleInfo();
    final now = DateTime.now();
    
    try {
      String deviceId = 'flutter_device_${DateTime.now().millisecondsSinceEpoch}';
      String platform = deviceInfo['platform'] ?? 'Unknown';
      String model = 'Flutter Device';
      String osVersion = 'Flutter Framework';
      bool isJailbroken = false;
      bool isEmulator = false;
      
      // Get screen info
      final screenResolution = '${screenInfo['width']}x${screenInfo['height']}';
      
      // Get locale and timezone
      final locale = localeInfo['toString'];
      final timezone = DateTime.now().timeZoneName;
      
      // Calculate risk level
      final riskLevel = _calculateDeviceRiskLevel(
        isJailbroken: isJailbroken,
        isEmulator: isEmulator,
        isNewDevice: !_devices.containsKey(deviceId),
      );
      
      final fingerprint = DeviceFingerprint(
        deviceId: deviceId,
        platform: platform,
        model: model,
        osVersion: osVersion,
        appVersion: '1.0.0', // Get from package info
        screenResolution: screenResolution,
        timezone: timezone,
        locale: locale,
        firstSeen: _devices[deviceId]?.firstSeen ?? now,
        lastSeen: now,
        accessCount: (_devices[deviceId]?.accessCount ?? 0) + 1,
        riskLevel: riskLevel,
        isJailbroken: isJailbroken,
        isEmulator: isEmulator,
      );
      
      // Check for anomalies
      await _checkForAnomalies(fingerprint, userEmail);
      
      // Update device registry
      _devices[deviceId] = fingerprint;
      await _saveDevices();
      
      notifyListeners();
      return fingerprint;
      
    } catch (e) {
      debugPrint('Error generating fingerprint: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      // Simplified device info without external dependencies
      return {
        'platform': 'Flutter',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'userAgent': 'Flutter App',
      };
    } catch (e) {
      return {'platform': 'Unknown', 'error': e.toString()};
    }
  }

  Map<String, dynamic> _getScreenInfo() {
    try {
      // Simplified screen info
      return {
        'width': 1080,
        'height': 1920,
        'devicePixelRatio': 2.0,
        'logicalWidth': 540,
        'logicalHeight': 960,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Map<String, dynamic> _getLocaleInfo() {
    try {
      // Simplified locale info
      return {
        'languageCode': 'en',
        'countryCode': 'US',
        'toString': 'en_US',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }


  /// Calculate device risk level
  DeviceRiskLevel _calculateDeviceRiskLevel({
    required bool isJailbroken,
    required bool isEmulator,
    required bool isNewDevice,
  }) {
    int riskScore = 0;
    
    if (isJailbroken) riskScore += 3;
    if (isEmulator) riskScore += 2;
    if (isNewDevice) riskScore += 1;
    
    if (riskScore >= 4) return DeviceRiskLevel.critical;
    if (riskScore >= 3) return DeviceRiskLevel.high;
    if (riskScore >= 2) return DeviceRiskLevel.medium;
    return DeviceRiskLevel.low;
  }

  /// Check for anomalies
  Future<void> _checkForAnomalies(DeviceFingerprint fingerprint, String? userEmail) async {
    final existingDevice = _devices[fingerprint.deviceId];
    
    // New device anomaly
    if (existingDevice == null && userEmail != null) {
      await _recordAnomaly(
        deviceId: fingerprint.deviceId,
        userEmail: userEmail,
        type: AnomalyType.newDevice,
        description: 'New device detected for user',
        severity: 0.6,
        details: {
          'platform': fingerprint.platform,
          'model': fingerprint.model,
        },
      );
    }
    
    // Jailbreak/root detection
    if (fingerprint.isJailbroken) {
      await _recordAnomaly(
        deviceId: fingerprint.deviceId,
        userEmail: userEmail,
        type: AnomalyType.jailbroken,
        description: 'Jailbroken/rooted device detected',
        severity: 0.8,
        details: {
          'platform': fingerprint.platform,
        },
      );
    }
    
    // Emulator detection
    if (fingerprint.isEmulator) {
      await _recordAnomaly(
        deviceId: fingerprint.deviceId,
        userEmail: userEmail,
        type: AnomalyType.emulator,
        description: 'Emulator/simulator detected',
        severity: 0.7,
        details: {
          'platform': fingerprint.platform,
        },
      );
    }
    
    // Device spoofing detection (simplified)
    if (existingDevice != null) {
      if (existingDevice.model != fingerprint.model ||
          existingDevice.osVersion != fingerprint.osVersion) {
        await _recordAnomaly(
          deviceId: fingerprint.deviceId,
          userEmail: userEmail,
          type: AnomalyType.deviceSpoof,
          description: 'Device characteristics changed unexpectedly',
          severity: 0.9,
          details: {
            'old_model': existingDevice.model,
            'new_model': fingerprint.model,
            'old_os': existingDevice.osVersion,
            'new_os': fingerprint.osVersion,
          },
        );
      }
    }
  }

  /// Record anomaly
  Future<void> _recordAnomaly({
    required String deviceId,
    String? userEmail,
    required AnomalyType type,
    required String description,
    required double severity,
    Map<String, dynamic> details = const {},
  }) async {
    final anomaly = DeviceAnomaly(
      id: 'anomaly_${DateTime.now().millisecondsSinceEpoch}',
      deviceId: deviceId,
      userEmail: userEmail,
      type: type,
      description: description,
      severity: severity,
      timestamp: DateTime.now(),
      details: details,
    );
    
    _anomalies.insert(0, anomaly);
    
    // Keep only last 5000 anomalies
    if (_anomalies.length > 5000) {
      _anomalies.removeRange(5000, _anomalies.length);
    }
    
    await _saveAnomalies();
    notifyListeners();
  }

  /// Perform anomaly analysis
  void _performAnomalyAnalysis() {
    // Analyze behavior patterns and detect anomalies
    for (final profile in _behaviorProfiles.values) {
      _analyzeBehaviorPattern(profile);
    }
  }

  /// Analyze behavior pattern
  void _analyzeBehaviorPattern(UserBehaviorProfile profile) {
    final now = DateTime.now();
    final currentHour = now.hour.toString();
    
    // Check for unusual access time
    final typicalAccessCount = profile.accessPatterns[currentHour] ?? 0;
    if (typicalAccessCount == 0) {
      // Unusual time access
      _recordAnomaly(
        deviceId: 'unknown',
        userEmail: profile.userEmail,
        type: AnomalyType.timePattern,
        description: 'Access at unusual time',
        severity: 0.4,
        details: {
          'hour': currentHour,
          'typical_hours': profile.accessPatterns.keys.toList(),
        },
      );
    }
  }

  /// Update behavior profile
  Future<void> updateBehaviorProfile(String userEmail, {
    String? location,
    String? deviceId,
    String? ip,
    Duration? sessionLength,
    Map<String, double>? featureUsage,
  }) async {
    final existing = _behaviorProfiles[userEmail];
    final now = DateTime.now();
    final currentHour = now.hour.toString();
    
    final accessPatterns = Map<String, int>.from(existing?.accessPatterns ?? {});
    accessPatterns[currentHour] = (accessPatterns[currentHour] ?? 0) + 1;
    
    final locationPatterns = Map<String, int>.from(existing?.locationPatterns ?? {});
    if (location != null) {
      locationPatterns[location] = (locationPatterns[location] ?? 0) + 1;
    }
    
    final devicePatterns = Map<String, int>.from(existing?.devicePatterns ?? {});
    if (deviceId != null) {
      devicePatterns[deviceId] = (devicePatterns[deviceId] ?? 0) + 1;
    }
    
    final typicalIPs = List<String>.from(existing?.typicalIPs ?? []);
    if (ip != null && !typicalIPs.contains(ip)) {
      typicalIPs.add(ip);
      if (typicalIPs.length > 10) {
        typicalIPs.removeAt(0); // Keep only last 10 IPs
      }
    }
    
    final profile = UserBehaviorProfile(
      userEmail: userEmail,
      accessPatterns: accessPatterns,
      locationPatterns: locationPatterns,
      devicePatterns: devicePatterns,
      typicalIPs: typicalIPs,
      averageSessionLength: sessionLength ?? existing?.averageSessionLength ?? const Duration(minutes: 30),
      featureUsage: featureUsage ?? existing?.featureUsage ?? {},
      lastUpdated: now,
    );
    
    _behaviorProfiles[userEmail] = profile;
    await _saveBehaviorProfiles();
    notifyListeners();
  }

  /// Trust device
  Future<void> trustDevice(String deviceId) async {
    if (_devices.containsKey(deviceId)) {
      _devices[deviceId] = _devices[deviceId]!.copyWith(
        isTrusted: true,
        riskLevel: DeviceRiskLevel.low,
      );
      await _saveDevices();
      notifyListeners();
    }
  }

  /// Untrust device
  Future<void> untrustDevice(String deviceId) async {
    if (_devices.containsKey(deviceId)) {
      _devices[deviceId] = _devices[deviceId]!.copyWith(isTrusted: false);
      await _saveDevices();
      notifyListeners();
    }
  }

  /// Get device statistics
  Map<String, dynamic> getDeviceStatistics() {
    final totalDevices = _devices.length;
    final trustedDevices = _devices.values.where((d) => d.isTrusted).length;
    final jailbrokenDevices = _devices.values.where((d) => d.isJailbroken).length;
    final emulatorDevices = _devices.values.where((d) => d.isEmulator).length;
    
    final riskDistribution = <String, int>{};
    for (final level in DeviceRiskLevel.values) {
      riskDistribution[level.name] = _devices.values.where((d) => d.riskLevel == level).length;
    }
    
    return {
      'total_devices': totalDevices,
      'trusted_devices': trustedDevices,
      'jailbroken_devices': jailbrokenDevices,
      'emulator_devices': emulatorDevices,
      'active_anomalies': _anomalies.where((a) => !a.resolved).length,
      'total_anomalies': _anomalies.length,
      'behavior_profiles': _behaviorProfiles.length,
      'risk_distribution': riskDistribution,
      'platform_distribution': _getPlatformDistribution(),
    };
  }

  /// Get platform distribution
  Map<String, int> _getPlatformDistribution() {
    final Map<String, int> distribution = {};
    for (final device in _devices.values) {
      distribution[device.platform] = (distribution[device.platform] ?? 0) + 1;
    }
    return distribution;
  }

  /// Export device data
  Map<String, dynamic> exportDeviceData() {
    return {
      'devices': _devices.values.map((d) => d.toJson()).toList(),
      'anomalies': _anomalies.map((a) => a.toJson()).toList(),
      'behavior_profiles': _behaviorProfiles.values.map((p) => p.toJson()).toList(),
      'statistics': getDeviceStatistics(),
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    super.dispose();
  }
}
