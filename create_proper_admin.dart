import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

void main() async {
  // Create proper v2 password record
  final password = 'password';
  final salt = _generateSalt();
  final iterations = 100000;
  final verifier = _computeVerifier(password, salt, iterations);
  
  final saltB64 = base64Encode(salt);
  final verifierB64 = base64Encode(verifier);
  final passwordRecordV2 = 'v2:$saltB64:$iterations:$verifierB64';
  
  print('Generated password record: $passwordRecordV2');
  
  // Register with proper format
  try {
    final registerResponse = await http.post(
      Uri.parse('https://clean-flutter-app.onrender.com/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': 'env.hygiene@gmail.com',
        'passwordRecordV2': passwordRecordV2,
      }),
    );
    
    print('Registration status: ${registerResponse.statusCode}');
    if (registerResponse.statusCode == 200 || registerResponse.statusCode == 201) {
      print('✅ Registration successful!');
      
      // Test login
      final loginResponse = await http.post(
        Uri.parse('https://clean-flutter-app.onrender.com/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': 'env.hygiene@gmail.com',
          'password': password,
        }),
      );
      
      print('Login status: ${loginResponse.statusCode}');
      if (loginResponse.statusCode == 200) {
        final loginData = json.decode(loginResponse.body);
        print('✅ Login successful!');
        print('Token: ${loginData['accessToken']?.substring(0, 20)}...');
        
        // Test migration status
        final token = loginData['accessToken'];
        final statusResponse = await http.get(
          Uri.parse('https://clean-flutter-app.onrender.com/migrations/status'),
          headers: {'Authorization': 'Bearer $token'},
        );
        
        print('Migration status: ${statusResponse.statusCode}');
        if (statusResponse.statusCode == 200) {
          final statusData = json.decode(statusResponse.body);
          print('✅ Migration status retrieved!');
          print('Database connected: ${statusData['databaseConnected']}');
        }
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}

Uint8List _generateSalt() {
  final random = Random.secure();
  final salt = Uint8List(32);
  for (int i = 0; i < salt.length; i++) {
    salt[i] = random.nextInt(256);
  }
  return salt;
}

Uint8List _computeVerifier(String password, Uint8List salt, int iterations) {
  final passwordBytes = utf8.encode(password);
  final key = _pbkdf2(passwordBytes, salt, iterations, 32);
  final hmac = Hmac(sha256, salt);
  final digest = hmac.convert(key);
  return Uint8List.fromList(digest.bytes);
}

Uint8List _pbkdf2(List<int> password, Uint8List salt, int iterations, int keyLength) {
  final hmac = Hmac(sha256, password);
  final result = Uint8List(keyLength);
  final block = Uint8List(salt.length + 4);
  
  block.setRange(0, salt.length, salt);
  
  for (int i = 1; i <= (keyLength / 32).ceil(); i++) {
    block[salt.length] = (i >> 24) & 0xff;
    block[salt.length + 1] = (i >> 16) & 0xff;
    block[salt.length + 2] = (i >> 8) & 0xff;
    block[salt.length + 3] = i & 0xff;
    
    var u = hmac.convert(block).bytes;
    var f = List<int>.from(u);
    
    for (int j = 1; j < iterations; j++) {
      u = hmac.convert(u).bytes;
      for (int k = 0; k < f.length; k++) {
        f[k] ^= u[k];
      }
    }
    
    final start = (i - 1) * 32;
    final end = (start + 32 > keyLength) ? keyLength : start + 32;
    result.setRange(start, end, f);
  }
  
  return result;
}
