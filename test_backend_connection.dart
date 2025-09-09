import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('Testing backend connection...\n');
  
  final backendUrl = 'https://clean-flutter-app.onrender.com';
  
  try {
    // Test health endpoint
    print('Testing health endpoint...');
    final healthResponse = await http.get(
      Uri.parse('$backendUrl/health'),
    ).timeout(const Duration(seconds: 10));
    print('Health: ${healthResponse.statusCode} - ${healthResponse.body}');
    
    // Test auth/login endpoint
    print('\nTesting login endpoint...');
    final loginResponse = await http.post(
      Uri.parse('$backendUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': 'env.hygiene@gmail.com',
        'password': 'password',
      }),
    ).timeout(const Duration(seconds: 10));
    
    print('Login: ${loginResponse.statusCode}');
    if (loginResponse.statusCode == 200) {
      final data = json.decode(loginResponse.body);
      print('Token received: ${data['accessToken'] != null ? 'YES' : 'NO'}');
      
      if (data['accessToken'] != null) {
        // Test migration status endpoint
        print('\nTesting migration status endpoint...');
        final migrationResponse = await http.get(
          Uri.parse('$backendUrl/migrations/status'),
          headers: {
            'Authorization': 'Bearer ${data['accessToken']}',
          },
        ).timeout(const Duration(seconds: 10));
        print('Migration status: ${migrationResponse.statusCode}');
        if (migrationResponse.statusCode == 200) {
          final migrationData = json.decode(migrationResponse.body);
          print('Database connected: ${migrationData['databaseConnected']}');
        }
      }
    } else {
      print('Login failed: ${loginResponse.body}');
    }
  } catch (e) {
    print('\nError: $e');
    print('\nThe backend server might be down or not responding.');
    print('Please check: https://dashboard.render.com');
  }
}
