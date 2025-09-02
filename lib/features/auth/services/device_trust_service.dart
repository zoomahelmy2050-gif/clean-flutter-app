import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';

class DeviceTrustService extends ChangeNotifier {
  static const String _trustedDevicesKey = 'trusted_devices';
  static const Duration _trustDuration = Duration(days: 30);
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final Uuid _uuid = const Uuid();
  
  List<TrustedDevice> _trustedDevices = [];
  String? _currentDeviceFingerprint;
  
  List<TrustedDevice> get trustedDevices => List.unmodifiable(_trustedDevices);
  String? get currentDeviceFingerprint => _currentDeviceFingerprint;
  
  DeviceTrustService() {
    _initialize();
  }
  
  Future<void> _initialize() async {
    await _loadTrustedDevices();
    _currentDeviceFingerprint = await _generateDeviceFingerprint();
  }
  
  // Register current device as trusted
  Future<TrustedDevice> trustCurrentDevice({
    required String userId,
    String? deviceName,
    bool requireBiometric = false,
  }) async {
    if (requireBiometric) {
      final authenticated = await _authenticateWithBiometric();
      if (!authenticated) {
        throw Exception('Biometric authentication failed');
      }
    }
    
    final fingerprint = await _generateDeviceFingerprint();
    final deviceInfo = await _getDeviceInfo();
    
    final trustedDevice = TrustedDevice(
      id: _uuid.v4(),
      userId: userId,
      fingerprint: fingerprint,
      deviceName: deviceName ?? deviceInfo['deviceName'] ?? 'Unknown Device',
      deviceType: deviceInfo['deviceType'] ?? 'unknown',
      deviceModel: deviceInfo['deviceModel'],
      osVersion: deviceInfo['osVersion'],
      trustedAt: DateTime.now(),
      expiresAt: DateTime.now().add(_trustDuration),
      lastUsedAt: DateTime.now(),
      isActive: true,
      metadata: deviceInfo,
    );
    
    // Remove any existing trust for this device
    _trustedDevices.removeWhere((d) => d.fingerprint == fingerprint);
    
    _trustedDevices.add(trustedDevice);
    await _saveTrustedDevices();
    
    notifyListeners();
    return trustedDevice;
  }
  
  // Check if current device is trusted
  Future<bool> isCurrentDeviceTrusted(String userId) async {
    final fingerprint = await _generateDeviceFingerprint();
    
    try {
      final device = _trustedDevices.firstWhere(
        (d) => d.userId == userId && 
               d.fingerprint == fingerprint && 
               d.isActive && 
               !d.isExpired,
      );
      
      // Update last used
      device.lastUsedAt = DateTime.now();
      await _saveTrustedDevices();
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Revoke device trust
  Future<void> revokeDeviceTrust(String deviceId) async {
    final device = _trustedDevices.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => throw Exception('Device not found'),
    );
    
    device.isActive = false;
    device.revokedAt = DateTime.now();
    
    await _saveTrustedDevices();
    notifyListeners();
  }
  
  // Revoke all trusted devices for a user
  Future<void> revokeAllDevices(String userId) async {
    for (final device in _trustedDevices) {
      if (device.userId == userId) {
        device.isActive = false;
        device.revokedAt = DateTime.now();
      }
    }
    
    await _saveTrustedDevices();
    notifyListeners();
  }
  
  // Extend device trust
  Future<void> extendDeviceTrust(String deviceId) async {
    final device = _trustedDevices.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => throw Exception('Device not found'),
    );
    
    device.expiresAt = DateTime.now().add(_trustDuration);
    await _saveTrustedDevices();
    notifyListeners();
  }
  
  // Get trusted devices for a user
  List<TrustedDevice> getUserTrustedDevices(String userId) {
    return _trustedDevices.where((d) => 
      d.userId == userId && d.isActive
    ).toList()
      ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
  }
  
  // Clean expired devices
  Future<void> cleanExpiredDevices() async {
    final now = DateTime.now();
    _trustedDevices.removeWhere((d) => 
      d.expiresAt.isBefore(now.subtract(const Duration(days: 90)))
    );
    await _saveTrustedDevices();
    notifyListeners();
  }
  
  // Generate device fingerprint
  Future<String> _generateDeviceFingerprint() async {
    final deviceInfo = await _getDeviceInfo();
    
    // Combine device characteristics
    final components = [
      deviceInfo['deviceId'] ?? '',
      deviceInfo['deviceModel'] ?? '',
      deviceInfo['osVersion'] ?? '',
      deviceInfo['deviceType'] ?? '',
    ];
    
    // Generate hash
    final input = components.join('|');
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    
    return digest.toString();
  }
  
