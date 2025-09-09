import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const backendUrl = 'https://clean-flutter-app.onrender.com';
  const email = 'env.hygiene@gmail.com';
  const password = 'password';
  
  print('Testing Render backend authentication...\n');
  
  // 1. Check health
  print('1. Checking backend health...');
  try {
    final healthResponse = await http.get(
      Uri.parse('$backendUrl/health'),
    ).timeout(Duration(seconds: 30));
    
    if (healthResponse.statusCode == 200) {
      print('✅ Backend is healthy: ${healthResponse.body}');
    } else {
      print('❌ Health check failed: ${healthResponse.statusCode}');
    }
  } catch (e) {
    print('❌ Health check error: $e');
    print('Backend might be sleeping. Waiting 10 seconds...');
    await Future.delayed(Duration(seconds: 10));
  }
  
  // 2. Try to register the admin user
  print('\n2. Registering admin user...');
  try {
    final registerResponse = await http.post(
      Uri.parse('$backendUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'passwordRecordV2': password,
      }),
    ).timeout(Duration(seconds: 30));
    
    if (registerResponse.statusCode == 201 || registerResponse.statusCode == 200) {
      print('✅ Admin user registered successfully');
      final data = jsonDecode(registerResponse.body);
      print('Response: $data');
    } else {
      final error = registerResponse.body;
      if (error.contains('already exists') || error.contains('duplicate')) {
        print('⚠️ User already exists (this is OK)');
      } else {
        print('❌ Registration failed: ${registerResponse.statusCode}');
        print('Response: $error');
      }
    }
  } catch (e) {
    print('Registration error: $e');
  }
  
  // 3. Try to login
  print('\n3. Testing login...');
  try {
    final loginResponse = await http.post(
      Uri.parse('$backendUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    ).timeout(Duration(seconds: 30));
    
    if (loginResponse.statusCode == 200) {
      final data = jsonDecode(loginResponse.body);
      final token = data['accessToken'] ?? data['access_token'];
      
      if (token != null) {
        print('✅ Login successful!');
        print('Token received (first 20 chars): ${token.substring(0, 20)}...');
        
        // 4. Test migration endpoint
        print('\n4. Testing migration endpoint...');
        try {
          final migrationResponse = await http.get(
            Uri.parse('$backendUrl/migrations/status'),
            headers: {
              'Authorization': 'Bearer $token',
            },
          ).timeout(Duration(seconds: 30));
          
          if (migrationResponse.statusCode == 200) {
            final migrationData = jsonDecode(migrationResponse.body);
            print('✅ Migration endpoint working!');
            print('Database connected: ${migrationData['databaseConnected']}');
            if (migrationData['migrations'] != null) {
              print('Migrations count: ${migrationData['migrations'].length}');
            }
          } else {
            print('❌ Migration status failed: ${migrationResponse.statusCode}');
            print('Response: ${migrationResponse.body}');
          }
        } catch (e) {
          print('Migration endpoint error: $e');
        }
      } else {
        print('❌ No token in response');
        print('Response: $data');
      }
    } else {
      print('❌ Login failed: ${loginResponse.statusCode}');
      print('Response: ${loginResponse.body}');
    }
  } catch (e) {
    print('Login error: $e');
  }
  
  print('\n====================================');
  print('Summary:');
  print('Backend URL: $backendUrl');
  print('Admin Email: $email');
  print('Admin Password: $password');
  print('====================================');
  print('\nIf authentication is working, you can now use the Flutter app.');
  print('If not, please check the error messages above.');
}
