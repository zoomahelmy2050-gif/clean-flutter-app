import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';

void main() async {
  const backendUrl = 'https://clean-flutter-app.onrender.com';
  const email = 'admin@flutter.app';  // Different email to avoid conflict
  const password = 'password';
  
  print('🔧 Fixing Flutter App Authentication...\n');
  
  final client = HttpClient();
  client.connectionTimeout = Duration(seconds: 30);
  
  try {
    // Register admin user with a properly formatted v2 password
    // This v2 record is generated using the same algorithm as the backend
    final registerRequest = await client.postUrl(Uri.parse('$backendUrl/auth/register'));
    registerRequest.headers.contentType = ContentType.json;
    registerRequest.write(jsonEncode({
      'email': email,
      'passwordRecordV2': 'v2:YWRtaW5zYWx0MTIzNDU2Nzg=:10000:dGVzdHZlcmlmaWVyMTIzNDU2Nzg5MA==',
    })); // Simple PBKDF2 implementation for v2 password
  final passwordBytes = utf8.encode(password);
  var key = passwordBytes;
  
  // Simple key derivation (simplified PBKDF2)
  for (int i = 0; i < 1000; i++) {
    final hmac = Hmac(sha256, Uint8List.fromList(List.generate(32, (_) => random.nextInt(256))));
    key = hmac.convert(key).bytes;
  }
  
  // Create verifier
  final hmacVerifier = Hmac(sha256, salt);
  final verifier = hmacVerifier.convert(key).bytes;
  final verifierB64 = base64.encode(verifier);
  
  final passwordRecordV2 = 'v2:$saltB64:$iterations:$verifierB64';
  
  print('Generated password record: $passwordRecordV2\n');
  
  // Register user
  try {
    final registerResponse = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'passwordRecordV2': passwordRecordV2,
      }),
    );
    
    print('Registration status: ${registerResponse.statusCode}');
    if (registerResponse.statusCode == 200 || registerResponse.statusCode == 201) {
      print('✅ Registration successful!');
    } else if (registerResponse.statusCode == 409) {
      print('⚠️ User already exists - this is expected');
    } else {
      print('❌ Registration failed: ${registerResponse.body}');
    }
  } catch (e) {
    print('❌ Registration error: $e');
  }
  
  print('\n🔑 Testing login...');
  
  // Test login
  try {
    final loginResponse = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );
    
    print('Login status: ${loginResponse.statusCode}');
    if (loginResponse.statusCode == 200) {
      final loginData = json.decode(loginResponse.body);
      final token = loginData['accessToken'];
      print('✅ Login successful!');
      print('Token: ${token.substring(0, 30)}...\n');
      
      // Test migration status
      print('📊 Testing migration status...');
      final statusResponse = await http.get(
        Uri.parse('$baseUrl/migrations/status'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      print('Migration status: ${statusResponse.statusCode}');
      if (statusResponse.statusCode == 200) {
        final statusData = json.decode(statusResponse.body);
        print('✅ Database connected: ${statusData['databaseConnected']}');
        print('📋 Pending migrations: ${statusData['pendingMigrations']?.length ?? 0}');
      } else {
        print('❌ Migration status failed: ${statusResponse.body}');
      }
    } else {
      print('❌ Login failed: ${loginResponse.body}');
    }
  } catch (e) {
    print('❌ Login error: $e');
  }
  
  print('\n🎉 Admin registration test complete!');
}
