import 'dart:async';
import 'dart:math';
import 'mdm_provider_service.dart';
import '../../locator.dart';
import 'dart:developer' as developer;
import '../models/admin_models.dart' hide ComplianceStatus;
import '../models/managed_device.dart';
import '../models/compliance_models.dart' as compliance;

class MobileDeviceManagementService {
  static final MobileDeviceManagementService _instance = MobileDeviceManagementService._internal();
  factory MobileDeviceManagementService() => _instance;
  MobileDeviceManagementService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  final Map<String, ManagedDevice> _devices = {};
  final Map<String, DevicePolicy> _policies = {};
  final List<DeviceCompliance> _complianceRecords = [];
  final List<DeviceAction> _actions = [];
  
  final StreamController<DeviceEvent> _eventController = StreamController<DeviceEvent>.broadcast();
  final StreamController<compliance.ComplianceAlert> _complianceController = StreamController<compliance.ComplianceAlert>.broadcast();
  final StreamController<DeviceAction> _actionController = StreamController<DeviceAction>.broadcast();

  Stream<DeviceEvent> get eventStream => _eventController.stream;
  Stream<compliance.ComplianceAlert> get complianceStream => _complianceController.stream;
  Stream<DeviceAction> get actionStream => _actionController.stream;

  final Random _random = Random();
  Timer? _complianceMonitor;
  Timer? _deviceStatusMonitor;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _setupDefaultPolicies();
      await _discoverDevices();
      await _connectToMdmProvider();
      _startComplianceMonitoring();
      _startDeviceStatusMonitoring();
      
