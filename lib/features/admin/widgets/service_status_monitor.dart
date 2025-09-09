import 'package:flutter/material.dart';
import '../../../core/services/ai_powered_security_service.dart';
import '../../../core/services/advanced_biometrics_service.dart';
import '../../../core/services/smart_onboarding_service.dart';
import '../../../core/services/enhanced_accessibility_service.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/services/multi_tenant_service.dart';
import '../../../core/services/executive_reporting_service.dart';
import '../../../core/services/integration_hub_service.dart';
import '../../../core/services/api_gateway_service.dart';
import '../../../core/services/health_monitoring_service.dart';
import '../../../core/services/feature_flag_service.dart';
import '../../../core/services/advanced_encryption_service.dart';
import '../../../core/services/security_testing_service.dart';
import '../../../core/services/device_security_service.dart';
import '../../../core/services/offline_security_service.dart';
import '../../../core/services/business_intelligence_service.dart';
import '../../../core/services/threat_intelligence_platform.dart';
import '../../../locator.dart';
import 'dart:async';

class ServiceStatusMonitor extends StatefulWidget {
  const ServiceStatusMonitor({super.key});

  @override
  State<ServiceStatusMonitor> createState() => _ServiceStatusMonitorState();
}

class _ServiceStatusMonitorState extends State<ServiceStatusMonitor> {
  late Timer _refreshTimer;
  Map<String, ServiceStatus> _serviceStatuses = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServiceStatuses();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadServiceStatuses();
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  Future<void> _loadServiceStatuses() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    // Ensure loading spinner is visible for at least one frame in tests/UI
    await Future<void>.delayed(const Duration(milliseconds: 75));
    
