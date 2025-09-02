import 'dart:async';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/admin_models.dart';
import '../models/managed_device.dart';

class MdmProviderService extends ChangeNotifier {
  static MdmProviderService? _instance;
  static MdmProviderService get instance => _instance ??= MdmProviderService._();
  MdmProviderService._();

  final Dio _dio = Dio();
  final Uuid _uuid = const Uuid();
  bool _isInitialized = false;
  bool _useRealConnections = false;

  // MDM Provider configurations loaded from environment
  final Map<String, String> _providerConfigs = {};
  final Map<String, String> _apiKeys = {};
  final Map<String, String> _tenantCodes = {};
  final Map<String, String> _clientIds = {};
  final Map<String, String> _clientSecrets = {};

  final StreamController<MdmEvent> _eventController = StreamController<MdmEvent>.broadcast();
  Stream<MdmEvent> get eventStream => _eventController.stream;
  
  // Device enrollment stream
  final StreamController<ManagedDevice> _deviceEnrollmentController = StreamController<ManagedDevice>.broadcast();
  Stream<ManagedDevice> get deviceEnrollmentStream => _deviceEnrollmentController.stream;
  
  // Device compliance stream
  final StreamController<Map<String, dynamic>> _complianceStatusController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get complianceStatusStream => _complianceStatusController.stream;
  
  // Device action stream
  final StreamController<Map<String, dynamic>> _deviceActionController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get deviceActionStream => _deviceActionController.stream;

  Timer? _syncTimer;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load configuration from environment variables
      _loadEnvironmentConfig();
      
      _dio.options.connectTimeout = const Duration(minutes: 2);
      _dio.options.receiveTimeout = const Duration(minutes: 5);

      _useRealConnections = _hasValidCredentials();
      
      if (_useRealConnections) {
        // Start periodic device sync only if we have real connections
        _syncTimer = Timer.periodic(const Duration(minutes: 10), (_) => _syncAllDevices());
        developer.log('MDM provider service initialized with real connections');
      } else {
        developer.log('MDM provider service initialized in mock mode - no credentials configured');
        _startMockDataGeneration();
      }

      // Initialize streams
      _initStreams();
      
