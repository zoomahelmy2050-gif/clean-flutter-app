import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // Test backend authentication
  await testBackendAuth();
}

Future<void> testBackendAuth() async {
  print('Testing backend authentication...\n');
  
  const baseUrl = 'https://clean-flutter-app.onrender.com';
  
  try {
    // Step 1: Login to get JWT token
    print('1. Logging in to backend...');
    final loginResponse = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': 'admin@example.com',  // Use your admin credentials
        'password': 'Admin123!',        // Use your admin password
      }),
    );
    
    if (loginResponse.statusCode == 200 || loginResponse.statusCode == 201) {
      final loginData = json.decode(loginResponse.body);
      final token = loginData['access_token'] ?? loginData['token'];
      
      print('✅ Login successful! Token: ${token?.substring(0, 20)}...\n');
      
      // Save token for the app to use
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      print('✅ Token saved to SharedPreferences\n');
      
      // Step 2: Test migrations endpoint with token
      print('2. Testing /migrations/status with token...');
      final statusResponse = await http.get(
        Uri.parse('$baseUrl/migrations/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (statusResponse.statusCode == 200) {
        final statusData = json.decode(statusResponse.body);
        print('✅ Migration status retrieved:');
        print('   Database Connected: ${statusData['databaseConnected']}');
        print('   Prisma Status: ${statusData['prismaStatus']}');
        print('   Migrations: ${statusData['migrations']}');
      } else {
        print('❌ Failed to get migration status: ${statusResponse.statusCode}');
        print('   Response: ${statusResponse.body}');
      }
    } else {
      print('❌ Login failed: ${loginResponse.statusCode}');
      print('   Response: ${loginResponse.body}');
      print('\n⚠️  Make sure you have created an admin user on the backend!');
      print('   You may need to register first at $baseUrl/auth/register');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
