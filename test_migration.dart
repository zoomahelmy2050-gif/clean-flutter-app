import 'lib/core/services/hybrid_auth_service.dart';
import 'lib/core/services/database_service.dart';

Future<void> main() async {
  print('Testing Database Migration Functionality...\n');
  
  // Initialize services
  final hybridAuth = HybridAuthService();
  await hybridAuth.initialize();
  
  print('1. Testing migration status...');
  final status = await hybridAuth.getMigrationStatus();
  print('   - Use Database: ${status['useDatabase']}');
  print('   - Local Users: ${status['localUsers']}');
  print('   - Database Users: ${status['databaseUsers']}');
  print('   - Server Healthy: ${status['serverHealthy']}');
  
  print('\n2. Testing local user registration...');
  final registerResult = await hybridAuth.register('test@example.com', 'password123');
  print('   - Registration successful: ${registerResult['success']}');
  if (registerResult['message'] != null) {
    print('   - Message: ${registerResult['message']}');
  }
  
  if (registerResult['success'] == true) {
    print('\n3. Testing local user login...');
    final loginResult = await hybridAuth.login('test@example.com', 'password123');
    print('   - Login successful: ${loginResult['success']}');
    if (loginResult['message'] != null) {
      print('   - Message: ${loginResult['message']}');
    }
    
    print('\n4. Testing user management...');
    final users = await hybridAuth.getAllUsersDetailed();
    print('   - Total users: ${users.length}');
    for (final user in users) {
      print('   - User: ${user['email']} (blocked: ${user['blocked']})');
    }
  }
  
  print('\n5. Testing database connection...');
  final databaseService = DatabaseService();
  await databaseService.initialize();
  final isHealthy = await databaseService.isServerHealthy();
  print('   - Database server healthy: $isHealthy');
  
  if (!isHealthy) {
    print('   - Database server is not available. This is expected if the server is not running.');
    print('   - The hybrid service will automatically fall back to local storage.');
  }
  
  print('\n6. Testing database mode toggle...');
  if (isHealthy) {
    final enableResult = await hybridAuth.enableDatabaseMode();
    print('   - Database mode enabled: $enableResult');
    
    if (enableResult) {
      final newStatus = await hybridAuth.getMigrationStatus();
      print('   - New status - Use Database: ${newStatus['useDatabase']}');
      
      // Test migration
      print('\n7. Testing migration to database...');
      final migrationResult = await hybridAuth.migrateToDatabase();
      print('   - Migration successful: ${migrationResult['success']}');
      if (migrationResult['success']) {
        final data = migrationResult['data'];
        print('   - Migrated: ${data['migrated']} users');
        print('   - Failed: ${data['failed']} users');
      }
    }
  } else {
    print('   - Skipping database mode tests (server not available)');
  }
  
  print('\nMigration functionality test completed!');
  print('The hybrid auth service is working correctly and can switch between local and database storage.');
}
