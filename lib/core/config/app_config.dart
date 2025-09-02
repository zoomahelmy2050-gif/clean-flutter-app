class AppConfig {
  // Environment configuration
  static const String _environment = 'production'; // Changed to production to use deployed backend
  
  // Backend URLs for different environments
  static const Map<String, String> _backendUrls = {
    'development': 'local', // Use local storage only during development
    'staging': 'https://clean-flutter-app.onrender.com', // Render staging
    'production': 'https://clean-flutter-app.onrender.com', // Render production - Your deployed backend
  };
  
  // Get current backend URL based on environment
  static String get backendUrl {
    return _backendUrls[_environment] ?? _backendUrls['development']!;
  }
  
  // Environment checks
  static bool get isDevelopment => _environment == 'development';
  static bool get isStaging => _environment == 'staging';
  static bool get isProduction => _environment == 'production';
  
  // Local development mode - use local storage instead of backend
  static bool get useLocalStorage => isDevelopment;
  
  // API endpoints
  static String get healthEndpoint => '$backendUrl/health';
  static String get authRegisterEndpoint => '$backendUrl/auth/register';
  static String get authLoginEndpoint => '$backendUrl/auth/login';
  static String get authRotateEndpoint => '$backendUrl/auth/rotate-verifier';
  static String get blobsListEndpoint => '$backendUrl/blobs/list';
  static String blobEndpoint(String key) => '$backendUrl/blobs/$key';
  
  // App configuration
  static const String appName = 'Security Center';
  static const String appVersion = '1.0.0';
  
  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 10);
  static const Duration healthCheckTimeout = Duration(seconds: 5);
  
  // Debug settings
  static bool get enableLogging => !isProduction;
  static bool get enableDebugFeatures => isDevelopment;
}