      _isInitialized = true;
      developer.log('Mobile Device Management Service initialized', name: 'MobileDeviceManagementService');
    } catch (e) {
      developer.log('Failed to initialize Mobile Device Management Service: $e', name: 'MobileDeviceManagementService');
      throw Exception('Mobile Device Management Service initialization failed: $e');
    }
  }

  Future<void> _connectToMdmProvider() async {
    try {
      final mdmProvider = locator<MdmProviderService>();
      
      // Subscribe to all MDM events from the provider
      mdmProvider.eventStream.listen((event) {
        switch (event.type) {
          case MdmEventType.deviceEnrolled:
            _handleDeviceEnrollment(event);
            break;
          case MdmEventType.complianceCheck:
            _handlePolicyCompliance(event);
            break;
          case MdmEventType.deviceAction:
            _handleRemoteActionResult(event);
            break;
          default:
            developer.log('Unhandled MDM event type: ${event.type}', name: 'MobileDeviceManagementService');
        }
      });
      
      developer.log('Connected to MDM provider services', name: 'MobileDeviceManagementService');
    } catch (e) {
      developer.log('Failed to connect to MDM provider: $e', name: 'MobileDeviceManagementService');
    }
  }

  void _handleDeviceEnrollment(MdmEvent event) {
    final deviceId = event.deviceId;
    final status = event.data['status'] as String?;
    
    final provider = event.data['provider'] as String?;
    if (status != null && provider != null) {
      developer.log('Device enrollment event: $deviceId -> $status from $provider', name: 'MobileDeviceManagementService');
      
      if (status == 'enrolled') {
        _syncDeviceFromProvider(deviceId, provider);
      } else if (status == 'unenrolled') {
        _devices.remove(deviceId);
      }
    }
  }

  void _handlePolicyCompliance(MdmEvent event) {
    final deviceId = event.deviceId;
    final isCompliant = event.data['compliant'] as bool?;
    final violations = event.data['violations'] as List<dynamic>?;
    
    if (isCompliant != null) {
      developer.log('Policy compliance event: $deviceId -> compliant: $isCompliant', name: 'MobileDeviceManagementService');
      
      final device = _devices[deviceId];
      if (device != null && !isCompliant && violations != null) {
        _complianceController.add(compliance.ComplianceAlert(
          alertId: 'alert_${DateTime.now().millisecondsSinceEpoch}',
          deviceId: deviceId,
          policyId: device.policyId ?? 'unknown',
          violations: violations.whereType<String>().toList(),
          timestamp: DateTime.now(),
          severity: compliance.AlertSeverity.high,
          status: compliance.AlertStatus.open,
        ));
      }
    }
  }

  void _handleRemoteActionResult(MdmEvent event) {
    final actionId = event.data['action_id'] as String?;
    final status = event.data['status'] as String?;
    final result = event.data['result'] as String?;
    
    if (actionId != null && status != null) {
      developer.log('Remote action result: $actionId -> $status', name: 'MobileDeviceManagementService');
      
      final action = _actions.firstWhere((a) => a.id == actionId, orElse: () => DeviceAction(
        id: actionId,
        deviceId: event.deviceId,
        type: DeviceActionType.lock,
        reason: 'Remote action update',
        initiatedAt: DateTime.now(),
        status: _mapActionStatus(status),
        result: result,
      ));

      _actionController.add(action.copyWith(
        status: _mapActionStatus(status),
        result: result,
        completedAt: DateTime.now(),
      ));
    }
  }

  Future<void> _syncDeviceFromProvider(String deviceId, String provider) async {
    try {
      final mdmProvider = locator<MdmProviderService>();
      final result = await mdmProvider.getDeviceDetails(deviceId: deviceId, provider: provider);
      
      if (result.success) {
        final data = result.data!;
        final device = ManagedDevice(
          id: deviceId,
          name: data['name'] ?? 'Unknown Device',
          platform: data['platform'] ?? 'unknown',
          osVersion: data['os_version'] ?? 'Unknown',
          serialNumber: data['serial_number'],
          imei: data['imei'],
          meid: data['meid'],
          lastSeen: DateTime.tryParse(data['last_seen'] ?? '') ?? DateTime.now(),
          isManaged: true,
          isCompliant: _mapComplianceStatus(data['compliance_status'] ?? 'unknown') == ComplianceStatus.compliant,
          policyId: data['policy_id'] ?? 'default_policy',
          additionalData: {
            'batteryLevel': data['battery_level'] ?? 0,
            'storageUsed': (data['storage_used'] as num?)?.toDouble() ?? 0.0,
            'isJailbroken': data['is_jailbroken'] ?? false,
            'isEncrypted': data['is_encrypted'] ?? false,
            'installedApps': (data['installed_apps'] as List<dynamic>?)?.whereType<String>().toList() ?? [],
            'location': data['location'] ?? {},
          },
        );

        _devices[deviceId] = device;
        _eventController.add(DeviceEvent(
          id: 'sync_${DateTime.now().millisecondsSinceEpoch}',
          deviceId: deviceId,
          type: DeviceEventType.enrollment,
          timestamp: DateTime.now(),
          details: 'Device synced from MDM provider',
        ));
      }
    } catch (e) {
      developer.log('Failed to sync device from provider: $e', name: 'MobileDeviceManagementService');
    }
  }



  ComplianceStatus _mapComplianceStatus(String status) {
    switch (status.toLowerCase()) {
      case 'compliant':
        return ComplianceStatus.compliant;
      case 'non_compliant':
        return ComplianceStatus.nonCompliant;
      default:
        return ComplianceStatus.nonCompliant;
    }
  }

  ActionStatus _mapActionStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ActionStatus.pending;
      case 'completed':
        return ActionStatus.completed;
      case 'failed':
        return ActionStatus.failed;
      default:
        return ActionStatus.pending;
    }
  }

  Future<void> _setupDefaultPolicies() async {
    _policies['corporate_standard'] = DevicePolicy(
      id: 'corporate_standard',
      name: 'Corporate Standard Policy',
      description: 'Standard security policy for corporate devices',
      requirements: {
        'passcode_required': true,
        'passcode_min_length': 8,
        'passcode_complex': true,
        'auto_lock_timeout': 300, // 5 minutes
        'encryption_required': true,
        'remote_wipe_enabled': true,
        'app_installation_restricted': true,
        'camera_disabled': false,
        'bluetooth_restricted': true,
        'wifi_restrictions': ['open_networks_blocked'],
        'vpn_required': true,
        'jailbreak_detection': true,
        'backup_restrictions': ['cloud_backup_disabled'],
      },
      complianceLevel: ComplianceLevel.high,
      enforcementMode: EnforcementMode.strict,
    );

    _policies['byod_policy'] = DevicePolicy(
      id: 'byod_policy',
      name: 'Bring Your Own Device Policy',
      description: 'Policy for personal devices accessing corporate resources',
      requirements: {
        'passcode_required': true,
        'passcode_min_length': 6,
        'encryption_required': true,
        'remote_wipe_enabled': true,
        'app_installation_restricted': false,
        'work_profile_required': true,
        'data_separation': true,
        'vpn_required': true,
        'jailbreak_detection': true,
      },
      complianceLevel: ComplianceLevel.medium,
      enforcementMode: EnforcementMode.lenient,
    );

    _policies['executive_policy'] = DevicePolicy(
      id: 'executive_policy',
      name: 'Executive Device Policy',
      description: 'Enhanced security policy for executive devices',
      requirements: {
        'passcode_required': true,
        'passcode_min_length': 12,
        'passcode_complex': true,
        'biometric_required': true,
        'auto_lock_timeout': 120, // 2 minutes
        'encryption_required': true,
        'remote_wipe_enabled': true,
        'app_installation_restricted': true,
        'camera_disabled': true,
        'microphone_disabled': true,
        'bluetooth_restricted': true,
        'wifi_restrictions': ['enterprise_only'],
        'vpn_required': true,
        'jailbreak_detection': true,
        'geofencing_enabled': true,
        'backup_restrictions': ['all_backups_disabled'],
      },
      complianceLevel: ComplianceLevel.critical,
      enforcementMode: EnforcementMode.strict,
    );
  }

  Future<void> _discoverDevices() async {
    // Simulate device discovery
    final users = ['john.doe', 'jane.smith', 'bob.wilson', 'alice.brown', 'charlie.davis'];

    for (int i = 0; i < 25; i++) {
      final platformName = ['iOS', 'Android', 'Windows'][_random.nextInt(3)];
      final device = ManagedDevice(
        id: 'device_${i.toString().padLeft(3, '0')}',
        name: 'Device ${i + 1}',
        platform: platformName,
        osVersion: _generateOSVersion(platformName),
        serialNumber: 'SN${i.toString().padLeft(6, '0')}',
        lastSeen: DateTime.now().subtract(Duration(minutes: _random.nextInt(1440))),
        isManaged: true,
        isCompliant: _random.nextDouble() > 0.2, // 80% compliant
        policyId: _random.nextBool() ? 'corporate_standard' : 'byod_policy',
        additionalData: {
          'deviceType': ['smartphone', 'tablet', 'laptop'][_random.nextInt(3)],
          'userId': users[_random.nextInt(users.length)],
          'enrolledAt': DateTime.now().subtract(Duration(days: _random.nextInt(365))).toIso8601String(),
          'location': _generateRandomLocation(),
          'batteryLevel': _random.nextInt(100),
          'storageUsed': _random.nextDouble() * 100,
          'isJailbroken': _random.nextDouble() < 0.05,
          'isEncrypted': _random.nextDouble() > 0.1,
          'installedApps': _generateInstalledApps(),
        },
      );

      _devices[device.id] = device;
    }
  }

  String _generateOSVersion(String platform) {
    switch (platform.toLowerCase()) {
      case 'ios':
        return '17.${_random.nextInt(6)}.${_random.nextInt(10)}';
      case 'android':
        return '${13 + _random.nextInt(2)}.${_random.nextInt(10)}';
      case 'windows':
        return '11.${_random.nextInt(5)}.${_random.nextInt(1000)}';
      case 'macos':
        return '14.${_random.nextInt(5)}.${_random.nextInt(10)}';
      default:
        return '1.0.0';
    }
  }

  Map<String, double> _generateRandomLocation() {
    return {
      'latitude': 40.7128 + (_random.nextDouble() - 0.5) * 10,
      'longitude': -74.0060 + (_random.nextDouble() - 0.5) * 10,
    };
  }

  List<String> _generateInstalledApps() {
    final apps = [
      'Microsoft Outlook', 'Slack', 'Zoom', 'Teams', 'Chrome',
      'Safari', 'WhatsApp', 'Instagram', 'Facebook', 'Twitter',
      'LinkedIn', 'Dropbox', 'OneDrive', 'Google Drive', 'Spotify',
    ];
    
    final numApps = 5 + _random.nextInt(10);
    apps.shuffle(_random);
    return apps.take(numApps).toList();
  }

  void _startComplianceMonitoring() {
    _complianceMonitor = Timer.periodic(const Duration(hours: 2), (timer) {
      _checkDeviceCompliance();
    });
  }

  void _startDeviceStatusMonitoring() {
    _deviceStatusMonitor = Timer.periodic(const Duration(minutes: 15), (timer) {
      _updateDeviceStatus();
    });
  }

  Future<void> _checkDeviceCompliance() async {
    developer.log('Checking device compliance', name: 'MobileDeviceManagementService');

    for (final device in _devices.values) {
      final policy = _policies[device.policyId];
      if (policy == null) continue;

      final complianceRecord = await _evaluateDeviceCompliance(device, policy);
      _complianceRecords.add(complianceRecord);

      if (complianceRecord.status != ComplianceStatus.compliant) {
        final alert = compliance.ComplianceAlert(
          alertId: 'alert_${DateTime.now().millisecondsSinceEpoch}',
          deviceId: device.id,
          policyId: policy.id,
          violations: complianceRecord.violations,
          timestamp: DateTime.now(),
          severity: _calculateAlertSeverity(complianceRecord.violations),
          status: complianceRecord.status == ComplianceStatus.compliant ? compliance.AlertStatus.resolved : compliance.AlertStatus.open,
        );

        _complianceController.add(alert);

        if (policy.enforcementMode == EnforcementMode.strict) {
          await _enforceCompliance(device, complianceRecord);
        }
      }

      // Update device compliance status
      _devices[device.id] = device.copyWith(isCompliant: complianceRecord.status == ComplianceStatus.compliant);
    }
  }

  Future<DeviceCompliance> _evaluateDeviceCompliance(ManagedDevice device, DevicePolicy policy) async {
    final violations = <String>[];

    // Check passcode requirements
    if ((policy.requirements['passcode_required'] as bool?) == true) {
      if (_random.nextDouble() < 0.1) { // 10% non-compliance
        violations.add('Passcode not configured');
      }
    }

    // Check encryption
    if ((policy.requirements['encryption_required'] as bool?) == true && 
        !(device.additionalData?['isEncrypted'] as bool? ?? false)) {
      violations.add('Device encryption not enabled');
    }

    // Check jailbreak/root detection
    if ((policy.requirements['jailbreak_detection'] as bool?) == true && 
        (device.additionalData?['isJailbroken'] as bool? ?? false)) {
      violations.add('Device is jailbroken/rooted');
    }

    // Check OS version
    if (_isOSVersionOutdated(device.osVersion, device.platform)) {
      violations.add('Operating system version is outdated');
    }

    // Check app restrictions
    if ((policy.requirements['app_installation_restricted'] as bool?) == true) {
      final installedApps = (device.additionalData?['installedApps'] as List<dynamic>?)?.cast<String>() ?? [];
      final unauthorizedApps = _checkUnauthorizedApps(installedApps);
      if (unauthorizedApps.isNotEmpty) {
        violations.add('Unauthorized applications installed: ${unauthorizedApps.join(', ')}');
      }
    }

    final status = violations.isEmpty ? ComplianceStatus.compliant : 
                   violations.length <= 2 ? ComplianceStatus.nonCompliant : 
                   ComplianceStatus.nonCompliant;

    return DeviceCompliance(
      id: 'compliance_${DateTime.now().millisecondsSinceEpoch}',
      deviceId: device.id,
      policyId: policy.id,
      status: status,
      violations: violations,
      checkedAt: DateTime.now(),
      score: _calculateComplianceScore(violations.length),
    );
  }

  bool _isOSVersionOutdated(String version, String platform) {
    // Simplified version check
    return _random.nextDouble() < 0.15; // 15% chance of outdated OS
  }

  List<String> _checkUnauthorizedApps(List<String> installedApps) {
    final unauthorizedApps = ['TikTok', 'WeChat', 'Telegram'];
    return installedApps.where((app) => unauthorizedApps.contains(app)).toList();
  }

  double _calculateComplianceScore(int violationCount) {
    if (violationCount == 0) return 100.0;
    if (violationCount <= 2) return 75.0;
    if (violationCount <= 4) return 50.0;
    return 25.0;
  }

  compliance.AlertSeverity _calculateAlertSeverity(List<String> violations) {
    if (violations.any((v) => v.contains('jailbroken') || v.contains('encryption'))) {
      return compliance.AlertSeverity.critical;
    }
    if (violations.length > 2) return compliance.AlertSeverity.high;
    if (violations.length > 1) return compliance.AlertSeverity.medium;
    return compliance.AlertSeverity.low;
  }

  Future<void> _enforceCompliance(ManagedDevice device, DeviceCompliance compliance) async {
    for (final violation in compliance.violations) {
      if (violation.contains('jailbroken')) {
        await _executeDeviceAction(device.id, DeviceActionType.lock, 
            'Device locked due to jailbreak detection');
      } else if (violation.contains('encryption')) {
        await _executeDeviceAction(device.id, DeviceActionType.lock, 
            'Device locked - encryption required');
      } else if (violation.contains('Unauthorized applications')) {
        await _executeDeviceAction(device.id, DeviceActionType.wipe, 
            'Device wiped - unauthorized applications');
      }
    }
  }

  Future<void> _updateDeviceStatus() async {
    for (final deviceId in _devices.keys) {
      final device = _devices[deviceId];
      if (device == null) continue;
      
      // Simulate device status changes
      if (_random.nextDouble() < 0.02) { // 2% chance of status change
        final newStatus = DeviceStatus.values[_random.nextInt(DeviceStatus.values.length)];
        final updatedAdditionalData = Map<String, dynamic>.from(device.additionalData ?? {});
        updatedAdditionalData['batteryLevel'] = _random.nextInt(100);
        _devices[deviceId] = device.copyWith(
          lastSeen: DateTime.now(),
          additionalData: updatedAdditionalData,
        );

        final event = DeviceEvent(
          id: 'event_${DateTime.now().millisecondsSinceEpoch}',
          deviceId: deviceId,
          type: DeviceEventType.statusChange,
          timestamp: DateTime.now(),
          details: 'Device status changed to ${newStatus.name}',
        );

        _eventController.add(event);
      }
    }
  }

  // Public API Methods
  Future<String> enrollDevice({
    required String deviceName,
    required DeviceType deviceType,
    required DevicePlatform platform,
    required String osVersion,
    required String userId,
    String? policyId,
  }) async {
    final deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
    
    final device = ManagedDevice(
      id: deviceId,
      name: deviceName,
      platform: platform.toString(),
      osVersion: osVersion,
      lastSeen: DateTime.now(),
      isManaged: true,
      isCompliant: false,
      policyId: policyId ?? 'byod_policy',
      additionalData: {
        'deviceType': deviceType.toString(),
        'userId': userId,
        'enrolledAt': DateTime.now().toIso8601String(),
        'batteryLevel': 100,
        'storageUsed': 0.0,
        'isJailbroken': false,
        'isEncrypted': false,
        'installedApps': <String>[],
      },
    );

    _devices[deviceId] = device;

    await Future.delayed(const Duration(seconds: 2)); // Simulate enrollment process

    _devices[deviceId] = device.copyWith(isManaged: true, isCompliant: true);

    final event = DeviceEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      deviceId: deviceId,
      type: DeviceEventType.enrollment,
      timestamp: DateTime.now(),
      details: 'Device enrolled successfully',
    );

    _eventController.add(event);

    return deviceId;
  }

  Future<void> unenrollDevice(String deviceId) async {
    final device = _devices[deviceId];
    if (device == null) {
      throw Exception('Device not found: $deviceId');
    }

    await _executeDeviceAction(deviceId, DeviceActionType.wipe, 'Device unenrollment');

    _devices.remove(deviceId);

    final event = DeviceEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      deviceId: deviceId,
      type: DeviceEventType.unenrollment,
      timestamp: DateTime.now(),
      details: 'Device unenrolled and wiped',
    );

    _eventController.add(event);
  }

  Future<void> _executeDeviceAction(String deviceId, DeviceActionType actionType, String reason) async {
    final action = DeviceAction(
      id: 'action_${DateTime.now().millisecondsSinceEpoch}',
      deviceId: deviceId,
      type: actionType,
      reason: reason,
      initiatedAt: DateTime.now(),
      status: ActionStatus.pending,
    );

    _actions.add(action);
    _actionController.add(action);

    // Simulate action execution
    await Future.delayed(const Duration(seconds: 1));

    final updatedAction = action.copyWith(
      status: ActionStatus.completed,
      completedAt: DateTime.now(),
      result: 'Action completed successfully',
    );

    final index = _actions.indexWhere((a) => a.id == action.id);
    if (index != -1) {
      _actions[index] = updatedAction;
    }

    _actionController.add(updatedAction);
  }

  Future<void> applyPolicyToDevice(String deviceId, String policyId) async {
    final device = _devices[deviceId];
    final policy = _policies[policyId];

    if (device == null) throw Exception('Device not found: $deviceId');
    if (policy == null) throw Exception('Policy not found: $policyId');

    _devices[deviceId] = device.copyWith(policyId: policyId);

    await _executeDeviceAction(deviceId, DeviceActionType.restart, 
        'Applied policy: ${policy.name}');
  }

  Future<void> remoteWipeDevice(String deviceId, {bool selective = false}) async {
    final actionType = DeviceActionType.wipe;
    await _executeDeviceAction(deviceId, actionType, 'Remote wipe initiated');
  }

  Future<void> lockDevice(String deviceId) async {
    await _executeDeviceAction(deviceId, DeviceActionType.lock, 'Device locked remotely');
  }

  Future<void> locateDevice(String deviceId) async {
    await _executeDeviceAction(deviceId, DeviceActionType.restart, 'Device location requested');
  }

  List<ManagedDevice> getDevices({DeviceStatus? status, ComplianceStatus? complianceStatus}) {
    var devices = _devices.values.toList();
    
    // Note: ManagedDevice doesn't have status or complianceStatus properties
    // Filtering would need to be based on additionalData or isCompliant
    if (complianceStatus != null) {
      final isCompliantFilter = complianceStatus == ComplianceStatus.compliant;
      devices = devices.where((d) => d.isCompliant == isCompliantFilter).toList();
    }
    
    return devices;
  }

  List<DevicePolicy> getPolicies() => _policies.values.toList();

  List<compliance.ComplianceAlert> getRecentAlerts({int limit = 50}) {
    final sorted = _complianceRecords
        .where((r) => r.status != ComplianceStatus.compliant)
        .map((r) => compliance.ComplianceAlert(
              alertId: 'alert_${r.id}',
              deviceId: r.deviceId,
              policyId: r.policyId,
              violations: r.violations,
              timestamp: r.checkedAt,
              severity: _calculateAlertSeverity(r.violations),
              status: r.status == ComplianceStatus.compliant ? compliance.AlertStatus.resolved : compliance.AlertStatus.open,
            ))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return sorted.take(limit).toList();
  }

  Map<String, dynamic> getMDMMetrics() {
    final totalDevices = _devices.length;
    final activeDevices = _devices.values.where((d) => d.isManaged).length;
    final compliantDevices = _devices.values.where((d) => d.isCompliant).length;
    final criticalDevices = _devices.values.where((d) => !d.isCompliant).length;

    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    final recentActions = _actions.where((a) => a.initiatedAt.isAfter(last24Hours)).length;

    return {
      'total_devices': totalDevices,
      'active_devices': activeDevices,
      'compliant_devices': compliantDevices,
      'non_compliant_devices': totalDevices - compliantDevices,
      'critical_devices': criticalDevices,
      'compliance_rate': totalDevices > 0 ? (compliantDevices / totalDevices * 100).toStringAsFixed(1) : '0.0',
      'actions_24h': recentActions,
      'total_policies': _policies.length,
      'platform_breakdown': _getPlatformBreakdown(),
      'device_type_breakdown': _getDeviceTypeBreakdown(),
    };
  }

  Map<String, int> _getPlatformBreakdown() {
    final breakdown = <String, int>{};
    for (final device in _devices.values) {
      breakdown[device.platform] = (breakdown[device.platform] ?? 0) + 1;
    }
    return breakdown;
  }

  Map<String, int> _getDeviceTypeBreakdown() {
    final breakdown = <String, int>{};
    for (final device in _devices.values) {
      final deviceType = device.additionalData?['deviceType'] as String? ?? 'unknown';
      breakdown[deviceType] = (breakdown[deviceType] ?? 0) + 1;
    }
    return breakdown;
  }

  void dispose() {
    _complianceMonitor?.cancel();
    _deviceStatusMonitor?.cancel();
    _eventController.close();
    _complianceController.close();
    _actionController.close();
  }
}

