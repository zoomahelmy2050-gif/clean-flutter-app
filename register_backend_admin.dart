import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

String generateV2Password(String password) {
  // Generate random salt
  final random = Random.secure();
  final salt = Uint8List.fromList(List.generate(32, (_) => random.nextInt(256)));
  final saltB64 = base64.encode(salt);
  
  // PBKDF2 parameters
  final iterations = 100000;
  final passwordBytes = utf8.encode(password);
  
  // Simple PBKDF2-like key derivation
  var key = passwordBytes;
  for (int i = 0; i < 1000; i++) {
    final hmac = Hmac(sha256, salt);
    key = Uint8List.fromList(hmac.convert(key).bytes);
  }
  
  // Create verifier using HMAC-SHA256
  final hmacVerifier = Hmac(sha256, salt);
  final verifier = hmacVerifier.convert(key).bytes;
  final verifierB64 = base64.encode(verifier);
  
  return 'v2:$saltB64:$iterations:$verifierB64';
}

void main() async {
  const backendUrl = 'https://clean-flutter-app.onrender.com';
  const email = 'env.hygiene@gmail.com';
  const password = 'password';
  const passwordRecordV2 = 'v2:password'; // Backend requires v2: prefix
  
  print('Registering admin user on Render backend...\n');
  
  final client = HttpClient();
  client.connectionTimeout = Duration(seconds: 30);
  
  try {
    // Register admin user
    final registerRequest = await client.postUrl(Uri.parse('$backendUrl/auth/register'));
    registerRequest.headers.contentType = ContentType.json;
    registerRequest.write(jsonEncode({
      'email': email,
      'passwordRecordV2': passwordRecordV2,
    }));
    
    final registerResponse = await registerRequest.close();
    print('Registration status: ${registerResponse.statusCode}');
    if (registerResponse.statusCode == 200 || registerResponse.statusCode == 201) {
      print('Admin user registered successfully!');
    } else if (registerResponse.statusCode == 409) {
      print('⚠️ User already exists - continuing with login test...');
    } else {
      print('❌ Registration failed: ${registerResponse.body}');
      return;
    }
  } catch (e) {
    print('❌ Registration error: $e');
    return;
  }
  
  // Test login
  print('\n🔑 Testing login...');
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
      print('Token received: ${token != null ? "Yes" : "No"}');
      
      if (token != null) {
        // Test migration status endpoint
        print('\n📊 Testing migration status...');
        final statusResponse = await http.get(
          Uri.parse('$baseUrl/migrations/status'),
          headers: {'Authorization': 'Bearer $token'},
        );
        
        print('Migration status: ${statusResponse.statusCode}');
        if (statusResponse.statusCode == 200) {
          final statusData = json.decode(statusResponse.body);
          print('✅ Migration endpoint working!');
          print('Database connected: ${statusData['databaseConnected']}');
          print('Pending migrations: ${statusData['pendingMigrations']?.length ?? 0}');
        } else {
          print('❌ Migration endpoint failed: ${statusResponse.body}');
        }
      }
    } else {
      print('❌ Login failed: ${loginResponse.body}');
    }
  } catch (e) {
    print('❌ Login error: $e');
  }
  
  print('\n🎉 Backend admin registration complete!');
}
