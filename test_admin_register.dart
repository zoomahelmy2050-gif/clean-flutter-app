import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final baseUrl = 'https://clean-flutter-app.onrender.com';
  final email = 'env.hygiene@gmail.com';
  final password = 'password';
  
  print('Testing admin registration and login...\n');
  
  // Simple v2 password record for testing
  final passwordRecordV2 = 'v2:dGVzdHNhbHQ=:100000:dGVzdGhhc2g=';
  
  // Register admin
  print('1. Registering admin user...');
  try {
    final registerResponse = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'passwordRecordV2': passwordRecordV2,
      }),
    );
    
    print('   Status: ${registerResponse.statusCode}');
    if (registerResponse.statusCode == 409) {
      print('   User already exists - continuing...');
    } else if (registerResponse.statusCode == 200 || registerResponse.statusCode == 201) {
      print('   ✅ Registration successful!');
    } else {
      print('   ❌ Registration failed: ${registerResponse.body}');
    }
  } catch (e) {
    print('   ❌ Registration error: $e');
  }
  
  // Test login
  print('\n2. Testing login...');
  try {
    final loginResponse = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );
    
    print('   Status: ${loginResponse.statusCode}');
    if (loginResponse.statusCode == 200) {
      final loginData = json.decode(loginResponse.body);
      final token = loginData['accessToken'];
      print('   ✅ Login successful!');
      print('   Token: ${token.substring(0, 20)}...');
      
      // Test migration endpoint
      print('\n3. Testing migration status...');
      final statusResponse = await http.get(
        Uri.parse('$baseUrl/migrations/status'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      print('   Status: ${statusResponse.statusCode}');
      if (statusResponse.statusCode == 200) {
        final statusData = json.decode(statusResponse.body);
        print('   ✅ Migration endpoint works!');
        print('   Database connected: ${statusData['databaseConnected']}');
      } else {
        print('   ❌ Migration endpoint failed: ${statusResponse.body}');
      }
    } else {
      print('   ❌ Login failed: ${loginResponse.body}');
    }
  } catch (e) {
    print('   ❌ Login error: $e');
  }
  
  print('\nTest complete!');
}