  // Get device information
  Future<Map<String, String>> _getDeviceInfo() async {
    final info = <String, String>{};
    
    if (kIsWeb) {
      final webInfo = await _deviceInfo.webBrowserInfo;
      info['deviceId'] = _generateBrowserId(webInfo.userAgent ?? '');
      info['deviceName'] = webInfo.browserName.name;
      info['deviceType'] = 'web';
      info['deviceModel'] = webInfo.browserName.name;
      info['osVersion'] = webInfo.platform ?? 'unknown';
      info['userAgent'] = webInfo.userAgent ?? 'unknown';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await _deviceInfo.androidInfo;
      info['deviceId'] = androidInfo.id;
      info['deviceName'] = '${androidInfo.brand} ${androidInfo.model}';
      info['deviceType'] = 'android';
      info['deviceModel'] = androidInfo.model;
      info['osVersion'] = 'Android ${androidInfo.version.release}';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      info['deviceId'] = iosInfo.identifierForVendor ?? _uuid.v4();
      info['deviceName'] = iosInfo.name;
      info['deviceType'] = 'ios';
      info['deviceModel'] = iosInfo.model;
      info['osVersion'] = 'iOS ${iosInfo.systemVersion}';
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      final windowsInfo = await _deviceInfo.windowsInfo;
      info['deviceId'] = windowsInfo.deviceId;
      info['deviceName'] = windowsInfo.computerName;
      info['deviceType'] = 'windows';
      info['deviceModel'] = windowsInfo.productName;
      info['osVersion'] = 'Build ${windowsInfo.buildNumber}';
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      final macInfo = await _deviceInfo.macOsInfo;
      info['deviceId'] = macInfo.systemGUID ?? _uuid.v4();
      info['deviceName'] = macInfo.computerName;
      info['deviceType'] = 'macos';
      info['deviceModel'] = macInfo.model;
      info['osVersion'] = 'macOS ${macInfo.majorVersion}.${macInfo.minorVersion}';
    } else if (defaultTargetPlatform == TargetPlatform.linux) {
      final linuxInfo = await _deviceInfo.linuxInfo;
      info['deviceId'] = linuxInfo.machineId ?? _uuid.v4();
      info['deviceName'] = linuxInfo.prettyName;
      info['deviceType'] = 'linux';
      info['deviceModel'] = linuxInfo.name;
      info['osVersion'] = linuxInfo.version ?? 'unknown';
    }
    
    return info;
  }
  
  String _generateBrowserId(String userAgent) {
    final bytes = utf8.encode(userAgent);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }
  
  // Authenticate with biometric
  Future<bool> _authenticateWithBiometric() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) return false;
      
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to trust this device',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      
      return didAuthenticate;
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      return false;
    }
  }
  
  // Save trusted devices
  Future<void> _saveTrustedDevices() async {
    final devicesJson = _trustedDevices.map((d) => d.toJson()).toList();
    await _storage.write(
      key: _trustedDevicesKey,
      value: jsonEncode(devicesJson),
    );
  }
  
  // Load trusted devices
  Future<void> _loadTrustedDevices() async {
    try {
      final devicesStr = await _storage.read(key: _trustedDevicesKey);
      if (devicesStr != null) {
        final devicesList = jsonDecode(devicesStr) as List;
        _trustedDevices = devicesList.map((d) => TrustedDevice.fromJson(d)).toList();
      }
    } catch (e) {
      debugPrint('Error loading trusted devices: $e');
    }
  }
}

class TrustedDevice {
  final String id;
  final String userId;
  final String fingerprint;
  final String deviceName;
  final String deviceType;
  final String? deviceModel;
  final String? osVersion;
  final DateTime trustedAt;
  DateTime expiresAt;
  DateTime lastUsedAt;
  DateTime? revokedAt;
  bool isActive;
  final Map<String, dynamic> metadata;
  
  TrustedDevice({
    required this.id,
    required this.userId,
    required this.fingerprint,
    required this.deviceName,
    required this.deviceType,
    this.deviceModel,
    this.osVersion,
    required this.trustedAt,
    required this.expiresAt,
    required this.lastUsedAt,
    this.revokedAt,
    required this.isActive,
    required this.metadata,
  });
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  Duration get timeRemaining => isExpired 
    ? Duration.zero 
    : expiresAt.difference(DateTime.now());
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'fingerprint': fingerprint,
    'deviceName': deviceName,
    'deviceType': deviceType,
    'deviceModel': deviceModel,
    'osVersion': osVersion,
    'trustedAt': trustedAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'lastUsedAt': lastUsedAt.toIso8601String(),
    'revokedAt': revokedAt?.toIso8601String(),
    'isActive': isActive,
    'metadata': metadata,
  };
  
  factory TrustedDevice.fromJson(Map<String, dynamic> json) => TrustedDevice(
    id: json['id'],
    userId: json['userId'],
    fingerprint: json['fingerprint'],
    deviceName: json['deviceName'],
    deviceType: json['deviceType'],
    deviceModel: json['deviceModel'],
    osVersion: json['osVersion'],
    trustedAt: DateTime.parse(json['trustedAt']),
    expiresAt: DateTime.parse(json['expiresAt']),
    lastUsedAt: DateTime.parse(json['lastUsedAt']),
    revokedAt: json['revokedAt'] != null ? DateTime.parse(json['revokedAt']) : null,
    isActive: json['isActive'],
    metadata: json['metadata'] ?? {},
  );
}