      _isInitialized = true;
    } catch (e) {
      developer.log('Failed to initialize MDM provider service: $e');
      _isInitialized = true;
      _startMockDataGeneration();
      _initStreams();
    }
  }
  
  void _loadEnvironmentConfig() {
    // Microsoft Intune
    _providerConfigs['microsoft_intune'] = dotenv.env['INTUNE_GRAPH_URL'] ?? 'https://graph.microsoft.com/v1.0/';
    _apiKeys['microsoft_intune'] = dotenv.env['INTUNE_ACCESS_TOKEN'] ?? '';
    _clientIds['microsoft_intune'] = dotenv.env['INTUNE_CLIENT_ID'] ?? '';
    _clientSecrets['microsoft_intune'] = dotenv.env['INTUNE_CLIENT_SECRET'] ?? '';
    
    // VMware Workspace ONE
    _providerConfigs['vmware_workspace_one'] = dotenv.env['WORKSPACE_ONE_URL'] ?? '';
    _apiKeys['vmware_workspace_one'] = dotenv.env['WORKSPACE_ONE_API_KEY'] ?? '';
    _tenantCodes['vmware_workspace_one'] = dotenv.env['WORKSPACE_ONE_TENANT_CODE'] ?? '';
    
    // JAMF
    _providerConfigs['jamf'] = dotenv.env['JAMF_URL'] ?? '';
    _apiKeys['jamf'] = dotenv.env['JAMF_API_TOKEN'] ?? '';
    
    // MobileIron
    _providerConfigs['mobileiron'] = dotenv.env['MOBILEIRON_URL'] ?? '';
    _apiKeys['mobileiron'] = dotenv.env['MOBILEIRON_API_KEY'] ?? '';
    
    // Citrix Endpoint Management
    _providerConfigs['citrix_endpoint'] = dotenv.env['CITRIX_ENDPOINT_URL'] ?? '';
    _apiKeys['citrix_endpoint'] = dotenv.env['CITRIX_ENDPOINT_API_KEY'] ?? '';
    
    // BlackBerry UEM
    _providerConfigs['blackberry_uem'] = dotenv.env['BLACKBERRY_UEM_URL'] ?? '';
    _apiKeys['blackberry_uem'] = dotenv.env['BLACKBERRY_UEM_API_KEY'] ?? '';
  }
  
  bool _hasValidCredentials() {
    return _providerConfigs.values.any((url) => url.isNotEmpty) &&
           _apiKeys.values.any((key) => key.isNotEmpty);
  }
  
  void _startMockDataGeneration() {
    // Generate mock MDM events for development/testing
    Timer.periodic(const Duration(minutes: 3), (timer) {
      if (!_isInitialized) {
        timer.cancel();
        return;
      }
      
      _generateMockMdmEvent();
    });
  }
  
  void _generateMockMdmEvent() {
    final providers = ['Microsoft Intune', 'VMware Workspace ONE', 'JAMF', 'MobileIron'];
    final eventTypes = [MdmEventType.deviceEnrolled, MdmEventType.policyApplied, MdmEventType.complianceCheck];
    
    final randomProvider = providers[DateTime.now().millisecondsSinceEpoch % providers.length];
    final randomEventType = eventTypes[DateTime.now().millisecondsSinceEpoch % eventTypes.length];
    final deviceId = 'device_${(DateTime.now().millisecondsSinceEpoch % 1000) + 1}';
    
    _eventController.add(MdmEvent(
      id: _uuid.v4(),
      type: randomEventType,
      provider: randomProvider,
      title: 'Mock MDM Event',
      description: 'Generated for development testing',
      deviceId: deviceId,
      data: {
        'deviceId': deviceId,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'success',
        'isMock': true,
      },
      timestamp: DateTime.now(),
    ));
  }
  
  void _initStreams() {
    // Forward device enrollment events
    _eventController.stream.where((event) => event.type == MdmEventType.deviceEnrolled).listen((event) {
      try {
        if (event.data is Map<String, dynamic>) {
          _deviceEnrollmentController.add(ManagedDevice.fromJson(event.data));
        }
      } catch (e) {
        developer.log('Error processing device enrollment: $e', error: e);
      }
    });

    // Forward compliance status changes
    _eventController.stream.where((event) => 
      event.type == MdmEventType.complianceCheck ||
      event.type == MdmEventType.complianceViolation ||
      event.type == MdmEventType.complianceStatusChanged ||
      event.type == MdmEventType.policyApplied ||
      event.type == MdmEventType.policyUpdated ||
      event.type == MdmEventType.policyRemoved
    ).listen((event) {
      if (event.data.isNotEmpty) {
        _complianceStatusController.add({
          'eventType': event.type.toString().split('.').last,
          'timestamp': DateTime.now().toIso8601String(),
          ...event.data,
        });
      }
    });
    
    // Listen for device actions and security events
    _eventController.stream.where((event) => 
      event.type == MdmEventType.deviceAction ||
      event.type == MdmEventType.deviceWipe ||
      event.type == MdmEventType.deviceLock ||
      event.type == MdmEventType.deviceUnlock ||
      event.type == MdmEventType.deviceRestart ||
      event.type == MdmEventType.deviceShutdown ||
      event.type == MdmEventType.appInstalled ||
      event.type == MdmEventType.appUpdated ||
      event.type == MdmEventType.appRemoved ||
      event.type == MdmEventType.securityThreatDetected ||
      event.type == MdmEventType.securityThreatResolved ||
      event.type == MdmEventType.errorOccurred
    ).listen((event) {
      if (event.data.isNotEmpty) {
        _deviceActionController.add({
          'eventType': event.type.toString().split('.').last,
          'timestamp': DateTime.now().toIso8601String(),
          ...event.data,
        });
      }
    });
  }

  // Microsoft Intune Integration
  Future<MdmResult<ManagedDevice>> enrollIntuneDevice({
    required String deviceId,
    required String userId,
    required String deviceType,
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      final response = await _dio.post(
        '${_providerConfigs['microsoft_intune']}deviceManagement/managedDevices',
        data: {
          'deviceName': deviceInfo?['deviceName'] ?? 'Unknown Device',
          'deviceType': deviceType,
          'operatingSystem': deviceInfo?['operatingSystem'] ?? 'Unknown',
          'osVersion': deviceInfo?['osVersion'] ?? '0.0',
          'userId': userId,
          'enrollmentType': 'userEnrollment',
          'complianceState': 'unknown',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${_apiKeys['microsoft_intune']}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201) {
        final device = ManagedDevice.fromJson(response.data);
        _eventController.add(MdmEvent(
          id: _uuid.v4(),
          type: MdmEventType.deviceEnrolled,
          provider: 'Microsoft Intune',
          title: 'Device Enrolled',
          description: 'Device $deviceId enrolled in Microsoft Intune.',
          deviceId: deviceId,
          data: device.toJson(),
          timestamp: DateTime.now(),
        ));

        return MdmResult<ManagedDevice>(
          success: true,
          data: device,
          provider: 'Microsoft Intune',
        );
      } else {
        return MdmResult<ManagedDevice>(
          success: false,
          error: 'Intune device enrollment failed: ${response.statusCode}',
          provider: 'Microsoft Intune',
        );
      }
    } catch (e) {
      developer.log('Intune device enrollment error: $e');
      return MdmResult<ManagedDevice>(
        success: false,
        error: e.toString(),
        provider: 'Microsoft Intune',
      );
    }
  }

  Future<List<ManagedDevice>> getIntuneDevices() async {
    try {
      final response = await _dio.get(
        '${_providerConfigs['microsoft_intune']}deviceManagement/managedDevices',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${_apiKeys['microsoft_intune']}',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> devices = response.data['value'];
        return devices.map((data) => ManagedDevice.fromJson(data)).toList();
      }
      return [];
    } catch (e) {
      developer.log('Intune devices retrieval error: $e');
      return [];
    }
  }

  Future<MdmResult<Map<String, String>>> applyIntunePolicy({
    required String deviceId,
    required String policyId,
    Map<String, dynamic>? policySettings,
  }) async {
    try {
      final response = await _dio.post(
        '${_providerConfigs['microsoft_intune']}deviceManagement/managedDevices/$deviceId/deviceConfigurationStates',
        data: {
          'settingStates': policySettings?.entries.map((entry) => {
            'setting': entry.key,
            'state': entry.value,
          }).toList() ?? [],
          'policyId': policyId,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${_apiKeys['microsoft_intune']}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        _eventController.add(MdmEvent(
          id: _uuid.v4(),
          type: MdmEventType.policyApplied,
          provider: 'Microsoft Intune',
          title: 'Policy Applied',
          description: 'Policy $policyId applied to device $deviceId.',
          deviceId: deviceId,
          data: {'policyId': policyId},
          timestamp: DateTime.now(),
        ));

        return MdmResult<Map<String, String>>(
          success: true,
          data: {'policyId': policyId, 'deviceId': deviceId},
          provider: 'Microsoft Intune',
        );
      } else {
        return MdmResult<Map<String, String>>(
          success: false,
          error: 'Intune policy application failed: ${response.statusCode}',
          provider: 'Microsoft Intune',
        );
      }
    } catch (e) {
      developer.log('Intune policy application error: $e');
      return MdmResult<Map<String, String>>(
        success: false,
        error: e.toString(),
        provider: 'Microsoft Intune',
      );
    }
  }

  // VMware Workspace ONE Integration
  Future<MdmResult<Map<String, dynamic>>> enrollWorkspaceOneDevice({
    required String deviceId,
    required String organizationGroupId,
    required Map<String, dynamic> deviceInfo,
  }) async {
    try {
      final response = await _dio.post(
        '${_providerConfigs['vmware_workspace_one']}devices/enrollment',
        data: {
          'DeviceId': deviceId,
          'OrganizationGroupId': organizationGroupId,
          'DeviceModel': deviceInfo['model'],
          'Platform': deviceInfo['platform'],
          'OperatingSystem': deviceInfo['operatingSystem'],
          'Ownership': 'Corporate',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${_apiKeys['vmware_workspace_one']}',
            'Content-Type': 'application/json',
            'aw-tenant-code': 'your-tenant-code',
          },
        ),
      );

      if (response.statusCode == 200) {
        final enrollmentId = response.data['Id']['Value'];
        _eventController.add(MdmEvent(
          id: _uuid.v4(),
          type: MdmEventType.deviceEnrolled,
          provider: 'VMware Workspace ONE',
          title: 'Device Enrolled',
          description: 'Device $deviceId enrolled in VMware Workspace ONE.',
          deviceId: deviceId,
          data: {'enrollmentId': enrollmentId},
          timestamp: DateTime.now(),
        ));

        return MdmResult<Map<String, dynamic>>(
          success: true,
          data: {'enrollmentId': enrollmentId},
          provider: 'VMware Workspace ONE',
        );
      } else {
        return MdmResult<Map<String, dynamic>>(
          success: false,
          error: 'Workspace ONE enrollment failed: ${response.statusCode}',
          provider: 'VMware Workspace ONE',
        );
      }
    } catch (e) {
      developer.log('Workspace ONE enrollment error: $e');
      return MdmResult<Map<String, dynamic>>(
        success: false,
        error: e.toString(),
        provider: 'VMware Workspace ONE',
      );
    }
  }

  // JAMF Integration
  Future<MdmResult<Map<String, String>>> enrollJamfDevice({
    required String serialNumber,
    required String deviceName,
    required Map<String, dynamic> deviceInfo,
  }) async {
    try {
      final response = await _dio.post(
        '${_providerConfigs['jamf']}mobiledeviceenrollmentprofiles/id/0',
        data: {
          'mobile_device_enrollment_profile': {
            'general': {
              'name': deviceName,
              'invitation': 'Corporate Device Enrollment',
            },
            'location': {
              'username': deviceInfo['username'] ?? '',
              'realname': deviceInfo['realname'] ?? '',
              'email_address': deviceInfo['email'] ?? '',
            },
          }
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${_apiKeys['jamf']}',
            'Content-Type': 'application/xml',
          },
        ),
      );

      if (response.statusCode == 201) {
        _eventController.add(MdmEvent(
          id: _uuid.v4(),
          type: MdmEventType.deviceEnrolled,
          provider: 'JAMF',
          title: 'Device Enrolled',
          description: 'Device $serialNumber enrolled in JAMF.',
          deviceId: serialNumber,
          data: {'deviceName': deviceName},
          timestamp: DateTime.now(),
        ));

        return MdmResult<Map<String, String>>(
          success: true,
          data: {'serialNumber': serialNumber},
          provider: 'JAMF',
        );
      } else {
        return MdmResult<Map<String, String>>(
          success: false,
          error: 'JAMF enrollment failed: ${response.statusCode}',
          provider: 'JAMF',
        );
      }
    } catch (e) {
      developer.log('JAMF enrollment error: $e');
      return MdmResult<Map<String, String>>(
        success: false,
        error: e.toString(),
        provider: 'JAMF',
      );
    }
  }

  // MobileIron Integration
  Future<MdmResult<Map<String, String>>> enrollMobileIronDevice({
    required String deviceId,
    required String userId,
    required Map<String, dynamic> deviceInfo,
  }) async {
    try {
      final response = await _dio.post(
        '${_providerConfigs['mobileiron']}device',
        data: {
          'common': {
            'deviceId': deviceId,
            'userId': userId,
            'platformType': deviceInfo['platform'],
            'model': deviceInfo['model'],
            'osVersion': deviceInfo['osVersion'],
          }
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${_apiKeys['mobileiron']}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        _eventController.add(MdmEvent(
          id: _uuid.v4(),
          type: MdmEventType.deviceEnrolled,
          provider: 'MobileIron',
          title: 'Device Enrolled',
          description: 'Device $deviceId enrolled in MobileIron.',
          deviceId: deviceId,
          data: deviceInfo,
          timestamp: DateTime.now(),
        ));

        return MdmResult<Map<String, String>>(
          success: true,
          data: {'deviceId': deviceId},
          provider: 'MobileIron',
        );
      } else {
        return MdmResult<Map<String, String>>(
          success: false,
          error: 'MobileIron enrollment failed: ${response.statusCode}',
          provider: 'MobileIron',
        );
      }
    } catch (e) {
      developer.log('MobileIron enrollment error: $e');
      return MdmResult<Map<String, String>>(
        success: false,
        error: e.toString(),
        provider: 'MobileIron',
      );
    }
  }

  // Device management actions
  Future<MdmResult<Map<String, String>>> lockDevice({
    required String deviceId,
    required String provider,
    String? message,
  }) async {
    try {
      switch (provider.toLowerCase()) {
        case 'microsoft_intune':
          return await _lockIntuneDevice(deviceId, message);
        case 'vmware_workspace_one':
          return await _lockWorkspaceOneDevice(deviceId, message);
        case 'jamf':
          return await _lockJamfDevice(deviceId, message);
        case 'mobileiron':
          return await _lockMobileIronDevice(deviceId, message);
        default:
          return MdmResult<Map<String, String>>(
            success: false,
            error: 'Unsupported provider: $provider',
            provider: provider,
          );
      }
    } catch (e) {
      developer.log('Device lock error: $e');
      return MdmResult<Map<String, String>>(
        success: false,
        error: e.toString(),
        provider: provider,
      );
    }
  }

  Future<MdmResult<Map<String, String>>> wipeDevice({
    required String deviceId,
    required String provider,
    bool preserveEnrollment = false,
  }) async {
    try {
      switch (provider.toLowerCase()) {
        case 'microsoft_intune':
          return await _wipeIntuneDevice(deviceId, preserveEnrollment);
        case 'vmware_workspace_one':
          return await _wipeWorkspaceOneDevice(deviceId, preserveEnrollment);
        case 'jamf':
          return await _wipeJamfDevice(deviceId, preserveEnrollment);
        case 'mobileiron':
          return await _wipeMobileIronDevice(deviceId, preserveEnrollment);
        default:
          return MdmResult<Map<String, String>>(
            success: false,
            error: 'Unsupported provider: $provider',
            provider: provider,
          );
      }
    } catch (e) {
      developer.log('Device wipe error: $e');
      return MdmResult<Map<String, String>>(
        success: false,
        error: e.toString(),
        provider: provider,
      );
    }
  }

  // Provider-specific lock implementations
  Future<MdmResult<Map<String, String>>> _lockIntuneDevice(String deviceId, String? message) async {
    final response = await _dio.post(
      '${_providerConfigs['microsoft_intune']}deviceManagement/managedDevices/$deviceId/remoteLock',
      options: Options(
        headers: {
          'Authorization': 'Bearer ${_apiKeys['microsoft_intune']}',
        },
      ),
    );

    if (response.statusCode == 200) {
      _eventController.add(MdmEvent(
        id: _uuid.v4(),
        type: MdmEventType.deviceLock,
        provider: 'Microsoft Intune',
        title: 'Device Locked',
        description: 'Device $deviceId locked via Microsoft Intune.',
        deviceId: deviceId,
        data: {'message': message ?? 'Device locked by security policy'},
        timestamp: DateTime.now(),
      ));

      return MdmResult<Map<String, String>>(
        success: true,
        data: {'action': 'lock', 'deviceId': deviceId},
        provider: 'Microsoft Intune',
      );
    } else {
      return MdmResult<Map<String, String>>(
        success: false,
        error: 'Intune device lock failed: ${response.statusCode}',
        provider: 'Microsoft Intune',
      );
    }
  }

  Future<MdmResult<Map<String, String>>> _lockWorkspaceOneDevice(String deviceId, String? message) async {
    final response = await _dio.post(
      '${_providerConfigs['vmware_workspace_one']}devices/$deviceId/commands',
      data: {
        'CommandXml': '<dict><key>RequestType</key><string>DeviceLock</string></dict>',
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer ${_apiKeys['vmware_workspace_one']}',
          'Content-Type': 'application/json',
          'aw-tenant-code': 'your-tenant-code',
        },
      ),
    );

    return MdmResult<Map<String, String>>(
      success: response.statusCode == 200,
      data: {'action': 'lock', 'deviceId': deviceId},
      provider: 'VMware Workspace ONE',
    );
  }

  Future<MdmResult<Map<String, String>>> _lockJamfDevice(String deviceId, String? message) async {
    final response = await _dio.post(
      '${_providerConfigs['jamf']}mobiledevicecommands/command/DeviceLock/id/$deviceId',
      options: Options(
        headers: {
          'Authorization': 'Bearer ${_apiKeys['jamf']}',
        },
      ),
    );

    return MdmResult<Map<String, String>>(
      success: response.statusCode == 201,
      data: {'action': 'lock', 'deviceId': deviceId},
      provider: 'JAMF',
    );
  }

  Future<MdmResult<Map<String, String>>> _lockMobileIronDevice(String deviceId, String? message) async {
    final response = await _dio.post(
      '${_providerConfigs['mobileiron']}device/$deviceId/actions/lock',
      data: {
        'message': message ?? 'Device locked by security policy',
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer ${_apiKeys['mobileiron']}',
          'Content-Type': 'application/json',
        },
      ),
    );

    return MdmResult<Map<String, String>>(
      success: response.statusCode == 200,
      data: {'action': 'lock', 'deviceId': deviceId},
      provider: 'MobileIron',
    );
  }

  // Provider-specific wipe implementations
  Future<MdmResult<Map<String, String>>> _wipeIntuneDevice(String deviceId, bool preserveEnrollment) async {
    final response = await _dio.post(
      '${_providerConfigs['microsoft_intune']}deviceManagement/managedDevices/$deviceId/wipe',
      data: {
        'keepEnrollmentData': preserveEnrollment,
        'keepUserData': false,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer ${_apiKeys['microsoft_intune']}',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      _eventController.add(MdmEvent(
        id: _uuid.v4(),
        type: MdmEventType.deviceWipe,
        provider: 'Microsoft Intune',
        title: 'Device Wiped',
        description: 'Device $deviceId wiped via Microsoft Intune.',
        deviceId: deviceId,
        data: {'preserveEnrollment': preserveEnrollment},
        timestamp: DateTime.now(),
      ));

      return MdmResult<Map<String, String>>(
        success: true,
        data: {'action': 'wipe', 'deviceId': deviceId},
        provider: 'Microsoft Intune',
      );
    } else {
      return MdmResult<Map<String, String>>(
        success: false,
        error: 'Intune device wipe failed: ${response.statusCode}',
        provider: 'Microsoft Intune',
      );
    }
  }

  Future<MdmResult<Map<String, String>>> _wipeWorkspaceOneDevice(String deviceId, bool preserveEnrollment) async {
    final response = await _dio.post(
      '${_providerConfigs['vmware_workspace_one']}devices/$deviceId/commands',
      data: {
        'CommandXml': '<dict><key>RequestType</key><string>EraseDevice</string></dict>',
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer ${_apiKeys['vmware_workspace_one']}',
          'Content-Type': 'application/json',
          'aw-tenant-code': 'your-tenant-code',
        },
      ),
    );

    return MdmResult<Map<String, String>>(
      success: response.statusCode == 200,
      data: {'action': 'wipe', 'deviceId': deviceId},
      provider: 'VMware Workspace ONE',
    );
  }

  Future<MdmResult<Map<String, String>>> _wipeJamfDevice(String deviceId, bool preserveEnrollment) async {
    final response = await _dio.post(
      '${_providerConfigs['jamf']}mobiledevicecommands/command/EraseDevice/id/$deviceId',
      options: Options(
        headers: {
          'Authorization': 'Bearer ${_apiKeys['jamf']}',
        },
      ),
    );

    return MdmResult<Map<String, String>>(
      success: response.statusCode == 201,
      data: {'action': 'wipe', 'deviceId': deviceId},
      provider: 'JAMF',
    );
  }

  Future<MdmResult<Map<String, String>>> _wipeMobileIronDevice(String deviceId, bool preserveEnrollment) async {
    final response = await _dio.post(
      '${_providerConfigs['mobileiron']}device/$deviceId/actions/wipe',
      data: {
        'preserveEnrollment': preserveEnrollment,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer ${_apiKeys['mobileiron']}',
          'Content-Type': 'application/json',
        },
      ),
    );

    return MdmResult<Map<String, String>>(
      success: response.statusCode == 200,
      data: {'action': 'wipe', 'deviceId': deviceId},
      provider: 'MobileIron',
    );
  }

  // Device sync
  Future<void> _syncAllDevices() async {
    developer.log('Starting MDM device sync');
    
    for (final provider in _providerConfigs.keys) {
      try {
        await _syncProviderDevices(provider);
      } catch (e) {
        developer.log('Error syncing $provider devices: $e');
      }
    }

    _eventController.add(MdmEvent(
      id: _uuid.v4(),
      type: MdmEventType.syncCompleted,
      provider: 'All',
      title: 'Device Sync Completed',
      description: 'MDM device sync completed for all providers.',
      deviceId: '',
      data: {'timestamp': DateTime.now().toIso8601String()},
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _syncProviderDevices(String provider) async {
    switch (provider) {
      case 'microsoft_intune':
        await getIntuneDevices();
        break;
      // Add other provider sync implementations
    }
  }

  Future<MdmResult<Map<String, dynamic>>> getDeviceDetails({
    required String deviceId,
    required String provider,
  }) async {
    try {
      switch (provider.toLowerCase()) {
        case 'microsoft_intune':
          final response = await _dio.get(
            '${_providerConfigs['microsoft_intune']}deviceManagement/managedDevices/$deviceId',
            options: Options(
              headers: {
                'Authorization': 'Bearer ${_apiKeys['microsoft_intune']}',
              },
            ),
          );
          if (response.statusCode == 200) {
            return MdmResult(success: true, data: response.data, provider: provider);
          } else {
            return MdmResult(success: false, error: 'Failed to get device details: ${response.statusCode}', provider: provider);
          }
        // Add cases for other providers here
        default:
          return MdmResult(success: false, error: 'Unsupported provider: $provider', provider: provider);
      }
    } catch (e) {
      developer.log('Get device details error: $e');
      return MdmResult(success: false, error: e.toString(), provider: provider);
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _eventController.close();
    _deviceEnrollmentController.close();
    _complianceStatusController.close();
    _deviceActionController.close();
    super.dispose();
  }
}


