import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final baseUrl = 'https://clean-flutter-app.onrender.com';
  
  print('🚀 Testing backend connection...\n');
  
  // Test health endpoint
  try {
    final healthResponse = await http.get(Uri.parse('$baseUrl/health'));
    print('✅ Health check: ${healthResponse.statusCode}');
  } catch (e) {
    print('❌ Health check failed: $e');
    return;
  }
  
  // Register admin user with proper v2 password
  print('\n📝 Registering admin user...');
  try {
    final registerResponse = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': 'env.hygiene@gmail.com',
        'passwordRecordV2': 'v2:c2FsdA==:100000:aGFzaA==', // Simple test record
      }),
    );
    
    print('   Registration: ${registerResponse.statusCode}');
    if (registerResponse.statusCode == 409) {
      print('   ℹ️ User already exists (expected)');
    }
  } catch (e) {
    print('   ❌ Registration error: $e');
  }
  
  // Test login
  print('\n🔐 Testing login...');
  try {
    final loginResponse = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': 'env.hygiene@gmail.com',
        'password': 'password',
      }),
    );
    
    print('   Login: ${loginResponse.statusCode}');
    if (loginResponse.statusCode == 200) {
      final loginData = json.decode(loginResponse.body);
      final token = loginData['accessToken'];
      print('   ✅ Login successful!');
      
      // Test migration status
      print('\n📊 Testing migration status...');
      final statusResponse = await http.get(
        Uri.parse('$baseUrl/migrations/status'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      print('   Migration status: ${statusResponse.statusCode}');
      if (statusResponse.statusCode == 200) {
        final statusData = json.decode(statusResponse.body);
        print('   ✅ Database connected: ${statusData['databaseConnected']}');
        print('   📋 Pending migrations: ${statusData['pendingMigrations']?.length ?? 0}');
      }
    } else {
      print('   ❌ Login failed: ${loginResponse.body}');
    }
  } catch (e) {
    print('   ❌ Login error: $e');
  }
  
  print('\n🎉 Backend test complete!');
}