// Enums
enum DeviceType { smartphone, tablet, laptop, desktop, wearable }
enum DevicePlatform { ios, android, windows, macos, linux, other }
enum DeviceStatus { active, inactive, suspended, quarantined }
enum ComplianceStatus { compliant, nonCompliant, critical, unknown }
enum ComplianceLevel { low, medium, high, critical }
enum EnforcementMode { lenient, moderate, strict }
enum DeviceEventType { enrollment, unenrollment, statusChange, policyChange, compliance }
enum DeviceActionType { lock, unlock, wipe, restart, shutdown }
enum ActionStatus { pending, inProgress, completed, failed, cancelled }

// Data Classes
class DevicePolicy {
  final String id;
  final String name;
  final String description;
  final Map<String, dynamic> requirements;
  final ComplianceLevel complianceLevel;
  final EnforcementMode enforcementMode;

  DevicePolicy({
    required this.id,
    required this.name,
    required this.description,
    required this.requirements,
    required this.complianceLevel,
    required this.enforcementMode,
  });
}

class DeviceCompliance {
  final String id;
  final String deviceId;
  final String policyId;
  final ComplianceStatus status;
  final List<String> violations;
  final DateTime checkedAt;
  final double score;

  DeviceCompliance({
    required this.id,
    required this.deviceId,
    required this.policyId,
    required this.status,
    required this.violations,
    required this.checkedAt,
    required this.score,
  });
}

class DeviceEvent {
  final String id;
  final String deviceId;
  final DeviceEventType type;
  final DateTime timestamp;
  final String details;

  DeviceEvent({
    required this.id,
    required this.deviceId,
    required this.type,
    required this.timestamp,
    required this.details,
  });
}

class DeviceAction {
  final String id;
  final String deviceId;
  final DeviceActionType type;
  final String reason;
  final DateTime initiatedAt;
  final ActionStatus status;
  final DateTime? completedAt;
  final String? result;

  DeviceAction({
    required this.id,
    required this.deviceId,
    required this.type,
    required this.reason,
    required this.initiatedAt,
    required this.status,
    this.completedAt,
    this.result,
  });

  DeviceAction copyWith({
    String? id,
    String? deviceId,
    DeviceActionType? type,
    String? reason,
    DateTime? initiatedAt,
    ActionStatus? status,
    DateTime? completedAt,
    String? result,
  }) {
    return DeviceAction(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      initiatedAt: initiatedAt ?? this.initiatedAt,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      result: result ?? this.result,
    );
  }
}

