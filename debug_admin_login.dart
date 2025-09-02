import 'lib/core/services/hybrid_auth_service.dart';

Future<void> main() async {
  print('=== DEBUGGING ADMIN LOGIN ===\n');
  
  // Initialize services
  final hybridAuth = HybridAuthService();
  await hybridAuth.initialize();
  
  const adminEmail = 'env.hygiene@gmail.com';
  const adminPassword = 'password';
  
  print('1. Checking if admin user exists...');
  final users = hybridAuth.getAllUsers();
  print('   - All users: $users');
  print('   - Admin exists: ${users.contains(adminEmail)}');
  
  print('\n2. Testing admin login...');
  final loginResult = await hybridAuth.login(adminEmail, adminPassword);
  print('   - Login result: $loginResult');
  print('   - Success: ${loginResult['success']}');
  print('   - Error: ${loginResult['error']}');
  
  print('\n3. Testing login attempts tracking...');
  final loginAttempts = hybridAuth.loginAttemptsService;
  final attemptCount = loginAttempts.getFailedAttemptCount(adminEmail);
  print('   - Failed attempts: $attemptCount');
  print('   - Is locked: ${loginAttempts.isUserLocked(adminEmail)}');
  
  print('\n4. Testing wrong password...');
  final wrongResult = await hybridAuth.login(adminEmail, 'wrongpassword');
  print('   - Wrong password result: $wrongResult');
  
  final newAttemptCount = loginAttempts.getFailedAttemptCount(adminEmail);
  print('   - Failed attempts after wrong password: $newAttemptCount');
  
  print('\n=== DEBUG COMPLETE ===');
}