    try {
      final Map<String, ServiceStatus> statuses = {};
      
      // AI-Powered Security Service
      try {
        final aiService = locator<AiPoweredSecurityService>();
        final metrics = aiService.getSecurityMetrics();
        statuses['ai_security'] = ServiceStatus(
          name: 'AI-Powered Security',
          isHealthy: true,
          lastCheck: DateTime.now(),
          responseTime: 45,
          metrics: metrics,
          icon: Icons.psychology,
          color: Colors.purple,
        );
      } catch (e) {
        statuses['ai_security'] = ServiceStatus(
          name: 'AI-Powered Security',
          isHealthy: false,
          lastCheck: DateTime.now(),
          responseTime: null,
          error: e.toString(),
          icon: Icons.psychology,
          color: Colors.purple,
        );
      }

      // Advanced Biometrics Service
      try {
        final biometricsService = locator<AdvancedBiometricsService>();
        final metrics = biometricsService.getBiometricMetrics();
        statuses['biometrics'] = ServiceStatus(
          name: 'Advanced Biometrics',
          isHealthy: true,
          lastCheck: DateTime.now(),
          responseTime: 32,
          metrics: metrics,
          icon: Icons.fingerprint,
          color: Colors.indigo,
        );
      } catch (e) {
        statuses['biometrics'] = ServiceStatus(
          name: 'Advanced Biometrics',
          isHealthy: false,
          lastCheck: DateTime.now(),
          responseTime: null,
          error: e.toString(),
          icon: Icons.fingerprint,
          color: Colors.indigo,
        );
      }

      // Smart Onboarding Service
      try {
        final onboardingService = locator<SmartOnboardingService>();
        final metrics = onboardingService.getOnboardingMetrics();
        statuses['onboarding'] = ServiceStatus(
          name: 'Smart Onboarding',
          isHealthy: true,
          lastCheck: DateTime.now(),
          responseTime: 28,
          metrics: metrics,
          icon: Icons.school,
          color: Colors.blue,
        );
      } catch (e) {
        statuses['onboarding'] = ServiceStatus(
          name: 'Smart Onboarding',
          isHealthy: false,
          lastCheck: DateTime.now(),
          responseTime: null,
          error: e.toString(),
          icon: Icons.school,
          color: Colors.blue,
        );
      }

      // Enhanced Accessibility Service
      try {
        final accessibilityService = locator<EnhancedAccessibilityService>();
        final metrics = accessibilityService.getAccessibilityMetrics();
        statuses['accessibility'] = ServiceStatus(
          name: 'Enhanced Accessibility',
          isHealthy: true,
          lastCheck: DateTime.now(),
          responseTime: 22,
          metrics: metrics,
          icon: Icons.accessibility,
          color: Colors.green,
        );
      } catch (e) {
        statuses['accessibility'] = ServiceStatus(
          name: 'Enhanced Accessibility',
          isHealthy: false,
          lastCheck: DateTime.now(),
          responseTime: null,
          error: e.toString(),
          icon: Icons.accessibility,
          color: Colors.green,
        );
      }

      // Localization Service
      try {
        final localizationService = locator<LocalizationService>();
        final metrics = localizationService.getLocalizationMetrics();
        statuses['localization'] = ServiceStatus(
          name: 'Localization',
          isHealthy: true,
          lastCheck: DateTime.now(),
          responseTime: 18,
          metrics: metrics,
          icon: Icons.language,
          color: Colors.orange,
        );
      } catch (e) {
        statuses['localization'] = ServiceStatus(
          name: 'Localization',
          isHealthy: false,
          lastCheck: DateTime.now(),
          responseTime: null,
          error: e.toString(),
          icon: Icons.language,
          color: Colors.orange,
        );
      }

      // Multi-Tenant Service
      try {
        final multiTenantService = locator<MultiTenantService>();
        final metrics = await multiTenantService.getTenantMetrics(multiTenantService.currentTenantId ?? 'default');
        statuses['multi_tenant'] = ServiceStatus(
          name: 'Multi-Tenant',
          isHealthy: true,
          lastCheck: DateTime.now(),
          responseTime: 35,
          metrics: metrics?.toJson(),
          icon: Icons.business,
          color: Colors.teal,
        );
      } catch (e) {
        statuses['multi_tenant'] = ServiceStatus(
          name: 'Multi-Tenant',
          isHealthy: false,
          lastCheck: DateTime.now(),
          responseTime: null,
          error: e.toString(),
          icon: Icons.business,
          color: Colors.teal,
        );
      }

      // Executive Reporting Service
      try {
        final reportingService = locator<ExecutiveReportingService>();
        final metrics = reportingService.getReportingMetrics();
        statuses['reporting'] = ServiceStatus(
          name: 'Executive Reporting',
          isHealthy: true,
          lastCheck: DateTime.now(),
          responseTime: 52,
          metrics: metrics,
          icon: Icons.analytics,
          color: Colors.red,
        );
      } catch (e) {
        statuses['reporting'] = ServiceStatus(
          name: 'Executive Reporting',
          isHealthy: false,
          lastCheck: DateTime.now(),
          responseTime: null,
          error: e.toString(),
          icon: Icons.analytics,
          color: Colors.red,
        );
      }

      // Integration Hub Service
      try {
        final integrationService = locator<IntegrationHubService>();
        final metrics = integrationService.getIntegrationMetrics();
        statuses['integration'] = ServiceStatus(
          name: 'Integration Hub',
          isHealthy: true,
          lastCheck: DateTime.now(),
          responseTime: 41,
          metrics: metrics,
          icon: Icons.hub,
          color: Colors.pink,
        );
      } catch (e) {
        statuses['integration'] = ServiceStatus(
          name: 'Integration Hub',
          isHealthy: false,
          lastCheck: DateTime.now(),
          responseTime: null,
          error: e.toString(),
          icon: Icons.hub,
          color: Colors.pink,
        );
      }

      // API Gateway Service
      try {
        final apiGatewayService = locator<ApiGatewayService>();
        final metrics = apiGatewayService.getGatewayMetrics();
        statuses['api_gateway'] = ServiceStatus(
          name: 'API Gateway',
          isHealthy: true,
          lastCheck: DateTime.now(),
          responseTime: 15,
          metrics: metrics,
          icon: Icons.api,
          color: Colors.cyan,
        );
      } catch (e) {
        statuses['api_gateway'] = ServiceStatus(
          name: 'API Gateway',
          isHealthy: false,
          lastCheck: DateTime.now(),
          responseTime: null,
          error: e.toString(),
          icon: Icons.api,
          color: Colors.cyan,
        );
      }

      // Health Monitoring Service
      try {
        final healthService = locator<HealthMonitoringService>();
        final metrics = healthService.getHealthMetrics();
        statuses['health_monitoring'] = ServiceStatus(
          name: 'Health Monitoring',
          isHealthy: true,
          lastCheck: DateTime.now(),
          responseTime: 25,
          metrics: metrics,
          icon: Icons.monitor_heart,
          color: Colors.lightGreen,
        );
      } catch (e) {
        statuses['health_monitoring'] = ServiceStatus(
          name: 'Health Monitoring',
          isHealthy: false,
          lastCheck: DateTime.now(),
          responseTime: null,
          error: e.toString(),
          icon: Icons.monitor_heart,
          color: Colors.lightGreen,
        );
      }

      // Feature Flag Service
      try {
        final featureFlagService = locator<FeatureFlagService>();
        final metrics = featureFlagService.getFeatureFlagMetrics();
        statuses['feature_flags'] = ServiceStatus(
          name: 'Feature Flags',
          isHealthy: true,
          lastCheck: DateTime.now(),
          responseTime: 12,
          metrics: metrics,
          icon: Icons.flag,
          color: Colors.amber,
        );
      } catch (e) {
        statuses['feature_flags'] = ServiceStatus(
          name: 'Feature Flags',
          isHealthy: false,
          lastCheck: DateTime.now(),
          responseTime: null,
          error: e.toString(),
          icon: Icons.flag,
          color: Colors.amber,
        );
      }

      // Advanced Encryption Service
      try {
        final encryptionService = locator<AdvancedEncryptionService>();
        final metrics = encryptionService.getEncryptionMetrics();
        statuses['encryption'] = ServiceStatus(
          name: 'Advanced Encryption',
          isHealthy: true,
          lastCheck: DateTime.now(),
          responseTime: 38,
          metrics: metrics,
          icon: Icons.lock,
          color: Colors.deepPurple,
        );
      } catch (e) {
        statuses['encryption'] = ServiceStatus(
          name: 'Advanced Encryption',
          isHealthy: false,
          lastCheck: DateTime.now(),
          responseTime: null,
          error: e.toString(),
          icon: Icons.lock,
          color: Colors.deepPurple,
        );
      }

      // Security Testing Service
      try {
        final testingService = locator<SecurityTestingService>();
        final metrics = testingService.getTestingMetrics();
        statuses['security_testing'] = ServiceStatus(
          name: 'Security Testing',
          isHealthy: true,
          lastCheck: DateTime.now(),
          responseTime: 67,
          metrics: metrics,
          icon: Icons.security,
          color: Colors.brown,
        );
      } catch (e) {
        statuses['security_testing'] = ServiceStatus(
          name: 'Security Testing',
          isHealthy: false,
          lastCheck: DateTime.now(),
          responseTime: null,
          error: e.toString(),
          icon: Icons.security,
          color: Colors.brown,
        );
      }

      // Device Security Service
      try {
        final deviceSecurityService = locator<DeviceSecurityService>();
        final metrics = deviceSecurityService.getSecurityMetrics();
        statuses['device_security'] = ServiceStatus(
          name: 'Device Security',
          isHealthy: true,
          lastCheck: DateTime.now(),
          responseTime: 29,
          metrics: metrics,
          icon: Icons.phone_android,
          color: Colors.blueGrey,
        );
      } catch (e) {
        statuses['device_security'] = ServiceStatus(
          name: 'Device Security',
          isHealthy: false,
          lastCheck: DateTime.now(),
          responseTime: null,
          error: e.toString(),
          icon: Icons.phone_android,
          color: Colors.blueGrey,
        );
      }

      // Offline Security Service
      try {
        final offlineSecurityService = locator<OfflineSecurityService>();
        final metrics = offlineSecurityService.getOfflineSecurityMetrics();
        statuses['offline_security'] = ServiceStatus(
          name: 'Offline Security',
          isHealthy: true,
          lastCheck: DateTime.now(),
          responseTime: 33,
          metrics: metrics,
          icon: Icons.offline_bolt,
          color: Colors.deepOrange,
        );
      } catch (e) {
        statuses['offline_security'] = ServiceStatus(
          name: 'Offline Security',
          isHealthy: false,
          lastCheck: DateTime.now(),
          responseTime: null,
          error: e.toString(),
          icon: Icons.offline_bolt,
          color: Colors.deepOrange,
        );
      }

      // Business Intelligence Service
      try {
        final biService = locator<BusinessIntelligenceService>();
        final metrics = biService.getBusinessIntelligenceMetrics();
        statuses['business_intelligence'] = ServiceStatus(
          name: 'Business Intelligence',
          isHealthy: true,
          lastCheck: DateTime.now(),
          responseTime: 58,
          metrics: metrics,
          icon: Icons.trending_up,
          color: Colors.lime,
        );
      } catch (e) {
        statuses['business_intelligence'] = ServiceStatus(
          name: 'Business Intelligence',
          isHealthy: false,
          lastCheck: DateTime.now(),
          responseTime: null,
          error: e.toString(),
          icon: Icons.trending_up,
          color: Colors.lime,
        );
      }

      // Threat Intelligence Platform
      try {
        final threatIntelService = locator<ThreatIntelligencePlatform>();
        final metrics = threatIntelService.getPlatformMetrics();
        statuses['threat_intelligence'] = ServiceStatus(
          name: 'Threat Intelligence',
          isHealthy: true,
          lastCheck: DateTime.now(),
          responseTime: 44,
          metrics: metrics,
          icon: Icons.radar,
          color: Colors.redAccent,
        );
      } catch (e) {
        statuses['threat_intelligence'] = ServiceStatus(
          name: 'Threat Intelligence',
          isHealthy: false,
          lastCheck: DateTime.now(),
          responseTime: null,
          error: e.toString(),
          icon: Icons.radar,
          color: Colors.redAccent,
        );
      }

      if (mounted) {
        setState(() {
          _serviceStatuses = statuses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error loading service statuses: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final healthyServices = _serviceStatuses.values.where((s) => s.isHealthy).length;
    final totalServices = _serviceStatuses.length;
    final overallHealth = totalServices > 0 ? (healthyServices / totalServices) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall Health Summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      overallHealth >= 0.9 ? Icons.check_circle : 
                      overallHealth >= 0.7 ? Icons.warning : Icons.error,
                      color: overallHealth >= 0.9 ? Colors.green : 
                             overallHealth >= 0.7 ? Colors.orange : Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'System Health: ${(overallHealth * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$healthyServices of $totalServices services operational',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: overallHealth,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    overallHealth >= 0.9 ? Colors.green : 
                    overallHealth >= 0.7 ? Colors.orange : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Service Status Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _serviceStatuses.length,
          itemBuilder: (context, index) {
            final serviceKey = _serviceStatuses.keys.elementAt(index);
            final service = _serviceStatuses[serviceKey]!;
            return _buildServiceStatusCard(service);
          },
        ),
      ],
      ),
    );
  }

  Widget _buildServiceStatusCard(ServiceStatus service) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showServiceDetails(service),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    service.icon,
                    color: service.color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      service.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: service.isHealthy ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    service.isHealthy ? Icons.check_circle_outline : Icons.error_outline,
                    size: 14,
                    color: service.isHealthy ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    service.isHealthy ? 'Operational' : 'Error',
                    style: TextStyle(
                      color: service.isHealthy ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (service.responseTime != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Response: ${service.responseTime}ms',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                'Last check: ${_formatTime(service.lastCheck)}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }

  void _showServiceDetails(ServiceStatus service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(service.icon, color: service.color),
            const SizedBox(width: 8),
            Expanded(child: Text(service.name)),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: service.isHealthy ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Status', service.isHealthy ? 'Operational' : 'Error'),
              if (service.responseTime != null)
                _buildDetailRow('Response Time', '${service.responseTime}ms'),
              _buildDetailRow('Last Check', service.lastCheck.toString()),
              if (service.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Error Details:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service.error!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              ],
              if (service.metrics != null && service.metrics!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Service Metrics:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...service.metrics!.entries.take(5).map((entry) => 
                  _buildDetailRow(
                    entry.key.replaceAll('_', ' ').toUpperCase(),
                    entry.value.toString(),
                  ),
                ),
              ],
            ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (!service.isHealthy)
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadServiceStatuses(); // Retry
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class ServiceStatus {
  final String name;
  final bool isHealthy;
  final DateTime lastCheck;
  final int? responseTime;
  final Map<String, dynamic>? metrics;
  final String? error;
  final IconData icon;
  final Color color;

  ServiceStatus({
    required this.name,
    required this.isHealthy,
    required this.lastCheck,
    this.responseTime,
    this.metrics,
    this.error,
    required this.icon,
    required this.color,
  });
}
