class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://your-project-name.up.railway.app',
  );
  
  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: '',
  );
  
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: true,
  );
  
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  static const Map<String, String> endpoints = {
    // Security Orchestration
    'playbooks': '/api/security/playbooks',
    'cases': '/api/security/cases',
    'executePlaybook': '/api/security/playbooks/{id}/execute',
    
    // Performance Monitoring
    'metrics': '/api/monitoring/metrics',
    'services': '/api/monitoring/services',
    'alerts': '/api/monitoring/alerts',
    'slas': '/api/monitoring/slas',
    'capacity': '/api/monitoring/capacity',
    
    // Emerging Threats
    'threats': '/api/threats/emerging',
    'iotDevices': '/api/threats/iot-devices',
    'containers': '/api/threats/containers',
    'apiEndpoints': '/api/threats/api-endpoints',
    'supplyChain': '/api/threats/supply-chain',
  };
}
