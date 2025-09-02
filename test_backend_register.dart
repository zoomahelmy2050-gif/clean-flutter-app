import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const baseUrl = 'https://clean-flutter-app.onrender.com';
  
  // Register admin account (same as Security Center)
  print('Registering admin account...');
  try {
    final registerResponse = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': 'env.hygiene@gmail.com',
        'passwordRecordV2': 'v2:password',
      }),
    );
    
    print('Register status: ${registerResponse.statusCode}');
    print('Register response: ${registerResponse.body}');
    
    if (registerResponse.statusCode == 201 || registerResponse.statusCode == 200) {
      print('✅ Admin account registered successfully!');
    }
  } catch (e) {
    print('Registration error: $e');
  }
  
  // Test login
  print('\nTesting login...');
  try {
    final loginResponse = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': 'env.hygiene@gmail.com',
        'password': 'password',
      }),
    );
    
    print('Login status: ${loginResponse.statusCode}');
    
    if (loginResponse.statusCode == 200) {
      final loginData = json.decode(loginResponse.body);
      final token = loginData['access_token'] ?? loginData['token'];
      print('✅ Login successful!');
      print('Token: ${token?.substring(0, 20)}...');
      
      // Test migration status with token
      print('\nTesting /migrations/status...');
      final statusResponse = await http.get(
        Uri.parse('$baseUrl/migrations/status'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      print('Migration status code: ${statusResponse.statusCode}');
      if (statusResponse.statusCode == 200) {
        final statusData = json.decode(statusResponse.body);
        print('✅ Migration status retrieved!');
        print('Database connected: ${statusData['databaseConnected']}');
        print('Has pending migrations: ${statusData['hasPendingMigrations']}');
      }
    }
  } catch (e) {
    print('Login error: $e');
  }
}
