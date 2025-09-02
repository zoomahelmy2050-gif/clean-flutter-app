import 'package:flutter_test/flutter_test.dart';
import 'test/services/security_orchestration_service_test.dart' as orchestration_test;
import 'test/services/performance_monitoring_service_test.dart' as performance_test;
import 'test/services/emerging_threats_service_test.dart' as threats_test;

void main() {
  print('Running Security Service Tests...\n');
  
  group('Security Service Tests', () {
    print('Testing Security Orchestration Service...');
    orchestration_test.main();
    
    print('Testing Performance Monitoring Service...');
    performance_test.main();
    
    print('Testing Emerging Threats Service...');
    threats_test.main();
  });
  
  print('\nAll tests completed!');
}
