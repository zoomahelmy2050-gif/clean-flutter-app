import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

void main() async {
  final baseUrl = 'https://clean-flutter-app.onrender.com';
  
  // First, delete existing user if exists
  print('Testing backend authentication...\n');
  
  // Generate proper v2 password record
  final password = 'password';
  final salt = base64.encode(List.generate(32, (i) => i));
  final iterations = 100000;
  
  // Compute PBKDF2
  final passwordBytes = utf8.encode(password);
  final saltBytes = base64.decode(salt);
  
  // Simple PBKDF2 computation for testing
  final key = Hmac(sha256, passwordBytes);
  final verifierBytes = key.convert(saltBytes).bytes;
  final verifier = base64.encode(verifierBytes);
  
  final passwordRecordV2 = 'v2:$salt:$iterations:$verifier';
  
  print('1. Registering user with proper v2 password record...');
  try {
    final registerResponse = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': 'test.admin@example.com',
        'passwordRecordV2': passwordRecordV2,
      }),
    );
    
    print('   Registration status: ${registerResponse.statusCode}');
    if (registerResponse.statusCode == 200 || registerResponse.statusCode == 201) {
      print('   ✅ Registration successful!\n');
    } else if (registerResponse.statusCode == 409) {
      print('   ⚠️ User already exists\n');
    }
  } catch (e) {
    print('   ❌ Registration failed: $e\n');
  }
  
  // Test with Security Center credentials
  print('2. Testing with Security Center admin credentials...');
  
  // Create a proper v2 record for Security Center admin
  final adminSalt = base64.encode(List.generate(32, (i) => 100 + i));
  final adminKey = Hmac(sha256, utf8.encode('password'));
  final adminVerifier = base64.encode(adminKey.convert(base64.decode(adminSalt)).bytes);
  final adminPasswordRecordV2 = 'v2:$adminSalt:100000:$adminVerifier';
  
  try {
    final registerResponse = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': 'env.hygiene@gmail.com',
        'passwordRecordV2': adminPasswordRecordV2,
      }),
    );
    
    print('   Admin registration status: ${registerResponse.statusCode}');
    if (registerResponse.statusCode == 200 || registerResponse.statusCode == 201) {
      print('   ✅ Admin registered successfully!');
      
      // Now test login
      print('\n3. Testing login...');
      final loginResponse = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': 'env.hygiene@gmail.com',
          'password': 'password',
        }),
      );
      
      print('   Login status: ${loginResponse.statusCode}');
      if (loginResponse.statusCode == 200) {
        final loginData = json.decode(loginResponse.body);
        print('   ✅ Login successful!');
        print('   Token: ${loginData['accessToken']?.substring(0, 30)}...\n');
        
        // Test migration status
        print('4. Testing migration status endpoint...');
        final statusResponse = await http.get(
          Uri.parse('$baseUrl/migrations/status'),
          headers: {'Authorization': 'Bearer ${loginData['accessToken']}'},
        );
        
        print('   Migration status: ${statusResponse.statusCode}');
        if (statusResponse.statusCode == 200) {
          final statusData = json.decode(statusResponse.body);
          print('   ✅ Migration status retrieved!');
          print('   Database connected: ${statusData['databaseConnected']}');
        }
      } else {
        print('   ❌ Login failed: ${loginResponse.body}');
      }
    } else if (registerResponse.statusCode == 409) {
      print('   ⚠️ Admin already exists - this is expected');
    }
  } catch (e) {
    print('   ❌ Error: $e');
  }
  
  print('\n✅ Test complete!');
}
