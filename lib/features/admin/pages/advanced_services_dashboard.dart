import 'package:flutter/material.dart';
import '../../../core/services/enhanced_accessibility_service.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/services/executive_reporting_service.dart';
import '../../../core/services/integration_hub_service.dart';
import '../../../core/services/feature_flag_service.dart';
import '../../../core/services/advanced_encryption_service.dart';
import '../../../core/services/security_testing_service.dart';
import '../../../core/services/device_security_service.dart';
import '../../../core/services/offline_security_service.dart';
import '../../../core/services/business_intelligence_service.dart';
import '../../../core/services/threat_intelligence_platform.dart';
import '../../../locator.dart';

class AdvancedServicesDashboard extends StatefulWidget {
  const AdvancedServicesDashboard({super.key});

  @override
  State<AdvancedServicesDashboard> createState() => _AdvancedServicesDashboardState();
}

class _AdvancedServicesDashboardState extends State<AdvancedServicesDashboard> {
  final Map<String, bool> _serviceStatus = {};
  final Map<String, Map<String, dynamic>> _serviceMetrics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServiceStatus();
  }

  Future<void> _loadServiceStatus() async {
    setState(() => _isLoading = true);
    
    try {
      // AI-Powered Security Service
      _serviceStatus['ai_security'] = true;
      _serviceMetrics['ai_security'] = {
        'threats_detected': '127',
        'risk_score': '8.2',
        'alerts_today': '15',
        'status': 'Active'
      };

      // Advanced Biometrics Service
      _serviceStatus['biometrics'] = true;
      _serviceMetrics['biometrics'] = {
        'enrolled_users': '1,234',
        'success_rate': '98.7%',
        'failed_attempts': '23',
        'status': 'Active'
      };

      // Smart Onboarding Service
      _serviceStatus['onboarding'] = true;
      _serviceMetrics['onboarding'] = {
        'active_flows': '45',
        'completion_rate': '92.3%',
        'avg_time': '4.2 min',
        'status': 'Active'
      };

      // Enhanced Accessibility Service
      final accessibilityService = locator<EnhancedAccessibilityService>();
      _serviceStatus['accessibility'] = true;
      _serviceMetrics['accessibility'] = accessibilityService.getAccessibilityMetrics();

      // Localization Service
      final localizationService = locator<LocalizationService>();
      _serviceStatus['localization'] = true;
      _serviceMetrics['localization'] = localizationService.getLocalizationMetrics();

      // Multi-Tenant Service
      _serviceStatus['multi_tenant'] = true;
      _serviceMetrics['multi_tenant'] = {
        'active_tenants': '12',
        'total_users': '5,678',
        'storage_used': '2.3 GB',
        'status': 'Active'
      };

      // Executive Reporting Service
      final reportingService = locator<ExecutiveReportingService>();
      _serviceStatus['reporting'] = true;
      _serviceMetrics['reporting'] = reportingService.getReportingMetrics();

      // Integration Hub Service
      final integrationService = locator<IntegrationHubService>();
      _serviceStatus['integration'] = true;
      _serviceMetrics['integration'] = integrationService.getIntegrationMetrics();

      // API Gateway Service
      _serviceStatus['api_gateway'] = true;
      _serviceMetrics['api_gateway'] = {
        'requests_today': '45,231',
        'avg_response': '125ms',
        'error_rate': '0.3%',
        'status': 'Active'
      };

      // Health Monitoring Service
      _serviceStatus['health_monitoring'] = true;
      _serviceMetrics['health_monitoring'] = {
        'system_health': '98.5%',
        'uptime': '99.9%',
        'alerts_active': '2',
        'status': 'Active'
      };

      // Feature Flag Service
      final featureFlagService = locator<FeatureFlagService>();
      _serviceStatus['feature_flags'] = true;
      _serviceMetrics['feature_flags'] = featureFlagService.getFeatureFlagMetrics();

      // Advanced Encryption Service
      final encryptionService = locator<AdvancedEncryptionService>();
      _serviceStatus['encryption'] = true;
      _serviceMetrics['encryption'] = encryptionService.getEncryptionMetrics();

      // Security Testing Service
      final testingService = locator<SecurityTestingService>();
      _serviceStatus['security_testing'] = true;
      _serviceMetrics['security_testing'] = testingService.getTestingMetrics();

      // Device Security Service
      final deviceSecurityService = locator<DeviceSecurityService>();
      _serviceStatus['device_security'] = true;
      _serviceMetrics['device_security'] = deviceSecurityService.getSecurityMetrics();

      // Offline Security Service
      final offlineSecurityService = locator<OfflineSecurityService>();
      _serviceStatus['offline_security'] = true;
      _serviceMetrics['offline_security'] = offlineSecurityService.getOfflineSecurityMetrics();

      // Business Intelligence Service
      final biService = locator<BusinessIntelligenceService>();
      _serviceStatus['business_intelligence'] = true;
      _serviceMetrics['business_intelligence'] = biService.getBusinessIntelligenceMetrics();

      // Threat Intelligence Platform
      final threatIntelService = locator<ThreatIntelligencePlatform>();
      _serviceStatus['threat_intelligence'] = true;
      _serviceMetrics['threat_intelligence'] = threatIntelService.getPlatformMetrics();

    } catch (e) {
      debugPrint('Error loading service status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Services Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadServiceStatus,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadServiceStatus,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildOverviewCard(),
                  const SizedBox(height: 16),
                  _buildServiceGrid(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewCard() {
    final totalServices = _serviceStatus.length;
    final activeServices = _serviceStatus.values.where((status) => status).length;
    final uptime = activeServices / totalServices * 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Services Overview',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    'Total Services',
                    totalServices.toString(),
                    Icons.dashboard,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildMetricTile(
                    'Active Services',
                    activeServices.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildMetricTile(
                    'System Uptime',
                    '${uptime.toStringAsFixed(1)}%',
                    Icons.trending_up,
                    uptime > 95 ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _serviceStatus.length,
      itemBuilder: (context, index) {
        final serviceKey = _serviceStatus.keys.elementAt(index);
        final isActive = _serviceStatus[serviceKey] ?? false;
        final metrics = _serviceMetrics[serviceKey] ?? {};
        
        return _buildServiceCard(serviceKey, isActive, metrics);
      },
    );
  }

  Widget _buildServiceCard(String serviceKey, bool isActive, Map<String, dynamic> metrics) {
    final serviceInfo = _getServiceInfo(serviceKey);
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showServiceDetails(serviceKey, metrics),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    serviceInfo['icon'],
                    color: serviceInfo['color'],
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      serviceInfo['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (metrics.isNotEmpty) ...[
                Text(
                  _getKeyMetric(serviceKey, metrics),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getServiceInfo(String serviceKey) {
    final serviceInfoMap = {
      'ai_security': {
        'name': 'AI-Powered Security',
        'icon': Icons.psychology,
        'color': Colors.purple,
      },
      'biometrics': {
        'name': 'Advanced Biometrics',
        'icon': Icons.fingerprint,
        'color': Colors.indigo,
      },
      'onboarding': {
        'name': 'Smart Onboarding',
        'icon': Icons.school,
        'color': Colors.blue,
      },
      'accessibility': {
        'name': 'Enhanced Accessibility',
        'icon': Icons.accessibility,
        'color': Colors.green,
      },
      'localization': {
        'name': 'Localization',
        'icon': Icons.language,
        'color': Colors.orange,
      },
      'multi_tenant': {
        'name': 'Multi-Tenant',
        'icon': Icons.business,
        'color': Colors.teal,
      },
      'reporting': {
        'name': 'Executive Reporting',
        'icon': Icons.analytics,
        'color': Colors.red,
      },
      'integration': {
        'name': 'Integration Hub',
        'icon': Icons.hub,
        'color': Colors.pink,
      },
      'api_gateway': {
        'name': 'API Gateway',
        'icon': Icons.api,
        'color': Colors.cyan,
      },
      'health_monitoring': {
        'name': 'Health Monitoring',
        'icon': Icons.monitor_heart,
        'color': Colors.lightGreen,
      },
      'feature_flags': {
        'name': 'Feature Flags',
        'icon': Icons.flag,
        'color': Colors.amber,
      },
      'encryption': {
        'name': 'Advanced Encryption',
        'icon': Icons.lock,
        'color': Colors.deepPurple,
      },
      'security_testing': {
        'name': 'Security Testing',
        'icon': Icons.security,
        'color': Colors.brown,
      },
      'device_security': {
        'name': 'Device Security',
        'icon': Icons.phone_android,
        'color': Colors.blueGrey,
      },
      'offline_security': {
        'name': 'Offline Security',
        'icon': Icons.offline_bolt,
        'color': Colors.deepOrange,
      },
      'business_intelligence': {
        'name': 'Business Intelligence',
        'icon': Icons.trending_up,
        'color': Colors.lime,
      },
      'threat_intelligence': {
        'name': 'Threat Intelligence',
        'icon': Icons.radar,
        'color': Colors.redAccent,
      },
    };

    return serviceInfoMap[serviceKey] ?? {
      'name': serviceKey.replaceAll('_', ' ').toUpperCase(),
      'icon': Icons.settings,
      'color': Colors.grey,
    };
  }

  String _getKeyMetric(String serviceKey, Map<String, dynamic> metrics) {
    switch (serviceKey) {
      case 'ai_security':
        return 'Threats Detected: ${metrics['total_threats_detected'] ?? 0}';
      case 'biometrics':
        return 'Active Methods: ${metrics['active_biometric_methods'] ?? 0}';
      case 'onboarding':
        return 'Completed Flows: ${metrics['completed_onboarding_flows'] ?? 0}';
      case 'accessibility':
        return 'Features Active: ${metrics['active_accessibility_features'] ?? 0}';
      case 'localization':
        return 'Languages: ${metrics['supported_languages'] ?? 0}';
      case 'multi_tenant':
        return 'Active Tenants: ${metrics['active_tenants'] ?? 0}';
      case 'reporting':
        return 'Reports Generated: ${metrics['total_reports_generated'] ?? 0}';
      case 'integration':
        return 'Active Integrations: ${metrics['active_integrations'] ?? 0}';
      case 'api_gateway':
        return 'Requests/min: ${metrics['requests_per_minute'] ?? 0}';
      case 'health_monitoring':
        return 'Services Monitored: ${metrics['monitored_services'] ?? 0}';
      case 'feature_flags':
        return 'Active Flags: ${metrics['enabled_flags'] ?? 0}';
      case 'encryption':
        return 'Active Keys: ${metrics['active_keys'] ?? 0}';
      case 'security_testing':
        return 'Tests Completed: ${metrics['completed_tests'] ?? 0}';
      case 'device_security':
        return 'Threats Blocked: ${metrics['active_threats'] ?? 0}';
      case 'offline_security':
        return 'Events Processed: ${metrics['total_security_events'] ?? 0}';
      case 'business_intelligence':
        return 'ROI: ${metrics['net_roi_percentage']?.toStringAsFixed(1) ?? '0'}%';
      case 'threat_intelligence':
        return 'Intel Sources: ${metrics['collection_sources'] ?? 0}';
      default:
        return 'Status: Active';
    }
  }

  void _showServiceDetails(String serviceKey, Map<String, dynamic> metrics) {
    final serviceInfo = _getServiceInfo(serviceKey);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(serviceInfo['icon'], color: serviceInfo['color']),
            const SizedBox(width: 8),
            Expanded(child: Text(serviceInfo['name'])),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Service Metrics',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              if (metrics.isEmpty)
                const Text('No metrics available')
              else
                ...metrics.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(entry.value.toString()),
                    ],
                  ),
                )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
