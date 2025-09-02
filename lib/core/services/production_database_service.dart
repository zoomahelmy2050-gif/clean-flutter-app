import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:crypto/crypto.dart';

class ProductionDatabaseService {
  static final ProductionDatabaseService _instance = ProductionDatabaseService._internal();
  factory ProductionDatabaseService() => _instance;
  ProductionDatabaseService._internal();

  bool _isInitialized = false;
  late String _supabaseUrl;
  late String _supabaseKey;
  late Map<String, String> _headers;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load environment variables
      _supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      _supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      
      _headers = {
        'Content-Type': 'application/json',
        'apikey': _supabaseKey,
        'Authorization': 'Bearer $_supabaseKey',
      };

      if (_supabaseUrl.isNotEmpty) {
        await _testConnection();
      }
      await _createSchema();
      _isInitialized = true;
      developer.log('Production Database Service initialized with Supabase', name: 'ProductionDatabaseService');
    } catch (e) {
      developer.log('Failed to initialize Production Database Service: $e', name: 'ProductionDatabaseService');
      // Fall back to mock mode if database connection fails
      _isInitialized = true;
      developer.log('Falling back to mock mode', name: 'ProductionDatabaseService');
    }
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    if (_supabaseUrl.isEmpty) {
      // Mock fallback
      await Future.delayed(const Duration(milliseconds: 50));
      return {
        'id': userId,
        'email': 'user@example.com',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      };
    }

    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/users?id=eq.$userId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.isNotEmpty ? data.first : null;
      }
    } catch (e) {
      developer.log('Error getting user: $e', name: 'ProductionDatabaseService');
    }
    return null;
  }

  Future<void> _testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/'),
        headers: _headers,
      );
      
      if (response.statusCode != 200) {
        throw Exception('Supabase connection failed: ${response.statusCode}');
      }
      
      developer.log('Supabase connection successful', name: 'ProductionDatabaseService');
    } catch (e) {
      developer.log('Supabase connection failed: $e', name: 'ProductionDatabaseService');
      rethrow;
    }
  }

  Future<void> _createSchema() async {
    if (_supabaseUrl.isEmpty) {
      developer.log('Mock: Schema creation skipped', name: 'ProductionDatabaseService');
      return;
    }

    // In production, schema would be managed via Supabase dashboard or migrations
    // This is just for logging purposes
    final tables = [
      'users', 'user_sessions', 'security_events', 'threat_alerts',
      'compliance_violations', 'managed_devices', 'device_policies',
      'forensic_cases', 'digital_evidence', 'crypto_operations', 'audit_logs'
    ];

    developer.log('Schema tables expected: ${tables.join(", ")}', name: 'ProductionDatabaseService');
  }

  Future<bool> registerUser(String email, String password) async {
    if (_supabaseUrl.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 100));
      developer.log('Mock: User registered - $email', name: 'ProductionDatabaseService');
      return true;
    }

    try {
      final hashedPassword = sha256.convert(utf8.encode(password)).toString();
      final userData = {
        'email': email,
        'password_hash': hashedPassword,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$_supabaseUrl/rest/v1/users'),
        headers: _headers,
        body: json.encode(userData),
      );

      return response.statusCode == 201;
    } catch (e) {
      developer.log('Error registering user: $e', name: 'ProductionDatabaseService');
      return false;
    }
  }

  Future<bool> authenticateUser(String email, String password) async {
    if (_supabaseUrl.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 100));
      developer.log('Mock: User authenticated - $email', name: 'ProductionDatabaseService');
      return true;
    }

    try {
      final hashedPassword = sha256.convert(utf8.encode(password)).toString();
      
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/users?email=eq.$email&password_hash=eq.$hashedPassword'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.isNotEmpty;
      }
    } catch (e) {
      developer.log('Error authenticating user: $e', name: 'ProductionDatabaseService');
    }
    return false;
  }

  Future<void> logSecurityEvent(String eventType, String severity, String description, {String? userId, Map<String, dynamic>? metadata}) async {
    if (_supabaseUrl.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 50));
      developer.log('Mock: Security event logged - $eventType', name: 'ProductionDatabaseService');
      return;
    }

    try {
      final eventData = {
        'event_type': eventType,
        'severity': severity,
        'description': description,
        'user_id': userId,
        'metadata': metadata ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      };

      await http.post(
        Uri.parse('$_supabaseUrl/rest/v1/security_events'),
        headers: _headers,
        body: json.encode(eventData),
      );
    } catch (e) {
      developer.log('Error logging security event: $e', name: 'ProductionDatabaseService');
    }
  }

  // Mock device management methods
  Future<void> enrollDevice(String deviceId, String userId, Map<String, dynamic> deviceInfo) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      developer.log('Mock: Device enrolled - $deviceId for user $userId', name: 'ProductionDatabaseService');
    } catch (e) {
      developer.log('Mock: Error enrolling device: $e', name: 'ProductionDatabaseService');
    }
  }

  Future<List<Map<String, dynamic>>> getUserDevices(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return [
      {
        'id': 'device-1',
        'device_name': 'iPhone 12',
        'platform': 'iOS',
        'enrollment_status': 'enrolled',
        'compliance_status': 'compliant',
      }
    ];
  }

  // Mock forensics methods
  Future<String> createForensicCase(String title, String description, String priority) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final caseId = 'case-${DateTime.now().millisecondsSinceEpoch}';
    developer.log('Mock: Forensic case created - $caseId', name: 'ProductionDatabaseService');
    return caseId;
  }

  Future<void> addDigitalEvidence(String caseId, String evidenceType, String fileName, Map<String, dynamic> metadata) async {
    await Future.delayed(const Duration(milliseconds: 100));
    developer.log('Mock: Digital evidence added to case $caseId', name: 'ProductionDatabaseService');
  }

  // Mock compliance methods
  Future<void> recordComplianceViolation(String frameworkId, String controlId, String violationType, String severity, String description) async {
    await Future.delayed(const Duration(milliseconds: 100));
    developer.log('Mock: Compliance violation recorded - $frameworkId:$controlId', name: 'ProductionDatabaseService');
  }

  // Mock crypto operations
  Future<String> recordCryptoOperation(String operationType, String algorithm, String keyId, Map<String, dynamic> metadata) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final operationId = 'crypto-${DateTime.now().millisecondsSinceEpoch}';
    developer.log('Mock: Crypto operation recorded - $operationId', name: 'ProductionDatabaseService');
    return operationId;
  }

  void dispose() {
    _isInitialized = false;
    developer.log('Production Database Service disposed (mock)', name: 'ProductionDatabaseService');
  }
}
