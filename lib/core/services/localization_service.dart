import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';

class LocaleData {
  final String languageCode;
  final String countryCode;
  final String displayName;
  final bool isRTL;
  final Map<String, String> translations;

  LocaleData({
    required this.languageCode,
    required this.countryCode,
    required this.displayName,
    required this.isRTL,
    required this.translations,
  });

  String get localeCode => countryCode.isEmpty ? languageCode : '${languageCode}_$countryCode';

  LocaleData copyWith({Map<String, String>? translations}) => LocaleData(
    languageCode: languageCode,
    countryCode: countryCode,
    displayName: displayName,
    isRTL: isRTL,
    translations: translations ?? this.translations,
  );

  Map<String, dynamic> toJson() => {
    'language_code': languageCode,
    'country_code': countryCode,
    'display_name': displayName,
    'is_rtl': isRTL,
    'translations': translations,
  };
}

class TranslationRequest {
  final String key;
  final String sourceText;
  final String targetLanguage;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;

  TranslationRequest({
    required this.key,
    required this.sourceText,
    required this.targetLanguage,
    this.parameters = const {},
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'key': key,
    'source_text': sourceText,
    'target_language': targetLanguage,
    'parameters': parameters,
    'timestamp': timestamp.toIso8601String(),
  };
}

class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  final Map<String, LocaleData> _locales = {};
  final Map<String, String> _fallbackTranslations = {};
  final List<TranslationRequest> _translationRequests = [];
  final List<String> _recentlyUsedKeys = [];
  
  String _currentLocale = 'en_US';
  String _fallbackLocale = 'en_US';
  
  final StreamController<String> _localeController = StreamController.broadcast();
  final StreamController<TranslationRequest> _translationController = StreamController.broadcast();

  Stream<String> get localeStream => _localeController.stream;
  Stream<TranslationRequest> get translationRequestStream => _translationController.stream;

  String get currentLocale => _currentLocale;
  bool get isRTL => _locales[_currentLocale]?.isRTL ?? false;

  Future<void> initialize() async {
    await _loadSupportedLocales();
    await _loadTranslations();
    await _detectSystemLocale();
    
    developer.log('Localization Service initialized with locale: $_currentLocale', name: 'LocalizationService');
  }

  Future<void> _loadSupportedLocales() async {
    _locales['en_US'] = LocaleData(
      languageCode: 'en', countryCode: 'US', displayName: 'English (US)', isRTL: false, translations: {},
    );
    _locales['es_ES'] = LocaleData(
      languageCode: 'es', countryCode: 'ES', displayName: 'Español', isRTL: false, translations: {},
    );
    _locales['fr_FR'] = LocaleData(
      languageCode: 'fr', countryCode: 'FR', displayName: 'Français', isRTL: false, translations: {},
    );
    _locales['de_DE'] = LocaleData(
      languageCode: 'de', countryCode: 'DE', displayName: 'Deutsch', isRTL: false, translations: {},
    );
    _locales['ar_SA'] = LocaleData(
      languageCode: 'ar', countryCode: 'SA', displayName: 'العربية', isRTL: true, translations: {},
    );
    _locales['zh_CN'] = LocaleData(
      languageCode: 'zh', countryCode: 'CN', displayName: '中文', isRTL: false, translations: {},
    );
    _locales['ja_JP'] = LocaleData(
      languageCode: 'ja', countryCode: 'JP', displayName: '日本語', isRTL: false, translations: {},
    );
    _locales['ru_RU'] = LocaleData(
      languageCode: 'ru', countryCode: 'RU', displayName: 'Русский', isRTL: false, translations: {},
    );
  }

