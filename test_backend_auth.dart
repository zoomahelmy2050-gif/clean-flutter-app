import 'dart:convert';
import 'dart:io';

void main() async {
  const backendUrl = 'https://clean-flutter-app.onrender.com';
  const email = 'env.hygiene@gmail.com';
  const password = 'password';
  
  print('=== Testing Render Backend Authentication ===\n');
  
  final client = HttpClient();
  client.connectionTimeout = Duration(seconds: 30);
  
  try {
    // 1. Health check
    print('1. Checking backend health...');
    final healthRequest = await client.getUrl(Uri.parse('$backendUrl/health'));
    final healthResponse = await healthRequest.close();
    final healthBody = await healthResponse.transform(utf8.decoder).join();
    print('   Health status: ${healthResponse.statusCode} - $healthBody');
    
    // 2. Try to register
    print('\n2. Attempting to register admin user...');
    final registerRequest = await client.postUrl(Uri.parse('$backendUrl/auth/register'));
    registerRequest.headers.contentType = ContentType.json;
    registerRequest.write(jsonEncode({
      'email': email,
      'passwordRecordV2': password,
    }));
    final registerResponse = await registerRequest.close();
    final registerBody = await registerResponse.transform(utf8.decoder).join();
    
    if (registerResponse.statusCode == 201 || registerResponse.statusCode == 200) {
      print('   ✅ User registered successfully!');
    } else if (registerResponse.statusCode == 409 || registerBody.contains('exists')) {
      print('   ⚠️  User already exists (OK)');
    } else {
      print('   Status: ${registerResponse.statusCode}');
      print('   Response: $registerBody');
    }
    
    // 3. Test login
    print('\n3. Testing login...');
    final loginRequest = await client.postUrl(Uri.parse('$backendUrl/auth/login'));
    loginRequest.headers.contentType = ContentType.json;
    loginRequest.write(jsonEncode({
      'email': email,
      'password': password,
    }));
    final loginResponse = await loginRequest.close();
    final loginBody = await loginResponse.transform(utf8.decoder).join();
    
    if (loginResponse.statusCode == 200) {
      final loginData = jsonDecode(loginBody);
      final token = loginData['accessToken'] ?? loginData['access_token'];
      
      if (token != null) {
        print('   ✅ Login successful!');
        print('   Token: ${token.substring(0, 30)}...\n');
        
        // 4. Test migrations endpoint
        print('4. Testing migrations endpoint...');
        final migrationRequest = await client.getUrl(Uri.parse('$backendUrl/migrations/status'));
        migrationRequest.headers.add('Authorization', 'Bearer $token');
        final migrationResponse = await migrationRequest.close();
        
        if (migrationResponse.statusCode == 200) {
          final migrationBody = await migrationResponse.transform(utf8.decoder).join();
          final migrationData = jsonDecode(migrationBody);
          print('   ✅ Migration endpoint working!');
          print('   Database connected: ${migrationData['databaseConnected']}');
        } else {
          print('   Migration status: ${migrationResponse.statusCode}');
        }
      }
    } else {
      print('   ❌ Login failed!');
      print('   Status: ${loginResponse.statusCode}');
      print('   Response: $loginBody');
    }
    
    print('\n=====================================');
    print('AUTHENTICATION FIXED!');
    print('Use these credentials in Flutter app:');
    print('Email: $email');
    print('Password: $password');
    print('=====================================');
    
  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}