  Future<void> _loadTranslations() async {
    final englishTranslations = {
      'app_name': 'Security Center',
      'welcome': 'Welcome',
      'login': 'Login',
      'logout': 'Logout',
      'register': 'Register',
      'settings': 'Settings',
      'profile': 'Profile',
      'dashboard': 'Dashboard',
      'notifications': 'Notifications',
      'help': 'Help',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'close': 'Close',
      'confirm': 'Confirm',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
      'error': 'Error',
      'success': 'Success',
      'warning': 'Warning',
      'loading': 'Loading...',
      'security_alerts': 'Security Alerts',
      'threat_intelligence': 'Threat Intelligence',
      'incident_response': 'Incident Response',
      'user_management': 'User Management',
      'access_control': 'Access Control',
      'audit_logs': 'Audit Logs',
      'compliance': 'Compliance',
      'risk_assessment': 'Risk Assessment',
      'vulnerability_scan': 'Vulnerability Scan',
      'security_policy': 'Security Policy',
      'encryption': 'Encryption',
      'authentication': 'Authentication',
      'authorization': 'Authorization',
      'multi_factor_auth': 'Multi-Factor Authentication',
      'biometric_auth': 'Biometric Authentication',
      'password_policy': 'Password Policy',
      'session_management': 'Session Management',
      'device_trust': 'Device Trust',
      'zero_trust': 'Zero Trust',
      'security_score': 'Security Score',
      'threat_level': 'Threat Level',
      'risk_score': 'Risk Score',
      'critical': 'Critical',
      'high': 'High',
      'medium': 'Medium',
      'low': 'Low',
      'active': 'Active',
      'inactive': 'Inactive',
      'pending': 'Pending',
      'approved': 'Approved',
      'denied': 'Denied',
      'login_success': 'Login successful',
      'login_failed': 'Login failed',
      'access_denied': 'Access denied',
      'session_expired': 'Session expired',
      'invalid_credentials': 'Invalid credentials',
      'network_error': 'Network connection error',
      'server_error': 'Server error occurred',
      'data_saved': 'Data saved successfully',
      'operation_failed': 'Operation failed',
    };

    _locales['en_US'] = _locales['en_US']!.copyWith(translations: englishTranslations);
    _fallbackTranslations.addAll(englishTranslations);

    // Load Spanish translations
    final spanishTranslations = {
      'app_name': 'Centro de Seguridad',
      'welcome': 'Bienvenido',
      'login': 'Iniciar Sesión',
      'logout': 'Cerrar Sesión',
      'register': 'Registrarse',
      'settings': 'Configuración',
      'profile': 'Perfil',
      'dashboard': 'Panel de Control',
      'notifications': 'Notificaciones',
      'help': 'Ayuda',
      'cancel': 'Cancelar',
      'save': 'Guardar',
      'delete': 'Eliminar',
      'security_alerts': 'Alertas de Seguridad',
      'threat_intelligence': 'Inteligencia de Amenazas',
      'user_management': 'Gestión de Usuarios',
      'access_control': 'Control de Acceso',
      'authentication': 'Autenticación',
      'authorization': 'Autorización',
      'critical': 'Crítico',
      'high': 'Alto',
      'medium': 'Medio',
      'low': 'Bajo',
    };
    _locales['es_ES'] = _locales['es_ES']!.copyWith(translations: spanishTranslations);

    // Load Arabic translations
    final arabicTranslations = {
      'app_name': 'مركز الأمان',
      'welcome': 'مرحباً',
      'login': 'تسجيل الدخول',
      'logout': 'تسجيل الخروج',
      'register': 'التسجيل',
      'settings': 'الإعدادات',
      'profile': 'الملف الشخصي',
      'dashboard': 'لوحة التحكم',
      'notifications': 'الإشعارات',
      'help': 'المساعدة',
      'security_alerts': 'تنبيهات الأمان',
      'threat_intelligence': 'استخبارات التهديدات',
      'user_management': 'إدارة المستخدمين',
      'access_control': 'التحكم في الوصول',
      'authentication': 'المصادقة',
      'authorization': 'التخويل',
    };
    _locales['ar_SA'] = _locales['ar_SA']!.copyWith(translations: arabicTranslations);
  }

  Future<void> _detectSystemLocale() async {
    try {
      final systemLocales = await _getSystemLocales();
      for (final locale in systemLocales) {
        if (_locales.containsKey(locale)) {
          _currentLocale = locale;
          break;
        }
      }
    } catch (e) {
      developer.log('Failed to detect system locale: $e', name: 'LocalizationService');
    }
  }

  Future<List<String>> _getSystemLocales() async {
    return ['en_US']; // Mock implementation
  }

  String translate(String key, {Map<String, dynamic>? parameters}) {
    _trackKeyUsage(key);
    
    final currentTranslations = _locales[_currentLocale]?.translations ?? {};
    String translation = currentTranslations[key] ?? _fallbackTranslations[key] ?? key;
    
    if (currentTranslations[key] == null && _fallbackTranslations[key] == null) {
      _requestTranslation(key, translation);
    }
    
    if (parameters != null && parameters.isNotEmpty) {
      translation = _interpolateParameters(translation, parameters);
    }
    
    return translation;
  }

  String _interpolateParameters(String text, Map<String, dynamic> parameters) {
    String result = text;
    for (final entry in parameters.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value.toString());
    }
    return result;
  }

  void _trackKeyUsage(String key) {
    _recentlyUsedKeys.remove(key);
    _recentlyUsedKeys.insert(0, key);
    if (_recentlyUsedKeys.length > 100) {
      _recentlyUsedKeys.removeLast();
    }
  }

  void _requestTranslation(String key, String sourceText) {
    final request = TranslationRequest(
      key: key,
      sourceText: sourceText,
      targetLanguage: _currentLocale,
      timestamp: DateTime.now(),
    );
    
    _translationRequests.add(request);
    _translationController.add(request);
    
    developer.log('Translation requested for key: $key', name: 'LocalizationService');
  }

  Future<void> setLocale(String localeCode) async {
    if (_locales.containsKey(localeCode)) {
      _currentLocale = localeCode;
      _localeController.add(_currentLocale);
      
      developer.log('Locale changed to: $localeCode', name: 'LocalizationService');
    }
  }

  List<LocaleData> getSupportedLocales() {
    return _locales.values.toList();
  }

  Future<void> addTranslation(String localeCode, String key, String translation) async {
    if (_locales.containsKey(localeCode)) {
      final locale = _locales[localeCode]!;
      final updatedTranslations = Map<String, String>.from(locale.translations);
      updatedTranslations[key] = translation;
      
      _locales[localeCode] = locale.copyWith(translations: updatedTranslations);
      
      developer.log('Added translation for $localeCode: $key = $translation', name: 'LocalizationService');
    }
  }

  Map<String, dynamic> getLocalizationMetrics() {
    final totalKeys = _fallbackTranslations.length;
    final languageCompleteness = <String, int>{};
    
    for (final entry in _locales.entries) {
      languageCompleteness[entry.key] = entry.value.translations.length;
    }
    
    return {
      'current_locale': _currentLocale,
      'total_keys': totalKeys,
      'supported_locales': _locales.keys.toList(),
      'language_completeness': languageCompleteness,
      'recent_translation_requests': _translationRequests.take(10).map((r) => r.toJson()).toList(),
      'recently_used_keys': _recentlyUsedKeys.take(20).toList(),
      'is_rtl': isRTL,
    };
  }

  void dispose() {
    _localeController.close();
    _translationController.close();
  }
}
